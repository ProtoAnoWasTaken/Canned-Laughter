SMODS.Achievement({
    key = "low_orbit",
    loc_txt = {
        name = "Low Orbit",
        description = {
            "Carry over a consumable",
            "to your next run",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_low_orbit"
    end,
})
