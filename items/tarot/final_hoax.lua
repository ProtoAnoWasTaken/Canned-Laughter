local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({
    key = "final_hoax",
    path = "finalhoax.png",
    px = 71,
    py = 95,
})

SMODS.Tarot({
    key = "final_hoax",
    atlas = "final_hoax",
    pos = { x = 0, y = 0 },
    cost = 3,
    weight = 5,
    in_pool = CL.tarot.pack_only_in_pool,
    loc_txt = {
        name = "The Final Hoax",
        text = {
            "Earn {C:money}$2{} for each card",
            "with {C:attention}more or less{}",
            "than {C:attention}1{} suit",
            "{C:inactive}(Currently {C:money}$#1#{C:inactive}, ignores Smeared Joker){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                2 * CL.tarot.count_irregular_suits(),
            },
        }
    end,
    can_use = function(self, card)
        return true
    end,
    use = function(self, card, area, copier)
        local used_tarot = copier or card
        local dollars = 2 * CL.tarot.count_irregular_suits()

        CL.tarot.juice_used_consumable(used_tarot)
        ease_dollars(dollars)
        delay(0.3)
    end,
})
