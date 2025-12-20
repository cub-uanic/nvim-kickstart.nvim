-- vim: ts=2 sts=2 sw=2 et
--
-- Sessions: persistence.nvim (аналог xolox/vim-session “по-проектно”)
--
return {
  'folke/persistence.nvim',
  event = 'VimEnter', -- гарантированно доступен к моменту автозагрузки
  opts = {
    need = 1,
  },
  config = function(_, opts)
    local ok, persistence = pcall(require, 'persistence')
    if not ok then
      return
    end
    persistence.setup(opts)

    local group = vim.api.nvim_create_augroup('CustomPersistence', { clear = true })

    local function should_autoload()
      -- если передали файлы аргументами — не лезем с сессией
      if vim.fn.argc() ~= 0 then
        return false
      end

      -- если nvim стартанул, читая из stdin (например: cat file | nvim -)
      -- в этом случае тоже не надо грузить сессию
      if vim.fn.exists 'g:started_with_stdin' == 1 and vim.g.started_with_stdin then
        return false
      end

      if vim.o.diff then
        return false
      end

      return true
    end

    local function autoload()
      if not should_autoload() then
        return
      end

      -- ВАЖНО: делаем после старта, чтобы не конфликтовать с UI/плагинами
      vim.schedule(function()
        -- persistence сам “ничего не сделает”, если сессии нет
        persistence.load()
      end)
    end

    -- 1) Надёжный автозапуск на VimEnter
    vim.api.nvim_create_autocmd('VimEnter', {
      group = group,
      callback = autoload,
    })

    -- 2) Доп. страховка: если у тебя реально нужен LazyDone (иногда cwd меняется позже)
    vim.api.nvim_create_autocmd('User', {
      group = group,
      pattern = 'LazyDone',
      callback = autoload,
    })

    -- Автосохранение на выходе persistence делает сам после setup()
  end,
}
