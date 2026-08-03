local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local FROZEN_KEY = "e_canlaugh_frozen"
local FROZEN_TYPE = "canlaugh_frozen"
local THAW_ODDS = 6

local function is_frozen(card)
    return card
        and card.edition
        and (card.edition.key == FROZEN_KEY or card.edition[FROZEN_TYPE])
        or false
end

CL.is_frozen = is_frozen

local function copy_value(value, state, depth)
    if type(value) ~= "table" then
        return value
    end

    if depth >= 6 or state.count >= 256 then
        return nil
    end

    if state.seen[value] then
        return state.seen[value]
    end

    local copied = {}
    state.seen[value] = copied
    state.count = state.count + 1

    for key, entry in pairs(value) do
        if type(key) ~= "table" then
            local copied_entry = copy_value(entry, state, depth + 1)
            if copied_entry ~= nil or entry == nil then
                copied[key] = copied_entry
            end
        end
    end

    return copied
end

local function copy_ability(ability)
    if type(ability) ~= "table" then
        return {}
    end

    return copy_value(ability, {
        count = 0,
        seen = {},
    }, 0) or {}
end

local function restore_ability(card)
    local frozen_ability = card and card.canlaugh_frozen_ability
    if not frozen_ability then
        return
    end

    local ability = card.ability
    if type(ability) ~= "table" then
        card.ability = copy_ability(frozen_ability)
        return
    end

    for key in pairs(ability) do
        ability[key] = nil
    end

    for key, value in pairs(frozen_ability) do
        ability[key] = copy_ability({ value = value }).value
    end
end

local function capture_ability(card)
    if is_frozen(card) then
        card.canlaugh_frozen_ability = copy_ability(card.ability)
    end
end

local function is_frozen_food(card)
    return is_frozen(card)
        and type(CL.center_is_food) == "function"
        and CL.center_is_food(card.config and card.config.center)
end

local function thaw_card(card)
    if not is_frozen(card) then
        return false
    end

    CL.frozen_internal_edition_change = true
    card:set_edition(nil, true, true)
    CL.frozen_internal_edition_change = nil
    card.canlaugh_frozen_ability = nil

    if type(card.juice_up) == "function" then
        card:juice_up(0.8, 0.5)
    end

    if type(play_sound) == "function" then
        play_sound("glass1", 1, 0.5)
    end

    if type(card_eval_status_text) == "function" then
        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "Thawed!",
            colour = G.C.CANLAUGH_FROZEN,
        })
    end

    return true
end

CL.thaw_frozen = thaw_card

local function for_each_run_card(callback)
    local seen = {}
    local areas = {
        G and G.jokers,
        G and G.consumeables,
        G and G.hand,
        G and G.play,
        G and G.deck,
        G and G.discard,
    }

    for _, area in ipairs(areas) do
        for _, card in ipairs((area and area.cards) or {}) do
            seen[card] = true
            callback(card)
        end
    end

    for _, card in ipairs((G and G.playing_cards) or {}) do
        if not seen[card] then
            callback(card)
        end
    end
end

local function score_caught_fire()
    local helpers = CL.playing_card_jokers
    return helpers
        and type(helpers.score_caught_fire) == "function"
        and helpers.score_caught_fire(G and G.ARGS and G.ARGS.score_intensity)
        or false
end

function CL.resolve_frozen_after_score()
    local round = G and G.GAME and G.GAME.current_round
    local hands_played = round and round.hands_played
    if round
        and hands_played ~= nil
        and round.canlaugh_frozen_resolved_hand == hands_played
    then
        return
    end

    if round and hands_played ~= nil then
        round.canlaugh_frozen_resolved_hand = hands_played
    end

    local caught_fire = score_caught_fire()
    local index = 0

    for_each_run_card(function(card)
        if not is_frozen(card) then
            return
        end

        index = index + 1
        local hot = type(CL.is_hot_card) == "function"
            and CL.is_hot_card(card)
            and not (type(CL.balefire_active) == "function" and CL.balefire_active())
        local thaw_from_fire = caught_fire
            and pseudorandom("canlaugh_frozen_fire_" .. tostring(card.sort_id or index)) < (1 / THAW_ODDS)

        if hot or thaw_from_fire then
            thaw_card(card)
        end
    end)
end

