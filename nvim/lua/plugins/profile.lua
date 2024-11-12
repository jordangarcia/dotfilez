local function get_profile_filename()
  -- Get cache dir and format current date/time
  local cache_dir = vim.fn.stdpath "cache"
  local datetime = os.date "%Y-%m-%d_%H-%M-%S"
  return string.format("%s/profile-%s.log", cache_dir, datetime)
end

local current_profile_file = nil

local function start_profile()
  current_profile_file = get_profile_filename()
  print("Starting profile: " .. current_profile_file)
  vim.cmd(string.format("profile start %s", current_profile_file))
  vim.cmd "profile func *"
  vim.cmd "profile file *"
end

local function stop_profile()
  if not current_profile_file then
    print "No active profile session"
    return
  end

  print("Stopping profile: " .. current_profile_file)
  vim.cmd "profile pause"
  vim.cmd "profile dump"

  -- Open the profile log in a vsplit
  vim.cmd("vsplit " .. current_profile_file)

  -- Reset current profile file
  current_profile_file = nil
end

return {
  "profiler",
  dev = true,
  lazy = true,
  keys = {
    { "<leader>ps", start_profile, desc = "Start profile" },
    { "<leader>pp", stop_profile, desc = "Stop profile and view" },
  },
}
