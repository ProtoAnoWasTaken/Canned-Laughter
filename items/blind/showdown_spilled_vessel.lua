local CL = CannedLaughter

local SPILLED_VESSEL_ACHIEVEMENT = "canlaugh_spilled_vessel_defeated"
local DIONYSUS_KEY = "j_canlaugh_dionysus"

SMODS.Atlas({
    key = "showdown_spilled_vessel",
    path = "supershowdown_spilledvessel.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

local function spilled_vessel_profile()
    return G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
end

local function spilled_vessel_default_base(card)
    local suit = card.canlaugh_original_suit or card.base and card.base.suit
    local rank = card.canlaugh_original_rank or card.base and card.base.value
    local suit_data = suit and SMODS.Suits and SMODS.Suits[suit]
    local rank_data = rank and SMODS.Ranks and SMODS.Ranks[rank]

    if not (suit_data and rank_data and G.P_CARDS) then
        return nil
    end

    return G.P_CARDS[suit_data.card_key .. "_" .. rank_data.card_key]
end

local function reset_card_to_default(card)
    if not card or card.removed or card.destroyed then
        return
    end

    if type(CL.thaw_frozen) == "function" then
        CL.thaw_frozen(card)
    end

    local base = spilled_vessel_default_base(card)
    if base then
        card:set_base(base)
    end

    if card.set_edition then
        card:set_edition(nil, true, true)
    end

    if card.set_seal then
        card:set_seal(nil, true, true)
    end

    if card.set_ability and G.P_CENTERS.c_base then
        card:set_ability(G.P_CENTERS.c_base, nil, true)
    end

    card.canlaugh_original_suit = nil
    card.canlaugh_original_rank = nil
    card.canlaugh_suit_changed = nil
end

local function reset_deck_to_default()
    for _, card in ipairs(G.playing_cards or {}) do
        reset_card_to_default(card)
    end
end

function CL.grant_spilled_vessel_dionysus()
    if not (SMODS and type(SMODS.add_card) == "function" and G and G.P_CENTERS and G.P_CENTERS[DIONYSUS_KEY]) then
        return false
    end

    SMODS.add_card({
        key = DIONYSUS_KEY,
        area = G.jokers,
        bypass_discovery_center = true,
        allow_duplicates = true,
    })
    return true
end

local function grant_spilled_vessel_reward()
    local profile = spilled_vessel_profile()
    if not profile or profile.canlaugh_spilled_vessel_defeated then
        return
    end

    profile.canlaugh_spilled_vessel_defeated = true

    if type(save_settings) == "function" then
        save_settings()
    end

    if type(check_for_unlock) == "function" then
        check_for_unlock({ type = SPILLED_VESSEL_ACHIEVEMENT })
        check_for_unlock({ type = "ach_canlaugh_still_the_best_522_bce" })
    end

    CL.grant_spilled_vessel_dionysus()
end

CL.register_super_showdown_boss({
    key = "spilled_vessel",
    atlas = "showdown_spilled_vessel",
    boss_colour = HEX("8B71DF"),
    mult = 8,
    loc_txt = {
        name = "Spilled Vessel",
        text = {
            "Deck returns to default state",
        },
    },
    in_pool = function()
        return false
    end,
    set_blind = function()
        reset_deck_to_default()
    end,
    calculate = function(self, blind, context)
        if context and context.end_of_round and context.beat_boss then
            grant_spilled_vessel_reward()
        end
    end,
})
