local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

function CL.register_graft_spectral(args)
    SMODS.Atlas({
        key = args.atlas,
        path = args.path,
        px = 71,
        py = 95,
    })

    SMODS.Spectral({
        key = args.key,
        atlas = args.atlas,
        pos = { x = 0, y = 0 },
        cost = 4,
        hidden = true,
        soul_set = "Spectral",
        weight = 2.5,
        discovered = false,
        config = { max_highlighted = 1 },
        loc_txt = {
            name = args.name,
            text = {
                "{C:mult}Graft{} a",
                args.seal_line,
                "to {C:attention}1{} selected card",
                "in your hand",
            },
        },
        loc_vars = function(self, info_queue, card)
            local seal = G.P_SEALS[args.seal_key]
            if seal then CannedLaughter.add_unique_tooltip(info_queue, seal, card) end
        end,
        can_use = function()
            local target = CL.tarot.selected_hand_card()
            return target and not target.seal and G.P_SEALS[args.seal_key]
        end,
        use = function(self, card, area, copier)
            local target = CL.tarot.selected_hand_card()
            local seal = G.P_SEALS[args.seal_key]
            if not target or target.seal or not seal then return end
            CL.tarot.juice_used_consumable(copier or card)
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.2,
                func = function()
                    CL.paired_seal_grafting = true
                    target:set_seal(seal.key, true)
                    CL.paired_seal_grafting = nil
                    CL.paired_seal_internal_change = true
                    target:set_ability(G.P_CENTERS.c_base, nil, true)
                    CL.paired_seal_internal_change = nil
                    target:juice_up(0.3, 0.3)
                    discover_card(seal)
                    return true
                end,
            }))
            CL.tarot.unhighlight_hand(0.25)
            delay(0.3)
        end,
    })
end
