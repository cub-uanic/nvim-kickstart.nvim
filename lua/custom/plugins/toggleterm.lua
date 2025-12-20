return {
  'akinsho/toggleterm.nvim',
  version = '*',
  keys = {
    { '<leader>tt', '<cmd>ToggleTerm<cr>', desc = 'Terminal: Toggle' },
    { '<leader>tg', '<cmd>1ToggleTerm<cr>', desc = 'Terminal: 1' },
    { '<leader>te', '<cmd>2ToggleTerm<cr>', desc = 'Terminal: 2' },
  },
  opts = {
    open_mapping = [[<c-\>]],
    direction = 'float', -- "horizontal" / "vertical" / "tab" / "float"
    shade_terminals = true,
    persist_size = true,
  },
}
