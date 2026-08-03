local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_holy_saber_active()
    for _, joker in ipairs(SMODS.find_card("j_canlaugh_holy_saber", true) or {}) do
        if joker and not joker.debuff and not joker.removed and not joker.getting_sliced then
            return true
        end
    end

    return false
end

local function canlaugh_holy_saber_hand_key()
    local round = G and G.GAME and G.GAME.current_round
    return table.concat({
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(round and round.hands_played or ""),
    }, ":")
end

local function canlaugh_holy_saber_queue_slice_sound()
    if G and G.E_MANAGER and type(Event) == "function" then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.2,
            func = function()
                play_sound("slice1")
                return true
            end,
        }))
        return
    end

    play_sound("slice1")
end

if CL.register_suit_showdown_unlock then
    CL.register_suit_showdown_unlock(
        "j_canlaugh_holy_saber",
        "bl_canlaugh_tyrian_baton",
        "Spades",
        "canlaugh_holy_saber"
    )
end

if SMODS and type(SMODS.always_scores) == "function" and not CL.holy_saber_always_scores_hook_installed then
    CL.holy_saber_always_scores_hook_installed = true
    local always_scores_ref = SMODS.always_scores

    function SMODS.always_scores(playing_card)
        if canlaugh_holy_saber_active()
            and playing_card
            and playing_card:is_suit("Spades")
            and not playing_card:is_face()
        then
            return true
        end

        return always_scores_ref(playing_card)
    end
end

if CL.barter then
    CL.barter.register_rep_modifier("holy_saber", function(phase, context)
        if phase == "availability" and context.booster_kind == "Arcana" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_holy_saber") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Arcana" then
            local center = G.P_CENTERS and G.P_CENTERS.c_world
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_holy_saber") or {}) do
                local rep = center and CL.barter.collection_representative(center, "Arcana")
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end

SMODS.Atlas({
    key = "holy_saber",
    path = "holy_saber.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "holy_saber",
    name = "Holy Saber",
    atlas = "holy_saber",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    loc_txt = {
        name = "Holy Saber",
        text = {
            "{C:spades}Spade{} number cards always score",
            "Scored {C:spades}Spade{} face cards are either",
            "destroyed or give {X:mult,C:white}X#1#{} Mult",
        },
        unlock = {
            "Defeat the {C:attention}Tyrian Baton{}",
            "with only scored {C:spades}Spades{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { 5 } }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_holy_saber"
    end,
    calculate = function(self, card, context)
        local target = context.other_card
        local hand_key = canlaugh_holy_saber_hand_key()

        if context.individual
            and context.cardarea == G.play
            and target
            and target:is_suit("Spades")
            and target:is_face()
            and not context.blueprint
        then
            local fate = target.ability.canlaugh_holy_saber_fate
            if not fate or fate.hand_key ~= hand_key then
                fate = {
                    hand_key = hand_key,
                    destroy = SMODS.pseudorandom_probability(card, "canlaugh_holy_saber", 1, 2),
                }
                target.ability.canlaugh_holy_saber_fate = fate
            end

            if not fate.destroy then
                return {
                    x_mult = 5,
                    card = target,
                }
            end
        end

        if context.destroying_card
            and context.destroying_card:is_suit("Spades")
            and context.destroying_card:is_face()
            and not context.blueprint
        then
            local fate = context.destroying_card.ability.canlaugh_holy_saber_fate
            if fate and fate.hand_key == hand_key and fate.destroy then
                canlaugh_holy_saber_queue_slice_sound()
                return {
                    message = "Judged!",
                    colour = G.C.RED,
                    remove = true,
                }
            end
        end
    end,
})
