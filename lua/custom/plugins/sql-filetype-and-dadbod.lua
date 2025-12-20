-- vim: ts=2 sts=2 sw=2 et
--

-- return {
--   'hrsh7th/nvim-cmp',
--   opts = function(_, opts)
--     local cmp = require 'cmp'
--
--     -- 2) На всякий случай: *.sql -> filetype=sql
--     vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
--       pattern = '*.sql',
--       callback = function()
--         if vim.bo.filetype == '' then
--           vim.bo.filetype = 'sql'
--         end
--       end,
--     })
--
--     -- 3) Для SQL добавляем dadbod-completion, НО buffer уже будет глобально
--     -- Применяем к нескольким возможным filetype (включая варианты).
--     local sql_fts = { 'sql', 'mysql', 'plsql', 'pgsql', 'tsql' }
--
--     cmp.setup.filetype(sql_fts, {
--       sources = cmp.config.sources {
--         { name = 'buffer', keyword_length = 1 },
--         { name = 'vim-dadbod-completion' },
--       },
--     })
--
--     return opts
--   end,
-- }

return {
  'hrsh7th/nvim-cmp',
  opts = function(_, opts)
    local cmp = require 'cmp'

    cmp.setup.filetype({ 'sql', 'mysql', 'plsql', 'pgsql', 'tsql' }, {
      sources = cmp.config.sources({
        -- 1) Слова из буфера — приоритетно (RESTRICT уже есть в файле)
        { name = 'buffer', keyword_length = 1 },
        -- 2) DB schema completion — вторым, и ограничиваем, чтобы не забивал список
        { name = 'vim-dadbod-completion', max_item_count = 5 },
      }, {
        { name = 'path' }, -- можно убрать, если не нужно
      }),
    })

    -- (опционально) если у тебя глобально маленький лимит видимых элементов,
    -- можно увеличить (но обычно хватает reorder + max_item_count выше)
    opts.window = opts.window or {}
    opts.window.completion = opts.window.completion or {}
    opts.window.completion.max_height = 20

    return opts
  end,
}
