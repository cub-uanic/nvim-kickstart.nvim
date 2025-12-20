return {
  {
    -- Sessions: persistence.nvim (аналог xolox/vim-session “по-проектно”)
    "folke/persistence.nvim",
    event = "VimEnter",
    config = function()
      local dir = vim.fn.stdpath("state") .. "/sessions/"
      vim.fn.mkdir(dir, "p")

      local persistence = require("persistence")
      persistence.setup({
        dir = dir,
        options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals" },
      })

      -- Не грузим сессию, если пользователь запустил nvim с файлами/аргументами
      if vim.fn.argc() == 0 then
        vim.schedule(function()
          persistence.load()
        end)
      end
    end,
  },
}

