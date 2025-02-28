local config = require("projects_nvim.config")
local history = require("projects_nvim.utils.history")
local path = require("projects_nvim.utils.path")
local M = {}

-- Internal states
M.last_project = nil

function M.set_pwd(dir, method)
  if dir ~= nil then
    M.last_project = dir
    table.insert(history.session_projects, dir)

    if vim.fn.getcwd() ~= dir then
      local scope_chdir = config.options.scope_chdir
      if scope_chdir == "global" then
        vim.api.nvim_set_current_dir(dir)
      elseif scope_chdir == "tab" then
        vim.cmd("tcd " .. dir)
      elseif scope_chdir == "win" then
        vim.cmd("lcd " .. dir)
      else
        return
      end

      if config.options.silent_chdir == false then
        vim.notify("Set CWD to " .. dir .. " using " .. method)
      end
    end
    return true
  end

  return false
end

function M.is_file()
  local buf_type = vim.api.nvim_buf_get_option(0, "buftype")

  local whitelisted_buf_type = { "", "acwrite" }
  local is_in_whitelist = false
  for _, wtype in ipairs(whitelisted_buf_type) do
    if buf_type == wtype then
      is_in_whitelist = true
      break
    end
  end
  if not is_in_whitelist then
    return false
  end

  return true
end

function M.on_buf_enter()
  if vim.v.vim_did_enter == 0 then
    return
  end

  if not M.is_file() then
    return
  end

  local current_dir = vim.fn.expand("%:p:h", true)
  if not path.exists(current_dir) or path.is_excluded(current_dir) then
    return
  end

  local root = vim.fs.root(current_dir, config.options.patterns)
  M.set_pwd(root, "git")
end

function M.add_project_manually()
  local current_dir = vim.fn.expand("%:p:h", true)
  M.set_pwd(current_dir, "manual")
end

function M.init()
  local autocmds = {}
  if not config.options.manual_mode then
    autocmds[#autocmds + 1] = 'autocmd VimEnter,BufEnter * ++nested lua require("projects_nvim.project").on_buf_enter()'
  end

  vim.cmd([[
    command! ProjectRoot lua require("projects_nvim.project").on_buf_enter()
    command! AddProject lua require("projects_nvim.project").add_project_manually()
  ]])

  autocmds[#autocmds + 1] =
    'autocmd VimLeavePre * lua require("projects_nvim.utils.history").write_projects_to_history()'

  vim.cmd([[augroup projects_nvim
            au!
  ]])
  for _, value in ipairs(autocmds) do
    vim.cmd(value)
  end
  vim.cmd("augroup END")

  history.read_projects_from_history()
end

return M
