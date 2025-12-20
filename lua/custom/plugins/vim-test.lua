return {
  "vim-test/vim-test",
  keys = {
    { "<leader>tn", "<cmd>TestNearest<cr>", desc = "Test: Nearest" },
    { "<leader>tf", "<cmd>TestFile<cr>", desc = "Test: File" },
    { "<leader>ts", "<cmd>TestSuite<cr>", desc = "Test: Suite" },
    { "<leader>tl", "<cmd>TestLast<cr>", desc = "Test: Last" },
    { "<leader>tv", "<cmd>TestVisit<cr>", desc = "Test: Visit" },
  },
  config = function()
    -- Запуск тестов в toggleterm-терминале — очень удобно.
    -- Если toggleterm не поставишь, можно поменять на "neovim" или "basic".
    vim.g["test#strategy"] = "toggleterm"

    -- Для perl обычно prove, но можно переопределить:
    -- vim.g["test#perl#prove#options"] = "-Ilib"
    -- vim.g["test#perl#prove#file_pattern"] = "\\v(t\\/.*\\.t|.*\\.t)$"
  end,
}

