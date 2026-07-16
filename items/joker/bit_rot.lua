SMODS.Shader({
    key = "bit_rot",
    path = "bit_rot.fs",
})

SMODS.Atlas({
    key = "bit_rot",
    path = "bit_rot.png",
    px = 69,
    py = 93,
})

local NUMBER_RANKS = { "2", "3", "4", "5", "6", "7", "8", "9", "10" }

local function canlaugh_bit_rot_other_number_ranks(scored_card)
    local ranks = {}

    for _, rank in ipairs(NUMBER_RANKS) do
        if rank ~= scored_card.base.value then
            ranks[#ranks + 1] = rank
        end
    end

    return ranks
end

SMODS.DrawStep({
    key = "canlaugh_bit_rot_shader",
    order = -9,
    func = function(card)
        local center = card and card.config and card.config.center
        if center
            and center.key == "j_canlaugh_bit_rot"
            and card.children
            and card.children.center
        then
            local shader = G and G.SHADERS and G.SHADERS.canlaugh_bit_rot
                and "canlaugh_bit_rot" or "dissolve"
            card.children.center:draw_shader(shader, nil, card.ARGS.send_to_shader)
        end
    end,
    conditions = { vortex = false, facing = "front" },
})

SMODS.Joker({
    key = "bit_rot",
    name = "Bit Rot",
    atlas = "bit_rot",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 4,
    config = { extra = { odds = 2 } },
    loc_txt = {
        name = "Bit Rot",
        text = {
            "Scored {C:attention}number cards{} have a",
            "{C:green}#1# in #2#{} chance to become a",
            "{C:attention}different rank{} after scoring",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability.extra or self.config.extra
        local numerator, denominator = SMODS.get_probability_vars(
            card,
            1,
            extra.odds,
            "canlaugh_bit_rot"
        )
        return { vars = { numerator, denominator } }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.after and not context.blueprint then
            local cards_to_change = {}

            for _, scored_card in ipairs(context.scoring_hand or {}) do
                local rank = scored_card:get_id()
                if rank >= 2 and rank <= 10
                    and SMODS.pseudorandom_probability(
                        card,
                        "canlaugh_bit_rot",
                        1,
                        card.ability.extra.odds
                    )
                then
                    cards_to_change[#cards_to_change + 1] = scored_card
                end
            end

            if #cards_to_change > 0 then
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.15,
                    func = function()
                        for _, scored_card in ipairs(cards_to_change) do
                            if scored_card and not scored_card.destroyed then
                                local ranks = canlaugh_bit_rot_other_number_ranks(scored_card)
                                local random_rank = pseudorandom_element(
                                    ranks,
                                    pseudoseed("canlaugh_bit_rot")
                                )

                                if random_rank then
                                    SMODS.change_base(scored_card, nil, random_rank)
                                    scored_card:juice_up(0.15, 0.15)
                                end
                            end
                        end

                        return true
                    end,
                }))

                return {
                    message = "Corrupted!",
                    colour = G.C.FILTER,
                }
            end
        end
    end,
})
