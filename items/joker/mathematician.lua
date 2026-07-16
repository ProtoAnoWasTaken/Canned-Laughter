SMODS.Atlas({
    key = "mathematician",
    path = "mathematician.png",
    px = 69,
    py = 93,
})

local MATHEMATICIAN_CHIPS = {
    [11] = 11,
    [12] = 12,
    [13] = 13,
    [14] = 14,
}

local CL = rawget(_G, "CannedLaughter") or {}
_G.CannedLaughter = CL

CL.mathematician_state = CL.mathematician_state or {
    defaults = setmetatable({}, { __mode = "k" }),
}

local MATHEMATICIAN_KEY = "j_canlaugh_mathematician"

local function mathematician_is_active(ignore_card)
    for _, joker in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local center = joker and joker.config and joker.config.center

        if joker ~= ignore_card
            and not joker.debuff
            and not joker.getting_sliced
            and center
            and (center.key == MATHEMATICIAN_KEY or center.original_key == "mathematician")
        then
            return true
        end
    end

    return false
end

local function mathematician_can_adjust(playing_card)
    local adjusted_chips = playing_card and MATHEMATICIAN_CHIPS[playing_card:get_id()]

    return adjusted_chips
        and playing_card.ability
        and not playing_card.ability.extra_enhancement
        and playing_card.ability.effect ~= "Stone Card"
        and not (playing_card.config and playing_card.config.center and playing_card.config.center.replace_base_card)
end

local function mathematician_natural_perma_bonus(playing_card)
    local harlequin_defaults = CL.harlequin_state
        and CL.harlequin_state.defaults
        and CL.harlequin_state.defaults[playing_card]

    if harlequin_defaults then
        return harlequin_defaults.perma_bonus
    end

    return (playing_card.ability.perma_bonus or 0)
        - (playing_card.ability.canlaugh_mathematician_bonus or 0)
end

local function restore_mathematician_card(playing_card, defaults)
    if not playing_card.ability then
        return
    end

    playing_card.ability.perma_bonus = defaults.perma_bonus
    playing_card.ability.canlaugh_mathematician_bonus = nil
end

function CL.refresh_mathematician_state(ignore_card)
    local state = CL.mathematician_state
    local active = mathematician_is_active(ignore_card)
    local adjusted_cards = {}

    for _, playing_card in ipairs((G and G.playing_cards) or {}) do
        if mathematician_can_adjust(playing_card) then
            adjusted_cards[playing_card] = true
        end
    end

    for playing_card, defaults in pairs(state.defaults) do
        if defaults.nominal_chips then
            if playing_card.base and playing_card:get_id() == defaults.id then
                playing_card.base.nominal = defaults.nominal_chips
            end

            state.defaults[playing_card] = nil
        elseif not adjusted_cards[playing_card] or not active then
            restore_mathematician_card(playing_card, defaults)
            state.defaults[playing_card] = nil
        end
    end

    if active then
        for playing_card in pairs(adjusted_cards) do
            local defaults = state.defaults[playing_card]

            if not defaults or defaults.id ~= playing_card:get_id() then
                if defaults then
                    restore_mathematician_card(playing_card, defaults)
                end

                defaults = {
                    id = playing_card:get_id(),
                    perma_bonus = mathematician_natural_perma_bonus(playing_card),
                }
                state.defaults[playing_card] = defaults
            end

            local adjustment = MATHEMATICIAN_CHIPS[playing_card:get_id()] - playing_card.base.nominal
            playing_card.ability.canlaugh_mathematician_bonus = adjustment
            playing_card.ability.perma_bonus = defaults.perma_bonus + adjustment
        end
    end

    state.active = active
    state.card_count = #(G and G.playing_cards or {})
    state.dirty = false

    if CL.refresh_harlequin_state then
        CL.refresh_harlequin_state()
    end
end

function CL.mark_mathematician_state_dirty()
    CL.mathematician_state.dirty = true
end

function CL.ensure_mathematician_state_current(ignore_card)
    local state = CL.mathematician_state
    local card_count = #(G and G.playing_cards or {})

    if state.dirty
        or state.card_count ~= card_count
        or state.active ~= mathematician_is_active(ignore_card)
    then
        CL.refresh_mathematician_state(ignore_card)
    end
end

if Card and type(Card.set_base) == "function" and not CL.mathematician_base_hook_installed then
    CL.mathematician_base_hook_installed = true
    local set_base_ref = Card.set_base

    function Card:set_base(...)
        local results = { set_base_ref(self, ...) }
        CL.mark_mathematician_state_dirty()
        return unpack(results)
    end
end

if Card and type(Card.set_ability) == "function" and not CL.mathematician_ability_hook_installed then
    CL.mathematician_ability_hook_installed = true
    local set_ability_ref = Card.set_ability

    function Card:set_ability(...)
        local results = { set_ability_ref(self, ...) }
        CL.mark_mathematician_state_dirty()
        return unpack(results)
    end
end

SMODS.Joker({
    key = "mathematician",
    name = "Mathematician",
    atlas = "mathematician",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    loc_txt = {
        name = "Mathematician",
        text = {
            "{C:attention}Face cards{} and {C:attention}Aces{}",
            "have been adjusted for linearity",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    add_to_deck = function(self, card, from_debuff)
        CL.refresh_mathematician_state()
    end,
    remove_from_deck = function(self, card, from_debuff)
        CL.refresh_mathematician_state(card)
    end,
    update = function(self, card, dt)
        CL.ensure_mathematician_state_current()
    end,
    calculate = function(self, card, context)
        CL.ensure_mathematician_state_current()
    end,
})
