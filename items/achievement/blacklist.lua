SMODS.Achievement({
    key = "blacklist",
    loc_txt = {
        name = "Blacklist",
        description = {
            "Discover the man at",
            "the edges of Challenges",
        },
    },
    unlock_condition = function(self, args)
        if args and args.type == "canlaugh_blacklist" then
            return true
        end
        local challenged_joker = G and G.P_CENTERS and G.P_CENTERS.j_canlaugh_challenged_joker
        return challenged_joker and challenged_joker.discovered
    end,
})
