SMODS.Achievement({
    key = "snake_eyes",
    loc_txt = {
        name = "Snake Eyes",
        description = {
            "Find dupes with the Businessman",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_snake_eyes"
    end,
})
