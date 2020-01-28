-- shared logic for loading / saving settings
-- this file pollutes the global namespace

function load_settings()
  local fd=io.open(norns.state.data .. SETTINGS_FILE,"r")
  local page
  if fd then
    io.input(fd)
    local str = io.read()
    io.close(fd)
    if str ~= "" then
      page = tonumber(str)
    end
  end
  set_page(page or 1)
end

function save_settings()
  local fd=io.open(norns.state.data .. SETTINGS_FILE,"w+")
  io.output(fd)
  io.write(get_page() .. "\n")
  io.close(fd)
end
