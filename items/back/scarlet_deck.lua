local CD = CannedLaughter.colour_decks

SMODS.Atlas({
    key = "scarlet_deck",
    path = "scarlet_deck.png",
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "scarlet_deck",
    name = "Scarlet Deck",
    atlas = "scarlet_deck",
    pos = { x = 0, y = 0 },
    order = 23,
    unlocked = false,

    config = {
        discards = -1,
    },

    loc_txt = {
        name = "Scarlet Deck",
        text = {
            "{C:planet}Planet Cards{} provide",
            "{C:mult}50% more Mult{}",
            "{C:red}-1{} discard every round",
        },
        unlock = {
            "Win a run with the {C:attention}Red Deck{}",
            "on any difficulty",
        },
    },

    locked_loc_vars = function()
        return { vars = {} }
    end,

    check_for_unlock = function(self, args)
        return CD.won_with("b_red", args)
    end,
})
