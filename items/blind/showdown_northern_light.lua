local CL = CannedLaughter

SMODS.Atlas({
    key = "showdown_northern_light",
    path = "showdown_northern_light.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

local function thaw_all_frozen_cards()
    if type(CL.thaw_frozen) ~= "function" then
        return
    end

    local seen = {}
    local areas = {
        G.jokers,
        G.consumeables,
        G.hand,
        G.play,
        G.deck,
        G.discard,
    }

    for _, area in ipairs(areas) do
        for _, card in ipairs(area and area.cards or {}) do
            seen[card] = true
            CL.thaw_frozen(card)
        end
    end

    for _, card in ipairs(G.playing_cards or {}) do
        if not seen[card] then
            CL.thaw_frozen(card)
        end
    end
end

CL.register_showdown_boss({
    key = "northern_light",
    atlas = "showdown_northern_light",
    boss_colour = HEX("FE5F55"),
    mult = 2,
    loc_txt = {
        name = "Northern Light",
        text = {
            "Thaw all Frozen cards,",
            "played cards lose a rank",
            "after scoring",
        },
    },
    set_blind = function()
        thaw_all_frozen_cards()
    end,
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
            CL.catalyze_rank(card, true, true)
        end
    end,
})
