local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({
    key = "concrete",
    path = "concrete.png",
    px = 69,
    py = 93,
})

SMODS.Enhancement({
    key = "concrete",
    atlas = "concrete",
    pos = { x = 0, y = 0 },
    no_suit = true,
    no_rank = true,
    always_scores = true,
    replace_base_card = true,
    loc_txt = {
        name = "Concrete Card",
        text = {
            "{C:mult}+10 Mult{}, plus {C:mult}+5{} for every",
            "other Concrete Card played",
            "{C:inactive}Must be played with another{}",
        },
    },
    calculate = function(self, card, context)
        if context.cardarea ~= G.play or not context.main_scoring then return end
        local count = 0
        for _, scored in ipairs(context.scoring_hand or {}) do
            if SMODS.has_enhancement(scored, "m_canlaugh_concrete") then count = count + 1 end
        end
        if count < 2 then return end
        return {
            mult = 10 + 5 * (count - 1),
            card = card,
        }
    end,
})

if SMODS and type(SMODS.calculate_context) == "function" and not CL.concrete_context_hook_installed then
    CL.concrete_context_hook_installed = true
    local calculate_context_ref = SMODS.calculate_context
    function SMODS.calculate_context(context, return_table, no_resolve, ...)
        local results = { calculate_context_ref(context, return_table, no_resolve, ...) }
        if context and context.evaluate_poker_hand and context.scoring_name == "High Card" and #(context.full_hand or {}) == 5 then
            local all_concrete = true
            for _, card in ipairs(context.full_hand) do
                if not SMODS.has_enhancement(card, "m_canlaugh_concrete") then all_concrete = false break end
            end
            if all_concrete and results[1] then
                results[1].replace_scoring_name = "Straight"
                results[1].replace_display_name = "Straight"
            end
        end
        return unpack(results)
    end
end
