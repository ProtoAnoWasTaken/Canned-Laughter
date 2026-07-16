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
        and not playing_card.config.center.replace_base_card
end

local function mathematician_signature(ignore_card)
    local signature = mathematician_is_active(ignore_card) and 1 or 0

    for index, playing_card in ipairs((G and G.playing_cards) or {}) do
        if mathematician_can_adjust(playing_card) then
            signature = signature * 131 + index
            signature = signature * 17 + playing_card:get_id()
        end
    end

    return signature
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
        if not adjusted_cards[playing_card] or not active then
            if playing_card.base and playing_card:get_id() == defaults.id then
                playing_card.base.nominal = defaults.nominal_chips
            end
            state.defaults[playing_card] = nil
        end
    end

    if active then
        for playing_card in pairs(adjusted_cards) do
            local defaults = state.defaults[playing_card]

            if not defaults or defaults.id ~= playing_card:get_id() then
                state.defaults[playing_card] = {
                    id = playing_card:get_id(),
                    nominal_chips = playing_card.base.nominal,
                }
            end

            playing_card.base.nominal = MATHEMATICIAN_CHIPS[playing_card:get_id()]
        end
    end

    state.signature = mathematician_signature(ignore_card)

    if CL.refresh_harlequin_state then
        CL.refresh_harlequin_state()
    end
end

function CL.ensure_mathematician_state_current(ignore_card)
    if CL.mathematician_state.signature ~= mathematician_signature(ignore_card) then
        CL.refresh_mathematician_state(ignore_card)
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
