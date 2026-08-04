local CL = CannedLaughter

SMODS.Atlas({
    key = "boss_sinker",
    path = "blind_sinker.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

CL.register_standard_boss({
    key = "sinker",
    atlas = "boss_sinker",
    boss_colour = HEX("3C5278"),
    mult = 2,
    loc_txt = {
        name = "The Sinker",
        text = {
            "Played cards lose",
            "a rank after scoring",
        },
    },
    calculate = function(self, blind, context)
        if context
            and context.destroying_card
            and context.destroying_card.canlaugh_catalyze_destroy_after_scoring
        then
            return { remove = true }
        end

        if not (context and context.final_scoring_step and context.full_hand) then
            return
        end

        for _, card in ipairs(context.full_hand) do
            CL.catalyze_rank(card, false, true)
        end
    end,
})
