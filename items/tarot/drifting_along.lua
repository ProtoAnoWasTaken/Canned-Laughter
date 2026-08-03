local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({ key = "drifting_along", path = "drifting_along.png", px = 71, py = 95 })

SMODS.Tarot({
    key = "drifting_along",
    atlas = "drifting_along",
    pos = { x = 0, y = 0 },
    cost = 3,
    weight = 5,
    config = { max_highlighted = 3 },
    in_pool = CL.tarot.pack_only_in_pool,
    loc_txt = {
        name = "Drifting Along",
        text = {
            "Balance the {C:attention}ranks{} of up to",
            "{C:attention}3{} selected cards",
            "{C:inactive}(Drag to rearrange){}",
        },
    },
    can_use = function() return CL.consumables.selected_hand_cards(1, 3) ~= nil end,
    use = function(self, card, area, copier)
        local cards = CL.consumables.sort_left_to_right(CL.consumables.selected_hand_cards(1, 3))
        if not cards then return end
        local total = 0
        for _, target in ipairs(cards) do total = total + target.base.id end
        local low = math.floor(total / #cards)
        local remainder = total - low * #cards
        CL.tarot.juice_used_consumable(copier or card)
        for index, target in ipairs(cards) do
            local rank = CL.consumables.rank_center(low + (index > #cards - remainder and 1 or 0))
            if rank then CL.consumables.tarot_flip(target, function() SMODS.change_base(target, nil, rank.key) end) end
        end
        CL.tarot.unhighlight_hand(0.6)
        delay(0.3)
    end,
})
