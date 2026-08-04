local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local BT = CL.barter

local function voucher_used(key)
    local used_vouchers = G and G.GAME and G.GAME.used_vouchers

    return used_vouchers and used_vouchers[key]
end

local function profile()
    return G
        and G.PROFILES
        and G.SETTINGS
        and G.PROFILES[G.SETTINGS.profile]
end

local function barter_success_count()
    local current_profile = profile()
    local career_stats = current_profile and current_profile.career_stats

    return career_stats and career_stats.canlaugh_successful_barters or 0
end

local function record_successful_barter()
    local current_profile = profile()

    if not current_profile then
        return
    end

    current_profile.career_stats = current_profile.career_stats or {}
    current_profile.career_stats.canlaugh_successful_barters = barter_success_count() + 1

    if type(check_for_unlock) == "function" then
        check_for_unlock({ type = "canlaugh_successful_barter" })
    end

    if G and type(G.save_progress) == "function" then
        G:save_progress()
    end
end

if BT and type(BT.start) == "function" and not CL.magpies_eye_barter_start_hook_installed then
    CL.magpies_eye_barter_start_hook_installed = true
    local start_barter_ref = BT.start

    function BT.start(...)
        BT.magpies_eye_barter_recorded = nil
        return start_barter_ref(...)
    end
end

if BT and type(BT.enter_reward_phase) == "function" and not CL.magpies_eye_barter_success_hook_installed then
    CL.magpies_eye_barter_success_hook_installed = true
    local enter_reward_phase_ref = BT.enter_reward_phase

    function BT.enter_reward_phase(...)
        if BT.active and not BT.magpies_eye_barter_recorded then
            BT.magpies_eye_barter_recorded = true
            record_successful_barter()
        end

        return enter_reward_phase_ref(...)
    end
end

if BT then
    BT.register_trial_count_modifier("magpies_eye", function()
        return voucher_used("v_canlaugh_magpies_eye") and 1 or 0
    end)

    BT.register_duplicate_trial_modifier("magicians_eye", function()
        return voucher_used("v_canlaugh_magicians_eye")
    end)

    BT.register_mercy_modifier("magicians_eye", function()
        return voucher_used("v_canlaugh_magicians_eye")
    end)
end

SMODS.Atlas({
    key = "magpies_eye",
    path = "magpies_eye.png",
    px = 71,
    py = 93,
})

SMODS.Atlas({
    key = "magicians_eye",
    path = "magicians_eye.png",
    px = 71,
    py = 93,
})

SMODS.Voucher({
    key = "magpies_eye",
    name = "Magpie's Eye",
    atlas = "magpies_eye",
    pos = { x = 0, y = 0 },
    order = 32,
    cost = 10,
    unlocked = true,
    available = true,
    loc_txt = {
        name = "Magpie's Eye",
        text = {
            "{C:attention}+1{} hand size",
            "Bartering may contain",
            "{C:attention}1{} additional Trial",
        },
    },
    redeem = function()
        if G and G.hand then
            G.hand:change_size(1)
        end
    end,
})

SMODS.Voucher({
    key = "magicians_eye",
    name = "Magician's Eye",
    atlas = "magicians_eye",
    pos = { x = 0, y = 0 },
    order = 33,
    cost = 10,
    requires = { "v_canlaugh_magpies_eye" },
    unlocked = false,
    available = true,
    loc_txt = {
        name = "Magician's Eye",
        text = {
            "Bartering may contain",
            "duplicate Trials",
            "All Booster Packs provide mercy",
        },
        unlock = {
            "Successfully barter",
            "{C:attention}15{} times",
            "{C:inactive}(#1#/#2#){}",
        },
    },
    locked_loc_vars = function()
        return { vars = { barter_success_count(), 15 } }
    end,
    check_for_unlock = function(self, args)
        return args
            and args.type == "canlaugh_successful_barter"
            and barter_success_count() >= 15
    end,
})
