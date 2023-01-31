name = "Animal Tracker"
version = "23.02.01"
author = "adai1198"
description = "Version: "..version.."\n"..
[[

"Gotcha!"

A button shows up when there's Suspicious Dirt Pile nearby.
Clicking the button will lead you to the next Dirt Pile.

Shortcut keys:
Press F2 key (default) to follow the animal track.
Press F11 key (default) to search for the lost toys.
]]
forumthread = ""
api_version = 10
icon_atlas = "AnimalTracker.xml"
icon = "AnimalTracker.tex"
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true
all_clients_require_mod = false
client_only_mod = true
server_filter_tags = {}

configuration_options =
{
	{
		name = "tracking_anim",
		label = "Tracking Animation",
		hover = "Play mole tracking animation after clicking the button.",
		options =
		{
			{description = "Off", data = 0},
			{description = "On", data = 1},
		},
		default = 1,
	},
	{
		name = "notification_sound",
		label = "Notification Sound",
		hover = "Play sound when nearby Dirt Pile appears/disappears.",
		options =
		{
			{description = "Off", data = 0},
			{description = "Appear Only", data = 1},
			{description = "Disappear Only", data = 2},
			{description = "Always", data = 3},
		},
		default = 3,
	},
	{
		name = "shortcut_key",
		label = "Animal Tracker Shortcut Key",
		hover = "Press the shortcut key to follow animal tracks.",
		options =
		{
			{description = "Off", data = false},
			{description = "F1", data = "KEY_F1"},
			{description = "F2", data = "KEY_F2"},
			{description = "F3", data = "KEY_F3"},
			{description = "F4", data = "KEY_F4"},
			{description = "F5", data = "KEY_F5"},
			{description = "F6", data = "KEY_F6"},
			{description = "F7", data = "KEY_F7"},
			{description = "F8", data = "KEY_F8"},
			{description = "F9", data = "KEY_F9"},
			{description = "F10", data = "KEY_F10"},
			{description = "F11", data = "KEY_F11"},
			{description = "F12", data = "KEY_F12"},
		},
		default = "KEY_F2",
	},
	{
		name = "shortcut_key_2",
		label = "Lost Toys Tracker Shortcut Key",
		hover = "Press the shortcut key to find lost toys.",
		options =
		{
			{description = "Off", data = false},
			{description = "F1", data = "KEY_F1"},
			{description = "F2", data = "KEY_F2"},
			{description = "F3", data = "KEY_F3"},
			{description = "F4", data = "KEY_F4"},
			{description = "F5", data = "KEY_F5"},
			{description = "F6", data = "KEY_F6"},
			{description = "F7", data = "KEY_F7"},
			{description = "F8", data = "KEY_F8"},
			{description = "F9", data = "KEY_F9"},
			{description = "F10", data = "KEY_F10"},
			{description = "F11", data = "KEY_F11"},
			{description = "F12", data = "KEY_F12"},
		},
		default = "KEY_F11",
	}
}