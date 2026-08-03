SMODS.Atlas({
    key = "case_card",
    path = "case_card.png",
    px = 69,
    py = 93,
})

local function canlaugh_case_card_scoring_position(scoring_hand, target)
    for index, scoring_card in ipairs(scoring_hand or {}) do
        if scoring_card == target then
            return index
        end
    end
end

local function canlaugh_case_card_is_last_of_rank(target, scoring_hand)
    if not (target and target.base and target.base.id) then
        return false
    end

    local target_rank = target.base.id
    local target_position = canlaugh_case_card_scoring_position(scoring_hand, target)

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card ~= target
            and not playing_card.removed
            and not playing_card.destroyed
            and playing_card.base
            and playing_card.base.id == target_rank
        then
            local other_position = canlaugh_case_card_scoring_position(scoring_hand, playing_card)
            if not other_position or not target_position or other_position > target_position then
                return false
            end
        end
    end

    return true
end

SMODS.Joker({
    key = "case_card",
    name = "Case Card",
    atlas = "case_card",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = {
        extra = {
            x_mult = 1.5,
        },
    },
    loc_txt = {
        name = "Case Card",
        text = {
            "The last played card of any",
            "given rank in your full deck",
            "gives {X:mult,C:white}X#1#{} Mult",
        },
        unlock = {
            "Lose by running out of",
            "playable cards",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return { vars = { extra.x_mult } }
    end,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_card_drought"
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual
            and context.cardarea == G.play
            and context.other_card
            and canlaugh_case_card_is_last_of_rank(context.other_card, context.scoring_hand)
        then
            return {
                x_mult = card.ability.extra.x_mult,
                card = card,
            }
        end
    end,
})

if SMODS and type(SMODS.calculate_context) == "function" and not CannedLaughter.case_card_drought_hook_installed then
    CannedLaughter.case_card_drought_hook_installed = true
    local calculate_context_ref = SMODS.calculate_context

    function SMODS.calculate_context(context, return_table, no_resolve, ...)
        if context and context.end_of_round and context.game_over and #(G.playing_cards or {}) == 0
            and type(check_for_unlock) == "function"
        then
            check_for_unlock({ type = "canlaugh_card_drought" })
        end

        return calculate_context_ref(context, return_table, no_resolve, ...)
    end
end
