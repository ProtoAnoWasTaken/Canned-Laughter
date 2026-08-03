local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

function CL.balefire_active()
    for _, joker in ipairs(SMODS.find_card("j_canlaugh_balefire", true) or {}) do
        if joker and not joker.debuff and not joker.getting_sliced then
            return true
        end
    end

    return false
end

SMODS.Atlas({
    key = "balefire",
    path = "balefire.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "balefire",
    name = "Balefire",
    atlas = "balefire",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    loc_txt = {
        name = "Balefire",
        text = {
            "{C:attention}Hot{} cards do not melt",
            "{C:canlaugh_frozen,T:e_canlaugh_frozen}Frozen{} cards",
        },
    },
    loc_vars = function(self, info_queue, card)
        CL.add_unique_tooltip(info_queue, G.P_CENTERS.e_canlaugh_frozen, card)
        return { vars = {} }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
})
