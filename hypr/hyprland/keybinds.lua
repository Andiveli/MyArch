require("hyprland.lib")
require("hyprland.variables")
if is_file_exists(HOME .. "/.config/hypr/custom/variables.lua") then
	require("custom.variables")
end

local qsScripts = HOME .. "/.config/quickshell/$qsConfig/scripts"
local hyprScripts = HOME .. "/.config/hypr/hyprland/scripts"
local qsIpcCall = "qs -c $qsConfig ipc call"
local qsIsAlive = qsIpcCall .. " TEST_ALIVE"
local scriptsDir = HOME .. "/.config/hypr/scripts"
local userScripts = HOME .. "/.config/hypr/UserScripts"

-- Super alone → fuzzel (Samael: no II overview; qs TEST_ALIVE always exits 0 so || fuzzel never ran)
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("pkill fuzzel 2>/dev/null || fuzzel"), { description = "fuzzel app launcher" })
hl.bind("SUPER + SUPER_R", hl.dsp.exec_cmd("pkill fuzzel 2>/dev/null || fuzzel"), { description = "fuzzel app launcher" })

hl.bind("SUPER + E", hl.dsp.exec_cmd("microsoft-edge-stable"), { description = "Open Edge browser" })
hl.bind("SUPER + Z", hl.dsp.exec_cmd(browser), { description = "Open Zen browser" })
hl.bind("SUPER + S", hl.dsp.exec_cmd("spotify"), { description = "Open Spotify" })
hl.bind("SUPER + D", hl.dsp.exec_cmd("discord"), { description = "Open Discord" })
hl.bind("SUPER + T", hl.dsp.exec_cmd("tableplus"), { description = "Open TablePlus" })
hl.bind("ALT + Space", hl.dsp.exec_cmd(scriptsDir .. "/puerta.sh"), { description = "App launcher" })

--##!!! Standard (from Keybinds.conf)
hl.bind("SUPER + A", hl.dsp.exec_cmd("dolphin"), { description = "Open dolphin" })
hl.bind("SUPER + Return", hl.dsp.exec_cmd("ghostty"), { description = "Open terminal" })

--##!!! Features / Extras
hl.bind(
	"SUPER + CTRL + SHIFT + H",
	hl.dsp.exec_cmd(scriptsDir .. "/KeyHints.sh"),
	{ description = "help / cheat sheet" }
)
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd(scriptsDir .. "/Refresh.sh"), { description = "refresh bar and menus" })
hl.bind("SUPER + ALT + E", hl.dsp.exec_cmd(scriptsDir .. "/RofiEmoji.sh"), { description = "emoji menu" })
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd(scriptsDir .. "/RofiSearch.sh"), { description = "web search" })
hl.bind("SUPER + CTRL + S", hl.dsp.exec_cmd("rofi -show window"), { description = "window switcher" })
hl.bind("SUPER + ALT + O", hl.dsp.exec_cmd(scriptsDir .. "/ChangeBlur.sh"), { description = "toggle blur" })
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd(scriptsDir .. "/GameMode.sh"), { description = "toggle game mode" })
hl.bind(
	"SUPER + ALT + L",
	hl.dsp.exec_cmd(scriptsDir .. "/ChangeLayout.sh"),
	{ description = "toggle master/dwindle layout" }
)
hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd(scriptsDir .. "/ClipManager.sh"), { description = "clipboard manager" })
hl.bind(
	"SUPER + CTRL + R",
	hl.dsp.exec_cmd(scriptsDir .. "/RofiThemeSelector.sh"),
	{ description = "rofi theme selector" }
)
hl.bind("SUPER + CTRL + F", hl.dsp.exec_cmd("hyprctl dispatch fullscreen 1"), { description = "maximize window" })
hl.bind("SUPER + Space", hl.dsp.exec_cmd("hyprctl dispatch togglefloating"), { description = "Float current window" })
hl.bind(
	"SUPER + ALT + Space",
	hl.dsp.exec_cmd("hyprctl dispatch workspaceopt allfloat"),
	{ description = "Float all windows" }
)
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("pypr toggle term"), { description = "DropDown terminal" })
hl.bind("SUPER + o", hl.dsp.exec_cmd("pypr toggle ollama"), { description = "Ollama side panel" })

--##!!! Desktop zoom / magnifier
hl.bind(
	"SUPER + ALT + mouse_down",
	hl.dsp.exec_cmd(
		"hyprctl keyword cursor:zoom_factor \"$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor * 2.0}')\""
	),
	{ description = "zoom in" }
)
hl.bind(
	"SUPER + ALT + mouse_up",
	hl.dsp.exec_cmd(
		"hyprctl keyword cursor:zoom_factor \"$(hyprctl getoption cursor:zoom_factor | awk 'NR==1 {factor = $2; if (factor < 1) {factor = 1}; print factor / 2.0}')\""
	),
	{ description = "zoom out" }
)

