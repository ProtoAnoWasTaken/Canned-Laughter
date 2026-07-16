local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.joker_seal_effects = CL.joker_seal_effects or {}
CL.joker_seal_blocklist = CL.joker_seal_blocklist or {
    canlaugh_calcite = true,
    canlaugh_phosphate = true,
    starlight = true,
}

local JOKER_SEAL_LOC_TXT = {
    Red = {
        key = "canlaugh_red_joker_seal",
        loc_txt = {
            name = "Red Seal",
            text = {
                "Retrigger this",
                "card {C:attention}1{} time",
            },
        },
    },
    Gold = {
        key = "canlaugh_gold_joker_seal",
        loc_txt = {
            name = "Gold Seal",
            text = {
                "Earn {C:money}$3{} every",
                "time this card procs",
            },
        },
    },
    Blue = {
        key = "canlaugh_blue_joker_seal",
        loc_txt = {
            name = "Blue Seal",
            text = {
                "Creates the {C:planet}Planet{} card",
                "for the {C:attention}last played{}",
                "{C:attention}poker hand{} if this",
                "card procs",
            },
        },
    },
    Purple = {
        key = "canlaugh_purple_joker_seal",
        loc_txt = {
            name = "Purple Seal",
            text = {
                "Creates a {C:tarot}Tarot{} card",
                "when sold",
                "{C:inactive}(Must have room){}",
            },
        },
    },
    canlaugh_shadow = {
        key = "canlaugh_shadow_joker_seal",
        loc_txt = {
            name = "Shadow Seal",
            text = {
                "Retries this card if it",
                "does not trigger",
                "{C:inactive}(Ignores debuffs){}",
            },
        },
    },
}

local function canlaugh_card_is_joker(card)
    local center = card and card.config and card.config.center
    return (card and card.ability and card.ability.set == "Joker")
        or (center and center.set == "Joker")
end

local function canlaugh_joker_is_blueprint_compatible(card)
    local center = card and card.config and card.config.center

    if not canlaugh_card_is_joker(card) then
        return false
    end

    if center and center.blueprint_compat ~= nil then
        return center.blueprint_compat
    end

    if card.config and card.config.blueprint_compat ~= nil then
        return card.config.blueprint_compat
    end

    return false
end

local function canlaugh_rules_card_active()
    return CL.rules_card_active and CL.rules_card_active()
end

local function canlaugh_joker_can_use_seal_effect(card)
    return canlaugh_card_is_joker(card)
        and (canlaugh_joker_is_blueprint_compatible(card) or canlaugh_rules_card_active())
end

local function canlaugh_has_consumable_room(create_count)
    create_count = create_count or 1

    if CL.tarot and type(CL.tarot.has_consumable_room) == "function" then
        return CL.tarot.has_consumable_room(create_count)
    end

    return G
        and G.consumeables
        and G.GAME
        and (
            #G.consumeables.cards + (G.GAME.consumeable_buffer or 0) + create_count <= G.consumeables.config.card_limit
            or canlaugh_rules_card_active()
        )
end

local function canlaugh_with_consumable_room(create_count, callback)
    if CL.rules_card_with_room then
        return CL.rules_card_with_room({ consumeables = create_count or 1, restore_delay = 2.0 }, callback)
    end

    return callback()
end

local function canlaugh_process_joker_seal_loc(seal_key, args)
    if not (SMODS and type(SMODS.process_loc_text) == "function" and G and G.localization) then
        return
    end

    if args and args.loc_txt and args.key then
        SMODS.process_loc_text(G.localization.descriptions.Other, args.key, args.loc_txt)
    end
end

local function canlaugh_install_joker_seal_loc(seal_key)
    local effect = CL.joker_seal_effects and CL.joker_seal_effects[seal_key]
    local args = effect and effect.loc or JOKER_SEAL_LOC_TXT[seal_key]
    local seal = G and G.P_SEALS and G.P_SEALS[seal_key]

    if not (seal and args and args.key) or seal.canlaugh_joker_loc_installed then
        return
    end

    canlaugh_process_joker_seal_loc(seal_key, args)

    local original_loc_vars = seal.loc_vars
    seal.loc_vars = function(self, info_queue, card)
        if canlaugh_card_is_joker(card) then
            return {
                key = args.key,
            }
        end

        if type(original_loc_vars) == "function" then
            return original_loc_vars(self, info_queue, card)
        end
    end
    seal.canlaugh_joker_loc_installed = true
