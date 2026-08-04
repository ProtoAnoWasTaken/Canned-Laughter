local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local CD = CL.colour_decks
local DECK_KEY = "b_canlaugh_chained_deck"

local function canlaugh_chained_deck_active()
    local selected_back = G and G.GAME and G.GAME.selected_back
    local center = selected_back and selected_back.effect and selected_back.effect.center

    return center and center.key == DECK_KEY
end

if SMODS and type(SMODS.always_scores) == "function" and not CL.chained_deck_always_scores_hook_installed then
    CL.chained_deck_always_scores_hook_installed = true
    local always_scores_ref = SMODS.always_scores

    function SMODS.always_scores(card)
        if canlaugh_chained_deck_active() then
            return true
        end

        return always_scores_ref(card)
    end
end

SMODS.Atlas({
    key = "chained_deck",
    path = "chained_deck.png",
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "chained_deck",
    name = "Chained Deck",
    atlas = "chained_deck",
    pos = { x = 0, y = 0 },
    order = 30,
    unlocked = false,
    config = {
        hands = -1,
    },
    loc_txt = {
        name = "Chained Deck",
        text = {
            "{C:blue}-1{} hand every round",
            "Every played card counts in scoring",
            "{C:attention,T:m_steel}Steel Cards{} retrigger",
        },
        unlock = {
            "Win a run with the",
            "{C:attention}Painted Deck{}",
            "on any difficulty",
        },
    },
    check_for_unlock = function(self, args)
        return CD.won_with("b_painted", args)
    end,
    calculate = function(self, back, context)
        if context.repetition
            and context.cardarea == G.hand
            and context.other_card
            and SMODS.has_enhancement(context.other_card, "m_steel")
        then
            return {
                message = localize("k_again_ex"),
                repetitions = 1,
                card = context.other_card,
            }
        end
    end,
})
