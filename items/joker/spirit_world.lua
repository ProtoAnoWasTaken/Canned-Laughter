SMODS.Atlas({
    key = "spirit_world",
    path = "spirit_world.png",
    px = 69,
    py = 93,
})

local function is_tarot_card(card)
    local center = card and card.config and card.config.center
    return center and center.set == "Tarot"
end

SMODS.Joker({
    key = "spirit_world",
    name = "Spirit World",
    atlas = "spirit_world",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            x_mult = 1,
            x_mult_gain = 0.1,
        },
    },
    loc_txt = {
        name = "Spirit World",
        text = {
            "Gains {X:mult,C:white}X#1#{} Mult",
            "per {C:tarot}Tarot{} card used",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.x_mult_gain,
                extra.x_mult,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.using_consumeable
            and not context.blueprint
            and is_tarot_card(context.consumeable)
        then
            card.ability.extra.x_mult = math.floor(
                (card.ability.extra.x_mult + card.ability.extra.x_mult_gain) * 10 + 0.5
            ) / 10
            return {
                message = "Upgrade!",
                colour = G.C.MULT,
            }
        end

        if context.joker_main then
            return {
                x_mult = card.ability.extra.x_mult,
            }
        end
    end,
})
