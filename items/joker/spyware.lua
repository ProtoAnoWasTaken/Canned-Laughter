SMODS.Shader({
    key = "spyware",
    path = "spyware.fs",
})

SMODS.Atlas({
    key = "spyware",
    path = "spyware_back.png",
    px = 69,
    py = 93,
})

SMODS.Atlas({
    key = "spyware_joker",
    path = "spyware_joker.png",
    px = 69,
    py = 93,
})

local function canlaugh_spyware_skipped_blind_type()
    local blind_on_deck = G and G.GAME and G.GAME.blind_on_deck
    local states = G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind_states

    if blind_on_deck == "Big" then
        return "Small"
    end

    if blind_on_deck == "Boss" then
        if states and states.Big == "Skipped" then
            return "Big"
        end

        return "Boss"
    end

    return "Small"
end

local function canlaugh_spyware_skipped_blind()
    local blind_type = canlaugh_spyware_skipped_blind_type()
    local choices = G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind_choices
    local blind_key = choices and choices[blind_type]

    return blind_type, blind_key and G.P_BLINDS and G.P_BLINDS[blind_key] or nil
end

local function canlaugh_spyware_trigger_setting_blind()
    if not (SMODS and type(SMODS.calculate_card_areas) == "function") then
        return false
    end

    local blind_type, blind = canlaugh_spyware_skipped_blind()
    if not blind then
        return false
    end

    local setting_context = {
        setting_blind = true,
        main_eval = true,
        blind = blind,
        canlaugh_spyware = true,
        canlaugh_spyware_blind_type = blind_type,
    }

    SMODS.calculate_card_areas("jokers", setting_context, nil, { joker_area = true })

    return true
end

local function canlaugh_spyware_draw(card, scale_mod, rotate_mod)
    if not (card and card.children and card.children.floating_sprite) then
        return
    end

    local shader = G and G.SHADERS and G.SHADERS.canlaugh_spyware and "canlaugh_spyware" or "hologram"

    card.hover_tilt = card.hover_tilt * 1.5
    card.children.floating_sprite:draw_shader(
        shader,
        nil,
        card.ARGS.send_to_shader,
        nil,
        card.children.center,
        2 * scale_mod,
        2 * rotate_mod
    )
    card.hover_tilt = card.hover_tilt / 1.5
end

SMODS.Joker({
    key = "spyware",
    name = "Spyware",
    atlas = "spyware",
    soul_atlas = "spyware_joker",
    pos = { x = 0, y = 0 },
    soul_pos = {
        x = 0,
        y = 0,
        draw = canlaugh_spyware_draw,
    },
    rarity = 2,
    cost = 6,
    unlocked = true,
    loc_txt = {
        name = "Spyware",
        text = {
            "{C:attention}Jokers{} that would require",
            "selecting a {C:attention}Blind{}",
            "activate on {C:attention}skip{}",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.skip_blind
            and context.main_eval
            and not context.blueprint
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            if canlaugh_spyware_trigger_setting_blind() then
                return {
                    message = "Intercepted!",
                    colour = G.C.RED,
                }
            end
        end
    end,
})
