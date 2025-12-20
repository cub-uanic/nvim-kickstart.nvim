-- Ported ~/.vimrc@cubuanic
--

-- ============================================================================
-- init.lua (Neovim) — миграция из твоего ~/.vimrc под kickstart.nvim
--
-- Куда положить:
--   1) Самый простой вариант: вставь ВЕСЬ этот файл в ~/.config/nvim/init.lua
--      (но если ты уже используешь kickstart.nvim как готовый init.lua — см. вариант 2)
--   2) Рекомендуемый под kickstart: создай файл
--        ~/.config/nvim/lua/custom/vimrc_migrated.lua
--      и в конце kickstart init.lua добавь:
--        require('custom.vimrc_migrated')
--
-- Принципы:
--   - Vundle/старые плагины не переносим (kickstart = lazy.nvim)
--   - fzf/ctrlp/taglist/nerdtree -> Telescope/встроенное
--   - TidyFile/LintFile реализуем “по-nvim” (через stdin/stdout, без блокировки)
--   - Всё, что решили не переносить, оставляем закомментированным + почему
--   - Для перенесённого — комментарий “почему/как” + оригинальная строка из .vimrc
-- ============================================================================

local VIMRC = {}

-- ---------------------------------------------------------------------------
-- (0) Вещи из .vimrc, которые в Neovim/kickstart НЕ нужны / неуместны
-- ---------------------------------------------------------------------------

-- Почему удалено: kickstart.nvim использует lazy.nvim, Vundle не нужен.
-- ORIGINAL (.vimrc): set rtp+=~/.vim/bundle/Vundle.vim
-- ORIGINAL (.vimrc): call vundle#begin()
-- ORIGINAL (.vimrc): Plugin 'VundleVim/Vundle.vim'
-- ORIGINAL (.vimrc): call vundle#end()

-- Почему удалено: filetype off / filetype on/plugin/indent в kickstart уже включены.
-- ORIGINAL (.vimrc): filetype off
-- ORIGINAL (.vimrc): filetype on
-- ORIGINAL (.vimrc): filetype plugin on
-- ORIGINAL (.vimrc): filetype indent on
-- ORIGINAL (.vimrc): filetype plugin indent on

-- Почему удалено: set nocompatible в Neovim не имеет смысла.
-- ORIGINAL (.vimrc): set nocompatible

-- Почему удалено: exrc+secure — потенциальная дырка безопасности (локальные .exrc/.vimrc в проекте).
-- ORIGINAL (.vimrc): set exrc
-- ORIGINAL (.vimrc): set secure

-- Почему удалено: set ttyfast в Neovim не актуален.
-- ORIGINAL (.vimrc): set ttyfast

-- Почему удалено: кастомный statusline из vimrc будет конфликтовать с lualine (в kickstart он обычно есть).
-- ORIGINAL (.vimrc): set statusline=...%{GetAdditionalStatusLineInfo()}...

-- Почему удалено: GUI-опции gvim (go/guifont/has('gui_running')) не для терминального nvim.
-- ORIGINAL (.vimrc): set go-=m go-=T go-=r
-- ORIGINAL (.vimrc): set guifont=Droid\ Sans\ Mono\ 14
-- ORIGINAL (.vimrc): if has('gui_running') | colorscheme murphy | endif

-- ---------------------------------------------------------------------------
-- (1) Глобальные переменные
-- ---------------------------------------------------------------------------

-- Почему и как переносим: использовалось для host-specific настроек/тайтла.
-- ORIGINAL (.vimrc): let g:user_host = $USER."@".hostname()
vim.g.user_host = (vim.env.USER or "user") .. "@" .. (vim.fn.hostname() or "host")

-- Почему и как переносим: это твои “публичные” переменные для perl-инструментов/шаблонов.
-- ORIGINAL (.vimrc): let g:Perl_AuthorName = 'Oleg Kostyuk'
-- ORIGINAL (.vimrc): let g:Perl_AuthorRef  = 'cub-uanic'
-- ORIGINAL (.vimrc): let g:Perl_Email      = 'cub.uanic@gmail.com'
-- ORIGINAL (.vimrc): let g:Perl_Company    = ''
-- ORIGINAL (.vimrc): let g:Perl_Debugger   = "ptkdb"
vim.g.Perl_AuthorName = "Oleg Kostyuk"
vim.g.Perl_AuthorRef  = "cub-uanic"
vim.g.Perl_Email      = "cub.uanic@gmail.com"
vim.g.Perl_Company    = ""
vim.g.Perl_Debugger   = "ptkdb"

-- ---------------------------------------------------------------------------
-- (2) Опции (set ...)
-- ---------------------------------------------------------------------------

-- ORIGINAL (.vimrc): set backupdir=~/tmp
vim.opt.backupdir = { vim.fn.expand("~/tmp") }

-- ORIGINAL (.vimrc): set dir=~/tmp
vim.opt.directory = { vim.fn.expand("~/tmp") }

-- ORIGINAL (.vimrc): set modeline
-- ORIGINAL (.vimrc): set modelines=5
vim.opt.modeline = true
vim.opt.modelines = 5

-- ORIGINAL (.vimrc): set updatetime=1500
vim.opt.updatetime = 1500

-- ORIGINAL (.vimrc): set history=5000
vim.opt.history = 5000

-- ORIGINAL (.vimrc): set tabstop=4
-- ORIGINAL (.vimrc): set softtabstop=4
-- ORIGINAL (.vimrc): set shiftwidth=4
-- ORIGINAL (.vimrc): set shiftround
-- ORIGINAL (.vimrc): set expandtab
-- ORIGINAL (.vimrc): set smartindent
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.smartindent = true

