-- Ported ~/.vimrc@cubuanic
--
-- ============================================================================
-- Neovim init.lua (copy-paste ready)
-- Миграция твоего .vimrc -> nvim с учётом kickstart.nvim “идеологии”
--
-- Главные принципы (как ты просил):
-- - Leader один: <Space> (без алиасов на Tab/Space/, — алиасы закомментированы)
-- - Telescope вместо fzf/ctrlp/taglist/bufexplorer
-- - LuaSnip вместо UltiSnips (с “аналогом UltiSnipsEdit”)
-- - F9/S-F9/C-F9: форматтер/линтер “естественно” для nvim (conform + nvim-lint)
-- - Сессии “по-проектно” как у xolox/vim-session: persistence.nvim с авто-load по cwd
-- - nohlsearch на <Bslash><Bslash>
-- - Без твоих helper-функций feed/cmd_anywhere: никаких feedkeys/replace_termcodes/input()
--   (где нужно действие из Insert — выходим из insert через :stopinsert, делаем действие и при
--    необходимости возвращаемся :startinsert)
-- - По возможности оптимизируем маппинги (одна функция на несколько режимов),
--   но если “оставаться в Insert” критично — это уже требует feedkeys, и мы это сознательно НЕ делаем.
--
-- ВАЖНО:
-- Этот файл самодостаточный (bootstrap lazy.nvim). Если ты реально используешь готовый kickstart init.lua,
-- то правильнее вынести “всё ниже” в lua/custom/vimrc_migrated.lua и подключить require(...).
-- ============================================================================

-- ============================================================================
-- Options (глобальные, безопасны даже если текущий буфер = Lazy/help/etc.)
-- ============================================================================
vim.g.mapleader = ' '

-- Disable dynamic SQL completion (dbext) and keep only static keywords
-- This prevents:
--   SQLComplete:The dbext plugin must be loaded for dynamic SQL completion
vim.g.sql_complete_default_db = nil
vim.g.sql_complete_dbext = 0

vim.opt.backupdir = { vim.fn.expand '~/tmp' }
vim.opt.directory = { vim.fn.expand '~/tmp' }

vim.o.exrc = true
vim.o.secure = true

vim.opt.modeline = true
vim.opt.modelines = 5
vim.opt.updatetime = 1500
vim.opt.history = 5000

vim.opt.shiftround = true
vim.opt.backspace = { 'indent', 'eol', 'start' }

vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.showmatch = true
vim.opt.autowrite = true
vim.opt.hidden = true

vim.opt.foldenable = false
vim.opt.background = 'dark'
vim.opt.backupcopy = 'yes'
vim.opt.ruler = true
vim.opt.showcmd = true
vim.opt.laststatus = 2

-- В nvim это по сути всегда utf-8, но оставляем “как в vimrc”
vim.opt.encoding = 'utf-8'
vim.opt.fileencodings = { 'utf-8', 'default', 'latin1' }

vim.opt.listchars = { tab = '•·' }
vim.opt.list = false

-- tags — опция глобальная (и буферная тоже бывает как local-to-buffer в некоторых сценариях),
-- но set через vim.opt обычно ок; оставим тут.
vim.opt.tags = { '.tags~' }
vim.opt.shada:append 'r.git/'

-- spell (buffer-local)
vim.opt.spell = false
vim.opt.spelllang = ''
vim.opt.spellfile = vim.fn.expand '~/.vim/spell/local.utf-8.add'

-- ============================================================================
-- Buffer defaults (как “глобально” в vimrc, но правильно для nvim)
-- Применяем только к обычным файловым буферам
-- ============================================================================
local cbd = vim.api.nvim_create_augroup('cub_buffer_defaults', { clear = true })
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufReadPost' }, {
  group = cbd,
  callback = function()
    -- не трогаем special буферы: lazy, help, telescope, terminal и т.п.
    if vim.bo.buftype ~= '' then
      return
    end
    -- если вдруг буфер немодифицируемый — тоже не трогаем
    if not vim.bo.modifiable then
      return
    end

    -- табы/инденты (buffer-local)
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
    vim.bo.shiftwidth = 4
    vim.bo.expandtab = true
    vim.bo.smartindent = true

    -- кодировки (buffer-local)
    -- fileencoding задаём тут, иначе можно попасть на modifiable=off в special буфере
    vim.bo.fileencoding = 'utf-8'
  end,
})

-- ----------------------------------------------------------------------------
-- SQL omni completion fix for nvim-cmp + cmp-omni:
-- force STATIC completion (keywords) and avoid dbext requirement.
-- ----------------------------------------------------------------------------
vim.cmd [[
function! SqlCompleteKeywords(findstart, base) abort
  " Force static keyword completion (no dbext)
  let b:sql_compl_type = 'sqlKeyword'
  return sqlcomplete#Complete(a:findstart, a:base)
endfunction
]]

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'sql', 'mysql', 'plsql' },
  callback = function()
    -- Use wrapper omnifunc instead of sqlcomplete#Complete directly
    vim.bo.omnifunc = 'SqlCompleteKeywords'
  end,
})

