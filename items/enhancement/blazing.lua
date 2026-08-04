local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({
    key = "blazing_enhancement",
    path = "blazing_enhancement.png",
    px = 69,
    py = 93,
})

local function ranks_lost(card)
    return card.ability and card.ability.canlaugh_blazing_ranks_lost or 0
end

local function blazing_aces(cards)
    if #(cards or {}) == 0 then
        return false
    end

    for _, card in ipairs(cards) do
        if card:get_id() ~= 14 or not SMODS.has_enhancement(card, "m_canlaugh_blazing") then
            return false
        end
    end

    return true
end

local function descend(card)
    if not card or card.removed then return end
    if card.base.id == 14 then
        card:flip()
        play_sound("card1", 1, 0.6)
        card.ability.canlaugh_blazing_destroy_after_scoring = true
        return
    end
    local rank = CL.consumables.rank_center(card.base.id == 2 and 14 or card.base.id - 1)
    if not rank then return end
    CL.consumables.tarot_flip(card, function()
        SMODS.change_base(card, nil, rank.key)
        card.ability.canlaugh_blazing_ranks_lost = ranks_lost(card) + 1
    end)
end

SMODS.Enhancement({
    key = "blazing",
    atlas = "blazing_enhancement",
    pos = { x = 0, y = 0 },
    config = {
        extra = {
            rank_decrease = 1,
        },
        canlaugh_blazing_ranks_lost = 0,
    },
    loc_txt = {
        name = "Blazing Card",
        text = {
            "Loses {C:attention}#1#{} rank after scoring",
            "until destroyed",
            "{C:mult}+#2#{} Mult for every rank",
            "lost this way",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.rank_decrease,
                5 * ranks_lost(card),
            },
        }
    end,
    calculate = function(self, card, context)
        if context.destroying_card == card and card.ability.canlaugh_blazing_destroy_after_scoring then
            return { remove = true }
        end

        if context.cardarea == G.play and context.main_scoring then
            CL.blazing_score_queue = CL.blazing_score_queue or {}
            if not card.ability.canlaugh_blazing_queued_this_score then
                card.ability.canlaugh_blazing_queued_this_score = true
                CL.blazing_score_queue[#CL.blazing_score_queue + 1] = card
            end
            local mult = 5 * ranks_lost(card)
            if mult > 0 then
                return {
                    mult = mult,
                    card = card,
                }
            end
        end
    end,
})

if SMODS and type(SMODS.calculate_context) == "function" and not CL.blazing_context_hook_installed then
    CL.blazing_context_hook_installed = true
    local calculate_context_ref = SMODS.calculate_context
    function SMODS.calculate_context(context, return_table, no_resolve, ...)
        local results = { calculate_context_ref(context, return_table, no_resolve, ...) }
        if context and context.final_scoring_step then
            local queue = CL.blazing_score_queue or {}
            CL.blazing_score_queue = nil
            for _, card in ipairs(queue) do descend(card) end
            for _, card in ipairs(G.playing_cards or {}) do
                if card.ability then card.ability.canlaugh_blazing_queued_this_score = nil end
            end
        end
        return unpack(results)
    end
end

if SMODS and type(SMODS.calculate_context) == "function" and not CL.blaze_of_glory_context_hook_installed then
    CL.blaze_of_glory_context_hook_installed = true
    local calculate_context_ref = SMODS.calculate_context
    function SMODS.calculate_context(context, return_table, no_resolve, ...)
        local results = { calculate_context_ref(context, return_table, no_resolve, ...) }
        if context
            and context.before
            and context.scoring_name == "Flush Five"
            and blazing_aces(context.full_hand)
            and type(check_for_unlock) == "function"
        then
            check_for_unlock({ type = "canlaugh_secreter_hands" })
        end
        if context
            and context.evaluate_poker_hand
            and context.scoring_name == "Flush Five"
            and not return_table
            and blazing_aces(context.full_hand)
        then
            results[1] = results[1] or {}
            results[1].replace_display_name = "Blaze of Glory"
        end
        return unpack(results)
    end
end