-- ORIGINAL (.vimrc): set backspace=indent,eol,start
vim.opt.backspace = { "indent", "eol", "start" }

-- ORIGINAL (.vimrc): set incsearch
-- ORIGINAL (.vimrc): set hlsearch
-- ORIGINAL (.vimrc): set ignorecase
-- ORIGINAL (.vimrc): set smartcase
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- ORIGINAL (.vimrc): set showmatch
-- ORIGINAL (.vimrc): set autowrite
-- ORIGINAL (.vimrc): set hidden
vim.opt.showmatch = true
vim.opt.autowrite = true
vim.opt.hidden = true

-- Folding: в vimrc было выключено
-- ORIGINAL (.vimrc): set nofoldenable
vim.opt.foldenable = false

-- Цвет/фон
-- ORIGINAL (.vimrc): set background=dark
vim.opt.background = "dark"

-- Почему оставлено комментом: kickstart часто управляет colorscheme сам.
-- Если хочешь именно elflord — раскомментируй.
-- ORIGINAL (.vimrc): colorscheme elflord
-- vim.cmd.colorscheme("elflord")

-- ORIGINAL (.vimrc): highlight PmenuSel ctermfg=yellow ctermbg=magenta
-- Почему оставлено комментом: в nvim лучше не ломать тему глобальными hi, но можно оставить при желании.
-- vim.cmd("highlight PmenuSel ctermfg=yellow ctermbg=magenta")

-- ORIGINAL (.vimrc): set backupcopy=yes
vim.opt.backupcopy = "yes"

-- ORIGINAL (.vimrc): set ruler
-- ORIGINAL (.vimrc): set showcmd
-- ORIGINAL (.vimrc): set laststatus=2
vim.opt.ruler = true
vim.opt.showcmd = true
vim.opt.laststatus = 2

-- Кодировки (в nvim обычно уже utf-8, но оставим явно как в vimrc)
-- ORIGINAL (.vimrc): set encoding=utf-8
-- ORIGINAL (.vimrc): set fileencoding=utf-8
-- ORIGINAL (.vimrc): set fileencodings=utf-8,default,latin1
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.fileencodings = { "utf-8", "default", "latin1" }

-- Табики видимые, но по умолчанию выключено
-- ORIGINAL (.vimrc): set listchars=tab:•·
-- ORIGINAL (.vimrc): set nolist
vim.opt.listchars = { tab = "•·" }
vim.opt.list = false

-- Русская раскладка (работает только если есть keymap файл; чаще сейчас делают иначе)
-- ORIGINAL (.vimrc): set keymap=russian-jcukenwin
-- ORIGINAL (.vimrc): set iminsert=0
-- ORIGINAL (.vimrc): set imsearch=0
vim.opt.keymap = "russian-jcukenwin"
vim.opt.iminsert = 0
vim.opt.imsearch = 0

-- Completion (в kickstart обычно nvim-cmp, но harmless оставить)
-- ORIGINAL (.vimrc): set complete=.,b,t,k
-- ORIGINAL (.vimrc): set completeopt=menu,preview,longest
vim.opt.complete = { ".", "b", "t", "k" }
vim.opt.completeopt = { "menu", "preview", "longest" }

-- Perl syntax flags (если нужны — они не вредят)
-- ORIGINAL (.vimrc): let perl_include_pod = 1
-- ORIGINAL (.vimrc): let perl_extended_vars = 1
-- ORIGINAL (.vimrc): let perl_moose_stuff = 1
-- ORIGINAL (.vimrc): let perl_sync_dist = 150
vim.g.perl_include_pod = 1
vim.g.perl_extended_vars = 1
vim.g.perl_moose_stuff = 1
vim.g.perl_sync_dist = 150

-- Spell
-- ORIGINAL (.vimrc): set spell spelllang=
-- ORIGINAL (.vimrc): set nospell
-- ORIGINAL (.vimrc): set spellfile=~/.vim/spell/local.utf-8.add
vim.opt.spell = false
vim.opt.spelllang = { "" }
vim.opt.spellfile = vim.fn.expand("~/.vim/spell/local.utf-8.add")

-- Ack grep
-- ORIGINAL (.vimrc): set grepprg=ack\ -a
vim.opt.grepprg = "ack -a"

-- Tags
-- ORIGINAL (.vimrc): silent set tags=.tags~
pcall(function() vim.opt.tags = { ".tags~" } end)

-- ---------------------------------------------------------------------------
-- (3) Leader и алиасы
-- ---------------------------------------------------------------------------

-- Почему и как: в vimrc лидер был '\', но kickstart обычно использует пробел.
-- Мы НЕ переписываем kickstart, но сохраняем “алиас” запятой на <Leader>.
-- ORIGINAL (.vimrc): let mapleader = '\'
-- ORIGINAL (.vimrc): nmap , <Leader>
-- vim.keymap.set({ "n", "v" }, ",", "<Leader>", { remap = true, silent = true, desc = "Алиас для <Leader>" })

-- Почему не переносим: <Tab> как leader-алиас часто ломает completion/snippets.
-- ORIGINAL (.vimrc): nmap <Tab> <Leader>

-- ---------------------------------------------------------------------------
-- (4) Filetype detection (замена твоих autocmd set ft=...)
-- ---------------------------------------------------------------------------

