SMODS.Atlas({
    key = "whitecollar",
    path = "whitecollar.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "whitecollar",
    name = "Whitecollar",
    atlas = "whitecollar",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 5,
    loc_txt = {
        name = "Whitecollar",
        text = {
            "When {C:attention}Blind{} is selected,",
            "a random {C:attention}Lucky Card{}",
            "gains {C:canlaugh_plastic,T:e_canlaugh_plastic}Plastic{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local CL = CannedLaughter
        if G and G.P_CENTERS and G.P_CENTERS.m_lucky then
            CL.add_unique_tooltip(info_queue, G.P_CENTERS.m_lucky, card)
        end
        if G and G.P_CENTERS and G.P_CENTERS.e_canlaugh_plastic then
            CL.add_unique_tooltip(info_queue, G.P_CENTERS.e_canlaugh_plastic, card)
        end
        return { vars = {} }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            local PCJ = CannedLaughter.playing_card_jokers
            local JPE = CannedLaughter.joker_plastic_edition
            local target = PCJ.random_lucky_card()
            if target and JPE and JPE.apply_after(target) then
                return { message = "Laminated!", colour = G.C.CANLAUGH_PLASTIC }
            end
        end
    end,
})
