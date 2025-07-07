local config = require("projects_nvim.config")
local history = require("projects_nvim.utils.history")
local project = require("projects_nvim.project")

local M = {
  setup = config.setup,
  get_recent_projects = history.get_recent_projects,
  file_project_root = project.file_project_root,
}

return M
