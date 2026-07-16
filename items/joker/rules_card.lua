SMODS.Atlas({
    key = "rules_card",
    path = "rules_card.png",
    px = 69,
    py = 93,
})

local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

function CL.rules_card_active()
    if not (SMODS and type(SMODS.find_card) == "function") then
        return false
    end

    return next(SMODS.find_card("j_canlaugh_rules_card", true)) ~= nil
end

local function canlaugh_rules_card_create_riff_raff(card, context)
    local source = context and (context.blueprint_card or card) or card
    local jokers_to_create = card and card.ability and card.ability.extra or 2

    G.GAME.joker_buffer = (G.GAME.joker_buffer or 0) + jokers_to_create
    G.E_MANAGER:add_event(Event({
        func = function()
            for i = 1, jokers_to_create do
                local joker = create_card("Joker", G.jokers, nil, 0, nil, nil, nil, "rif")
                joker:add_to_deck()
                G.jokers:emplace(joker)
                joker:start_materialize()
            end

            G.GAME.joker_buffer = math.max(0, (G.GAME.joker_buffer or 0) - jokers_to_create)
            return true
        end,
    }))

    card_eval_status_text(source, "extra", nil, nil, nil, {
        message = localize("k_plus_joker"),
        colour = G.C.BLUE,
    })
end

local function canlaugh_rules_card_queue_consumable(card_type, seed)
    G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
    G.E_MANAGER:add_event(Event({
        trigger = "before",
        delay = 0.0,
        func = function()
            local card = create_card(card_type, G.consumeables, nil, nil, nil, nil, nil, seed)
            card:add_to_deck()
            G.consumeables:emplace(card)
            G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 0) - 1)
            return true
        end,
    }))
end

local function canlaugh_rules_card_consumable_result(card, card_type, seed, message, colour)
    canlaugh_rules_card_queue_consumable(card_type, seed)
    return {
        message = localize(message),
        colour = colour,
        card = card,
    }
end

local function canlaugh_rules_card_has_poker_hand(context, poker_hand)
    return context
        and context.poker_hands
        and context.poker_hands[poker_hand]
        and next(context.poker_hands[poker_hand])
end

local function canlaugh_rules_card_temperance_money()
    local money = 0

    if G and G.jokers then
        for i = 1, #G.jokers.cards do
            if G.jokers.cards[i].ability and G.jokers.cards[i].ability.set == "Joker" then
                money = money + G.jokers.cards[i].sell_cost
            end
        end
    end

    return money
end

local function canlaugh_rules_card_restore_after(value_setter, delay_time)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay_time or 0.45,
        func = function()
            value_setter()
            return true
        end,
    }))
end

function CL.rules_card_with_room(room_counts, callback)
    local old_consumeable_limit
    local old_joker_limit
    local restore_delay = room_counts and room_counts.restore_delay

    if not CL.rules_card_active() then
        return callback()
    end

    if room_counts and room_counts.consumeables and G.consumeables then
        old_consumeable_limit = G.consumeables.config.card_limit
        G.consumeables.config.card_limit = math.max(
            old_consumeable_limit,
            #G.consumeables.cards + (G.GAME.consumeable_buffer or 0) + room_counts.consumeables
        )
    end

    if room_counts and room_counts.jokers and G.jokers then
        old_joker_limit = G.jokers.config.card_limit
        G.jokers.config.card_limit = math.max(
            old_joker_limit,
            #G.jokers.cards + (G.GAME.joker_buffer or 0) + room_counts.jokers
        )
    end

    local results = { callback() }

    if old_consumeable_limit or old_joker_limit then
        canlaugh_rules_card_restore_after(function()
            if old_consumeable_limit then
                G.consumeables.config.card_limit = old_consumeable_limit
            end

            if old_joker_limit then
                G.jokers.config.card_limit = old_joker_limit
            end
        end, restore_delay)
    end

    return unpack(results)
end

