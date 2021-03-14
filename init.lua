
notify = {}
setmetatable(notify, notify)
notify.__call = function(self,...)
	return self.notify(...)
end

dofile(minetest.get_modpath(minetest.get_current_modname())..'/settings.lua')
dofile(minetest.get_modpath(minetest.get_current_modname())..'/hud_notifier.lua')
dofile(minetest.get_modpath(minetest.get_current_modname())..'/notifier.lua')

local default_notifier
function notify.set_default_notifier(new_default)
	default_notifier = new_default
	notify.notify = function (...)
		return default_notifier:notify(...)
	end
	notify.mod_notifier = function (...)
		return default_notifier:mod_notifier(...)
	end
end

function notify.notifier(method, config)
	return notify.Notifier:new({
		method = method,
		config = config
	})
end

notify.set_default_notifier(notify.notifier(notify.settings.default_method))
dofile(minetest.get_modpath(minetest.get_current_modname())..'/test.lua')
