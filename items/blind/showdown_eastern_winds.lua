local CL = CannedLaughter

SMODS.Atlas({
    key = "showdown_eastern_winds",
    path = "showdown_eastern_winds.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

if G
    and G.FUNCS
    and type(G.FUNCS.play_cards_from_highlighted) == "function"
    and type(G.FUNCS.discard_cards_from_highlighted) == "function"
    and not CL.eastern_winds_action_hook_installed
then
    CL.eastern_winds_action_hook_installed = true
    local play_cards_from_highlighted_ref = G.FUNCS.play_cards_from_highlighted
    local discard_cards_from_highlighted_ref = G.FUNCS.discard_cards_from_highlighted

    function G.FUNCS.play_cards_from_highlighted(e)
        if CL.boss_active("bl_canlaugh_eastern_winds") then
            return discard_cards_from_highlighted_ref(e)
        end

        return play_cards_from_highlighted_ref(e)
    end

    function G.FUNCS.discard_cards_from_highlighted(e, hook)
        if CL.boss_active("bl_canlaugh_eastern_winds") and not hook then
            return play_cards_from_highlighted_ref(e)
        end

        return discard_cards_from_highlighted_ref(e, hook)
    end
end

CL.register_showdown_boss({
    key = "eastern_winds",
    atlas = "showdown_eastern_winds",
    boss_colour = HEX("F3B958"),
    mult = 2,
    loc_txt = {
        name = "Eastern Winds",
        text = {
            "Discards play,",
            "plays discard",
        },
    },
})
