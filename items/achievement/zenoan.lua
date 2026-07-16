SMODS.Achievement({
    key = "zenoan",
    loc_txt = {
        name = "Zenoan",
        description = {
            "Overcharge on Blood Money",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_zenoan"
    end,
})
