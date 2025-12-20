-- vim: ts=2 sts=2 sw=2 et
--
-- Sessions: persistence.nvim (аналог xolox/vim-session “по-проектно”)
--
return {
  "folke/persistence.nvim",
  event = "BufReadPre", -- чтобы модуль был доступен достаточно рано, но без лишней нагрузки
  opts = {
    -- defaults are fine; tune if you want:
    -- dir = vim.fn.stdpath("state") .. "/sessions/",
    need = 1, -- минимум файловых буферов для автосейва (0 = всегда)
    -- branch = true, -- если хочешь отдельные сессии по git-веткам
  },
  config = function(_, opts)
    require("persistence").setup(opts)

    local group = vim.api.nvim_create_augroup("CustomPersistence", { clear = true })

    -- Автозагрузка сессии для текущего каталога при старте,
    -- но только если Neovim запущен без аргументов (nvim . / nvim)
    -- и только когда lazy.nvim уже закончил старт (чтобы не было конфликтов с UI).
    vim.api.nvim_create_autocmd("User", {
      group = group,
      pattern = "LazyDone",
      callback = function()
        if vim.fn.argc() ~= 0 then
          return
        end

        -- Не грузим поверх некоторых спец-режимов/буферов
        if vim.o.diff then
          return
        end
        local ft = vim.bo.filetype
        if ft == "lazy" or ft == "TelescopePrompt" then
          return
        end

        -- Если для cwd есть сохранённая сессия — загрузим
        -- (persistence сам корректно “не сделает ничего”, если сессии нет)
        require("persistence").load()
      end,
    })

    -- Автосохранение на выходе persistence.nvim делает сам
    -- (через свои autocmd после setup/start), отдельно ничего не нужно.
  end,
}

