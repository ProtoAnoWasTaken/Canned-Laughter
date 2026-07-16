SMODS.Atlas({
    key = "jesters_privilege",
    path = "jesters_privilege.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "jesters_privilege",
    name = "Jester's Privilege",
    atlas = "jesters_privilege",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    loc_txt = {
        name = "Jester's Privilege",
        text = {
            "Complete {C:attention}1 less Trial{} to pass",
            "Cashed-out consumables give",
            "{C:money}50%{} less money",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
})
