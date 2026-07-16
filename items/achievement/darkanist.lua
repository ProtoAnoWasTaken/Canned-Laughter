local DARKANIST_JOKERS = {
    "j_canlaugh_mad_groove",
    "j_canlaugh_blood_astronomia",
    "j_canlaugh_hail_from_the_future",
    "j_canlaugh_edge_of_the_earth",
}

local function canlaugh_darkanist_discovered()
    for _, key in ipairs(DARKANIST_JOKERS) do
        local center = G and G.P_CENTERS and G.P_CENTERS[key]
        if not (center and center.discovered) then return false end
    end
    return true
end

SMODS.Achievement({
    key = "darkanist",
    loc_txt = {
        name = "Darkanist",
        description = { "Discover all four of",
                        "the Randomazzo's Jokers" },
    },
    unlock_condition = function(self, args)
         return (args and args.type == "canlaugh_darkanist")
            or canlaugh_darkanist_discovered()
    end,
})
