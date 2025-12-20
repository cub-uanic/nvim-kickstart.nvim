return {
  "akinsho/toggleterm.nvim",
  version = "*",
  keys = {
    { "<leader>tt", "<cmd>ToggleTerm<cr>", desc = "Terminal: Toggle" },
    { "<leader>tn", "<cmd>1ToggleTerm<cr>", desc = "Terminal: 1" },
    { "<leader>te", "<cmd>2ToggleTerm<cr>", desc = "Terminal: 2" },
  },
  opts = {
    open_mapping = [[<c-\>]],
    direction = "float", -- "horizontal" / "vertical" / "tab" / "float"
    shade_terminals = true,
    persist_size = true,
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)

    -- Удобная команда для morbo в отдельном терминале:
    local Terminal = require("toggleterm.terminal").Terminal
    local morbo_term = Terminal:new({
      cmd = "morbo script/app.pl",
      hidden = true,
      direction = "float",
    })

    vim.api.nvim_create_user_command("MorboTerm", function()
      morbo_term:toggle()
    end, {})

    vim.keymap.set("n", "<leader>mT", "<cmd>MorboTerm<cr>", { desc = "Mojo: morbo (ToggleTerm)" })
  end,
}

