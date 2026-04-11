-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("v", "<D-c>", '"+y', { noremap = true, silent = true })

-- Indent/outdent with Cmd+] and Cmd+[ (via Ghostty keybinds sending escape sequences)
vim.keymap.set("n", "<M-]>", ">>", { noremap = true, silent = true, desc = "Indent line" })
vim.keymap.set("n", "<M-[>", "<<", { noremap = true, silent = true, desc = "Outdent line" })
vim.keymap.set("v", "<M-]>", ">gv", { noremap = true, silent = true, desc = "Indent selection" })
vim.keymap.set("v", "<M-[>", "<gv", { noremap = true, silent = true, desc = "Outdent selection" })
vim.keymap.set("i", "<M-]>", "<C-t>", { noremap = true, silent = true, desc = "Indent line" })
vim.keymap.set("i", "<M-[>", "<C-d>", { noremap = true, silent = true, desc = "Outdent line" })

-- Diagnostics to quickfix/location list
vim.keymap.set("n", "<leader>xs", vim.diagnostic.setloclist, { desc = "Buffer diagnostics to loclist" })
vim.keymap.set("n", "<leader>xS", vim.diagnostic.setqflist, { desc = "All diagnostics to quickfix" })

-- Open quickfix in trouble (if not already open)
local function open_trouble_qf()
  local trouble = require("trouble")
  if not trouble.is_open({ mode = "quickfix" }) then
    trouble.open({ mode = "quickfix" })
  end
end

-- Find project root by searching upward for common markers
local function find_project_root()
  local markers = { "pyproject.toml", "setup.py", "setup.cfg", ".git", "ruff.toml", ".ruff.toml", "mypy.ini" }
  local buf_path = vim.api.nvim_buf_get_name(0)
  local start_dir = buf_path ~= "" and vim.fn.fnamemodify(buf_path, ":h") or vim.fn.getcwd()

  local found = vim.fs.find(markers, {
    upward = true,
    path = start_dir,
    stop = vim.env.HOME,
  })

  if #found > 0 then
    return vim.fn.fnamemodify(found[1], ":h")
  end
  return vim.fn.getcwd()
end

-- Run project diagnostics
local function run_ruff()
  local root = find_project_root()
  local cmd = string.format("cd %s && ruff check --output-format=concise .", vim.fn.shellescape(root))
  vim.cmd('cexpr system("' .. cmd:gsub('"', '\\"') .. '")')
end

local function run_mypy()
  local root = find_project_root()
  local cmd = string.format("cd %s && mypy --show-column-numbers .", vim.fn.shellescape(root))
  vim.cmd('caddexpr system("' .. cmd:gsub('"', '\\"') .. '")')
end

vim.keymap.set("n", "<leader>xdr", function()
  run_ruff()
  open_trouble_qf()
end, { desc = "Ruff" })

vim.keymap.set("n", "<leader>xdm", function()
  vim.fn.setqflist({})
  run_mypy()
  open_trouble_qf()
end, { desc = "Mypy" })

vim.keymap.set("n", "<leader>xdd", function()
  run_ruff()
  run_mypy()
  open_trouble_qf()
end, { desc = "All (ruff + mypy)" })
