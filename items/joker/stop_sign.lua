local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "stop_sign",
    path = "stop_sign.png",
    px = 69,
    py = 93,
})

local function canlaugh_has_stop_sign()
    if not (G and G.jokers and G.jokers.cards) then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        if joker
            and not joker.debuff
            and joker.config
            and (
                joker.config.center_key == "j_canlaugh_stop_sign"
                or joker.config.center_key == "j_stop_sign"
                or joker.config.center_key == "j_canlaugh_lag_train"
                or joker.config.center_key == "j_lag_train"
            )
        then
            return true
        end
    end

    return false
end

local function canlaugh_should_sunshower_delay(card, edition_effect)
    local PCJ = CL.playing_card_jokers
    return PCJ
        and edition_effect
        and PCJ.should_suppress_polychrome_scoring
        and PCJ.should_suppress_polychrome_scoring(card)
end

local function canlaugh_should_oil_chamber_suppress(card, edition_effect)
    local PCJ = CL.playing_card_jokers
    return PCJ
        and edition_effect
        and PCJ.should_suppress_holographic_scoring
        and PCJ.should_suppress_holographic_scoring(card)
end

local function canlaugh_should_intercept_playing_card_editions()
    local PCJ = CL.playing_card_jokers
    return canlaugh_has_stop_sign()
        or (PCJ and PCJ.sunshower_active and PCJ.sunshower_active())
        or (PCJ and PCJ.oil_chamber_active and PCJ.oil_chamber_active())
end

local function canlaugh_is_queued_scoring_card(scored_card)
    return scored_card
        and CL.stop_sign_scoring_cards
        and CL.stop_sign_scoring_cards[scored_card]
end

