SMODS.Achievement({
    key = "oh_banana",
    loc_txt = {
        name = "Oh, Banana!",
        description = {
            "Expire the Cavendish",
            "and meet its successor",
        },
    },
    unlock_condition = function(self, args)
        return args and args.type == "canlaugh_oh_banana"
    end,
})
