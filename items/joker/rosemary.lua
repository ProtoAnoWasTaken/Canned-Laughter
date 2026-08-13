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

local function canlaugh_rosemary_shield_source_is(key)
    local shield = G and G.GAME and G.GAME.canlaugh_rosemary_shield
    return canlaugh_rosemary_shield_active() and shield.source_key == key
end

local function canlaugh_rosemary_is_spectral(card)
    local center = card and card.config and card.config.center
    return (card and card.ability and card.ability.set == "Spectral")
        or (center and center.set == "Spectral")
end

local function canlaugh_rosemary_card_key(card)
    local center = card and card.config and card.config.center
    return center and center.key
end

local function canlaugh_rosemary_has_non_eternal_joker()
    for _, joker in ipairs(G.jokers and G.jokers.cards or {}) do
        local is_eternal = type(SMODS.is_eternal) == "function"
            and SMODS.is_eternal(joker)
            or (joker.ability and joker.ability.eternal)

        if not is_eternal then
            return true
        end
    end

    return false
end

local function canlaugh_rosemary_has_hand_levels()
    for _, hand_name in ipairs(G.handlist or {}) do
        local hand = G.GAME and G.GAME.hands and G.GAME.hands[hand_name]
        local level = hand and hand.level
        local number_level = tonumber(level)

        if not number_level and type(to_number) == "function" then
            number_level = to_number(level)
        end

        if number_level and number_level > 1 then
            return true
        end
    end

    return false
end

local function canlaugh_rosemary_has_negative_effect(card)
    local key = canlaugh_rosemary_card_key(card)

    if key == "c_wraith" then
        return (G.GAME and G.GAME.dollars or 0) > 0
    end

    if key == "c_canlaugh_tessellation" then
        return true
    end

    if key == "c_familiar"
        or key == "c_grim"
        or key == "c_incantation"
        or key == "c_immolate"
        or key == "c_canlaugh_equivalence"
        or key == "c_canlaugh_cryomancy"
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

    if key == "c_cry_lock" or key == "c_cry_adversary" then
        return #(G.jokers and G.jokers.cards or {}) > 0
    end

    if key == "c_cry_vacuum" then
        return #(G.hand and G.hand.cards or {}) > 0
    end

    if key == "c_cry_trade" then
        return #(G.vouchers and G.vouchers.cards or {}) > 0
    end

    if key == "c_cry_analog" or key == "c_cry_summoning" or key == "c_cry_gateway" then
        return canlaugh_rosemary_has_non_eternal_joker()
    end

    if key == "c_cry_white_hole" or key == "c_cry_white_hole2" then
        return canlaugh_rosemary_has_hand_levels()
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

local function canlaugh_rosemary_clear_sliced(cards)
    if type(cards) ~= "table" then
        return
    end

    if cards.config then
        cards.getting_sliced = nil
        return
    end

    for _, card in ipairs(cards) do
        if card then
            card.getting_sliced = nil
        end
    end
end

local function canlaugh_rosemary_activate(source)
    local card = canlaugh_rosemary_card()
    local extra = card and card.ability and card.ability.extra
    if not (card and extra and extra.actions > 0) then
        return
    end

    local source_key = canlaugh_rosemary_card_key(source)
    local action_cost = (source_key == "c_cry_white_hole" or source_key == "c_cry_white_hole2") and 4 or 1
    extra.actions = math.max(extra.actions - action_cost, 0)
    G.GAME.canlaugh_rosemary_shield = {
        card = card,
        source = source,
        source_key = source_key,
    }

    if source_key == "c_cry_adversary" then
        G.GAME.canlaugh_rosemary_shield.adversary_price_modifier = G.GAME.cry_shop_joker_price_modifier or 1
    end

    if source_key == "c_cry_lock" then
        G.GAME.canlaugh_rosemary_shield.lock_eternals = {}
        for _, joker in ipairs(G.jokers and G.jokers.cards or {}) do
            if joker.ability and joker.ability.eternal then
                G.GAME.canlaugh_rosemary_shield.lock_eternals[joker] = true
            end
        end
    end
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

    if source_key == "c_cry_lock" then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 4,
            func = function()
                local shield = G and G.GAME and G.GAME.canlaugh_rosemary_shield
                local lock_eternals = shield and shield.lock_eternals

                for _, joker in ipairs(G.jokers and G.jokers.cards or {}) do
                    if not (lock_eternals and lock_eternals[joker]) then
                        joker.ability.eternal = nil
                    end
                end

                return true
            end,
        }))
    end

    if source_key == "c_cry_adversary" then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 2,
            func = function()
                local shield = G and G.GAME and G.GAME.canlaugh_rosemary_shield
                if shield and shield.source_key == "c_cry_adversary" then
                    G.GAME.cry_shop_joker_price_modifier = shield.adversary_price_modifier
                end
                return true
            end,
        }))
    end
