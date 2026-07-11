-- ######## Window rules (from WindowRules.conf) ########

--##!!! Tags (from WindowRules.conf)

--# browser tags
hl.window_rule({
	match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" },
	tag = "+browser",
})
hl.window_rule({ match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(chrome-.+-Default)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Cc]hromium)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Tt]horium-browser|[Cc]achy-browser)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(zen-alpha|zen|zen-browser)$" }, tag = "+browser" })

-- Zen immediate is applied by ~/.config/zen/launch.sh (blur: default / tag browser).

--# notif tags
hl.window_rule({
	match = { class = "^(swaync-control-center|swaync-notification-window|swaync-client|class)$" },
	tag = "+notif",
})

--# KooL settings tags
hl.window_rule({ match = { title = "^(KooL Quick Cheat Sheet)$" }, tag = "+KooL_Cheat" })
hl.window_rule({ match = { title = "^(KooL Hyprland Settings)$" }, tag = "+KooL_Settings" })
hl.window_rule({ match = { class = "^(nwg-displays|nwg-look)$" }, tag = "+KooL-Settings" })

--# terminal tags
hl.window_rule({ match = { class = "^(Alacritty|kitty|kitty-dropterm)$" }, tag = "+terminal" })

--# email tags
hl.window_rule({ match = { class = "^([Tt]hunderbird|org.gnome.Evolution)$" }, tag = "+email" })
hl.window_rule({ match = { class = "^(eu.betterbird.Betterbird)$" }, tag = "+email" })

--# project tags
hl.window_rule({ match = { class = "^(codium|codium-url-handler|VSCodium)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(VSCode|code|code-url-handler)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(jetbrains-.+)$" }, tag = "+projects" })

--# screenshare tags
hl.window_rule({ match = { class = "^(com.obsproject.Studio)$" }, tag = "+screenshare" })

--# IM tags
hl.window_rule({ match = { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(ZapZap|com.rtosta.zapzap)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(teams-for-linux)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(im.riot.Riot|Element)$" }, tag = "+im" })

--# game tags
hl.window_rule({ match = { class = "^(gamescope)$" }, tag = "+games" })
hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, tag = "+games" })

--# gamestore tags
hl.window_rule({ match = { class = "^([Ss]team)$" }, tag = "+gamestore" })
hl.window_rule({ match = { title = "^([Ll]utris)$" }, tag = "+gamestore" })
hl.window_rule({ match = { class = "^(com.heroicgameslauncher.hgl)$" }, tag = "+gamestore" })

--# file-manager tags
hl.window_rule({ match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$" }, tag = "+file-manager" })
hl.window_rule({ match = { class = "^(app.drey.Warp)$" }, tag = "+file-manager" })

--# wallpaper tags
hl.window_rule({ match = { class = "^([Ww]aytrogen)$" }, tag = "+wallpaper" })

--# multimedia tags
hl.window_rule({ match = { class = "^([Aa]udacious)$" }, tag = "+multimedia" })
hl.window_rule({ match = { class = "^(spotify)$" }, tag = "+multimedia" })

--# multimedia-video tags
hl.window_rule({ match = { class = "^([Mm]pv|vlc)$" }, tag = "+multimedia_video" })

--# settings tags
hl.window_rule({ match = { title = "^(ROG Control)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(wihotspot(-gui)?)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^([Bb]aobab|org.gnome.[Bb]aobab)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(gnome-disks|wihotspot(-gui)?)$" }, tag = "+settings" })
hl.window_rule({ match = { title = "^(Kvantum Manager)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(file-roller|org.gnome.FileRoller)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" }, tag = "+settings" })
hl.window_rule({
	match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },
	tag = "+settings",
})
hl.window_rule({ match = { class = "^(qt5ct|qt6ct|[Yy]ad)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(xdg-desktop-portal-gtk)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^([Rr]ofi)$" }, tag = "+settings" })

--# viewer tags
hl.window_rule({
	match = { class = "^(gnome-system-monitor|org.gnome.SystemMonitor|io.missioncenter.MissionCenter)$" },
	tag = "+viewer",
})
hl.window_rule({ match = { class = "^(evince)$" }, tag = "+viewer" })
hl.window_rule({ match = { class = "^(eog|org.gnome.Loupe)$" }, tag = "+viewer" })

--##!!! Special overrides (from WindowRules.conf)
hl.window_rule({ match = { tag = "multimedia_video" }, no_blur = true })
hl.window_rule({ match = { tag = "multimedia_video" }, opacity = 1.0 })

--##!!! Position / Center (from WindowRules.conf)
hl.window_rule({ match = { tag = "KooL_Cheat" }, center = true })
hl.window_rule({ match = { class = "^([Tt]hunar)$" }, center = true })
hl.window_rule({ match = { title = "^(ROG Control)$" }, center = true })
hl.window_rule({ match = { tag = "KooL-Settings" }, center = true })
hl.window_rule({ match = { title = "^(Keybindings)$" }, center = true })
hl.window_rule({
	match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },
	center = true,
})
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" }, center = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, center = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, move = { "72%", "7%" } })

--##!!! Idleinhibit (from WindowRules.conf)
hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })

