local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_all_scored_suit(suit, scoring_hand)
    scoring_hand = scoring_hand or (SMODS and SMODS.last_hand and SMODS.last_hand.scoring_hand) or {}
    if #scoring_hand == 0 then
        return false
    end

    for _, playing_card in ipairs(scoring_hand) do
        if not playing_card:is_suit(suit) then
            return false
        end
    end

    return true
end

CL.suit_showdown_unlocks = CL.suit_showdown_unlocks or {}

function CL.register_suit_showdown_unlock(joker_key, blind_key, suit, unlock_type)
    CL.suit_showdown_unlocks[joker_key] = {
        blind_key = blind_key,
        suit = suit,
        unlock_type = unlock_type,
    }

    if not (SMODS and type(SMODS.calculate_context) == "function") or CL.suit_showdown_unlock_hook_installed then
        return
    end

    CL.suit_showdown_unlock_hook_installed = true
    local calculate_context_ref = SMODS.calculate_context

    function SMODS.calculate_context(context, return_table, no_resolve, ...)
        if not (context and context.end_of_round and context.beat_boss) then
            return calculate_context_ref(context, return_table, no_resolve, ...)
        end

        local blind = G and G.GAME and G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind
        local blind_key = blind and blind.key

        for _, unlock in pairs(CL.suit_showdown_unlocks) do
            if type(check_for_unlock) == "function"
                and blind_key == unlock.blind_key
                and canlaugh_all_scored_suit(unlock.suit, context.scoring_hand)
            then
                check_for_unlock({
                    type = unlock.unlock_type,
                })
            end
        end

        return calculate_context_ref(context, return_table, no_resolve, ...)
    end
end

CL.register_suit_showdown_unlock(
    "j_canlaugh_dark_pentacle",
    "bl_canlaugh_celadon_coin",
    "Diamonds",
    "canlaugh_dark_pentacle"
)

local function canlaugh_dark_pentacle_transmute(target, center, message, colour)
    if not (target and center and type(target.set_ability) == "function") then
        return
    end

    target:set_ability(center, nil, true)
    target:juice_up(0.3, 0.5)
    card_eval_status_text(target, "extra", nil, nil, nil, {
        message = message,
        colour = colour,
    })
end

if CL.barter then
    CL.barter.register_rep_modifier("dark_pentacle", function(phase, context)
        if phase == "availability" and context.booster_kind == "Arcana" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_dark_pentacle") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Arcana" then
            local center = G.P_CENTERS and G.P_CENTERS.c_star
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_dark_pentacle") or {}) do
                local rep = center and CL.barter.collection_representative(center, "Arcana")
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end

SMODS.Atlas({
    key = "dark_pentacle",
    path = "dark_pentacle.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "dark_pentacle",
    name = "Dark Pentacle",
    atlas = "dark_pentacle",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    loc_txt = {
        name = "Dark Pentacle",
        text = {
            "Scored {C:diamonds}Diamond{} cards become",
            "{C:green,T:m_lucky}Lucky Cards{}; held {C:diamonds}Diamond{} cards",
            "become {C:gold,T:m_gold}Gold Cards{}",
        },
        unlock = {
            "Defeat the {C:attention}Celadon Coin{}",
            "with only scored {C:diamonds}Diamonds{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        CL.add_unique_tooltip(info_queue, G.P_CENTERS.m_lucky, card)
        CL.add_unique_tooltip(info_queue, G.P_CENTERS.m_gold, card)
        return { vars = {} }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_dark_pentacle"
    end,
    calculate = function(self, card, context)
        local target = context.other_card
        if context.individual
            and context.cardarea == G.play
            and target
            and target:is_suit("Diamonds")
            and not context.blueprint
        then
            canlaugh_dark_pentacle_transmute(target, G.P_CENTERS.m_lucky, "Lucky!", G.C.GREEN)
        end

        if context.individual
            and context.cardarea == G.hand
            and target
            and target:is_suit("Diamonds")
            and not context.blueprint
        then
            canlaugh_dark_pentacle_transmute(target, G.P_CENTERS.m_gold, "Gold!", G.C.MONEY)
        end
    end,
})
