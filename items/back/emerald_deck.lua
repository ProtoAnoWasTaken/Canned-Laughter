local CD = CannedLaughter.colour_decks

SMODS.Atlas({
    key = "emerald_deck",
    path = "emerald_deck.png",
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "emerald_deck",
    name = "Emerald Deck",
    atlas = "emerald_deck",
    pos = { x = 0, y = 0 },
    order = 26,
    unlocked = false,

    config = {},

    loc_txt = {
        name = "Emerald Deck",
        text = {
            "Earn no {C:money}Interest{}",
            "Gain an {C:attention}Uncommon Tag{} after",
            "defeating a {C:attention}Big Blind{}",
        },
        unlock = {
            "Win a run with the {C:attention}Green Deck{}",
            "on any difficulty",
        },
    },

    locked_loc_vars = function()
        return { vars = {} }
    end,

    check_for_unlock = function(self, args)
        return CD.won_with("b_green", args)
    end,

    apply = function(self, back)
        G.GAME.modifiers.no_interest = true
    end,

    calculate = function(self, back, context)
        if context.setting_blind then
            G.GAME.canlaugh_emerald_tag_this_round = nil
        end

        if context.end_of_round
            and context.main_eval
            and not context.game_over
            and not context.individual
            and not context.repetition
            and G.GAME.blind_on_deck == "Big"
            and not G.GAME.canlaugh_emerald_tag_this_round
        then
            G.GAME.canlaugh_emerald_tag_this_round = true
            add_tag(Tag("tag_uncommon"))

            return {
                message = "+Uncommon Tag",
                colour = G.C.FILTER,
            }
        end
    end,
})
