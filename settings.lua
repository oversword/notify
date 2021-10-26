local direction_map = {
	['left-right'] = 0,
	['right-left'] = 1,
	['top-bottom'] = 2,
	['bottom-top'] = 3
}

local function position_array(v)
	return {x=v[1],y=v[2]}
end

local types = config.types

notify.settings = config.settings_model('notify', {
	default_method = types.enum('hud', { options={ 'hud', 'chat', 'formspec' } }),
	hud = {
		default_position = types.array({ 0.1, 0.9 }, { type=types.number(0, { min=0, max=1 }) }, position_array),
		default_alignment = types.array({ 1, -1 }, { type=types.number(0, { min=-1, max=1 }) }, position_array),
		default_offset = types.array({ 0, 0 }, { type=types.number(0) }, position_array),
		default_direction = types.enum('left-right', { options={ 'left-right', 'right-left', 'top-bottom', 'bottom-top' } }, direction_map),
		default_duration = types.integer(3, { min=0, max=1000 }),
		default_conflict_behaviour = types.enum('stack', { options={'stack','stack-up','stack-down','overwrite','ignore','wait'} }),
		default_color = types.color('#FFFFFF'),
	},
	chat = {
		default_color = types.color('#FFFFFF')
	},
	formspec = {
		default_color = types.color('#FFFFFF')
	}
})