--# Zoom keyboard (non-conflicting lua)
local function zoomfunction(value)
	local zoomvalue = hl.get_config("cursor:zoom_factor")
	if (zoomvalue + value) > 3.0 then
		hl.config({ cursor = { zoom_factor = 3.0 } })
	elseif (zoomvalue + value) < 1.0 then
		hl.config({ cursor = { zoom_factor = 1.0 } })
	else
		hl.config({ cursor = { zoom_factor = zoomvalue + value } })
	end
end
hl.bind("SUPER + Minus", function()
	zoomfunction(-0.3)
end, { repeating = true, description = "Screen: Zoom out" })
hl.bind("SUPER + Equal", function()
	zoomfunction(0.3)
end, { repeating = true, description = "Screen: Zoom in" })
hl.bind("SUPER + code:82", function()
	zoomfunction(-0.3)
end, { repeating = true })
hl.bind("SUPER + code:86", function()
	zoomfunction(0.3)
end, { repeating = true })

--##!!! Waybar / Bar
hl.bind("SUPER + B", hl.dsp.exec_cmd("pkill -SIGUSR1 waybar"), { description = "toggle waybar on/off" })
-- hl.bind("SUPER + CTRL + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarStyles.sh"), { description = "waybar styles menu" })
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarLayout.sh"), { description = "waybar layout menu" })

--##!!! Night light
hl.bind("SUPER + N", hl.dsp.exec_cmd(scriptsDir .. "/Hyprsunset.sh toggle"), { description = "toggle night light" })

--##!!! Features / Extras (UserScripts)
-- RofiBeats moved: Super+Shift+M is Samael control center (see below)
hl.bind("SUPER + ALT + M", hl.dsp.exec_cmd(userScripts .. "/RofiBeats.sh"), { description = "online music (RofiBeats)" })

-- Refresh.sh: wallust + qs -c ii (Samael; no waybar/swaync)
-- hl.bind("SUPER + W", hl.dsp.exec_cmd(userScripts .. "/WallpaperSelect.sh"), { description = "select wallpaper" })
hl.bind(
	"SUPER + W",
	hl.dsp.global("quickshell:wallpaperSelectorToggle"),
	{ description = "select wallpaper (Quickshell grid)" }
)
hl.bind(
	"SUPER + SHIFT + W",
	hl.dsp.global("quickshell:samaelWifiMenuToggle"),
	{ description = "Wi-Fi menu (Samael)" }
)
hl.bind(
	"SUPER + SHIFT + B",
	hl.dsp.global("quickshell:samaelBluetoothMenuToggle"),
	{ description = "Bluetooth menu (Samael)" }
)
hl.bind(
	"SUPER + SHIFT + N",
	hl.dsp.global("quickshell:samaelNotificationsMenuToggle"),
	{ description = "Notifications menu (Samael)" }
)
-- Samael bar app mode: Super+Ctrl+B enter/exit; then h/l move, j/k act, Esc quit (submap)
hl.bind(
	"SUPER + CTRL + B",
	hl.dsp.global("quickshell:samaelBarNavToggle"),
	{ description = "Samael bar keyboard nav" }
)
hl.bind(
	"CTRL + ALT + W",
	hl.dsp.global("quickshell:wallpaperSelectorRandom"),
	{ description = "random wallpaper" }
)
hl.bind(
	"SUPER + CTRL + O",
	hl.dsp.global("quickshell:samaelSystemSidebarToggle"),
	{ description = "Samael system monitor sidebar" }
)
hl.bind(
	"SUPER + M",
	hl.dsp.global("quickshell:mediaControlsToggle"),
	{ description = "Samael media manager (MPRIS panel)" }
)
hl.bind(
	"SUPER + SHIFT + M",
	hl.dsp.global("quickshell:samaelSuperMenuToggle"),
	{ description = "Samael super menu (control center)" }
)
hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd(scriptsDir .. "/KeyBinds.sh"), { description = "search keybinds" })
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd(scriptsDir .. "/Animations.sh"), { description = "animations menu" })
hl.bind(
	"SUPER + SHIFT + O",
	hl.dsp.exec_cmd("hyprctl setprop active opaque toggle"),
	{ description = "toggle active window opacity" }
)
hl.bind("SUPER + ALT + C", hl.dsp.exec_cmd(scriptsDir .. "/__RofiCalcCopy.sh"), { description = "calculator" })

--##!!! Keyboard layout switching
hl.bind(
	"ALT_L + SHIFT_L",
	hl.dsp.exec_cmd(scriptsDir .. "/SwitchKeyboardLayout.sh"),
	{ locked = true, non_consuming = true, description = "switch keyboard layout globally" }
)
hl.bind(
	"SHIFT_L + ALT_L",
	hl.dsp.exec_cmd(scriptsDir .. "/Tak0-Per-Window-Switch.sh"),
	{ locked = true, non_consuming = true, description = "switch keyboard layout per-window" }
)

--##!!! Move workspace to monitor
hl.bind(
	"SUPER + CTRL + F9",
	hl.dsp.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor l"),
	{ description = "move workspace to left monitor" }
)
hl.bind(
	"SUPER + CTRL + F10",
	hl.dsp.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor r"),
	{ description = "move workspace to right monitor" }
)
hl.bind(
	"SUPER + CTRL + F11",
	hl.dsp.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor u"),
	{ description = "move workspace to up monitor" }
)
hl.bind(
	"SUPER + CTRL + F12",
	hl.dsp.exec_cmd("hyprctl dispatch movecurrentworkspacetomonitor d"),
	{ description = "move workspace to down monitor" }
)

