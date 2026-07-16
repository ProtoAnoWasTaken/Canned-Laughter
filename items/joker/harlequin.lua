local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.harlequin_state = CL.harlequin_state or {
    defaults = setmetatable({}, { __mode = "k" }),
}

local HARLEQUIN_KEY = "j_canlaugh_harlequin"
local ABILITY_STAT_FIELDS = { "bonus", "mult", "x_mult" }
local EDITION_STAT_FIELDS = { "chips", "mult", "x_mult" }
local STANDARD_EDITION_FIELDS = {
    e_foil = "chips",
    e_holo = "mult",
    e_polychrome = "x_mult",
}

local function harlequin_is_active(ignore_card)
    for _, joker in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local center = joker and joker.config and joker.config.center

        if joker ~= ignore_card
            and not joker.getting_sliced
            and center
            and center.key == HARLEQUIN_KEY
        then
            return true
        end
    end

    return false
end

local function harlequin_signature(ignore_card)
    local signature = harlequin_is_active(ignore_card) and 1 or 0

    for index, playing_card in ipairs((G and G.playing_cards) or {}) do
        local base = playing_card.base or {}
        local is_face = playing_card.is_face and playing_card:is_face(true)

        if is_face then
            signature = signature * 131 + index
            signature = signature * 17 + (base.id or 0)
        end
    end

    return signature
end

local function harlequin_scaled_value(field, value)
    if field == "x_mult" then
        return 1 + (value - 1) * 0.5
    end

    return value * 0.5
end

local function capture_harlequin_defaults(playing_card)
    local defaults = CL.harlequin_state.defaults[playing_card]

    if defaults then
        return defaults
    end

    defaults = {
        perma_bonus = playing_card.ability and playing_card.ability.perma_bonus or 0,
        ability = {},
        edition = {},
    }

    for _, field in ipairs(ABILITY_STAT_FIELDS) do
        defaults.ability[field] = playing_card.ability and playing_card.ability[field]
    end

    for _, field in ipairs(EDITION_STAT_FIELDS) do
        defaults.edition[field] = playing_card.edition and playing_card.edition[field]
    end

    CL.harlequin_state.defaults[playing_card] = defaults
    return defaults
end

local function restore_harlequin_card(playing_card, defaults)
    if not defaults then
        return
    end

    if playing_card.ability then
        playing_card.ability.perma_bonus = defaults.perma_bonus

        for _, field in ipairs(ABILITY_STAT_FIELDS) do
            playing_card.ability[field] = defaults.ability[field]
        end
    end

    if playing_card.edition then
        for _, field in ipairs(EDITION_STAT_FIELDS) do
            playing_card.edition[field] = defaults.edition[field]
        end
    end
end

local function apply_harlequin_card(playing_card, defaults)
    if not (playing_card and playing_card.ability) then
        return
    end

    local base_chips = playing_card.base and playing_card.base.nominal or 0
    playing_card.ability.perma_bonus = defaults.perma_bonus - base_chips * 0.5

    for _, field in ipairs(ABILITY_STAT_FIELDS) do
        local value = defaults.ability[field]

        if value ~= nil then
            playing_card.ability[field] = harlequin_scaled_value(field, value)
        end
    end

    if playing_card.edition then
        for _, field in ipairs(EDITION_STAT_FIELDS) do
            local value = defaults.edition[field]

            if value ~= nil then
                playing_card.edition[field] = harlequin_scaled_value(field, value)
            end
        end
    end
end

function CL.refresh_harlequin_state(ignore_card)
    local state = CL.harlequin_state
    local active = harlequin_is_active(ignore_card)
    local face_cards = {}

    for _, playing_card in ipairs((G and G.playing_cards) or {}) do
        if playing_card.is_face and playing_card:is_face(true) then
            face_cards[playing_card] = true
        end
    end

    for playing_card, defaults in pairs(state.defaults) do
        if not face_cards[playing_card] or not active then
            restore_harlequin_card(playing_card, defaults)
            state.defaults[playing_card] = nil
        end
    end

    if active then
        for playing_card in pairs(face_cards) do
            local defaults = capture_harlequin_defaults(playing_card)
            apply_harlequin_card(playing_card, defaults)
        end
    end

    state.signature = harlequin_signature(ignore_card)
end

function CL.ensure_harlequin_state_current(ignore_card)
    if CL.harlequin_state.signature ~= harlequin_signature(ignore_card) then
        CL.refresh_harlequin_state(ignore_card)
    end
end

function CL.harlequin_affects_card(card)
    CL.ensure_harlequin_state_current()
    return CL.harlequin_state.defaults[card] ~= nil
end

function CL.configure_harlequin_edition_tooltips()
    for center_key, field in pairs(STANDARD_EDITION_FIELDS) do
        local center = G and G.P_CENTERS and G.P_CENTERS[center_key]

        if center and not center.canlaugh_harlequin_loc_vars then
            center.canlaugh_harlequin_loc_vars = true
            local loc_vars_ref = center.loc_vars
            local edition_field = field

            center.loc_vars = function(self, info_queue, card)
                local result = loc_vars_ref and loc_vars_ref(self, info_queue, card) or nil

                if CL.harlequin_affects_card(card) and card.edition and card.edition[edition_field] ~= nil then
                    result = result or {}
                    result.vars = { card.edition[edition_field] }
                end

                return result
            end
        end
    end
end

SMODS.Atlas({
    key = "harlequin",
    path = "harlequin.png",
    px = 69,
    py = 93,
})

if Card and type(Card.is_suit) == "function" and not CL.harlequin_suit_hook_installed then
    CL.harlequin_suit_hook_installed = true
    local canlaugh_harlequin_is_suit_ref = Card.is_suit

    function Card:is_suit(suit, bypass_debuff, flush_calc)
        if harlequin_is_active() and self:is_face(true) then
            return true
        end

        return canlaugh_harlequin_is_suit_ref(self, suit, bypass_debuff, flush_calc)
    end
end

SMODS.Joker({
    key = "harlequin",
    name = "Harlequin",
    atlas = "harlequin",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    loc_txt = {
        name = "Harlequin",
        text = {
            "All face cards are considered",
            "{C:attention}Wild{} but are {C:attention}half as effective{}",
            "{C:attention}+1{} Trial option",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    add_to_deck = function(self, card, from_debuff)
        CL.configure_harlequin_edition_tooltips()
        CL.refresh_harlequin_state()
    end,
    remove_from_deck = function(self, card, from_debuff)
        CL.refresh_harlequin_state(card)
    end,
    update = function(self, card, dt)
        CL.configure_harlequin_edition_tooltips()
        CL.ensure_harlequin_state_current()
    end,
    calculate = function(self, card, context)
        CL.ensure_harlequin_state_current()
    end,
})
