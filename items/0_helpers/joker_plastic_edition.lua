local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.joker_plastic_edition = CL.joker_plastic_edition or {}
local JPE = CL.joker_plastic_edition

local PLASTIC_KEY = "e_canlaugh_plastic"
local PLASTIC_TYPE = "canlaugh_plastic"

local function canlaugh_copy(value)
    if type(value) ~= "table" then
        return value
    end

    if type(copy_table) == "function" then
        return copy_table(value)
    end

    local copied = {}
    for k, v in pairs(value) do
        copied[k] = canlaugh_copy(v)
    end
    return copied
end

local function canlaugh_plastic_center()
    return G and G.P_CENTERS and G.P_CENTERS[PLASTIC_KEY]
end

local function canlaugh_remove_existing_edition(card)
    if not (card and card.edition) then
        return
    end

    card.ability = card.ability or {}
    card.ability.card_limit = (card.ability.card_limit or 0) - (card.edition.card_limit or 0)
    card.ability.extra_slots_used = (card.ability.extra_slots_used or 0) - (card.edition.extra_slots_used or 0)

    local old_key = card.edition.key
    if old_key then
        card.ignore_base_shader = card.ignore_base_shader or {}
        card.ignore_shadow = card.ignore_shadow or {}
        card.ignore_base_shader[old_key] = nil
        card.ignore_shadow[old_key] = nil

        local old_center = G and G.P_CENTERS and G.P_CENTERS[old_key]
        if old_center and type(old_center.on_remove) == "function" then
            old_center.on_remove(card)
        end
    end
end

function JPE.apply_now(card)
    local plastic = canlaugh_plastic_center()
    if not (card and plastic and card.ability) then
        return false
    end

    if SMODS and SMODS.enh_cache and type(SMODS.enh_cache.write) == "function" then
        SMODS.enh_cache:write(card, nil)
    end

    canlaugh_remove_existing_edition(card)

    card.ignore_base_shader = card.ignore_base_shader or {}
    card.ignore_shadow = card.ignore_shadow or {}
    card.edition = {
        [PLASTIC_TYPE] = true,
        type = PLASTIC_TYPE,
        key = PLASTIC_KEY,
    }

    if plastic.override_base_shader or plastic.disable_base_shader then
        card.ignore_base_shader[PLASTIC_KEY] = true
    end
    if plastic.no_shadow or plastic.disable_shadow then
        card.ignore_shadow[PLASTIC_KEY] = true
    end

    for k, v in pairs(plastic.config or {}) do
        card.edition[k] = canlaugh_copy(v)
    end

    if type(plastic.on_apply) == "function" then
        plastic.on_apply(card)
    end

    card.ability.card_limit = (card.ability.card_limit or 0) + (card.edition.card_limit or 0)
    card.ability.extra_slots_used = (card.ability.extra_slots_used or 0) + (card.edition.extra_slots_used or 0)

    if type(card.set_cost) == "function" then
        card:set_cost()
    end

    return true
end

local function canlaugh_play_plastic_feedback(card)
    if card and type(card.juice_up) == "function" then
        card:juice_up(1, 0.5)
    end

    local plastic = canlaugh_plastic_center()
    local sound_config = plastic and plastic.canlaugh_native_sound
    local native_sound = CL.native_sound
    if sound_config and native_sound and type(native_sound.play) == "function" then
        local ok = pcall(native_sound.play, sound_config.path, {
            pitch = sound_config.pitch,
            volume = sound_config.volume,
            source_type = "static",
        })
        if ok then
            return
        end
    end

    if plastic and plastic.sound and type(play_sound) == "function" then
        play_sound(plastic.sound.sound, plastic.sound.per, plastic.sound.vol)
    end
end

function JPE.apply_after(target, message_card, message, colour)
    if not target then
        return false
    end

    if not (G and G.E_MANAGER and Event) then
        return JPE.apply_now(target)
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.25,
        func = function()
            if target and not target.removed and not target.destroyed and JPE.apply_now(target) then
                canlaugh_play_plastic_feedback(target)

                if message_card and not message_card.removed then
                    card_eval_status_text(message_card, "extra", nil, nil, nil, {
                        message = message or "Edition!",
                        colour = colour or G.C.EDITION,
                    })
                end
            end

            return true
        end,
    }))

    return true
end
