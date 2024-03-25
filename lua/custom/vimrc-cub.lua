-- Ported ~/.vimrc@cubuanic
--

local VIMRC = {}

function VIMRC.tag_back_or_alternate()
  local ok, err = pcall(vim.cmd.pop)
  if not ok then
    if err:match("E73") or err:match("E555") or err:match("E556") then
      vim.cmd("silent edit #")
    else
      error(err)
    end
  end
end

function VIMRC.gf_or_tag()
  -- 1) try LSP go-to-definition
  local bufnr = 0
  local cfile = vim.fn.expand("<cfile>")
  local params = vim.lsp.util.make_position_params()
  local res = vim.lsp.buf_request_sync(bufnr, "textDocument/definition", params, 300)

  local function first_location(r)
    if not r then return nil end
    for _, v in pairs(r) do
      local result = v.result
      if result then
        if vim.tbl_islist(result) then
          return result[1]
        else
          return result
        end
      end
    end
    return nil
  end

  local loc = first_location(res)
  if loc then
    vim.lsp.util.jump_to_location(loc, "utf-8", true)
    return
  end

  -- 2. fallback to <gf> if <file> under cursor
  local cfile = vim.fn.expand("<cfile>")
  if vim.fn.filereadable(cfile) == 1 then
    vim.cmd.normal({ "gf", bang = true })
    return
  end

  -- 3. Fallback to tags
  vim.cmd.normal({ "<C-]>", bang = true })
end


-- fix for LSP "grd"
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'perl',
  callback = function()
    vim.opt_local.iskeyword:append(':')
  end,
})

vim.keymap.set("n", "<BS>",    VIMRC.tag_back_or_alternate, { silent = true, desc = "Tag back or alternate file" })
vim.keymap.set("n", "<CR>",    VIMRC.gf_or_tag,             { silent = true, desc = "gf or tag" })

return VIMRC

-- vim: ts=2 sts=2 sw=2 et

