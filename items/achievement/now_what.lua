SMODS.Achievement({
    key = "now_what",
    loc_txt = {
        name = "Now What?",
        description = {
            "Pick up Joker Template",
            "with a non-face deck",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_now_what"
    end,
})
