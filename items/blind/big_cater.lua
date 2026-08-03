local CL = CannedLaughter
SMODS.Atlas({
    key = "big_cater",
    path = "blind_cater.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

local function scored_suits(cards)
    local suits = {}

    for _, card in ipairs(cards or {}) do
        local suit = card and card.base and card.base.suit

        if suit then
            suits[suit] = true
        end
    end

    return suits
end

CL.register_alternate_big_blind({
    key = "cater",
    atlas = "big_cater",
    boss_colour = HEX("4BC292"),
    loc_txt = {
        name = "The Cater",
        text = {
            "After scoring, #1# in #2# chance",
            "to debuff scored suits",
        },
    },
    loc_vars = function(self)
        local numerator, denominator = SMODS.get_probability_vars(self, 1, 6, "canlaugh_big_cater")

        return {
            vars = {
                numerator,
                denominator,
            },
        }
    end,
    calculate = function(self, blind, context)
        if not (context and context.after and context.scoring_hand) then
            return
        end

        local round = G and G.GAME and G.GAME.current_round
        local hands_played = round and round.hands_played or 0

        if not CL.big_blind_roll(
            self,
            "canlaugh_big_cater_" .. tostring(hands_played),
            "canlaugh_big_cater"
        ) then
            return
        end

        blind.canlaugh_big_cater_suits = blind.canlaugh_big_cater_suits or {}

        for suit in pairs(scored_suits(context.scoring_hand)) do
            blind.canlaugh_big_cater_suits[suit] = true
        end

        CL.refresh_big_blind_debuffs()
    end,
    recalc_debuff = function(self, card)
        local suits = G
            and G.GAME
            and G.GAME.blind
            and G.GAME.blind.canlaugh_big_cater_suits
        local suit = card and card.base and card.base.suit

        return card and card.playing_card and suit and suits and suits[suit]
    end,
})
