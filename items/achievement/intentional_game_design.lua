SMODS.Achievement({
    key = "intentional_game_design",
    loc_txt = {
        name = "Intentional Game Design",
        description = {
            "Find a game-breaking pair",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_intentional_game_design"
    end,
})
