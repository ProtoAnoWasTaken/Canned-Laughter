SMODS.Shader({
    key = "plastic",
    path = "plastic.fs",
})

local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function cl_is_plastic_edition(edition)
    if type(edition) == "string" then
        return edition == "e_canlaugh_plastic" or edition == "canlaugh_plastic"
    end
    return type(edition) == "table"
        and (edition.key == "e_canlaugh_plastic" or edition.canlaugh_plastic)
end

if Card and type(Card.set_edition) == "function" and not CL.plastic_blueprint_compat_hook_installed then
    CL.plastic_blueprint_compat_hook_installed = true
    local cl_plastic_set_edition_ref = Card.set_edition

    function Card:set_edition(edition, ...)
        local center = self and self.config and self.config.center
        if cl_is_plastic_edition(edition)
            and center
            and center.set == "Joker"
            and center.blueprint_compat ~= true
        then
            return
        end
        return cl_plastic_set_edition_ref(self, edition, ...)
    end
end

local function cl_is_plastic_sealed(card)
    return card
        and card.seal
        and card.edition
        and (card.edition.key == "e_canlaugh_plastic" or card.edition.canlaugh_plastic)
end

if type(create_card) == "function" and not CL.plastic_create_card_hook_installed then
    CL.plastic_create_card_hook_installed = true
    local cl_plastic_create_card_ref = create_card

    function create_card(card_type, ...)
        local previous_context = CL.plastic_natural_joker_poll
        CL.plastic_natural_joker_poll = card_type == "Joker"

        local results = { cl_plastic_create_card_ref(card_type, ...) }

        CL.plastic_natural_joker_poll = previous_context
        return unpack(results)
    end
end

if Card and type(Card.calculate_seal) == "function" and not CL.plastic_calculate_seal_hook_installed then
    CL.plastic_calculate_seal_hook_installed = true
    local cl_plastic_calculate_seal_ref = Card.calculate_seal

    function Card:calculate_seal(context, ...)
        local first_effect, first_post = cl_plastic_calculate_seal_ref(self, context, ...)
        if not cl_is_plastic_sealed(self) then
            return first_effect, first_post
        end

        local second_effect, second_post = cl_plastic_calculate_seal_ref(self, context, ...)
        local effects = {}

        if first_effect then
            effects[#effects + 1] = first_effect
        end
        if second_effect then
            effects[#effects + 1] = second_effect
        end

        local combined_effect = #effects > 0 and SMODS.merge_effects(effects) or nil
        return combined_effect, first_post or second_post
    end
end

if Card and type(Card.get_p_dollars) == "function" and not CL.plastic_p_dollars_hook_installed then
    CL.plastic_p_dollars_hook_installed = true
    local cl_plastic_get_p_dollars_ref = Card.get_p_dollars

    function Card:get_p_dollars(...)
        local dollars = cl_plastic_get_p_dollars_ref(self, ...)
        if not cl_is_plastic_sealed(self) then
            return dollars
        end

        local seal = G.P_SEALS[self.seal] or {}
        local extra_seal_dollars = 0

        if type(seal.get_p_dollars) == "function" then
            extra_seal_dollars = seal:get_p_dollars(self) or 0
        elseif self.seal == "Gold" and not self.ability.extra_enhancement then
            extra_seal_dollars = 3
        end

        return dollars + extra_seal_dollars
    end
end

local function cl_create_blue_seal_planet(card)
    if not (G.GAME.last_hand_played
        and #G.consumeables.cards + G.GAME.consumeable_buffer < G.consumeables.config.card_limit)
    then
        return
    end

    G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
    G.E_MANAGER:add_event(Event({
        trigger = "before",
        delay = 0,
        func = function()
            local planet_key = nil

            for _, planet in pairs(G.P_CENTER_POOLS.Planet) do
                if planet.config.hand_type == G.GAME.last_hand_played then
                    planet_key = planet.key
                    break
                end
            end

            local planet = create_card("Planet", G.consumeables, nil, nil, nil, nil, planet_key, "canlaugh_plastic_blue")
            planet:add_to_deck()
            G.consumeables:emplace(planet)
            G.GAME.consumeable_buffer = math.max(0, G.GAME.consumeable_buffer - 1)
            return true
        end,
    }))

    card_eval_status_text(card, "extra", nil, nil, nil, {
        message = localize("k_plus_planet"),
        colour = G.C.SECONDARY_SET.Planet,
    })
end

if Card and type(Card.get_end_of_round_effect) == "function" and not CL.plastic_blue_seal_hook_installed then
    CL.plastic_blue_seal_hook_installed = true
    local cl_plastic_get_end_of_round_effect_ref = Card.get_end_of_round_effect

    function Card:get_end_of_round_effect(context, ...)
        local effect = cl_plastic_get_end_of_round_effect_ref(self, context, ...)

        if cl_is_plastic_sealed(self)
            and self.seal == "Blue"
            and not self.extra_enhancement
            and not self.ability.extra_enhancement
            and effect
            and effect.effect
        then
            cl_create_blue_seal_planet(self)
        end

        return effect
    end
end

local PLASTIC_JOKER_LOC_KEY = "e_canlaugh_plastic_joker"
local PLASTIC_JOKER_LOC_TXT = {
    name = "Plastic",
    label = "Plastic",
    text = {
        "Can be {C:attention}sealed{}",
    },
}

local function cl_plastic_card_is_joker(card)
    local center = card and card.config and card.config.center
    return (card and card.ability and card.ability.set == "Joker")
        or (center and center.set == "Joker")
end

local function cl_ensure_plastic_joker_loc()
    if not (SMODS and type(SMODS.process_loc_text) == "function" and G and G.localization) then
        return
    end

    local edition_loc = G.localization.descriptions and G.localization.descriptions.Edition
    if edition_loc and not edition_loc[PLASTIC_JOKER_LOC_KEY] then
        SMODS.process_loc_text(edition_loc, PLASTIC_JOKER_LOC_KEY, PLASTIC_JOKER_LOC_TXT)
    end

    local loc = edition_loc and edition_loc[PLASTIC_JOKER_LOC_KEY]
    if loc and type(loc) == "table" then
        if not loc.name_parsed and type(loc.name) == "string" and type(loc_parse_string) == "function" then
            loc.name_parsed = { loc_parse_string(loc.name) }
        end

        if not loc.text_parsed and type(loc.text) == "table" and type(loc_parse_string) == "function" then
            loc.text_parsed = {}
            for _, line in ipairs(loc.text) do
                loc.text_parsed[#loc.text_parsed + 1] = loc_parse_string(line)
            end
        end
    end
end

SMODS.Edition({
    key = "plastic",
    order = 22,
    shader = "plastic",
    badge_colour = G.C.CANLAUGH_PLASTIC,
    in_shop = true,
    weight = 40 / 7,
    extra_cost = 2,
    canlaugh_native_sound = {
        path = "plastic.ogg",
        pitch = 1,
        volume = 0.25,
    },
    loc_txt = {
        name = "Plastic",
        label = "Plastic",
        text = {
            "Can be {C:attention}sealed{} for",
            "a {C:attention}doubled effect{}",
        },
    },
    get_weight = function(self)
        if CL.plastic_natural_joker_poll then
            return 0
        end

        return (G.GAME and G.GAME.edition_rate or 1) * self.weight
    end,
    loc_vars = function(self, info_queue, card)
        if cl_plastic_card_is_joker(card) then
            cl_ensure_plastic_joker_loc()
            return {
                key = PLASTIC_JOKER_LOC_KEY,
            }
        end
    end,
})
