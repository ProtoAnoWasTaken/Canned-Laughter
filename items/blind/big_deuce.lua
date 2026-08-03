local CL = CannedLaughter
SMODS.Atlas({
    key = "big_deuce",
    path = "blind_deuce.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

local function scored_ranks(cards)
    local ranks = {}

    for _, card in ipairs(cards or {}) do
        local rank = card and card.get_id and card:get_id()

        if rank then
            ranks[rank] = true
        end
    end

    return ranks
end

CL.register_alternate_big_blind({
    key = "deuce",
    atlas = "big_deuce",
    boss_colour = HEX("4BC292"),
    loc_txt = {
        name = "The Deuce",
        text = {
            "After scoring, #1# in #2# chance",
            "to debuff scored ranks",
        },
    },
    loc_vars = function(self)
        local numerator, denominator = SMODS.get_probability_vars(self, 1, 6, "canlaugh_big_deuce")

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
            "canlaugh_big_deuce_" .. tostring(hands_played),
            "canlaugh_big_deuce"
        ) then
            return
        end

        blind.canlaugh_big_deuce_ranks = blind.canlaugh_big_deuce_ranks or {}

        for rank in pairs(scored_ranks(context.scoring_hand)) do
            blind.canlaugh_big_deuce_ranks[rank] = true
        end

        CL.refresh_big_blind_debuffs()
    end,
    recalc_debuff = function(self, card)
        local ranks = G
            and G.GAME
            and G.GAME.blind
            and G.GAME.blind.canlaugh_big_deuce_ranks
        local rank = card and card.get_id and card:get_id()

        return card and card.playing_card and rank and ranks and ranks[rank]
    end,
})
