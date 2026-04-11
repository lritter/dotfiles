-- Neotest Python configuration
-- Adds <leader>td to run tests in directory (from buffer or Snacks explorer)

local function run_tests_in_directory()
  local neotest = require("neotest")
  local path = nil

  -- Check if we're in the Snacks explorer by looking at filetype
  local ft = vim.bo.filetype
  if ft == "snacks_picker_list" or ft == "snacks_explorer" then
    -- Try to get the explorer picker and current item
    local ok, pickers = pcall(function()
      return Snacks.picker.get({ source = "explorer" })
    end)

    if ok and pickers and pickers[1] then
      local explorer = pickers[1]
      local item = explorer:current()
      if item and item.file then
        path = item.file
      end
    end
  end

  -- Fallback: use current buffer's file path
  if not path then
    path = vim.fn.expand("%:p")
  end

  -- Normalize: if it's a file, get its directory
  if path and path ~= "" then
    if vim.fn.isdirectory(path) == 0 then
      path = vim.fn.fnamemodify(path, ":h")
    end

    vim.notify("Running tests in: " .. path, vim.log.levels.INFO)
    neotest.run.run(path)
  else
    vim.notify("Could not determine directory for tests", vim.log.levels.WARN)
  end
end

return {
  {
    "nvim-neotest/neotest",
    keys = {
      {
        "<leader>td",
        run_tests_in_directory,
        desc = "Run tests in directory",
      },
    },
  },
}