local function canlaugh_split_playing_card_edition_effects(scored_card, effects)
    local immediate = {}
    local delayed = {}

    for _, effect in ipairs(effects or {}) do
        local delayed_edition = effect and effect.edition
        local suppress_edition = canlaugh_should_oil_chamber_suppress(scored_card, delayed_edition)
        local sunshower_delay = canlaugh_should_sunshower_delay(scored_card, delayed_edition)
        local stop_sign_delay = delayed_edition
            and canlaugh_has_stop_sign()
            and canlaugh_is_queued_scoring_card(scored_card)
        local delay_edition = not suppress_edition and (sunshower_delay or stop_sign_delay)

        if delay_edition then
            delayed[#delayed + 1] = { edition = delayed_edition }
        end

        local immediate_effect = effect
        if delayed_edition and (suppress_edition or delay_edition) then
            immediate_effect = {}
            for key, value in pairs(effect) do
                if key ~= "edition" then
                    immediate_effect[key] = value
                end
            end
        end

        if next(immediate_effect) then
            immediate[#immediate + 1] = immediate_effect
        end
    end

    return immediate, delayed
end

local function canlaugh_queue_stop_sign_effects(scored_card, effects)
    if not (scored_card and type(effects) == "table" and #effects > 0) then
        return
    end

    CL.stop_sign_queue = CL.stop_sign_queue or {}
    CL.stop_sign_queue[scored_card] = CL.stop_sign_queue[scored_card] or {}

    local queue = CL.stop_sign_queue[scored_card]
    for _, effect in ipairs(effects) do
        queue[#queue + 1] = effect
    end
end

local function canlaugh_pop_stop_sign_effects(scored_card)
    local queue = CL.stop_sign_queue and CL.stop_sign_queue[scored_card]

    if not queue then
        return nil
    end

    CL.stop_sign_queue[scored_card] = nil
    return queue
end

local function canlaugh_clear_stop_sign_scoring_state()
    CL.stop_sign_scoring_hand = nil
    CL.stop_sign_scoring_cards = nil
end

local function canlaugh_flush_stop_sign_queue(scoring_hand)
    if not (CL.stop_sign_queue and scoring_hand and SMODS and SMODS.trigger_effects) then
        return
    end

    CL.stop_sign_replaying = true

    for _, scored_card in ipairs(scoring_hand) do
        local delayed_effects = canlaugh_pop_stop_sign_effects(scored_card)

        if delayed_effects and #delayed_effects > 0 then
            SMODS.trigger_effects(delayed_effects, scored_card)
        end
    end

    CL.stop_sign_replaying = nil
    CL.stop_sign_queue = nil
    canlaugh_clear_stop_sign_scoring_state()
end

local function canlaugh_joker_area_contains(card)
    if not (card and SMODS and SMODS.get_card_areas) then
        return false
    end

    for _, area in ipairs(SMODS.get_card_areas("jokers")) do
        for _, joker in ipairs(area.cards or {}) do
            if joker == card then
                return true
            end
        end
    end

    return false
end

local function canlaugh_is_last_joker_area_card(card)
    if not (card and SMODS and SMODS.get_card_areas) then
        return false
    end

    local last_joker
    for _, area in ipairs(SMODS.get_card_areas("jokers")) do
        for _, joker in ipairs(area.cards or {}) do
            last_joker = joker
        end
    end

    return last_joker == card
end

local function canlaugh_finish_stop_sign_joker_scoring(card)
    if CL.stop_sign_queue
        and canlaugh_joker_area_contains(card)
        and canlaugh_is_last_joker_area_card(card)
    then
        canlaugh_flush_stop_sign_queue(CL.stop_sign_scoring_hand)
    end
end

local function canlaugh_install_stop_sign_hooks()
    if CL.stop_sign_hooks_installed
        or not (SMODS and SMODS.calculate_context and SMODS.calculate_main_scoring and SMODS.trigger_effects)
    then
        return
    end

    CL.stop_sign_hooks_installed = true

    local calculate_main_scoring_ref = SMODS.calculate_main_scoring
    function SMODS.calculate_main_scoring(context, scoring_hand, ...)
        local should_delay = canlaugh_should_intercept_playing_card_editions()
            and context
            and context.cardarea == G.play
            and scoring_hand

        if should_delay then
            CL.stop_sign_scoring_hand = scoring_hand
            CL.stop_sign_scoring_cards = {}
            for _, scored_card in ipairs(scoring_hand) do
                CL.stop_sign_scoring_cards[scored_card] = true
            end
        end

        local results = { calculate_main_scoring_ref(context, scoring_hand, ...) }

        if should_delay and not CL.stop_sign_queue then
            canlaugh_clear_stop_sign_scoring_state()
        end

        return unpack(results)
    end

    local trigger_effects_ref = SMODS.trigger_effects
    function SMODS.trigger_effects(effects, card)
        if canlaugh_should_intercept_playing_card_editions()
            and not CL.stop_sign_replaying
            and canlaugh_is_queued_scoring_card(card)
        then
            local immediate_effects, delayed_effects = canlaugh_split_playing_card_edition_effects(card, effects)
            canlaugh_queue_stop_sign_effects(card, delayed_effects)

            local flags = trigger_effects_ref(immediate_effects, card) or {}
            if delayed_effects and #delayed_effects > 0 then
                flags.calculated = true
            end

            return flags
        end

        local flags = trigger_effects_ref(effects, card)
        canlaugh_finish_stop_sign_joker_scoring(card)
        return flags
    end

    if type(SMODS.eval_individual) == "function" then
        local eval_individual_ref = SMODS.eval_individual
        function SMODS.eval_individual(area, context, ...)
            if CL.stop_sign_queue
                and not CL.stop_sign_replaying
                and context
                and context.main_scoring
            then
                canlaugh_flush_stop_sign_queue(CL.stop_sign_scoring_hand)
            end

            return eval_individual_ref(area, context, ...)
        end
    end

    local calculate_context_ref = SMODS.calculate_context
    function SMODS.calculate_context(context, return_table, no_resolve)
        if CL.stop_sign_queue
            and not CL.stop_sign_replaying
            and context
            and context.final_scoring_step
        then
            canlaugh_flush_stop_sign_queue(CL.stop_sign_scoring_hand)
        end

        return calculate_context_ref(context, return_table, no_resolve)
    end
end

canlaugh_install_stop_sign_hooks()

SMODS.Joker({
    key = "stop_sign",
    name = "Stop Sign",
    atlas = "stop_sign",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    loc_txt = {
        name = "Stop Sign",
        text = {
            "{C:dark_edition}Edition{} effects from",
            "{C:attention}playing cards{} score",
            "after {C:attention}Jokers{} finish scoring",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
})
