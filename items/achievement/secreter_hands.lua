SMODS.Achievement({
    key = "secreter_hands",
    loc_txt = {
        name = "Secreter Hands",
        description = {
            "Play a Blaze of Glory",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_secreter_hands"
    end,
})
