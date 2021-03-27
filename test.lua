
if not minetest.global_exists('test') then return end

local describe = test.describe
local it = test.it
local stub = test.stub


local test_hud_id = 'test_id'

local hud_add_stub = stub(function (player, def)
	return test_hud_id
end)
local hud_change_stub = stub()
local hud_remove_stub = stub()

local test_player_name = 'test_player'
local test_player = {
	get_player_name = function ()
		return test_player_name
	end,
	hud_add = hud_add_stub.call,
	hud_change = hud_change_stub.call,
	hud_remove = hud_remove_stub.call
}

local test_hud_args = {
	position = {x=0,y=0},
	alignment = {x=0,y=0},
	offset = {x=0,y=0},
	direction = 0,
}
local test_hud_config = table.copy(test_hud_args)
test_hud_config.duration = 5
test_hud_config.conflict_behaviour = 'stack-up'
test_hud_config.color = "#FFFFFF"

local test_hud_def = table.copy(test_hud_args)
test_hud_def.number = 0xFFFFFF
test_hud_def.hud_elem_type = 'text'

local get_player_stub = stub(function (name)
	return test_player
end)

local send_chat_stub = stub()


describe("Notify", function ()
	local get_player_orig = minetest.get_player_by_name
	minetest.get_player_by_name = get_player_stub.call
	test.after_all(function ()
		minetest.get_player_by_name = get_player_orig
	end)
	describe("HUD Notifier",function ()
		it("adds a hud to our player", function ()
			local hud_notifier = notify.notifier('hud', test_hud_config)
			test_hud_def.name = 'notify_feedback_2'
			test_hud_def.text = "Hello"

			hud_notifier:notify(test_player_name, "Hello")

			get_player_stub.called_times(1)
			get_player_stub.called_with(test_player_name)
			hud_add_stub.called_times(1)
			hud_add_stub.called_with(test_player, test_hud_def)
			hud_remove_stub.to_be_called_times(1)
			hud_remove_stub.to_be_called_in_with(5, test_player, test_hud_id)
		end)
		it("prefixes text to the hud when in stack-up mode", function ()
			test_hud_config.conflict_behaviour = 'stack-up'
			local hud_notifier = notify.notifier('hud', test_hud_config)
			test_hud_def.name = 'notify_feedback_3'
			test_hud_def.text = "Hello"

			hud_notifier:notify(test_player_name, "Hello")
			hud_notifier:notify(test_player_name, "Again")

			hud_add_stub.called_times(1)
			hud_add_stub.called_with(test_player, test_hud_def)
			hud_change_stub.to_be_called_times(1)
			hud_change_stub.to_be_called_in_with(0, test_player, test_hud_id, 'text', "Again\nHello")
			hud_remove_stub.to_be_called_times(1)
			hud_remove_stub.to_be_called_in_with(5, test_player, test_hud_id)
		end)
		it("postfixes text to the hud when in stack-down mode", function ()
			test_hud_config.conflict_behaviour = 'stack-down'
			local hud_notifier = notify.notifier('hud', test_hud_config)
			test_hud_def.name = 'notify_feedback_4'
			test_hud_def.text = "Hello"

			hud_notifier:notify(test_player_name, "Hello")
			hud_notifier:notify(test_player_name, "Again")

			hud_add_stub.called_times(1)
			hud_add_stub.called_with(test_player, test_hud_def)
			hud_change_stub.to_be_called_times(1)
			hud_change_stub.to_be_called_in_with(0, test_player, test_hud_id, 'text', "Hello\nAgain")
			hud_remove_stub.to_be_called_times(1)
			hud_remove_stub.to_be_called_in_with(5, test_player, test_hud_id)
		end)
		it("overrides text to the hud when in overwrite mode", function ()
			test_hud_config.conflict_behaviour = 'overwrite'
			local hud_notifier = notify.notifier('hud', test_hud_config)
			test_hud_def.name = 'notify_feedback_5'
			test_hud_def.text = "Hello"

			hud_notifier:notify(test_player_name, "Hello")
			hud_notifier:notify(test_player_name, "Again")

			hud_add_stub.called_times(1)
			hud_add_stub.called_with(test_player, test_hud_def)
			hud_change_stub.to_be_called_times(1)
			hud_change_stub.to_be_called_in_with(0, test_player, test_hud_id, 'text', "Again")
			hud_remove_stub.to_be_called_times(1)
			hud_remove_stub.to_be_called_in_with(5, test_player, test_hud_id)
		end)
		it("ignores additional messages to the hud when in ignore mode", function ()
			test_hud_config.conflict_behaviour = 'ignore'
			local hud_notifier = notify.notifier('hud', test_hud_config)
			test_hud_def.name = 'notify_feedback_6'
			test_hud_def.text = "Hello"

			hud_notifier:notify(test_player_name, "Hello")
			hud_notifier:notify(test_player_name, "Again")

			hud_add_stub.called_times(1)
			hud_add_stub.called_with(test_player, test_hud_def)
			hud_change_stub.to_be_called_times(0)
			hud_remove_stub.to_be_called_times(1)
			hud_remove_stub.to_be_called_in_with(5, test_player, test_hud_id)
		end)
		it("waits for the existing message to be removed from the hud when in wait mode", function ()
			test_hud_config.conflict_behaviour = 'wait'
			local hud_notifier = notify.notifier('hud', test_hud_config)
			test_hud_def.name = 'notify_feedback_7'
			test_hud_def.text = "Hello"

			hud_notifier:notify(test_player_name, "Hello")
			hud_notifier:notify(test_player_name, "Again")

			hud_add_stub.called_times(1)
			hud_add_stub.called_with(test_player, test_hud_def)
			hud_change_stub.to_be_called_times(1)
			hud_change_stub.to_be_called_in_with(5, test_player, test_hud_id, 'text', "Again")
			hud_remove_stub.to_be_called_times(1)
			hud_remove_stub.to_be_called_in_with(5+5, test_player, test_hud_id)
		end)
		it("properly removes and re-creates hud for non-overlapping calls", function ()
			test_hud_config.conflict_behaviour = 'wait'
			local hud_notifier = notify.notifier('hud', test_hud_config)
			test_hud_def.name = 'notify_feedback_8'
			test_hud_def.text = "Hello"

			local test_hud_def2 = table.copy(test_hud_def)
			test_hud_def2.text = "Again"

			hud_notifier:notify(test_player_name, "Hello")
			minetest.after(10, function ()
				hud_notifier:notify(test_player_name, "Again")
			end)

			hud_change_stub.to_be_called_times(0)
			hud_remove_stub.to_be_called_times(2)

			hud_add_stub.called_times(1)
			hud_add_stub.to_be_called_times(2)

			hud_add_stub.called_with(test_player, test_hud_def)
			hud_remove_stub.to_be_called_in_with(5, test_player, test_hud_id)

			hud_add_stub.to_be_called_in_with(10, test_player, test_hud_def2)
			hud_remove_stub.to_be_called_in_with(10+5, test_player, test_hud_id)
		end)
		it("prefixes the hud message with the mod name for a mod notifier", function ()
			test_hud_config.conflict_behaviour = 'stack-up'
			local hud_notifier = notify.notifier('hud', test_hud_config)
			local mod_hud_notifier = hud_notifier:mod_notifier('test_mod')
			test_hud_def.name = 'notify_feedback_9'
			test_hud_def.text = "[test_mod] Hello\n[test_mod] Again"

			mod_hud_notifier:notify(test_player_name, "Hello\nAgain")

			hud_add_stub.called_times(1)
			hud_add_stub.called_with(test_player, test_hud_def)
			hud_remove_stub.to_be_called_times(1)
			hud_remove_stub.to_be_called_in_with(5, test_player, test_hud_id)
		end)
		it("uses the same hud notifier instance in a mod notifier as it does in the extended base notifier", function ()
			test_hud_config.conflict_behaviour = 'stack-up'
			local hud_notifier = notify.notifier('hud', test_hud_config)
			local mod_hud_notifier = hud_notifier:mod_notifier('test_mod')
			test_hud_def.name = 'notify_feedback_10'
			test_hud_def.text = "Hello"
			local mod_test_hud_def = table.copy(test_hud_def)
			mod_test_hud_def.text = "[test_mod] Again"

			hud_notifier:notify(test_player_name, "Hello")
			minetest.after(10, function ()
				mod_hud_notifier:notify(test_player_name, "Again")
			end)

			hud_add_stub.called_times(1)
			hud_add_stub.to_be_called_times(2)
			hud_add_stub.called_with(test_player, test_hud_def)
			hud_add_stub.to_be_called_in_with(10, test_player, mod_test_hud_def)
			hud_remove_stub.to_be_called_times(2)
			hud_remove_stub.to_be_called_in_with(5, test_player, test_hud_id)
			hud_remove_stub.to_be_called_in_with(10+5, test_player, test_hud_id)
		end)
		it("staggers the removal of notifications when they are delayed in less time than the duration", function ()
			test_hud_config.conflict_behaviour = 'stack-down'
			local hud_notifier = notify.notifier('hud', test_hud_config)
			test_hud_def.name = 'notify_feedback_11'
			test_hud_def.text = "Hello"

			hud_notifier:notify(test_player_name, "Hello")
			minetest.after(2, function ()
				hud_notifier:notify(test_player_name, "Again")
			end)

			hud_add_stub.called_times(1)
			hud_add_stub.called_with(test_player, test_hud_def)
			hud_change_stub.to_be_called_times(2)
			hud_change_stub.to_be_called_in_with(2, test_player, test_hud_id, 'text', "Hello\nAgain")
			hud_change_stub.to_be_called_in_with(5, test_player, test_hud_id, 'text', "Again")
			hud_remove_stub.to_be_called_times(1)
			hud_remove_stub.to_be_called_in_with(7, test_player, test_hud_id)
		end)
	end)

	describe("Chat Notifier", function ()
		local send_chat_orig = minetest.chat_send_player
		minetest.chat_send_player = send_chat_stub.call
		test.after_all(function ()
			minetest.chat_send_player = send_chat_orig
		end)
		it("sends a message to our player", function ()
			local chat_notifier = notify.notifier('chat')
			local text = "Hello"

			chat_notifier:notify(test_player_name, text)

			get_player_stub.called_times(1)
			get_player_stub.called_with(test_player_name)
			send_chat_stub.called_times(1)
			send_chat_stub.called_with(test_player_name, minetest.colorize("#FFFFFF", text))
		end)
		it("crunches newlines to be double spaces", function ()
			local chat_notifier = notify.notifier('chat')
			local text = "Hello\nAgain"

			chat_notifier:notify(test_player_name, text)

			send_chat_stub.called_times(1)
			send_chat_stub.called_with(test_player_name, minetest.colorize("#FFFFFF", "Hello  Again"))
		end)
		it("prefixes a mod notifier with mod name", function ()
			local chat_notifier = notify.notifier('chat')
			local mod_chat_notifier = chat_notifier:mod_notifier('test_mod')
			local text = "Hello"

			mod_chat_notifier:notify(test_player_name, text)

			send_chat_stub.called_times(1)
			send_chat_stub.called_with(test_player_name, minetest.colorize("#FFFFFF", "[test_mod] Hello"))
		end)
	end)

	--TODO: test colours
	--TODO: formspec tests once functionality is decided

end)

test.execute()
