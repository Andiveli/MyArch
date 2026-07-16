-- Read wallust color12 for active_border (matches Quickshell's borderColor)
local function get_wallust_color(idx, fallback)
    local f = io.open(os.getenv("HOME") .. "/.config/hypr/wallust/wallust-hyprland.conf", "r")
    if not f then return fallback end
    local content = f:read("*all")
    f:close()
    local c = content:match("%$color" .. idx .. "%s*=%s*rgb%((%x+)%)")
    return c or fallback
end

local active = get_wallust_color(12, "067263")
local inactive = get_wallust_color(1, "151d18")

hl.config({
    general = {
        col = {
            active_border   = "rgba(" .. active .. "FF)",
            inactive_border = "rgba(" .. inactive .. "33)",
        },
    },
    misc = {
        background_color = "rgba(0d1510FF)",
    },
})

hl.window_rule({
    match        = { pin = 1 },
    border_color = "rgba(47f4aaAA) rgba(47f4aa77)",
})