-- Почему и как: в Neovim лучше через vim.filetype.add()
-- ORIGINAL (.vimrc): au BufNewFile,BufRead *.tt set ft=tt2 ... (и т.д.)
vim.filetype.add({
  extension = {
    tt      = "tt2",
    tt2     = "tt2",
    ttajax  = "tt2",
    tta     = "tt2",
    ta      = "tt2",
    mas     = "mason",
    phtml   = "perl",
    psgi    = "perl",
    ["pl-dist"] = "perl",
    json    = "javascript",
    js      = "javascript",
    ["sh-dist"] = "sh",
    logic   = "perlgem",
    tmpl    = "perlgem",
    mustache = "mustache",
  },
  filename = {
    ["elinks.conf"] = "elinks",
  },
})

-- ---------------------------------------------------------------------------
-- (5) Хелперы: подсветка “длинных строк”, пробелов/табов, окна, теги
-- ---------------------------------------------------------------------------

local function highlight_overlength(enable)
  -- ORIGINAL (.vimrc): function HighLightOverLength(highlight) ...
  vim.cmd("highlight OverLength ctermbg=red")
  vim.cmd([[match OverLength /\%>120v.\+/]])
  if not enable then
    vim.cmd("highlight clear OverLength")
    vim.cmd("match none")
  end
end

local function add_tab_spaces_syntax()
  -- ORIGINAL (.vimrc): function AddTabSpacesSyntax() ...
  vim.cmd("highlight SpecialKey ctermfg=DarkGray")
  local ft = vim.bo.filetype
  if ft == "perl" or ft == "ruby" or ft == "javascript" then
    vim.cmd([[syn match ExtraWhitespace /[^\t]\zs\t\+/ containedin=ALL]])
    vim.cmd([[syn match ExtraWhitespace /\s\+$/ containedin=ALL]])
    vim.cmd([[syn match ExtraWhitespace / \+\t\s*/ containedin=ALL]])
    vim.cmd([[syn match ExtraWhitespace /\t\+ \s*/ containedin=ALL]])
    vim.cmd("highlight ExtraWhitespace ctermbg=Red")
  end
end

local function next_window()
  -- ORIGINAL (.vimrc): function NextWindow() ...
  local cur = vim.fn.winnr()
  local last = vim.fn.winnr("$")
  local neww = cur + 1
  if neww > last then neww = 1 end
  vim.cmd(("silent %dwincmd w"):format(neww))
end

local function prev_window()
  -- ORIGINAL (.vimrc): function PrevWindow() ...
  local cur = vim.fn.winnr()
  local last = vim.fn.winnr("$")
  local neww = cur - 1
  if neww < 1 then neww = last end
  vim.cmd(("silent %dwincmd w"):format(neww))
end

local function update_tags()
  -- ORIGINAL (.vimrc): function UpdateTags() let stdout = system('update-ctags >/dev/null 2>&1 &') endfunction
  vim.fn.jobstart({ "sh", "-lc", "update-ctags >/dev/null 2>&1 &" }, { detach = true })
end

local function tagback_or_alternate()
  -- ORIGINAL (.vimrc): function TagBack_or_Alternate() try | pop | catch ... | e# | endtry
  local ok = pcall(vim.cmd, "pop")
  if not ok then
    vim.cmd("silent normal! :e#<CR>")
  end
end

-- ---------------------------------------------------------------------------
-- (6) GF_or_Tag -> LSP definition -> gf -> tag
-- ---------------------------------------------------------------------------

