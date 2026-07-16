SMODS.Atlas({
    key = "inland_empire",
    path = "inland_empire.png",
    px = 69,
    py = 93,
})

local CL = rawget(_G, "CannedLaughter") or {}

local INLAND_RULES_CARD_RARE_ODDS = 100
local INLAND_RULES_CARD_EXCLUDED_SPECTRALS = {
    c_canlaugh_crimson_king = true,
    c_canlaugh_city_keeper = true,
    c_crimson_king = true,
    c_city_keeper = true,
    canlaugh_crimson_king = true,
    canlaugh_city_keeper = true,
    crimson_king = true,
    city_keeper = true,
}

local function canlaugh_rules_card_active()
    return CL.rules_card_active and CL.rules_card_active()
end

local function canlaugh_has_consumable_room()
    if CL.tarot and type(CL.tarot.has_consumable_room) == "function" then
        return CL.tarot.has_consumable_room(1)
    end

    return G
        and G.consumeables
        and G.GAME
        and (
            #G.consumeables.cards + (G.GAME.consumeable_buffer or 0) < G.consumeables.config.card_limit
            or (CL.rules_card_active and CL.rules_card_active())
        )
end

local function canlaugh_create_consumable(card_type, seed, forced_key, achievement_event)
    if not canlaugh_has_consumable_room() then
        return
    end

    G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
    G.E_MANAGER:add_event(Event({
        trigger = "before",
        delay = 0.0,
        func = function()
            local consumable = create_card(card_type, G.consumeables, nil, nil, nil, nil, forced_key, seed)
            consumable:add_to_deck()
            G.consumeables:emplace(consumable)
            if achievement_event and type(check_for_unlock) == "function" then
                check_for_unlock({ type = achievement_event })
            end
            G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 1) - 1)
            return true
        end,
    }))
end

local function canlaugh_inland_rules_card_rare_key(card)
    if not (canlaugh_rules_card_active() and G and G.P_CENTERS) then
        return nil
    end

    if not SMODS.pseudorandom_probability(card, "canlaugh_inland_empire_rules_card_rare", 1, INLAND_RULES_CARD_RARE_ODDS) then
        return nil
    end

    local available = {}
    local seen = {}

    local function add_spectral(center_or_key, fallback_key)
        local key = type(center_or_key) == "table" and (center_or_key.key or fallback_key) or center_or_key
        local center = type(center_or_key) == "table" and center_or_key or G.P_CENTERS[key]

        if key
            and center
            and center.set == "Spectral"
            and center.hidden == true
            and key ~= "UNAVAILABLE"
            and not INLAND_RULES_CARD_EXCLUDED_SPECTRALS[key]
            and not seen[key]
        then
            available[#available + 1] = key
            seen[key] = true
        end
    end

    for _, center in ipairs((G.P_CENTER_POOLS and G.P_CENTER_POOLS.Spectral) or {}) do
        add_spectral(center)
    end

    if #available == 0 then
        for key, center in pairs(G.P_CENTERS or {}) do
            add_spectral(center, key)
        end
    end

    if #available == 0 then
        return nil
    end

    return pseudorandom_element(available, pseudoseed("canlaugh_inland_empire_rules_card_rare_key"))
end

SMODS.Joker({
    key = "inland_empire",
    name = "Inland Empire",
    atlas = "inland_empire",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    unlocked = false,
    config = {
        extra = {
            odds = 2,
        },
    },
    loc_txt = {
        name = "Inland Empire",
        text = {
            "If {C:attention}Small{} or {C:attention}Big Blind{} selected,",
            "{C:green}#1# in #2#{} chance to create a {C:tarot}Tarot{} card",
            "If {C:attention}Boss Blind{}, create a",
            "{C:spectral}Spectral{} card instead",
            "{C:inactive}(Must have room){}",
        },
        unlock = {
            "Banish {C:tarot}The Hanged Man{}",
            "with {C:attention}Resourceful Joker{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra

        return {
            vars = {
                G.GAME and G.GAME.probabilities.normal or 1,
                extra.odds,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_resourceful_hanged_man"
    end,
    locked_loc_vars = function(self, info_queue, card)
        if G and G.P_CENTERS then
            CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS.c_hanged_man, card)
            CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS.j_canlaugh_resourceful_joker, card)
        end

        return { vars = {} }
    end,
    calculate = function(self, card, context)
        if context.setting_blind
            and not context.blueprint
            and canlaugh_has_consumable_room()
            and SMODS.pseudorandom_probability(card, "canlaugh_inland_empire", 1, card.ability.extra.odds)
        then
            local blind_type = G.GAME.blind and G.GAME.blind:get_type()
            local card_type = blind_type == "Boss" and "Spectral" or "Tarot"
            local forced_key = canlaugh_inland_rules_card_rare_key(card)

            if forced_key then
                card_type = "Spectral"
            end

            local colour = blind_type == "Boss" and G.C.SECONDARY_SET.Spectral or G.C.PURPLE
            local message = blind_type == "Boss" and localize("k_plus_spectral") or localize("k_plus_tarot")

            if forced_key then
                colour = G.C.SECONDARY_SET.Spectral
                message = localize("k_plus_spectral")
            end

            canlaugh_create_consumable(
                card_type,
                "canlaugh_inland_empire",
                forced_key,
                forced_key and "canlaugh_motorway_south" or nil
            )

            return {
                message = message,
                colour = colour,
            }
        end
    end,
})
