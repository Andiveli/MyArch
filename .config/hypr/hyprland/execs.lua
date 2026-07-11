-- =====================================================================
-- FORMER 'exec' COMMANDS (Outside the start function)
-- =====================================================================
-- Cursor
hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")

-- =====================================================================
-- FORMER 'exec-once' COMMANDS (Inside hyprland.start)
-- =====================================================================

hl.on("hyprland.start", function()
	-- Custom
	hl.exec_cmd(HOME .. "/Documentos/Handy_0.8.3_amd64.AppImage")

	-- Bar / notifications: Quickshell (Samael panel); Waybar + swaync removed from autostart
	hl.exec_cmd(HOME .. "/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
	hl.exec_cmd("pypr &")

	-- Core components
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- xdg-desktop-portal backends (file picker, screenshot, theme, pipewire)
	-- These have no [Install] section, so they must be started on login instead of enabled.
	hl.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland.service xdg-desktop-portal-gtk.service")

	-- Wallpaper daemon + wallust colors (Samael WallustColors reads ~/.config/waybar/wallust/colors-waybar.css)
	hl.exec_cmd("awww-daemon --format xrgb")
	hl.exec_cmd(HOME .. "/.config/hypr/scripts/WallustSwww.sh")
	hl.exec_cmd("qs -c samaelv2 &")

	-- Rainbow borders (multi-color active border + manual angle animation).
	-- Must run after WallustSwww.sh because wallust can set solid borders via the hyprland color template.
	-- The script sets the gradient and starts the background loop for the spinning effect.
	hl.exec_cmd("sleep 2 && " .. HOME .. "/.config/hypr/UserScripts/RainbowBorders.sh &")

	-- Start Quickshell after wallust colors file is ready (same gate Waybar used to use).

	-- Waylandar calendar (second Quickshell instance; does not use qs -c samael)
	-- hl.exec_cmd("sleep 3 && waylandar-widget &")

	-- Audio
	hl.exec_cmd("easyeffects --hide-window --service-mode")

	-- Clipboard: history
	hl.exec_cmd(
		"wl-paste --type text --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'"
	)
	hl.exec_cmd(
		"wl-paste --type image --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'"
	)

	-- Scripts
	hl.exec_cmd("env -u LUA_PATH -u LUA_CPATH bash -c '$HOME/.config/hypr/scripts/Polkit.sh'")
	hl.exec_cmd(HOME .. "/.config/hypr/initial-boot.sh")

	-- Custom
	hl.exec_cmd("fcitx5 -d")
	hl.exec_cmd("blueman-applet")

	-- Full refresh after login (optional): ~/.config/hypr/scripts/WallustSwww.sh && ~/.config/hypr/scripts/Refresh.sh
end)
