local CL = CannedLaughter
SMODS.Atlas({ key = "boss_justice", path = "blind_justice.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

local function justice_unselect_random_card()
    local highlighted = G and G.hand and G.hand.highlighted or {}
    if #highlighted <= 1 then
        return false
    end

    local card = CL.boss_random(highlighted, "canlaugh_justice")
    if not card then
        return false
    end

    if type(G.hand.remove_from_highlighted) == "function" then
        G.hand:remove_from_highlighted(card)
    end

    if type(card.juice_up) == "function" then
        card:juice_up(0.3, 0.3)
    end

    if type(play_sound) == "function" then
        play_sound("cardSlide1", 0.85, 0.6)
    end

    if G and G.GAME and G.GAME.blind then
        G.GAME.blind.canlaugh_justice_unselected = true
    end

    return true
end

if G and G.FUNCS and type(G.FUNCS.play_cards_from_highlighted) == "function" and not CL.justice_play_hook_installed then
    CL.justice_play_hook_installed = true
    local play_cards_from_highlighted_ref = G.FUNCS.play_cards_from_highlighted

    function G.FUNCS.play_cards_from_highlighted(e)
        if CL.boss_active("bl_canlaugh_justice") then
            justice_unselect_random_card()
        end

        return play_cards_from_highlighted_ref(e)
    end
end

CL.register_standard_boss({
    key = "justice",
    atlas = "boss_justice",
    art = "justice",
    boss_colour = HEX("DFC11A"),
    mult = 1.75,
    loc_txt = { name = "The Justice", text = { "One random card is", "unselected before Play" } },
    press_play = function(self)
        local blind = G and G.GAME and G.GAME.blind
        if blind and blind.canlaugh_justice_unselected then
            blind.canlaugh_justice_unselected = nil
            return true
        end
    end,
})