local function gf_or_tag()
  -- ORIGINAL (.vimrc): function GF_or_Tag() if filereadable(expand("<cfile>")) gf else <C-]> end
  -- Новое поведение: LSP definition -> gf -> tag
  local params = vim.lsp.util.make_position_params(0, "utf-8")

  local has_def = false
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if c.supports_method and c:supports_method("textDocument/definition") then
      has_def = true
      break
    end
  end

  if has_def then
    local resp = vim.lsp.buf_request_sync(0, "textDocument/definition", params, 250)
    local found = false
    if resp then
      for _, r in pairs(resp) do
        local res = r.result
        if res and ((type(res) == "table" and #res > 0) or (type(res) == "table" and res.uri)) then
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

  local cfile = vim.fn.expand("<cfile>")
  if cfile ~= "" and vim.fn.filereadable(cfile) == 1 then
    vim.cmd.normal({ "gf", bang = true })
    return
  end

  vim.cmd.normal({ "<C-]>", bang = true })
end

-- ---------------------------------------------------------------------------
-- (7) TidyFile / LintFile — реализация под Neovim (ПУНКТ 2)
-- ---------------------------------------------------------------------------

local function exe_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

local function notify_warn(msg)
  vim.notify(msg, vim.log.levels.WARN)
end

-- Безопасный “filter”: берём весь буфер как stdin, получаем stdout, заменяем буфер.
local function filter_buffer_through(cmd, args)
  local buf = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local input = table.concat(lines, "\n") .. "\n"

  -- nvim 0.10+: vim.system
  if vim.system then
    local res = vim.system(vim.list_extend({ cmd }, args or {}), { stdin = input, text = true }):wait()
    if res.code ~= 0 then
      notify_warn(("Tidy: команда завершилась с кодом %d\n%s"):format(res.code, res.stderr or ""))
      return false
    end
    local out = res.stdout or ""
    local out_lines = vim.split(out, "\n", { plain = true })
    if #out_lines > 0 and out_lines[#out_lines] == "" then
      table.remove(out_lines, #out_lines)
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, out_lines)
    return true
  end

  -- fallback на jobstart (если очень старая версия nvim)
  notify_warn("Tidy: vim.system недоступен, обнови Neovim до 0.10+ (или скажи — сделаю jobstart-реализацию).")
  return false
end

-- TidyFile: выбираем тулзу по filetype (как в vimrc, но без жёстких путей).
local function tidy_file()
  -- ORIGINAL (.vimrc): function TidyFile() ... perltidy/js_beautify.pl/tidy ...
  local ft = vim.bo.filetype

  if ft == "perl" then
    -- В vimrc было: %!perltidy -pro=.../.perltidyrc
    -- Почему так: путь "…/.perltidyrc" в vimrc был невалидным/непереносимым.
    -- Как делаем: ищем .perltidyrc в корне проекта/домашней папке, иначе без него.
    local candidates = {
      vim.fs.joinpath(vim.fn.getcwd(), ".perltidyrc"),
      vim.fn.expand("~/.perltidyrc"),
    }
    local rc = nil
    for _, p in ipairs(candidates) do
      if vim.fn.filereadable(p) == 1 then
        rc = p
        break
      end
    end

    if not exe_exists("perltidy") then
      notify_warn("Tidy(perl): не найден perltidy в PATH")
      return
    end

    local args = {}
    if rc then
      args = { ("-pro=%s"):format(rc) }
    end
    filter_buffer_through("perltidy", args)
    return
  end

  if ft == "javascript" or ft == "typescript" or ft == "json" then
    -- В vimrc было: %!js_beautify.pl -
    -- Почему меняем: js_beautify.pl обычно не стоит по умолчанию; в мире nvim чаще prettier.
    -- Как делаем: если есть prettier -> используем его.
    if exe_exists("prettier") then
      -- prettier понимает stdin
      filter_buffer_through("prettier", { "--stdin-filepath", vim.fn.expand("%:p") })
      return
    end
    notify_warn("Tidy(js): не найден prettier в PATH (в vimrc был js_beautify.pl)")
    return
  end

  if ft == "html" then
    -- В vimrc было: %!tidy -q -i -utf8 -asxhtml --tidy-mark no -f /dev/null
    if not exe_exists("tidy") then
      notify_warn("Tidy(html): не найден tidy в PATH")
      return
    end
    filter_buffer_through("tidy", { "-q", "-i", "-utf8", "-asxhtml", "--tidy-mark", "no", "-f", "/dev/null" })
    return
  end

  if ft == "xml" then
    -- В vimrc было: %!tidy -q -i -utf8 -asxml --tidy-mark no -f /dev/null
    if not exe_exists("tidy") then
      notify_warn("Tidy(xml): не найден tidy в PATH")
      return
    end
    filter_buffer_through("tidy", { "-q", "-i", "-utf8", "-asxml", "--tidy-mark", "no", "-f", "/dev/null" })
    return
  end

  notify_warn("Tidyer для этого filetype пока не определён")
end

-- LintFile: запускаем линтер и открываем quickfix как в vimrc (cwindow 5).
local function set_qf_from_lines(title, lines)
  local items = {}
  for _, l in ipairs(lines) do
    -- максимально универсально: кладём как текстовую строку
    table.insert(items, { text = l })
  end
  vim.fn.setqflist({}, " ", { title = title, items = items })
end

local function lint_file()
  -- ORIGINAL (.vimrc): function LintFile() if perl/js then make | cwindow 5 end
  -- Почему меняем: :make зависит от makeprg/errorformat; в kickstart LSP уже делает диагностику.
  -- Но ты просил сохранить поведение — делаем явный запуск линтера и вывод в quickfix.
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%:p")

  local function run_capture(cmdline, title)
    if vim.system then
      local res = vim.system({ "sh", "-lc", cmdline }, { text = true }):wait()
      local out = (res.stdout or "") .. (res.stderr or "")
      local lines = vim.split(out, "\n", { plain = true, trimempty = true })
      set_qf_from_lines(title, lines)
      if #lines > 0 then
        vim.cmd("silent cwindow 5")
      else
        vim.cmd("silent cclose")
      end
      return
    end
    notify_warn("Lint: vim.system недоступен, обнови Neovim до 0.10+ (или скажи — сделаю jobstart-реализацию).")
  end

  if ft == "perl" then
    -- В vimrc было: make (perlcritic -verbose 1 %)
    if exe_exists("perlcritic") then
      run_capture(("perlcritic -verbose 1 %q"):format(file), "perlcritic")
      return
    end
    notify_warn("Lint(perl): не найден perlcritic в PATH")
    vim.cmd("silent cclose")
    return
  end

  if ft == "javascript" or ft == "typescript" then
    -- В vimrc было: make (jslint-run-node.js %)
    -- Почему меняем: jslint-run-node.js был жёстким путём. В мире сейчас чаще eslint.
    if exe_exists("eslint") then
      run_capture(("eslint %q"):format(file), "eslint")
      return
    end
    notify_warn("Lint(js): не найден eslint в PATH (в vimrc был jslint-run-node.js)")
    vim.cmd("silent cclose")
    return
  end

  notify_warn("Linter для этого filetype пока не определён")
  vim.cmd("silent cclose")
end

vim.api.nvim_create_user_command("TidyFile", tidy_file, {})
vim.api.nvim_create_user_command("LintFile", lint_file, {})
vim.api.nvim_create_user_command("UpdateTags", update_tags, {})
vim.api.nvim_create_user_command("GFOrTag", gf_or_tag, {})

-- ---------------------------------------------------------------------------
-- (8) Telescope вместо fzf/ctrlp/taglist/bufexplorer (ПУНКТ 1)
-- ---------------------------------------------------------------------------

local function telescope_ok()
  local ok, builtin = pcall(require, "telescope.builtin")
  if not ok then
    notify_warn("Telescope не найден (в kickstart он обычно есть).")
    return nil
  end
  return builtin
end

-- Почему удалено: добавление ~/.fzf в runtimepath не нужно.
-- ORIGINAL (.vimrc): if !empty(glob('~/.fzf')) | set rtp+=~/.fzf | else | set rtp+=... | endif

-- Почему удалено: <Plug>(fzf-maps-*) и fzf-complete-* — это API fzf.vim.
-- ORIGINAL (.vimrc): nmap <Leader><Tab> <Plug>(fzf-maps-n)
-- ORIGINAL (.vimrc): imap <C-X><Tab> <Plug>(fzf-complete-word)
-- и т.п.
-- Как делаем: Telescope builtin.keymaps / live_grep / find_files / buffers / tags.

-- ---------------------------------------------------------------------------
-- (9) Автокоманды: эквивалент твоего MyBufEnter + Syntax * AddTabSpacesSyntax + BufWritePost UpdateTags
-- ---------------------------------------------------------------------------

local aug = vim.api.nvim_create_augroup("cub_vimrc_migration", { clear = true })

vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
  group = aug,
  callback = function()
    local ft = vim.bo.filetype

    if ft == "perl" then
      -- ORIGINAL (.vimrc): setlocal makeprg=perlcritic\ -verbose\ 1\ %
      -- ORIGINAL (.vimrc): setlocal errorformat=%f:%l:%c:%m
      -- Почему оставляем: удобно для :make, хотя сейчас lint делаем отдельной командой.
      vim.opt_local.makeprg = "perlcritic -verbose 1 %"
      vim.opt_local.errorformat = "%f:%l:%c:%m"

      -- ORIGINAL (.vimrc): setlocal iskeyword+=:
      vim.opt_local.iskeyword:append(":")

      highlight_overlength(true)
      add_tab_spaces_syntax()

      -- ORIGINAL (.vimrc): syn match perlCustomStatement...
      vim.cmd([[
        syn match perlCustomStatement1 "\<\%(_[a-z0-9_]\+\)\>\%((\?\)\@="
        syn match perlCustomStatement1 "\<\%([a-z0-9]\+_[a-z0-9_]\+\)\>\%((\?\)\@="
        syn match perlCustomStatement2 "&start_log"
        syn match perlCustomStatement2 "\<\%(write_log[a-z_]*\|start_log\|end_log\|log_var\)\>\%((\?\)\@="
        syn match perlCustomStatement2 "\<\%(rpc\|qrpc\|ajsrpc\|config_get\|placeholders\)\>\%((\?\)\@="
        syn match perlCustomStatement2 "\<\%(first\|max\|maxstr\|min\|minstr\|reduce\|shuffle\|sum\)\>\%((\?\)\@="
        syn match perlCustomStatement2 "\<\%(abs\|ceil\)\>\%((\?\)\@="
        syn match perlCustomStatement2 "\<\%(any\|all\|none\|notall\|firstidx\|lastidx\|indexes\|firstval\|lastval\|natatime\|mesh\|zip\|uniq\|minmax\|part\)\>\%((\?\)\@="
        syn match perlCustomStatement2 "\<\%(\%(assume\|any\|my\|round\)_[a-z_]\+\)\>\%((\?\)\@="
        syn match perlCustomStatement2 "\<\%([a-z_]*\%(bpa_history\|withdrawal_requests\)[a-z_]*\)\>"
        syn match perlCustomStatement3 "\<\%([A-Z][A-Za-z0-9_]*\%(::[A-Za-z0-9_]\+\)*\)\>\%((\?\)\@="
        syn match perlCustomStatement4 "\<\%([a-z0-9_]*\%(crash\|assert\|warn\|err\)[a-z0-9_]*\|[A-Z]\+_[A-Z0-9_]\+\)\>\%((\?\)\@="
        syn match perlCustomStatement4 "\<\%(retry\|process_by_chunk\|dbh\|\%(dbh\|osql\|execute\|billing\)_[a-z0-9_]\+\)\>\%((\?\)\@="
        syn match perlStatementScalar "\<\%(strftime\)\>"
        command -nargs=+ HiLink hi def link <args>
        HiLink perlCustomStatement1 perlSpecialMatch
        HiLink perlCustomStatement2 perlSubPrototype
        HiLink perlCustomStatement3 perlSubAttributes
        HiLink perlCustomStatement4 perlOperator
        delcommand HiLink
      ]])

      -- Perl buffer-local bindings
      -- ORIGINAL (.vimrc): map <buffer> [[ ?\(sub\s.*\)\@<={<CR>
      -- ORIGINAL (.vimrc): map <buffer> ]] ?\(^\s*\)\@<=};*$<CR>
      vim.keymap.set("n", "[[", [[?\(sub\s.*\)\@<={<CR>]], { buffer = true, silent = true, desc = "Perl: prev sub" })
      vim.keymap.set("n", "]]", [[?\(^\s*\)\@<=};*$<CR>]], { buffer = true, silent = true, desc = "Perl: next end block" })

    elseif ft == "javascript" then
      -- ORIGINAL (.vimrc): setlocal makeprg=/home/cub/.vim/jslint/jslint-run-node.js\ %
      -- Почему не переносим: жёсткий путь.
      -- Как делаем: LintFile использует eslint, если установлен.
      -- vim.opt_local.makeprg = "/home/cub/.vim/jslint/jslint-run-node.js %"
      -- vim.opt_local.errorformat = "%f:%l:%c:%m"
      add_tab_spaces_syntax()

    elseif ft == "gitcommit" then
      -- ORIGINAL (.vimrc): call setpos('.', [0, 1, 1, 0])
      pcall(vim.fn.setpos, ".", { 0, 1, 1, 0 })
    end

    -- Title string (в nvim это работает, но зависит от терминала)
    -- ORIGINAL (.vimrc): let &titlestring=g:user_host.": e ".expand("%") | set title
    vim.opt.titlestring = ("%s: e %s"):format(vim.g.user_host, vim.fn.expand("%"))
    vim.opt.title = true

    -- Host-specific StatusLine tweaks (оставляем как в vimrc, но мягко)
    -- ORIGINAL (.vimrc): if g:user_host == "cub-uanic@tux" ... hi StatusLine ...
    if vim.g.user_host == "cub-uanic@tux" or vim.g.user_host == "o@tux" then
      vim.cmd("hi StatusLine ctermfg=blue")
    end
    if vim.g.user_host == "cub-uanic@specific1-host.com" then
      vim.cmd("hi StatusLine ctermbg=black ctermfg=yellow")
    end
    if vim.g.user_host == "cub-uanic@specific2-host.com" then
      vim.cmd("hi StatusLine ctermfg=red")
    end
  end,
})

