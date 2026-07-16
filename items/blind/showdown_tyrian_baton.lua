local CL = CannedLaughter
SMODS.Atlas({ key = "showdown_tyrian_baton", path = "showdown_tyrianbaton.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_showdown_boss({
    key = "tyrian_baton",
    atlas = "showdown_tyrian_baton",
    boss_colour = HEX("FD00B1"),
    mult = 3,
    loc_txt = {
        name = "Tyrian Baton",
        text = {
            "Playing or discarding uses every card",
            "All cards score",
        },
    },
})
