local CL = rawget(_G, "CannedLaughter") or {}

CannedLaughter = CL

local function cl_get_edition_sound_key(card)
    local edition = card and card.edition
    if type(edition) ~= "table" then
        return nil
    end

    if type(edition.key) == "string" and G and G.P_CENTERS and G.P_CENTERS[edition.key] then
        return edition.key
    end

    if type(edition.type) == "string" then
        local keyed_center = G and G.P_CENTERS and G.P_CENTERS["e_" .. edition.type]
        if keyed_center then
            return keyed_center.key
        end
    end

    if G and G.P_CENTERS then
        for edition_key, center in pairs(G.P_CENTERS) do
            local suffix = type(edition_key) == "string" and edition_key:gsub("^e_", "") or nil

            if center
                and center.set == "Edition"
                and center.canlaugh_native_sound
                and (edition[edition_key] or edition[suffix])
            then
                return edition_key
            end
        end
    end
end

local function cl_play_edition_sound(edition_key)
    local center = G and G.P_CENTERS and G.P_CENTERS[edition_key]
    local sound_config = center and center.canlaugh_native_sound
    local native_sound = CL.native_sound

    if not (sound_config and native_sound and type(native_sound.play) == "function") then
        return
    end

    local ok, err = pcall(native_sound.play, sound_config.path, {
        pitch = sound_config.pitch,
        volume = sound_config.volume,
        source_type = "static",
    })

    if not ok and type(sendErrorMessage) == "function" then
        sendErrorMessage("[Canned Laughter] Failed to play edition sound: " .. tostring(err))
    end
end

if Card and type(Card.set_edition) == "function" and not CL.edition_sound_hook_installed then
    CL.edition_sound_hook_installed = true
    local cl_set_edition_ref = Card.set_edition

    function Card:set_edition(edition, immediate, silent, ...)
        local results = { cl_set_edition_ref(self, edition, immediate, silent, ...) }
        local edition_sound_key = not silent and cl_get_edition_sound_key(self)

        if edition_sound_key then
            local function play_sound_event()
                cl_play_edition_sound(edition_sound_key)
                return true
            end

            if G and G.E_MANAGER and Event then
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = not immediate and 0.2 or 0,
                    blockable = not immediate,
                    func = play_sound_event,
                }))
            else
                play_sound_event()
            end
        end

        return unpack(results)
    end
end