--##!!! Float (from WindowRules.conf)
hl.window_rule({ match = { tag = "KooL_Cheat" }, float = true })
hl.window_rule({ match = { tag = "wallpaper" }, float = true })
hl.window_rule({ match = { tag = "settings" }, float = true })
hl.window_rule({ match = { tag = "viewer" }, float = true })
hl.window_rule({ match = { tag = "KooL-Settings" }, float = true })
hl.window_rule({ match = { class = "^([Zz]oom|onedriver|onedriver-launcher)$" }, float = true })
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$", title = "^(Calculator)$" }, float = true })
hl.window_rule({ match = { class = "^(mpv|com.github.rafostar.Clapper)$" }, float = true, pin = true })
hl.window_rule({ match = { class = "^([Qq]alculate-gtk)$" }, float = true })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, float = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true })

--# Float popups and dialogues
hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true })
hl.window_rule({ match = { title = "^(Authentication Required)$" }, center = true })
hl.window_rule({ match = { class = "^(codium|codium-url-handler|VSCodium)$" }, float = true })
hl.window_rule({ match = { class = "^(com.heroicgameslauncher.hgl)$" }, float = true })
hl.window_rule({ match = { class = "^([Ss]team)$" }, float = true })
hl.window_rule({ match = { class = "^([Tt]hunar)$" }, float = true })
hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, float = true })
hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, center = true })
hl.window_rule({ match = { title = "^(Add Folder to Workspace)$" }, size = { "(monitor_w*0.7)", "(monitor_h*0.6)" } })
hl.window_rule({ match = { title = "^(Save As)$" }, float = true })
hl.window_rule({ match = { title = "^(Save As)$" }, center = true })
hl.window_rule({ match = { title = "^(Save As)$" }, size = { "(monitor_w*0.7)", "(monitor_h*0.6)" } })
hl.window_rule({ match = { title = "^(Open Files)$" }, float = true })
hl.window_rule({ match = { title = "^(Open Files)$" }, size = { "(monitor_w*0.7)", "(monitor_h*0.6)" } })
hl.window_rule({ match = { title = "^(SDDM Background)$" }, float = true })
hl.window_rule({ match = { title = "^(SDDM Background)$" }, center = true })
hl.window_rule({ match = { title = "^(SDDM Background)$" }, size = { "(monitor_w*0.16)", "(monitor_h*0.12)" } })
hl.window_rule({ match = { class = "^(yad)$", title = "^(YAD)$" }, float = true })
hl.window_rule({ match = { class = "^(yad)$", title = "^(YAD)$" }, center = true })
hl.window_rule({ match = { class = "^(yad)$", title = "^(YAD)$" }, size = { "(monitor_w*0.2)", "(monitor_h*0.2)" } })

