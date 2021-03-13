# Notify - MineTest
> Provides a simple API for sending consistent notifications to a user across a variety of mods, via the HUD, chat message or a pop-up formspec

## Default behaviour
A default notifier is provided that notifies to the HUD (check settings to change this default behaviour)

```
notify( player, "message" )
notify.notify( player, "message" )
```
As you can see here, `notify.notify(...)` is effectively an alias for just calling `notify(...)` directly.

## Mod-Specific Notifier
To inform the user which mod a notification is coming from, you should create a new mod notifier for each mod you use this in, then re-use that mod notifier over and over within that mod.
You do not need to configure a mod notifier, you should call `mod_notifier` on an existing notifier to use its pre-existing configuration.
```
local notify_mymod = notify.mod_notifier("my_mod")
notify_mymod( player, "message" )
notify_mymod:notify( player, "message" )
```
Please note that when you create your own notifier you will need to use `:notify` instead of `.notify`, any methods on the `notify` global are really just proxies to the default notifier.

## Creating New Notifiers
You can create your own notifiers if you desire a different behaviour for your specific implementation, here we create a chat notifier, and then extend a mod-specific notifier from it later.
```
local chat_notifier = notify.notifier('chat')
chat_notifier( player, "message" )
chat_notifier:notify( player, "message" )

local chat_notify_mymod = chat_notifier:mod_notifier("my_mod")
chat_notify_mymod( player, "message" )
chat_notify_mymod:notify( player, "message" )
```

## Setting the Default Notifier
The default notifier can be overridden if the existing settings are not enough for you
```
local notifier_config = {
  position = { x = 0.9, y = 0.9 },
  alignment = { x = -1, y = -1 }
}
local new_default_notifier = notify.notifier( 'hud', notifier_config )
notify.set_default_notifier( new_default_notifier )
```


## Settings
> most of this information is pulled from settingtypes.txt, check that file for the most up-to-date information

> See HUD docs for more details https://dev.minetest.net/HUD

|Config Setting | Description | Data Type | Default | Possible Values | Extra Information
|--|--|--|--|--|--|
|notify.default_method | Display method of the default notification factory | enum | hud | hud,chat,formspec | 
|notify.hud.default_position | Default on-screen position of a HUD | v3f | (0.1, 0.9, 0) | | Only first 2 values will be used, will be relative to the size of the screen, between 0 and 1  
|notify.hud.default_alignment | Default text alignment of a HUD relative to position | v3f | (1, -1, 0) | | Only first 2 values will be used, will align to top/left (-1) center (0) or bottom/right(1), values can be fractional
|notify.hud.default_offset | Default pixel offset of a HUD | v3f | (0, 0, 0) | | Only first 2 values will be used, number of pixels to offset, scaled by user DPI and scaling factor, but not screen size
|notify.hud.default_direction | Default text direction of a HUD | enum | left-right | left-right,right-left,top-bottom,bottom-top | 
|notify.hud.default_duration | Default duration that a HUD message will display for | float | 3.0 | 
|notify.hud.default_conflict_behaviour | Default behaviour when a new message is sent to a HUD that is already displaying a message| enum | stack | stack,stack-up,stack-down,overwrite,ignore,wait | If `stack` is set it will be set to `stack-up` or `stack-down` depending on the value of `alignment`
