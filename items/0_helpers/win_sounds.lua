local CL = rawget(_G, "CannedLaughter") or {}

CannedLaughter = CL

local joker_win_sounds = {
    j_canlaugh_commodore_silence = "sfx_commodoresilence.wav",
    j_canlaugh_paul_revere = "sfx_paulrevere.wav",
}

local joker_keys = {
    "j_canlaugh_commodore_silence",
    "j_canlaugh_paul_revere",
}

local function get_active_win_sound_jokers()
    local present = {}
    local active = {}
    local jokers = G and G.jokers and G.jokers.cards or {}

    for _, joker in ipairs(jokers) do
        local center = joker.config and joker.config.center
        local key = center and center.key

        if key and joker_win_sounds[key] and not joker.debuff then
            present[key] = true
        end
    end

    for _, key in ipairs(joker_keys) do
        if present[key] then
            active[#active + 1] = key
        end
    end

    return active
end

local function choose_win_sound_joker(active)
    if #active == 1 then
        return active[1]
    end

    if type(pseudorandom_element) == "function"
        and type(pseudoseed) == "function"
    then
        return pseudorandom_element(active, pseudoseed("canlaugh_photo_finish"))
    end

    return active[math.random(#active)]
end

local function play_joker_win_sound(key)
    local native_sound = CL.native_sound

    if not native_sound or type(native_sound.play) ~= "function" then
        return false
    end

    local success, source = pcall(
        native_sound.play,
        joker_win_sounds[key],
        {
            source_type = "static",
            volume = 0.7,
        }
    )

    return success and source ~= nil
end

if type(play_sound) == "function" and not CL.joker_win_sound_hook_installed then
    CL.joker_win_sound_hook_installed = true

    local original_play_sound = play_sound

    function play_sound(sound_code, ...)
        if sound_code == "win" then
            local active = get_active_win_sound_jokers()

            if #active > 0 then
                if #active == #joker_keys and type(check_for_unlock) == "function" then
                    check_for_unlock({
                        type = "canlaugh_photo_finish",
                    })
                end

                local key = choose_win_sound_joker(active)

                if play_joker_win_sound(key) then
                    return
                end
            end
        end

        return original_play_sound(sound_code, ...)
    end
end
