SMODS.Shader({
    key = "glitter",
    path = "glitter.fs",
})

local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

if not CL.glitter_sell_value_hooked then
    CL.glitter_sell_value_hooked = true

    local canlaugh_glitter_set_sell_value = Card.set_sell_value
    function Card:set_sell_value(...)
        canlaugh_glitter_set_sell_value(self, ...)

        if self.edition and self.edition.key == "e_canlaugh_glitter" then
            self.sell_cost = self.sell_cost * 2
        end
    end
end

local function canlaugh_is_playing_card_type(card_type)
    return card_type == "Base"
        or card_type == "Default"
        or card_type == "Enhanced"
        or card_type == "Playing Card"
end

if type(create_card) == "function" and not CL.glitter_create_card_hook_installed then
    CL.glitter_create_card_hook_installed = true
    local canlaugh_glitter_create_card_ref = create_card

    function create_card(card_type, ...)
        local previous_context = CL.glitter_natural_playing_card_poll
        CL.glitter_natural_playing_card_poll = canlaugh_is_playing_card_type(card_type)

        local results = { canlaugh_glitter_create_card_ref(card_type, ...) }

        CL.glitter_natural_playing_card_poll = previous_context
        return unpack(results)
    end
end

local canlaugh_is_glitter = CL.is_glitter
local canlaugh_is_negative = CL.is_negative

local canlaugh_is_joker = CL.is_joker_card

local function canlaugh_glitter_can_receive(card, source)
    return card
        and card ~= source
        and not card.removed
        and not card.destroyed
        and not canlaugh_is_glitter(card)
        and not canlaugh_is_negative(card)
end

local function canlaugh_glitter_can_receive_from_consumable(card, source)
    return canlaugh_glitter_can_receive(card, source)
        and not (canlaugh_is_joker(card) and card.edition)
end

local function canlaugh_glitter_owned_spread_candidates(source)
    local candidates = {}
    local seen = {}

    local function add_area(area)
        for _, card in ipairs((area and area.cards) or {}) do
            if not seen[card] and canlaugh_glitter_can_receive_from_consumable(card, source) then
                candidates[#candidates + 1] = card
                seen[card] = true
            end
        end
    end

    add_area(G and G.consumeables)
    add_area(G and G.jokers)
    add_area(G and G.hand)

    for _, card in ipairs((G and G.playing_cards) or {}) do
        if not seen[card] and canlaugh_glitter_can_receive_from_consumable(card, source) then
            candidates[#candidates + 1] = card
            seen[card] = true
        end
    end

    return candidates
end

local function canlaugh_spread_used_consumable_glitter(source)
    local candidates = canlaugh_glitter_owned_spread_candidates(source)

    if #candidates == 0 then
        return
    end

    local target = pseudorandom_element(candidates, pseudoseed("canlaugh_glitter_consumable_use"))

    if not target then
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.15,
        func = function()
            if canlaugh_glitter_can_receive_from_consumable(target, source) then
                target:set_edition("e_canlaugh_glitter", true)
                card_eval_status_text(target, "extra", nil, nil, nil, {
                    message = "Spread!",
                    colour = G.C.CANLAUGH_GLITTER,
                })
            end
            return true
        end,
    }))
end

