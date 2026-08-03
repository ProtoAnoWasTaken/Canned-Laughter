local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_fire_striker_target()
    local helpers = CL.playing_card_jokers
    if not helpers then
        return nil
    end

    local candidates = helpers.find_playing_cards(function(playing_card)
        return helpers.is_playing_card(playing_card)
            and not playing_card.removed
            and not (type(CL.is_frozen) == "function" and CL.is_frozen(playing_card))
            and not next(SMODS.get_enhancements(playing_card) or {})
    end)

    return pseudorandom_element(candidates, pseudoseed("canlaugh_fire_striker"))
end

local function canlaugh_fire_striker_blaze(card)
    local target = canlaugh_fire_striker_target()
    local blazing = G and G.P_CENTERS and G.P_CENTERS.m_canlaugh_blazing
    if not (target and blazing) then
        return false
    end

    target:set_ability(blazing, nil, true)
    discover_card(blazing)
    card_eval_status_text(card, "extra", nil, nil, nil, {
        message = "Blazing!",
        colour = G.C.RED,
    })
    return true
end

if CL.barter then
    CL.barter.register_rep_modifier("fire_striker", function(phase, context)
        if phase == "availability" and context.booster_kind == "Arcana" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_fire_striker") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Arcana" then
            local center = G.P_CENTERS and G.P_CENTERS.c_lovers
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_fire_striker") or {}) do
                local rep = center and CL.barter.collection_representative(center, "Arcana")
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end

SMODS.Atlas({
    key = "fire_striker",
    path = "fire_striker.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "fire_striker",
    name = "Fire Striker",
    atlas = "fire_striker",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    loc_txt = {
        name = "Fire Striker",
        text = {
            "When {C:attention}Blind{} is selected or the score",
            "{C:attention}catches fire{}, enhance a random",
            "unenhanced card to {C:mult,T:m_canlaugh_blazing}Blazing{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        CL.add_unique_tooltip(info_queue, G.P_CENTERS.m_canlaugh_blazing, card)
        return { vars = {} }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            canlaugh_fire_striker_blaze(card)
            return
        end

        if context.final_scoring_step and not context.blueprint and not context.retrigger_joker then
            G.E_MANAGER:add_event(Event({
                func = function()
                    local helpers = CL.playing_card_jokers
                    if helpers and helpers.score_caught_fire(G.ARGS and G.ARGS.score_intensity) then
                        canlaugh_fire_striker_blaze(card)
                    end
                    return true
                end,
            }))
        end
    end,
})
