SMODS.Atlas({ key = "goldbeard", path = "goldbeard.png", px = 69, py = 93 })

SMODS.Joker({
    key = "goldbeard",
    name = "Goldbeard",
    atlas = "goldbeard",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    loc_txt = { name = "Goldbeard", text = {
        "All {C:attention}Booster Packs{} contain",
        "{C:attention}1{} more card",
        "Cashing out after {C:attention}bartering{} gives",
        "{C:money}50%{} more money",
    } },
    add_to_deck = function(self, card, from_debuff)
        if not from_debuff and G and G.GAME and G.GAME.modifiers then
            G.GAME.modifiers.booster_size_mod = (G.GAME.modifiers.booster_size_mod or 0) + 1
        end
    end,
    remove_from_deck = function(self, card, from_debuff)
        if not from_debuff and G and G.GAME and G.GAME.modifiers then
            G.GAME.modifiers.booster_size_mod = (G.GAME.modifiers.booster_size_mod or 0) - 1
        end
    end,
})