--##!!! Opacity (from WindowRules.conf)
hl.window_rule({ match = { tag = "browser" }, opacity = 1.0, 0.8 })
hl.window_rule({ match = { tag = "projects" }, opacity = 0.9, 0.8 })
hl.window_rule({ match = { tag = "im" }, opacity = 0.94, 0.86 })
hl.window_rule({ match = { tag = "multimedia" }, opacity = 0.94, 0.86 })
hl.window_rule({ match = { tag = "file-manager" }, opacity = 0.9, 0.8 })
hl.window_rule({ match = { tag = "terminal" }, opacity = 0.9, 0.7 })
hl.window_rule({ match = { tag = "settings" }, opacity = 0.8, 0.7 })
hl.window_rule({ match = { tag = "viewer" }, opacity = 0.82, 0.75 })
hl.window_rule({ match = { tag = "wallpaper" }, opacity = 0.9, 0.7 })
hl.window_rule({ match = { class = "^(gedit|org.gnome.TextEditor|mousepad)$" }, opacity = 0.8, 0.7 })
hl.window_rule({ match = { class = "^(deluge)$" }, opacity = 0.9, 0.8 })
hl.window_rule({ match = { class = "^(seahorse)$" }, opacity = 0.9, 0.8 })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, opacity = 0.95, 0.75 })

--##!!! Size (from WindowRules.conf)
hl.window_rule({ match = { tag = "KooL_Cheat" }, size = { "(monitor_w*0.65)", "(monitor_h*0.9)" } })
hl.window_rule({ match = { tag = "wallpaper" }, size = { "(monitor_w*0.7)", "(monitor_h*0.7)" } })
hl.window_rule({ match = { tag = "settings" }, size = { "(monitor_w*0.7)", "(monitor_h*0.7)" } })
hl.window_rule({
	match = { class = "^([Ww]hatsapp-for-linux|ZapZap|com.rtosta.zapzap)$" },
	size = { "(monitor_w*0.6)", "(monitor_h*0.7)" },
})
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, size = { "(monitor_w*0.6)", "(monitor_h*0.7)" } })

--##!!! Pin (from WindowRules.conf)
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, pin = true })
hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, keep_aspect_ratio = true })

--##!!! Blur & Fullscreen (from WindowRules.conf)
hl.window_rule({ match = { tag = "games" }, fullscreen = 1, no_blur = true })
hl.window_rule({ match = { tag = "games" }, fullscreen = true })

--##!!! Nofocus (from WindowRules.conf)
hl.window_rule({ match = { class = "^(jetbrains-.*)$" }, no_initial_focus = true })
hl.window_rule({ match = { title = "^(wind.*)$" }, no_initial_focus = true })

-- ######## Window rules (from lua - non-conflicting) ########

-- Disable blur for xwayland context menus and all windows
hl.window_rule({ match = { class = "^()$", title = "^()$" }, no_blur = true })
-- hl.window_rule({ match = { class = ".*" }, no_blur = true })

-- Floating dialogs (generic)
hl.window_rule({ match = { title = "^(Open File)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Open File)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Select a File)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Select a File)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Choose wallpaper)(.*)$" }, size = { "(monitor_w*0.60)", "(monitor_h*0.65)" } })
hl.window_rule({ match = { title = "^(Open Folder)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Open Folder)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Library)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(Library)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(File Upload)(.*)$" }, center = true })
hl.window_rule({ match = { title = "^(File Upload)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(.*)(wants to save)$" }, center = true })
hl.window_rule({ match = { title = "^(.*)(wants to save)$" }, float = true })
hl.window_rule({ match = { title = "^(.*)(wants to open)$" }, center = true })
hl.window_rule({ match = { title = "^(.*)(wants to open)$" }, float = true })

