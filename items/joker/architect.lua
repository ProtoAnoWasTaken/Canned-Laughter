local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_architect_deck_concrete()
    local count = 0

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if SMODS.has_enhancement(playing_card, "m_canlaugh_concrete") then
            count = count + 1
        end
    end

    return count
end

if CL.barter then
    CL.barter.register_rep_modifier("architect", function(phase, context)
        if phase == "availability" and context.booster_kind == "Arcana" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_architect") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Arcana" then
            local center = G.P_CENTERS and G.P_CENTERS.c_tower
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_architect") or {}) do
                local rep = center and CL.barter.collection_representative(center, "Arcana")
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end

SMODS.Atlas({
    key = "architect",
    path = "architect.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "architect",
    name = "Architect",
    atlas = "architect",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            chips_per_card = 35,
        },
    },
    loc_txt = {
        name = "Architect",
        text = {
            "Gives {C:chips}+#2#{} Chips for each",
            "{C:attention,T:m_canlaugh_concrete}Concrete Card{} in your full deck",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        CL.add_unique_tooltip(info_queue, G.P_CENTERS.m_canlaugh_concrete, card)
        return {
            vars = {
                canlaugh_architect_deck_concrete() * extra.chips_per_card,
                extra.chips_per_card,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        local chips = canlaugh_architect_deck_concrete() * extra.chips_per_card

        if context.joker_main and chips > 0 then
            return { chips = chips }
        end
    end,
})
