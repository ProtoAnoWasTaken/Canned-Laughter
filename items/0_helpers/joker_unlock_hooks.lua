local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.unlocks = CL.unlocks or {}

function CL.unlocks.fire(args)
    if type(check_for_unlock) == "function" then
        check_for_unlock(args)
    end
end

CL.unlocks.mega_barter_rewards = CL.unlocks.mega_barter_rewards or {}

function CL.unlocks.queue_negative_joker(joker_key)
    if not (joker_key and G and G.P_CENTERS and G.P_CENTERS[joker_key] and G.jokers) then
        return false
    end
    if CL.unlocks.mega_barter_rewards[joker_key] then
        return false
    end

    CL.unlocks.mega_barter_rewards[joker_key] = true

    local grant = function()
        if type(discover_card) == "function" then
            discover_card(G.P_CENTERS[joker_key])
        end
        local joker = create_card("Joker", G.jokers, nil, nil, nil, nil, joker_key, "canlaugh_mega_barter")
        if not joker then
            return true
        end

        if type(joker.set_edition) == "function" then
            joker:set_edition({ negative = true }, true, true)
        end
        joker:add_to_deck()
        G.jokers:emplace(joker)
        if type(card_eval_status_text) == "function" then
            card_eval_status_text(joker, "extra", nil, nil, nil, {
                message = "Unlocked!",
                colour = G.C.GREEN,
            })
        end
        return true
    end

    if G.E_MANAGER and Event then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.35,
            func = grant,
        }))
    else
        grant()
    end
    return true
end

function CL.unlocks.register_mega_barter_joker(booster_kind, unlock_type, joker_key)
    if not (CL.barter and type(CL.barter.register_mega_success_hook) == "function") then
        return
    end

    CL.barter.register_mega_success_hook(booster_kind, joker_key, function()
        local center = G and G.P_CENTERS and G.P_CENTERS[joker_key]
        if not (center and center.unlocked == false) then
            return
        end

        CL.unlocks.fire({ type = unlock_type })
        if center.unlocked == false then
            center.unlocked = true
        end
        CL.unlocks.queue_negative_joker(joker_key)
    end)
end

function CL.unlocks.increment_playing_cards_acquired(amount)
    if not (G and G.GAME) then
        return
    end

    G.GAME.canlaugh_playing_cards_acquired = (G.GAME.canlaugh_playing_cards_acquired or 0) + (amount or 1)
    CL.unlocks.fire({
        type = "canlaugh_playing_cards_acquired",
        amount = G.GAME.canlaugh_playing_cards_acquired,
    })
end

function CL.unlocks.note_ante()
    if not (G and G.GAME and G.GAME.round_resets) then
        return
    end

    local ante = G.GAME.round_resets.ante or 1
    G.GAME.canlaugh_highest_ante_reached = math.max(G.GAME.canlaugh_highest_ante_reached or ante, ante)
end

function CL.unlocks.in_previous_ante()
    if not (G and G.GAME and G.GAME.round_resets) then
        return false
    end

    CL.unlocks.note_ante()
    return (G.GAME.round_resets.ante or 1) < (G.GAME.canlaugh_highest_ante_reached or 1)
end

local function canlaugh_bootstraps_unlocked()
    return G
        and G.P_CENTERS
        and G.P_CENTERS.j_bootstraps
        and G.P_CENTERS.j_bootstraps.unlocked
end

local function canlaugh_is_polychrome_joker(card)
    return card
        and card.edition
        and card.edition.polychrome
        and card.ability
        and card.ability.set == "Joker"
end

function CL.unlocks.check_bootstrap_paradox_purchase(card)
    if canlaugh_bootstraps_unlocked()
        and canlaugh_is_polychrome_joker(card)
        and CL.unlocks.in_previous_ante()
    then
        CL.unlocks.fire({ type = "canlaugh_bootstrap_paradox_purchase" })
    end
end

local function canlaugh_is_playing_card(card)
    return card
        and card.ability
        and (card.ability.set == "Default" or card.ability.set == "Enhanced")
end

if type(create_playing_card) == "function" and not CL.playing_card_create_hook_installed then
    CL.playing_card_create_hook_installed = true
    local canlaugh_create_playing_card_ref = create_playing_card

    function create_playing_card(...)
        local card = canlaugh_create_playing_card_ref(...)

        if card and not CL.suppress_playing_card_acquired_unlock then
            CL.unlocks.increment_playing_cards_acquired(1)
        end

        return card
    end
end

if type(ease_ante) == "function" and not CL.ante_tracking_hook_installed then
    CL.ante_tracking_hook_installed = true
    local canlaugh_ease_ante_ref = ease_ante

    function ease_ante(...)
        CL.unlocks.note_ante()
        local ret = canlaugh_ease_ante_ref(...)

        G.E_MANAGER:add_event(Event({
            trigger = "immediate",
            func = function()
                CL.unlocks.note_ante()
                return true
            end,
        }))

        return ret
    end
end

