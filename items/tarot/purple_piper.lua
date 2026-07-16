local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({
    key = "purple_piper",
    path = "piper.png",
    px = 71,
    py = 95,
})

SMODS.Tarot({
    key = "purple_piper",
    atlas = "purple_piper",
    pos = { x = 0, y = 0 },
    cost = 3,
    weight = 5,
    in_pool = CL.tarot.pack_only_in_pool,
    loc_txt = {
        name = "The Purple Piper",
        text = {
            "Create a {C:planet}Planet{} card",
            "of your most played {C:attention}poker hand{}",
            "{C:inactive}(Must have room){}",
        },
    },
    can_use = function(self, card)
        return CL.tarot
            and CL.tarot.has_consumable_room(1, card)
            and CL.tarot.planet_for_hand(CL.tarot.most_played_hand())
    end,
    use = function(self, card, area, copier)
        local used_tarot = copier or card
        local hand_key = CL.tarot.most_played_hand()
        local planet_key = CL.tarot.planet_for_hand(hand_key)

        if not planet_key then
            return
        end

        CL.tarot.juice_used_consumable(used_tarot)
        CL.tarot.with_consumable_room(1, function()
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1

            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.2,
                func = function()
                    local planet = create_card("Planet", G.consumeables, nil, nil, nil, nil, planet_key, "canlaugh_piper")
                    planet:add_to_deck()
                    G.consumeables:emplace(planet)
                    G.GAME.consumeable_buffer = math.max(0, G.GAME.consumeable_buffer - 1)
                    return true
                end,
            }))
        end)

        delay(0.3)
    end,
})
