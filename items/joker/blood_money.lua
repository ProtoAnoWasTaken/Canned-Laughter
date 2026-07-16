SMODS.Atlas({
    key = "blood_money",
    path = "blood_money.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "blood_money",
    name = "Blood Money",
    atlas = "blood_money",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 9,
    unlocked = false,
    config = { extra = { dollars = 25, reduction = 50, unlock = 800 } },
    loc_txt = {
        name = "Blood Money",
        text = {
            "{C:attention}Boss Blinds{} require",
            "up to {C:attention}#2#%{} less score",
            "scaling every {C:money}$#1#{}",
            "{C:inactive}(diminishing){}",
        },
        unlock = {
            "Have at least {C:money}$#1#{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return { vars = { extra.dollars, extra.reduction, extra.unlock } }
    end,
    check_for_unlock = function(self, args)
        return args and args.type == "money" and (args.money or args.amount or G.GAME.dollars or 0) >= self.config.extra.unlock
    end,
    locked_loc_vars = function(self, info_queue, card)
        return { vars = { self.config.extra.unlock } }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind and context.blind and context.blind.boss and not context.blueprint then
            local mult, steps, discount = CannedLaughter.playing_card_jokers.blood_money_multiplier()
            if type(check_for_unlock) == "function" then
                if CannedLaughter.rules_card_active and CannedLaughter.rules_card_active() and steps >= 19 then
                    check_for_unlock({ type = "canlaugh_zenoan" })
                elseif steps >= 10 then
                    check_for_unlock({ type = "canlaugh_atalantean" })
                end
            end
            if steps > 0 then
                return {
                    x_blind_size = mult,
                    message = "-" .. tostring(math.floor(discount + 0.5)) .. "%",
                    colour = G.C.MONEY,
                }
            end
        end
    end,
})