--##!!! System
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("hyprctl dispatch exit 0"), { description = "exit Hyprland" })
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "close active window" })
hl.bind(
	"SUPER + SHIFT + Q",
	hl.dsp.exec_cmd(scriptsDir .. "/KillActiveProcess.sh"),
	{ description = "Terminate active process" }
)
hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd(scriptsDir .. "/LockScreen.sh"), { description = "lock screen" })
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh"), { description = "powermenu" })
hl.bind(
	"SUPER + SHIFT + E",
	hl.dsp.exec_cmd(scriptsDir .. "/Kool_Quick_Settings.sh"),
	{ description = "Quick settings menu" }
)

--##!!! Master Layout
hl.bind("SUPER + CTRL + D", hl.dsp.layout("removemaster"), { description = "remove master" })
hl.bind("SUPER + I", hl.dsp.layout("addmaster"), { description = "add master" })
hl.bind("SUPER + CTRL + Return", hl.dsp.layout("swapwithmaster"), { description = "swap with master" })

--##!!! Dwindle Layout
hl.bind(
	"SUPER + SHIFT + I",
	hl.dsp.exec_cmd("hyprctl dispatch togglesplit"),
	{ description = "toggle split (dwindle)" }
)
hl.bind("SUPER + P", hl.dsp.exec_cmd("hyprctl dispatch pseudo"), { description = "toggle pseudo (dwindle)" })

--##!!! Split ratio
-- SUPER+M → Samael super menu (see binds above); splitratio was here — use hyprctl manually if needed

--##!!! Cycle windows
hl.bind("ALT + Tab", hl.dsp.exec_cmd("hyprctl dispatch bringactivetotop"), { description = "bring active to top" })

--##!!! Resize windows
hl.bind(
	"SUPER + SHIFT + H",
	hl.dsp.exec_cmd("hyprctl dispatch resizeactive -50 0"),
	{ repeating = true, description = "resize left (-50)" }
)
hl.bind(
	"SUPER + SHIFT + L",
	hl.dsp.exec_cmd("hyprctl dispatch resizeactive 50 0"),
	{ repeating = true, description = "resize right (+50)" }
)
hl.bind(
	"SUPER + SHIFT + K",
	hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -50"),
	{ repeating = true, description = "resize up (-50)" }
)
hl.bind(
	"SUPER + SHIFT + J",
	hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 50"),
	{ repeating = true, description = "resize down (+50)" }
)

--##!!! Move windows
hl.bind("SUPER + CTRL + H", hl.dsp.window.move({ direction = "l" }), { description = "move window left" })
hl.bind("SUPER + CTRL + L", hl.dsp.window.move({ direction = "r" }), { description = "move window right" })
hl.bind("SUPER + CTRL + K", hl.dsp.window.move({ direction = "u" }), { description = "move window up" })
hl.bind("SUPER + CTRL + J", hl.dsp.window.move({ direction = "d" }), { description = "move window down" })

--##!!! Swap windows
hl.bind("SUPER + ALT + Left", hl.dsp.exec_cmd("hyprctl dispatch swapwindow l"), { description = "swap window left" })
hl.bind("SUPER + ALT + Right", hl.dsp.exec_cmd("hyprctl dispatch swapwindow r"), { description = "swap window right" })
hl.bind("SUPER + ALT + Up", hl.dsp.exec_cmd("hyprctl dispatch swapwindow u"), { description = "swap window up" })
hl.bind("SUPER + ALT + Down", hl.dsp.exec_cmd("hyprctl dispatch swapwindow d"), { description = "swap window down" })

--##!!! Group
hl.bind("SUPER + G", hl.dsp.exec_cmd("hyprctl dispatch togglegroup"), { description = "toggle group" })

--##!!! Focus (vim-style)
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }), { description = "focus left" })
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }), { description = "focus right" })
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }), { description = "focus up" })
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }), { description = "focus down" })

--##!!! Focus (arrow keys - lua non-conflicting)
for i = 1, 4 do
	local arrowkey = { "Left", "Right", "Up", "Down" }
	local focusdir = { "l", "r", "u", "d" }
	hl.bind(
		"SUPER + " .. arrowkey[i],
		hl.dsp.focus({ direction = focusdir[i] }),
		{ description = "Window: Focus " .. arrowkey[i] }
	)
end
for i = 1, 2 do
	local arrowkey = { "BracketLeft", "BracketRight" }
	local focusdir = { "l", "r" }
	hl.bind("SUPER + " .. arrowkey[i], hl.dsp.focus({ direction = focusdir[i] }))
end

