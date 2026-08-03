SMODS.Achievement({
    key = "still_the_best_522_bce",
    loc_txt = {
        name = "STILL THE BEST 522 BCE",
        description = {
            "Conquer the Spilled Vessel",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_spilled_vessel_defeated"
    end,
})
