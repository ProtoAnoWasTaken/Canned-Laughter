local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.colour_decks = CL.colour_decks or {}
local CD = CL.colour_decks

CD.planet_upgrade_state = CD.planet_upgrade_state or {}

function CD.has_deck_sticker(deck_key)
    local profile = G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    local usage = profile and profile.deck_usage and profile.deck_usage[deck_key]

    if not usage then
        return false
    end

    return next(usage.wins_by_key or {}) ~= nil
        or next(usage.wins or {}) ~= nil
end

function CD.won_with(deck_key, args)
    return CD.has_deck_sticker(deck_key)
        or (args and args.type == "win_deck" and args.deck == deck_key)
end

function CD.selected_back_key()
    local selected = G and G.GAME and G.GAME.selected_back

    return selected
        and selected.effect
        and selected.effect.center
        and selected.effect.center.key
end

function CD.refresh_planet_upgrade_stats()
    local hands = G and G.GAME and G.GAME.hands

    if not hands then
        return
    end

    local state = CD.planet_upgrade_state

    if state.hands ~= hands then
        state.hands = hands
        state.defaults = {}
    end

    local back_key = CD.selected_back_key()
    local cobalt_active = back_key == "b_canlaugh_cobalt_deck"
    local scarlet_active = back_key == "b_canlaugh_scarlet_deck"

    for hand_key, hand in pairs(hands) do
        local defaults = state.defaults[hand_key]

        if not defaults then
            defaults = {
                l_chips = hand.l_chips,
                l_mult = hand.l_mult,
            }
            state.defaults[hand_key] = defaults
        end

        hand.l_chips = cobalt_active and defaults.l_chips * 1.5 or defaults.l_chips
        hand.l_mult = scarlet_active and defaults.l_mult * 1.5 or defaults.l_mult
    end
end

if Back and type(Back.apply_to_run) == "function" and not CL.colour_deck_apply_hook then
    CL.colour_deck_apply_hook = true
    local apply_to_run_ref = Back.apply_to_run

    function Back:apply_to_run(...)
        local results = { apply_to_run_ref(self, ...) }
        CD.refresh_planet_upgrade_stats()
        return unpack(results)
    end
end

if Card and type(Card.use_consumeable) == "function" and not CL.colour_deck_planet_hook then
    CL.colour_deck_planet_hook = true
    local use_consumeable_ref = Card.use_consumeable

    function Card:use_consumeable(area, copier, ...)
        CD.refresh_planet_upgrade_stats()
        return use_consumeable_ref(self, area, copier, ...)
    end
end
