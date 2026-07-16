local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "summon",
    path = "summon.png",
    px = 71,
    py = 95,
})

local function canlaugh_rules_card_active()
    return CL.rules_card_active and CL.rules_card_active()
end

local function canlaugh_is_joker(card)
    local center = card and card.config and card.config.center
    return (card and card.ability and card.ability.set == "Joker")
        or (center and center.set == "Joker")
end

local function canlaugh_is_plastic(card)
    return card
        and card.edition
        and (card.edition.key == "e_canlaugh_plastic" or card.edition.canlaugh_plastic)
end

local function canlaugh_joker_is_owned(card)
    if not (card and G and G.jokers) then
        return false
    end

    if card.area == G.jokers then
        return true
    end

    for _, joker in ipairs(G.jokers.cards or {}) do
        if joker == card then
            return true
        end
    end

    return false
end

local function canlaugh_mark_plastic_joker_seen(card, allow_pre_emplace)
    if G
        and G.GAME
        and canlaugh_is_joker(card)
        and canlaugh_is_plastic(card)
        and (allow_pre_emplace or canlaugh_joker_is_owned(card))
    then
        G.GAME.canlaugh_plastic_joker_seen = true
    end
end

if Card and type(Card.add_to_deck) == "function" and not CL.summon_plastic_joker_add_hook_installed then
    CL.summon_plastic_joker_add_hook_installed = true
    local canlaugh_add_to_deck_ref = Card.add_to_deck

    function Card:add_to_deck(...)
        local results = { canlaugh_add_to_deck_ref(self, ...) }
        canlaugh_mark_plastic_joker_seen(self, true)
        return unpack(results)
    end
end

if Card and type(Card.set_edition) == "function" and not CL.summon_plastic_joker_edition_hook_installed then
    CL.summon_plastic_joker_edition_hook_installed = true
    local canlaugh_set_edition_ref = Card.set_edition

    function Card:set_edition(...)
        local results = { canlaugh_set_edition_ref(self, ...) }
        canlaugh_mark_plastic_joker_seen(self)
        return unpack(results)
    end
end

local function canlaugh_get_selected_joker()
    local highlighted = G and G.jokers and G.jokers.highlighted

    if highlighted and #highlighted == 1 then
        return highlighted[1]
    end
end

local function canlaugh_get_joker_seal_pool(card)
    local pool = {}

    if not (card and not card.seal and G and G.P_SEALS and CL.can_joker_receive_seal) then
        return pool
    end

    for seal_key in pairs(CL.joker_seal_effects or {}) do
        if G.P_SEALS[seal_key] and CL.can_joker_receive_seal(card, seal_key) then
            pool[#pool + 1] = seal_key
        end
    end

    table.sort(pool)
    return pool
end

local function canlaugh_can_summon_to_joker(card)
    return canlaugh_is_joker(card)
        and (canlaugh_is_plastic(card) or canlaugh_rules_card_active())
        and #canlaugh_get_joker_seal_pool(card) > 0
end

SMODS.Spectral({
    key = "summon",
    atlas = "summon",
    pos = { x = 0, y = 0 },
    cost = 4,
    weight = 0.5,
    config = {
        max_highlighted = 1,
    },
    loc_txt = {
        name = "Summon",
        text = {
            "Apply a {C:attention}random Seal{}",
            "to {C:attention}1{} selected Joker",
            "{C:inactive}(Has to be {C:canlaugh_plastic}Plastic{C:inactive}){}",
        },
    },
    in_pool = function(self, args)
        return canlaugh_rules_card_active()
            or (G and G.GAME and G.GAME.canlaugh_plastic_joker_seen)
    end,
    can_use = function(self, card)
        return canlaugh_can_summon_to_joker(canlaugh_get_selected_joker())
    end,
    use = function(self, card, area, copier)
        local used_spectral = copier or card
        local target = canlaugh_get_selected_joker()
        local pool = canlaugh_get_joker_seal_pool(target)
        local seal_key = #pool > 0 and pseudorandom_element(pool, pseudoseed("canlaugh_summon_seal"))

        if not (target and seal_key) then
            return
        end

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.4,
            func = function()
                play_sound("tarot1")
                used_spectral:juice_up(0.3, 0.5)
                return true
            end,
        }))

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.2,
            func = function()
                if target and not target.removed then
                    play_sound("tarot2", 1, 0.6)
                    target:set_seal(seal_key, true)
                    target:juice_up(0.3, 0.3)
                    discover_card(G.P_SEALS[seal_key])
                end
                return true
            end,
        }))

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.25,
            func = function()
                if G and G.jokers and type(G.jokers.unhighlight_all) == "function" then
                    G.jokers:unhighlight_all()
                end
                return true
            end,
        }))

        delay(0.3)
    end,
})
