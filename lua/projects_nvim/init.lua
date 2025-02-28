local config = require("projects_nvim.config")
local history = require("projects_nvim.utils.history")

local M = {
  setup = config.setup,
  get_recent_projects = history.get_recent_projects,
}

return M
