local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_bluecollar_queue_cement(target)
    target.canlaugh_bluecollar_pending = true

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.4,
        func = function()
            target.canlaugh_bluecollar_pending = nil

            if target.removed or target.REMOVED or target.destroyed then
                return true
            end

            if not SMODS.has_enhancement(target, "m_stone") then
                return true
            end

            local cement = G.P_CENTERS and G.P_CENTERS.m_canlaugh_concrete
            if not cement then
                return true
            end

            target:set_ability(cement, nil, true)
            discover_card(cement)
            target:juice_up(0.3, 0.5)
            card_eval_status_text(target, "extra", nil, nil, nil, {
                message = "Cemented!",
                colour = G.C.GREY,
            })
            return true
        end,
    }))
end

if CL.barter then
    CL.barter.register_rep_modifier("bluecollar", function(phase, context)
        if phase == "availability" and context.booster_kind == "Arcana" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_bluecollar") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Arcana" then
            local center = G.P_CENTERS and G.P_CENTERS.c_tower
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_bluecollar") or {}) do
                local rep = center and CL.barter.collection_representative(center, "Arcana")
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end

SMODS.Atlas({
    key = "bluecollar",
    path = "bluecollar.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "bluecollar",
    name = "Bluecollar",
    atlas = "bluecollar",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    loc_txt = {
        name = "Bluecollar",
        text = {
            "{C:attention,T:m_stone}Stone Cards{} become",
            "{C:attention,T:m_canlaugh_concrete}Cement Cards{} after scoring",
        },
    },
    loc_vars = function(self, info_queue, card)
        CL.add_unique_tooltip(info_queue, G.P_CENTERS.m_stone, card)
        CL.add_unique_tooltip(info_queue, G.P_CENTERS.m_canlaugh_concrete, card)
        CL.add_unique_tooltip(info_queue, {
            key = "canlaugh_card_designer",
            set = "Other",
            vars = { "vordhosbn" },
        }, card)
        return { vars = {} }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual
            and context.cardarea == G.play
            and context.other_card
            and not context.other_card.canlaugh_bluecollar_pending
            and SMODS.has_enhancement(context.other_card, "m_stone")
            and not context.blueprint
        then
            canlaugh_bluecollar_queue_cement(context.other_card)
        end
    end,
})