local function canlaugh_rules_card_use_ankh(card, copier)
    if not (G.jokers and G.jokers.cards and #G.jokers.cards > 0) then
        return nil
    end

    stop_use()
    if not copier then
        set_consumeable_usage(card)
    end
    if card.debuff then
        return nil
    end

    local deletable_jokers = {}
    for _, joker in pairs(G.jokers.cards) do
        if not SMODS.is_eternal(joker, card) then
            deletable_jokers[#deletable_jokers + 1] = joker
        end
    end

    local chosen_joker = pseudorandom_element(G.jokers.cards, pseudoseed("ankh_choice"))
    local first_dissolve = nil
    G.E_MANAGER:add_event(Event({
        trigger = "before",
        delay = 0.75,
        func = function()
            for _, joker in pairs(deletable_jokers) do
                if joker ~= chosen_joker then
                    joker.getting_sliced = true
                    joker:start_dissolve(nil, first_dissolve)
                    first_dissolve = true
                end
            end
            return true
        end,
    }))

    G.E_MANAGER:add_event(Event({
        trigger = "before",
        delay = 0.4,
        func = function()
            local copy = copy_card(chosen_joker, nil, nil, nil, chosen_joker.edition and chosen_joker.edition.negative)
            copy:start_materialize()
            copy:add_to_deck()
            G.jokers:emplace(copy)
            return true
        end,
    }))
end

local function canlaugh_rules_card_complete_consumable_creation(start_count, target_created, card_type, forced_key, seed, used_card)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.85,
        func = function()
            local created = math.max(0, #G.consumeables.cards - start_count)
            local missing = math.max(0, target_created - created)

            for i = 1, missing do
                play_sound("timpani")
                local card = create_card(card_type, G.consumeables, nil, nil, nil, nil, forced_key, seed)
                card:add_to_deck()
                G.consumeables:emplace(card)

                if used_card then
                    used_card:juice_up(0.3, 0.5)
                end
            end

            return true
        end,
    }))
end

local function canlaugh_rules_card_consumable_room_shortfall(target_created)
    if not (G and G.consumeables and G.consumeables.cards and G.consumeables.config) then
        return 0
    end

    local available = (G.consumeables.config.card_limit or 0)
        - #G.consumeables.cards
        - (G.GAME.consumeable_buffer or 0)

    return math.max(0, target_created - math.max(0, available))
end

local function canlaugh_rules_card_invisible_can_unlock(card, context)
    return card
        and context
        and context.selling_self
        and not context.blueprint
        and card.ability
        and card.ability.name == "Invisible Joker"
        and (card.ability.invis_rounds or 0) >= (card.ability.extra or 0)
        and G
        and G.jokers
        and G.jokers.cards
        and G.jokers.config
        and #G.jokers.cards <= G.jokers.config.card_limit
end

local function canlaugh_rules_card_check_invisible_unlock(was_eligible)
    if was_eligible
        and G
        and G.jokers
        and G.jokers.cards
        and G.jokers.config
        and #G.jokers.cards > G.jokers.config.card_limit
        and type(check_for_unlock) == "function"
    then
        check_for_unlock({ type = "canlaugh_invisible_joker_over_limit" })
    end
end

if G and G.FUNCS and type(G.FUNCS.can_select_card) == "function" and not CL.rules_card_select_hook_installed then
    CL.rules_card_select_hook_installed = true
    local canlaugh_can_select_card_ref = G.FUNCS.can_select_card

    function G.FUNCS.can_select_card(e)
        local card = e and e.config and e.config.ref_table

        if CL.rules_card_active()
            and card
            and card.ability
            and card.ability.set == "Joker"
        then
            e.config.colour = G.C.GREEN
            e.config.button = "use_card"
            return
        end

        return canlaugh_can_select_card_ref(e)
    end
end

if Card and type(Card.can_calculate) == "function" and not CL.rules_card_can_calculate_hook_installed then
    CL.rules_card_can_calculate_hook_installed = true
    local canlaugh_can_calculate_ref = Card.can_calculate

    function Card:can_calculate(...)
        if CL.rules_card_active() then
            return true
        end

        return canlaugh_can_calculate_ref(self, ...)
    end
end

