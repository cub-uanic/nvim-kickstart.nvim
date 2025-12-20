-- vim: ts=2 sts=2 sw=2 et
--

return {
  'hrsh7th/nvim-cmp',
  opts = function(_, opts)
    local cmp = require 'cmp'

    --------------------------------------------------------------------------
    -- MAPPINGS (from cmp-mappings.lua)
    --------------------------------------------------------------------------
    opts.mapping = cmp.mapping.preset.insert {
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-t>'] = cmp.mapping.complete(),
      ['<C-g>'] = cmp.mapping.abort(),

      ['<C-u>'] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
      ['<C-f>'] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },

      ['<CR>'] = cmp.mapping.confirm { select = true },

      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.confirm { select = true }
        else
          fallback()
        end
      end, { 'i', 's' }),

      ['<C-n>'] = cmp.mapping(function(fallback)
        local ok, ls = pcall(require, 'luasnip')
        if ok and ls and ls.jumpable(1) then
          ls.jump(1)
        else
          fallback()
        end
      end, { 'i', 's' }),

      ['<C-e>'] = cmp.mapping(function(fallback)
        local ok, ls = pcall(require, 'luasnip')
        if ok and ls and ls.jumpable(-1) then
          ls.jump(-1)
        else
          fallback()
        end
      end, { 'i', 's' }),
    }

    --------------------------------------------------------------------------
    -- GLOBAL buffer source behavior (from cmp-sql-global.lua)
    --------------------------------------------------------------------------
    local buffer_source = {
      name = 'buffer',
      keyword_length = 1,
      option = {
        get_bufnrs = function()
          local bufs = {}
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local b = vim.api.nvim_win_get_buf(win)
            if vim.bo[b].buftype == '' then
              bufs[b] = true
            end
          end
          local res = {}
          for b, _ in pairs(bufs) do
            table.insert(res, b)
          end
          return res
        end,
      },
    }

    opts.sources = opts.sources or {}

    local has_buffer = false
    for _, s in ipairs(opts.sources) do
      if s.name == 'buffer' then
        has_buffer = true
        s.keyword_length = s.keyword_length or 1
        s.option = s.option or buffer_source.option
      end
    end

    if not has_buffer then
      table.insert(opts.sources, 1, buffer_source)
    end

    --------------------------------------------------------------------------
    -- SQL: prioritize buffer; limit dadbod items; include path
    -- (from sql-filetype-and-dadbod.lua)
    --------------------------------------------------------------------------
    cmp.setup.filetype({ 'sql', 'mysql', 'plsql', 'pgsql', 'tsql' }, {
      sources = cmp.config.sources({
        { name = 'buffer', keyword_length = 1 },
        { name = 'vim-dadbod-completion', max_item_count = 5 },
      }, {
        { name = 'path' },
      }),
    })

    opts.window = opts.window or {}
    opts.window.completion = opts.window.completion or {}
    opts.window.completion.max_height = 20

    return opts
  end,
}
