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
-- 🧠 Neovim Perl / Web Dev Cheat Sheet (Custom Setup)
-- ============================================================================
--
-- Telescope (kickstart.nvim)
--   :Telescope live_grep        — поиск по проекту (код, логи, SQL)
--   :Telescope find_files       — поиск файлов
--   :Telescope buffers          — список буферов
--
-- Overseer (tasks / servers / runners)
--   <leader>rr                  — умный запуск текущего файла / проекта:
--                                  * Mojo / Dancer / Catalyst → сервер
--                                  * Test::*, *.t             → prove
--                                  * PSGI / Plack             → plackup
--                                  * не perl (yml/json/etc)   → запуск app entrypoint
--                                  * иначе                    → терминал / notify
--   <leader>oo                  — показать / скрыть окно Overseer
--   <leader>or                  — список задач (Run task)
--
-- ToggleTerm (интерактивные терминалы)
--   <C-\>                       — открыть / закрыть терминал (float)
--   <leader>tt                  — ToggleTerm
--   <leader>t1                  — терминал #1
--   <leader>t2                  — терминал #2
--
-- log-highlight.nvim
--   (без хоткеев)
--   Автоматическая подсветка логов:
--     * уровни (INFO / WARN / ERROR)
--     * timestamps
--   Работает для *.log / filetype=log
--
-- vim-dadbod / vim-dadbod-ui / vim-dadbod-completion
--   <leader>du                  — DB UI toggle
--   <leader>df                  — найти DB-буфер (DBUIFindBuffer)
--   :DB <dsn>                   — подключение вручную
--   :DBUIToggle                 — DB UI
--   :DBProjectReload            — перечитать DB-конфиг проекта
--                                 (.env, config.yml, config/database.yml)
--   SQL completion              — автоматически в SQL-буферах
--
-- vim-test (Perl tests)
--   <leader>tn                  — TestNearest
--   <leader>tf                  — TestFile
--   <leader>ts                  — TestSuite
--   <leader>tl                  — TestLast
--   <leader>tv                  — TestVisit
--   (стратегия: toggleterm)
--
-- vim-perl
--   (без хоткеев)
--   Улучшенный syntax / indent / folding для Perl
--
-- ============================================================================
-- 🧠 Neovim Autocompletion Cheat Sheet
-- ============================================================================
--
-- nvim-cmp (основной автокомплит)
--
--   <C-Space>                  — вручную открыть меню completion
--   <C-e>                      — закрыть меню completion
--   <CR>                       — подтвердить выбранный вариант
--                                 (Insert → Replace, как в kickstart)
--
-- Навигация по списку completion
--   <C-n>                      — следующий элемент
--   <C-p>                      — предыдущий элемент
--
-- Snippets (LuaSnip, если включён в kickstart)
--   <Tab>                      — перейти к следующему placeholder’у сниппета
--   <S-Tab>                    — перейти к предыдущему placeholder’у
--   (работает, если активен snippet jump)
--
-- Источники completion (автоматически)
--
--   LSP                        — код, символы, методы (Perl LSP, если подключён)
--   buffer                     — слова из текущего буфера
--   path                       — пути к файлам
--   luasnip                    — сниппеты
--
-- SQL / DB (vim-dadbod-completion)
--
--   completion в SQL-буферах:
--     * имена таблиц
--     * колонки
--     * схемы
--   Источник активен, если:
--     - открыт SQL-буфер
--     - есть активное dadbod-подключение (:DBUI / vim.g.dbs)
--
--   :DBProjectReload           — перечитать DB-конфиг проекта
--                                 (.env / config.yml / config/database.yml)
--
-- Полезно помнить
--
--   completion появляется автоматически при вводе
--   <C-Space> — всегда принудительно показывает список
--   если completion "пропал":
--     :LspInfo                 — проверить LSP
--     :CmpStatus               — статус nvim-cmp (если доступно)
--
-- ============================================================================