--##!!! Move window with arrows (lua non-conflicting)
for i = 1, 4 do
	local arrowkey = { "Left", "Right", "Up", "Down" }
	local focusdir = { "l", "r", "u", "d" }
	hl.bind(
		"SUPER + SHIFT + " .. arrowkey[i],
		hl.dsp.window.move({ direction = focusdir[i] }),
		{ description = "Window: Move " .. arrowkey[i] }
	)
end

--##!!! Window close / misc
hl.bind("ALT + F4", function()
	hl.exec_cmd('notify-send "Wrong close keybind" "Super+Q to close. Use Alt+F4 for Windows VMs" -a Hyprland')
end, { non_consuming = true })
hl.bind("SUPER + SHIFT + ALT + Q", hl.dsp.exec_cmd("hyprctl kill"), { description = "Window: Forcefully zap a window" })
hl.bind("SUPER + Semicolon", hl.dsp.layout("splitratio -0.1"), { repeating = true })
hl.bind("SUPER + Apostrophe", hl.dsp.layout("splitratio +0.1"), { repeating = true })
hl.bind(
	"SUPER + F",
	hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
	{ description = "Window: Fullscreen" }
)
hl.bind(
	"SUPER + ALT + F",
	hl.dsp.window.fullscreen_state({ internal = 0, client = 3, action = "toggle" }),
	{ description = "Window: Fullscreen spoof" }
)
hl.bind("SUPER + P", hl.dsp.window.pin(), { description = "Window: Pin" })

--##!!! Send to workspace (SUPER + ALT + n - lua non-conflicting)
workspaceGroupSize = workspaceGroupSize or 10
for i = 1, workspaceGroupSize do
	hl.bind("SUPER + ALT + " .. (i % workspaceGroupSize), function()
		hl.dispatch(hl.dsp.window.move({ workspace = i, follow = false }))
	end, { description = "Window: Send to workspace " .. i })
end
for i = 1, 10 do
	local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
	hl.bind("SUPER + ALT + code:" .. numpadkey[i], function()
		hl.dispatch(hl.dsp.window.move({ workspace = i, follow = false }))
	end)
end

--# Scroll to send workspace
for i = 1, 4 do
	local key = { "SUPER + SHIFT + mouse_", "SUPER + ALT + mouse_" }
	local keycombos = { key[1] .. "down", key[1] .. "up", key[2] .. "down", key[2] .. "up" }
	local prefix = { "r-", "r+", "r-", "r+" }
	hl.bind(keycombos[i], hl.dsp.window.move({ workspace = prefix[i] .. "1" }))
end
for i = 1, 2 do
	local keydirs = { "Up", "Down" }
	local prefix = { "r-", "r+" }
	local descdir = { "left", "right" }
	hl.bind(
		"SUPER + SHIFT + Page_" .. keydirs[i],
		hl.dsp.window.move({ workspace = prefix[i] .. "1" }),
		{ description = "Window: Send to workspace " .. descdir[i] }
	)
end
for i = 1, 4 do
	local key = { "SUPER + ALT + Page_", "CTRL + SUPER + SHIFT + " }
	local keycombos = { key[1] .. "down", key[1] .. "up", key[2] .. "Right", key[2] .. "Left" }
	local prefix = { "r+", "r-", "r+", "r-" }
	hl.bind(keycombos[i], hl.dsp.window.move({ workspace = prefix[i] .. "1" }))
end
hl.bind(
	"SUPER + ALT + S",
	hl.dsp.window.move({ workspace = "special:special", follow = false }),
	{ description = "Window: Send to scratchpad" }
)
hl.bind("CTRL + SUPER + S", hl.dsp.workspace.toggle_special("special"))

--##!!! Workspace switching
--# SUPER + n (number keys)
for i = 1, 10 do
	hl.bind("SUPER + " .. (i % 10), function()
		hl.dispatch(hl.dsp.focus({ workspace = i }))
	end, { description = "Workspace: Focus " .. i })
end
--# SUPER + code:10-19 (keyboard layout independent)
for i = 1, 10 do
	local numberkey = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
	hl.bind("SUPER + code:" .. numberkey[i], function()
		hl.dispatch(hl.dsp.focus({ workspace = i }))
	end)
end
--# keypad numbers
for i = 1, 10 do
	local numpadkey = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }
	hl.bind("SUPER + code:" .. numpadkey[i], function()
		hl.dispatch(hl.dsp.focus({ workspace = i }))
	end)
end

