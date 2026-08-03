local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({ key = "use_the_force", path = "use_the_force.png", px = 71, py = 95 })

local function selected_pair()
    local hand = G.hand and G.hand.highlighted or {}
    local jokers = G.jokers and G.jokers.highlighted or {}
    if #hand == 2 and #jokers == 0 then return CL.consumables.sort_left_to_right(hand) end
    if #jokers == 2 and #hand == 0 then return CL.consumables.sort_left_to_right(jokers) end
end

SMODS.Tarot({
    key = "use_the_force",
    atlas = "use_the_force",
    pos = { x = 0, y = 0 },
    cost = 3,
    weight = 5,
    config = { max_highlighted = 2 },
    in_pool = CL.tarot.pack_only_in_pool,
    loc_txt = {
        name = "Use the Force",
        text = {
            "Select {C:attention}2{} cards, transfer the",
            "{C:dark_edition}edition{} of the left card",
            "to the right card",
            "{C:inactive}(Drag to rearrange){}",
        },
    },
    can_use = function()
        local cards = selected_pair()
        return cards and cards[1].edition and not CL.is_frozen(cards[1]) and not CL.is_frozen(cards[2])
    end,
    use = function(self, card, area, copier)
        local cards = selected_pair()
        if not cards or not cards[1].edition or CL.is_frozen(cards[1]) or CL.is_frozen(cards[2]) then return end
        local edition = copy_table(cards[1].edition)
        CL.tarot.juice_used_consumable(copier or card)
        CL.consumables.tarot_flip(cards[1], function() cards[1]:set_edition(nil, true, true) end)
        CL.consumables.tarot_flip(cards[2], function() cards[2]:set_edition(edition, true, true) end)
        CL.tarot.unhighlight_hand(0.5)
        delay(0.3)
    end,
})
