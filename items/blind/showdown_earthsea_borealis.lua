local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.earthsea_borealis_config = CL.earthsea_borealis_config or {}
CL.earthsea_borealis_config.accepted_blinds = CL.earthsea_borealis_config.accepted_blinds or {}

function CL.register_earthsea_borealis_blind(key)
    if type(key) ~= "string" then
        return false
    end

    CL.earthsea_borealis_config.accepted_blinds[key] = true
    return true
end

local earthsea_pair_conflicts = {
    bl_canlaugh_horse = { bl_canlaugh_flare = true },
    bl_canlaugh_flare = { bl_canlaugh_horse = true },
    bl_canlaugh_exchange = { bl_canlaugh_land = true },
    bl_canlaugh_land = { bl_canlaugh_exchange = true },
}

local earthsea_hand_restrictions = {
    bl_ox = true,
    bl_canlaugh_ure = true,
    bl_canlaugh_revel = true,
}

local function conflicts_with_inherited(center, inherited)
    local key = center.key
    local pair_conflicts = earthsea_pair_conflicts[key]

    for _, other in ipairs(inherited) do
        if pair_conflicts and pair_conflicts[other.key] then
            return true
        end

        if earthsea_hand_restrictions[key] and earthsea_hand_restrictions[other.key] then
            return true
        end
    end

    return false
end