--# Workspace navigation
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "m+1" }), { description = "next workspace" })
hl.bind("SUPER + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }), { description = "previous workspace" })

--# Special workspace
hl.bind(
	"SUPER + SHIFT + U",
	hl.dsp.window.move({ workspace = "special", follow = true }),
	{ description = "move to special workspace" }
)
hl.bind("SUPER + U", hl.dsp.workspace.toggle_special("special"), { description = "toggle special workspace" })

--# Focus left/right workspace
for i = 1, 2 do
	local keys = { "Left", "Right" }
	local prefix = { "r-", "r+" }
	local descdir = { "left", "right" }
	hl.bind(
		"CTRL + SUPER + " .. keys[i],
		hl.dsp.focus({ workspace = prefix[i] .. "1" }),
		{ description = "Workspace: Focus " .. descdir[i] }
	)
end
for i = 1, 2 do
	local keys = { "Left", "Right" }
	local prefix = { "m-", "m+" }
	hl.bind("CTRL + SUPER + ALT + " .. keys[i], hl.dsp.focus({ workspace = prefix[i] .. "1" }))
end
for i = 1, 4 do
	local key = { "SUPER + Page_Down", "SUPER + Page_Up" }
	local keycombos = { key[1], key[2], "CTRL + " .. key[1], "CTRL + " .. key[2] }
	local prefix = { "r+", "r-", "r+", "r-" }
	hl.bind(keycombos[i], hl.dsp.focus({ workspace = prefix[i] .. "1" }))
end
for i = 1, 4 do
	local key = { "SUPER + mouse_up", "SUPER + mouse_down" }
	local keycombos = { key[1], key[2], "CTRL + " .. key[1], "CTRL + " .. key[2] }
	local prefix = { "+", "-", "r+", "r-" }
	hl.bind(keycombos[i], hl.dsp.focus({ workspace = prefix[i] .. "1" }))
end

--# Scroll / period / comma through workspaces
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "next workspace" })
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "previous workspace" })
hl.bind("SUPER + Period", hl.dsp.focus({ workspace = "e+1" }), { description = "next workspace" })
hl.bind("SUPER + Comma", hl.dsp.focus({ workspace = "e-1" }), { description = "previous workspace" })

--# CTRL+SUPER bracket navigation
hl.bind("SUPER + mouse:275", hl.dsp.workspace.toggle_special("special"))
for i = 1, 4 do
	local key = { "BracketLeft", "BracketRight", "Up", "Down" }
	local prefix = { "-1", "+1", "r-5", "r+5" }
	hl.bind("CTRL + SUPER + " .. key[i], hl.dsp.focus({ workspace = prefix[i] }))
end

--##!!! Move to workspace (with follow)
hl.bind(
	"SUPER + SHIFT + code:10",
	hl.dsp.window.move({ workspace = 1, follow = true }),
	{ description = "move to workspace 1" }
)
hl.bind(
	"SUPER + SHIFT + code:11",
	hl.dsp.window.move({ workspace = 2, follow = true }),
	{ description = "move to workspace 2" }
)
hl.bind(
	"SUPER + SHIFT + code:12",
	hl.dsp.window.move({ workspace = 3, follow = true }),
	{ description = "move to workspace 3" }
)
hl.bind(
	"SUPER + SHIFT + code:13",
	hl.dsp.window.move({ workspace = 4, follow = true }),
	{ description = "move to workspace 4" }
)
hl.bind(
	"SUPER + SHIFT + code:14",
	hl.dsp.window.move({ workspace = 5, follow = true }),
	{ description = "move to workspace 5" }
)
hl.bind(
	"SUPER + SHIFT + code:15",
	hl.dsp.window.move({ workspace = 6, follow = true }),
	{ description = "move to workspace 6" }
)
hl.bind(
	"SUPER + SHIFT + code:16",
	hl.dsp.window.move({ workspace = 7, follow = true }),
	{ description = "move to workspace 7" }
)
hl.bind(
	"SUPER + SHIFT + code:17",
	hl.dsp.window.move({ workspace = 8, follow = true }),
	{ description = "move to workspace 8" }
)
hl.bind(
	"SUPER + SHIFT + code:18",
	hl.dsp.window.move({ workspace = 9, follow = true }),
	{ description = "move to workspace 9" }
)
hl.bind(
	"SUPER + SHIFT + code:19",
	hl.dsp.window.move({ workspace = 10, follow = true }),
	{ description = "move to workspace 10" }
)
hl.bind(
	"SUPER + SHIFT + BracketLeft",
	hl.dsp.window.move({ workspace = -1, follow = true }),
	{ description = "move to previous workspace" }
)
hl.bind(
	"SUPER + SHIFT + BracketRight",
	hl.dsp.window.move({ workspace = 1, follow = true }),
	{ description = "move to next workspace" }
)