function CL.apply_bootstrap_paradox_money(amount)
    if not (G and G.GAME and amount and amount > 0) then
        return
    end

    local state_total = (G.GAME.canlaugh_bootstrap_paradox_money_received or 0) + amount
    local previous_steps = math.floor((G.GAME.canlaugh_bootstrap_paradox_money_received or 0) / 5)
    local current_steps = math.floor(state_total / 5)
    local gained_steps = current_steps - previous_steps

    G.GAME.canlaugh_bootstrap_paradox_money_received = state_total

    if gained_steps <= 0 or not (G.jokers and G.jokers.cards) then
        return
    end

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center

        if center and center.key == "j_canlaugh_bootstrap_paradox" then
            local extra = joker.ability and joker.ability.extra
            local gain = gained_steps * ((extra and extra.mult_gain) or 2)

            if extra then
                extra.mult = (extra.mult or 0) + gain
            end

            if type(card_eval_status_text) == "function" then
                card_eval_status_text(joker, "extra", nil, nil, nil, {
                    message = localize({ type = "variable", key = "a_mult", vars = { gain } }),
                    colour = G.C.MULT,
                })
            end
        end
    end
end

local function canlaugh_is_negative_card(card)
    return card
        and card.edition
        and (card.edition.negative or card.edition.type == "negative" or card.edition.key == "e_negative")
end

local function canlaugh_note_negative_sale_money(card)
    if not canlaugh_is_negative_card(card) then
        return
    end

    local sell_cost = tonumber(card.sell_cost) or 0

    if sell_cost > 0 then
        CL.chula_reh_negative_sale_money_to_ignore =
            (CL.chula_reh_negative_sale_money_to_ignore or 0) + sell_cost
    end
end

local function canlaugh_apply_positive_money_gain(amount)
    CL.apply_bootstrap_paradox_money(amount)

    if type(CL.apply_chula_reh_money) == "function" then
        local tracked_amount = amount
        local ignored_negative_sale = CL.chula_reh_negative_sale_money_to_ignore or 0

        if ignored_negative_sale > 0 then
            local ignored_amount = math.min(tracked_amount, ignored_negative_sale)

            tracked_amount = tracked_amount - ignored_amount
            CL.chula_reh_negative_sale_money_to_ignore = ignored_negative_sale - ignored_amount
        end

        if tracked_amount > 0 then
            CL.apply_chula_reh_money(tracked_amount)
        end
    end
end

local function canlaugh_number_value(value)
    if type(value) == "number" then
        return value
    end

    if type(to_number) == "function" then
        local ok, converted = pcall(to_number, value)

        if ok and type(converted) == "number" then
            return converted
        end
    end

    if type(value) == "table" and type(value.to_number) == "function" then
        local ok, converted = pcall(value.to_number, value)

        if ok and type(converted) == "number" then
            return converted
        end
    end

    return nil
end

if Card and type(Card.sell_card) == "function" and not CL.negative_sale_money_hook_installed then
    CL.negative_sale_money_hook_installed = true
    local canlaugh_negative_sale_ref = Card.sell_card

    function Card:sell_card(...)
        canlaugh_note_negative_sale_money(self)
        return canlaugh_negative_sale_ref(self, ...)
    end
end

if type(ease_dollars) == "function" and not CL.bootstrap_paradox_money_hook_installed then
    CL.bootstrap_paradox_money_hook_installed = true
    local canlaugh_ease_dollars_ref = ease_dollars

    function ease_dollars(mod, instant, ...)
        local ret = canlaugh_ease_dollars_ref(mod, instant, ...)
        local tracked_mod = canlaugh_number_value(mod)

        if tracked_mod and tracked_mod > 0 then
            if instant then
                canlaugh_apply_positive_money_gain(tracked_mod)
            else
                G.E_MANAGER:add_event(Event({
                    trigger = "immediate",
                    func = function()
                        canlaugh_apply_positive_money_gain(tracked_mod)
                        return true
                    end,
                }))
            end
        end

        return ret
    end
end

if type(copy_card) == "function" and not CL.playing_card_copy_hook_installed then
    CL.playing_card_copy_hook_installed = true
    local canlaugh_copy_card_ref = copy_card

    function copy_card(other, new_card, card_scale, playing_card, strip_edition)
        local preserve_negative = strip_edition
            and other
            and other.edition
            and other.edition.negative
            and CL.rules_card_active
            and CL.rules_card_active()
        local card = canlaugh_copy_card_ref(other, new_card, card_scale, playing_card, strip_edition)

        if preserve_negative and card and type(card.set_edition) == "function" then
            card:set_edition({ negative = true }, true, true)
        end

        if playing_card and card and canlaugh_is_playing_card(card) and not CL.suppress_playing_card_acquired_unlock then
            CL.unlocks.increment_playing_cards_acquired(1)
        end

        return card
    end
end

if G and G.FUNCS and type(G.FUNCS.buy_from_shop) == "function" and not CL.playing_card_buy_hook_installed then
    CL.playing_card_buy_hook_installed = true
    local canlaugh_buy_from_shop_ref = G.FUNCS.buy_from_shop

    function G.FUNCS.buy_from_shop(e)
        local card = e and e.config and e.config.ref_table
        local is_playing_card = canlaugh_is_playing_card(card)
            and not (card.area == G.deck or card.area == G.hand or card.area == G.play)
        local is_shop_joker = G and G.shop_jokers and card and card.area == G.shop_jokers

        local ret = canlaugh_buy_from_shop_ref(e)

        if ret ~= false and is_playing_card then
            CL.unlocks.increment_playing_cards_acquired(1)
        end

        if ret ~= false and is_shop_joker then
            CL.unlocks.check_bootstrap_paradox_purchase(card)
        end

        return ret
    end
end