if Card and type(Card.calculate_joker) == "function" and not CL.rules_card_riff_raff_hook_installed then
    CL.rules_card_riff_raff_hook_installed = true
    local canlaugh_calculate_joker_ref = Card.calculate_joker

    function Card:calculate_joker(context, ...)
        local invisible_unlock_eligible = canlaugh_rules_card_invisible_can_unlock(self, context)
        local original_sin = nil

        if invisible_unlock_eligible then
            original_sin = { source = self }
            CL.original_sin_pending = original_sin
        end

        if CL.rules_card_active() and context and self.ability then
            local source = context.blueprint_card or self

            if context.open_booster
                and self.ability.name == "Hallucination"
                and SMODS.pseudorandom_probability(self, "halu" .. G.GAME.round_resets.ante, 1, self.ability.extra)
            then
                canlaugh_rules_card_queue_consumable("Tarot", "hal")
                card_eval_status_text(source, "extra", nil, nil, nil, {
                    message = localize("k_plus_tarot"),
                    colour = G.C.PURPLE,
                })
                return nil, true
            end

            if context.setting_blind and not self.getting_sliced then
                if self.ability.name == "Riff-raff" and not source.getting_sliced then
                    canlaugh_rules_card_create_riff_raff(self, context)
                    return nil, true
                end

                if self.ability.name == "Cartomancer" and not source.getting_sliced then
                    G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            G.E_MANAGER:add_event(Event({
                                func = function()
                                    local card = create_card("Tarot", G.consumeables, nil, nil, nil, nil, nil, "car")
                                    card:add_to_deck()
                                    G.consumeables:emplace(card)
                                    G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 0) - 1)
                                    return true
                                end,
                            }))
                            card_eval_status_text(source, "extra", nil, nil, nil, {
                                message = localize("k_plus_tarot"),
                                colour = G.C.PURPLE,
                            })
                            return true
                        end,
                    }))
                    return nil, true
                end
            elseif context.destroying_card and not context.blueprint then
                if self.ability.name == "Sixth Sense"
                    and #context.full_hand == 1
                    and context.full_hand[1]:get_id() == 6
                    and not context.full_hand[1].sixth_sense
                    and G.GAME.current_round.hands_played == 0
                then
                    context.full_hand[1].sixth_sense = true
                    canlaugh_rules_card_queue_consumable("Spectral", "sixth")
                    card_eval_status_text(source, "extra", nil, nil, nil, {
                        message = localize("k_plus_spectral"),
                        colour = G.C.SECONDARY_SET.Spectral,
                    })
                    return true
                end
            elseif context.individual then
                if context.cardarea == G.play
                    and self.ability.name == "8 Ball"
                    and context.other_card
                    and context.other_card:get_id() == 8
                    and SMODS.pseudorandom_probability(self, "8ball", 1, self.ability.extra)
                then
                    G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
                    return {
                        extra = {
                            focus = source,
                            message = localize("k_plus_tarot"),
                            func = function()
                                G.E_MANAGER:add_event(Event({
                                    trigger = "before",
                                    delay = 0.0,
                                    func = function()
                                        local card = create_card("Tarot", G.consumeables, nil, nil, nil, nil, nil, "8ba")
                                        card:add_to_deck()
                                        G.consumeables:emplace(card)
                                        G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 0) - 1)
                                        return true
                                    end,
                                }))
                            end,
                        },
                        colour = G.C.SECONDARY_SET.Tarot,
                        card = source,
                    }
                end
            elseif context.joker_main then
                if self.ability.name == "Superposition" then
                    local aces = 0
                    for i = 1, #context.scoring_hand do
                        if context.scoring_hand[i]:get_id() == 14 then
                            aces = aces + 1
                        end
                    end

                    if aces >= 1 and canlaugh_rules_card_has_poker_hand(context, "Straight") then
                        return canlaugh_rules_card_consumable_result(
                            source,
                            "Tarot",
                            "sup",
                            "k_plus_tarot",
                            G.C.SECONDARY_SET.Tarot
                        )
                    end
                end

                if self.ability.name == "Seance"
                    and self.ability.extra
                    and canlaugh_rules_card_has_poker_hand(context, self.ability.extra.poker_hand)
                then
                    return canlaugh_rules_card_consumable_result(
                        source,
                        "Spectral",
                        "sea",
                        "k_plus_spectral",
                        G.C.SECONDARY_SET.Spectral
                    )
                end
            end
        end

        local results = { canlaugh_calculate_joker_ref(self, context, ...) }
        if invisible_unlock_eligible and not original_sin.copy_added then
            CL.original_sin_pending = nil
            canlaugh_rules_card_check_invisible_unlock(invisible_unlock_eligible)
        end
        return unpack(results)
    end
