local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "rosemary",
    path = "rosemary.png",
    px = 69,
    py = 93,
})

local function canlaugh_rosemary_card()
    for _, card in ipairs(SMODS.find_card("j_canlaugh_rosemary") or {}) do
        if not card.debuff and not card.getting_sliced then
            return card
        end
    end
end

local function canlaugh_rosemary_shield_active()
    local shield = G and G.GAME and G.GAME.canlaugh_rosemary_shield
    return shield and shield.card and not shield.card.removed and not shield.card.getting_sliced
end

local function canlaugh_rosemary_is_spectral(card)
    local center = card and card.config and card.config.center
    return (card and card.ability and card.ability.set == "Spectral")
        or (center and center.set == "Spectral")
end

local function canlaugh_rosemary_has_negative_effect(card)
    local center = card and card.config and card.config.center
    local key = center and center.key

    if key == "c_wraith" then
        return (G.GAME and G.GAME.dollars or 0) > 0
    end

    if key == "c_familiar"
        or key == "c_grim"
        or key == "c_incantation"
        or key == "c_immolate"
    then
        return #(G.hand and G.hand.cards or {}) > 0
    end

    if key == "c_ouija" or key == "c_ectoplasm" then
        return true
    end

    if key == "c_ankh" or key == "c_hex" then
        local jokers = G.jokers and G.jokers.cards or {}
        return #jokers > 1
    end

    return false
end

local function canlaugh_rosemary_expire(card)
    if not (card and not card.getting_sliced) then
        return
    end

    CL.rosemary_expiring = true
    SMODS.destroy_cards(card, nil, true, true)
    CL.rosemary_expiring = nil
end

local function canlaugh_rosemary_activate(source)
    local card = canlaugh_rosemary_card()
    local extra = card and card.ability and card.ability.extra
    if not (card and extra and extra.actions > 0) then
        return
    end

    extra.actions = extra.actions - 1
    G.GAME.canlaugh_rosemary_shield = {
        card = card,
        source = source,
    }
    card_eval_status_text(card, "extra", nil, nil, nil, {
        message = "Blessed!",
        colour = G.C.FILTER,
    })

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 5,
        func = function()
            if G and G.GAME then
                G.GAME.canlaugh_rosemary_shield = nil
            end
            if extra.actions <= 0 then
                canlaugh_rosemary_expire(card)
            end
            return true
        end,
    }))
end

if Card and type(Card.use_consumeable) == "function" and not CL.rosemary_spectral_hook_installed then
    CL.rosemary_spectral_hook_installed = true
    local use_consumeable_ref = Card.use_consumeable

    function Card:use_consumeable(area, copier, ...)
        if canlaugh_rosemary_is_spectral(self)
            and canlaugh_rosemary_has_negative_effect(self)
            and not canlaugh_rosemary_shield_active()
        then
            canlaugh_rosemary_activate(self)
        end

        return use_consumeable_ref(self, area, copier, ...)
    end
end

if Card and type(Card.start_dissolve) == "function" and not CL.rosemary_dissolve_hook_installed then
    CL.rosemary_dissolve_hook_installed = true
    local start_dissolve_ref = Card.start_dissolve

    function Card:start_dissolve(...)
        local shield = G and G.GAME and G.GAME.canlaugh_rosemary_shield
        if shield
            and shield.card
            and self ~= shield.card
            and self ~= shield.source
            and not CL.rosemary_expiring
        then
            return
        end

        return start_dissolve_ref(self, ...)
    end
end

if SMODS and type(SMODS.destroy_cards) == "function" and not CL.rosemary_destroy_hook_installed then
    CL.rosemary_destroy_hook_installed = true
    local destroy_cards_ref = SMODS.destroy_cards

    function SMODS.destroy_cards(cards, ...)
        if canlaugh_rosemary_shield_active() and not CL.rosemary_expiring then
            return
        end

        return destroy_cards_ref(cards, ...)
    end
end

if type(ease_dollars) == "function" and not CL.rosemary_money_hook_installed then
    CL.rosemary_money_hook_installed = true
    local ease_dollars_ref = ease_dollars

    function ease_dollars(mod, ...)
        if canlaugh_rosemary_shield_active() and type(mod) == "number" and mod < 0 then
            return
        end

        return ease_dollars_ref(mod, ...)
    end
end

if CardArea and type(CardArea.change_size) == "function" and not CL.rosemary_size_hook_installed then
    CL.rosemary_size_hook_installed = true
    local change_size_ref = CardArea.change_size

    function CardArea:change_size(mod, ...)
        if self == G.hand and canlaugh_rosemary_shield_active() and type(mod) == "number" and mod < 0 then
            return
        end

        return change_size_ref(self, mod, ...)
    end
end

SMODS.Joker({
    key = "rosemary",
    name = "Rosemary",
    atlas = "rosemary",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            actions = 1,
        },
    },
    loc_txt = {
        name = "Rosemary",
        text = {
            "Prevent the negative effects of",
            "{C:spectral}Spectral{} cards for {C:attention}#1# action{}",
            "{C:attention}+1{} action for each {C:attention}Boss Blind{}",
            "defeated while held",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return { vars = { extra.actions } }
    end,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    pools = {
        Food = true,
    },
    calculate = function(self, card, context)
        if context.end_of_round
            and context.beat_boss
            and context.main_eval
            and not context.blueprint
        then
            card.ability.extra.actions = card.ability.extra.actions + 1
            return {
                message = "+1 Action",
                colour = G.C.FILTER,
            }
        end
    end,
})
