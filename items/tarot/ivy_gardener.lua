local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({
    key = "ivy_gardener",
    path = "gardener.png",
    px = 71,
    py = 95,
})

SMODS.Tarot({
    key = "ivy_gardener",
    atlas = "ivy_gardener",
    pos = { x = 0, y = 0 },
    cost = 3,
    weight = 5,
    in_pool = CL.tarot.pack_only_in_pool,
    config = {
        max_highlighted = 1,
    },
    loc_txt = {
        name = "The Ivy Gardener",
        text = {
            "Increases the rank of",
            "{C:attention}1{} selected card",
            "by {C:attention}2{}",
        },
    },
    can_use = function(self, card)
        return CL.tarot.selected_hand_card() ~= nil
    end,
    use = function(self, card, area, copier)
        local used_tarot = copier or card
        local target = CL.tarot.selected_hand_card()

        if not target then
            return
        end

        CL.tarot.juice_used_consumable(used_tarot)

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.15,
            func = function()
                target:flip()
                play_sound("card1", 1)
                target:juice_up(0.3, 0.3)
                return true
            end,
        }))

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.2,
            func = function()
                SMODS.modify_rank(target, 2)
                return true
            end,
        }))

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.15,
            func = function()
                target:flip()
                play_sound("tarot2", 1, 0.6)
                target:juice_up(0.3, 0.3)
                return true
            end,
        }))

        CL.tarot.unhighlight_hand(0.25)
        delay(0.3)
    end,
})
