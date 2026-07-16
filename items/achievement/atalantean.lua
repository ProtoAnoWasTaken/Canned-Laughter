SMODS.Achievement({
    key = "atalantean",
    loc_txt = {
        name = "Atalantean",
        description = {
            "Max out on Blood Money",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_atalantean"
    end,
})
