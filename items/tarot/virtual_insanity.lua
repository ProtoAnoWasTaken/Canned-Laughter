local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({ key = "virtual_insanity", path = "virtual_insanity.png", px = 71, py = 95 })

SMODS.Tarot({
    key = "virtual_insanity",
    atlas = "virtual_insanity",
    pos = { x = 0, y = 0 },
    cost = 3,
    weight = 5,
    in_pool = CL.tarot.pack_only_in_pool,
    loc_txt = { name = "Virtual Insanity", text = { "Create a random", "{C:tarot}Colored Tarot{}", "{C:inactive}(Must have room){}" } },
    can_use = function(self, card)
        return CL.tarot.has_consumable_room(1, card) and CL.colored_tarot.random_center("canlaugh_virtual_insanity_check") ~= nil
    end,
    use = function(self, card, area, copier)
        local center = CL.colored_tarot.random_center("canlaugh_virtual_insanity")
        if not center then return end
        CL.tarot.juice_used_consumable(copier or card)
        CL.tarot.with_consumable_room(1, function()
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.2,
                func = function()
                    local created = create_card(center.set, G.consumeables, nil, nil, nil, nil, center.key, "canlaugh_virtual_insanity")
                    if created then
                        created:add_to_deck()
                        G.consumeables:emplace(created)
                    end
                    G.GAME.consumeable_buffer = math.max(0, G.GAME.consumeable_buffer - 1)
                    return true
                end,
            }))
        end)
        delay(0.3)
    end,
})