-- ----------------------------------------------------------------------------
-- Filetype detection (из vimrc)
-- ----------------------------------------------------------------------------
vim.filetype.add {
  extension = {
    tt = 'tt2',
    tt2 = 'tt2',
    ttajax = 'tt2',
    tta = 'tt2',
    ta = 'tt2',
    mas = 'mason',
    phtml = 'perl',
    psgi = 'perl',
    ['pl-dist'] = 'perl',
    json = 'javascript',
    js = 'javascript',
    ['sh-dist'] = 'sh',
    logic = 'perlgem',
    tmpl = 'perlgem',
    mustache = 'mustache',
  },
  filename = { ['elinks.conf'] = 'elinks' },
}

-- ----------------------------------------------------------------------------
-- Leader aliases (закомментированы по требованию)
-- ----------------------------------------------------------------------------
-- Почему закомментировано: Leader один (Space). Алиасы часто создают конфликты.
-- ORIGINAL (.vimrc): nmap <Tab> <Leader>
-- ORIGINAL (.vimrc): nmap <Space> <Leader>
-- ORIGINAL (.vimrc): nmap , <Leader>
-- ORIGINAL (.vimrc): vmap <Space> <Leader>
-- ORIGINAL (.vimrc): vmap , <Leader>
-- vim.keymap.set({ "n", "v" }, ",", "<Leader>", { remap = true, silent = true })

-- ============================================================================
-- Global window navigation remap
-- Replace <C-h/j/k/l> with <C-n/e/o/i>
-- ============================================================================

-- Normal mode
vim.keymap.set('n', '<C-n>', '<C-w>h', { desc = 'Window left' })
vim.keymap.set('n', '<C-e>', '<C-w>k', { desc = 'Window up' })
vim.keymap.set('n', '<C-o>', '<C-w>j', { desc = 'Window down' })
vim.keymap.set('n', '<C-i>', '<C-w>l', { desc = 'Window right' })

-- Terminal mode (works with toggleterm.nvim and any :terminal)
vim.keymap.set('t', '<C-n>', [[<C-\><C-n><C-w>h]], { desc = 'Terminal window left' })
vim.keymap.set('t', '<C-e>', [[<C-\><C-n><C-w>k]], { desc = 'Terminal window up' })
vim.keymap.set('t', '<C-o>', [[<C-\><C-n><C-w>j]], { desc = 'Terminal window down' })
vim.keymap.set('t', '<C-i>', [[<C-\><C-n><C-w>l]], { desc = 'Terminal window right' })

-- ============================================================================
-- Resize windows (useful for terminal splits)
-- ============================================================================

vim.keymap.set('n', '<C-u>', '<C-w>+', { desc = 'Increase window height' })
vim.keymap.set('n', '<C-p>', '<C-w>-', { desc = 'Decrease window height' })

vim.keymap.set('n', '<C-S-e>', '<C-w>+', { desc = 'Increase window height' })
vim.keymap.set('n', '<C-S-o>', '<C-w>-', { desc = 'Decrease window height' })

vim.keymap.set('n', '<C-S-n>', '<C-w><', { desc = 'Decrease window width' })
vim.keymap.set('n', '<C-S-i>', '<C-w>>', { desc = 'Increase window width' })

-- ============================================================================
-- Terminal key passthrough (Tab, F-keys)
-- ============================================================================
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    local opts = { buffer = 0, silent = true }

    -- Tab → shell completion
    vim.keymap.set('t', '<Tab>', [[<Tab>]], opts)

    -- Function keys → shell (F1–F36)
    for i = 1, 36 do
      vim.keymap.set('t', '<F' .. i .. '>', '<F' .. i .. '>', opts)
    end
  end,
})

-- ----------------------------------------------------------------------------
-- Helpers (без feedkeys/input): только “чистые” vim.cmd / vim.cmd.normal
-- ----------------------------------------------------------------------------
local function feed(keys, mode)
  local term = vim.api.nvim_replace_termcodes(keys, true, false, true)
  vim.api.nvim_feedkeys(term, mode or 'n', false)
end

-- Команда, которая работает и в Normal, и в Insert (не выкидывает тебя из insert)
local function cmd_anywhere(cmd)
  if vim.fn.mode():match '^i' then
    feed('<C-o>:' .. cmd .. '<CR>', 'n')
  else
    vim.cmd(cmd)
  end
end

local function t_builtin()
  local ok, b = pcall(require, 'telescope.builtin')
  if ok then
    return b
  end
  return nil
end

local function ensure_parent_dir_for_current_buffer()
  local buf = vim.api.nvim_get_current_buf()
  local fname = vim.api.nvim_buf_get_name(buf)

  -- No name / special buffers
  if fname == nil or fname == '' then
    return true
  end
  -- Don't try to create dirs for non-file buffers (netrw, fugitive, etc.)
  if fname:match '^%a+://' then
    return true
  end

  local dir = vim.fn.fnamemodify(fname, ':h')
  if dir == nil or dir == '' or dir == '.' then
    return true
  end

  if vim.fn.isdirectory(dir) == 1 then
    return true
  end

  local msg = ("Directory doesn't exist:\n%s\n\nCreate it (including parents)?"):format(dir)
  local choice = vim.fn.confirm(msg, '&Yes\n&No', 2)
  if choice ~= 1 then
    return false
  end

  local ok, err = pcall(vim.fn.mkdir, dir, 'p')
  if not ok then
    vim.notify(('Failed to create directory:\n%s\n%s'):format(dir, tostring(err)), vim.log.levels.ERROR)
    return false
  end

  return true
