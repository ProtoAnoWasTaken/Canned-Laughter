local CL = CannedLaughter
SMODS.Atlas({ key = "boss_journey", path = "blind_journey.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

local function ante_limit(ante)
    return math.ceil(ante / 8) * 8
end

CL.register_standard_boss({
    key = "journey",
    atlas = "boss_journey",
    art = "journey",
    boss_colour = HEX("E7952B"),
    mult = 2,
    loc_txt = { name = "The Journey", text = { "Every 100% of the goal", "raises the next Ante" } },
    calculate = function(self, _blind, context)
        if not (context and context.end_of_round and context.beat_boss) then return end
        local defeated_blind = G and G.GAME and G.GAME.blind
        if not (defeated_blind and defeated_blind.chips and G.GAME.chips) then return end
        local raises = math.floor(G.GAME.chips / defeated_blind.chips)
        local ante = G.GAME.round_resets.ante
        local extra = math.min(math.max(0, raises - 1), math.max(0, ante_limit(ante) - ante - 1))
        G.GAME.canlaugh_journey_ante_bonus = extra > 0 and extra or nil
    end,
})

if type(ease_ante) == "function" and not CL.boss_journey_hook then
    CL.boss_journey_hook = true
    local ease_ante_ref = ease_ante
    function ease_ante(mod, ...)
        local results = { ease_ante_ref(mod, ...) }
        local extra = G and G.GAME and G.GAME.canlaugh_journey_ante_bonus
        if mod and mod > 0 and SMODS and SMODS.ante_end and extra and extra > 0 then
            G.GAME.canlaugh_journey_ante_bonus = nil
            ease_ante(extra)
            ease_dollars(extra * 25)
        end
        return unpack(results)
    end
end