-- ORIGINAL (.vimrc): au Syntax * call AddTabSpacesSyntax()
vim.api.nvim_create_autocmd("Syntax", {
  group = aug,
  callback = function()
    add_tab_spaces_syntax()
  end,
})

-- ORIGINAL (.vimrc): au BufWritePost * call UpdateTags()
vim.api.nvim_create_autocmd("BufWritePost", {
  group = aug,
  callback = function()
    update_tags()
  end,
})

-- ---------------------------------------------------------------------------
-- (10) Keymaps — перенос основных “функциональных” биндов + Telescope-замены
-- ---------------------------------------------------------------------------

local function map(mode, lhs, rhs, desc, opts)
  opts = opts or {}
  opts.silent = (opts.silent ~= false)
  opts.desc = desc
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- F1/F2 и quickfix
-- ORIGINAL (.vimrc): nmap <silent> <F1> :only<CR>
-- ORIGINAL (.vimrc): imap <silent> <F1> <C-O>:only<CR>
map("n", "<F1>", "<cmd>only<CR>", "Оставить только текущее окно")
map("i", "<F1>", "<C-o><cmd>only<CR>", "Оставить только текущее окно (insert)")

-- ORIGINAL (.vimrc): nmap <silent> <S-F1> :copen<CR>
-- ORIGINAL (.vimrc): nmap <silent> <C-F1> :close<CR>
map("n", "<S-F1>", "<cmd>copen<CR>", "Открыть quickfix")
map("i", "<S-F1>", "<C-o><cmd>copen<CR>", "Открыть quickfix (insert)")
map("n", "<C-F1>", "<cmd>close<CR>", "Закрыть окно")
map("i", "<C-F1>", "<C-o><cmd>close<CR>", "Закрыть окно (insert)")

