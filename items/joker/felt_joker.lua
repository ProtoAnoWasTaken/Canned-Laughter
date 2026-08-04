local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "felt_joker",
    path = "felt_joker.png",
    px = 69,
    py = 93,
})

local function canlaugh_felt_state()
    if not (G and G.GAME) then
        return
    end

    G.GAME.canlaugh_felt_joker = G.GAME.canlaugh_felt_joker or {}
    return G.GAME.canlaugh_felt_joker
end

local function canlaugh_felt_number(value)
    if type(value) == "number" then
        return value
    end

    if type(to_number) == "function" then
        local success, number = pcall(to_number, value)
        if success and type(number) == "number" then
            return number
        end
    end

    return nil
end

local function canlaugh_felt_rules_card_active()
    return CL.rules_card_active and CL.rules_card_active()
end

local function canlaugh_felt_card()
    for _, card in ipairs(SMODS.find_card("j_canlaugh_felt_joker") or {}) do
        if not card.debuff and not card.getting_sliced then
            return card
        end
    end
end

local function canlaugh_felt_ready(card)
    local state = G and G.GAME and G.GAME.canlaugh_felt_joker
    return state
        and state.card == card
        and state.eligible
        and not state.used
        and not card.getting_sliced
end

local function canlaugh_felt_pulse(card)
    if not (card and type(juice_card_until) == "function") then
        return
    end

    if card.canlaugh_felt_pulsing then
        return
    end

    card.canlaugh_felt_pulsing = true
    juice_card_until(card, function()
        local ready = canlaugh_felt_ready(card)
        if not ready then
            card.canlaugh_felt_pulsing = nil
        end
        return ready
    end, true)
end

local function canlaugh_felt_finish_at_max(state)
    if state.finished_at_max then
        return
    end

    state.finished_at_max = true
    state.used = true

    local card = state.card
    if card and not card.getting_sliced then
        SMODS.destroy_cards(card, nil, nil, true)
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.8,
        func = function()
            if type(add_tag) == "function" and Tag then
                add_tag(Tag("tag_buffoon"))
            end
            return true
        end,
    }))
end

local function canlaugh_felt_apply_steps(state)
    state.applying = nil

    local requested = state.requested_steps or 0
    local moved = state.moved_steps or 0
    local pending_steps = math.max(0, requested - moved)
    local current_ante = G.GAME.round_resets and G.GAME.round_resets.ante or 1
    local actual_steps = math.min(pending_steps, math.max(0, current_ante - 1))

    if actual_steps <= 0 then
        if requested >= 6 or current_ante <= 1 then
            canlaugh_felt_finish_at_max(state)
        end
        return
    end

    state.moved_steps = moved + actual_steps
    local destination_ante = current_ante - actual_steps
    state.ante = destination_ante

    if CL.challenge_active and CL.challenge_active("double_reacharound") then
        CL.challenge_win_run()
        return
    end

    ease_ante(-actual_steps)

    G.GAME.canlaugh_felt_ante_loops = (G.GAME.canlaugh_felt_ante_loops or 0) + actual_steps
    if type(check_for_unlock) == "function" then
        check_for_unlock({ type = "canlaugh_already_here" })
        if G.GAME.canlaugh_felt_ante_loops >= 2 then
            check_for_unlock({ type = "canlaugh_chronomancer" })
        end
    end

    if state.moved_steps >= 6 or destination_ante <= 1 then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.2,
            func = function()
                canlaugh_felt_finish_at_max(state)
                return true
            end,
        }))
    end
end

local function canlaugh_felt_note_blind(context, card)
    local state = canlaugh_felt_state()
    local ante = G.GAME.round_resets and G.GAME.round_resets.ante or 0
    if state.ante ~= ante then
        state.ante = ante
        state.blinds_selected = 0
        state.eligible = false
        state.spent = 0
        state.used = false
        state.requested_steps = 0
        state.moved_steps = 0
        state.applying = nil
        state.finished_at_max = false
        state.card = nil
    end

    if context.canlaugh_spyware then
        return
    end

    local choices = G.GAME.round_resets and G.GAME.round_resets.blind_choices
    local big_choice = choices and choices.Big
    local selected_blind = context.blind
    if not (big_choice and selected_blind and selected_blind.key == big_choice) then
        return
    end

    state.eligible = big_choice ~= "bl_big"
    if state.eligible then
        state.card = card
        canlaugh_felt_pulse(card)
    end
