local CL = CannedLaughter
SMODS.Atlas({ key = "boss_exchange", path = "blind_exchange.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "exchange",
    atlas = "boss_exchange",
    art = "exchange",
    boss_colour = HEX("176012"),
    mult = 2,
    loc_txt = { name = "The Exchange", text = { "On discard, all other cards", "are discarded instead" } },
})
