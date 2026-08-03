local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({ key = "spend_a_lifetime", path = "spend_a_lifetime.png", px = 71, py = 95 })

SMODS.Tarot({
    key = "spend_a_lifetime",
    atlas = "spend_a_lifetime",
    pos = { x = 0, y = 0 },
    cost = 3,
    weight = 5,
    config = { max_highlighted = 1 },
    in_pool = CL.tarot.pack_only_in_pool,
    loc_txt = { name = "Spend a Lifetime", text = { "Enhances {C:attention}1{} selected card", "into a {C:mult}Blazing Card{}" } },
    loc_vars = function(self, info_queue, card)
        local blazing = G and G.P_CENTERS and G.P_CENTERS.m_canlaugh_blazing

        if blazing then
            CL.add_unique_tooltip(info_queue, blazing, card)
        end

        return {
            vars = {},
        }
    end,
    can_use = function() return CL.tarot.selected_hand_card() ~= nil end,
    use = function(self, card, area, copier)
        local target = CL.tarot.selected_hand_card()
        if not target then return end
        CL.tarot.juice_used_consumable(copier or card)
        CL.consumables.tarot_flip(target, function()
            target:set_ability(G.P_CENTERS.m_canlaugh_blazing, nil, false)
        end)
        CL.tarot.unhighlight_hand(0.5)
        delay(0.3)
    end,
})
