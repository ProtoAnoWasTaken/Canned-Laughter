SMODS.Atlas({ key = "warlord", path = "warlord.png", px = 69, py = 93 })

local function is_first_hand()
    return G and G.GAME and G.GAME.current_round and (G.GAME.current_round.hands_played or 0) == 0
end

local function unflip_warlord_cards(card)
    local extra = card and card.ability and card.ability.extra
    for _, playing_card in ipairs(extra and extra.flipped_cards or {}) do
        if playing_card.facing == "back" then playing_card:flip() end
    end
    if extra then extra.flipped_cards = nil end
end

SMODS.Joker({
    key = "warlord",
    name = "Warlord",
    atlas = "warlord",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { flipped_cards = nil } },
    loc_txt = { name = "Warlord", text = {
        "First hand of each round is drawn {C:attention}face down{}",
        "If its first played hand has exactly {C:attention}2{} cards",
        "with different ranks, destroy the lower-rank card",
    } },
    calculate = function(self, card, context)
        if context.first_hand_drawn and context.hand_drawn and not context.blueprint then
            G.GAME.current_round.canlaugh_warlord_destroyed = nil
            card.ability.extra.flipped_cards = {}
            for _, playing_card in ipairs(context.hand_drawn) do
                if playing_card.facing == "front" then
                    playing_card:flip()
                    card.ability.extra.flipped_cards[#card.ability.extra.flipped_cards + 1] = playing_card
                end
            end
        end

        if context.after and not context.blueprint and card.ability.extra.flipped_cards then
            unflip_warlord_cards(card)
        end

        if context.selling_self and not context.blueprint then
            unflip_warlord_cards(card)
        end

        if context.final_scoring_step
            and not context.blueprint
            and is_first_hand()
            and not G.GAME.current_round.canlaugh_warlord_destroyed
            and context.full_hand
            and #context.full_hand == 2
        then
            local first, second = context.full_hand[1], context.full_hand[2]
            if first:get_id() ~= second:get_id() then
                local lower = first:get_id() < second:get_id() and first or second
                G.GAME.current_round.canlaugh_warlord_destroyed = true
                play_sound("slice1")
                if SMODS and type(SMODS.destroy_cards) == "function" then
                    SMODS.destroy_cards(lower, { immediate = true })
                elseif type(lower.start_dissolve) == "function" then
                    lower.destroyed = true
                    lower:start_dissolve()
                end
                return { message = "Sliced!", colour = G.C.RED }
            end
        end
    end,
})
