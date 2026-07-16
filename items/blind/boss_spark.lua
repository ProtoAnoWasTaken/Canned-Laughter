local CL = CannedLaughter
SMODS.Atlas({ key = "boss_spark", path = "blind_spark.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "spark",
    atlas = "boss_spark",
    boss_colour = HEX("DAB772"),
    mult = 2,
    loc_txt = { name = "The Spark", text = { "Hand must contain", "only face cards" } },
    debuff_hand = function(self, cards)
        local triggered = false

        for _, card in ipairs(cards) do
            if not card:is_face(true) then
                triggered = true
                if G and G.GAME and G.GAME.blind then G.GAME.blind.triggered = true end
                return true
            end
        end

        if G and G.GAME and G.GAME.blind then G.GAME.blind.triggered = false end
    end,
})
