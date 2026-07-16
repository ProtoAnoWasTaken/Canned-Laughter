local CL = CannedLaughter
SMODS.Atlas({ key = "showdown_cinnabar_saber", path = "showdown_cinnabarsaber.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_showdown_boss({
    key = "cinnabar_saber",
    atlas = "showdown_cinnabar_saber",
    boss_colour = HEX("FD3F00"),
    mult = 3,
    loc_txt = { name = "Cinnabar Saber", text = { "Hands and Discards", "share resources" } },
    set_blind = function(self)
        local round = G and G.GAME and G.GAME.current_round
        if not round then return end

        local total = round.hands_left + round.discards_left
        CL.saber_syncing = true
        ease_hands_played(total - round.hands_left)
        ease_discard(total - round.discards_left)
        CL.saber_syncing = nil
    end,
})
