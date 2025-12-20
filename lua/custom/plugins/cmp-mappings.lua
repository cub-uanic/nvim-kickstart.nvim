-- vim: ts=2 sts=2 sw=2 et
--
return {
  'hrsh7th/nvim-cmp',
  opts = function(_, opts)
    local cmp = require 'cmp'

    opts.mapping = cmp.mapping.preset.insert {
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),

      ['<C-n>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
      ['<C-p>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },

      -- Enter: подтверждает, даже если ничего не выбрано (берёт первый вариант)
      ['<CR>'] = cmp.mapping.confirm { select = true },

      -- Tab: подтверждает ТОЛЬКО если есть активный выбранный пункт,
      -- иначе ведёт себя как обычный Tab (indent/snippet/fallback)
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.confirm { select = true }
        else
          fallback()
        end
      end, { 'i', 's' }),

      -- Snippet jump (если используешь LuaSnip; если нет — можно удалить)
      ['<C-n>'] = cmp.mapping(function(fallback)
        local ok, ls = pcall(require, 'luasnip')
        if ok and ls and ls.jumpable(1) then
          ls.jump(1)
        else
          fallback()
        end
      end, { 'i', 's' }),

      ['<C-l>'] = cmp.mapping(function(fallback)
        local ok, ls = pcall(require, 'luasnip')
        if ok and ls and ls.jumpable(-1) then
          ls.jump(-1)
        else
          fallback()
        end
      end, { 'i', 's' }),
    }

    return opts
  end,
}
