local ConfigReload = {}

-- Re-apply Config.App.lua defaults, then Config.Local.lua overrides.
function ConfigReload.Run ()
  local app = Config.app
  dofile('./script/Config.App.lua')
  Config.app = app
  if io.exists('./script/Config.Local.lua') then
    dofile('./script/Config.Local.lua')
  end
end

return ConfigReload
