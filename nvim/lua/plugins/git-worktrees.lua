-- return {
--   "polarmutex/git-worktree.nvim",
--   version = "^2",
--   dependencies = { "nvim-lua/plenary.nvim" },
--   keys = {
--     { "<leader>gw", "<cmd>Telescope git_worktree git_worktrees<cr>", desc = "Switch Worktree" },
--     { "<leader>gW", "<cmd>Telescope git_worktree create_git_worktree<cr>", desc = "Create Worktree" },
--   },
-- }
--

return {
  "polarmutex/git-worktree.nvim",
  version = "^2", -- It is recommended to use the v2 branch
  dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
  enabled = true,
  keys = {
    { "<leader>gw", "<cmd>Telescope git_worktree git_worktree<cr>", desc = "Switch Worktree" },
    { "<leader>gW", "<cmd>Telescope git_worktree create_git_worktree<cr>", desc = "Create Worktree" },
  },
  config = function()
    require("telescope").load_extension("git_worktree")
  end,
}
