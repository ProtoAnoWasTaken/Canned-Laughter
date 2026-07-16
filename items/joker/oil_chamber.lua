SMODS.Atlas({
    key = "oil_chamber",
    path = "oil_chamber.png",
    px = 69,
    py = 93,
})

if CannedLaughter.barter then
    CannedLaughter.barter.register_rep_modifier("oil_chamber", function(phase, context)
        if phase == "availability" and context.booster_kind == "Spectral" then context.extra_reps = context.extra_reps + 2 * #(SMODS.find_card("j_canlaugh_oil_chamber") or {}); return end
        if phase == "hand" and context.booster_kind == "Spectral" then
            local center = G.P_CENTERS and G.P_CENTERS.c_aura
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_oil_chamber") or {}) do
                for _ = 1, 2 do
                    local rep = center and CannedLaughter.barter.collection_representative(center, "Spectral")
                    if rep then rep.edition = "holo"; CannedLaughter.barter.add_rep(rep, joker) end
                end
            end
        end
    end)
end

local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_queue_oil_chamber_scratch(scored_card)
    if not scored_card then
        return
    end

    CL.oil_chamber_scratch_queue = CL.oil_chamber_scratch_queue or {}
    CL.oil_chamber_scratch_seen = CL.oil_chamber_scratch_seen or {}

    if CL.oil_chamber_scratch_seen[scored_card] then
        return
    end

    CL.oil_chamber_scratch_seen[scored_card] = true
    CL.oil_chamber_scratch_queue[#CL.oil_chamber_scratch_queue + 1] = scored_card
end

local function canlaugh_flush_oil_chamber_scratch_queue()
    if CL.oil_chamber_scratch_flushing then
        return
    end

    local queue = CL.oil_chamber_scratch_queue
    if not queue then
        return
    end

    CL.oil_chamber_scratch_flushing = true
    CL.oil_chamber_scratch_queue = nil
    CL.oil_chamber_scratch_seen = nil

    local PCJ = CannedLaughter.playing_card_jokers
    for _, scored_card in ipairs(queue) do
        if scored_card and PCJ.has_edition(scored_card, "holo") then
            card_eval_status_text(scored_card, "extra", nil, nil, nil, {
                message = "Scratched...",
                colour = G.C.RED,
            })
            scored_card:juice_up(0.8, 0.8)
            play_sound("slice1", 0.96 + math.random() * 0.08)
            scored_card:set_edition(nil, true)
        end
    end

    CL.oil_chamber_scratch_flushing = nil
end

if SMODS and type(SMODS.trigger_effects) == "function" and not CL.oil_chamber_trigger_effects_hook_installed then
    CL.oil_chamber_trigger_effects_hook_installed = true
    local canlaugh_oil_chamber_trigger_effects_ref = SMODS.trigger_effects

    function SMODS.trigger_effects(effects, card, ...)
        local results = { canlaugh_oil_chamber_trigger_effects_ref(effects, card, ...) }
        canlaugh_flush_oil_chamber_scratch_queue()
        return unpack(results)
    end
end

SMODS.Joker({
    key = "oil_chamber",
    name = "Oil Chamber",
    atlas = "oil_chamber",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    unlocked = false,
    config = { extra = { mult = 30, odds = 6 } },
    loc_txt = {
        name = "Oil Chamber",
        text = {
            "Scored {C:dark_edition}Holographic{} cards",
            "give {C:mult}+#1#{} Mult",
            "{C:green}#2# in #3#{} chance to remove",
            "{C:dark_edition}Holographic{} after scoring",
        },
        unlock = {
            "Play a {C:attention}5{} card hand",
            "with less than {C:attention}1{} or",
            "more than {C:attention}4{} suits",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                self.config.extra.mult,
                G.GAME and G.GAME.probabilities.normal or 1,
                self.config.extra.odds,
            },
        }
    end,
    check_for_unlock = function(self, args)
        local suits = CannedLaughter.playing_card_jokers.count_suits(args and args.full_hand)
        return args and args.type == "hand" and args.full_hand and #args.full_hand == 5 and (suits < 1 or suits > 4)
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local PCJ = CannedLaughter.playing_card_jokers

        if context.individual and context.cardarea == G.play and PCJ.is_playing_card(context.other_card) and PCJ.has_edition(context.other_card, "holo") then
            local scored_card = context.other_card
            if pseudorandom("canlaugh_oil_chamber_scratch") < (G.GAME.probabilities.normal / card.ability.extra.odds)
                and not context.blueprint
            then
                canlaugh_queue_oil_chamber_scratch(scored_card)
            end

            return { mult = card.ability.extra.mult }
        end
    end,
})
