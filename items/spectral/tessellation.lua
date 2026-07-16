SMODS.Atlas({
    key = "tessellation",
    path = "tessellation.png",
    px = 71,
    py = 95,
})

local function canlaugh_is_vanilla_center(center)
    local mod = center and (center.mod or center.original_mod)

    return not mod or mod.id == "Balatro"
end

local function canlaugh_all_vanilla_vouchers_discovered()
    if not (G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Voucher) then
        return false
    end

    for _, voucher in ipairs(G.P_CENTER_POOLS.Voucher) do
        if voucher
            and voucher.set == "Voucher"
            and canlaugh_is_vanilla_center(voucher)
            and not voucher.discovered
        then
            return false
        end
    end

    return true
end

local function canlaugh_get_profile()
    return G
        and G.PROFILES
        and G.SETTINGS
        and G.PROFILES[G.SETTINGS.profile]
end

local function canlaugh_get_most_used_joker_key()
    local profile = canlaugh_get_profile()
    local usage = profile and profile.joker_usage
    local best_key
    local best_count = -1
    local best_order = math.huge

    for key, data in pairs(usage or {}) do
        local center = G and G.P_CENTERS and G.P_CENTERS[key]
        local count = tonumber(data and data.count) or 0
        local order = tonumber(data and data.order) or tonumber(center and center.order) or math.huge

        if center
            and center.set == "Joker"
            and count > 0
            and (count > best_count or (count == best_count and order < best_order))
        then
            best_key = key
            best_count = count
            best_order = order
        end
    end

    return best_key, best_count
end

local function canlaugh_create_negative_joker_copy(joker_key)
    if not (joker_key and G and G.jokers and type(create_card) == "function") then
        return
    end

    local joker = create_card("Joker", G.jokers, nil, nil, nil, nil, joker_key, "canlaugh_tessellation")

    if not joker then
        return
    end

    joker:add_to_deck()
    joker:set_edition({ negative = true }, true)
    G.jokers:emplace(joker)
    joker:start_materialize()

    return joker
end

SMODS.Spectral({
    key = "tessellation",
    name = "Tessellation",
    atlas = "tessellation",
    pos = { x = 0, y = 0 },
    cost = 4,
    hidden = true,
    soul_set = "Spectral",
    weight = 2.5,
    unlocked = false,
    discovered = false,
    loc_txt = {
        name = "Tessellation",
        text = {
            "Create a {C:dark_edition}Negative{} copy",
            "of your {C:attention}most used Joker{}",
            "Lose {C:money}$15{}",
        },
        unlock = {
            "Discover every",
            "{C:attention}vanilla Voucher{}",
        },
    },
    can_use = function(self, card)
        return canlaugh_get_most_used_joker_key() ~= nil
    end,
    use = function(self, card, area, copier)
        local used_spectral = copier or card
        local joker_key = canlaugh_get_most_used_joker_key()

        if not joker_key then
            return
        end

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.4,
            func = function()
                play_sound("tarot1")
                used_spectral:juice_up(0.3, 0.5)
                return true
            end,
        }))

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.2,
            func = function()
                local joker = canlaugh_create_negative_joker_copy(joker_key)

                if joker then
                    discover_card(G.P_CENTERS[joker_key])
                    ease_dollars(-15)
                end

                return true
            end,
        }))

        delay(0.3)
    end,
    check_for_unlock = function(self, args)
        return canlaugh_all_vanilla_vouchers_discovered()
    end,
})
