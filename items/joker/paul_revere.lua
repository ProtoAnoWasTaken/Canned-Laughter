SMODS.Atlas({
    key = "paul_revere",
    path = "paul_revere.png",
    px = 69,
    py = 93,
})

local function blind_is_active()
    return G
        and G.GAME
        and G.GAME.blind
        and G.GAME.blind.in_blind
end

SMODS.Joker({
    key = "paul_revere",
    name = "Paul Revere",
    atlas = "paul_revere",
    pos = {
        x = 0,
        y = 0,
    },
    rarity = 1,
    cost = 5,
    config = {
        extra = {
            chips = 0,
            chips_gain = 5,
        },
    },
    loc_txt = {
        name = "Paul Revere",
        text = {
            "Gains {C:chips}+#1#{} Chips whenever",
            "a consumable is used during a {C:attention}Blind{}",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips)",
        },
        unlock = {
            "Defeat {C:attention}The Horse{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra
            or self.config.extra

        return {
            vars = {
                extra.chips_gain,
                extra.chips,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = false,
    discovered = false,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_horse_defeated"
    end,
    calculate = function(self, card, context)
        if context.using_consumeable
            and blind_is_active()
            and not context.blueprint
            and not context.retrigger_joker
        then
            card.ability.extra.chips = card.ability.extra.chips
                + card.ability.extra.chips_gain

            return {
                message = "Upgrade!",
                colour = G.C.CHIPS,
            }
        end

        if context.joker_main and card.ability.extra.chips > 0 then
            return {
                chips = card.ability.extra.chips,
            }
        end
    end,
})
