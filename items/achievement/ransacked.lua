SMODS.Achievement({
    key = "ransacked",
    loc_txt = {
        name = "Ransacked",
        description = {
            "Successfully barter for everything",
            "you can in a Shop",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_ransacked"
    end,
})
