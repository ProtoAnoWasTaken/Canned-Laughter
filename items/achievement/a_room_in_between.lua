SMODS.Achievement({
    key = "a_room_in_between",
    loc_txt = {
        name = "A Room In-Between",
        description = {
            "Receive 5 Eggs from",
            "the forgotten man",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_room_in_between"
    end,
})
