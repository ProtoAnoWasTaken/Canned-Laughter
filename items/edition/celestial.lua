local function get_celestial_hand()
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

    return best_hand, G.GAME and G.GAME.hands and G.GAME.hands[best_hand]
end

SMODS.Shader({
    key = "celestial",
    path = "celestial.fs",
})

SMODS.Edition({
    key = "celestial",
    order = 20,
    shader = "celestial",
    in_shop = true,
    weight = 40 / 7,
    extra_cost = 4,
    badge_colour = HEX("79A9B8"),
    canlaugh_native_sound = {
        path = "celestial.ogg",
        pitch = 1.1,
        volume = 0.25,
    },
    loc_txt = {
        name = "Celestial",
        label = "Celestial",
        text = {
            "{C:chips}+#1#{} Chips and {C:mult}+#2#{} Mult",
            "from your most-played poker hand",
            "{C:attention}#3#{} {C:inactive}(lvl. #4#){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local hand_key, hand = get_celestial_hand()
        local harlequin_adjusted = CannedLaughter.harlequin_affects_card
            and CannedLaughter.harlequin_affects_card(card)
        local chips = hand and hand.chips or 5
        local mult = hand and hand.mult or 1

        if harlequin_adjusted then
            chips = chips * 0.5
            mult = 1 + (mult - 1) * 0.5
        end

        return {
            vars = {
                chips,
                mult,
                localize(hand_key, "poker_hands"),
                hand and hand.level or 1,
            },
        }
    end,
    get_weight = function(self)
        return (G.GAME and G.GAME.edition_rate or 1) * self.weight
    end,
    calculate = function(self, card, context)
        if context.pre_joker or (context.main_scoring and context.cardarea == G.play) then
            local _, hand = get_celestial_hand()

            if hand then
                local chips = hand.chips
                local mult = hand.mult
                local harlequin_adjusted = CannedLaughter.harlequin_affects_card
                    and CannedLaughter.harlequin_affects_card(card)

                if harlequin_adjusted then
                    chips = chips * 0.5
                    mult = 1 + (mult - 1) * 0.5
                end

                return {
                    chips = chips,
                    mult = mult,
                }
            end
        end
    end,
})
