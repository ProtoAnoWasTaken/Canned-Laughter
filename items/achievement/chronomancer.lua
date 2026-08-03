SMODS.Achievement({
    key = "chronomancer",
    loc_txt = {
        name = "Chronomancer",
        description = {
            "Loop the Antes twice",
            "in a single run",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_chronomancer"
    end,
})
