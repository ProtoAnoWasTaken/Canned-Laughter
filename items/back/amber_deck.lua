local CD = CannedLaughter.colour_decks

SMODS.Atlas({
    key = "amber_deck",
    path = "amber_deck.png",
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "amber_deck",
    name = "Amber Deck",
    atlas = "amber_deck",
    pos = { x = 0, y = 0 },
    order = 25,
    unlocked = false,

    config = {
        dollars = -4,
    },

    loc_txt = {
        name = "Amber Deck",
        text = {
            "Start the run with {C:money}$0{}",
            "Go up to {C:red}-$10{} in debt",
        },
        unlock = {
            "Win a run with the {C:attention}Yellow Deck{}",
            "on any difficulty",
        },
    },

    locked_loc_vars = function()
        return { vars = {} }
    end,

    check_for_unlock = function(self, args)
        return CD.won_with("b_yellow", args)
    end,

    apply = function(self, back)
        G.GAME.bankrupt_at = -10
    end,
})
