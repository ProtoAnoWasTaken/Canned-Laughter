SMODS.Atlas({
    key = "citadel",
    path = "citadel.png",
    px = 69,
    py = 93,
})

local function canlaugh_citadel_sold_tarot(sold_card)
    local center = sold_card and sold_card.config and sold_card.config.center
    return center and center.set == "Tarot"
end

SMODS.Joker({
    key = "citadel",
    name = "Citadel",
    atlas = "citadel",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            mult = 0,
            mult_gain = 4,
        },
    },
    loc_txt = {
        name = "Citadel",
        text = {
            "Gains {C:mult}+#1#{} Mult per",
            "{C:tarot}Tarot{} card sold",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.mult_gain,
                extra.mult,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.joker_main and extra.mult > 0 then
            return {
                mult = extra.mult,
            }
        end

        if context.selling_card
            and not context.blueprint
            and not context.retrigger_joker
            and canlaugh_citadel_sold_tarot(context.card)
        then
            extra.mult = extra.mult + extra.mult_gain
            card:juice_up(0.3, 0.5)
            return {
                message = "+" .. tostring(extra.mult_gain) .. " Mult",
                colour = G.C.MULT,
            }
        end
    end,
})
