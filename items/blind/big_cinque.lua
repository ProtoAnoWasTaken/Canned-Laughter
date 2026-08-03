local CL = CannedLaughter
SMODS.Atlas({
    key = "big_cinque",
    path = "blind_cinque.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

CL.register_alternate_big_blind({
    key = "cinque",
    atlas = "big_cinque",
    boss_colour = HEX("4BC292"),
    loc_txt = {
        name = "The Cinque",
        text = {
            "#1# in #2# chance for played",
            "hands to be debuffed",
        },
    },
    loc_vars = function(self)
        local numerator, denominator = SMODS.get_probability_vars(self, 1, 6, "canlaugh_big_cinque")

        return {
            vars = {
                numerator,
                denominator,
            },
        }
    end,
    debuff_hand = function(self, cards, hand, handname)
        local round = G and G.GAME and G.GAME.current_round
        local hands_played = round and round.hands_played or 0
        local blind = G and G.GAME and G.GAME.blind
        local hand_key = tostring(hands_played) .. ":" .. tostring(handname)

        if blind and blind.canlaugh_big_cinque_hand_key ~= hand_key then
            blind.canlaugh_big_cinque_hand_key = hand_key
            blind.canlaugh_big_cinque_triggered = CL.big_blind_roll(
                self,
                "canlaugh_big_cinque_" .. hand_key,
                "canlaugh_big_cinque"
            )
        end

        local triggered = blind and blind.canlaugh_big_cinque_triggered or false

        if blind then
            blind.triggered = triggered
        end

        return triggered
    end,
})
