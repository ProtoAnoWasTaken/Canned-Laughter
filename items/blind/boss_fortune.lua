local CL = CannedLaughter
SMODS.Atlas({ key = "boss_fortune", path = "blind_fortune.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "fortune",
    atlas = "boss_fortune",
    art = "fortune",
    boss_colour = HEX("EFDF72"),
    mult = 1.5,
    loc_txt = { name = "The Fortune", text = { "Money gained adds to score" } },
})

local function canlaugh_is_positive_money_gain(value)
    if type(value) == "number" then
        return value > 0
    end

    if type(compare_numbers) == "function" then
        local ok, result = pcall(compare_numbers, value, "gt", 0)

        if ok then
            return result == true
        end
    end

    if type(to_number) == "function" then
        local ok, converted = pcall(to_number, value)

        if ok and type(converted) == "number" then
            return converted > 0
        end
    end

    return false
end

if type(ease_dollars) == "function" and not CL.boss_fortune_hook then
    CL.boss_fortune_hook = true
    local ease_dollars_ref = ease_dollars
    function ease_dollars(mod, instant, ...)
        local factor = CL.boss_active("bl_canlaugh_celadon_coin") and 2
            or CL.boss_active("bl_canlaugh_fortune") and 1
        local results = { ease_dollars_ref(mod, instant, ...) }

        if factor
            and mod
            and canlaugh_is_positive_money_gain(mod)
            and SMODS.ease_dollars_calc
            and type(SMODS.mod_score) == "function"
        then
            SMODS.mod_score({
                add = mod * 1000 * factor,
            })
        end

        return unpack(results)
    end
end
