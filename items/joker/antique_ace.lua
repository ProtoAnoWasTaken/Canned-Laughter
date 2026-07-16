SMODS.Atlas({
    key = "antique_ace",
    path = "antiqueace.png",
    px = 69,
    py = 93,
})

local BANNED_ANTIQUE_SEALS = {
    canlaugh_phosphate = true,
    canlaugh_calcite = true,
}

local BANNED_ANTIQUE_CENTERS = {
    m_canlaugh_phosphate_backer = true,
    m_canlaugh_calcite_backer = true,
}

local function canlaugh_filtered_current_pool(pool_type, banned_keys)
    if type(get_current_pool) ~= "function" then
        return nil
    end

    local pool = get_current_pool(pool_type)
    local filtered_pool = {}
    local available_count = 0

    for _, entry in ipairs(pool or {}) do
        local key = type(entry) == "table" and entry.key or entry

        if key ~= "UNAVAILABLE" and not banned_keys[key] then
            filtered_pool[#filtered_pool + 1] = entry
            available_count = available_count + 1
        end
    end

    if available_count == 0 then
        return nil
    end

    return filtered_pool
end

local function canlaugh_poll_antique_enhancement(seed)
    if not (SMODS and type(SMODS.poll_enhancement) == "function") then
        return nil
    end

    local enhancement_key = SMODS.poll_enhancement({
        key = "canlaugh_antique_ace_enhancement_" .. seed,
        type_key = "canlaugh_antique_ace_enhancement_type_" .. seed,
        options = canlaugh_filtered_current_pool("Enhanced", BANNED_ANTIQUE_CENTERS),
    })

    return enhancement_key and G.P_CENTERS and G.P_CENTERS[enhancement_key]
end

local function canlaugh_poll_antique_edition(seed)
    if type(poll_edition) == "function" then
        return poll_edition("canlaugh_antique_ace_edition_" .. seed, 2, true)
    end

    if SMODS and type(SMODS.poll_edition) == "function" then
        return SMODS.poll_edition({
            key = "canlaugh_antique_ace_edition_" .. seed,
            mod = 2,
            no_negative = true,
        })
    end
end

local function canlaugh_poll_antique_seal(seed)
    if not (SMODS and type(SMODS.poll_seal) == "function") then
        return nil
    end

    local seal_key = SMODS.poll_seal({
        key = "canlaugh_antique_ace_seal_" .. seed,
        type_key = "canlaugh_antique_ace_seal_type_" .. seed,
        mod = 10,
        options = canlaugh_filtered_current_pool("Seal", BANNED_ANTIQUE_SEALS),
    })

    if seal_key and BANNED_ANTIQUE_SEALS[seal_key] then
        return nil
    end

    return seal_key
end

local function canlaugh_create_modified_replacement(source_card)
    if not (source_card and G and G.deck and type(create_playing_card) == "function") then
        return
    end

    local front = source_card.config and source_card.config.card
    local new_card = create_playing_card({
        front = front,
        center = G.P_CENTERS and G.P_CENTERS.c_base,
    }, G.deck, nil, nil, nil)

    if not new_card then
        return
    end

    local seed_suffix = table.concat({
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(G and G.GAME and G.GAME.hands_played or ""),
        tostring(source_card.sort_id or ""),
    }, "_")

    local enhancement = canlaugh_poll_antique_enhancement(seed_suffix)
    if enhancement and type(new_card.set_ability) == "function" then
        new_card:set_ability(enhancement, nil, true)
    end

    local edition = canlaugh_poll_antique_edition(seed_suffix)
    if edition and type(new_card.set_edition) == "function" then
        new_card:set_edition(edition, true, true)
    end

    local seal = canlaugh_poll_antique_seal(seed_suffix)
    if seal and type(new_card.set_seal) == "function" then
        new_card:set_seal(seal, true, true)
    end

    if type(playing_card_joker_effects) == "function" then
        playing_card_joker_effects({ new_card })
    end

    return new_card
end

local function canlaugh_first_discard_of_round()
    local round = G and G.GAME and G.GAME.current_round

    if not round then
        return true
    end

    return (round.discards_used or 0) == 0
end

local function canlaugh_pulse_antique_ace(card)
    if type(juice_card_until) ~= "function" then
        return
    end

    local eval = function()
        return canlaugh_first_discard_of_round()
            and card
            and card.ability
            and card.ability.extra
            and not card.ability.extra.used_this_round
            and not G.RESET_JIGGLES
    end

    juice_card_until(card, eval, true)
end

SMODS.Joker({
    key = "antique_ace",
    name = "Antique Ace",
    atlas = "antique_ace",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            used_this_round = false,
        },
    },
    loc_txt = {
        name = "Antique Ace",
        text = {
            "If {C:attention}first discard{} of round",
            "has only {C:attention}1{} card, destroy it",
            "and create a new one",
            "with {C:attention}random modifiers{}",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            card.ability.extra.used_this_round = false
            canlaugh_pulse_antique_ace(card)
            return
        end

        if not context.discard or context.blueprint then
            return
        end

        local discarded_cards = context.full_hand or {}

        if card.ability.extra.used_this_round
            or not canlaugh_first_discard_of_round()
            or #discarded_cards ~= 1
        then
            return
        end

        local discarded_card = discarded_cards[1]

        if not discarded_card or discarded_card.destroyed then
            return
        end

        card.ability.extra.used_this_round = true
        canlaugh_create_modified_replacement(discarded_card)

        return {
            message = "Remade!",
            colour = G.C.FILTER,
            remove = true,
        }
    end,
})