end

local function is_telescope_active()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      local buf_type = vim.api.nvim_get_option_value('buftype', { buf = buf })
      local buf_name = vim.api.nvim_buf_get_name(buf)
      if buf_type == 'prompt' or buf_name:match 'Telescope' then
        return true
      end
    end
  end
  return false
end

-- Выполнить Ex-команду и в Insert тоже:
-- Мы сознательно не сохраняем Insert-mode (это требовало бы feedkeys).
local function ex_anywhere(cmd)
  if is_telescope_active() then
    vim.api.nvim_win_close(0, true)
  end

  local lower = cmd:lower()
  if lower == 'w' or lower == 'write' or lower:match '^w%s' or lower:match '^write%s' then
    if not ensure_parent_dir_for_current_buffer() then
      return
    end
  end

  if vim.fn.mode():match '^i' then
    vim.cmd 'stopinsert'
  end

  vim.cmd(cmd)
end

-- Выполнить normal-команду; в Insert выходим и (если нужно) возвращаемся
local function normal_anywhere(keys, return_to_insert)
  local was_insert = vim.fn.mode():match '^i' ~= nil
  if was_insert then
    vim.cmd 'stopinsert'
  end
  vim.cmd.normal { keys, bang = true }
  if was_insert and return_to_insert then
    vim.cmd 'startinsert'
  end
end

local function highlight_overlength(enable)
  vim.cmd 'highlight OverLength ctermbg=red'
  vim.cmd [[match OverLength /\%>120v.\+/]]
  if not enable then
    vim.cmd 'highlight clear OverLength'
    vim.cmd 'match none'
  end
end

local function add_tab_spaces_syntax()
  vim.cmd 'highlight SpecialKey ctermfg=DarkGray'
  local ft = vim.bo.filetype
  if ft == 'perl' or ft == 'ruby' or ft == 'javascript' then
    vim.cmd [[syn match ExtraWhitespace /[^\t]\zs\t\+/ containedin=ALL]]
    vim.cmd [[syn match ExtraWhitespace /\s\+$/ containedin=ALL]]
    vim.cmd [[syn match ExtraWhitespace / \+\t\s*/ containedin=ALL]]
    vim.cmd [[syn match ExtraWhitespace /\t\+ \s*/ containedin=ALL]]
    vim.cmd 'highlight ExtraWhitespace ctermbg=Red'
  end
end

local function next_window()
  local cur = vim.fn.winnr()
  local last = vim.fn.winnr '$'
  local neww = cur + 1
  if neww > last then
    neww = 1
  end
  vim.cmd(('silent %dwincmd w'):format(neww))
end

local function prev_window()
  local cur = vim.fn.winnr()
  local last = vim.fn.winnr '$'
  local neww = cur - 1
  if neww < 1 then
    neww = last
  end
  vim.cmd(('silent %dwincmd w'):format(neww))
end

local function update_tags()
  -- ORIGINAL (.vimrc): system('update-ctags >/dev/null 2>&1 &')
  vim.fn.jobstart({ 'sh', '-lc', 'update-ctags' }, { detach = true })
end

local function tagback_or_alternate()
  local ok = pcall(vim.cmd, 'pop')
  if not ok then
    vim.cmd 'silent normal! :e#<CR>'
  end
end