-- Save
-- ORIGINAL (.vimrc): nmap <silent> <F2> :w<CR>
-- ORIGINAL (.vimrc): nmap <silent> <S-F2> :wa<CR>
map("n", "<F2>", "<cmd>w<CR>", "Сохранить файл")
map("i", "<F2>", "<C-o><cmd>w<CR>", "Сохранить файл (insert)")
map("n", "<S-F2>", "<cmd>wa<CR>", "Сохранить все")
map("i", "<S-F2>", "<C-o><cmd>wa<CR>", "Сохранить все (insert)")

-- Переключение BOM (оставляем как команду)
-- ORIGINAL (.vimrc): function TogilleBOM()
local function toggle_bom()
  vim.bo.bomb = not vim.bo.bomb
end
map("n", "<S-F3>", toggle_bom, "Переключить BOM")
map("i", "<S-F3>", function() toggle_bom() end, "Переключить BOM (insert)")

-- list/nolist
-- ORIGINAL (.vimrc): nmap <silent> <C-F3> :set list!<CR>
map("n", "<C-F3>", function() vim.opt.list = not vim.opt.list:get() end, "Показать/скрыть listchars")
map("i", "<C-F3>", function() vim.opt.list = not vim.opt.list:get() end, "Показать/скрыть listchars (insert)")

-- ---------------------------------------------------------------------------
-- Telescope: замена F6/F5/Tags/Buffers/Keymaps (ПУНКТ 1)
-- ---------------------------------------------------------------------------

-- ORIGINAL (.vimrc): nmap <silent> <F6> :Buffers<CR>
-- ORIGINAL (.vimrc): nmap <silent> <S-F6> :Tags<CR>
map("n", "<F6>", function()
  local b = telescope_ok()
  if b then b.buffers() end
end, "Telescope: buffers")
map("i", "<F6>", function()
  local b = telescope_ok()
  if b then b.buffers() end
end, "Telescope: buffers (insert)")

map("n", "<S-F6>", function()
  local b = telescope_ok()
  if b then b.tags() end
end, "Telescope: tags (ctags)")
map("i", "<S-F6>", function()
  local b = telescope_ok()
  if b then b.tags() end
end, "Telescope: tags (ctags) (insert)")

-- ORIGINAL (.vimrc): nmap <Leader><Tab> <Plug>(fzf-maps-n)
map("n", "<Leader><Tab>", function()
  local b = telescope_ok()
  if b then b.keymaps() end
end, "Telescope: keymaps")

