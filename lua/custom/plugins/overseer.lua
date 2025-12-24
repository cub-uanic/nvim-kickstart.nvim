-- vim: ts=2 sts=2 sw=2 et
-- Если ты открыл не *.psgi/config.ru, но файл по use определился как psgi,
-- и в проекте найден bin/app.psgi (или app.psgi/config.ru) — запустится entrypoint проекта.
--
-- Если ты открыл именно *.psgi или config.ru — запустится он, как и раньше.
--

return {
  'stevearc/overseer.nvim',
  cmd = { 'OverseerRun', 'OverseerToggle', 'OverseerOpen', 'OverseerClose' },
  keys = {
    { '<leader>oo', '<cmd>OverseerToggle<cr>', desc = 'Overseer: Toggle' },
    { '<leader>or', '<cmd>OverseerRun<cr>', desc = 'Overseer: Run task' },
    { '<leader>rr', desc = 'Run current file (smart) (Overseer/Terminal)' },
  },
  opts = {},
  config = function(_, opts)
    local overseer = require 'overseer'
    overseer.setup(opts)

    -- ---------------------------------------------------------------------
    -- helpers
    -- ---------------------------------------------------------------------
    local function notify(msg, level)
      vim.notify(msg, level or vim.log.levels.INFO)
    end

    local function buf_abs_path()
      local file = vim.api.nvim_buf_get_name(0)
      if not file or file == '' then
        return nil
      end
      return file
    end

    local function is_readable(file)
      return file and vim.fn.filereadable(file) == 1
    end

    local function exists(path)
      return vim.fn.filereadable(path) == 1 or vim.fn.isdirectory(path) == 1
    end

    local function joinpath(...)
      return table.concat({ ... }, '/')
    end

    local function dirname(p)
      return vim.fs.dirname(p)
    end

    local function find_project_root(start_dir)
      local markers = { '.git', 'cpanfile', 'Makefile.PL', 'dist.ini' }
      local found = vim.fs.find(markers, { upward = true, path = start_dir })[1]
      if found then
        return dirname(found)
      end
      return start_dir
    end

    local function glob_one(pattern)
      local res = vim.fn.glob(pattern, false, true)
      if type(res) == 'table' and #res > 0 then
        return res[1]
      end
      return nil
    end

    local function glob_all(pattern)
      local res = vim.fn.glob(pattern, false, true)
      if type(res) == 'table' then
        return res
      end
      return {}
    end

    local function ensure_cmd(cmd0)
      if vim.fn.executable(cmd0) ~= 1 then
        notify(('rr: command not found in $PATH: %s'):format(cmd0), vim.log.levels.ERROR)
        return false
      end
      return true
    end

    local function is_perl_like(file, bufnr)
      if file:match '%.p[lm]$' or file:match '%.t$' or file:match '%.psgi$' then
        return true
      end
      local ft = vim.bo[bufnr].filetype
      if ft == 'perl' then
        return true
      end
      local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ''
      if first:match '^#!' and (first:match 'perl' or first:match 'env%s+perl') then
        return true
      end
      return false
    end

    -- Create & start overseer task directly (NO run_template)
    local function run_overseer(spec)
      if not spec or not spec.cmd or not spec.cmd[1] then
        notify('rr: internal error: bad task spec', vim.log.levels.ERROR)
        return
      end

      if not ensure_cmd(spec.cmd[1]) then
        return
      end

      local task = overseer.new_task {
        name = spec.name,
        cmd = spec.cmd,
        args = spec.args,
        cwd = spec.cwd,
        components = { 'default' },
      }

      task:start()
      overseer.toggle()
    end

    local function run_in_terminal(cmdline)
      local ok_term, term_mod = pcall(require, 'toggleterm.terminal')
      if ok_term and term_mod and term_mod.Terminal then
        local Terminal = term_mod.Terminal
        local t = Terminal:new {
          cmd = cmdline,
          hidden = true,
          direction = 'float',
          close_on_exit = false,
        }
        t:toggle()
        return
      end

      run_overseer {
        name = 'terminal fallback: ' .. cmdline,
        cmd = { vim.o.shell },
        args = { vim.o.shellcmdflag, cmdline },
        cwd = nil,
      }
    end

    -- ---------------------------------------------------------------------
    -- PRIMARY detection: scan buffer for "use Something"
    -- ---------------------------------------------------------------------
    local function detect_by_uses(bufnr)
      local max_lines = math.min(vim.api.nvim_buf_line_count(bufnr), 800)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, max_lines, false)
      local text = table.concat(lines, '\n')

      if text:match '[\r\n]%s*use%s+Catalyst[%s;]' or text:match '^%s*use%s+Catalyst[%s;]' then
        return 'catalyst'
      end

      if
        text:match '[\r\n]%s*use%s+Mojolicious[%s;]'
        or text:match '^%s*use%s+Mojolicious[%s;]'
        or text:match '[\r\n]%s*use%s+Mojolicious::Lite[%s;]'
        or text:match '^%s*use%s+Mojolicious::Lite[%s;]'
        or text:match '[\r\n]%s*use%s+Mojo::[%w:]+[%s;]'
        or text:match '^%s*use%s+Mojo::[%w:]+[%s;]'
        or text:match '[\r\n]%s*use%s+Mojo[%s;]'
        or text:match '^%s*use%s+Mojo[%s;]'
      then
        return 'mojo'
      end

      if text:match '[\r\n]%s*use%s+Dancer2?[%s;]' or text:match '^%s*use%s+Dancer2?[%s;]' then
        return 'dancer'
      end

      if
        text:match '[\r\n]%s*use%s+Test2?::[%w:]+[%s;]'
        or text:match '^%s*use%s+Test2?::[%w:]+[%s;]'
        or text:match '[\r\n]%s*use%s+Test::More[%s;]'
        or text:match '^%s*use%s+Test::More[%s;]'
        or text:match '[\r\n]%s*use%s+Test::Mojo[%s;]'
        or text:match '^%s*use%s+Test::Mojo[%s;]'
        or text:match '[\r\n]%s*use%s+Test::[%w:]+[%s;]'
        or text:match '^%s*use%s+Test::[%w:]+[%s;]'
        or text:match '[\r\n]%s*use%s+Test2::V0[%s;]'
        or text:match '^%s*use%s+Test2::V0[%s;]'
      then
        return 'test'
      end

      if
        text:match '[\r\n]%s*use%s+Plack[%s;]'
        or text:match '^%s*use%s+Plack[%s;]'
        or text:match '[\r\n]%s*use%s+Plack::[%w:]+[%s;]'
        or text:match '^%s*use%s+Plack::[%w:]+[%s;]'
        or text:match '[\r\n]%s*use%s+PSGI[%s;]'
        or text:match '^%s*use%s+PSGI[%s;]'
      then
        return 'psgi'
      end

      return nil
    end

    -- ---------------------------------------------------------------------
    -- FALLBACK detection: filesystem/project + file-based heuristics
    -- (улучшено для entrypoints без поломки существующей логики)
    -- ---------------------------------------------------------------------
    local function detect_fallback(root, file)
      local is_test_path = (file:match '%.t$' ~= nil) or (file:match '/t/' ~= nil)
      local is_psgi_file = (file:match '%.psgi$' ~= nil) or (file:match 'config%.ru$' ~= nil)

      -- Mojo entrypoint:
      -- 1) script/app.pl (старое поведение)
      -- 2) иначе: любой исполняемый файл в script/ (scaffold: script/<app>)
      local mojo_app = nil
      local mojo_app_pl = joinpath(root, 'script', 'app.pl')
      if exists(mojo_app_pl) then
        mojo_app = mojo_app_pl
      else
        local scripts = glob_all(joinpath(root, 'script', '*'))
        for _, p in ipairs(scripts) do
          if vim.fn.filereadable(p) == 1 and vim.fn.executable(p) == 1 then
            mojo_app = p
            break
          end
        end
      end
      local is_mojo = mojo_app ~= nil

      -- Dancer/PSGI entrypoint: расширили поиски (bin/*.psgi, script/*.psgi тоже)
      local dancer_entry = nil
      local candidates = {
        joinpath(root, 'bin', 'app.psgi'),
        joinpath(root, 'app.psgi'),
        joinpath(root, 'config.ru'),
      }
      for _, c in ipairs(candidates) do
        if exists(c) then
          dancer_entry = c
          break
        end
      end
      if not dancer_entry then
        dancer_entry = glob_one(joinpath(root, 'bin', '*.psgi')) or glob_one(joinpath(root, 'script', '*.psgi'))
      end
      local is_dancer = dancer_entry ~= nil

      -- Catalyst: script/*_server.pl
      local catalyst_server = glob_one(joinpath(root, 'script', '*_server.pl'))
      local is_catalyst = catalyst_server ~= nil

      return {
        root = root,
        is_test = is_test_path,
        is_psgi = is_psgi_file,

        is_mojo = is_mojo,
        mojo_app = mojo_app,

        is_dancer = is_dancer,
        dancer_entry = dancer_entry,

        is_catalyst = is_catalyst,
        catalyst_server = catalyst_server,
      }
    end

    -- ---------------------------------------------------------------------
    -- rr: smart runner
    -- ---------------------------------------------------------------------
    vim.keymap.set('n', '<leader>rr', function()
      local bufnr = 0
      local file = buf_abs_path()
      if not file then
        notify('rr: current buffer has no file name', vim.log.levels.WARN)
        return
      end
      if not is_readable(file) then
        notify('rr: file is not readable: ' .. file, vim.log.levels.WARN)
        return
      end

      local root = find_project_root(dirname(file))
      local kind = detect_by_uses(bufnr)
      local fb = detect_fallback(root, file)

      -- TESTS --------------------------------------------------------------
      if kind == 'test' or fb.is_test then
        run_overseer {
          name = 'prove: ' .. vim.fn.fnamemodify(file, ':t'),
          cmd = { 'prove' },
          args = { '-l', file },
          cwd = fb.root,
        }
        return
      end

      -- PSGI / Plack -------------------------------------------------------
      if kind == 'psgi' or fb.is_psgi then
        local target = file
        if (not fb.is_psgi) and fb.dancer_entry then
          target = fb.dancer_entry
        end

        run_overseer {
          name = 'plackup: ' .. vim.fn.fnamemodify(target, ':t'),
          cmd = { 'plackup' },
          args = { '-R', 'lib', target },
          cwd = fb.root,
        }
        return
      end

      -- CATALYST -----------------------------------------------------------
      if kind == 'catalyst' or fb.is_catalyst then
        if file:match '_server%.pl$' then
          run_overseer {
            name = 'catalyst: ' .. vim.fn.fnamemodify(file, ':t'),
            cmd = { 'perl' },
            args = { file, '-r' },
            cwd = fb.root,
          }
          return
        end

        if fb.catalyst_server then
          run_overseer {
            name = 'catalyst: ' .. vim.fn.fnamemodify(fb.catalyst_server, ':t'),
            cmd = { 'perl' },
            args = { fb.catalyst_server, '-r' },
            cwd = fb.root,
          }
          return
        end

        run_in_terminal('perl ' .. vim.fn.shellescape(file))
        return
      end

      -- DANCER -------------------------------------------------------------
      if kind == 'dancer' or fb.is_dancer then
        if fb.dancer_entry then
          run_overseer {
            name = 'psgi: ' .. vim.fn.fnamemodify(fb.dancer_entry, ':t'),
            cmd = { 'plackup' },
            args = { '-R', 'lib', fb.dancer_entry },
            cwd = fb.root,
          }
          return
        end

        run_in_terminal('perl ' .. vim.fn.shellescape(file))
        return
      end

      -- MOJO ---------------------------------------------------------------
      if kind == 'mojo' or fb.is_mojo then
        -- если открыли script/*.pl — morbo текущий файл (как было)
        if file:match '/script/' and file:match '%.pl$' then
          run_overseer {
            name = 'morbo: ' .. vim.fn.fnamemodify(file, ':t'),
            cmd = { 'morbo' },
            args = { '-w', '.', file },
            cwd = fb.root,
          }
          return
        end

        -- entrypoint найден:
        if fb.mojo_app then
          -- если это app.pl -> morbo
          if fb.mojo_app:match '%.pl$' then
            run_overseer {
              name = 'morbo: ' .. vim.fn.fnamemodify(fb.mojo_app, ':t'),
              cmd = { 'morbo' },
              args = { '-w', '.', fb.mojo_app },
              cwd = fb.root,
            }
            return
          end

          -- иначе (scaffold script/<app>) — запускаем напрямую
          run_overseer {
            name = 'mojo: daemon ' .. vim.fn.fnamemodify(fb.mojo_app, ':t'),
            cmd = { fb.mojo_app },
            args = { 'daemon' },
            cwd = fb.root,
          }
          return
        end

        -- последний шанс: morbo текущий файл
        run_overseer {
          name = 'morbo: ' .. vim.fn.fnamemodify(file, ':t'),
          cmd = { 'morbo' },
          args = { '-w', '.', file },
          cwd = fb.root,
        }
        return
      end

      -- DEFAULT ------------------------------------------------------------
      if not is_perl_like(file, bufnr) then
        if fb.is_mojo and fb.mojo_app then
          if fb.mojo_app:match '%.pl$' then
            run_overseer {
              name = 'morbo: ' .. vim.fn.fnamemodify(fb.mojo_app, ':t'),
              cmd = { 'morbo' },
              args = { '-w', '.', fb.mojo_app },
              cwd = fb.root,
            }
          else
            run_overseer {
              name = 'mojo: daemon ' .. vim.fn.fnamemodify(fb.mojo_app, ':t'),
              cmd = { fb.mojo_app },
              args = { 'daemon' },
              cwd = fb.root,
            }
          end
          return
        end

        notify(('rr: not a Perl file (%s), nothing to run'):format(vim.fn.fnamemodify(file, ':t')), vim.log.levels.WARN)
        return
      end

      local is_exec = vim.fn.executable(file) == 1
      local cmdline
      if is_exec then
        cmdline = vim.fn.shellescape(file)
      else
        cmdline = 'perl ' .. vim.fn.shellescape(file)
      end
      run_in_terminal(cmdline)
    end, { desc = 'Run current file (smart) (Overseer/Terminal)' })
  end,
}
