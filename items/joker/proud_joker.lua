SMODS.Atlas({
    key = "proud_joker",
    path = "proudjoker.png",
    px = 69,
    py = 93,
})

local function canlaugh_has_multiple_suits(card)
    local suit_count = 0

    for _, suit_key in ipairs(SMODS.Suit.obj_buffer or {}) do
        if card:is_suit(suit_key) then
            suit_count = suit_count + 1

            if suit_count > 1 then
                return true
            end
        end
    end

    return false
end

SMODS.Joker({
    key = "proud_joker",
    name = "Proud Joker",
    atlas = "proud_joker",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 4,
    config = {
        extra = {
            mult = 3,
        },
    },
    loc_txt = {
        name = "Proud Joker",
        text = {
            "Played cards with {C:attention}more than one suit{} give",
            "{C:mult}+#1#{} Mult when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card and card.ability and card.ability.extra and card.ability.extra.mult
                    or self.config.extra.mult,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual
            and context.cardarea == G.play
            and context.other_card
            and canlaugh_has_multiple_suits(context.other_card)
        then
            return {
                mult = card.ability.extra.mult,
            }
        end
    end,
})
