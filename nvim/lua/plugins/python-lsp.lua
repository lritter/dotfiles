-- Python LSP configuration: basedpyright + ruff
-- Configures venv detection and LSP cooperation

return {
  -- Configure basedpyright for better venv detection
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          mason = false,
          autostart = false,
          settings = {
            basedpyright = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
              },
            },
            python = {
              venvPath = ".",
              venv = ".venv",
            },
          },
        },
        ruff = {
          -- Disable hover in favor of basedpyright
          on_attach = function(client, _)
            client.server_capabilities.hoverProvider = false
          end,
        },
      },
    },
  },

  -- Ensure mason installs the tools
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "basedpyright",
        "ruff",
      },
    },
  },
}