end

local function canlaugh_felt_spend(amount)
    local state = canlaugh_felt_state()
    if not (
        state
        and state.eligible
        and not state.used
        and amount > 0
        and canlaugh_felt_card()
    ) then
        return
    end

    local card = state.card or canlaugh_felt_card()
    local spend = card and card.ability and card.ability.extra and card.ability.extra.spend or 15
    state.spent = (state.spent or 0) + amount
    if state.spent < spend then
        return
    end

    local step_limit = canlaugh_felt_rules_card_active() and 6 or 1
    local requested_steps = math.min(step_limit, math.floor(state.spent / spend))
    if requested_steps <= (state.requested_steps or 0) then
        return
    end

    state.card = card
    state.requested_steps = requested_steps
    if not canlaugh_felt_rules_card_active() then
        state.used = true
    end

    if state.applying then
        return
    end

    state.applying = true
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.1,
        func = function()
            canlaugh_felt_apply_steps(state)
            return true
        end,
    }))
end

local function canlaugh_felt_is_in_shop()
    return G and G.STATE == G.STATES.SHOP
end

local function canlaugh_felt_record_shop_purchase(cost, card)
    if card and card.canlaugh_felt_purchase_recorded then
        return
    end

    local amount = canlaugh_felt_number(cost)
    if canlaugh_felt_is_in_shop() and amount and amount > 0 then
        if card then
            card.canlaugh_felt_purchase_recorded = true
        end
        canlaugh_felt_spend(amount)
    end
end

if Card and type(Card.open) == "function" and not CL.felt_joker_booster_hook_installed then
    CL.felt_joker_booster_hook_installed = true
    local open_ref = Card.open

    function Card:open(...)
        if self.ability and self.ability.set == "Booster" then
            canlaugh_felt_record_shop_purchase(self.cost, self)
        end

        return open_ref(self, ...)
    end
end

if Card and type(Card.redeem) == "function" and not CL.felt_joker_voucher_hook_installed then
    CL.felt_joker_voucher_hook_installed = true
    local redeem_ref = Card.redeem

    function Card:redeem(...)
        if self.ability and self.ability.set == "Voucher" then
            canlaugh_felt_record_shop_purchase(self.cost, self)
        end

        return redeem_ref(self, ...)
    end
end

if G and G.FUNCS and type(G.FUNCS.buy_from_shop) == "function" and not CL.felt_joker_buy_hook_installed then
    CL.felt_joker_buy_hook_installed = true
    local buy_from_shop_ref = G.FUNCS.buy_from_shop

    function G.FUNCS.buy_from_shop(e, ...)
        local card = e and e.config and e.config.ref_table
        local cost = card and card.cost
        local result = buy_from_shop_ref(e, ...)

        if result ~= false then
            canlaugh_felt_record_shop_purchase(cost, card)
        end

        return result
    end
end

if G and G.FUNCS and type(G.FUNCS.reroll_shop) == "function" and not CL.felt_joker_reroll_hook_installed then
    CL.felt_joker_reroll_hook_installed = true
    local reroll_shop_ref = G.FUNCS.reroll_shop

    function G.FUNCS.reroll_shop(e, ...)
        local cost = G.GAME and G.GAME.current_round and G.GAME.current_round.reroll_cost
        canlaugh_felt_record_shop_purchase(cost)
        return reroll_shop_ref(e, ...)
    end
end

SMODS.Joker({
    key = "felt_joker",
    name = "Felt Joker",
    atlas = "felt_joker",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    config = {
        extra = {
            spend = 15,
        },
    },
    loc_txt = {
        name = "Felt Joker",
        text = {
            "If the {C:attention}second Blind{} this Ante",
            "is not {C:attention}the Big Blind{}, spend",
            "{C:money}$#1#{} or more at the {C:attention}shop{}",
            "to go back {C:attention}1 Ante{}",
            "{C:inactive}({C:money}$#2#{C:inactive}/$#1# spent){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        local state = G and G.GAME and G.GAME.canlaugh_felt_joker
        local spent = state and state.card == card and state.spent or 0
        return { vars = { extra.spend, spent } }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            canlaugh_felt_note_blind(context, card)
        end
    end,
})
