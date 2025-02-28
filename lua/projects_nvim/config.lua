local M = {}

---@class ProjectOptions
M.defaults = {
  -- Manual mode doesn't automatically change your root directory, so you have
  -- the option to manually do so using `:ProjectRoot` command.
  manual_mode = false,

  -- All the patterns used to detect root dir, when **"pattern"** is in
  -- detection_methods
  -- patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json" },
  patterns = { ".git" },

  -- Show hidden files in telescope
  show_hidden = false,

  -- When set to false, you will get a message when project.nvim changes your
  -- directory.
  silent_chdir = true,

  exclude_dirs = {},

  -- What scope to change the directory, valid options are
  -- * global (default)
  -- * tab
  -- * win
  scope_chdir = "global",

  -- Path where project.nvim will store the project history for use in
  -- telescope
  datapath = vim.fn.stdpath("data"),
}

---@type ProjectOptions
---@diagnostic disable-next-line: missing-fields
M.options = {}

M.setup = function(options)
  M.options = vim.tbl_deep_extend("force", M.defaults, options or {})

  vim.opt.autochdir = false -- implicitly unset autochdir

  require("projects_nvim.utils.path").init()
  require("projects_nvim.project").init()
end

return M
