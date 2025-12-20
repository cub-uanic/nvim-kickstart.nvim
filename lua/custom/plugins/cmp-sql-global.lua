-- vim: ts=2 sts=2 sw=2 et
--
return {
  'hrsh7th/nvim-cmp',
  opts = function(_, opts)
    -- 1) Глобально: buffer всегда доступен и начинает предлагать с 1 символа
    -- Это НЕ требует LSP/omni/словарей, и решает “RESTRICT уже есть в файле”.
    local buffer_source = {
      name = 'buffer',
      keyword_length = 1,
      option = {
        -- берем слова из текущего + всех открытых окон (не шумит)
        get_bufnrs = function()
          local bufs = {}
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local b = vim.api.nvim_win_get_buf(win)
            if vim.bo[b].buftype == '' then
              bufs[b] = true
            end
          end
          -- важно: вернуть список чисел-буферов
          local res = {}
          for b, _ in pairs(bufs) do
            table.insert(res, b)
          end
          return res
        end,
      },
    }

    opts.sources = opts.sources or {}

    -- добавляем buffer в начало, если его ещё нет
    local has_buffer = false
    for _, s in ipairs(opts.sources) do
      if s.name == 'buffer' then
        has_buffer = true
        -- и на всякий случай занижаем keyword_length
        s.keyword_length = s.keyword_length or 1
        s.option = s.option or buffer_source.option
      end
    end

    if not has_buffer then
      table.insert(opts.sources, 1, buffer_source)
    end

    return opts
  end,
}