local function canlaugh_hot_thaw_roll(source, target)
    local game = G and G.GAME
    if not game then
        return false
    end

    game.canlaugh_frozen_hot_trigger_index = (game.canlaugh_frozen_hot_trigger_index or 0) + 1
    local seed = table.concat({
        "canlaugh_frozen_hot",
        tostring(source.sort_id or "source"),
        tostring(target.sort_id or "target"),
        tostring(game.canlaugh_frozen_hot_trigger_index),
    }, "_")

    return pseudorandom(seed) < (1 / THAW_ODDS)
end

local function canlaugh_thaw_hot_card_neighbors(source)
    if not source
        or not (type(CL.is_hot_card) == "function" and CL.is_hot_card(source))
        or (type(CL.balefire_active) == "function" and CL.balefire_active())
    then
        return
    end

    local cards = source.area and source.area.cards
    if not cards then
        return
    end

    local source_index = nil
    for index, card in ipairs(cards) do
        if card == source then
            source_index = index
            break
        end
    end

    if not source_index then
        return
    end

    for _, target_index in ipairs({ source_index - 1, source_index + 1 }) do
        local target = cards[target_index]
        if target and is_frozen(target) and canlaugh_hot_thaw_roll(source, target) then
            thaw_card(target)
        end
    end
end

local function canlaugh_thaw_neighbors_from_hot_effects(effects, fallback_source)
    for _, effect_table in ipairs(effects or {}) do
        local thawed_sources = {}

        for _, key in ipairs({ "playing_card", "enhancement", "edition", "seals", "jokers", "individual" }) do
            local effect = effect_table[key]
            local source = type(effect) == "table" and effect.card or nil

            if not source
                and key ~= "jokers"
                and key ~= "individual"
            then
                source = fallback_source
            end

            if source and not thawed_sources[source] then
                thawed_sources[source] = true
                canlaugh_thaw_hot_card_neighbors(source)
            end
        end
    end
end

if Card and type(Card.calculate_joker) == "function" and not CL.frozen_joker_hook_installed then
    CL.frozen_joker_hook_installed = true
    local calculate_joker_ref = Card.calculate_joker

    function Card:calculate_joker(context, ...)
        local frozen = is_frozen(self)
        local frozen_target = context and context.other_card
        frozen_target = is_frozen(frozen_target) and context.other_card or nil

        if frozen then
            restore_ability(self)
        end

        if frozen_target then
            restore_ability(frozen_target)
        end

        local result, post = calculate_joker_ref(self, context, ...)

        if frozen then
            restore_ability(self)
        end

        if frozen_target then
            restore_ability(frozen_target)
        end

        return result, post
    end
end

if Card and type(Card.set_ability) == "function" and not CL.frozen_ability_change_hook_installed then
    CL.frozen_ability_change_hook_installed = true
    local set_ability_ref = Card.set_ability

    function Card:set_ability(center, initial, delay_sprites)
        if is_frozen(self) and not initial then
            restore_ability(self)
            return
        end

        return set_ability_ref(self, center, initial, delay_sprites)
    end
end

if Card and type(Card.set_base) == "function" and not CL.frozen_base_change_hook_installed then
    CL.frozen_base_change_hook_installed = true
    local set_base_ref = Card.set_base

    function Card:set_base(base, initial, delay_sprites, ...)
        if is_frozen(self) and not initial then
            return
        end

        return set_base_ref(self, base, initial, delay_sprites, ...)
    end
end

if Card and type(Card.set_edition) == "function" and not CL.frozen_edition_change_hook_installed then
    CL.frozen_edition_change_hook_installed = true
    local set_edition_ref = Card.set_edition

    function Card:set_edition(edition, immediate, silent, ...)
        if is_frozen(self) and not CL.frozen_internal_edition_change then
            return
        end

        return set_edition_ref(self, edition, immediate, silent, ...)
    end
end

if Card and type(Card.set_eternal) == "function" and not CL.frozen_eternal_change_hook_installed then
    CL.frozen_eternal_change_hook_installed = true
    local set_eternal_ref = Card.set_eternal

    function Card:set_eternal(eternal, ...)
        if is_frozen(self) then
            return
        end

        return set_eternal_ref(self, eternal, ...)
    end
end

if Card and type(Card.set_seal) == "function" and not CL.frozen_seal_change_hook_installed then
    CL.frozen_seal_change_hook_installed = true
    local set_seal_ref = Card.set_seal

    function Card:set_seal(seal, silent, immediate, ...)
        if is_frozen(self) then
            return
        end

        return set_seal_ref(self, seal, silent, immediate, ...)
    end
