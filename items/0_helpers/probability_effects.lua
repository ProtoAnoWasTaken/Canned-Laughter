local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.probability_effects = CL.probability_effects or {
    centers = {},
    seals = {},
}
CL.probability_effects.centers = CL.probability_effects.centers or {}
CL.probability_effects.seals = CL.probability_effects.seals or {}

function CL.register_probability_center(key)
    if type(key) ~= "string" then
        return false
    end

    CL.probability_effects.centers[key] = true
    return true
end

function CL.register_probability_seal(key)
    if type(key) ~= "string" then
        return false
    end

    CL.probability_effects.seals[key] = true
    return true
end

local function has_probability_metadata(value, seen)
    if type(value) ~= "table" then
        return false
    end

    seen = seen or {}
    if seen[value] then
        return false
    end
    seen[value] = true

    for key, field in pairs(value) do
        local name = type(key) == "string" and key:lower() or ""

        if field ~= nil
            and (name == "odds"
                or name == "chance"
                or name == "chances"
                or name == "probability"
                or name == "probabilities"
                or name == "has_probability")
        then
            return true
        end

        if type(field) == "table" and has_probability_metadata(field, seen) then
            return true
        end
    end

    return false
end

local function center_has_probability(center)
    if not center then
        return false
    end

    if center.probability or center.has_probability or center.random_effect then
        return true
    end

    return CL.probability_effects.centers[center.key] or has_probability_metadata(center.config)
end

function CL.record_probability_card(card)
    if not (card and card.playing_card) then
        return false
    end

    card.canlaugh_probability_effect = true
    return true
end

function CL.card_has_probability_effect(card)
    if not (card and card.playing_card) then
        return false
    end

    if card.canlaugh_probability_effect or has_probability_metadata(card.ability) then
        return true
    end

    local center = card.config and card.config.center
    if center_has_probability(center) then
        return true
    end

    local edition = card.edition
    local edition_key = edition and (edition.key or (edition.type and "e_" .. edition.type))
    if center_has_probability(edition_key and G and G.P_CENTERS and G.P_CENTERS[edition_key]) then
        return true
    end

    local seal = card.seal
    local seal_center = seal and G and G.P_SEALS and G.P_SEALS[seal]
    local registered_seal = seal and CL.probability_effects.seals[seal]
    if registered_seal or center_has_probability(seal_center) then
        return true
    end

    if SMODS and type(SMODS.get_enhancements) == "function" then
        for key in pairs(SMODS.get_enhancements(card) or {}) do
            if center_has_probability(G and G.P_CENTERS and G.P_CENTERS[key]) then
                return true
            end
        end
    end

    return false
end

CL.register_probability_center("m_glass")
CL.register_probability_center("m_lucky")

if SMODS and type(SMODS.pseudorandom_probability) == "function" and not CL.probability_effect_roll_hook_installed then
    CL.probability_effect_roll_hook_installed = true
    local probability_ref = SMODS.pseudorandom_probability

    function SMODS.pseudorandom_probability(trigger_obj, ...)
        if trigger_obj and trigger_obj.playing_card then
            CL.record_probability_card(trigger_obj)

            if CL.boss_active and CL.boss_active("bl_canlaugh_chance") then
                if type(trigger_obj.set_debuff) == "function" then
                    trigger_obj:set_debuff(true)
                end
                return false
            end
        end

        return probability_ref(trigger_obj, ...)
    end
end