-- Полезные аналоги ctrlp/nerdtree/bufexplorer (опционально)
-- (в vimrc это было распределено по разным плагинам, тут — “идеологично” Telescope)
map("n", "<Leader>ff", function()
  local b = telescope_ok()
  if b then b.find_files() end
end, "Telescope: файлы")
map("n", "<Leader>fg", function()
  local b = telescope_ok()
  if b then b.live_grep() end
end, "Telescope: grep")
map("n", "<Leader>fr", function()
  local b = telescope_ok()
  if b then b.oldfiles() end
end, "Telescope: recent")

-- Почему оставлено комментом: NERDTreeToggle (<C-G>) — зависит от того, что у тебя в kickstart (neo-tree/oil).
-- ORIGINAL (.vimrc): nmap <silent> <C-G> :NERDTreeToggle<CR>
-- map("n", "<C-G>", "<cmd>Neotree toggle<CR>", "Neo-tree toggle")   -- если у тебя neo-tree
-- map("n", "<C-G>", "<cmd>Oil<CR>", "Oil file explorer")            -- если у тебя oil.nvim

-- ---------------------------------------------------------------------------
-- Буфер туда-сюда / окна / quickfix nav
-- ---------------------------------------------------------------------------

-- ORIGINAL (.vimrc): nmap <silent> <C-F6> :e#<CR>
map("n", "<C-F6>", "<cmd>e#<CR>", "Предыдущий файл")
map("i", "<C-F6>", "<C-o><cmd>e#<CR>", "Предыдущий файл (insert)")

-- ORIGINAL (.vimrc): nmap <silent> <F7> :call NextWindow()<CR>
-- ORIGINAL (.vimrc): nmap <silent> <F8> :call PrevWindow()<CR>
map("n", "<F7>", next_window, "Следующее окно")
map("i", "<F7>", next_window, "Следующее окно (insert)")
map("n", "<F8>", prev_window, "Предыдущее окно")
map("i", "<F8>", prev_window, "Предыдущее окно (insert)")

-- ORIGINAL (.vimrc): map <silent> <C-F7> :cp<CR>  (prev qf)
-- ORIGINAL (.vimrc): map <silent> <C-F8> :cn<CR>  (next qf)
map({ "n", "i" }, "<C-F7>", "<cmd>cp<CR>", "Quickfix: prev")
map({ "n", "i" }, "<C-F8>", "<cmd>cn<CR>", "Quickfix: next")

-- Buffer prev/next
-- ORIGINAL (.vimrc): map <silent> <S-F7> :bp<CR>
-- ORIGINAL (.vimrc): map <silent> <S-F8> :bn<CR>
map({ "n", "i" }, "<S-F7>", "<cmd>bp<CR>", "Буфер: предыдущий")
map({ "n", "i" }, "<S-F8>", "<cmd>bn<CR>", "Буфер: следующий")

-- ---------------------------------------------------------------------------
-- Tidy/Lint бинды (ПУНКТ 2) — как в vimrc на F9/S-F9
-- ---------------------------------------------------------------------------

-- ORIGINAL (.vimrc): nmap <silent> <F9> m':call TidyFile()<CR>''   (с сохранением позиции)
-- В nvim проще: ставим mark ' и после — возврат. (аналогично твоей идее)
map("n", "<F9>", function()
  vim.cmd("normal! m'")
  tidy_file()
  vim.cmd("normal! ''")
end, "TidyFile (format)")

map("i", "<F9>", function()
  vim.cmd("normal! m'")
  tidy_file()
  vim.cmd("normal! ''")
end, "TidyFile (format) (insert)")

-- ORIGINAL (.vimrc): nmap <silent> <S-F9> m':call LintFile()<CR>''  (quickfix)
map("n", "<S-F9>", function()
  vim.cmd("normal! m'")
  lint_file()
  vim.cmd("normal! ''")
end, "LintFile (quickfix)")

map("i", "<S-F9>", function()
  vim.cmd("normal! m'")
  lint_file()
  vim.cmd("normal! ''")
end, "LintFile (quickfix) (insert)")

-- ORIGINAL (.vimrc): nmap <silent> <C-F9> <F9><F2><F6>
map("n", "<C-F9>", function()
  vim.cmd("normal! m'")
  tidy_file()
  vim.cmd("write")
  local b = telescope_ok()
  if b then b.buffers() end
  vim.cmd("normal! ''")
end, "Tidy + save + buffers")

-- Exit
-- ORIGINAL (.vimrc): nmap <silent> <F10> :qa<CR>
-- ORIGINAL (.vimrc): nmap <silent> <S-F10> :wqa<CR>
-- ORIGINAL (.vimrc): nmap <silent> <C-F10> :qa!<CR>
map({ "n", "i" }, "<F10>", "<cmd>qa<CR>", "Выйти")
map({ "n", "i" }, "<S-F10>", "<cmd>wqa<CR>", "Сохранить и выйти")
map({ "n", "i" }, "<C-F10>", "<cmd>qa!<CR>", "Выйти без сохранения")

-- Window resize (Alt+arrows)
-- ORIGINAL (.vimrc): map <A-Up> <C-W>-  и т.д.
map("n", "<A-Up>", "<C-w>-", "Окно ниже (уменьшить высоту)")
map("n", "<A-Down>", "<C-w>+", "Окно выше (увеличить высоту)")
map("n", "<A-Left>", "<C-w><", "Окно уже")
map("n", "<A-Right>", "<C-w>>", "Окно шире")

-- Backspace/Enter на теги/переход (как в vimrc)
-- ORIGINAL (.vimrc): nmap <silent> <BS> :call TagBack_or_Alternate()<CR>
-- ORIGINAL (.vimrc): nmap <silent> <Enter> :call GF_or_Tag()<CR>
map("n", "<BS>", tagback_or_alternate, "Назад по тегам или alternate")
map("n", "<CR>", gf_or_tag, "LSP definition -> gf -> tag")