end

if Card and type(Card.update) == "function" and not CL.rules_card_update_hook_installed then
    CL.rules_card_update_hook_installed = true
    local canlaugh_update_ref = Card.update

    function Card:update(...)
        local results = { canlaugh_update_ref(self, ...) }

        if self.ability
            and self.ability.name == "Temperance"
            and CL.rules_card_active()
        then
            self.ability.money = canlaugh_rules_card_temperance_money()
        end

        return unpack(results)
    end
end

if Card and type(Card.use_consumeable) == "function" and not CL.rules_card_use_hook_installed then
    CL.rules_card_use_hook_installed = true
    local canlaugh_use_consumeable_ref = Card.use_consumeable

    function Card:use_consumeable(area, copier, ...)
        local extra_args = { ... }
        local extra_arg_count = select("#", ...)

        if CL.rules_card_active() and self.ability then
            if self.ability.name == "The Fool" and G.GAME.last_tarot_planet then
                if canlaugh_rules_card_consumable_room_shortfall(1) <= 0 then
                    return canlaugh_use_consumeable_ref(self, area, copier, ...)
                end

                local start_count = #G.consumeables.cards
                local forced_key = G.GAME.last_tarot_planet
                local results = {
                    CL.rules_card_with_room({ consumeables = 1, restore_delay = 2.0 }, function()
                        return canlaugh_use_consumeable_ref(self, area, copier, unpack(extra_args, 1, extra_arg_count))
                    end),
                }
                canlaugh_rules_card_complete_consumable_creation(start_count, 1, "Tarot_Planet", forced_key, "fool", copier or self)
                return unpack(results)
            end

            if self.ability.name == "The High Priestess" then
                local planets = self.ability.consumeable.planets or 2
                if canlaugh_rules_card_consumable_room_shortfall(planets) <= 0 then
                    return canlaugh_use_consumeable_ref(self, area, copier, ...)
                end

                local start_count = #G.consumeables.cards
                local results = {
                    CL.rules_card_with_room({ consumeables = planets, restore_delay = 2.0 }, function()
                        return canlaugh_use_consumeable_ref(self, area, copier, unpack(extra_args, 1, extra_arg_count))
                    end),
                }
                canlaugh_rules_card_complete_consumable_creation(start_count, planets, "Planet", nil, "pri", copier or self)
                return unpack(results)
            end

            if self.ability.name == "The Emperor" then
                local tarots = self.ability.consumeable.tarots or 2
                if canlaugh_rules_card_consumable_room_shortfall(tarots) <= 0 then
                    return canlaugh_use_consumeable_ref(self, area, copier, ...)
                end

                local start_count = #G.consumeables.cards
                local results = {
                    CL.rules_card_with_room({ consumeables = tarots, restore_delay = 2.0 }, function()
                        return canlaugh_use_consumeable_ref(self, area, copier, unpack(extra_args, 1, extra_arg_count))
                    end),
                }
                canlaugh_rules_card_complete_consumable_creation(start_count, tarots, "Tarot", nil, "emp", copier or self)
                return unpack(results)
            end

            if self.ability.name == "The Hermit" then
                local old_extra = self.ability.extra
                self.ability.extra = math.max(old_extra or 0, G.GAME.dollars or 0)
                local results = { pcall(canlaugh_use_consumeable_ref, self, area, copier, ...) }
                if not results[1] then
                    self.ability.extra = old_extra
                    error(results[2])
                end
                canlaugh_rules_card_restore_after(function()
                    self.ability.extra = old_extra
                end)
                return unpack(results, 2)
            end

            if self.ability.name == "Temperance" then
                local old_extra = self.ability.extra
                local old_money = self.ability.money
                local money = canlaugh_rules_card_temperance_money()
                self.ability.extra = math.max(old_extra or 0, money)
                self.ability.money = money
                local results = { pcall(canlaugh_use_consumeable_ref, self, area, copier, ...) }
                if not results[1] then
                    self.ability.extra = old_extra
                    self.ability.money = old_money
                    error(results[2])
                end
                canlaugh_rules_card_restore_after(function()
                    self.ability.extra = old_extra
                    self.ability.money = old_money
                end)
                return unpack(results, 2)
            end

            if self.ability.name == "Ankh" then
                return canlaugh_rules_card_use_ankh(self, copier)
            end
        end

        return canlaugh_use_consumeable_ref(self, area, copier, ...)
    end
