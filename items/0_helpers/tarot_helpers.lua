local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.tarot = CL.tarot or {}

function CL.tarot.pack_only_in_pool(self, args)
    local source = args and args.source

    return source ~= "sho"
        and source ~= "shop"
        and source ~= "Shop"
end

local function canlaugh_consumable_is_being_used(card)
    if not (card and G and G.consumeables) then
        return false
    end

    if card.area == G.consumeables then
        return true
    end

    for _, consumable in ipairs(G.consumeables.cards or {}) do
        if consumable == card then
            return true
        end
    end

    return false
end

function CL.tarot.has_consumable_room(create_count, used_card)
    create_count = create_count or 1

    if not G.consumeables then
        return false
    end

    local spent_slots = canlaugh_consumable_is_being_used(used_card) and 1 or 0

    if #G.consumeables.cards - spent_slots + (G.GAME.consumeable_buffer or 0) + create_count <= G.consumeables.config.card_limit then
        return true
    end

    return CannedLaughter.rules_card_active
        and CannedLaughter.rules_card_active()
end

function CL.tarot.with_consumable_room(create_count, callback)
    if CannedLaughter.rules_card_with_room then
        return CannedLaughter.rules_card_with_room({ consumeables = create_count or 1 }, callback)
    end

    return callback()
end

function CL.tarot.selected_hand_card()
    local highlighted = G and G.hand and G.hand.highlighted

    if highlighted and #highlighted == 1 then
        return highlighted[1]
    end
end

function CL.tarot.count_deck_suits(suit_lookup)
    local count = 0

    for _, playing_card in ipairs(G.playing_cards or {}) do
        local suit = playing_card and playing_card.base and playing_card.base.suit

        if suit_lookup[suit] then
            count = count + 1
        end
    end

    return count
end

function CL.tarot.count_irregular_suits()
    local count = 0

    for _, playing_card in ipairs(G.playing_cards or {}) do
        local irregular = playing_card
            and (SMODS.has_no_suit(playing_card) or SMODS.has_any_suit(playing_card))

        if not irregular
            and CannedLaughter
            and CannedLaughter.rules_card_active
            and CannedLaughter.rules_card_active()
            and playing_card
            and playing_card.base
            and type(SMODS.smeared_check) == "function"
        then
            local suit = playing_card.base.suit
            local paired_suit = ({
                Hearts = "Diamonds",
                Diamonds = "Hearts",
                Spades = "Clubs",
                Clubs = "Spades",
            })[suit]

            if paired_suit and SMODS.smeared_check(playing_card, paired_suit) then
                irregular = true
            end
        end

        if irregular then
            count = count + 1
        end
    end

    return count
end

function CL.tarot.most_played_hand()
    local best_hand = "High Card"
    local best_played = -1

    for _, hand_key in ipairs(G.handlist or {}) do
        local hand = G.GAME and G.GAME.hands and G.GAME.hands[hand_key]

        if hand
            and type(SMODS.is_poker_hand_visible) == "function"
            and SMODS.is_poker_hand_visible(hand_key)
            and (hand.played or 0) > best_played
        then
            best_hand = hand_key
            best_played = hand.played or 0
        end
    end

    return best_hand
end

function CL.tarot.planet_for_hand(hand_key)
    for _, planet in pairs(G.P_CENTER_POOLS.Planet or {}) do
        if planet.config and planet.config.hand_type == hand_key then
            return planet.key
        end
    end
end

function CL.tarot.juice_used_consumable(used_card)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.4,
        func = function()
            play_sound("tarot1")
            used_card:juice_up(0.3, 0.5)
            return true
        end,
    }))
end

function CL.tarot.unhighlight_hand(delay_time)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay_time or 0.25,
        func = function()
            if G and G.hand then
                G.hand:unhighlight_all()
            end
            return true
        end,
    }))
end
