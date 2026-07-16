SMODS.Atlas({
    key = "sunshower",
    path = "dayshower.png",
    px = 69,
    py = 93,
})

if CannedLaughter.barter then
    CannedLaughter.barter.register_rep_modifier("sunshower", function(phase, context)
        if phase == "availability" and context.booster_kind == "Spectral" then context.extra_reps = context.extra_reps + 2 * #(SMODS.find_card("j_canlaugh_sunshower") or {}); return end
        if phase == "hand" and context.booster_kind == "Spectral" then
            local center = G.P_CENTERS and G.P_CENTERS.c_aura
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_sunshower") or {}) do
                for _ = 1, 2 do
                    local rep = center and CannedLaughter.barter.collection_representative(center, "Spectral")
                    if rep then rep.edition = "holo"; CannedLaughter.barter.add_rep(rep, joker) end
                end
            end
        end
    end)
end

SMODS.Joker({
    key = "sunshower",
    name = "Sunshower",
    atlas = "sunshower",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = { extra = { x_mult = 1.5 } },
    loc_txt = {
        name = "Sunshower",
        text = {
            "{C:dark_edition}Polychrome{} cards",
            "give {X:mult,C:white}X#1#{} Mult",
            "after {C:attention}Jokers{} score",
        },
        unlock = {
            "Beat a {C:attention}Showdown Blind{}",
            "in one hand",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { self.config.extra.x_mult } }
    end,
    check_for_unlock = function(self, args)
        return args and args.type == "round_win" and CannedLaughter.playing_card_jokers.blind_was_one_shot_showdown()
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
})
