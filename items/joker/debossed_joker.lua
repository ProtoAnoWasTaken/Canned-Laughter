SMODS.Atlas({
    key = "debossed_joker",
    path = "debossed_joker.png",
    px = 69,
    py = 93,
})

if CannedLaughter.barter then
    CannedLaughter.barter.register_rep_modifier("debossed_joker", function(phase, context)
        if phase == "availability" and context.booster_kind == "Spectral" then context.extra_reps = context.extra_reps + 2 * #(SMODS.find_card("j_canlaugh_debossed_joker") or {}); return end
        if phase == "hand" and context.booster_kind == "Spectral" then
            local center = G.P_CENTERS and G.P_CENTERS.c_aura
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_debossed_joker") or {}) do
                for _ = 1, 2 do
                    local rep = center and CannedLaughter.barter.collection_representative(center, "Spectral")
                    if rep then rep.edition = "foil"; CannedLaughter.barter.add_rep(rep, joker) end
                end
            end
        end
    end)
end

SMODS.Joker({
    key = "debossed_joker",
    name = "Debossed Joker",
    atlas = "debossed_joker",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    unlocked = false,
    config = { extra = { odds = 10, unlock = 16 } },
    loc_txt = {
        name = "Debossed Joker",
        text = {
            "Scored {C:dark_edition}Foil{} cards",
            "have a {C:green}#1# in #2#{} chance",
            "to refund the hand",
        },
        unlock = {
            "Have at least {C:attention}#1#{} hand size",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                G.GAME and G.GAME.probabilities.normal or 1,
                self.config.extra.odds,
                self.config.extra.unlock,
            },
        }
    end,
    check_for_unlock = function(self, args)
        return args and args.type == "min_hand_size" and G.hand and G.hand.config.card_limit >= self.config.extra.unlock
    end,
    locked_loc_vars = function(self, info_queue, card)
        return { vars = { self.config.extra.unlock } }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local PCJ = CannedLaughter.playing_card_jokers
        if context.before and not context.blueprint and G.GAME and G.GAME.current_round then
            G.GAME.current_round.canlaugh_debossed_refunded_hand = nil
        end

        if context.individual
            and context.cardarea == G.play
            and PCJ.is_playing_card(context.other_card)
            and PCJ.has_edition(context.other_card, "foil")
            and pseudorandom("canlaugh_debossed_refund") < (G.GAME.probabilities.normal / card.ability.extra.odds)
            and not context.blueprint
            and not (G.GAME and G.GAME.current_round and G.GAME.current_round.canlaugh_debossed_refunded_hand)
        then
            if G.GAME and G.GAME.current_round then
                G.GAME.current_round.canlaugh_debossed_refunded_hand = true
            end
            PCJ.refund_hand(card)
        end
    end,
})
