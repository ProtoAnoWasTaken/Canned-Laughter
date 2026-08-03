local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_rime_hand_key()
    local round = G and G.GAME and G.GAME.current_round
    return table.concat({
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(round and round.hands_played or ""),
    }, ":")
end

local function canlaugh_rime_destroy_frozen(card, scoring_hand)
    local frozen = {}

    for _, playing_card in ipairs(scoring_hand or {}) do
        if CL.is_frozen and CL.is_frozen(playing_card) then
            frozen[#frozen + 1] = playing_card
        end
    end

    if #frozen == 0 then
        return 0
    end

    if type(play_sound) == "function" then
        play_sound("glass1", 1, 0.5)
    end

    SMODS.destroy_cards(frozen, {
        immediate = true,
    })

    return #frozen
end

if CL.barter then
    CL.barter.register_rep_modifier("rime_joker", function(phase, context)
        if phase == "availability" and context.booster_kind == "Spectral" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_rime_joker") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Spectral" then
            local center = G.P_CENTERS and G.P_CENTERS.c_canlaugh_cryomancy
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_rime_joker") or {}) do
                local rep = center and CL.barter.collection_representative(center, "Spectral")
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end

SMODS.Atlas({
    key = "rime_joker",
    path = "rime_joker.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "rime_joker",
    name = "Rime Joker",
    atlas = "rime_joker",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            mult = 0,
            mult_gain = 4,
            last_hand = nil,
        },
    },
    loc_txt = {
        name = "Rime Joker",
        text = {
            "Scored {C:canlaugh_frozen,T:e_canlaugh_frozen}Frozen{} cards are destroyed",
            "Gains {C:mult}+#1#{} Mult for each",
            "card destroyed this way",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        CL.add_unique_tooltip(info_queue, G.P_CENTERS.e_canlaugh_frozen, card)
        return {
            vars = {
                extra.mult_gain,
                extra.mult,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.after and not context.blueprint then
            local hand_key = canlaugh_rime_hand_key()
            if extra.last_hand ~= hand_key then
                extra.last_hand = hand_key
                local destroyed = canlaugh_rime_destroy_frozen(card, context.scoring_hand)
                if destroyed > 0 then
                    local gain = destroyed * extra.mult_gain
                    extra.mult = extra.mult + gain
                    card:juice_up(0.3, 0.5)
                    return {
                        message = "+" .. tostring(gain) .. " Mult",
                        colour = G.C.MULT,
                    }
                end
            end
        end

        if context.joker_main and extra.mult > 0 then
            return {
                mult = extra.mult,
            }
        end
    end,
})
