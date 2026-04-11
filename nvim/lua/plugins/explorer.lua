return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          include = {
            ".github",
            ".claude",
            ".local",
            "**/.env*",
            ".gitignore",
            ".pre-commit-config.yaml",
          },
        },
      },
    },
  },
}
