local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({ key = "traveling_without_moving", path = "traveling_without_moving.png", px = 71, py = 95 })

SMODS.Tarot({
    key = "traveling_without_moving",
    atlas = "traveling_without_moving",
    pos = { x = 0, y = 0 },
    cost = 3,
    weight = 5,
    config = { max_highlighted = 3 },
    in_pool = CL.tarot.pack_only_in_pool,
    loc_txt = {
        name = "Traveling Without Moving",
        text = {
            "Select {C:attention}3{} cards, add the {C:attention}enhancements{}",
            "and {C:attention}seal{} of the rightmost card to",
            "the two leftmost",
            "{C:inactive}(Does not copy editions){}",
            "{C:inactive}(Drag to rearrange){}",
        },
    },
    can_use = function() return CL.consumables.selected_hand_cards(3, 3) ~= nil end,
    use = function(self, card, area, copier)
        local cards = CL.consumables.sort_left_to_right(CL.consumables.selected_hand_cards(3, 3))
        if not cards then return end
        local source = cards[3]
        local enhancements = SMODS.get_enhancements(source)
        local source_seal = source.seal
        CL.tarot.juice_used_consumable(copier or card)
        for _, target in ipairs({ cards[1], cards[2] }) do
            CL.consumables.tarot_flip(target, function()
                local changed = false
                for key in pairs(enhancements) do
                    local center = G.P_CENTERS[key]
                    if center
                        and not SMODS.has_enhancement(target, key)
                        and not CL.is_frozen(target)
                    then
                        target:set_ability(center, nil, "quantum")
                        changed = true
                    end
                end

                if source_seal and target.seal ~= source_seal then
                    target:set_seal(source_seal, true)
                    changed = true
                end

                if changed then
                    target:set_sprites(source.config.center, target.config.card)
                end
            end)
        end
        CL.tarot.unhighlight_hand(0.7)
        delay(0.3)
    end,
})
