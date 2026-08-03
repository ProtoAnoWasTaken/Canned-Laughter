SMODS.Atlas({
    key = "ice_soup",
    path = "ice_soup.png",
    px = 69,
    py = 93,
})

local function canlaugh_ice_soup_discard_key()
    local game = G and G.GAME
    local round = game and game.current_round

    return table.concat({
        tostring(game and game.round or ""),
        tostring(game and game.round_resets and game.round_resets.ante or ""),
        tostring(round and round.discards_used or ""),
    }, ":")
end

SMODS.Joker({
    key = "ice_soup",
    name = "Ice Soup",
    atlas = "ice_soup",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 5,
    config = {
        extra = {
            chips = 250,
            chips_loss = 25,
            last_discard = nil,
        },
    },
    loc_txt = {
        name = "Ice Soup",
        text = {
            "{C:chips}+#1#{} Chips",
            "Lose {C:chips}-#2#{} Chips for",
            "every discard",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.chips,
                extra.chips_loss,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    pools = {
        Food = true,
    },
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.joker_main and extra.chips > 0 then
            return {
                chips = extra.chips,
            }
        end

        if context.discard
            and not context.blueprint
            and not context.retrigger_joker
            and extra.chips > 0
        then
            local discard_key = canlaugh_ice_soup_discard_key()
            if extra.last_discard == discard_key then
                return
            end

            extra.last_discard = discard_key
            extra.chips = math.max(0, extra.chips - extra.chips_loss)
            if extra.chips <= 0 then
                SMODS.destroy_cards(card, nil, nil, true)
                return {
                    message = localize("k_melted_ex"),
                    colour = G.C.CHIPS,
                }
            end

            card:juice_up(0.3, 0.5)
            return {
                message = "-" .. tostring(extra.chips_loss) .. " Chips",
                colour = G.C.CHIPS,
            }
        end
    end,
})
