local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local MERCHANT_KEY = "v_canlaugh_spectral_merchant"
local TYCOON_KEY = "v_canlaugh_spectral_tycoon"
local GHOST_TYCOON_LOC_KEY = "b_canlaugh_ghost_tycoon"
local GHOST_TYCOON_LOC_TXT = {
    name = "Ghost Deck",
    text = {
        "Start run with",
        "{C:spectral,T:v_canlaugh_spectral_merchant}Spectral Merchant{}",
        "and {C:spectral,T:v_canlaugh_spectral_tycoon}Spectral Tycoon{}",
    },
}

local function profile()
    return G
        and G.PROFILES
        and G.SETTINGS
        and G.PROFILES[G.SETTINGS.profile]
end

local function spectral_purchase_count()
    local current_profile = profile()
    local career_stats = current_profile and current_profile.career_stats

    return career_stats and career_stats.canlaugh_spectral_shop_purchases or 0
end

local function record_spectral_purchase()
    local current_profile = profile()

    if not current_profile then
        return
    end

    current_profile.career_stats = current_profile.career_stats or {}
    current_profile.career_stats.canlaugh_spectral_shop_purchases = spectral_purchase_count() + 1

    if type(check_for_unlock) == "function" then
        check_for_unlock({ type = "canlaugh_spectral_shop_purchase" })
    end

    if G and type(G.save_progress) == "function" then
        G:save_progress()
    end
end

local function is_spectral_card(card)
    local center = card and card.config and card.config.center

    return (card and card.ability and card.ability.set == "Spectral")
        or (center and center.set == "Spectral")
end

local function increase_spectral_rate(amount)
    if G and G.GAME then
        G.GAME.spectral_rate = (G.GAME.spectral_rate or 0) + amount
    end
end

local function spectral_tycoon_unlocked()
    local tycoon = G and G.P_CENTERS and G.P_CENTERS[TYCOON_KEY]

    return tycoon and tycoon.unlocked
end

local function ensure_ghost_tycoon_loc()
    local descriptions = G and G.localization and G.localization.descriptions
    local back_loc = descriptions and descriptions.Back

    if not (back_loc and SMODS and type(SMODS.process_loc_text) == "function") then
        return false
    end

    if not back_loc[GHOST_TYCOON_LOC_KEY] then
        SMODS.process_loc_text(back_loc, GHOST_TYCOON_LOC_KEY, GHOST_TYCOON_LOC_TXT)
    end

    return back_loc[GHOST_TYCOON_LOC_KEY] ~= nil
end

local function grant_starting_merchant()
    if not (G and G.GAME) then
        return
    end

    G.GAME.used_vouchers = G.GAME.used_vouchers or {}
    if G.GAME.used_vouchers[MERCHANT_KEY] then
        return
    end

    G.GAME.used_vouchers[MERCHANT_KEY] = true
    increase_spectral_rate(2)
end

local function grant_starting_tycoon()
    if not (G and G.GAME and spectral_tycoon_unlocked()) then
        return
    end

    G.GAME.used_vouchers = G.GAME.used_vouchers or {}
    if G.GAME.used_vouchers[TYCOON_KEY] then
        return
    end

    G.GAME.used_vouchers[TYCOON_KEY] = true
    increase_spectral_rate(2)
end

if G and G.FUNCS and type(G.FUNCS.buy_from_shop) == "function" and not CL.spectral_merchant_shop_buy_hook_installed then
    CL.spectral_merchant_shop_buy_hook_installed = true
    local buy_from_shop_ref = G.FUNCS.buy_from_shop

    function G.FUNCS.buy_from_shop(e, ...)
        local card = e and e.config and e.config.ref_table
        local shop_area = card and card.area
        local was_spectral = is_spectral_card(card)
        local results = { buy_from_shop_ref(e, ...) }

        if was_spectral and card and shop_area and card.area ~= shop_area then
            record_spectral_purchase()
        end

        return unpack(results)
    end
end

if G and G.FUNCS and type(G.FUNCS.use_card) == "function" and not CL.spectral_merchant_pack_pick_hook_installed then
    CL.spectral_merchant_pack_pick_hook_installed = true
    local use_card_ref = G.FUNCS.use_card

    function G.FUNCS.use_card(e, ...)
        local card = e and e.config and e.config.ref_table
        local selected_from_pack = card and card.area == G.pack_cards
        local was_spectral = is_spectral_card(card)
        local results = { use_card_ref(e, ...) }

        if selected_from_pack and was_spectral and card and card.area ~= G.pack_cards then
            record_spectral_purchase()
        end

        return unpack(results)
    end
end

if not (CL.config and CL.config.disable_edition_modifier_overrides) and SMODS.Back then
    SMODS.Back:take_ownership("ghost", {
        config = {},
        loc_txt = {
            name = "Ghost Deck",
            text = {
                "Start run with",
                "{C:spectral,T:v_canlaugh_spectral_merchant}Spectral Merchant{}",
            },
        },
        loc_vars = function()
            if spectral_tycoon_unlocked() and ensure_ghost_tycoon_loc() then
                return { key = GHOST_TYCOON_LOC_KEY }
            end

            return { vars = {} }
        end,
        apply = function()
            grant_starting_merchant()
            grant_starting_tycoon()
        end,
    }, true)
end

SMODS.Atlas({
    key = "spectral_merchant",
    path = "spectral_merchant.png",
    px = 71,
    py = 93,
})

SMODS.Atlas({
    key = "spectral_tycoon",
    path = "spectral_tycoon.png",
    px = 71,
    py = 93,
})

SMODS.Voucher({
    key = "spectral_merchant",
    name = "Spectral Merchant",
    atlas = "spectral_merchant",
    pos = { x = 0, y = 0 },
    order = 36,
    cost = 10,
    unlocked = true,
    available = true,
    loc_txt = {
        name = "Spectral Merchant",
        text = {
            "{C:spectral}Spectral{} cards may",
            "appear in the shop",
        },
    },
    redeem = function()
        increase_spectral_rate(2)
    end,
})

SMODS.Voucher({
    key = "spectral_tycoon",
    name = "Spectral Tycoon",
    atlas = "spectral_tycoon",
    pos = { x = 0, y = 0 },
    order = 37,
    cost = 10,
    requires = { MERCHANT_KEY },
    unlocked = false,
    available = true,
    loc_txt = {
        name = "Spectral Tycoon",
        text = {
            "{C:spectral}Spectral{} cards appear",
            "{C:attention}2X{} more frequently in the shop",
        },
        unlock = {
            "Buy {C:attention}25{} {C:spectral}Spectral{} cards",
            "from the shop or Booster Packs",
        },
    },
    redeem = function()
        increase_spectral_rate(2)
    end,
    locked_loc_vars = function()
        return { vars = { spectral_purchase_count(), 25 } }
    end,
    check_for_unlock = function(self, args)
        return args
            and args.type == "canlaugh_spectral_shop_purchase"
            and spectral_purchase_count() >= 25
    end,
})