-- Быстрый nohl
-- ORIGINAL (.vimrc): nmap <silent> <Leader><Leader> :nohl<CR>
map("n", "<Bslash><Bslash>", "<cmd>nohlsearch<CR>", "Убрать подсветку поиска")

-- OverLength toggles
-- ORIGINAL (.vimrc): nmap <Leader>y :call HighLightOverLength("yes")<CR>
-- ORIGINAL (.vimrc): nmap <Leader>n :call HighLightOverLength("no")<CR>
map("n", "<Leader>y", function() highlight_overlength(true) end, "Подсветка >120: включить")
map("n", "<Leader>n", function() highlight_overlength(false) end, "Подсветка >120: выключить")

-- Русская “№” -> “#”
-- ORIGINAL (.vimrc): imap № #
map("i", "№", "#", "№ -> #")

-- Визуальные отступы (как в vimrc)
-- ORIGINAL (.vimrc): vmap <  <gv ; vmap > >gv ; vmap <Tab> >gv ; vmap <S-Tab> <gv
map("v", "<", "<gv", "Сдвиг влево (остаться в выделении)")
map("v", ">", ">gv", "Сдвиг вправо (остаться в выделении)")
map("v", "<Tab>", ">gv", "Сдвиг вправо (Tab)")
map("v", "<S-Tab>", "<gv", "Сдвиг влево (S-Tab)")

-- Mirror/Reverse команды
-- ORIGINAL (.vimrc): command! -range Mirror ...
-- ORIGINAL (.vimrc): command! -range=% Reverse ...
vim.api.nvim_create_user_command("Mirror", function(opts)
  local l1, l2 = opts.line1, opts.line2
  for l = l1, l2 do
    local s = vim.fn.getline(l)
    local chars = vim.fn.split(s, [[\zs]])
    chars = vim.fn.reverse(chars)
    vim.fn.setline(l, table.concat(chars, ""))
  end
end, { range = true })

vim.api.nvim_create_user_command("Reverse", function(opts)
  local l1, l2 = opts.line1, opts.line2
  local lines = vim.api.nvim_buf_get_lines(0, l1 - 1, l2, false)
  local rev = {}
  for i = #lines, 1, -1 do
    table.insert(rev, lines[i])
  end
  vim.api.nvim_buf_set_lines(0, l1 - 1, l2, false, rev)
end, { range = true })

-- Визуальные маппинги на Mirror/Reverse (как в vimrc)
-- ORIGINAL (.vimrc): vmap <Leader>m :Mirror<CR>
-- ORIGINAL (.vimrc): vmap <Leader>r :Reverse<CR>
map("v", "<Leader>m", ":Mirror<CR>", "Mirror выделение", { silent = false })
map("v", "<Leader>r", ":Reverse<CR>", "Reverse выделение", { silent = false })

-- ---------------------------------------------------------------------------
-- (11) Прочее из vimrc — оставлено комментом (можно вернуть по запросу)
-- ---------------------------------------------------------------------------

-- Почему оставлено комментом: StardictTranslate зависит от внешнего sdcv.
-- ORIGINAL (.vimrc): function StardictTranslate() ... system("sdcv -n ...")
-- (Если надо — перенесу как Lua-команду и аккуратно покажу вывод в floating window)

-- Почему оставлено комментом: DimInactiveWindows “хак” через colorcolumn может тормозить в nvim.
-- ORIGINAL (.vimrc): s:DimInactiveWindows() ... setwinvar('&colorcolumn', range) ...
-- Если тебе реально важно — сделаю nvim-версию через winhighlight (обычно быстрее).


-- ============================================================================
-- Handy shortcuts (добавка)
-- ============================================================================

-- Быстро закрыть текущий буфер (без убийства окна)
-- Аналог “удобно, как в bufexplorer/плагинах”
map("n", "<Leader>bd", "<cmd>bdelete<CR>", "Буфер: закрыть текущий")

-- Быстро закрыть все остальные буферы (оставить текущий)
map("n", "<Leader>bo", "<cmd>%bdelete|edit#|bdelete#<CR>", "Буфер: закрыть остальные")

-- Быстро открыть список буферов (Telescope)
map("n", "<Leader>bb", function()
  local ok, b = pcall(require, "telescope.builtin")
  if ok then b.buffers() end
end, "Telescope: buffers")

-- Файлы / grep (если хочешь прям “handy” под рукой)
map("n", "<Leader>pf", function()
  local ok, b = pcall(require, "telescope.builtin")
  if ok then b.find_files() end
end, "Telescope: найти файл")

map("n", "<Leader>pg", function()
  local ok, b = pcall(require, "telescope.builtin")
  if ok then b.live_grep() end
end, "Telescope: поиск по проекту")

-- Переключение относительных номеров (часто супер-удобно)
map("n", "<Leader>nr", function()
  vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, "Номера строк: relative on/off")

-- Быстро включить/выключить wrap
map("n", "<Leader>tw", function()
  vim.opt.wrap = not vim.opt.wrap:get()
end, "Wrap: on/off")

-- Быстро включить/выключить spell
map("n", "<Leader>ts", function()
  vim.opt.spell = not vim.opt.spell:get()
end, "Spell: on/off")

-- Быстро открыть/закрыть quickfix
map("n", "<Leader>qq", function()
  if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
    vim.cmd("cclose")
  else
    vim.cmd("copen")
  end
end, "Quickfix: toggle")

return VIMRC

-- vim: ts=2 sts=2 sw=2 et

