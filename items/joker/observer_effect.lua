SMODS.Atlas({
    key = "observer_effect",
    path = "observer_effect.png",
    px = 69,
    py = 93,
})

if CannedLaughter.barter then
    CannedLaughter.barter.register_rep_modifier("observer_effect", function(phase, context)
        if phase == "availability" and context.booster_kind == "Spectral" then context.extra_reps = context.extra_reps + 2 * #(SMODS.find_card("j_canlaugh_observer_effect") or {}); return end
        if phase == "hand" and context.booster_kind == "Spectral" then
            local center = G.P_CENTERS and G.P_CENTERS.c_ectoplasm
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_observer_effect") or {}) do
                for _ = 1, 2 do
                    local rep = center and CannedLaughter.barter.collection_representative(center, "Spectral")
                    if rep then rep.edition = "negative"; CannedLaughter.barter.add_rep(rep, joker) end
                end
            end
        end
    end)
end

SMODS.Atlas({
    key = "observed",
    path = "observed.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "observer_effect",
    name = "Observer Effect",
    atlas = "observer_effect",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = { extra = { odds = 5, unlock = 10 } },
    loc_txt = {
        name = "Observer Effect",
        text = {
            "When {C:attention}Blind{} is selected,",
            "{C:green}#1# in #2#{} chance to create",
            "a {C:attention}Negative Tag{}",
        },
        unlock = {
            "Have at least {C:attention}#1#{}",
            "{C:attention}Joker{} slots at once",
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
        return args and args.type == "modify_jokers" and CannedLaughter.playing_card_jokers.current_joker_slots() >= self.config.extra.unlock
    end,
    locked_loc_vars = function(self, info_queue, card)
        return { vars = { self.config.extra.unlock } }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind
            and not context.blueprint
            and pseudorandom("canlaugh_observer_effect") < (G.GAME.probabilities.normal / card.ability.extra.odds)
            and CannedLaughter.playing_card_jokers.queue_negative_tag()
        then
            return { message = "+Tag", colour = G.C.DARK_EDITION }
        end
    end,
})
