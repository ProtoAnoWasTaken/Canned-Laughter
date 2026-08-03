local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local GLASS_CENTER_KEY = "m_glass"
local SPECIAL_AGENT_KEY = "j_canlaugh_special_agent"
local SPECIAL_AGENT_X_MULT = 1.25
local SPECIAL_AGENT_BREAK_ODDS = 10

CL.special_agent_glass_state = CL.special_agent_glass_state or {}

local function canlaugh_special_agent_is_active(ignore_card)
    if not (G and G.jokers and G.jokers.cards) then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center
        if joker ~= ignore_card and center and center.key == SPECIAL_AGENT_KEY and not joker.getting_sliced then
            return true
        end
    end

    return false
end

local function canlaugh_is_glass_card(card)
    if SMODS and type(SMODS.has_enhancement) == "function" then
        return SMODS.has_enhancement(card, GLASS_CENTER_KEY)
    end

    local center = card and card.config and card.config.center
    return center and center.key == GLASS_CENTER_KEY
end

local function canlaugh_refresh_special_agent_glass(ignore_card)
    local glass_center = G and G.P_CENTERS and G.P_CENTERS[GLASS_CENTER_KEY]
    if not glass_center or not glass_center.config then
        return
    end

    local state = CL.special_agent_glass_state
    if state.refresh_in_progress then
        return
    end

    state.refresh_in_progress = true

    if not state.defaults then
        state.defaults = {
            Xmult = glass_center.config.Xmult,
            x_mult = glass_center.config.x_mult,
            extra = glass_center.config.extra,
        }
    end

    local active = canlaugh_special_agent_is_active(ignore_card)
    local defaults = state.defaults
    glass_center.config.Xmult = active and SPECIAL_AGENT_X_MULT or defaults.Xmult
    glass_center.config.x_mult = active and SPECIAL_AGENT_X_MULT or defaults.x_mult
    glass_center.config.extra = active and SPECIAL_AGENT_BREAK_ODDS or defaults.extra
    state.active = active

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card.ability and canlaugh_is_glass_card(playing_card) then
            playing_card.ability.x_mult = glass_center.config.Xmult or glass_center.config.x_mult or 1
            playing_card.ability.extra = glass_center.config.extra

            if G.GAME and G.GAME.blind then
                G.GAME.blind:debuff_card(playing_card)
            end
        end
    end

    state.refresh_in_progress = false
end

local function canlaugh_ensure_special_agent_glass_current(ignore_card)
    local state = CL.special_agent_glass_state
    if state.refresh_in_progress then
        return
    end

    if state.active ~= canlaugh_special_agent_is_active(ignore_card) then
        canlaugh_refresh_special_agent_glass(ignore_card)
    end
end

SMODS.Atlas({
    key = "special_agent",
    path = "special_agent.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "special_agent",
    name = "Special Agent",
    atlas = "special_agent",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    loc_txt = {
        name = "Special Agent",
        text = {
            "{C:attention,T:m_glass}Glass Cards{} are weaker",
            "but less likely to break",
        },
    },
    loc_vars = function(self, info_queue, card)
        CL.add_unique_tooltip(info_queue, G.P_CENTERS.m_glass, card)
        CL.add_unique_tooltip(info_queue, {
            key = "canlaugh_card_conceptualizer",
            set = "Other",
            vars = { "ChasetheDog" },
        }, card)
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    add_to_deck = function(self, card, from_debuff)
        canlaugh_refresh_special_agent_glass()
    end,
    remove_from_deck = function(self, card, from_debuff)
        canlaugh_refresh_special_agent_glass(card)
    end,
    update = function(self, card, dt)
        canlaugh_ensure_special_agent_glass_current()
    end,
    calculate = function(self, card, context)
        if context.fix_probability and context.identifier == "glass" and not context.blueprint then
            return {
                denominator = SPECIAL_AGENT_BREAK_ODDS,
            }
        end
    end,
})