end

if Card and type(Card.calculate_perishable) == "function" and not CL.frozen_perishable_hook_installed then
    CL.frozen_perishable_hook_installed = true
    local calculate_perishable_ref = Card.calculate_perishable

    function Card:calculate_perishable(...)
        if is_frozen_food(self) then
            return
        end

        return calculate_perishable_ref(self, ...)
    end
end

if Card and type(Card.start_dissolve) == "function" and not CL.frozen_food_dissolve_hook_installed then
    CL.frozen_food_dissolve_hook_installed = true
    local start_dissolve_ref = Card.start_dissolve

    function Card:start_dissolve(...)
        if is_frozen_food(self) then
            self.destroyed = nil
            self.getting_sliced = nil
            self.shattered = nil
            return
        end

        return start_dissolve_ref(self, ...)
    end
end

if SMODS and type(SMODS.destroy_cards) == "function" and not CL.frozen_food_destroy_hook_installed then
    CL.frozen_food_destroy_hook_installed = true
    local destroy_cards_ref = SMODS.destroy_cards

    function SMODS.destroy_cards(cards, ...)
        if not cards then
            return destroy_cards_ref(cards, ...)
        end

        local targets = cards[1] and cards or { cards }
        local survivors = {}

        for _, card in ipairs(targets) do
            if is_frozen_food(card) then
                card.destroyed = nil
                card.getting_sliced = nil
                card.shattered = nil
            else
                survivors[#survivors + 1] = card
            end
        end

        if #survivors == 0 then
            return
        end

        return destroy_cards_ref(survivors, ...)
    end
end

if SMODS and type(SMODS.get_probability_vars) == "function" and not CL.frozen_probability_hook_installed then
    CL.frozen_probability_hook_installed = true
    local get_probability_vars_ref = SMODS.get_probability_vars

    function SMODS.get_probability_vars(trigger_obj, numerator, denominator, ...)
        if is_frozen(trigger_obj) then
            return numerator, denominator
        end

        return get_probability_vars_ref(trigger_obj, numerator, denominator, ...)
    end
end

if SMODS and type(SMODS.trigger_effects) == "function" and not CL.frozen_hot_neighbor_hook_installed then
    CL.frozen_hot_neighbor_hook_installed = true
    local trigger_effects_ref = SMODS.trigger_effects

    function SMODS.trigger_effects(effects, card, ...)
        local results = {
            trigger_effects_ref(effects, card, ...),
        }
        canlaugh_thaw_neighbors_from_hot_effects(effects, card)
        return unpack(results)
    end
end

if SMODS and type(SMODS.calculate_context) == "function" and not CL.frozen_score_hook_installed then
    CL.frozen_score_hook_installed = true
    local calculate_context_ref = SMODS.calculate_context

    function SMODS.calculate_context(context, return_table, no_resolve)
        local result = calculate_context_ref(context, return_table, no_resolve)

        if context and context.final_scoring_step then
            CL.resolve_frozen_after_score()
        end

        return result
    end
end

SMODS.Shader({
    key = "frozen",
    path = "frozen.fs",
})

SMODS.Edition({
    key = "frozen",
    order = 23,
    shader = "frozen",
    badge_colour = G.C.CANLAUGH_FROZEN,
    in_shop = true,
    weight = 40 / 7,
    extra_cost = 3,
    canlaugh_native_sound = {
        path = "frozen.ogg",
        pitch = 1,
        volume = 0.25,
    },
    loc_txt = {
        name = "Frozen",
        label = "Frozen",
        text = {
            "Cannot be changed in any way",
            "{C:green}1 in 6{} chance to thaw when",
            "the score {C:attention}catches fire{}",
            "{C:attention}Hot{} cards may thaw adjacent",
            "{C:canlaugh_frozen}Frozen{} cards when triggered",
        },
    },
    get_weight = function(self, base_weight, args)
        local seed = tostring(args and args.seed or "")
        if seed == "illusion" or seed:match("^standard_edition") then
            return 0
        end

        return (G.GAME and G.GAME.edition_rate or 1) * self.weight
    end,
    on_apply = function(card)
        capture_ability(card)
    end,
    on_load = function(card)
        capture_ability(card)
    end,
    on_remove = function(card)
        card.canlaugh_frozen_ability = nil
    end,
})
