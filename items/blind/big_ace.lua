local CL = CannedLaughter
SMODS.Atlas({
    key = "big_ace",
    path = "blind_ace.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

CL.register_alternate_big_blind({
    key = "ace",
    atlas = "big_ace",
    boss_colour = HEX("4BC292"),
    loc_txt = {
        name = "The Ace",
        text = {
            "After scoring, #1# in #2# chance",
            "to debuff a random card",
        },
    },
    loc_vars = function(self)
        local numerator, denominator = SMODS.get_probability_vars(self, 1, 6, "canlaugh_big_ace")

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
        local seed = "canlaugh_big_ace_" .. tostring(hands_played)

        if not CL.big_blind_roll(self, seed, "canlaugh_big_ace") then
            return
        end

        local card = CL.big_blind_random(G.playing_cards or {}, seed .. "_card")

        if not card then
            return
        end

        card.ability.canlaugh_big_ace_debuff = true
        card:set_debuff(true)
    end,
    recalc_debuff = function(self, card)
        return card
            and card.playing_card
            and card.ability
            and card.ability.canlaugh_big_ace_debuff
    end,
    disable = function(self)
        for _, card in ipairs(G and G.playing_cards or {}) do
            if card.ability then
                card.ability.canlaugh_big_ace_debuff = nil
                card:set_debuff(false)
            end
        end
    end,
    defeat = function(self)
        self:disable()
    end,
})
