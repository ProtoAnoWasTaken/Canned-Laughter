SMODS.Atlas({
    key = "power_armor",
    path = "power_armor.png",
    px = 69,
    py = 93,
})

local function canlaugh_destroy_power_armor_steel(target)
    if not (
        target
        and not target.removed
        and not target.REMOVED
        and not target.destroyed
        and SMODS
        and type(SMODS.destroy_cards) == "function"
    ) then
        return
    end

    SMODS.destroy_cards(target, nil, true)
end

local function canlaugh_queue_power_armor_destruction(target)
    target.canlaugh_power_armor_destroyed = true

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.4,
        func = function()
            canlaugh_destroy_power_armor_steel(target)
            return true
        end,
    }))
end

SMODS.Joker({
    key = "power_armor",
    name = "Power Armor",
    atlas = "power_armor",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = {
        extra = {
            x_mult = 1,
            x_mult_gain = 0.25,
        },
    },
    loc_txt = {
        name = "Power Armor",
        text = {
            "{C:attention,T:m_steel}Steel Cards{} are {C:red}destroyed{}",
            "after triggering",
            "Gain {X:mult,C:white}X#2#{} Mult for every",
            "{C:attention,T:m_steel}Steel Card{} destroyed this way",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult){}",
        },
        unlock = {
            "Reach Ante {C:attention}8{} from",
            "{C:attention}The Journey{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS.m_steel, card)
        return { vars = { extra.x_mult, extra.x_mult_gain } }
    end,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_power_armor"
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.joker_main then
            return { x_mult = extra.x_mult }
        end

        if context.individual
            and context.cardarea == G.hand
            and context.other_card
            and not context.other_card.canlaugh_power_armor_destroyed
            and SMODS.has_enhancement(context.other_card, "m_steel")
            and not context.blueprint
        then
            extra.x_mult = extra.x_mult + extra.x_mult_gain
            canlaugh_queue_power_armor_destruction(context.other_card)
            card:juice_up(0.3, 0.5)
            return {
                message = "Powered!",
                colour = G.C.MULT,
                card = card,
            }
        end
    end,
})
