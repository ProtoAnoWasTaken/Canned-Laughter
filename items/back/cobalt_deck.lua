local CD = CannedLaughter.colour_decks

SMODS.Atlas({
    key = "cobalt_deck",
    path = "cobalt_deck.png",
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "cobalt_deck",
    name = "Cobalt Deck",
    atlas = "cobalt_deck",
    pos = { x = 0, y = 0 },
    order = 24,
    unlocked = false,

    config = {
        hands = -1,
    },

    loc_txt = {
        name = "Cobalt Deck",
        text = {
            "{C:planet}Planet Cards{} provide",
            "{C:chips}50% more Chips{}",
            "{C:blue}-1{} hand every round",
        },
        unlock = {
            "Win a run with the {C:attention}Blue Deck{}",
            "on any difficulty",
        },
    },

    locked_loc_vars = function()
        return { vars = {} }
    end,

    check_for_unlock = function(self, args)
        return CD.won_with("b_blue", args)
    end,
})