local function canlaugh_spread_glitter_in_area(area, area_key)
    local cards = area and area.cards
    if not cards or #cards < 2 then
        return
    end

    local sources = {}
    local claimed_targets = {}

    for index, card in ipairs(cards) do
        if canlaugh_is_glitter(card) then
            sources[#sources + 1] = { card = card, index = index }
        end
    end

    for _, source in ipairs(sources) do
        local candidates = {}

        for _, target_index in ipairs({ source.index - 1, source.index + 1 }) do
            local target = cards[target_index]

            if target
                and not claimed_targets[target]
                and not canlaugh_is_glitter(target)
                and not canlaugh_is_negative(target)
            then
                candidates[#candidates + 1] = target
            end
        end

        if #candidates > 0 then
            local ante = G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or 0
            local blind = G.GAME
                and G.GAME.round_resets
                and G.GAME.round_resets.blind
                and G.GAME.round_resets.blind.key or "blind"
            local seed = table.concat({
                "canlaugh_glitter_spread",
                area_key,
                tostring(ante),
                tostring(blind),
                tostring(source.index),
            }, "_")
            local target = pseudorandom_element(candidates, pseudoseed(seed))

            claimed_targets[target] = true
            target:set_edition("e_canlaugh_glitter", true)
            card_eval_status_text(target, "extra", nil, nil, nil, {
                message = "Spread!",
                colour = G.C.CANLAUGH_GLITTER,
            })
        end
    end
end

local function canlaugh_spread_glitter(area_group)
    if not G then
        return
    end

    local areas = area_group == "play" and {
        { area = G.play, key = "play" },
    } or {
        { area = G.jokers, key = "jokers" },
        { area = G.consumeables, key = "consumables" },
    }
    local seen_areas = {}

    for _, entry in ipairs(areas) do
        if entry.area and not seen_areas[entry.area] then
            seen_areas[entry.area] = true
            canlaugh_spread_glitter_in_area(entry.area, entry.key)
        end
    end
end

if SMODS and type(SMODS.calculate_context) == "function" and not CL.glitter_spread_hook_installed then
    CL.glitter_spread_hook_installed = true
    local canlaugh_glitter_calculate_context_ref = SMODS.calculate_context

    function SMODS.calculate_context(context, return_table, no_resolve, ...)
        local spread_group = context and (
            context.setting_blind and "tableau"
            or context.before and "play"
        )

        if spread_group and not CL.glitter_spread_running then
            CL.glitter_spread_running = true
            local spread_ok, spread_err = pcall(canlaugh_spread_glitter, spread_group)
            CL.glitter_spread_running = nil

            if not spread_ok and type(sendErrorMessage) == "function" then
                sendErrorMessage("[Canned Laughter] Glitter failed to spread: " .. tostring(spread_err))
            end
        end

        return canlaugh_glitter_calculate_context_ref(context, return_table, no_resolve, ...)
    end
end

if Card and type(Card.use_consumeable) == "function" and not CL.glitter_consumable_use_hook_installed then
    CL.glitter_consumable_use_hook_installed = true
    local canlaugh_glitter_use_consumeable_ref = Card.use_consumeable

    function Card:use_consumeable(area, copier, ...)
        local used_card = copier or self
        local should_spread = canlaugh_is_glitter(used_card)

        local results = { canlaugh_glitter_use_consumeable_ref(self, area, copier, ...) }

        if should_spread and not CL.glitter_consumable_use_spreading then
            CL.glitter_consumable_use_spreading = true
            local spread_ok, spread_err = pcall(canlaugh_spread_used_consumable_glitter, used_card)
            CL.glitter_consumable_use_spreading = nil

            if not spread_ok and type(sendErrorMessage) == "function" then
                sendErrorMessage("[Canned Laughter] Glitter consumable spread failed: " .. tostring(spread_err))
            end
        end

        return unpack(results)
    end
end

SMODS.Edition({
    key = "glitter",
    order = 21,
    shader = "glitter",
    badge_colour = G.C.CANLAUGH_GLITTER,
    in_shop = true,
    weight = 40 / 7,
    extra_cost = 3,
    canlaugh_native_sound = {
        path = "glitter.ogg",
        pitch = 1,
        volume = 0.25,
    },
    loc_txt = {
        name = "Glitter",
        label = "Glitter",
        text = {
            "Doubled {C:money}sell value{}",
            "Spreads to an {C:attention}adjacent{} card",
            "{C:attention}Consumables{} spread when used",
            "{C:dark_edition}Negative{} blocks spread",
        },
    },
    get_weight = function(self, base_weight, args)
        local seed = tostring(args and args.seed or "")
        local natural_playing_card_roll = CL.glitter_natural_playing_card_poll
            or seed == "illusion"
            or seed:match("^standard_edition") ~= nil

        if natural_playing_card_roll then
            return 0
        end

        return (G.GAME and G.GAME.edition_rate or 1) * self.weight
    end,
})
