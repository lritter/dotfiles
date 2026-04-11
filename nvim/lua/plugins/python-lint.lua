-- Python linting with mypy via nvim-lint
-- Uses project's venv mypy to ensure proper package resolution

return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.python = opts.linters_by_ft.python or {}
      table.insert(opts.linters_by_ft.python, "mypy")

      opts.linters = opts.linters or {}
      opts.linters.mypy = {
        cmd = function()
          -- Prefer project's venv mypy over mason's
          local venv_mypy = vim.fn.getcwd() .. "/.venv/bin/mypy"
          if vim.fn.executable(venv_mypy) == 1 then
            return venv_mypy
          end
          -- Fall back to mason's mypy
          return vim.fn.stdpath("data") .. "/mason/bin/mypy"
        end,
      }
    end,
  },
}
