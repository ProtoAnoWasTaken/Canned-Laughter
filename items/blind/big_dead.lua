local CL = CannedLaughter
SMODS.Atlas({
    key = "big_dead",
    path = "blind_dead.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

CL.register_alternate_big_blind({
    key = "dead",
    atlas = "big_dead",
    boss_colour = HEX("7A73BB"),
    loc_txt = {
        name = "The Dead",
        text = {
            "First hand's Chips",
            "do not score",
        },
    },
    modify_hand = function(self, cards, poker_hands, handname, mult, chips)
        local round = G and G.GAME and G.GAME.current_round

        if not round or round.hands_played ~= 0 then
            return mult, chips, false
        end

        return mult, 0, true
    end,
})
