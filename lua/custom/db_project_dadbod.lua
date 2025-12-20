-- vim: ts=2 sts=2 sw=2 et
--
-- Project-aware loader for vim-dadbod connections.
-- Tries to infer DB connection from common project files:
--   - .env(.local/.development/.dev): DATABASE_URL / DBI_DSN / DB_DSN
--   - config.yml (Dancer/Dancer2 style): plugins: Database: ...
--   - config/database.yml (very rough)
--
-- It merges into vim.g.dbs without overwriting existing keys.

local M = {}

local function exists(path)
  return vim.fn.filereadable(path) == 1
end

local function readfile(path)
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end
  return lines
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function unquote(s)
  s = trim(s)
  if (s:sub(1, 1) == '"' and s:sub(-1) == '"') or (s:sub(1, 1) == "'" and s:sub(-1) == "'") then
    return s:sub(2, -2)
  end
  return s
end

local function find_project_root(start_dir)
  local markers = { ".git", "cpanfile", "Makefile.PL", "dist.ini" }
  local found = vim.fs.find(markers, { upward = true, path = start_dir })[1]
  if found then
    return vim.fs.dirname(found)
  end
  return start_dir
end

local function parse_env(lines)
  -- Supports:
  --   KEY=VALUE
  --   export KEY=VALUE
  -- Ignores comments.
  local env = {}
  for _, line in ipairs(lines or {}) do
    -- strip comments (naive, but OK for typical .env)
    line = line:gsub("%s+#.*$", "")
    line = trim(line)
    if line ~= "" then
      local k, v = line:match("^export%s+([A-Za-z_][A-Za-z0-9_]*)%s*=%s*(.+)$")
      if not k then
        k, v = line:match("^([A-Za-z_][A-Za-z0-9_]*)%s*=%s*(.+)$")
      end
      if k and v then
        env[k] = unquote(v)
      end
    end
  end
  return env
end

local function first_nonempty(...)
  for i = 1, select("#", ...) do
    local v = select(i, ...)
    if v and v ~= "" then
      return v
    end
  end
  return nil
end

local function infer_from_env(root)
  local env_files = {
    ".env",
    ".env.local",
    ".env.development",
    ".env.dev",
  }

  for _, fname in ipairs(env_files) do
    local path = root .. "/" .. fname
    if exists(path) then
      local env = parse_env(readfile(path))
      local dsn = first_nonempty(env.DATABASE_URL, env.DBI_DSN, env.DB_DSN)
      if dsn and dsn ~= "" then
        return {
          key = "project",
          dsn = dsn,
          source = fname,
        }
      end
    end
  end

  return nil
end

local function yaml_get(lines, key)
  -- Very naive YAML "key: value" at any indentation.
  -- Works for simple scalar values.
  for _, line in ipairs(lines or {}) do
    local k, v = line:match("^%s*([%w_%-]+)%s*:%s*(.-)%s*$")
    if k == key and v and v ~= "" then
      return unquote(v)
    end
  end
  return nil
end

local function infer_from_dancer_config_yml(root)
  -- Tries to parse typical Dancer2 config.yml:
  -- plugins:
  --   Database:
  --     driver: Pg
  --     database: dbname
  --     host: 127.0.0.1
  --     port: 5432
  --     username: user
  --     password: pass
  --
  -- Or Dancer plugin:
  -- plugins:
  --   Database:
  --     dsn: "dbi:Pg:dbname=...;host=...;port=..."
  local path = root .. "/config.yml"
  if not exists(path) then
    return nil
  end

  local lines = readfile(path)
  if not lines then
    return nil
  end

  -- First: if explicit DSN present anywhere, use it.
  local dsn = yaml_get(lines, "dsn")
  if dsn and dsn:match("^dbi:") then
    -- dadbod prefers URL-like DSN, but it can also work with some dbi: strings
    -- We'll keep as-is; user can adjust.
    return { key = "project", dsn = dsn, source = "config.yml(dsn)" }
  end

  -- Try scalar keys
  local driver = yaml_get(lines, "driver")
  local database = yaml_get(lines, "database")
  local host = yaml_get(lines, "host")
  local port = yaml_get(lines, "port")
  local username = yaml_get(lines, "username") or yaml_get(lines, "user")
  local password = yaml_get(lines, "password") or yaml_get(lines, "pass")

  if driver and database then
    driver = driver:lower()
    host = host or "127.0.0.1"

    -- Map common drivers to URL schemes.
    local scheme_map = {
      pg = "postgresql",
      postgres = "postgresql",
      postgresql = "postgresql",
      mysql = "mysql",
      mariadb = "mysql",
      sqlite = "sqlite",
    }
    local scheme = scheme_map[driver] or driver

    -- Build URL. Password optional.
    local auth = ""
    if username and username ~= "" then
      if password and password ~= "" then
        auth = ("%s:%s@"):format(username, password)
      else
        auth = ("%s@"):format(username)
      end
    end

    if scheme == "sqlite" then
      -- For sqlite, database may be a path or filename; keep minimal
      return { key = "project", dsn = ("sqlite:%s"):format(database), source = "config.yml(sqlite)" }
    end

    local hp = host
    if port and port ~= "" then
      hp = ("%s:%s"):format(host, port)
    end

    return {
      key = "project",
      dsn = ("%s://%s%s/%s"):format(scheme, auth, hp, database),
      source = "config.yml(driver/database)",
    }
  end

  return nil
