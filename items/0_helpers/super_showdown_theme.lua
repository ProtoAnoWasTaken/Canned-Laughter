local CL = CannedLaughter

local function super_showdown_theme_active()
    local blind = G and G.GAME and G.GAME.blind
    local center = blind and blind.config and blind.config.blind

    return center and center.canlaugh_superboss and not blind.disabled
end

local function selected_final_boss_theme()
    if CL.config.final_boss_theme == "Dirty" then
        return "Dirty"
    end

    return "Clean"
end

SMODS.Sound({
    key = "music_canlaugh_final_boss_clean",
    path = "mus_clean.ogg",
    sync = false,
    pitch = 0.7,
    volume = 1,
    select_music_track = function()
        if super_showdown_theme_active() and selected_final_boss_theme() == "Clean" then
            return 100
        end
    end,
})

SMODS.Sound({
    key = "music_canlaugh_final_boss_dirty",
    path = "mus_dirty.ogg",
    sync = false,
    pitch = 0.7,
    volume = 1,
    select_music_track = function()
        if super_showdown_theme_active() and selected_final_boss_theme() == "Dirty" then
            return 100
        end
    end,
})
