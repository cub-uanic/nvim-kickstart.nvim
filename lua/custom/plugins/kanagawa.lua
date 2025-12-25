-- vim: ts=2 sts=2 sw=2 et
--
return {
  'rebelot/kanagawa.nvim',
  priority = 1000,
  config = function()
    require('kanagawa').setup {
      theme = 'wave', -- или "dragon" / "moon"
      transparent = false,
      colors = { palette_overrides = { sumiInk0 = '#1e1e2e' } }, -- под zmk.dev
    }
  end,
}
