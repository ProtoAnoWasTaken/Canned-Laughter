local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local RARE_SPECTRAL_KEYS = {
    c_soul = true,
    c_black_hole = true,
    c_canlaugh_tessellation = true,
    c_canlaugh_crimson_king = true,
    c_canlaugh_city_keeper = true,
    c_canlaugh_retrospect = true,
}

local function voucher_used(key)
    local used_vouchers = G and G.GAME and G.GAME.used_vouchers

    return used_vouchers and used_vouchers[key]
end

local function vinyl_print_unlocked()
    local required_keys = {
        "c_canlaugh_crimson_king",
        "c_canlaugh_city_keeper",
        "c_canlaugh_retrospect",
    }

    for _, key in ipairs(required_keys) do
        local center = G and G.P_CENTERS and G.P_CENTERS[key]
        if not (center and center.discovered) then
            return false
        end
    end

    return true
end

local function apply_weight_modifier(center, voucher_key)
    if not center or center.canlaugh_voucher_weight_modifier then
        return
    end

    center.canlaugh_voucher_weight_modifier = true
    local get_weight_ref = center.get_weight

    center.get_weight = function(self, weight, args)
        local result = get_weight_ref and get_weight_ref(self, weight, args) or weight

        if voucher_used(voucher_key) then
            return result * 1.5
        end

        return result
    end
end

for _, center in ipairs(CL.colored_tarot and CL.colored_tarot.pool() or {}) do
    apply_weight_modifier(center, "v_canlaugh_b_side")
end

for key in pairs(RARE_SPECTRAL_KEYS) do
    local center = G and G.P_CENTERS and G.P_CENTERS[key]
    if center and not center.canlaugh_vinyl_print_weight_modifier then
        center.canlaugh_vinyl_print_weight_modifier = true
        local get_weight_ref = center.get_weight

        center.get_weight = function(self, weight, args)
            local result = get_weight_ref and get_weight_ref(self, weight, args) or weight

            if voucher_used("v_canlaugh_vinyl_print") then
                return result * 2
            end

            return result
        end
    end
end

SMODS.Atlas({
    key = "b_side",
    path = "b_side.png",
    px = 71,
    py = 95,
})

SMODS.Atlas({
    key = "vinyl_print",
    path = "vinyl_release.png",
    px = 71,
    py = 95,
})

SMODS.Voucher({
    key = "b_side",
    name = "B-Side",
    atlas = "b_side",
    pos = { x = 0, y = 0 },
    order = 34,
    cost = 10,
    unlocked = true,
    available = true,
    loc_txt = {
        name = "B-Side",
        text = {
            "{C:tarot}Colored Tarot{} cards",
            "are {C:attention}50%{} more common",
            "in Tarot Booster Packs",
        },
    },
})

SMODS.Voucher({
    key = "vinyl_print",
    name = "Vinyl Print",
    atlas = "vinyl_print",
    pos = { x = 0, y = 0 },
    order = 35,
    cost = 10,
    requires = { "v_canlaugh_b_side" },
    unlocked = false,
    available = true,
    loc_txt = {
        name = "Vinyl Print",
        text = {
            "Rare {C:spectral}Spectral{} cards",
            "are {C:attention}2X{} more common",
        },
        unlock = {
            "Discover {C:spectral}The Crimson King{},",
            "{C:spectral}The City Keeper{}, and",
            "{C:spectral}Retrospect{}",
        },
    },
    locked_loc_vars = function()
        return { vars = {} }
    end,
    check_for_unlock = function()
        return vinyl_print_unlocked()
    end,
})
