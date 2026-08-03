local CL = CannedLaughter
SMODS.Atlas({
    key = "big_trey",
    path = "blind_trey.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

CL.register_alternate_big_blind({
    key = "trey",
    atlas = "big_trey",
    boss_colour = HEX("4BC292"),
    loc_txt = {
        name = "The Trey",
        text = {
            "After scoring, #1# in #2# chance",
            "to debuff that poker hand",
        },
    },
    loc_vars = function(self)
        local numerator, denominator = SMODS.get_probability_vars(self, 1, 6, "canlaugh_big_trey")

        return {
            vars = {
                numerator,
                denominator,
            },
        }
    end,
    calculate = function(self, blind, context)
        if not (context and context.after and context.scoring_name) then
            return
        end

        local round = G and G.GAME and G.GAME.current_round
        local hands_played = round and round.hands_played or 0

        if not CL.big_blind_roll(
            self,
            "canlaugh_big_trey_" .. tostring(hands_played),
            "canlaugh_big_trey"
        ) then
            return
        end

        blind.canlaugh_big_trey_hands = blind.canlaugh_big_trey_hands or {}
        blind.canlaugh_big_trey_hands[context.scoring_name] = true
    end,
    debuff_hand = function(self, cards, hand, handname)
        local hands = G
            and G.GAME
            and G.GAME.blind
            and G.GAME.blind.canlaugh_big_trey_hands
        local triggered = hands and hands[handname]

        if G and G.GAME and G.GAME.blind then
            G.GAME.blind.triggered = triggered or false
        end

        return triggered
    end,
})