--##!!! Move silently to workspace
hl.bind(
	"SUPER + CTRL + code:10",
	hl.dsp.window.move({ workspace = 1, follow = false }),
	{ description = "move silently to workspace 1" }
)
hl.bind(
	"SUPER + CTRL + code:11",
	hl.dsp.window.move({ workspace = 2, follow = false }),
	{ description = "move silently to workspace 2" }
)
hl.bind(
	"SUPER + CTRL + code:12",
	hl.dsp.window.move({ workspace = 3, follow = false }),
	{ description = "move silently to workspace 3" }
)
hl.bind(
	"SUPER + CTRL + code:13",
	hl.dsp.window.move({ workspace = 4, follow = false }),
	{ description = "move silently to workspace 4" }
)
hl.bind(
	"SUPER + CTRL + code:14",
	hl.dsp.window.move({ workspace = 5, follow = false }),
	{ description = "move silently to workspace 5" }
)
hl.bind(
	"SUPER + CTRL + code:15",
	hl.dsp.window.move({ workspace = 6, follow = false }),
	{ description = "move silently to workspace 6" }
)
hl.bind(
	"SUPER + CTRL + code:16",
	hl.dsp.window.move({ workspace = 7, follow = false }),
	{ description = "move silently to workspace 7" }
)
hl.bind(
	"SUPER + CTRL + code:17",
	hl.dsp.window.move({ workspace = 8, follow = false }),
	{ description = "move silently to workspace 8" }
)
hl.bind(
	"SUPER + CTRL + code:18",
	hl.dsp.window.move({ workspace = 9, follow = false }),
	{ description = "move silently to workspace 9" }
)
hl.bind(
	"SUPER + CTRL + code:19",
	hl.dsp.window.move({ workspace = 10, follow = false }),
	{ description = "move silently to workspace 10" }
)
hl.bind(
	"SUPER + CTRL + BracketLeft",
	hl.dsp.window.move({ workspace = -1, follow = false }),
	{ description = "move silently to previous workspace" }
)
hl.bind(
	"SUPER + CTRL + BracketRight",
	hl.dsp.window.move({ workspace = 1, follow = false }),
	{ description = "move silently to next workspace" }
)

--##!!! Mouse bindings
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "move window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "resize window" })

--##!!! Screenshots (from Keybinds.conf)
hl.bind("SUPER + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"), { description = "screenshot now" })
hl.bind(
	"SUPER + SHIFT + Print",
	hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --area"),
	{ description = "screenshot (area)" }
)
hl.bind(
	"SUPER + CTRL + Print",
	hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in5"),
	{ description = "screenshot in 5s" }
)
hl.bind(
	"SUPER + CTRL + SHIFT + Print",
	hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --in10"),
	{ description = "screenshot in 10s" }
)
hl.bind(
	"ALT + Print",
	hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --active"),
	{ description = "screenshot active window" }
)
hl.bind(
	"SUPER + SHIFT + S",
	hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --swappy"),
	{ description = "screenshot (swappy)" }
)

--# Screenshot with grim (lua non-conflicting: Print alone, CTRL+Print)
local grimhyprctl = "grim -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\""
hl.bind(
	"Print",
	hl.dsp.exec_cmd(grimhyprctl .. " - | wl-copy"),
	{ locked = true, description = "Utilities: Screenshot >> clipboard" }
)
hl.bind(
	"CTRL + Print",
	hl.dsp.exec_cmd(
		"mkdir -p $(xdg-user-dir PICTURES)/Screenshots && "
			.. grimhyprctl
			.. " $(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png"
	),
	{ locked = true, non_consuming = true, description = "Utilities: Screenshot >> clipboard & file" }
)
hl.bind("CTRL + Print", hl.dsp.exec_cmd(grimhyprctl .. " - | wl-copy"), { locked = true, non_consuming = true })

--##!!! Media keys (from Keybinds.conf)
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --inc"),
	{ locked = true, repeating = true, description = "volume up" }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --dec"),
	{ locked = true, repeating = true, description = "volume down" }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle-mic"),
	{ locked = true, description = "toggle mic mute" }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd(scriptsDir .. "/Volume.sh --toggle"),
	{ locked = true, description = "toggle mute" }
)
hl.bind("XF86Sleep", hl.dsp.exec_cmd("systemctl suspend"), { locked = true, description = "sleep" })
hl.bind(
	"XF86Rfkill",
	hl.dsp.exec_cmd(scriptsDir .. "/AirplaneMode.sh"),
	{ locked = true, description = "airplane mode" }
)
hl.bind(
	"XF86AudioPause",
	hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"),
	{ locked = true, description = "pause" }
)
hl.bind(
	"XF86AudioPlay",
	hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --pause"),
	{ locked = true, description = "play" }
)
hl.bind(
	"XF86AudioNext",
	hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --nxt"),
	{ locked = true, description = "next track" }
)
hl.bind(
	"XF86AudioPrev",
	hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --prv"),
	{ locked = true, description = "previous track" }
)
hl.bind("XF86AudioStop", hl.dsp.exec_cmd(scriptsDir .. "/MediaCtrl.sh --stop"), { locked = true, description = "stop" })

--# Media playerctl (lua non-conflicting)
local mediaNextCommand =
	'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"`'
-- was media next; Super+Shift+N → Samael notifications (see bar section)
-- hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd(mediaNextCommand), { locked = true, description = "Media: Next track" })
hl.bind(
	"SUPER + SHIFT + P",
	hl.dsp.exec_cmd("playerctl play-pause"),
	{ locked = true, description = "Media: Play/pause media" }
)
-- was media previous; Super+Shift+B → Samael Bluetooth (see bar section)
-- hl.bind(
-- 	"SUPER + SHIFT + B",
-- 	hl.dsp.exec_cmd("playerctl previous"),
-- 	{ locked = true, description = "Media: Previous track" }
-- )
hl.bind("SUPER + SHIFT + ALT + mouse:275", hl.dsp.exec_cmd("playerctl previous"))
hl.bind("SUPER + SHIFT + ALT + mouse:276", hl.dsp.exec_cmd(mediaNextCommand))

