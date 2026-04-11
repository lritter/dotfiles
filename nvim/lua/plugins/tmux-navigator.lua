return {
  "alexghergh/nvim-tmux-navigation",
  lazy = false, -- Ensure the plugin loads immediately
  init = function()
    -- Tell Neovim that the specific escape sequence is <D-h>
    -- This MUST run before the mappings below are bound
    vim.cmd([[
      set <D-h>=\e[1;9h
      set <D-j>=\e[1;9j
      set <D-k>=\e[1;9k
      set <D-l>=\e[1;9l
    ]])
  end,
  keys = {
    -- Override default LazyVim keymaps for buffer navigation with tmux navigation
    {
      "<C-h>",
      function()
        require("nvim-tmux-navigation").NvimTmuxNavigateLeft()
      end,
      mode = { "n", "i", "t" },
      desc = "Navigate Left",
    },
    {
      "<C-j>",
      function()
        require("nvim-tmux-navigation").NvimTmuxNavigateDown()
      end,
      mode = { "n", "i", "t" },
      desc = "Navigate Down",
    },
    {
      "<C-k>",
      function()
        require("nvim-tmux-navigation").NvimTmuxNavigateUp()
      end,
      mode = { "n", "i", "t" },
      desc = "Navigate Up",
    },
    {
      "<C-l>",
      function()
        require("nvim-tmux-navigation").NvimTmuxNavigateRight()
      end,
      mode = { "n", "i", "t" },
      desc = "Navigate Right",
    },
  },
}
