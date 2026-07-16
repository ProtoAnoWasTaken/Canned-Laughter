local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({
    key = "still_life",
    path = "still_life.png",
    px = 69,
    py = 93,
})

if CannedLaughter.barter then
    CannedLaughter.barter.register_rep_modifier("still_life", function(phase, context)
        if phase == "availability" then
            if (context.base_reps or 0) > 0 then context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_still_life") or {}) end
            return
        end
        if phase == "hand" then
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_still_life") or {}) do
                local cards = CannedLaughter.barter.hand_area and CannedLaughter.barter.hand_area.cards or {}
                local source = cards[math.floor(pseudorandom("canlaugh_still_life_trial") * #cards) + 1]
                if source and source.canlaugh_barter_rep then CannedLaughter.barter.add_rep(copy_table(source.canlaugh_barter_rep), joker) end
            end
        end
    end)
end

local function canlaugh_mark_temporary_copy(card)
    card.ability.canlaugh_temporary_still_life = true
    card.ability.canlaugh_temporary = true
end

local function canlaugh_create_temporary_copy(source_card)
    if not (source_card and G and G.hand and type(copy_card) == "function") then
        return
    end

    G.playing_card = (G.playing_card and G.playing_card + 1) or 1
    CL.suppress_playing_card_acquired_unlock = true
    local copy = copy_card(source_card, nil, nil, G.playing_card)
    CL.suppress_playing_card_acquired_unlock = nil

    if not copy then
        return
    end

    canlaugh_mark_temporary_copy(copy)
    copy:add_to_deck()
    G.deck.config.card_limit = G.deck.config.card_limit + 1
    table.insert(G.playing_cards, copy)
    G.hand:emplace(copy)
    copy.states.visible = nil

    if type(playing_card_joker_effects) == "function" then
        playing_card_joker_effects({ copy })
    end

    G.E_MANAGER:add_event(Event({
        func = function()
            copy:start_materialize()
            return true
        end,
    }))

    return copy
end

local function canlaugh_still_life_temporary_cards()
    local cards = {}

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card
            and playing_card.ability
            and playing_card.ability.canlaugh_temporary_still_life
            and not playing_card.destroyed
        then
            cards[#cards + 1] = playing_card
        end
    end

    return cards
end

local function canlaugh_silent_clipped_text(card)
    if not (card and type(attention_text) == "function") then
        return
    end

    G.E_MANAGER:add_event(Event({
        func = function()
            attention_text({
                text = "Clipped!",
                scale = 0.7,
                hold = 0.7,
                backdrop_colour = G.C.FILTER,
                align = card.area == G.hand and "tm" or "bm",
                major = card,
                offset = { x = 0, y = card.area == G.hand and -0.05 * G.CARD_H or 0.15 * G.CARD_H },
            })
            return true
        end,
    }))
end

local function canlaugh_clip_temporary_card(card)
    if not card then
        return
    end

    card.destroyed = true
    canlaugh_silent_clipped_text(card)

    G.E_MANAGER:add_event(Event({
        func = function()
            if G and G.deck and G.deck.config then
                G.deck.config.card_limit = math.max(0, (G.deck.config.card_limit or 0) - 1)
            end
            if type(card.start_dissolve) == "function" then
                card:start_dissolve(nil, true, nil, true)
            end
            return true
        end,
    }))
end

SMODS.Joker({
    key = "still_life",
    name = "Still Life",
    atlas = "still_life",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 4,
    unlocked = false,
    loc_txt = {
        name = "Still Life",
        text = {
            "Adds one {C:attention}temporary copy{}",
            "of a card drawn to hand",
            "when {C:attention}Blind{} is selected",
        },
        unlock = {
            "Create or purchase at least",
            "{C:attention}20{} playing cards",
            "in one run",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args
            and args.type == "canlaugh_playing_cards_acquired"
            and (args.amount or 0) >= 20
    end,
    calculate = function(self, card, context)
        if context.first_hand_drawn
            and not context.blueprint
            and context.hand_drawn
            and #context.hand_drawn > 0
        then
            local source = pseudorandom_element(context.hand_drawn, pseudoseed("canlaugh_still_life"))
            local copy = canlaugh_create_temporary_copy(source)

            if copy then
                return {
                    message = "Copied!",
                    colour = G.C.FILTER,
                }
            end
        end

        if context.after and not context.blueprint then
            local temporary_cards = canlaugh_still_life_temporary_cards()

            for _, temporary_card in ipairs(temporary_cards) do
                canlaugh_clip_temporary_card(temporary_card)
            end
        end
    end,
})