SMODS.Atlas({
    key = "showdown_earthsea_borealis",
    path = "supershowdown_earthsea_borealis.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

local function earthsea_profile()
    return G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
end

local function earthsea_unlocked()
    local profile = earthsea_profile()
    local earned = G and G.SETTINGS and G.SETTINGS.ACHIEVEMENTS_EARNED

    return profile and profile.canlaugh_earthsea_borealis_defeated
        or earned and earned.canlaugh_still_the_best_2026
end

local function inherited_blinds()
    local result = {}
    local history = G and G.GAME and G.GAME.canlaugh_boss_history or {}

    for _, key in ipairs(history) do
        local center = G.P_BLINDS and G.P_BLINDS[key]
        local is_vanilla = center and not center.mod
        local is_canned_laughter = center and center.canlaugh_boss
        local is_registered = CL.earthsea_borealis_config.accepted_blinds[key]
            or center and center.canlaugh_earthsea_compatible

        if center
            and center.boss
            and center.key ~= "bl_canlaugh_earthsea_borealis"
            and (is_vanilla or is_canned_laughter or is_registered)
            and not conflicts_with_inherited(center, result)
        then
            result[#result + 1] = center
        end
    end

    return result
end

local function each_inherited(callback)
    for _, center in ipairs(inherited_blinds()) do
        callback(center)
    end
end

local function earthsea_standard_resource_adjustment(center, hands_left, discards_left)
    if center.key == "bl_water" then
        return 0, -discards_left
    end

    if center.key == "bl_needle" then
        local hands = G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.hands or hands_left
        return -(hands - 1), 0
    end

    return 0, 0
end

local function earthsea_capture_resource_adjustments(callback)
    local current_round = G and G.GAME and G.GAME.current_round
    if not current_round then
        callback()
        return 0, 0
    end

    local hands_left = current_round.hands_left or 0
    local discards_left = current_round.discards_left or 0
    local captured_hands = 0
    local captured_discards = 0
    local ease_hands_played_ref = ease_hands_played
    local ease_discard_ref = ease_discard

    if type(ease_hands_played_ref) == "function" then
        ease_hands_played = function(amount)
            captured_hands = captured_hands + (amount or 0)
        end
    end

    if type(ease_discard_ref) == "function" then
        ease_discard = function(amount)
            captured_discards = captured_discards + (amount or 0)
        end
    end

    local ok, err = pcall(callback)
    ease_hands_played = ease_hands_played_ref
    ease_discard = ease_discard_ref

    local direct_hands = (current_round.hands_left or hands_left) - hands_left
    local direct_discards = (current_round.discards_left or discards_left) - discards_left
    current_round.hands_left = hands_left
    current_round.discards_left = discards_left

    if not ok and type(sendErrorMessage) == "function" then
        sendErrorMessage("[Canned Laughter] Earthsea Borealis failed to apply an inherited Blind: " .. tostring(err))
    end

    return captured_hands + direct_hands, captured_discards + direct_discards
end

local function earthsea_apply_average_resource_adjustments(hands_delta, discards_delta, count)
    local current_round = G and G.GAME and G.GAME.current_round
    if not current_round or count <= 0 then
        return
    end

    local hands_left = current_round.hands_left or 0
    local discards_left = current_round.discards_left or 0
    local target_hands = math.max(1, math.floor(hands_left + hands_delta / count))
    local target_discards = math.max(0, math.floor(discards_left + discards_delta / count))
    local hands_adjustment = target_hands - hands_left
    local discards_adjustment = target_discards - discards_left

    if hands_adjustment ~= 0 then
        if type(ease_hands_played) == "function" then
            ease_hands_played(hands_adjustment)
        else
            current_round.hands_left = target_hands
        end
    end

    if discards_adjustment ~= 0 then
        if type(ease_discard) == "function" then
            ease_discard(discards_adjustment)
        else
            current_round.discards_left = target_discards
        end
    end

    return hands_adjustment, discards_adjustment
end

local function earthsea_set_inherited_blinds(base_mult)
    local blind = G and G.GAME and G.GAME.blind
    local inherited = inherited_blinds()
    if not blind then
        return
    end

    local total_mult = base_mult
    for _, center in ipairs(inherited) do
        total_mult = total_mult + (tonumber(center.mult) or 0)
    end

    blind.mult = total_mult
    blind.chips = get_blind_amount(G.GAME.round_resets.ante) * total_mult * G.GAME.starting_params.ante_scaling
    blind.chip_text = number_format(blind.chips)
    blind.canlaugh_fortune_goal_bonuses = nil

    local hands_left = G.GAME.current_round and G.GAME.current_round.hands_left or 0
    local discards_left = G.GAME.current_round and G.GAME.current_round.discards_left or 0
    local hands_delta = 0
    local discards_delta = 0

    for _, center in ipairs(inherited) do
        local standard_hands, standard_discards = earthsea_standard_resource_adjustment(center, hands_left, discards_left)
        hands_delta = hands_delta + standard_hands
        discards_delta = discards_delta + standard_discards

        if type(center.set_blind) == "function" then
            local custom_hands, custom_discards = earthsea_capture_resource_adjustments(function()
                center:set_blind()
            end)
            hands_delta = hands_delta + custom_hands
            discards_delta = discards_delta + custom_discards
        end
    end

    local hands_adjustment, discards_adjustment = earthsea_apply_average_resource_adjustments(
        hands_delta,
        discards_delta,
        #inherited
    )
    blind.canlaugh_earthsea_hands_adjustment = hands_adjustment
    blind.canlaugh_earthsea_discards_adjustment = discards_adjustment
    blind.chip_text = number_format(blind.chips)
end

local function earthsea_restore_resource_adjustments()
    local blind = G and G.GAME and G.GAME.blind
    local current_round = G and G.GAME and G.GAME.current_round
    if not blind or not current_round then
        return
    end

    local hands_adjustment = blind.canlaugh_earthsea_hands_adjustment or 0
    local discards_adjustment = blind.canlaugh_earthsea_discards_adjustment or 0

    if hands_adjustment ~= 0 then
        if type(ease_hands_played) == "function" then
            ease_hands_played(-hands_adjustment)
        else
            current_round.hands_left = current_round.hands_left - hands_adjustment
        end
    end

    if discards_adjustment ~= 0 then
        if type(ease_discard) == "function" then
            ease_discard(-discards_adjustment)
        else
            current_round.discards_left = current_round.discards_left - discards_adjustment
        end
    end

    blind.canlaugh_earthsea_hands_adjustment = nil
    blind.canlaugh_earthsea_discards_adjustment = nil
end

local function grant_author_avatar()
    local profile = earthsea_profile()
    if not profile or profile.canlaugh_earthsea_borealis_defeated then
        return
    end

    profile.canlaugh_earthsea_borealis_defeated = true
    if type(save_settings) == "function" then
        save_settings()
    end
    if type(check_for_unlock) == "function" then
        check_for_unlock({ type = "canlaugh_earthsea_borealis_defeated" })
    end
    if SMODS and type(SMODS.add_card) == "function" then
        SMODS.add_card({
            key = "j_canlaugh_author_avatar",
            area = G.jokers,
            bypass_discovery_center = true,
            allow_duplicates = true,
        })
    end
end

SMODS.Blind({
    key = "earthsea_borealis",
    atlas = "showdown_earthsea_borealis",
    pos = { x = 0, y = 0 },
    boss = { min = 1, max = 1000000, showdown = true },
    canlaugh_boss = true,
    canlaugh_showdown = true,
    boss_colour = HEX("4569A8"),
    mult = 4,
    discovered = false,
    loc_txt = {
        name = "Earthsea Borealis",
        text = {
            "Inherits the properties of",
            "the last {C:attention}6{} Boss Blinds",
        },
    },
    in_pool = function(self)
        return earthsea_unlocked()
    end,
    set_blind = function(self)
        G.GAME.canlaugh_earthsea_inherited_bosses = {}
        each_inherited(function(center)
            G.GAME.canlaugh_earthsea_inherited_bosses[center.key] = true
        end)
        earthsea_set_inherited_blinds(self.mult)
    end,
    disable = function(self)
        earthsea_restore_resource_adjustments()
        each_inherited(function(center)
            if type(center.disable) == "function" then
                center:disable()
            end
        end)
    end,
    defeat = function(self)
        each_inherited(function(center)
            if type(center.defeat) == "function" then
                center:defeat()
            end
        end)
        G.GAME.canlaugh_earthsea_inherited_bosses = nil
    end,
    recalc_debuff = function(self, card, from_blind)
        local debuffed = false
        each_inherited(function(center)
            if type(center.recalc_debuff) == "function" and center:recalc_debuff(card, from_blind) then
                debuffed = true
            end
        end)
        return debuffed
    end,
    debuff_hand = function(self, cards, hand, handname, check)
        local debuffed = false
        each_inherited(function(center)
            if type(center.debuff_hand) == "function" and center:debuff_hand(cards, hand, handname, check) then
                debuffed = true
            end
        end)
        return debuffed
    end,
    stay_flipped = function(self, area, card, from_area)
        local flipped = false
        each_inherited(function(center)
            if type(center.stay_flipped) == "function" and center:stay_flipped(area, card, from_area) then
                flipped = true
            end
        end)
        return flipped
    end,
    press_play = function(self)
        each_inherited(function(center)
            if type(center.press_play) == "function" then
                center:press_play()
            end
        end)
    end,
    drawn_to_hand = function(self)
        each_inherited(function(center)
            if type(center.drawn_to_hand) == "function" then
                center:drawn_to_hand()
            end
        end)
    end,
    modify_hand = function(self, cards, poker_hands, handname, mult, chips)
        local current_mult = mult
        local current_chips = chips
        each_inherited(function(center)
            if type(center.modify_hand) == "function" then
                local next_mult, next_chips = center:modify_hand(cards, poker_hands, handname, current_mult, current_chips)
                current_mult = next_mult or current_mult
                current_chips = next_chips or current_chips
            end
        end)
        return current_mult, current_chips
    end,
    calculate = function(self, blind, context)
        each_inherited(function(center)
            if type(center.calculate) == "function" then
                center:calculate(blind, context)
            end
        end)
        if context and context.end_of_round and context.beat_boss then
            grant_author_avatar()
        end
    end,
})