local function gf_or_tag()
  -- LSP definition -> gf -> tag
  local params = vim.lsp.util.make_position_params(0, 'utf-8')

  local has_def = false
  for _, c in ipairs(vim.lsp.get_clients { bufnr = 0 }) do
    if c.supports_method and c:supports_method 'textDocument/definition' then
      has_def = true
      break
    end
  end

  if has_def then
    local resp = vim.lsp.buf_request_sync(0, 'textDocument/definition', params, 250)
    local found = false
    if resp then
      for _, r in pairs(resp) do
        local res = r.result
        if res and ((type(res) == 'table' and #res > 0) or (type(res) == 'table' and res.uri)) then
          found = true
          break
        end
      end
    end
    if found then
      vim.lsp.buf.definition()
      return
    end
  end

  local cfile = vim.fn.expand '<cfile>'
  if cfile ~= '' and vim.fn.filereadable(cfile) == 1 then
    vim.cmd.normal { 'gf', bang = true }
    -- vim.cmd.edit(cfile)
    return
  end

  vim.cmd.normal { '<C-]>', bang = true }
end

vim.api.nvim_create_user_command('UpdateTags', update_tags, {})
vim.api.nvim_create_user_command('GFOrTag', gf_or_tag, {})
vim.api.nvim_create_user_command('TagBackOrAlternate', tagback_or_alternate, {})

-- ----------------------------------------------------------------------------
-- Autocmds (из MyBufEnter + Syntax *)
-- ----------------------------------------------------------------------------
local cvm = vim.api.nvim_create_augroup('cub_vimrc_migrated', { clear = true })

vim.api.nvim_create_autocmd({ 'BufEnter', 'FileType' }, {
  group = cvm,
  callback = function()
    local ft = vim.bo.filetype
    if ft == 'perl' then
      -- ORIGINAL (.vimrc): setlocal iskeyword+=:
      vim.opt_local.iskeyword:append ':'

      highlight_overlength(true)
      add_tab_spaces_syntax()

      -- ORIGINAL (.vimrc): perl custom syntax (частично)
      vim.cmd [[
        syn match perlCustomStatement1 "\<\%(_[a-z0-9_]\+\)\>\%((\?\)\@="
        syn match perlCustomStatement1 "\<\%([a-z0-9]\+_[a-z0-9_]\+\)\>\%((\?\)\@="
      ]]
    elseif ft == 'javascript' then
      add_tab_spaces_syntax()
    elseif ft == 'gitcommit' then
      pcall(vim.fn.setpos, '.', { 0, 1, 1, 0 })
    end
  end,
})

vim.api.nvim_create_autocmd('Syntax', {
  group = cvm,
  callback = function()
    add_tab_spaces_syntax()
  end,
})

vim.api.nvim_create_autocmd('BufWritePost', {
  group = cvm,
  callback = function()
    update_tags()
  end,
})

-- Perl buffer-local maps from vimrc
-- ORIGINAL (.vimrc):
--   map <buffer> [[ ?\(sub\s.*\)\@<={<CR>
--   map <buffer> ]] ?\(^\s*\)\@<=};*$<CR>
vim.api.nvim_create_autocmd('FileType', {
  group = cvm,
  pattern = 'perl',
  callback = function()
    vim.keymap.set('n', '[[', [[?\(sub\s.*\)\@<={<CR>]], { buffer = true, silent = true, desc = 'Perl: prev sub' })
    vim.keymap.set('n', ']]', [[?\(^\s*\)\@<=};*$<CR>]], { buffer = true, silent = true, desc = 'Perl: next end block' })
  end,
})

-- ----------------------------------------------------------------------------
-- LuaSnip “UltiSnipsEdit” аналог
-- ----------------------------------------------------------------------------
local function open_luasnip_file(ft)
  local base = vim.fn.stdpath 'config' .. '/lua/snippets'
  local path = base .. '/' .. ft .. '.lua'
  vim.fn.mkdir(base, 'p')
  ex_anywhere('edit ' .. vim.fn.fnameescape(path))
end

local function luasnip_edit_current_ft()
  local ft = vim.bo.filetype
  if not ft or ft == '' then
    ft = 'all'
  end
  open_luasnip_file(ft)
end

-- ----------------------------------------------------------------------------
-- Mirror / Reverse (из vimrc)
-- ----------------------------------------------------------------------------
vim.api.nvim_create_user_command('Mirror', function(opts)
  local l1, l2 = opts.line1, opts.line2
  for l = l1, l2 do
    local s = vim.fn.getline(l)
    local chars = vim.fn.split(s, [[\zs]])
    chars = vim.fn.reverse(chars)
    vim.fn.setline(l, table.concat(chars, ''))
  end
end, { range = true })

vim.api.nvim_create_user_command('Reverse', function(opts)
  local l1, l2 = opts.line1, opts.line2
  local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)
  local rev = {}
  for i = #lines, 1, -1 do
    table.insert(rev, lines[i])
  end
  vim.api.nvim_buf_set_lines(0, l1 - 1, l2, false, rev)
end, { range = true })

-- ----------------------------------------------------------------------------
-- Keymaps (оптимизированные)
-- ----------------------------------------------------------------------------
local function map(mode, lhs, rhs, desc, opts)
  opts = opts or {}
  opts.silent = (opts.silent ~= false)
  opts.desc = desc
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Универсальная функция: повесить одно действие на несколько клавиш
local function map_multi(modes, keys, action, desc)
  for _, key in ipairs(keys) do
    vim.keymap.set(modes, key, action, {
      silent = true,
      desc = desc,
    })
  end
end

-- ============================================================================
-- F1: toggle :only with proper restore via temporary session
-- (winrestcmd() restores sizes, not layout; session restores layout)
-- ============================================================================
do
  local only_session = nil

  local function toggle_only_restore()
    local wins = vim.fn.winnr '$'

    if wins > 1 then
      -- Save session (layout) and collapse to one window
      only_session = vim.fn.stdpath 'state' .. '/only-toggle.vim'

      -- Ensure session can restore terminal splits too
      local so = vim.o.sessionoptions
      if not so:match 'terminal' then
        vim.o.sessionoptions = so .. ',terminal'
      end

      -- Write session for current state
      vim.cmd('silent! mksession! ' .. vim.fn.fnameescape(only_session))

      -- Restore user's sessionoptions back (keep config clean)
      vim.o.sessionoptions = so

      -- Collapse
      ex_anywhere 'only'
      return
    end

    -- wins == 1: restore layout from saved session
    if only_session and vim.fn.filereadable(only_session) == 1 then
      vim.cmd('silent! source ' .. vim.fn.fnameescape(only_session))
      vim.fn.delete(only_session)
      only_session = nil
    end
  end

  -- ORIGINAL (.vimrc): nmap/imap <F1> :only
  map({ 'n', 'i' }, '<F1>', toggle_only_restore, 'Only / restore window layout')
end

-- ORIGINAL (.vimrc): nmap/imap <S-F1> :copen
map_multi({ 'n', 'i' }, { '<S-F1>', '<F13>' }, function()
  ex_anywhere 'copen'
end, 'Quickfix: открыть')

-- ORIGINAL (.vimrc): nmap/imap <C-F1> :close
map_multi({ 'n', 'i' }, { '<C-F1>', '<F25>' }, function()
  ex_anywhere 'close'
end, 'Окно: закрыть')

-- ORIGINAL (.vimrc): nmap/imap <F2> :w
map({ 'n', 'i' }, '<F2>', function()
  ex_anywhere 'write'
end, 'Сохранить')

-- ORIGINAL (.vimrc): nmap/imap <S-F2> :wa
map_multi({ 'n', 'i' }, { '<S-F2>', '<F14>' }, function()
  ex_anywhere 'wall'
end, 'Сохранить все')

-- UltiSnipsEdit -> LuaSnip edit file
-- ORIGINAL (.vimrc):
--   vmap <F2> y<C-O>:UltiSnipsEdit<CR>
--   vmap <C-F2> d<C-O>:UltiSnipsEdit<CR>
--   imap <C-F2> <C-O>:UltiSnipsEdit<CR>
--   nmap <C-F2> :UltiSnipsEdit<CR>
map('v', '<F2>', function()
  normal_anywhere('y', false)
  luasnip_edit_current_ft()
end, 'LuaSnip: открыть сниппеты (yank selection)')

map_multi('v', { '<C-F2>', '<F26>' }, function()
  normal_anywhere('d', false)
  luasnip_edit_current_ft()
end, 'LuaSnip: открыть сниппеты (delete selection)')

map_multi({ 'n', 'i' }, { '<C-F2>', '<F26>' }, function()
  luasnip_edit_current_ft()
end, 'LuaSnip: открыть сниппеты для текущего ft')

-- Utl plugin — не переносим
-- ORIGINAL (.vimrc): map/imap <F3> :Utl
-- (плагина нет в kickstart)

-- ORIGINAL (.vimrc): nmap/imap <S-F3> :call TogilleBOM()
map_multi({ 'n', 'i' }, { '<S-F3>', '<F15>' }, function()
  vim.bo.bomb = not vim.bo.bomb
end, 'Переключить BOM')

-- ORIGINAL (.vimrc): nmap/imap <C-F3> :set list!
map_multi({ 'n', 'i' }, { '<C-F3>', '<F27>' }, function()
  vim.opt.list = not vim.opt.list:get()
end, 'Listchars: on/off')

-- TagList -> Telescope symbols/tags
-- ORIGINAL (.vimrc): nmap/imap <F4> :TlistOpen
map({ 'n', 'i' }, '<F4>', function()
  local b = t_builtin()
  if b then
    b.lsp_document_symbols()
  end
end, 'Symbols: document (Telescope вместо TagList)')

-- ORIGINAL (.vimrc): nmap/imap <S-F4> :TlistToggle
map_multi({ 'n', 'i' }, { '<S-F4>', '<F16>' }, function()
  local b = t_builtin()
  if b then
    b.tags()
  end
end, 'Tags (ctags) (Telescope)')

-- BufExplorer -> Telescope buffers
-- ORIGINAL (.vimrc): nmap/imap <F5> :BufExplorer
map({ 'n', 'i' }, '<F5>', function()
  local b = t_builtin()
  if b then
    b.oldfiles {
      cwd_only = true,
      previewer = false,
    }
  end
end, 'Buffers (Telescope)')

-- fugitive :Gblame -> gitsigns blame (visual F5)
-- ORIGINAL (.vimrc): vmap <F5> :Gblame
map('v', '<F5>', function()
  local ok, gs = pcall(require, 'gitsigns')
  if ok then
    gs.blame_line { full = true }
  end
end, 'Git blame (gitsigns)')

-- MultipleSearch -> Telescope current buffer + reset
-- ORIGINAL (.vimrc): nmap/imap <C-F5> :Search
map_multi({ 'n', 'i' }, { '<C-F5>', '<F29>' }, function()
  local b = t_builtin()
  if b then
    b.current_buffer_fuzzy_find()
  end
end, 'Search in buffer (Telescope)')

-- ORIGINAL (.vimrc): nmap/imap <S-F5> :SearchReset
map_multi({ 'n', 'i' }, { '<S-F5>', '<F17>' }, function()
  vim.fn.setreg('/', '')
  vim.cmd 'nohlsearch'
end, 'SearchReset (очистить поиск + nohl)')

-- fzf :Buffers/:Tags -> Telescope
-- ORIGINAL (.vimrc): nmap/imap <F6> :Buffers
map({ 'n', 'i' }, '<F6>', function()
  local b = t_builtin()
  if b then
    b.buffers()
  end
end, 'Telescope: buffers')

-- ORIGINAL (.vimrc): nmap/imap <S-F6> :Tags
map_multi({ 'n', 'i' }, { '<S-F6>', '<F18>' }, function()
  local b = t_builtin()
  if b then
    b.tags()
  end
end, 'Telescope: tags')

-- ORIGINAL (.vimrc): nmap/imap <C-F6> :e#
map_multi({ 'n', 'i' }, { '<C-F6>', '<F30>' }, function()
  ex_anywhere 'edit #'
end, 'Предыдущий файл (e#)')

-- ORIGINAL (.vimrc): nmap/imap <F7> NextWindow
map({ 'n', 'i' }, '<F7>', function()
  next_window()
end, 'Окна: следующее (циклом)')

-- ORIGINAL (.vimrc): nmap/imap <F8> PrevWindow
map({ 'n', 'i' }, '<F8>', function()
  prev_window()
end, 'Окна: предыдущее (циклом)')

-- ORIGINAL (.vimrc): map/imap <C-F7> :cp
map_multi({ 'n', 'i' }, { '<C-F7>', '<F31>' }, function()
  ex_anywhere 'cp'
end, 'Quickfix: prev')

-- ORIGINAL (.vimrc): map/imap <C-F8> :cn
map_multi({ 'n', 'i' }, { '<C-F8>', '<F32>' }, function()
  ex_anywhere 'cn'
end, 'Quickfix: next')

-- ORIGINAL (.vimrc): map/imap <S-F7> :bp
map_multi({ 'n', 'i' }, { '<S-F7>', '<F19>' }, function()
  ex_anywhere 'bp'
end, 'Буфер: предыдущий')

-- ORIGINAL (.vimrc): map/imap <S-F8> :bn
map_multi({ 'n', 'i' }, { '<S-F8>', '<F20>' }, function()
  ex_anywhere 'bn'
end, 'Буфер: следующий')

-- F9 / S-F9 / C-F9 “естественно” для nvim:
-- F9 -> formatter (conform/perltidy)
-- S-F9 -> linter (nvim-lint/perlcritic)
-- C-F9 -> format + save + buffers
map({ 'n', 'i' }, '<F9>', function()
  if vim.fn.mode():match '^i' then
    vim.cmd 'stopinsert'
  end
  local ok, conform = pcall(require, 'conform')
  if ok then
    conform.format { async = false, lsp_fallback = true }
  else
    vim.lsp.buf.format { async = false }
  end
end, 'Format (conform/perltidy)')

-- TODO: delete?
-- map({ "n", "i" }, "<S-F9>", function()
--   if vim.fn.mode():match("^i") then vim.cmd("stopinsert") end
--   local ok, lint = pcall(require, "lint")
--   if ok then lint.try_lint() end
-- end, "Lint (nvim-lint/perlcritic)")

map_multi({ 'n', 'i' }, { '<C-F9>', '<F33>' }, function()
  if vim.fn.mode():match '^i' then
    vim.cmd 'stopinsert'
  end
  local ok, conform = pcall(require, 'conform')
  if ok then
    conform.format { async = false, lsp_fallback = true }
  end
  vim.cmd 'write'
  local b = t_builtin()
  if b then
    b.buffers()
  end
end, 'Format + save + buffers')

-- ORIGINAL (.vimrc): nmap/imap <F10> :qa
map({ 'n', 'i' }, '<F10>', function()
  ex_anywhere 'qa'
end, 'Выйти', { noremap = true })

-- ORIGINAL (.vimrc): nmap/imap <S-F10> :wqa
map_multi({ 'n', 'i' }, { '<S-F10>', '<F22>' }, function()
  ex_anywhere 'wqa'
end, 'Сохранить и выйти')

-- ORIGINAL (.vimrc): nmap/imap <C-F10> :qa!
map_multi({ 'n', 'i' }, { '<C-F10>', '<F34>' }, function()
  ex_anywhere 'qa!'
end, 'Выйти без сохранения')

-- SessionOpen -> persistence
-- ORIGINAL (.vimrc): nmap <S-F11> :SessionOpen elc
-- ORIGINAL (.vimrc): nmap <S-F12> :SessionOpen default
map_multi('n', { '<S-F11>', '<F23>' }, function()
  local ok, p = pcall(require, 'persistence')
  if ok then
    p.load()
  end
end, 'Session: load (persistence)')

map_multi('n', { '<S-F12>', '<F24>' }, function()
  local ok, p = pcall(require, 'persistence')
  if ok then
    p.select()
  end
end, 'Session: select (persistence)')

-- UpdateTags
-- ORIGINAL (.vimrc): nmap/imap <C-F12> :call UpdateTags()
map_multi({ 'n', 'i' }, { '<C-F12>', '<F36>' }, function()
  update_tags()
end, 'UpdateTags')
-- raw-seq убран: нужен только если терминал не умеет <C-F12> (у тебя сейчас клавиши норм приходят)

-- VNC workaround
-- ORIGINAL (.vimrc): nmap/imap <F12> :qa
map({ 'n', 'i' }, '<F12>', function()
  ex_anywhere 'qa'
end, 'Выйти (F12, как в vimrc для VNC)')

-- ========== Alt+Arrows window resize ==========
-- ORIGINAL (.vimrc): map <A-Up>/<A-Down>/<A-Left>/<A-Right> <C-W>-/+/</>
map('n', '<A-Up>', '<C-w>-', 'Окно: меньше высота')
map('n', '<A-Down>', '<C-w>+', 'Окно: больше высота')
map('n', '<A-Left>', '<C-w><', 'Окно: меньше ширина')
map('n', '<A-Right>', '<C-w>>', 'Окно: больше ширина')

-- ========== Non-functional keys / handy stuff ==========

-- NERDTreeToggle заменяем на “идеологичный” toggle: neo-tree/oil/Ex
-- ORIGINAL (.vimrc): nmap/imap <C-G> :NERDTreeToggle
map({ 'n', 'i' }, '<C-G>', function()
  if vim.fn.mode():match '^i' then
    vim.cmd 'stopinsert'
  end

  local ok_neotree, neotree = pcall(require, 'neo-tree.command')
  if ok_neotree then
    neotree.execute { toggle = true, dir = vim.uv.cwd() }
    return
  end

  local ok_oil = pcall(require, 'oil')
  if ok_oil then
    vim.cmd 'Oil'
    return
  end

  vim.cmd 'Ex'
end, 'File tree toggle (neo-tree/oil/Ex)')

-- Yank/Paste в определённый регистр (как в vimrc)
-- В Vim “встроенной Lua-функции yank в регистр” нет: yank — это оператор, поэтому
-- самый естественный способ — normal-команды с префиксом регистра.
-- Мы делаем это через vim.cmd.normal() (без feedkeys).
-- workman-based -> Y/K works with reg J, N/L with reg F
-- ORIGINAL (.vimrc): nmap/vmap/imap <C-Y> "fy
map('n', '<C-Y>', function()
  vim.cmd.normal { [["jy]], bang = true }
end, 'Yank -> регистр "j"')
map('v', '<C-Y>', function()
  vim.cmd.normal { [["jy]], bang = true }
end, 'Yank -> регистр "j" (visual)')
map('i', '<C-Y>', function()
  normal_anywhere([["jy]], true)
end, 'Yank -> регистр "j" (insert)')

-- ORIGINAL (.vimrc): nmap/imap <C-K> "fP
map('n', '<C-K>', function()
  if vim.fn.getreg 'j' == '' then
    return
  end
  vim.cmd.normal { [["jP]], bang = true }
end, 'Paste(before) из регистра "j"')
map('i', '<C-K>', function()
  if vim.fn.getreg 'j' == '' then
    return
  end
  normal_anywhere([["jP]], true)
end, 'Paste(before) из регистра "j" (insert)')

-- ORIGINAL (.vimrc): nmap/vmap/imap <C-N> "uy
map('n', '<C-N>', function()
  vim.cmd.normal { [["fy]], bang = true }
end, 'Yank -> регистр "f"')
map('v', '<C-N>', function()
  vim.cmd.normal { [["fy]], bang = true }
end, 'Yank -> регистр "f" (visual)')
map('i', '<C-N>', function()
  normal_anywhere([["fy]], true)
end, 'Yank -> регистр "f" (insert)')

-- ORIGINAL (.vimrc): nmap/imap <C-L> "uP
map('n', '<C-L>', function()
  if vim.fn.getreg 'f' == '' then
    return
  end
  vim.cmd.normal { [["fP]], bang = true }
end, 'Paste(before) из регистра "f"')
map('i', '<C-L>', function()
  if vim.fn.getreg 'f' == '' then
    return
  end
  normal_anywhere([["fP]], true)
end, 'Paste(before) из регистра "f" (insert)')

-- C-* : FufTagWithCursorWord (плагина нет) -> Telescope tags с подстановкой слова или LSP def
-- ORIGINAL (.vimrc): nmap/imap <C-*> :FufTagWithCursorWord
map({ 'n', 'i' }, '<C-*>', function()
  if vim.fn.mode():match '^i' then
    vim.cmd 'stopinsert'
  end
  local b = t_builtin()
  if b then
    b.tags { default_text = vim.fn.expand '<cword>' }
  else
    vim.lsp.buf.definition()
  end
end, 'Tag with cursor word (Telescope/LSP)')

vim.keymap.set('n', '<leader>gl', function()
  local b = t_builtin()
  if b then
    b.live_grep { default_text = vim.fn.expand '<cword>' }
  end
end, { desc = 'live_grep current word' })

vim.keymap.set('v', '<leader>sw', function()
  local b = t_builtin()
  if b then
    b.grep_string { search = vim.fn.getreg '/' }
  end
end, { desc = 'grep visual selection' })

vim.keymap.set('n', '<leader>et', function()
  local trust_file = vim.fn.stdpath 'state' .. '/trust'
  if vim.fn.filereadable(trust_file) == 0 then
    vim.notify('Trust file not found: ' .. trust_file, vim.log.levels.WARN)
    return
  end
  vim.cmd('edit ' .. vim.fn.fnameescape(trust_file))
end, { desc = 'Edit trust database' })

-- TagBack/GFOrTag
-- ORIGINAL (.vimrc): nmap <BS> :call TagBack_or_Alternate()
map('n', '<BS>', tagback_or_alternate, 'Tag back / alternate')
-- ORIGINAL (.vimrc): nmap <Enter> :call GF_or_Tag()
map('n', '<CR>', gf_or_tag, 'LSP def -> gf -> tag')

-- <Space> -> PageDown (замена) — закомментить по требованию
-- ORIGINAL (.vimrc): nmap <silent> <Space> <PageDown>
-- map("n", "<Space>", "<PageDown>", "PageDown")

-- Ctrl-Up/Down: gk/gj (перемещение по экранным строкам)
-- ORIGINAL (.vimrc): nmap <C-Up> gk ; nmap <C-Down> gj ; imap ... <C-O>gk/gj
-- Без feedkeys мы делаем: stopinsert -> normal -> startinsert
map('n', '<C-Up>', function()
  vim.cmd.normal { 'gk', bang = true }
end, 'Вверх по экранным строкам')
map('n', '<C-Down>', function()
  vim.cmd.normal { 'gj', bang = true }
end, 'Вниз по экранным строкам')
map('i', '<C-Up>', function()
  normal_anywhere('gk', true)
end, 'Вверх по экранным строкам (insert)')
map('i', '<C-Down>', function()
  normal_anywhere('gj', true)
end, 'Вниз по экранным строкам (insert)')

-- Mirror/Reverse visual
-- ORIGINAL (.vimrc): vmap <Leader>m :Mirror<CR>
-- ORIGINAL (.vimrc): vmap <Leader>r :Reverse<CR>
map('v', '<Leader>m', ':Mirror<CR>', 'Mirror (visual)', { silent = false })
map('v', '<Leader>r', ':Reverse<CR>', 'Reverse (visual)', { silent = false })

-- nohlsearch (требование: <Bslash><Bslash>)
-- ORIGINAL (.vimrc): nmap <Leader><Leader> :nohl
map('n', '<Bslash><Bslash>', '<cmd>nohlsearch<CR>', 'Убрать подсветку поиска')

-- OverLength
-- ORIGINAL (.vimrc): nmap <Leader>y ... yes ; nmap <Leader>n ... no
map('n', '<Leader>y', function()
  highlight_overlength(true)
end, 'OverLength: ON')
map('n', '<Leader>n', function()
  highlight_overlength(false)
end, 'OverLength: OFF')

-- Marks shortcuts (Tab-f/u/p/$ and jumps) — оставляем как было
-- ORIGINAL (.vimrc): nmap <Tab>f mF ... etc
map('n', '<Tab>f', 'mF', 'Mark: поставить F')
map('n', '<Tab>u', 'mU', 'Mark: поставить U')
map('n', '<Tab>p', 'mP', 'Mark: поставить P')
map('n', '<Tab>;', 'mA', 'Mark: поставить A')
map('n', '<Tab>n', "'F", 'Jump: к mark F')
map('n', '<Tab>e', "'U", 'Jump: к mark U')
map('n', '<Tab>o', "'P", 'Jump: к mark P')
map('n', '<Tab>i', "'A", 'Jump: к mark A')

-- Indent shortcuts (< >)
-- ORIGINAL (.vimrc): nmap < << ; nmap > >> ; vmap < <gv ; vmap > >gv ; vmap <Tab>/<S-Tab>
map('n', '<', '<<', 'Indent: строка влево')
map('n', '>', '>>', 'Indent: строка вправо')
map('v', '<', '<gv', 'Indent: блок влево (остаться)')
map('v', '>', '>gv', 'Indent: блок вправо (остаться)')
map('v', '<Tab>', '>gv', 'Indent: блок вправо (Tab)')
map('v', '<S-Tab>', '<gv', 'Indent: блок влево (S-Tab)')

-- Registers list ("" )
-- ORIGINAL (.vimrc): nnoremap "" :registers "0123456789abcdefghijklmnopqrstuvwxyz*+.<CR>
map('n', [[""]], function()
  vim.cmd [[registers "0123456789abcdefghijklmnopqrstuvwxyz*+.]]
end, 'Показать регистры')

-- Русская “№” -> “#”
-- ORIGINAL (.vimrc): imap № #
-- map("i", "№", "#", "№ -> #")

-- ----------------------------------------------------------------------------
-- Session handy shortcuts (как “вокруг vim-session”, но под persistence.nvim)
-- ----------------------------------------------------------------------------
map('n', '<Leader>ps', function()
  local ok, p = pcall(require, 'persistence')
  if ok then
    p.save()
  end
end, 'Session: save')

map('n', '<Leader>pl', function()
  local ok, p = pcall(require, 'persistence')
  if ok then
    p.load()
  end
end, 'Session: load')

map('n', '<Leader>pc', function()
  local ok, p = pcall(require, 'persistence')
  if ok then
    p.select()
  end
end, 'Session: choose')

-- vim: ts=2 sts=2 sw=2 et
