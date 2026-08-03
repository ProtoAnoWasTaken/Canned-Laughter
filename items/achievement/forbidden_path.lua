SMODS.Achievement({
    key = "forbidden_path",
    loc_txt = {
        name = "Forbidden Path",
        description = {
            "Play a full hand of Frozen Cards",
            "without thawing them",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_forbidden_path"
    end,
})
