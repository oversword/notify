

local HUDNotifier = {}
local __hud_id = 0
local function hud_id()
	__hud_id = __hud_id + 1
	return __hud_id
end

local function stack_up(stack)
	local text
	for _,rec in ipairs(stack) do
		if text then
			text = rec.text .. "\n" .. text
		else
			text = rec.text
		end
	end
	return text or ''
end

local function stack_down(stack)
	local text
	for _,rec in ipairs(stack) do
		if text then
			text = text .. "\n" .. rec.text
		else
			text = rec.text
		end
	end
	return text or ''
end

function HUDNotifier:new(attrs)
	local o = {
		player_huds = {},
		duration = attrs.duration or notify.settings.hud.default_duration,
		position = attrs.position or notify.settings.hud.default_position,
		alignment = attrs.alignment or notify.settings.hud.default_alignment,
		offset = attrs.offset or notify.settings.hud.default_offset,
		direction = attrs.direction or notify.settings.hud.default_direction,
		text_color = 0xFFFFFF
	}
	local conflict_behaviour = attrs.conflict_behaviour or notify.settings.hud.default_conflict_behaviour
	if conflict_behaviour == 'stack' then
		if o.alignment.y > 0 then
			conflict_behaviour = 'stack-up'
		else
			conflict_behaviour = 'stack-down'
		end
	end
	o.conflict_behaviour = conflict_behaviour
	o.name = 'notify_feedback_'..tostring(hud_id())

	setmetatable(o, self)
	self.__index = self
	return o
end

function HUDNotifier:notify(player, message)

	if not (player and player.hud_add) then
		return
	end

	local player_name = player:get_player_name()
	local hud = self.player_huds[player_name]

	local message_record = {
		text = message,
		time = os.time()
	}

	if hud then
		if self.conflict_behaviour == 'ignore' then
		elseif self.conflict_behaviour == 'wait' then
			table.insert(hud.stack, message_record)
		elseif self.conflict_behaviour == 'stack-up' then
			table.insert(hud.stack, message_record)
			local text = stack_up(hud.stack)
			minetest.after(0, function ()
				player:hud_change(hud.id, 'text', text)
			end)
			minetest.after(self.duration, function()
				self:update(player)
			end)
		elseif self.conflict_behaviour == 'stack-down' then
			table.insert(hud.stack, message_record)
			local text = stack_down(hud.stack)
			minetest.after(0, function ()
				player:hud_change(hud.id, 'text', text)
			end)
			minetest.after(self.duration, function()
				self:update(player)
			end)
		elseif self.conflict_behaviour == 'overwrite' then
			hud.stack = { message_record }
			minetest.after(0, function ()
				player:hud_change(hud.id, 'text', message)
			end)
			minetest.after(self.duration, function()
				self:update(player)
			end)
		end
	else
		local def = {
			position = self.position,
			alignment = self.alignment,
			offset = self.offset,
			number = self.text_color,-- or normal_color
			direction = self.direction,
			hud_elem_type = 'text', --  def.hud_elem_type or 
			name = self.name
		}
		def.text = message
		local id = player:hud_add(def)
		self.player_huds[player_name] = {
			id = id,
			stack = { message_record }
		}
		minetest.after(self.duration, function()
			self:update(player)
		end)
	end
end

function HUDNotifier:update(player)
	local player_name = player:get_player_name()
	local hud = self.player_huds[player_name]
	if not hud then return end

	if self.conflict_behaviour == 'stack-up'
	or self.conflict_behaviour == 'stack-down' then
		local clean_stack = {}
		for _,rec in ipairs(hud.stack) do
			if os.time() < rec.time + self.duration then
				table.insert(clean_stack, rec)
			end
		end
		hud.stack = clean_stack
	end

	if self.conflict_behaviour == 'wait' then
		table.remove(hud.stack, 1)
		if #hud.stack > 0 then
			player:hud_change(hud.id, 'text', hud.stack[1].text)
			minetest.after(self.duration, function()
				self:update(player)
			end)
		else
			player:hud_remove(hud.id)
			self.player_huds[player_name] = nil
		end
	elseif self.conflict_behaviour == 'stack-up' then
		if #hud.stack > 0 then
			local text = stack_up(hud.stack)
			player:hud_change(hud.id, 'text', text)
		else
			player:hud_remove(hud.id)
			self.player_huds[player_name] = nil
		end
	elseif self.conflict_behaviour == 'stack-down' then
		if #hud.stack > 0 then
			local text = stack_down(hud.stack)
			player:hud_change(hud.id, 'text', text)
		else
			player:hud_remove(hud.id)
			self.player_huds[player_name] = nil
		end
	elseif self.conflict_behaviour == 'overwrite' then
		if os.time() >= hud.stack[1].time + self.duration then
			player:hud_remove(hud.id)
			self.player_huds[player_name] = nil
		end
	else
		player:hud_remove(hud.id)
		self.player_huds[player_name] = nil
	end
end

notify.HUDNotifier = HUDNotifier