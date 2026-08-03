local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_brick_joke_first_hand()
    local round = G and G.GAME and G.GAME.current_round
    return round and (round.hands_played or 0) == 0
end

local function canlaugh_brick_joke_played_concrete(context)
    local count = 0

    for _, playing_card in ipairs(context.full_hand or {}) do
        if SMODS.has_enhancement(playing_card, "m_canlaugh_concrete") then
            count = count + 1
        end
    end

    return count
end

if CL.barter then
    CL.barter.register_rep_modifier("brick_joke", function(phase, context)
        if phase == "availability" and context.booster_kind == "Arcana" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_brick_joke") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Arcana" then
            local center = G.P_CENTERS and G.P_CENTERS.c_tower
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_brick_joke") or {}) do
                local rep = center and CL.barter.collection_representative(center, "Arcana")
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end

SMODS.Atlas({
    key = "brick_joke",
    path = "brick_joke.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "brick_joke",
    name = "Brick Joke",
    atlas = "brick_joke",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            chips = 0,
            chips_per_card = 25,
        },
    },
    loc_txt = {
        name = "Brick Joke",
        text = {
            "Gives {C:chips}+#2#{} Chips for each",
            "{C:attention,T:m_canlaugh_concrete}Cement Card{} played this round",
            "{C:inactive}(Does not count first hand){}",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        CL.add_unique_tooltip(info_queue, G.P_CENTERS.m_canlaugh_concrete, card)
        return { vars = { extra.chips, extra.chips_per_card } }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.setting_blind and not context.blueprint then
            extra.chips = 0
        end

        if context.before
            and not context.blueprint
            and not context.retrigger_joker
            and not canlaugh_brick_joke_first_hand()
        then
            extra.chips = extra.chips + canlaugh_brick_joke_played_concrete(context) * extra.chips_per_card
        end

        if context.joker_main and extra.chips > 0 then
            return { chips = extra.chips }
        end
    end,
})
