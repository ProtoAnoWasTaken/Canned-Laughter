SMODS.Achievement({
    key = "motorway_south",
    loc_txt = {
        name = "Motorway South",
        description = {
            "Reach into the psyche",
            "with Inland Empire",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_motorway_south"
    end,
})
