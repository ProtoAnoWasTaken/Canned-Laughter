local CL = CannedLaughter

SMODS.Atlas({
    key = "boss_line",
    path = "blind_line.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

local function line_hand_cards()
    local cards = {}

    for _, card in ipairs(G and G.hand and G.hand.cards or {}) do
        cards[#cards + 1] = card
    end

    return cards
end

local function line_reshuffle_hand()
    local cards = line_hand_cards()

    if #cards == 0 or not (G and G.hand and G.discard and G.deck and G.FUNCS) then
        return
    end

    local highlighted_limit = G.hand.config.highlighted_limit
    local discard_limit = G.discard.config.card_limit

    G.hand.config.highlighted_limit = #cards
    G.discard.config.card_limit = #cards + #(G.play and G.play.cards or {})
    G.hand:unhighlight_all()

    for _, card in ipairs(cards) do
        G.hand:add_to_highlighted(card, true)
    end

    G.FUNCS.discard_cards_from_highlighted(nil, true)
    G.hand.config.highlighted_limit = highlighted_limit
    G.discard.config.card_limit = discard_limit

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.2,
        func = function()
            local reshuffled = {}

            for _, card in ipairs(cards) do
                if card and not card.destroyed and not card.removed and card.area == G.discard then
                    reshuffled[#reshuffled + 1] = card
                end
            end

            for _, card in ipairs(reshuffled) do
                G.discard:remove_card(card)
                G.deck:emplace(card)
            end

            if #reshuffled > 0 then
                G.deck:shuffle("canlaugh_line_" .. tostring(G.GAME.current_round.hands_played))
                G.FUNCS.draw_from_deck_to_hand()
            end

            return true
        end,
    }))
end

CL.register_standard_boss({
    key = "line",
    atlas = "boss_line",
    boss_colour = HEX("509AA0"),
    mult = 2,
    loc_txt = {
        name = "The Line",
        text = {
            "Unplayed cards are",
            "discarded, reshuffled,",
            "then redrawn",
        },
    },
    calculate = function(self, blind, context)
        if context and context.after and context.scoring_hand then
            line_reshuffle_hand()
        end
    end,
})
