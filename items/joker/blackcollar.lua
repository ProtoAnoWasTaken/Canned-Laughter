SMODS.Atlas({
    key = "blackcollar",
    path = "blackcollar.png",
    px = 69,
    py = 93,
})

local function canlaugh_blackcollar_target(card)
    return card and (
        SMODS.has_enhancement(card, "m_stone")
        or SMODS.has_enhancement(card, "m_canlaugh_concrete")
        or SMODS.has_enhancement(card, "m_steel")
        or SMODS.has_enhancement(card, "m_gold")
    )
end

local function canlaugh_queue_blackcollar_destruction(target)
    target.canlaugh_blackcollar_destroyed = true

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.4,
        func = function()
            if not target.removed and not target.REMOVED and not target.destroyed then
                SMODS.destroy_cards(target, nil, true)
            end
            return true
        end,
    }))
end

SMODS.Joker({
    key = "blackcollar",
    name = "Blackcollar",
    atlas = "blackcollar",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 4,
    config = {
        extra = {
            mult = 0,
            mult_gain = 4,
        },
    },
    loc_txt = {
        name = "Blackcollar",
        text = {
            "Gains {C:mult}+#2#{} Mult after {C:attention,T:m_stone}Stone{} or",
            "{C:attention,T:m_canlaugh_concrete}Concrete{}, {C:attention,T:m_steel}Steel{}, or {C:attention,T:m_gold}Gold{}",
            "cards are scored",
            "Those cards are {C:red}destroyed{} after scoring",
            "{C:inactive}(Currently {C:mult}+#1#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        for _, key in ipairs({ "m_stone", "m_canlaugh_concrete", "m_steel", "m_gold" }) do
            CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS[key], card)
        end
        return { vars = { extra.mult, extra.mult_gain } }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.joker_main and extra.mult > 0 then
            return { mult = extra.mult }
        end

        if context.individual
            and context.cardarea == G.play
            and context.other_card
            and not context.other_card.canlaugh_blackcollar_destroyed
            and canlaugh_blackcollar_target(context.other_card)
            and not context.blueprint
        then
            local target = context.other_card
            extra.mult = extra.mult + extra.mult_gain
            canlaugh_queue_blackcollar_destruction(target)
            return {
                message = "Worked!",
                colour = G.C.MULT,
                card = card,
            }
        end
    end,
})