end

local function canlaugh_install_all_joker_seal_locs()
    for seal_key in pairs(CL.joker_seal_effects or {}) do
        canlaugh_install_joker_seal_loc(seal_key)
    end
end

function CL.register_joker_seal_effect(seal_key, effect)
    if type(seal_key) ~= "string" or type(effect) ~= "table" then
        return
    end

    CL.joker_seal_effects[seal_key] = effect
    canlaugh_install_joker_seal_loc(seal_key)
end

function CL.can_joker_receive_seal(card, seal_key)
    if not (card and seal_key) then
        return false
    end

    local center = card.config and card.config.center
    local is_joker = (card.ability and card.ability.set == "Joker")
        or (center and center.set == "Joker")

    if not is_joker then
        return true
    end

    if CL.joker_seal_blocklist[seal_key] then
        return false
    end

    return canlaugh_joker_can_use_seal_effect(card)
        and CL.joker_seal_effects[seal_key] ~= nil
end

local function canlaugh_joker_scored(result)
    if type(result) ~= "table" then
        return false
    end

    for key, value in pairs(result) do
        if key ~= "card"
            and key ~= "extra"
            and key ~= "message"
            and key ~= "colour"
            and value ~= nil
        then
            return true
        end
    end

    return false
end

local function canlaugh_is_real_joker_proc(card, context, result)
    if not context
        or context.retrigger_joker_check
        or context.post_trigger
        or (SMODS and type(SMODS.is_getter_context) == "function" and SMODS.is_getter_context(context))
    then
        return false
    end

    if not canlaugh_joker_can_use_seal_effect(card) then
        return false
    end

    return canlaugh_joker_scored(result)
end

local function canlaugh_is_last_hand_of_round()
    return G
        and G.GAME
        and G.GAME.current_round
        and G.GAME.current_round.hands_left == 0
end

local function canlaugh_create_planet_for_last_hand(card)
    if not (G and G.GAME and G.GAME.last_hand_played and G.consumeables and G.P_CENTER_POOLS) then
        return false
    end

    local planet_key
    for _, planet in ipairs(G.P_CENTER_POOLS.Planet or {}) do
        if planet and planet.config and planet.config.hand_type == G.GAME.last_hand_played then
            planet_key = planet.key
            break
        end
    end

    if not planet_key then
        return false
    end

    if not canlaugh_has_consumable_room(1) then
        return false
    end

    return canlaugh_with_consumable_room(1, function()
        if #G.consumeables.cards + (G.GAME.consumeable_buffer or 0) >= G.consumeables.config.card_limit then
            return false
        end

        G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
        G.E_MANAGER:add_event(Event({
            trigger = "before",
            delay = 0,
            func = function()
                local planet = create_card("Planet", G.consumeables, nil, nil, nil, nil, planet_key, "canlaugh_blue_joker_seal")
                planet:add_to_deck()
                G.consumeables:emplace(planet)
                G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 1) - 1)
                return true
            end,
        }))
        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = localize("k_plus_planet"),
            colour = G.C.SECONDARY_SET.Planet,
        })
        return true
    end)
end

local function canlaugh_create_tarot_from_sold_joker(card)
    if not (G and G.GAME and G.consumeables and G.P_CENTERS) then
        return false
    end

    if not canlaugh_has_consumable_room(1) then
        return false
    end

    return canlaugh_with_consumable_room(1, function()
        if #G.consumeables.cards + (G.GAME.consumeable_buffer or 0) >= G.consumeables.config.card_limit then
            return false
        end

        G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
        G.E_MANAGER:add_event(Event({
            trigger = "before",
            delay = 0,
            func = function()
                local tarot = create_card("Tarot", G.consumeables, nil, nil, nil, nil, nil, "canlaugh_purple_joker_seal")
                tarot:add_to_deck()
                G.consumeables:emplace(tarot)
                G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 1) - 1)
                return true
            end,
        }))
        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = localize("k_plus_tarot"),
            colour = G.C.PURPLE,
        })
        return true
    end)