-- Specific apps float
hl.window_rule({ match = { class = "^(blueberry\\.py)$" }, float = true })
hl.window_rule({ match = { class = "^(guifetch)$" }, float = true }) -- FlafyDev/guifetch
hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, size = { "(monitor_w*0.45)", "(monitor_h*0.45)" } })
hl.window_rule({ match = { class = "^(pavucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true })
hl.window_rule({
	match = { class = "^(org.pulseaudio.pavucontrol)$" },
	size = { "(monitor_w*0.45)", "(monitor_h*0.45)" },
})
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, center = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, size = { "(monitor_w*0.45)", "(monitor_h*0.45)" } })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, center = true })
hl.window_rule({ match = { class = ".*plasmawindowed.*" }, float = true })
hl.window_rule({ match = { class = "kcm_.*" }, float = true })
hl.window_rule({ match = { class = ".*bluedevilwizard" }, float = true })
hl.window_rule({ match = { title = ".*Welcome" }, float = true })
hl.window_rule({ match = { title = "^(illogical-impulse Settings)$" }, float = true })
hl.window_rule({ match = { title = ".*Shell conflicts.*" }, float = true })
hl.window_rule({ match = { class = "org.freedesktop.impl.portal.desktop.kde" }, float = true })
hl.window_rule({
	match = { class = "org.freedesktop.impl.portal.desktop.kde" },
	size = { "(monitor_w*0.60)", "(monitor_h*0.65)" },
})
hl.window_rule({ match = { class = "^(Zotero)$" }, float = true })
hl.window_rule({ match = { class = "^(Zotero)$" }, size = { "(monitor_w*0.45)", "(monitor_h*0.45)" } })

-- Move / hide
hl.window_rule({ match = { class = "^(plasma-changeicons)$" }, float = true })
hl.window_rule({ match = { class = "^(plasma-changeicons)$" }, no_initial_focus = true })
hl.window_rule({ match = { class = "^(plasma-changeicons)$" }, move = { 999999, 999999 } })
hl.window_rule({ match = { title = "^(Copying — Dolphin)$" }, move = { 40, 80 } })

-- Tiling
hl.window_rule({ match = { class = "^dev\\.warp\\.Warp$" }, tile = true })

-- Picture-in-Picture size
hl.window_rule({
	match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },
	size = { "(monitor_w*0.25)", "(monitor_h*0.25)" },
})
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, keep_aspect_ratio = true })
hl.window_rule({ match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, pin = true })

-- Screen sharing
hl.window_rule({ match = { title = ".*is sharing (a window|your screen).*" }, float = true })
hl.window_rule({ match = { title = ".*is sharing (a window|your screen).*" }, pin = true })
hl.window_rule({
	match = { title = ".*is sharing (a window|your screen).*" },
	move = { "(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)" },
})

-- Tearing
hl.window_rule({ match = { title = ".*\\.exe" }, immediate = true })
hl.window_rule({ match = { title = ".*minecraft.*" }, immediate = true })
hl.window_rule({ match = { class = "^(steam_app).*" }, immediate = true })

-- No shadow for tiled windows
hl.window_rule({ match = { float = 0 }, no_shadow = true })

-- ######## Workspace rules ########
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

--# Workspace assignment (from WindowRules.conf)
hl.window_rule({ match = { tag = "email*" }, workspace = 1 })
hl.window_rule({ match = { tag = "projects*" }, workspace = 1 })
hl.window_rule({ match = { tag = "browser*" }, workspace = 2 })
hl.window_rule({ match = { tag = "multimedia*" }, workspace = 3 })
hl.window_rule({ match = { tag = "im*" }, workspace = 4 })
hl.window_rule({ match = { tag = "settings*" }, workspace = 5 })

