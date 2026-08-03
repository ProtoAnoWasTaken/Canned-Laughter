SMODS.Achievement({
    key = "where_am_i",
    loc_txt = {
        name = "Where Am I?",
        description = {
            "Huh?",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_where_am_i"
    end,
})
