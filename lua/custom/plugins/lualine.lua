return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = function()
      local home = vim.loop.os_homedir()

      local function is_under(path, root)
        return root and path:sub(1, #root) == root and (path:sub(#root + 1, #root + 1) == '/' or #path == #root)
      end

      local function find_root(path)
        -- If file is inside $HOME, do not search above $HOME
        local stop = is_under(path, home) and home or nil

        -- Prefer git root if present
        local git = vim.fs.find('.git', { path = path, upward = true, stop = stop })[1]
        if git then
          return vim.fs.dirname(git)
        end

        -- Fallback markers (Perl-friendly, extend anytime)
        local m = vim.fs.find({ 'cpanfile', 'Makefile.PL', 'dist.ini' }, { path = path, upward = true, stop = stop })[1]
        return m and vim.fs.dirname(m) or nil
      end

      local function proj_path_with_icon()
        local path = vim.api.nvim_buf_get_name(0)
        if path == '' then
          return ''
        end

        local root = find_root(path)
        local shown = (root and path:sub(1, #root + 1) == root .. '/') and path:sub(#root + 2) or vim.fn.fnamemodify(path, ':~')

        -- Shorten when window is narrow
        if vim.api.nvim_win_get_width(0) < 120 then
          shown = vim.fn.pathshorten(shown)
        end

        -- Add icon
        local ok, devicons = pcall(require, 'nvim-web-devicons')
        if ok then
          local icon = devicons.get_icon(path, nil, { default = true })
          if icon and icon ~= '' then
            shown = icon .. ' ' .. shown
          end
        end

        return shown
      end

      return {
        options = { globalstatus = true }, -- остальное оставляем дефолтами
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch' },
          lualine_c = { proj_path_with_icon },
          lualine_x = { 'diagnostics', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' },
        },
      }
    end,
  },

  -- Чтобы не было конфликта: statusline должен контролировать один плагин
  { 'echasnovski/mini.statusline', enabled = false },
}