-- ######## Layer rules (from WindowRules.conf) ########
hl.layer_rule({ match = { namespace = "rofi" }, blur = true })
hl.layer_rule({ match = { namespace = "notifications" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, ignore_alpha = 0.5 })

-- ######## Layer rules (from lua - non-conflicting) ########
hl.layer_rule({ match = { namespace = ".*" }, xray = true })
hl.layer_rule({ match = { namespace = "walker" }, no_anim = true })
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })
hl.layer_rule({ match = { namespace = "overview" }, no_anim = true })
hl.layer_rule({ match = { namespace = "anyrun" }, no_anim = true })
hl.layer_rule({ match = { namespace = "indicator.*" }, no_anim = true })
hl.layer_rule({ match = { namespace = "osk" }, no_anim = true })
hl.layer_rule({ match = { namespace = "hyprpicker" }, no_anim = true })

hl.layer_rule({ match = { namespace = "noanim" }, no_anim = true })
hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, blur = true })
hl.layer_rule({ match = { namespace = "gtk-layer-shell" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "launcher" }, blur = true })
hl.layer_rule({ match = { namespace = "launcher" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "notifications" }, ignore_alpha = 0.69 })
hl.layer_rule({ match = { namespace = "logout_dialog" }, blur = true }) -- wlogout

-- ags
hl.layer_rule({ match = { namespace = "sideleft.*" }, animation = "slide left" })
hl.layer_rule({ match = { namespace = "sideright.*" }, animation = "slide right" })
hl.layer_rule({ match = { namespace = "session[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "bar[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "bar[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "barcorner.*" }, blur = true })
hl.layer_rule({ match = { namespace = "barcorner.*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "dock[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "dock[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "indicator.*" }, blur = true })
hl.layer_rule({ match = { namespace = "indicator.*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "overview[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "overview[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "cheatsheet[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "cheatsheet[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "sideright[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "sideright[0-9]*" }, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "sideleft[0-9]*" }, blur = true })
hl.layer_rule({ match = { namespace = "sideleft[0-9]*" }, ignore_alpha = 0.6 })

-- Quickshell
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur_popups = true })
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:.*" }, ignore_alpha = 0.79 })
hl.layer_rule({ match = { namespace = "quickshell:bar" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:actionCenter" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:cheatsheet" }, animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:dock" }, animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:screenCorners" }, animation = "popin 120%" })
hl.layer_rule({ match = { namespace = "quickshell:lockWindowPusher" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:notificationPopup" }, animation = "fade" })
hl.layer_rule({ match = { namespace = "quickshell:overlay" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:overlay" }, ignore_alpha = 1 })
hl.layer_rule({ match = { namespace = "quickshell:overview" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:osk" }, animation = "slide bottom" })
hl.layer_rule({ match = { namespace = "quickshell:polkit" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:popup" }, xray = false })
hl.layer_rule({ match = { namespace = "quickshell:popup" }, ignore_alpha = 1 })
hl.layer_rule({ match = { namespace = "quickshell:mediaControls" }, ignore_alpha = 1 })
hl.layer_rule({ match = { namespace = "quickshell:reloadPopup" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:regionSelector" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:screenshot" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:session" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell:session" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:session" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "quickshell:sidebarRight" }, animation = "slide right" })
hl.layer_rule({ match = { namespace = "quickshell:sidebarLeft" }, animation = "slide left" })
hl.layer_rule({ match = { namespace = "quickshell:verticalBar" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell:osk" }, order = -1 })
hl.layer_rule({ match = { namespace = "quickshell:wallpaperSelector" }, animation = "slide top" })
hl.layer_rule({ match = { namespace = "quickshell:wNotificationCenter" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:wOnScreenDisplay" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:wStartMenu" }, no_anim = true })
hl.layer_rule({ match = { namespace = "quickshell:wTaskView" }, ignore_alpha = 0 })
hl.layer_rule({ match = { namespace = "quickshell:wTaskView" }, no_anim = true })

-- Launchers need to be FAST
hl.layer_rule({ match = { namespace = "gtk4-layer-shell" }, no_anim = true })
