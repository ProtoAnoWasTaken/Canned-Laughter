local CL = CannedLaughter
SMODS.Atlas({ key = "boss_flare", path = "blind_flare.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "flare",
    atlas = "boss_flare",
    art = "flare",
    boss_colour = HEX("D94A36"),
    mult = 2,
    loc_txt = { name = "The Flare", text = { "Hands are capped at", "80% of the goal" } },
})

if SMODS.calculate_round_score and not CL.flare_score_hook_installed then
    CL.flare_score_hook_installed = true
    local calculate_round_score = SMODS.calculate_round_score

    function SMODS.calculate_round_score(flames)
        local score = calculate_round_score(flames)
        local cap = CL.boss_active("bl_canlaugh_flare") and G.GAME.blind.chips * 0.8

        if cap and score > cap then return cap end
        return score
    end
end
