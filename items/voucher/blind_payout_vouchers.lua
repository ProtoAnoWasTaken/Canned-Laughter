local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local legacy_voucher_centers = {
    ["Silver Spoon"] = "v_canlaugh_silver_spoon",
    ["Heirloom"] = "v_canlaugh_heirloom",
}

local function migrate_legacy_voucher_center(card_table)
    local save_fields = card_table and card_table.save_fields
    local center_key = save_fields and save_fields.center

    if not center_key or (G and G.P_CENTERS and G.P_CENTERS[center_key]) then
        return
    end

    local replacement_key = legacy_voucher_centers[card_table.label]
    if replacement_key and G.P_CENTERS[replacement_key] then
        save_fields.center = replacement_key
    end
end

if Card and type(Card.load) == "function" and not CL.blind_payout_voucher_load_hook_installed then
    CL.blind_payout_voucher_load_hook_installed = true
    local blind_payout_voucher_load_ref = Card.load

    function Card:load(card_table, other_card)
        migrate_legacy_voucher_center(card_table)
        return blind_payout_voucher_load_ref(self, card_table, other_card)
    end
end

local function cl_voucher_used(suffix)
    local used = G and G.GAME and G.GAME.used_vouchers

    if not used then
        return false
    end

    return used["v_canlaugh_" .. suffix] or used["v_" .. suffix]
end

local function cl_blind_payout_bonus_fraction()
    local bonus = 0

    if cl_voucher_used("silver_spoon") then
        bonus = bonus + 0.5
    end
    if cl_voucher_used("heirloom") then
        bonus = bonus + 0.5
    end

    return bonus
end

local function cl_silver_spoon_redeem_count()
    local profile = G
        and G.PROFILES
        and G.SETTINGS
        and G.PROFILES[G.SETTINGS.profile]
    local usage = profile
        and profile.voucher_usage
        and (profile.voucher_usage.v_canlaugh_silver_spoon or profile.voucher_usage.v_silver_spoon)

    return usage and usage.count or 0
end

local function cl_apply_blind_payout_bonus()
    local bonus_fraction = cl_blind_payout_bonus_fraction()

    if bonus_fraction <= 0
        or not (G and G.GAME and G.GAME.blind)
        or G.GAME.chips - G.GAME.blind.chips < 0
    then
        return
    end

    local base_dollars = G.GAME.blind.dollars or 0
    local extra_dollars = math.floor(base_dollars * bonus_fraction)

    if extra_dollars <= 0 then
        return
    end

    SMODS.cashout_dollars = (SMODS.cashout_dollars or 0) + extra_dollars

    if type(add_round_eval_row) == "function" then
        add_round_eval_row({
            dollars = extra_dollars,
            bonus = true,
            name = "custom_canlaugh_blind_payout",
            pitch = SMODS.cashout_pitch or 0.95,
            text = localize({
                type = "name_text",
                set = "Voucher",
                key = cl_voucher_used("heirloom") and "v_canlaugh_heirloom" or "v_canlaugh_silver_spoon",
            }),
            text_colour = G.C.MONEY,
        })

        SMODS.cashout_index = (SMODS.cashout_index or 0) + 1
        SMODS.cashout_pitch = (SMODS.cashout_pitch or 0.95) + 0.06
    end
end

if SMODS and type(SMODS.calculate_context) == "function" and not CL.blind_payout_voucher_hook_installed then
    CL.blind_payout_voucher_hook_installed = true
    local cl_calculate_context_ref = SMODS.calculate_context

    function SMODS.calculate_context(context, return_table, no_resolve)
        local results = { cl_calculate_context_ref(context, return_table, no_resolve) }

        if context
            and context.modify_final_cashout
            and not CL.blind_payout_voucher_running
        then
            CL.blind_payout_voucher_running = true
            local ok, err = pcall(cl_apply_blind_payout_bonus)
            CL.blind_payout_voucher_running = nil

            if not ok and type(sendErrorMessage) == "function" then
                sendErrorMessage("[Canned Laughter] Blind payout vouchers failed: " .. tostring(err))
            end
        end

        return unpack(results)
    end
end

SMODS.Atlas({
    key = "silver_spoon",
    path = "silverspoon.png",
    px = 71,
    py = 95,
})

SMODS.Atlas({
    key = "heirloom",
    path = "heirloom.png",
    px = 71,
    py = 95,
})

SMODS.Voucher({
    key = "silver_spoon",
    name = "Silver Spoon",
    atlas = "silver_spoon",
    pos = { x = 0, y = 0 },
    order = 30,
    cost = 10,
    unlocked = true,
    available = true,
    loc_txt = {
        name = "Silver Spoon",
        text = {
            "{C:attention}Blind payouts{}",
            "provide {C:money}50%{} more",
        },
    },
})

SMODS.Voucher({
    key = "heirloom",
    name = "Heirloom",
    atlas = "heirloom",
    pos = { x = 0, y = 0 },
    order = 31,
    cost = 10,
    requires = { "v_canlaugh_silver_spoon" },
    unlocked = false,
    available = true,
    loc_txt = {
        name = "Heirloom",
        text = {
            "{C:attention}Blind payouts{}",
            "provide another {C:money}50%{} more",
        },
        unlock = {
            "Redeem {C:attention}Silver Spoon{}",
            "{C:attention}5{} times",
        },
    },
    locked_loc_vars = function()
        return { vars = {} }
    end,
    check_for_unlock = function(self, args)
        return args
            and args.type == "run_redeem"
            and cl_silver_spoon_redeem_count() >= 5
    end,
})
