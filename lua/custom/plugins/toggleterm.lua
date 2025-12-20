-- vim: ts=2 sts=2 sw=2 et
--

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
    direction = 'horizontal', -- "horizontal" / "vertical" / "tab" / "float"
    shade_terminals = true,
    persist_size = true,
  },
}
