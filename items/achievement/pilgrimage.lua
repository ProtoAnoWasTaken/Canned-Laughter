SMODS.Achievement({
    key = "pilgrimage",
    loc_txt = {
        name = "Pilgrimage",
        description = {
            "Discover the Court in Full",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_pilgrimage"
    end,
})
