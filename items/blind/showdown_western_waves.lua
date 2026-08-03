local CL = CannedLaughter

SMODS.Atlas({
    key = "showdown_western_waves",
    path = "showdown_western_waves.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

local function rank_id(card)
    if not card or not card.base then
        return 0
    end

    return card.base.id or 0
end

local function select_all_hand_cards()
    G.hand:unhighlight_all()

    for _, card in ipairs(G.hand.cards or {}) do
        G.hand:add_to_highlighted(card, true)
    end
end

if G
    and G.FUNCS
    and type(G.FUNCS.discard_cards_from_highlighted) == "function"
    and not CL.western_waves_discard_hook_installed
then
    CL.western_waves_discard_hook_installed = true
    local discard_cards_from_highlighted_ref = G.FUNCS.discard_cards_from_highlighted

    function G.FUNCS.discard_cards_from_highlighted(e, hook)
        if not CL.boss_active("bl_canlaugh_western_waves") then
            return discard_cards_from_highlighted_ref(e, hook)
        end

        local highlighted_limit = G.hand.config.highlighted_limit
        local discard_limit = G.discard.config.card_limit
        G.hand.config.highlighted_limit = #G.hand.cards
        G.discard.config.card_limit = #G.hand.cards + #(G.play.cards or {})
        select_all_hand_cards()
        local results = { pcall(discard_cards_from_highlighted_ref, e, hook) }
        G.hand.config.highlighted_limit = highlighted_limit
        G.discard.config.card_limit = discard_limit

        if not results[1] then
            error(results[2])
        end

        return unpack(results, 2)
    end
end

if G
    and G.FUNCS
    and type(G.FUNCS.draw_from_deck_to_hand) == "function"
    and not CL.western_waves_draw_hook_installed
then
    CL.western_waves_draw_hook_installed = true
    local draw_from_deck_to_hand_ref = G.FUNCS.draw_from_deck_to_hand

    function G.FUNCS.draw_from_deck_to_hand(e)
        if CL.boss_active("bl_canlaugh_western_waves") then
            table.sort(G.deck.cards, function(a, b)
                local a_rank = rank_id(a)
                local b_rank = rank_id(b)

                if a_rank == b_rank then
                    return (a.sort_id or 0) > (b.sort_id or 0)
                end

                return a_rank > b_rank
            end)
        end

        return draw_from_deck_to_hand_ref(e)
    end
end

CL.register_showdown_boss({
    key = "western_waves",
    atlas = "showdown_western_waves",
    boss_colour = HEX("009DFF"),
    mult = 2,
    loc_txt = {
        name = "Western Waves",
        text = {
            "All cards discard,",
            "lowest-rank cards draw first",
        },
    },
})
