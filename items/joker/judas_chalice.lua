local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

if CL.register_suit_showdown_unlock then
    CL.register_suit_showdown_unlock(
        "j_canlaugh_judas_chalice",
        "bl_final_vessel",
        "Hearts",
        "canlaugh_judas_chalice"
    )
end

if CL.barter then
    CL.barter.register_rep_modifier("judas_chalice", function(phase, context)
        if phase == "availability" and context.booster_kind == "Arcana" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_judas_chalice") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Arcana" then
            local center = G.P_CENTERS and G.P_CENTERS.c_sun
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_judas_chalice") or {}) do
                local rep = center and CL.barter.collection_representative(center, "Arcana")
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end

SMODS.Atlas({
    key = "judas_chalice",
    path = "judas_chalice.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "judas_chalice",
    name = "Judas Chalice",
    atlas = "judas_chalice",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    loc_txt = {
        name = "Judas Chalice",
        text = {
            "Scored {C:hearts}Heart{} cards permanently",
            "gain {C:mult}+#1#{} Mult",
        },
        unlock = {
            "Defeat the {C:attention}Violet Vessel{}",
            "with only scored {C:hearts}Hearts{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { 1 } }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_judas_chalice"
    end,
    calculate = function(self, card, context)
        local target = context.other_card
        if context.individual
            and context.cardarea == G.play
            and target
            and target:is_suit("Hearts")
            and not context.blueprint
        then
            target.ability.perma_mult = (target.ability.perma_mult or 0) + 1
            return {
                mult = 1,
                card = target,
            }
        end
    end,
})