--# Mic toggle via keyboard (lua non-conflicting)
hl.bind(
	"SUPER + ALT + M",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"),
	{ locked = true, description = "Media: Toggle mic" }
)
hl.bind("ALT + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })

--##!!! Brightness (lua non-conflicting)
-- brightnessctl always runs; QS ipc optional (was broken: IpcHandler had invalid syntax + exit 0 hid || fallback)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd(
"sh -c '" .. qsIpcCall .. " brightness increment >/dev/null 2>&1; brightnessctl s 5%+'"
	),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd(
"sh -c '" .. qsIpcCall .. " brightness decrement >/dev/null 2>&1; brightnessctl s 5%-'"
	),
	{ locked = true, repeating = true }
)

--##!!! Quickshell features (lua non-conflicting)
hl.bind(
	"CTRL + SUPER + T",
	hl.dsp.exec_cmd(qsIsAlive .. " || " .. qsScripts .. "/colors/switchwall.sh"),
	{ description = "Shell: Change wallpaper" }
)
hl.bind(
	"CTRL + SUPER + T",
	hl.dsp.global("quickshell:wallpaperSelectorToggle"),
	{ description = "Shell: Change wallpaper" }
)
hl.bind(
	"CTRL + SUPER + ALT + T",
	hl.dsp.global("quickshell:wallpaperSelectorRandom"),
	{ description = "Shell: Random wallpaper" }
)
hl.bind(
	"CTRL + SUPER + SHIFT + D",
	hl.dsp.global("quickshell:toggleLightDark"),
	{ description = "Shell: Toggle light/dark mode" }
)
hl.bind("CTRL + SUPER + P", hl.dsp.global("quickshell:panelFamilyCycle"), { description = "Shell: Cycle panel family" })
hl.bind(
	"CTRL + SUPER + R",
	hl.dsp.exec_cmd("killall ydotool qs quickshell; qs -c $qsConfig &"),
	{ description = "Shell: Restart widgets" }
)
hl.bind(
	"SUPER + Period",
	hl.dsp.exec_cmd(qsIsAlive .. " || pkill fuzzel || " .. hyprScripts .. "/fuzzel-emoji.sh copy"),
	{ description = "Utilities: Emoji >> clipboard" }
)

--##!!! Utilities (lua non-conflicting)
--# OCR
hl.bind(
	"SUPER + SHIFT + X",
	hl.dsp.global("quickshell:regionOcr"),
	{ description = "Utilities: Character recognition >> clipboard" }
)
hl.bind(
	"SUPER + SHIFT + X",
	hl.dsp.exec_cmd(
		qsIsAlive
			.. " || pidof slurp || grim -g \"$(slurp $SLURP_ARGS)\" \"/tmp/ocr_image.png\" && tesseract \"/tmp/ocr_image.png\" stdout -l $(tesseract --list-langs | awk 'NR>1{print $1}' | tr '\\\\n' '+' | sed 's/\\\\+$/\\\\n/') | wl-copy && rm \"/tmp/ocr_image.png\""
	)
)
--# Search / Google Lens
hl.bind("SUPER + SHIFT + A", hl.dsp.global("quickshell:regionSearch"), { description = "Utilities: Google Lens" })
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd(qsIsAlive .. " || pidof slurp || " .. hyprScripts .. "/snip_to_search.sh"))

--# Color picker
hl.bind(
	"SUPER + SHIFT + C",
	hl.dsp.exec_cmd("hyprpicker -a"),
	{ description = "Utilities: Pick color #RRGGBB >> clipboard" }
)

hl.bind("SUPER + SHIFT + R", hl.dsp.global("quickshell:regionRecord"), { locked = true })
hl.bind(
	"SUPER + SHIFT + R",
	hl.dsp.exec_cmd(qsIsAlive .. " || " .. qsScripts .. "/videos/record.sh"),
	{ locked = true }
)
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen"), { locked = true })
hl.bind(
	"SUPER + SHIFT + ALT + R",
	hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen --sound"),
	{ locked = true, description = "Utilities: Record screen (with sound)" }
)

--# AI
hl.bind(
	"SUPER + SHIFT + ALT + mouse:273",
	hl.dsp.exec_cmd(hyprScripts .. "/ai/primary-buffer-query.sh"),
	{ description = "Utilities: Generate AI summary for selected text" }
)

--##!!! Session
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }), { description = "focus right" }) -- from Keybinds.conf (overrides lua lock)
hl.bind(
	"SUPER + SHIFT + L",
	hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"),
	{ locked = true, description = "Session: Sleep" }
)
hl.bind(
	"CTRL + SHIFT + ALT + SUPER + Delete",
	hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff"),
	{ description = "Session: Shut down" }
)

--##!!! Apps (lua non-conflicting with conf keybinds)
hl.bind("SUPER + C", hl.dsp.exec_cmd(codeEditor), { description = "App: Code editor" })
hl.bind("SUPER + X", hl.dsp.exec_cmd(textEditor), { description = "App: Text editor" })
hl.bind("CTRL + SUPER + V", hl.dsp.exec_cmd(volumeMixer), { description = "App: Volume mixer" })
hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd(taskManager), { description = "App: Task manager" })
hl.bind("CTRL + SUPER + SHIFT + ALT + W", hl.dsp.exec_cmd(officeSoftware), { description = "App: Office software" })

