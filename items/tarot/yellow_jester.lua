local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({
    key = "yellow_jester",
    path = "yellowjester.png",
    px = 71,
    py = 95,
})

SMODS.Tarot({
    key = "yellow_jester",
    atlas = "yellow_jester",
    pos = { x = 0, y = 0 },
    cost = 3,
    weight = 5,
    in_pool = CL.tarot.pack_only_in_pool,
    loc_txt = {
        name = "The Yellow Jester",
        text = {
            "Earn {C:money}$1{} for every {C:attention}2{}",
            "{C:clubs}Clubs{} or {C:diamonds}Diamonds{}",
            "card in your deck",
            "{C:inactive}(Currently {C:money}$#1#{C:inactive}){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                math.floor(CL.tarot.count_deck_suits({ Clubs = true, Diamonds = true }) / 2),
            },
        }
    end,
    can_use = function(self, card)
        return true
    end,
    use = function(self, card, area, copier)
        local used_tarot = copier or card
        local dollars = math.floor(CL.tarot.count_deck_suits({ Clubs = true, Diamonds = true }) / 2)

        CL.tarot.juice_used_consumable(used_tarot)
        ease_dollars(dollars)
        delay(0.3)
    end,
})
