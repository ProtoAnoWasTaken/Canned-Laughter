local function canlaugh_deviant_mult_cards()
    local count = 0

    for _, playing_card in ipairs((G and G.playing_cards) or {}) do
        if SMODS.has_enhancement(playing_card, "m_mult") then
            count = count + 1
        end
    end

    return count
end

SMODS.Atlas({
    key = "deviant",
    path = "deviant.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "deviant",
    name = "Deviant",
    atlas = "deviant",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 4,
    config = {
        extra = {
            mult_per_card = 4,
        },
    },
    loc_txt = {
        name = "Deviant",
        text = {
            "{C:mult}+#1#{} Mult for each {C:mult}Mult Card{}",
            "in your full deck",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.mult_per_card,
                canlaugh_deviant_mult_cards() * extra.mult_per_card,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local mult = canlaugh_deviant_mult_cards() * card.ability.extra.mult_per_card
            if mult > 0 then
                return {
                    mult = mult,
                }
            end
        end
    end,
})
