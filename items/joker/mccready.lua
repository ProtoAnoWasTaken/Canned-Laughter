SMODS.Atlas({
    key = "mccready_back",
    path = "mccready_back.png",
    px = 69,
    py = 93,
})

SMODS.Atlas({
    key = "mccready_front",
    path = "mccready_front.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "mccready",
    name = "McCready",
    atlas = "mccready_back",
    soul_atlas = "mccready_front",
    pos = { x = 0, y = 0 },
    soul_pos = { x = 0, y = 0 },
    rarity = 4,
    cost = 20,
    unlocked = false,
    unlock_condition = {
        type = "",
        extra = "",
        hidden = true,
    },
    config = {
        extra = {
            x_mult_per_slot = 4,
        },
    },
    loc_txt = {
        name = "McCready",
        text = {
            "{X:mult,C:white}X#1#{} Mult for each",
            "occupied {C:attention}Joker{} slot",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult){}",
        },
        unlock = {
            "{C:inactive,s:1.3}??????{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        local occupied = G and G.jokers and G.jokers.cards and #G.jokers.cards or 0

        return {
            vars = {
                extra.x_mult_per_slot,
                math.max(1, occupied * extra.x_mult_per_slot),
            },
        }
    end,
    locked_loc_vars = function(self, info_queue, card)
        if not (G and G.P_CENTERS and G.P_CENTERS.c_soul and G.P_CENTERS.c_soul.discovered) then
            return {
                not_hidden = true,
                vars = {},
            }
        end

        return {
            key = "joker_locked_legendary",
            set = "Other",
            vars = {},
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local occupied = G and G.jokers and G.jokers.cards and #G.jokers.cards or 0

            return {
                x_mult = math.max(1, occupied * card.ability.extra.x_mult_per_slot),
            }
        end
    end,
})
