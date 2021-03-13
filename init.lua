
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

--[[
-- TODO: turn this into tests
minetest.after(2, function ()

	local player = minetest.get_player_by_name("singleplayer")

	local mod_specific_notifier = notify.mod_notifier('mod_name')
	local chat_notifier = notify.notifier('chat')
	local mod_specific_chat_notifier = chat_notifier:mod_notifier('mod_name')
	local form_notifier = notify.notifier('formspec')
	local mod_specific_form_notifier = form_notifier:mod_notifier('mod_name')


	notify(player, "DEFAULT")
	minetest.after(1, function ()
		notify(player, "DEFAULT2")
	end)
	mod_specific_notifier(player, "MOD SPECIFIC\nhello")
	mod_specific_chat_notifier(player, "MOD SPECIFIC CHAT\nhello")
	chat_notifier(player, "CHAT")
	-- minetest.after(5, function ()
	-- 	form_notifier:notify(player, "testy test\ntes")
	-- end)
	-- minetest.after(7, function ()
	-- 	form_notifier:notify(player, "SECOND!")
	-- end)
end)
--]]