return {
  "nvimtools/none-ls.nvim",
  opts = function(_, opts)
    local null_ls = require("null-ls")

    -- Custom code action for adding ignore comments
    local ignore_diagnostic = {
      name = "ignore_diagnostic",
      method = null_ls.methods.CODE_ACTION,
      filetypes = { "python" },
      generator = {
        fn = function(params)
          local actions = {}
          local diagnostics = vim.diagnostic.get(params.bufnr, { lnum = params.row - 1 })

          for _, d in ipairs(diagnostics) do
            if d.source == "mypy" and d.code then
              table.insert(actions, {
                title = "Ignore mypy: " .. d.code,
                action = function()
                  local line = vim.api.nvim_buf_get_lines(params.bufnr, params.row - 1, params.row, false)[1]
                  vim.api.nvim_buf_set_lines(params.bufnr, params.row - 1, params.row, false,
                    { line .. "  # type: ignore[" .. d.code .. "]" })
                end,
              })
            elseif d.source == "Ruff" and d.code then
              table.insert(actions, {
                title = "Ignore ruff: " .. d.code,
                action = function()
                  local line = vim.api.nvim_buf_get_lines(params.bufnr, params.row - 1, params.row, false)[1]
                  vim.api.nvim_buf_set_lines(params.bufnr, params.row - 1, params.row, false,
                    { line .. "  # noqa: " .. d.code })
                end,
              })
            end
          end

          return actions
        end,
      },
    }

    opts.sources = opts.sources or {}
    table.insert(opts.sources, ignore_diagnostic)
  end,
}
