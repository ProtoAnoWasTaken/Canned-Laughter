local CL = CannedLaughter
SMODS.Atlas({ key = "boss_oracle", path = "blind_oracle.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "oracle",
    atlas = "boss_oracle",
    art = "oracle",
    boss_colour = HEX("2BE7AE"),
    mult = 2,
    loc_txt = { name = "The Oracle", text = { "All hands are considered", "the first this Ante" } },
    press_play = function(self)
        if G and G.GAME and G.GAME.current_round then G.GAME.current_round.hands_played = 0 end
    end,
})
