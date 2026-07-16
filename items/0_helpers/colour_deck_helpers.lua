local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.colour_decks = CL.colour_decks or {}
local CD = CL.colour_decks

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

if Card and type(Card.use_consumeable) == "function" and not CL.colour_deck_planet_hook then
    CL.colour_deck_planet_hook = true

    local use_consumeable_ref = Card.use_consumeable

    function Card:use_consumeable(area, copier, ...)
        local center = self.config and self.config.center
        local hand_key = center
            and center.set == "Planet"
            and center.config
            and center.config.hand_type
        local hand = hand_key
            and G.GAME
            and G.GAME.hands
            and G.GAME.hands[hand_key]
        local before_chips = hand and hand.chips
        local before_mult = hand and hand.mult
        local back_key = CD.selected_back_key()
        local results = { use_consumeable_ref(self, area, copier, ...) }

        if hand
            and before_chips
            and before_mult
            and (back_key == "b_canlaugh_scarlet_deck"
                or back_key == "b_canlaugh_cobalt_deck")
        then
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.01,
                func = function()
                    if back_key == "b_canlaugh_scarlet_deck" then
                        hand.mult = hand.mult + (hand.mult - before_mult) * 0.5
                    else
                        hand.chips = hand.chips + (hand.chips - before_chips) * 0.5
                    end

                    return true
                end,
            }))
        end

        return unpack(results)
    end
end
