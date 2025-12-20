-- vim: ts=2 sts=2 sw=2 et
--
-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
require 'custom.vimrc-cub'

vim.filetype.add {
  extension = {
    log = 'log',
  },
  filename = {
    ['morbo.log'] = 'log',
    ['app.log'] = 'log',
  },
}

-- Auto-load vim-dadbod connections from project files
-- (DATABASE_URL in .env, Dancer config.yml, etc.)
do
  local group = vim.api.nvim_create_augroup('CustomDadbodProject', { clear = true })

  local function reload(notify)
    local ok, mod = pcall(require, 'custom.db_project_dadbod')
    if ok and mod then
      mod.load_for_cwd { notify = notify }
    end
  end

  -- Load on startup
  vim.api.nvim_create_autocmd('VimEnter', {
    group = group,
    callback = function()
      reload(false)
    end,
  })

  -- Reload when you change directory (e.g. opening another project)
  vim.api.nvim_create_autocmd('DirChanged', {
    group = group,
    callback = function()
      reload(false)
    end,
  })

  -- Manual command
  vim.api.nvim_create_user_command('DBProjectReload', function()
    reload(true)
  end, {})
end

-- ============================================================================
-- 🧠 NVIM HOTKEYS CHEAT SHEET (from this config)
-- Leader: <Space>
-- NOTE: Insert-mode completion mappings are customized (see “Completion” below).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Core / UI (kickstart init.lua)
-- ----------------------------------------------------------------------------
-- Normal:
--   <Esc>                 : nohlsearch (clear search highlight)
--   <leader>q             : open diagnostic quickfix/loclist (vim.diagnostic.setloclist)
--
-- Terminal-mode:
--   <Esc><Esc>            : exit terminal mode to Normal  (<C-\><C-n>)
--
-- Window navigation (custom remap):
--   <C-n>                 : move to window on the left
--   <C-e>                 : move to window below
--   <C-o>                 : move to window above
--   <C-i>                 : move to window on the right
--

-- ----------------------------------------------------------------------------
-- Window navigation & moving splits (kickstart init.lua)
-- ----------------------------------------------------------------------------
-- Focus window:
--   <C-h> / <C-j> / <C-k> / <C-l>        : move focus left/down/up/right
--
-- Move current window:
--   <C-S-h> / <C-S-j> / <C-S-k> / <C-S-l>: move split to left/bottom/top/right

-- ----------------------------------------------------------------------------
-- Telescope (kickstart init.lua)
-- ----------------------------------------------------------------------------
--   <leader>sh            : help tags
--   <leader>sk            : keymaps
--   <leader>sf            : find files
--   <leader>ss            : builtin pickers
--   <leader>sw            : grep string under cursor
--   <leader>sg            : live grep
--   <leader>sd            : diagnostics
--   <leader>sr            : resume last Telescope picker
--   <leader>s.            : recent files
--   <leader>sb            : buffers
--   <leader><leader>      : live grep (same as <leader>sg in this config)
--   <leader>sn            : search Neovim config files

-- ----------------------------------------------------------------------------
-- File tree (kickstart: neo-tree)
-- ----------------------------------------------------------------------------
--   \                      : NeoTree reveal

-- ----------------------------------------------------------------------------
-- LSP (kickstart init.lua, inside LspAttach)
-- ----------------------------------------------------------------------------
-- (Your kickstart uses the “gr*” family)
--   grn                   : rename
--   grr                   : goto references
--   gri                   : goto implementation
--   grd                   : goto definition
--   grD                   : goto declaration
--   grt                   : goto type definition
--   gO                    : document symbols
--   gW                    : workspace symbols

-- ----------------------------------------------------------------------------
-- Debugging (kickstart: nvim-dap / dap-ui)
-- ----------------------------------------------------------------------------
--   <F5>                  : start/continue
--   <F1>                  : step into
--   <F2>                  : step over
--   <F3>                  : step out
--   <leader>b             : toggle breakpoint
--   <leader>B             : set conditional breakpoint
--   <F7>                  : dapui toggle (“see last session result”)

-- ----------------------------------------------------------------------------
-- Overseer (custom/plugins/overseer.lua)
-- ----------------------------------------------------------------------------
--   <leader>oo            : Overseer toggle
--   <leader>or            : Overseer run task
--   <leader>rr            : Run current file (smart: Mojo/Dancer/Catalyst/tests/psgi/etc)

-- ----------------------------------------------------------------------------
-- ToggleTerm (custom/plugins/toggleterm.lua)
-- ----------------------------------------------------------------------------
-- Open / close terminal:
--   <leader>tt            : Toggle terminal
--   <leader>tg            : Terminal #1
--   <leader>te            : Terminal #2
--
-- Inside terminal:
--   <Esc><Esc>        : leave terminal-mode → normal-mode
--
-- Notes:
-- - toggleterm creates a persistent terminal buffer
-- - closing == hiding, state is preserved
-- - you freely switch between code and terminal buffers
--
-- Typical workflow:
--   <leader>tt        → open terminal
--   work in shell
--   <Esc><Esc>        → normal-mode
--   <C-n/e/o/i>       → jump back to code window
--   <leader>tt        → return to terminal

-- ----------------------------------------------------------------------------
-- vim-test (custom/plugins/vim-test.lua)
-- ----------------------------------------------------------------------------
--   <leader>tn            : TestNearest
--   <leader>tf            : TestFile
--   <leader>ts            : TestSuite
--   <leader>tl            : TestLast
--   <leader>tv            : TestVisit

-- ----------------------------------------------------------------------------
-- Dadbod / DB UI (custom/plugins/dadbod.lua + custom/db_project_dadbod.lua)
-- ----------------------------------------------------------------------------
-- Commands:
--   :DB <dsn>             : connect (manual)
--   :DBUI / :DBUIToggle   : DB UI
--   :DBProjectReload      : (custom) reload project DB config (.env / config.yml / etc)
--
-- Completion:
--   vim-dadbod-completion is enabled for SQL filetypes (sql/mysql/plsql).

-- ----------------------------------------------------------------------------
-- Completion (nvim-cmp + LuaSnip)  [YOUR UPDATED MAPPINGS]
-- ----------------------------------------------------------------------------
-- Insert-mode (when completion menu is visible):
--   <C-Space>             : open completion menu
--   <C-t>                 : open completion menu (same as <C-Space>)
--   <C-g>                 : abort/close completion menu
--
--   <C-u>                 : select next completion item
--   <C-f>                 : select previous completion item
--
--   <CR>                  : confirm selection (select=true)
--   <Tab>                 : confirm selection if menu visible, else normal Tab
--
-- Snippet jumping (LuaSnip):
--   <C-n>                 : jump forward in snippet (if jumpable)
--   <C-e>                 : jump backward in snippet (if jumpable)

-- ----------------------------------------------------------------------------
-- Misc from custom/vimrc-cub.lua
-- ----------------------------------------------------------------------------
-- Normal:
--   [[                    : search backwards for Perl “sub …” (no desc)
--   ]]                    : search forwards for Perl “sub …” (no desc)
-- ============================================================================
