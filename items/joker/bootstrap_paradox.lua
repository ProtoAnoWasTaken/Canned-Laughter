SMODS.Atlas({
    key = "bootstrap_paradox",
    path = "bootstrap_paradox.png",
    px = 69,
    py = 93,
})

local function canlaugh_bootstraps_unlocked()
    return G
        and G.P_CENTERS
        and G.P_CENTERS.j_bootstraps
        and G.P_CENTERS.j_bootstraps.unlocked
end

SMODS.Joker({
    key = "bootstrap_paradox",
    name = "Bootstrap Paradox",
    atlas = "bootstrap_paradox",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = {
        extra = {
            mult = 0,
            mult_gain = 2,
            dollars = 5,
        },
    },
    loc_txt = {
        name = "Bootstrap Paradox",
        text = {
            "Gains {C:mult}+#1#{} Mult every time",
            "you receive {C:money}$#2#{} this run",
            "{C:inactive}(Currently {C:mult}+#3#{C:inactive} Mult){}",
        },
        unlock = {
            "Purchase a {C:dark_edition}Polychrome{} Joker",
            "from a previous {C:attention}Ante{}",
            "{C:inactive}(Requires {C:attention}Bootstraps{C:inactive}){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra

        return {
            vars = {
                extra.mult_gain,
                extra.dollars,
                extra.mult,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args
            and args.type == "canlaugh_bootstrap_paradox_purchase"
            and canlaugh_bootstraps_unlocked()
    end,
    locked_loc_vars = function(self, info_queue, card)
        if G and G.P_CENTERS and G.P_CENTERS.j_bootstraps then
            CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS.j_bootstraps, card)
        end

        if G and G.P_CENTERS and G.P_CENTERS.e_polychrome then
            CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS.e_polychrome, card)
        end

        return { vars = {} }
    end,
    calculate = function(self, card, context)
        if context.joker_main and card.ability.extra.mult > 0 then
            return {
                mult = card.ability.extra.mult,
            }
        end
    end,
})