end

CL.register_joker_seal_effect("Red", {
    loc = JOKER_SEAL_LOC_TXT.Red,
})

CL.register_joker_seal_effect("Gold", {
    loc = JOKER_SEAL_LOC_TXT.Gold,
    after_score = function(card)
        ease_dollars(3)
        card_eval_status_text(card, "dollars", 3)
    end,
})

CL.register_joker_seal_effect("Blue", {
    loc = JOKER_SEAL_LOC_TXT.Blue,
    after_score = function(card)
        if canlaugh_is_last_hand_of_round() then
            canlaugh_create_planet_for_last_hand(card)
        end
    end,
})

CL.register_joker_seal_effect("Purple", {
    loc = JOKER_SEAL_LOC_TXT.Purple,
    calculate = function(card, context)
        if canlaugh_joker_can_use_seal_effect(card)
            and context.selling_self
            and not card.canlaugh_purple_joker_seal_sold
        then
            card.canlaugh_purple_joker_seal_sold = true
            canlaugh_create_tarot_from_sold_joker(card)
        end
    end,
})

CL.register_joker_seal_effect("canlaugh_shadow", {
    loc = JOKER_SEAL_LOC_TXT.canlaugh_shadow,
})

if SMODS and SMODS.Seal and type(SMODS.Seal.inject) == "function" and not CL.joker_seal_loc_inject_hook_installed then
    CL.joker_seal_loc_inject_hook_installed = true
    local canlaugh_seal_inject_ref = SMODS.Seal.inject

    function SMODS.Seal:inject(...)
        local results = { canlaugh_seal_inject_ref(self, ...) }
        canlaugh_install_joker_seal_loc(self.key)
        return unpack(results)
    end
end

canlaugh_install_all_joker_seal_locs()

if Card and type(Card.set_seal) == "function" and not CL.joker_seal_set_seal_hook_installed then
    CL.joker_seal_set_seal_hook_installed = true
    local canlaugh_set_seal_ref = Card.set_seal

    function Card:set_seal(_seal, silent, immediate, ...)
        if _seal and not CL.can_joker_receive_seal(self, _seal) then
            return
        end

        local center = self.config and self.config.center
        local is_joker = (self.ability and self.ability.set == "Joker")
            or (center and center.set == "Joker")
        local old_seal = self.seal
        local results = { canlaugh_set_seal_ref(self, _seal, silent, immediate, ...) }

        if _seal and is_joker and self.seal == _seal and old_seal ~= _seal then
            self:juice_up(0.3, 0.4)
        end

        return unpack(results)
    end
end

local JOKER_SEAL_CALCULATE_SEAL_HOOK_VERSION = 1

if Card
    and type(Card.calculate_seal) == "function"
    and CL.joker_seal_calculate_seal_hook_version ~= JOKER_SEAL_CALCULATE_SEAL_HOOK_VERSION
then
    CL.joker_seal_calculate_seal_hook_version = JOKER_SEAL_CALCULATE_SEAL_HOOK_VERSION
    CL.joker_seal_calculate_seal_base_ref = CL.joker_seal_calculate_seal_base_ref or Card.calculate_seal
    local canlaugh_calculate_seal_ref = CL.joker_seal_calculate_seal_base_ref

    function Card:calculate_seal(context, ...)
        if canlaugh_card_is_joker(self) and self.seal and CL.joker_seal_effects[self.seal] then
            return nil, nil
        end

        return canlaugh_calculate_seal_ref(self, context, ...)
    end
end

local function canlaugh_unwrap_old_red_seal_repetition_hook()
    if not (SMODS and type(SMODS.insert_repetitions) == "function" and debug and type(debug.getupvalue) == "function") then
        return
    end

    local current = SMODS.insert_repetitions

    for _ = 1, 8 do
        local replacement

        for index = 1, 20 do
            local name, value = debug.getupvalue(current, index)
            if not name then
                break
            end

            if name == "canlaugh_insert_repetitions_ref" and type(value) == "function" then
                replacement = value
                break
            end
        end

        if not replacement then
            break
        end

        current = replacement
    end

    if current ~= SMODS.insert_repetitions then
        SMODS.insert_repetitions = current
    end
