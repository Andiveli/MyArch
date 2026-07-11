require("hyprland.lib")
require("hyprland.variables")

local qsScripts = HOME .. "/.config/quickshell/$qsConfig/scripts"
local qsIpcCall = "qs -c $qsConfig ipc call"
local scriptsDir = HOME .. "/.config/hypr/scripts"

-- Super alone → launcher drawer (qs -c samael; global appid samael)
hl.bind("SUPER + SUPER_L", hl.dsp.global("samael:launcher"), { description = "Samael launcher", release = true })
hl.bind("SUPER + SUPER_R", hl.dsp.global("samael:launcher"), { description = "Samael launcher", release = true })

hl.bind("SUPER + E", hl.dsp.exec_cmd("microsoft-edge-stable"), { description = "Open Edge browser" })
hl.bind("SUPER + Z", hl.dsp.exec_cmd(browser), { description = "Open Zen browser" })
hl.bind("SUPER + S", hl.dsp.exec_cmd("spotify"), { description = "Open Spotify" })
hl.bind("SUPER + D", hl.dsp.exec_cmd("discord"), { description = "Open Discord" })
hl.bind("SUPER + T", hl.dsp.exec_cmd("tableplus"), { description = "Open TablePlus" })
hl.bind("ALT + Space", hl.dsp.exec_cmd(scriptsDir .. "/puerta.sh"), { description = "App launcher" })
hl.bind("SUPER + A", hl.dsp.exec_cmd("dolphin"), { description = "Open dolphin" })
hl.bind("SUPER + Return", hl.dsp.exec_cmd("ghostty"), { description = "Open terminal" })

--##!!! Features / Extras
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd(scriptsDir .. "/Refresh.sh"), { description = "refresh bar and menus" })
hl.bind("SUPER + ALT + O", hl.dsp.exec_cmd(scriptsDir .. "/ChangeBlur.sh"), { description = "toggle blur" })
hl.bind("SUPER + SHIFT + G", hl.dsp.exec_cmd(scriptsDir .. "/GameMode.sh"), { description = "toggle game mode" }) --Arreglar --
hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("pypr toggle term"), { description = "DropDown terminal" })
hl.bind("SUPER + CTRL + F", hl.dsp.exec_cmd("hyprctl dispatch fullscreen 1"), { description = "maximize window" }) -- Arreglar --
hl.bind("SUPER + Space", hl.dsp.exec_cmd("hyprctl dispatch togglefloating"), { description = "Float current window" }) -- Arreglar --
hl.bind("SUPER + o", hl.dsp.exec_cmd("pypr toggle ollama"), { description = "Ollama side panel" })

hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd(scriptsDir .. "/WaybarLayout.sh"), { description = "waybar layout menu" }) --Arreglar --
hl.bind("SUPER + N", hl.dsp.exec_cmd(scriptsDir .. "/Hyprsunset.sh toggle"), { description = "toggle night light" })

--##!!! qs call
hl.bind(
	"SUPER + W",
	hl.dsp.global("quickshell:wallpaperSelectorToggle"),
	{ description = "select wallpaper (Quickshell grid)" }
)
hl.bind("SUPER + SHIFT + W", hl.dsp.global("quickshell:samaelWifiMenuToggle"), { description = "Wi-Fi menu (Samael)" })
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
hl.bind("SUPER + CTRL + B", hl.dsp.global("quickshell:samaelBarNavToggle"), { description = "Samael bar keyboard nav" })
hl.bind("CTRL + ALT + W", hl.dsp.global("quickshell:wallpaperSelectorRandom"), { description = "random wallpaper" })
hl.bind(
	"SUPER + CTRL + O",
	hl.dsp.global("quickshell:samaelSystemSidebarToggle"),
	{ description = "Samael system monitor sidebar (qs -c samael)" }
)
hl.bind(
	"SUPER + SHIFT + O",
	hl.dsp.global("quickshell:samaelOverviewToggle"),
	{ description = "System overview (samaelv2 right pill)" }
)
-- Media: quickshell global (Samael or samaelv2 — whichever `qs -c …` is running registers it)
hl.bind(
	"SUPER + M",
	hl.dsp.global("quickshell:mediaControlsToggle"),
	{ description = "Media manager (active Quickshell config)" }
)
hl.bind(
	"SUPER + SHIFT + M",
	hl.dsp.global("quickshell:samaelSuperMenuToggle"),
	{ description = "Samael super menu (control center)" }
)
hl.bind(
	"SUPER + SHIFT + O",
	hl.dsp.global("quickshell:samaelPerformanceDropToggle"),
	{ description = "Samael performance drop (system monitor)" }
)
hl.bind("CTRL + ALT + L", hl.dsp.global("samael:lock"), { description = "lock screen (qs -c samael)" })

--##!!! System
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("hyprctl dispatch exit 0"), { description = "exit Hyprland" })
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "close active window" })
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd(scriptsDir .. "/Wlogout.sh"), { description = "powermenu" })

--##!!! Move windows
hl.bind("SUPER + CTRL + H", hl.dsp.window.move({ direction = "l" }), { description = "move window left" })
hl.bind("SUPER + CTRL + L", hl.dsp.window.move({ direction = "r" }), { description = "move window right" })
hl.bind("SUPER + CTRL + K", hl.dsp.window.move({ direction = "u" }), { description = "move window up" })
hl.bind("SUPER + CTRL + J", hl.dsp.window.move({ direction = "d" }), { description = "move window down" })

--##!!! Focus (vim-style)
hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }), { description = "focus left" })
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }), { description = "focus right" })
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }), { description = "focus up" })
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }), { description = "focus down" })

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

--# Special workspace
hl.bind(
	"SUPER + SHIFT + U",
	hl.dsp.window.move({ workspace = "special", follow = true }),
	{ description = "move to special workspace" }
)
hl.bind("SUPER + U", hl.dsp.workspace.toggle_special("special"), { description = "toggle special workspace" })

--##!!! Screenshots (from Keybinds.conf)
hl.bind("SUPER + Print", hl.dsp.exec_cmd(scriptsDir .. "/ScreenShot.sh --now"), { description = "screenshot now" })
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
hl.bind("ALT + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })

--##!!! Brightness (lua non-conflicting)
-- brightnessctl always runs; QS ipc optional (was broken: IpcHandler had invalid syntax + exit 0 hid || fallback)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("sh -c '" .. qsIpcCall .. " brightness increment >/dev/null 2>&1; brightnessctl s 5%+'"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("sh -c '" .. qsIpcCall .. " brightness decrement >/dev/null 2>&1; brightnessctl s 5%-'"),
	{ locked = true, repeating = true }
)

--# Color picker
hl.bind(
	"SUPER + SHIFT + C",
	hl.dsp.exec_cmd("hyprpicker -a"),
	{ description = "Utilities: Pick color #RRGGBB >> clipboard" }
)

hl.bind("SUPER + SHIFT + R", hl.dsp.global("quickshell:regionRecord"), { locked = true }) -- Arreglar --
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen"), { locked = true }) -- Arreglar --

-- Waylandar full-month overlay (Super+C is code editor)
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("waylandar-dashboard"), { description = "Calendar: Waylandar dashboard" }) -- Configurar con wallust

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