end

local function infer_from_database_yml(root)
  -- Very rough: look for config/database.yml and a "development:" block.
  local path = root .. "/config/database.yml"
  if not exists(path) then
    return nil
  end

  local lines = readfile(path)
  if not lines then
    return nil
  end

  -- naive block detection
  local in_dev = false
  local dev_lines = {}
  for _, line in ipairs(lines) do
    if line:match("^development:%s*$") then
      in_dev = true
    elseif in_dev and line:match("^[%w_%-]+:%s*$") and not line:match("^%s+") then
      -- next top-level section started
      break
    elseif in_dev then
      table.insert(dev_lines, line)
    end
  end

  if #dev_lines == 0 then
    return nil
  end

  local adapter = yaml_get(dev_lines, "adapter") or yaml_get(dev_lines, "driver")
  local database = yaml_get(dev_lines, "database")
  local host = yaml_get(dev_lines, "host") or "127.0.0.1"
  local port = yaml_get(dev_lines, "port")
  local username = yaml_get(dev_lines, "username") or yaml_get(dev_lines, "user")
  local password = yaml_get(dev_lines, "password")

  if adapter and database then
    adapter = adapter:lower()
    local scheme_map = {
      pg = "postgresql",
      postgres = "postgresql",
      postgresql = "postgresql",
      mysql2 = "mysql",
      mysql = "mysql",
      sqlite3 = "sqlite",
      sqlite = "sqlite",
    }
    local scheme = scheme_map[adapter] or adapter

    if scheme == "sqlite" then
      return { key = "project", dsn = ("sqlite:%s"):format(database), source = "config/database.yml(sqlite)" }
    end

    local auth = ""
    if username and username ~= "" then
      if password and password ~= "" then
        auth = ("%s:%s@"):format(username, password)
      else
        auth = ("%s@"):format(username)
      end
    end

    local hp = host
    if port and port ~= "" then
      hp = ("%s:%s"):format(host, port)
    end

    return {
      key = "project",
      dsn = ("%s://%s%s/%s"):format(scheme, auth, hp, database),
      source = "config/database.yml(development)",
    }
  end

  return nil
end

local function merge_dbs(new_dbs)
  if not new_dbs or not new_dbs.key or not new_dbs.dsn then
    return false
  end

  vim.g.dbs = vim.g.dbs or {}

  -- don't overwrite
  if vim.g.dbs[new_dbs.key] and vim.g.dbs[new_dbs.key] ~= "" then
    return false
  end

  vim.g.dbs[new_dbs.key] = new_dbs.dsn
  return true
end

function M.load_for_cwd(opts)
  opts = opts or {}
  local cwd = vim.fn.getcwd()
  local root = find_project_root(cwd)

  -- Priority: .env -> config.yml -> config/database.yml
  local found = infer_from_env(root)
  if not found then
    found = infer_from_dancer_config_yml(root)
  end
  if not found then
    found = infer_from_database_yml(root)
  end

  if found then
    local changed = merge_dbs(found)
    if opts.notify then
      if changed then
        notify(("dadbod: added connection '%s' from %s"):format(found.key, found.source), vim.log.levels.INFO)
      else
        notify(("dadbod: connection '%s' already set; skipped (%s)"):format(found.key, found.source), vim.log.levels.DEBUG)
      end
    end
    return true
  else
    if opts.notify then
      notify("dadbod: no project DB config found (.env/config.yml/config/database.yml)", vim.log.levels.WARN)
    end
    return false
  end
end

return M

