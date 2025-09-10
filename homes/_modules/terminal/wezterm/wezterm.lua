local wezterm = require("wezterm")
local hostname = wezterm.hostname()
local font_size

if hostname == "ot-framework" then
	font_size = 18
else
	font_size = 12
end

return {
	-- atm wayland seems to break copy/paste, but is necessary for non-aliasing on framework
	enable_wayland = (hostname == "ot-framework" and true or false),
	keys = {
		{ key = "V", mods = "CTRL", action = wezterm.action.PasteFrom("Clipboard") },
		{ key = "V", mods = "CTRL", action = wezterm.action.PasteFrom("PrimarySelection") },
	},

	-- Mousing bindings
	mouse_bindings = {
		-- Change the default click behavior so that it only selects
		-- text and doesn't open hyperlinks
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "NONE",
			action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
		},

		-- and make CTRL-Click open hyperlinks
		{
			event = { Up = { streak = 1, button = "Left" } },
			mods = "CTRL",
			action = wezterm.action.OpenLinkAtMouseCursor,
		},
		{
			event = { Down = { streak = 3, button = "Left" } },
			action = wezterm.action.SelectTextAtMouseCursor("SemanticZone"),
			mods = "NONE",
		},
	},

	scrollback_lines = 7000,
	hyperlink_rules = wezterm.default_hyperlink_rules(),
	hide_tab_bar_if_only_one_tab = true,
	color_scheme = "Tokyo Night Storm",
	font_size = font_size,
	font = wezterm.font_with_fallback({
		"JetBrains Mono",
		"Font Awesome 6 Free",
		"Font Awesome 6 Free Solid",
	}),
	launch_menu = {
		{
			args = { "top" },
		},
		{
			-- Optional label to show in the launcher. If omitted, a label
			-- is derived from the `args`
			label = "Bash",
			-- The argument array to spawn.  If omitted the default program
			-- will be used as described in the documentation above
			args = { "bash", "-l" },

			-- You can specify an alternative current working directory;
			-- if you don't specify one then a default based on the OSC 7
			-- escape sequence will be used (see the Shell Integration
			-- docs), falling back to the home directory.
			-- cwd = "/some/path"

			-- You can override environment variables just for this command
			-- by setting this here.  It has the same semantics as the main
			-- set_environment_variables configuration option described above
			-- set_environment_variables = { FOO = "bar" },
		},
	},
	default_cursor_style = "BlinkingUnderline",
	disable_default_key_bindings = false,
	window_background_opacity = 0.9,
	check_for_updates = false,
	-- front_end = "WebGpu",
	mux_enable_ssh_agent = false,
}
