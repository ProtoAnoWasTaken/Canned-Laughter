local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "joker_template",
    path = "template_joker.png",
    px = 69,
    py = 93,
})

local function canlaugh_joker_template_face_count()
    local count = 0

    for _, playing_card in ipairs((G and G.playing_cards) or {}) do
        if playing_card and type(playing_card.is_face) == "function" and playing_card:is_face() then
            count = count + 1
        end
    end

    return count
end

local function canlaugh_joker_template_face_target()
    local starting_params = G and G.GAME and G.GAME.starting_params
    if starting_params and starting_params.no_faces then
        return 0
    end

    local selected_back = G and G.GAME and G.GAME.selected_back
    local effect = selected_back and selected_back.effect
    local center = effect and effect.center
    local config = center and center.config
    if config and config.remove_faces then
        return 0
    end

    return 12
end

local function canlaugh_joker_template_mult(card, fallback)
    local extra = card and card.ability and card.ability.extra or fallback
    local missing_faces = math.max(0, canlaugh_joker_template_face_target() - canlaugh_joker_template_face_count())

    return missing_faces * extra.mult_gain, missing_faces
end

local function canlaugh_joker_template_won_deck(deck_key)
    if not deck_key then
        return false
    end

    local profile = G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    local usage = profile and profile.deck_usage and profile.deck_usage[deck_key]

    return usage and (
        next(usage.wins or {}) ~= nil
        or next(usage.wins_by_key or {}) ~= nil
    )
end

if CL.barter then
    CL.barter.register_rep_modifier("joker_template", function(phase, context)
        if phase == "availability" and context.booster_kind == "Arcana" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_joker_template") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Arcana" then
            local center = G.P_CENTERS and G.P_CENTERS.c_strength
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_joker_template") or {}) do
                local rep = center and CL.barter.collection_representative(center, "Arcana")
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end

SMODS.Joker({
    key = "joker_template",
    name = "Joker Template",
    atlas = "joker_template",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    unlocked = false,
    config = {
        extra = {
            mult_gain = 6,
        },
    },
    loc_txt = {
        name = "Joker Template",
        text = {
            "{C:mult}+#1#{} Mult for each {C:attention}face card{}",
            "below {C:attention}#3#{} in your full deck",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult){}",
        },
        unlock = {
            "Win a run with the",
            "{C:attention}Abandoned Deck{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local mult = canlaugh_joker_template_mult(card, self.config.extra)
        local extra = card and card.ability and card.ability.extra or self.config.extra

        return {
            vars = {
                extra.mult_gain,
                mult,
                canlaugh_joker_template_face_target(),
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        if not (args and args.type == "win_deck") then
            return false
        end

        local selected_back = G and G.GAME and G.GAME.selected_back
        local selected_key = selected_back
            and selected_back.effect
            and selected_back.effect.center
            and selected_back.effect.center.key

        return args.deck == "b_abandoned"
            or selected_key == "b_abandoned"
            or canlaugh_joker_template_won_deck("b_abandoned")
    end,
    add_to_deck = function(self, card, from_debuff)
        if not from_debuff
            and canlaugh_joker_template_face_target() == 0
            and type(check_for_unlock) == "function"
        then
            check_for_unlock({ type = "canlaugh_now_what" })
        end
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            local mult = canlaugh_joker_template_mult(card, self.config.extra)
            if mult > 0 then
                return {
                    mult = mult,
                }
            end
        end
    end,
})
