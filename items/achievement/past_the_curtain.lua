SMODS.Achievement({
    key = "past_the_curtain",
    loc_txt = {
        name = "Past the Curtain",
        description = { "Kill the Rat's past" },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_past_the_curtain"
    end,
})
