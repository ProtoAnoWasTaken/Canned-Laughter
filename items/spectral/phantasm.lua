local function canlaugh_get_selected_hand_card()
    local highlighted = G and G.hand and G.hand.highlighted

    if highlighted and #highlighted == 1 then
        return highlighted[1]
    end
end

local function canlaugh_get_shadow_seal()
    return G
        and G.P_SEALS
        and (G.P_SEALS.canlaugh_shadow or G.P_SEALS.shadow)
end

SMODS.Atlas({
    key = "phantasm",
    path = "phantasm.png",
    px = 71,
    py = 95,
})

SMODS.Spectral({
    key = "phantasm",
    atlas = "phantasm",
    pos = { x = 0, y = 0 },
    cost = 4,
    config = {
        max_highlighted = 1,
    },
    loc_txt = {
        name = "Phantasm",
        text = {
            "Add a {C:canlaugh_shadow}Shadow Seal{}",
            "to {C:attention}1{} selected card",
            "in your hand",
        },
    },
    loc_vars = function(self, info_queue, card)
        local shadow_seal = canlaugh_get_shadow_seal()

        if shadow_seal then
            CannedLaughter.add_unique_tooltip(info_queue, shadow_seal, card)
        end
    end,
    can_use = function(self, card)
        return canlaugh_get_selected_hand_card() ~= nil
            and canlaugh_get_shadow_seal() ~= nil
    end,
    use = function(self, card, area, copier)
        local used_spectral = copier or card
        local target = canlaugh_get_selected_hand_card()
        local shadow_seal = canlaugh_get_shadow_seal()

        if not target or not shadow_seal then
            return
        end

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.4,
            func = function()
                play_sound("tarot1")
                used_spectral:juice_up(0.3, 0.5)
                return true
            end,
        }))

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.2,
            func = function()
                if target and not target.removed then
                    play_sound("tarot2", 1, 0.6)
                    target:set_seal(shadow_seal.key, true)
                    target:juice_up(0.3, 0.3)
                    discover_card(shadow_seal)
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
    end,
})
