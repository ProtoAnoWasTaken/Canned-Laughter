local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({ key = "etiology", path = "etiology.png", px = 71, py = 95 })

SMODS.Tarot({
    key = "etiology",
    atlas = "etiology",
    pos = { x = 0, y = 0 },
    cost = 3,
    weight = 10,
    config = { max_highlighted = 2 },
    loc_txt = { name = "Etiology", text = { "Enhances {C:attention}2{} selected cards", "into {C:mult}Concrete Cards{}" } },
    loc_vars = function(self, info_queue, card)
        local concrete = G and G.P_CENTERS and G.P_CENTERS.m_canlaugh_concrete

        if concrete then
            CL.add_unique_tooltip(info_queue, concrete, card)
        end

        return {
            vars = {},
        }
    end,
    can_use = function() return CL.consumables.selected_hand_cards(2, 2) ~= nil end,
    use = function(self, card, area, copier)
        local targets = CL.consumables.selected_hand_cards(2, 2)
        if not targets then return end
        CL.tarot.juice_used_consumable(copier or card)
        for _, target in ipairs(targets) do
            CL.consumables.tarot_flip(target, function()
                target:set_ability(G.P_CENTERS.m_canlaugh_concrete, nil, false)
            end)
        end
        CL.tarot.unhighlight_hand(0.5)
        delay(0.3)
    end,
})