--# Cursed stuff
hl.bind("CTRL + SUPER + Backslash", hl.dsp.window.resize({ x = 640, y = 480, "exact" }))

--##!!! Samael bar navigation (plain h/l/j/k while submap active)
hl.define_submap("samael-bar-nav", function()
hl.bind("h", hl.dsp.global("quickshell:samaelBarNavKeyH"), { description = "Samael bar: left" })
hl.bind("l", hl.dsp.global("quickshell:samaelBarNavKeyL"), { description = "Samael bar: right" })
hl.bind("j", hl.dsp.global("quickshell:samaelBarNavKeyJ"), { description = "Samael bar: action" })
hl.bind("k", hl.dsp.global("quickshell:samaelBarNavKeyK"), { description = "Samael bar: alt action" })
hl.bind("ESCAPE", hl.dsp.global("quickshell:samaelBarNavKeyEsc"), { description = "Samael bar: exit" })
end)

--##!!! Samael session menu (vim while overlay open)
hl.define_submap("samael-session-menu", function()
hl.bind("h", hl.dsp.global("quickshell:samaelSessionMenuKeyH"), { description = "Session: left" })
hl.bind("l", hl.dsp.global("quickshell:samaelSessionMenuKeyL"), { description = "Session: right" })
hl.bind("j", hl.dsp.global("quickshell:samaelSessionMenuKeyJ"), { description = "Session: down" })
hl.bind("k", hl.dsp.global("quickshell:samaelSessionMenuKeyK"), { description = "Session: up" })
hl.bind("RETURN", hl.dsp.global("quickshell:samaelSessionMenuKeyEnter"), { description = "Session: activate" })
hl.bind("ESCAPE", hl.dsp.global("quickshell:samaelSessionMenuKeyEsc"), { description = "Session: close" })
end)

--##!!! Virtual machines (lua non-conflicting)
hl.define_submap("virtual-machine", function()
	hl.bind("SUPER + ALT + F1", function()
		local currentsubmap = hl.get_current_submap()
		if currentsubmap == "virtual-machine" then
			hl.dispatch(
				hl.dsp.exec_cmd("notify-send 'Exited Virtual Machine submap' 'Keybinds re-enabled' -a 'Hyprland'")
			)
			hl.dispatch(hl.dsp.submap("reset"))
		elseif currentsubmap == "" then
			hl.dispatch(
				hl.dsp.exec_cmd(
					"notify-send 'Entered Virtual Machine submap' 'Keybinds disabled. hit SUPER+ALT+F1 to escape' -a 'Hyprland'"
				)
			)
			hl.dispatch(hl.dsp.submap("virtual-machine"))
		end
	end, { submap_universal = true })
end)

--##!!! Testing (lua non-conflicting)
hl.bind(
	"SUPER + ALT + F11",
	hl.dsp.exec_cmd(
		'bash -c \'RANDOM_IMAGE=$(find ~/Pictures -type f | shuf -n 1); ACTION=$(notify-send "Test notification with body image" "This notification should contain your user account <b>image</b> and <a href=\\"https://discord.com/app\\">Discord</a> <b>icon</b>. Oh and here is a random image in your Pictures folder: <img src=\\"$RANDOM_IMAGE\\" alt=\\"Testing image\\"/>" -a "Hyprland" -p -h "string:image-path:/var/lib/AccountsService/icons/$USER" -t 6000 -i "discord" -A "openImage=Profile image" -A "action2=Open the random image" -A "action3=Useless button"); [[ $ACTION == *openImage ]] && xdg-open "/var/lib/AccountsService/icons/$USER"; [[ $ACTION == *action2 ]] && xdg-open "$RANDOM_IMAGE"\''
	)
)
hl.bind(
	"SUPER + ALT + F12",
	hl.dsp.exec_cmd(
		'bash -c \'RANDOM_IMAGE=$(find ~/Pictures -type f | shuf -n 1); ACTION=$(notify-send "Test notification" "This notification should contain a random image in your <b>Pictures</b> folder and <a href=\\"https://discord.com/app\\">Discord</a> <b>icon</b>.\n<i>Flick right to dismiss!</i>" -a "Discord (fake)" -p -h "string:image-path:$RANDOM_IMAGE" -t 6000 -i "discord" -A "openImage=Profile image" -A "action2=Useless button"); [[ $ACTION == *openImage ]] && xdg-open "/var/lib/AccountsService/icons/$USER"\''
	)
)
hl.bind(
	"SUPER + ALT + Equal",
	hl.dsp.exec_cmd("notify-send 'Urgent notification' 'Ah hell no' -u critical -a 'Hyprland keybind'")
)
hl.bind(
	"SUPER + SHIFT + T",
	hl.dsp.exec_cmd("bash /home/samael/.config/hypr/scripts/__TestSimple.sh"),
	{ description = "script via bash" }
)
