SMODS.Atlas({
    key = "alchemist",
    path = "alchemist.png",
    px = 69,
    py = 93,
})

local function canlaugh_transmute_to_gold(playing_card)
    if not (playing_card and G and G.P_CENTERS and G.P_CENTERS.m_gold) then
        return
    end

    if type(playing_card.set_ability) == "function" then
        playing_card:set_ability(G.P_CENTERS.m_gold, nil, true)
    end
end

SMODS.Joker({
    key = "alchemist",
    name = "Alchemist",
    atlas = "alchemist",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    loc_txt = {
        name = "Alchemist",
        text = {
            "{C:attention,T:m_steel}Steel Cards{} are transmuted",
            "into {C:gold,T:m_gold}Gold Cards{} after triggering",
        },
    },
    loc_vars = function(self, info_queue, card)
        CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS.m_steel, card)
        CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS.m_gold, card)
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual
            and context.cardarea == G.hand
            and context.other_card
            and SMODS.has_enhancement(context.other_card, "m_steel")
            and not context.blueprint
        then
            local target = context.other_card

            canlaugh_transmute_to_gold(target)
            G.E_MANAGER:add_event(Event({
                func = function()
                    target:juice_up()
                    return true
                end,
            }))

            return {
                message = "Gold!",
                colour = G.C.MONEY,
                card = card,
            }
        end
    end,
})
