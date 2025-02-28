local telescope = require("telescope")

local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local telescope_config = require("telescope.config").values
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local builtin = require("telescope.builtin")
local entry_display = require("telescope.pickers.entry_display")

local history = require("projects_nvim.utils.history")
local project = require("projects_nvim.project")
local p_config = require("projects_nvim.config")

----------
-- Actions
----------

local function create_finder()
  local results = history.get_recent_projects()

  -- Reverse results
  for i = 1, math.floor(#results / 2) do
    results[i], results[#results - i + 1] = results[#results - i + 1], results[i]
  end
  local displayer = entry_display.create({
    separator = " ",
    items = {
      {
        width = 30,
      },
      {
        remaining = true,
      },
    },
  })

  local function make_display(entry)
    return displayer({ entry.name, { entry.value, "Comment" } })
  end

  return finders.new_table({
    results = results,
    entry_maker = function(entry)
      local name = vim.fn.fnamemodify(entry, ":t")
      return {
        display = make_display,
        name = name,
        value = entry,
        ordinal = name .. " " .. entry,
      }
    end,
  })
end

local function change_working_directory(prompt_bufnr, prompt)
  local selected_entry = state.get_selected_entry(prompt_bufnr)
  if selected_entry == nil then
    actions.close(prompt_bufnr)
    return
  end
  local project_path = selected_entry.value
  if prompt == true then
    actions._close(prompt_bufnr, true)
  else
    actions.close(prompt_bufnr)
  end
  local cd_successful = project.set_pwd(project_path, "telescope")
  return project_path, cd_successful
end

local function find_project_files(prompt_bufnr)
  local opt = {
    cwd = project.last_project,
    hidden = p_config.options.show_hidden,
    mode = "insert",
  }
  builtin.find_files(opt)
end

local function browse_project_files(prompt_bufnr)
  local project_path, cd_successful = change_working_directory(prompt_bufnr, true)
  local opt = {
    cwd = project_path,
    hidden = p_config.options.show_hidden,
  }
  if cd_successful then
    builtin.file_browser(opt)
  end
end

local function search_in_project_files(prompt_bufnr)
  local project_path, cd_successful = change_working_directory(prompt_bufnr, true)
  local opt = {
    cwd = project_path,
    hidden = p_config.options.show_hidden,
    mode = "insert",
  }
  if cd_successful then
    builtin.live_grep(opt)
  end
end

local function recent_project_files(prompt_bufnr)
  local _, cd_successful = change_working_directory(prompt_bufnr, true)
  local opt = {
    cwd_only = true,
    hidden = p_config.options.show_hidden,
  }
  if cd_successful then
    builtin.oldfiles(opt)
  end
end

local function delete_project(prompt_bufnr)
  local selectedEntry = state.get_selected_entry(prompt_bufnr)
  if selectedEntry == nil then
    actions.close(prompt_bufnr)
    return
  end
  local choice = vim.fn.confirm("Delete '" .. selectedEntry.value .. "' from project list?", "&Yes\n&No", 2)

  if choice == 1 then
    history.delete_project(selectedEntry)

    local finder = create_finder()
    state.get_current_picker(prompt_bufnr):refresh(finder, {
      reset_prompt = true,
    })
  end
end

---Main entrypoint for Telescope.
---@param opts table
local function projects(opts)
  opts = opts or {}

  pickers
    .new(opts, {
      prompt_title = "Recent Projects",
      finder = create_finder(),
      previewer = false,
      sorter = telescope_config.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        map("n", "f", find_project_files)
        map("n", "b", browse_project_files)
        map("n", "d", delete_project)
        map("n", "s", search_in_project_files)
        map("n", "r", recent_project_files)
        map("n", "w", change_working_directory)

        map("i", "<c-f>", find_project_files)
        map("i", "<c-b>", browse_project_files)
        map("i", "<c-d>", delete_project)
        map("i", "<c-s>", search_in_project_files)
        map("i", "<c-r>", recent_project_files)
        map("i", "<c-w>", change_working_directory)

        local on_project_selected = function()
          local selected = state.get_selected_entry(prompt_bufnr).value
          local dir = vim.fn.fnamemodify(selected, ":p:h")
          project.last_project = dir
          vim.fn.chdir(dir)
          find_project_files(prompt_bufnr)
        end
        actions.select_default:replace(on_project_selected)
        return true
      end,
    })
    :find()
end

---Main entrypoint for Telescope.
---@param opts table
local function last_project_find_file(opts)
  opts = opts or {}

  builtin.find_files({
    prompt_title = "project files",
    cwd = project.last_project,
  })
end

local function last_project_live_grep(opts)
  builtin.live_grep(opts, {
    prompt_title = "project live grep",
    cwd = project.last_project,
  })
end

local function pwd_find_file(opts)
  opts = opts or {}
  local cwd = vim.fn.expand("%:p:h")

  builtin.find_files({
    prompt_title = "pwd files",
    cwd = cwd,
  })
end

local M = telescope.register_extension({
  setup = p_config.setup,
  exports = {
    projects_nvim = projects,
    project_files = last_project_find_file,
    project_live_grep = last_project_live_grep,
    find_files = pwd_find_file,
  },
})

return M
