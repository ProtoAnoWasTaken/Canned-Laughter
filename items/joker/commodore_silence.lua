SMODS.Atlas({
    key = "commodore_silence",
    path = "commodore_silence.png",
    px = 69,
    py = 93,
})

local mult_fields = {
    mult = true,
    mult_mod = true,
    perma_mult = true,
    x_mult = true,
    Xmult = true,
    Xmult_mod = true,
    x_mult_mod = true,
    perma_x_mult = true,
}

local function mult_field_has_effect(key, amount)
    if key == "mult" or key == "mult_mod" or key == "perma_mult" then
        return amount ~= 0
    end

    if key == "perma_x_mult" then
        return amount ~= 0
    end

    return amount ~= 1
end

local function table_provides_mult(values, seen)
    if type(values) ~= "table" then
        return false
    end

    seen = seen or {}

    if seen[values] then
        return false
    end

    seen[values] = true

    for key, value in pairs(values) do
        local amount = tonumber(value)

        if mult_fields[key] and amount and mult_field_has_effect(key, amount)
        then
            return true
        end

        if type(value) == "table" and table_provides_mult(value, seen) then
            return true
        end
    end

    return false
end

local function playing_card_provides_mult(card)
    local center = card and card.config and card.config.center
    local blazing_ranks_lost = card
        and card.ability
        and card.ability.canlaugh_blazing_ranks_lost
        or 0
    local is_blazing = SMODS
        and type(SMODS.has_enhancement) == "function"
        and SMODS.has_enhancement(card, "m_canlaugh_blazing")

    return (is_blazing and blazing_ranks_lost > 0)
        or table_provides_mult(center and center.config)
        or table_provides_mult(card and card.ability)
        or table_provides_mult(card and card.edition)
end

SMODS.Joker({
    key = "commodore_silence",
    name = "Commodore Silence",
    atlas = "commodore_silence",
    pos = {
        x = 0,
        y = 0,
    },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            mult = 0,
            mult_gain = 1,
        },
    },
    loc_txt = {
        name = "Commodore Silence",
        text = {
            "Gains {C:mult}+#1#{} Mult whenever",
            "a playing card gives {C:mult}Mult{}",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult)",
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
                extra.mult_gain,
                extra.mult,
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
        if context.individual
            and context.cardarea == G.play
            and playing_card_provides_mult(context.other_card)
            and not context.blueprint
            and not context.retrigger_joker
        then
            card.ability.extra.mult = card.ability.extra.mult
                + card.ability.extra.mult_gain

            return {
                message = "Upgrade!",
                colour = G.C.MULT,
            }
        end

        if context.joker_main and card.ability.extra.mult > 0 then
            return {
                mult = card.ability.extra.mult,
            }
        end
    end,
})