end

local RULES_CARD_ROOM_CONSUMABLES = {
    ["The Emperor"] = true,
    ["The High Priestess"] = true,
    Judgement = true,
    ["The Soul"] = true,
    Wraith = true,
}

if Card and type(Card.can_use_consumeable) == "function" and not CL.rules_card_can_use_hook_installed then
    CL.rules_card_can_use_hook_installed = true
    local canlaugh_can_use_consumeable_ref = Card.can_use_consumeable

    function Card:can_use_consumeable(any_state, skip_check, ...)
        if CL.rules_card_active()
            and self.ability
            and self.ability.name == "Ankh"
        then
            for _, joker in pairs(G.jokers.cards) do
                if joker.ability and joker.ability.set == "Joker" then
                    return true
                end
            end

            return false
        end

        if CL.rules_card_active()
            and self.ability
            and self.ability.name == "The Fool"
        then
            return G.GAME.last_tarot_planet ~= nil
        end

        if CL.rules_card_active()
            and self.ability
            and RULES_CARD_ROOM_CONSUMABLES[self.ability.name]
        then
            return true
        end

        return canlaugh_can_use_consumeable_ref(self, any_state, skip_check, ...)
    end
end

if Card and type(Card.check_use) == "function" and not CL.rules_card_check_use_hook_installed then
    CL.rules_card_check_use_hook_installed = true
    local canlaugh_check_use_ref = Card.check_use

    function Card:check_use(...)
        if CL.rules_card_active()
            and self.ability
            and self.ability.name == "Ankh"
        then
            return nil
        end

        if CL.rules_card_active()
            and self.ability
            and RULES_CARD_ROOM_CONSUMABLES[self.ability.name]
        then
            return nil
        end

        return canlaugh_check_use_ref(self, ...)
    end
end

if G and G.FUNCS and type(G.FUNCS.evaluate_round) == "function" and not CL.rules_card_interest_hook_installed then
    CL.rules_card_interest_hook_installed = true
    local canlaugh_evaluate_round_ref = G.FUNCS.evaluate_round

    function G.FUNCS.evaluate_round(...)
        local old_interest_cap

        if CL.rules_card_active() and G and G.GAME and G.GAME.interest_cap then
            old_interest_cap = G.GAME.interest_cap
            G.GAME.interest_cap = math.max(G.GAME.interest_cap, G.GAME.dollars or G.GAME.interest_cap)
        end

        local results = { pcall(canlaugh_evaluate_round_ref, ...) }

        if old_interest_cap then
            G.GAME.interest_cap = old_interest_cap
        end

        if not results[1] then
            error(results[2])
        end

        return unpack(results, 2)
    end
end

SMODS.Joker({
    key = "rules_card",
    name = "Rules Card",
    atlas = "rules_card",
    pos = { x = 0, y = 0 },
    rarity = 3,
    weight = 5,
    cost = 8,
    unlocked = false,
    loc_txt = {
        name = "Rules Card",
        text = {
            "All this world's rules are",
            "at {C:attention}your{} command"
        },
        unlock = {
            "Go {C:attention}over the limit{}",
            "with an {C:attention}Invisible Joker{}",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_invisible_joker_over_limit"
    end,
    locked_loc_vars = function(self, info_queue, card)
        if G and G.P_CENTERS and G.P_CENTERS.j_invisible then
            CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS.j_invisible, card)
        end

        return { vars = {} }
    end,
})
