G.C.CANLAUGH_SHADOW = G.C.CANLAUGH_SHADOW or HEX("7A4B92")

local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_has_shadow_seal(card)
    return card and card.seal == "canlaugh_shadow"
end

local function canlaugh_card_is_in_area(card, area)
    if not card then
        return false
    end

    if card.area == area then
        return true
    end

    for _, area_card in ipairs((area and area.cards) or {}) do
        if area_card == card then
            return true
        end
    end

    return false
end

local function canlaugh_card_is_in_played_or_unplayed_hand(card)
    return canlaugh_card_is_in_area(card, G and G.hand)
        or canlaugh_card_is_in_area(card, G and G.play)
end

local function canlaugh_shadow_card_chips(card)
    if not (card and type(card.get_chip_bonus) == "function") then
        return 0
    end

    local chips = card:get_chip_bonus() or 0
    local enhancement_chips = card.ability and card.ability.bonus or 0

    return math.max(chips - enhancement_chips, 0)
end

local function canlaugh_shadow_trigger_cards()
    local cards = {}
    local seen = {}

    local function add_card(card)
        if card
            and not seen[card]
            and canlaugh_has_shadow_seal(card)
            and not canlaugh_card_is_in_played_or_unplayed_hand(card)
        then
            cards[#cards + 1] = card
            seen[card] = true
        end
    end

    local function add_area(area)
        for _, card in ipairs((area and area.cards) or {}) do
            add_card(card)
        end
    end

    add_area(G and G.deck)
    add_area(G and G.discard)

    for _, card in ipairs((G and G.playing_cards) or {}) do
        add_card(card)
    end

    return cards
end

local function canlaugh_discarded_shadow_cards(context)
    local cards = {}
    local seen = {}

    for _, card in ipairs((context and context.full_hand) or {}) do
        if card
            and not seen[card]
            and canlaugh_has_shadow_seal(card)
        then
            cards[#cards + 1] = card
            seen[card] = true
        end
    end

    return cards
end

local function canlaugh_trigger_shadow_cards(context, cards, args)
    if not G then
        return
    end

    local shadow_context = {
        cardarea = G.hand,
        full_hand = context.full_hand,
        scoring_hand = context.scoring_hand,
        scoring_name = context.scoring_name,
        poker_hands = context.poker_hands,
        main_scoring = true,
        canlaugh_shadow_deck_trigger = true,
    }

    for _, shadow_card in ipairs(cards or {}) do
        if canlaugh_has_shadow_seal(shadow_card)
            and not shadow_card.debuff
            and not canlaugh_card_is_in_played_or_unplayed_hand(shadow_card)
            and not SMODS.check_looping_context(shadow_card)
        then
            SMODS.current_evaluated_object = shadow_card
            local effects = { eval_card(shadow_card, shadow_context) }
            SMODS.calculate_quantum_enhancements(shadow_card, effects, shadow_context)

            local chips = canlaugh_shadow_card_chips(shadow_card)
            if chips > 0 then
                effects[1] = effects[1] or {}
                effects[1].playing_card = effects[1].playing_card or {}
                effects[1].playing_card.chips = chips
            end

            if args and args.suppress_seal_message and effects[1] then
                effects[1].seals = nil
            elseif effects[1] and effects[1].seals then
                effects[1].seals.message = effects[1].seals.message or "Shadow!"
                effects[1].seals.colour = effects[1].seals.colour or G.C.CANLAUGH_SHADOW
            end

            SMODS.trigger_effects(effects, shadow_card)
        end
    end

    SMODS.current_evaluated_object = nil
end

local function canlaugh_trigger_shadow_seals(context)
    canlaugh_trigger_shadow_cards(context, canlaugh_shadow_trigger_cards())
end

local function canlaugh_queue_discarded_shadow_seals(context)
    local discarded_cards = canlaugh_discarded_shadow_cards(context)

    if #discarded_cards == 0 then
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.15,
        func = function()
            local ok, err = pcall(canlaugh_trigger_shadow_cards, context, discarded_cards, {
                suppress_seal_message = true,
            })

            if not ok and type(sendErrorMessage) == "function" then
                sendErrorMessage("[Canned Laughter] Shadow Seal discard trigger failed: " .. tostring(err))
            end

            return true
        end,
    }))
end

if SMODS and type(SMODS.calculate_context) == "function" and not CL.shadow_seal_hook_installed then
    CL.shadow_seal_hook_installed = true
    local cl_shadow_calculate_context_ref = SMODS.calculate_context

    function SMODS.calculate_context(context, return_table, no_resolve)
        local results = { cl_shadow_calculate_context_ref(context, return_table, no_resolve) }

        if context
            and context.initial_scoring_step
            and not context.canlaugh_shadow_deck_trigger
            and not CL.shadow_seal_trigger_running
        then
            CL.shadow_seal_trigger_running = true
            local ok, err = pcall(canlaugh_trigger_shadow_seals, context)
            CL.shadow_seal_trigger_running = nil

            if not ok and type(sendErrorMessage) == "function" then
                sendErrorMessage("[Canned Laughter] Shadow Seal failed to trigger: " .. tostring(err))
            end
        end

        if context
            and context.discard
            and not context.canlaugh_shadow_deck_trigger
            and not CL.shadow_seal_discard_trigger_running
        then
            CL.shadow_seal_discard_trigger_running = true
            local ok, err = pcall(canlaugh_queue_discarded_shadow_seals, context)
            CL.shadow_seal_discard_trigger_running = nil

            if not ok and type(sendErrorMessage) == "function" then
                sendErrorMessage("[Canned Laughter] Shadow Seal discard queue failed: " .. tostring(err))
            end
        end

        return unpack(results)
    end
end

SMODS.Atlas({
    key = "shadow_seal",
    path = "shadow_seal.png",
    px = 69,
    py = 93,
})

SMODS.Seal({
    key = "shadow",
    atlas = "shadow_seal",
    pos = { x = 0, y = 0 },
    badge_colour = G.C.CANLAUGH_SHADOW,
    discovered = true,
    loc_txt = {
        label = "Shadow Seal",
        name = "Shadow Seal",
        text = {
            "{C:canlaugh_shadow}Triggers{} and scores",
            "this card's {C:chips}Chips{} while",
            "in {C:attention}deck{} or {C:attention}discard{}",
        },
    },
    calculate = function(self, card, context)
        if context.canlaugh_shadow_deck_trigger then
            return {
                message = "Shadow!",
                colour = G.C.CANLAUGH_SHADOW,
                card = card,
            }
        end
    end,
})