end

canlaugh_unwrap_old_red_seal_repetition_hook()

local JOKER_SEAL_CALCULATE_HOOK_VERSION = 6

if Card
    and type(Card.calculate_joker) == "function"
    and CL.joker_seal_calculate_joker_hook_version ~= JOKER_SEAL_CALCULATE_HOOK_VERSION
then
    CL.joker_seal_calculate_joker_hook_version = JOKER_SEAL_CALCULATE_HOOK_VERSION
    CL.joker_seal_calculate_joker_base_ref = CL.joker_seal_calculate_joker_base_ref or Card.calculate_joker
    local canlaugh_calculate_joker_ref = CL.joker_seal_calculate_joker_base_ref

    local function canlaugh_joker_returned_effect(result, post)
        if post then
            return true
        end

        if result == true then
            return true
        end

        return type(result) == "table" and next(result) ~= nil
    end

    local function canlaugh_red_seal_can_self_retrigger(card, context, result, post)
        if not (context and card and card.seal == "Red") then
            return false
        end

        if context.blueprint
            or context.no_blueprint
            or context.canlaugh_red_seal_retrigger
            or context.retrigger_joker_check
            or context.retrigger_joker
            or context.post_trigger
            or (SMODS and type(SMODS.is_getter_context) == "function" and SMODS.is_getter_context(context))
        then
            return false
        end

        if card.debuff and not canlaugh_rules_card_active() then
            return false
        end

        if not canlaugh_joker_can_use_seal_effect(card) then
            return false
        end

        return canlaugh_joker_returned_effect(result, post)
    end

    local function canlaugh_shadow_seal_can_retry(card, context, result, post)
        if not (context and card and card.seal == "canlaugh_shadow") then
            return false
        end

        if context.blueprint
            or context.no_blueprint
            or context.canlaugh_shadow_seal_retry
            or context.retrigger_joker_check
            or context.retrigger_joker
            or context.post_trigger
            or (SMODS and type(SMODS.is_getter_context) == "function" and SMODS.is_getter_context(context))
        then
            return false
        end

        return canlaugh_joker_can_use_seal_effect(card)
            and not canlaugh_joker_returned_effect(result, post)
    end

    local function canlaugh_merge_joker_effects(first, second)
        if not first then
            return second
        end

        if not second then
            return first
        end

        if SMODS and type(SMODS.merge_effects) == "function" then
            return SMODS.merge_effects({ first }, { second })
        end

        local first_table = first == true and { remove = true } or first
        first_table.extra = second == true and { remove = true } or second
        return first_table
    end

    local function canlaugh_red_seal_self_retrigger(card, context, ...)
        local old_blueprint = context.blueprint
        local old_blueprint_card = context.blueprint_card
        local old_blueprint_copiers_stack = context.blueprint_copiers_stack
        local old_blueprint_copier = context.blueprint_copier
        local old_red_retrigger = context.canlaugh_red_seal_retrigger

        context.blueprint = (context.blueprint and (context.blueprint + 1)) or 1
        context.blueprint_card = context.blueprint_card or card
        context.blueprint_copiers_stack = context.blueprint_copiers_stack or {}
        context.blueprint_copiers_stack[#context.blueprint_copiers_stack + 1] = card
        context.blueprint_copier = context.blueprint_copiers_stack[#context.blueprint_copiers_stack]
        context.canlaugh_red_seal_retrigger = true

        local retrigger_result, retrigger_post = canlaugh_calculate_joker_ref(card, context, ...)

        context.blueprint = old_blueprint
        context.blueprint_card = old_blueprint_card
        table.remove(context.blueprint_copiers_stack, #context.blueprint_copiers_stack)
        context.blueprint_copiers_stack = old_blueprint_copiers_stack
        context.blueprint_copier = old_blueprint_copier
        context.canlaugh_red_seal_retrigger = old_red_retrigger

        if type(retrigger_result) == "table" then
            retrigger_result.card = retrigger_result.card or card
        end

        return retrigger_result, retrigger_post
    end

    local function canlaugh_shadow_seal_retry(card, context, ...)
        local old_ignore_debuff = context.ignore_debuff
        local old_shadow_retry = context.canlaugh_shadow_seal_retry

        context.ignore_debuff = true
        context.canlaugh_shadow_seal_retry = true
        local retry_result, retry_post = canlaugh_calculate_joker_ref(card, context, ...)
        context.ignore_debuff = old_ignore_debuff
        context.canlaugh_shadow_seal_retry = old_shadow_retry

        if type(retry_result) == "table" then
            retry_result.card = retry_result.card or card
        end

        return retry_result, retry_post
    end

    function Card:calculate_joker(context, ...)
        local result, post = canlaugh_calculate_joker_ref(self, context, ...)
        local effect = self.seal and CL.joker_seal_effects[self.seal]

        if effect and type(effect.calculate) == "function" then
            local seal_result, seal_post = effect.calculate(self, context, result, post)
            result = seal_result or result
            post = seal_post or post
        end

        if canlaugh_red_seal_can_self_retrigger(self, context, result, post) then
            local retrigger_result, retrigger_post = canlaugh_red_seal_self_retrigger(self, context, ...)
            result = canlaugh_merge_joker_effects(result, retrigger_result)
            post = post or retrigger_post
        end

        if canlaugh_shadow_seal_can_retry(self, context, result, post) then
            local retry_result, retry_post = canlaugh_shadow_seal_retry(self, context, ...)
            result = retry_result or result
            post = retry_post or post
        end

        if effect
            and type(effect.after_score) == "function"
        then
            local procced = canlaugh_is_real_joker_proc(self, context, result)
            if procced then
                self.canlaugh_joker_seal_last_proc_context = context
                effect.after_score(self, context, result, post)
            end
        elseif canlaugh_is_real_joker_proc(self, context, result) then
            self.canlaugh_joker_seal_last_proc_context = context
        end

        return result, post
    end
end

local JOKER_SHADOW_SEAL_EVAL_HOOK_VERSION = 1

if type(eval_card) == "function"
    and CL.joker_shadow_seal_eval_hook_version ~= JOKER_SHADOW_SEAL_EVAL_HOOK_VERSION
then
    CL.joker_shadow_seal_eval_hook_version = JOKER_SHADOW_SEAL_EVAL_HOOK_VERSION
    CL.joker_shadow_seal_eval_card_base_ref = CL.joker_shadow_seal_eval_card_base_ref or eval_card
    local canlaugh_eval_card_ref = CL.joker_shadow_seal_eval_card_base_ref

    local function canlaugh_shadow_seal_can_ignore_debuff(card, context, result)
        if not (card and card.debuff and card.seal == "canlaugh_shadow" and context) then
            return false
        end

        if context.ignore_debuff
            or context.blueprint
            or context.no_blueprint
            or context.canlaugh_shadow_seal_retry
            or context.retrigger_joker_check
            or context.retrigger_joker
            or context.post_trigger
            or (SMODS and type(SMODS.is_getter_context) == "function" and SMODS.is_getter_context(context))
        then
            return false
        end

        return canlaugh_joker_can_use_seal_effect(card)
            and not (result and result.jokers)
    end

    local function canlaugh_shadow_seal_debuff_context(context)
        local retry_context = {}

        for key, value in pairs(context) do
            retry_context[key] = value
        end

        retry_context.ignore_debuff = true
        retry_context.canlaugh_shadow_seal_retry = true
        return retry_context
    end

    function eval_card(card, context)
        local results = { canlaugh_eval_card_ref(card, context) }

        if canlaugh_shadow_seal_can_ignore_debuff(card, context, results[1]) then
            local retry_results = { canlaugh_eval_card_ref(card, canlaugh_shadow_seal_debuff_context(context)) }

            if retry_results[1] and retry_results[1].jokers then
                return unpack(retry_results)
            end
        end

        return unpack(results)
    end
end