end

local function canlaugh_rosemary_install_trade_hooks()
    if Card and type(Card.unredeem) == "function" and not CL.rosemary_unredeem_hook_installed then
        CL.rosemary_unredeem_hook_installed = true
        local unredeem_ref = Card.unredeem

        function Card:unredeem(...)
            if canlaugh_rosemary_shield_source_is("c_cry_trade") then
                return
            end

            return unredeem_ref(self, ...)
        end
    end

    if Card and type(Card.unapply_to_run) == "function" and not CL.rosemary_unapply_voucher_hook_installed then
        CL.rosemary_unapply_voucher_hook_installed = true
        local unapply_to_run_ref = Card.unapply_to_run

        function Card:unapply_to_run(...)
            if canlaugh_rosemary_shield_source_is("c_cry_trade") then
                return
            end

            return unapply_to_run_ref(self, ...)
        end
    end
end

canlaugh_rosemary_install_trade_hooks()

if Card and type(Card.use_consumeable) == "function" and not CL.rosemary_spectral_hook_installed then
    CL.rosemary_spectral_hook_installed = true
    local use_consumeable_ref = Card.use_consumeable

    function Card:use_consumeable(area, copier, ...)
        canlaugh_rosemary_install_trade_hooks()
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
            if shield.source_key == "c_cry_trade" and self.area ~= G.vouchers then
                return start_dissolve_ref(self, ...)
            end

            self.getting_sliced = nil
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
            canlaugh_rosemary_clear_sliced(cards)
            return
        end

        return destroy_cards_ref(cards, ...)
    end
end

if Card and type(Card.set_ability) == "function" and not CL.rosemary_ability_hook_installed then
    CL.rosemary_ability_hook_installed = true
    local set_ability_ref = Card.set_ability

    function Card:set_ability(center, ...)
        if canlaugh_rosemary_shield_source_is("c_cry_vacuum") and center == G.P_CENTERS.c_base then
            return
        end

        return set_ability_ref(self, center, ...)
    end
end

if Card and type(Card.set_edition) == "function" and not CL.rosemary_edition_hook_installed then
    CL.rosemary_edition_hook_installed = true
    local set_edition_ref = Card.set_edition

    function Card:set_edition(edition, ...)
        if canlaugh_rosemary_shield_source_is("c_cry_vacuum") and edition == nil then
            return
        end

        return set_edition_ref(self, edition, ...)
    end
end

if Card and type(Card.set_seal) == "function" and not CL.rosemary_seal_hook_installed then
    CL.rosemary_seal_hook_installed = true
    local set_seal_ref = Card.set_seal

    function Card:set_seal(seal, ...)
        if canlaugh_rosemary_shield_source_is("c_cry_vacuum") and seal == nil then
            return
        end

        return set_seal_ref(self, seal, ...)
    end
end

if Card and type(Card.set_cost) == "function" and not CL.rosemary_cost_hook_installed then
    CL.rosemary_cost_hook_installed = true
    local set_cost_ref = Card.set_cost

    function Card:set_cost(...)
        local shield = G and G.GAME and G.GAME.canlaugh_rosemary_shield
        if canlaugh_rosemary_shield_source_is("c_cry_adversary") then
            G.GAME.cry_shop_joker_price_modifier = shield.adversary_price_modifier
        end

        return set_cost_ref(self, ...)
    end
end

if type(level_up_hand) == "function" and not CL.rosemary_hand_level_hook_installed then
    CL.rosemary_hand_level_hook_installed = true
    local level_up_hand_ref = level_up_hand

    function level_up_hand(card, hand, instant, amount, ...)
        local number_amount = tonumber(amount)

        if not number_amount and type(to_number) == "function" then
            number_amount = to_number(amount)
        end

        if (canlaugh_rosemary_shield_source_is("c_cry_white_hole")
                or canlaugh_rosemary_shield_source_is("c_cry_white_hole2"))
            and number_amount
            and number_amount < 0
        then
            return
        end

        return level_up_hand_ref(card, hand, instant, amount, ...)
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
            "{C:spectral}White Hole{} costs {C:attention}4{} actions",
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
