SMODS.Atlas({
    key = "defect",
    path = "defect.png",
    px = 69,
    py = 93,
})

local function canlaugh_defect_main_start(card)
    local x_mults = {}

    for i = 1, 10 do
        x_mults[#x_mults + 1] = tostring(i)
    end

    local deck_card = G.deck and G.deck.cards and G.deck.cards[1] and G.deck.cards[#G.deck.cards]
    local glitch_suffix = "#@"
        .. (deck_card and deck_card.base and deck_card.base.id or 11)
        .. (deck_card and deck_card.base and deck_card.base.suit and deck_card.base.suit:sub(1, 1) or "D")
    local x_mult_text = " Mult "

    return {
        { n = G.UIT.T, config = { text = "  X", colour = G.C.MULT, scale = 0.32 } },
        {
            n = G.UIT.O,
            config = {
                object = DynaText({
                    string = x_mults,
                    colours = { G.C.RED },
                    pop_in_rate = 9999999,
                    silent = true,
                    random_element = true,
                    pop_delay = 0.5,
                    scale = 0.32,
                    min_cycle_time = 0,
                }),
            },
        },
        {
            n = G.UIT.O,
            config = {
                object = DynaText({
                    string = {
                        { string = "rand()", colour = G.C.JOKER_GREY },
                        { string = glitch_suffix, colour = G.C.RED },
                        x_mult_text,
                        x_mult_text,
                        x_mult_text,
                        x_mult_text,
                        x_mult_text,
                        x_mult_text,
                        x_mult_text,
                        x_mult_text,
                        x_mult_text,
                        x_mult_text,
                        x_mult_text,
                        x_mult_text,
                        x_mult_text,
                    },
                    colours = { G.C.UI.TEXT_DARK },
                    pop_in_rate = 9999999,
                    silent = true,
                    random_element = true,
                    pop_delay = 0.2011,
                    scale = 0.32,
                    min_cycle_time = 0,
                }),
            },
        },
    }
end

local function canlaugh_create_defect_consumable()
    if not (SMODS and type(SMODS.add_card) == "function" and G and G.consumeables) then
        return nil
    end

    return SMODS.add_card({
        set = "Consumeables",
        area = G.consumeables,
        key_append = "canlaugh_defect",
    })
end

local function canlaugh_create_defect_consumable_after_message()
    if G and G.E_MANAGER and type(Event) == "function" then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.45,
            func = function()
                canlaugh_create_defect_consumable()
                return true
            end,
        }))
        return
    end

    canlaugh_create_defect_consumable()
end

SMODS.Joker({
    key = "defect",
    name = "Defect",
    atlas = "defect",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    config = {
        extra = {
            min = 1,
            max = 10,
        },
    },
    loc_txt = {
        name = "Defect",
        text = {
            "",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {},
            main_start = canlaugh_defect_main_start(card),
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local extra = card.ability.extra
            local roll = pseudorandom(
                "canlaugh_defect_" .. tostring(card.sort_id or "") .. "_" .. tostring(G.GAME.hands_played or 0),
                extra.min,
                extra.max
            )

            if roll >= extra.max and not context.blueprint then
                card_eval_status_text(card, "extra", nil, nil, nil, {
                    message = "Jackpot!",
                    colour = G.C.FILTER,
                })
                canlaugh_create_defect_consumable_after_message()
            end

            return {
                x_mult = roll,
            }
        end
    end,
})
