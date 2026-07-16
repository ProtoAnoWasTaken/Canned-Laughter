local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_get_selected_hand_card()
    local highlighted = G and G.hand and G.hand.highlighted

    if highlighted and #highlighted == 1 then
        return highlighted[1]
    end
end

local function canlaugh_get_seal(key)
    return G and G.P_SEALS and G.P_SEALS[key]
end

local function canlaugh_can_graft_seal(card, seal_key)
    return card
        and not card.seal
        and canlaugh_get_seal(seal_key) ~= nil
end

local function canlaugh_graft_seal(card, used_card, seal)
    if not (card and seal) then
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.4,
        func = function()
            play_sound("tarot1")
            used_card:juice_up(0.3, 0.5)
            return true
        end,
    }))

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.2,
        func = function()
            if card and not card.removed then
                play_sound("tarot2", 1, 0.6)
                CL.paired_seal_grafting = true
                card:set_seal(seal.key, true)
                CL.paired_seal_grafting = nil

                if G and G.P_CENTERS and G.P_CENTERS.c_base and type(card.set_ability) == "function" then
                    CL.paired_seal_internal_change = true
                    card:set_ability(G.P_CENTERS.c_base, nil, true)
                    CL.paired_seal_internal_change = nil
                end

                card:juice_up(0.3, 0.3)
                discover_card(seal)
            end
            return true
        end,
    }))

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.25,
        func = function()
            if G and G.hand then
                G.hand:unhighlight_all()
            end
            return true
        end,
    }))

    delay(0.3)
end

local function canlaugh_register_graft_spectral(args)
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
        weight = args.weight,
        discovered = false,
        config = {
            max_highlighted = 1,
        },
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
            local seal = canlaugh_get_seal(args.seal_key)

            if seal then
                CannedLaughter.add_unique_tooltip(info_queue, seal, card)
            end
        end,
        can_use = function(self, card)
            return canlaugh_can_graft_seal(canlaugh_get_selected_hand_card(), args.seal_key)
        end,
        use = function(self, card, area, copier)
            local target = canlaugh_get_selected_hand_card()
            local seal = canlaugh_get_seal(args.seal_key)

            if not canlaugh_can_graft_seal(target, args.seal_key) or not seal then
                return
            end

            canlaugh_graft_seal(target, copier or card, seal)
        end,
    })
end

canlaugh_register_graft_spectral({
    key = "crimson_king",
    atlas = "crimson_king",
    path = "crimsonking.png",
    name = "The Crimson King",
    seal_key = "canlaugh_phosphate",
    seal_line = "{C:canlaugh_phosphate}Phosphate Seal{}",
    weight = 2.5,
})

canlaugh_register_graft_spectral({
    key = "city_keeper",
    atlas = "city_keeper",
    path = "citykeeper.png",
    name = "The City Keeper",
    seal_key = "canlaugh_calcite",
    seal_line = "{C:canlaugh_calcite}Calcite Seal{}",
    weight = 2.5,
})
