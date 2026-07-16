SMODS.Atlas({
    key = "mathematician",
    path = "mathematician.png",
    px = 69,
    py = 93,
})

local MATHEMATICIAN_CHIPS = {
    [11] = 11,
    [12] = 12,
    [13] = 13,
    [14] = 14,
}

local CL = rawget(_G, "CannedLaughter") or {}
_G.CannedLaughter = CL

local function canlaugh_has_mathematician()
    if not (G and G.jokers and G.jokers.cards) then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center
        if center
            and (center.key == "j_canlaugh_mathematician"
                or center.original_key == "mathematician")
        then
            return true
        end
    end

    return false
end

if not CL.mathematician_chip_hook_installed then
    CL.mathematician_chip_hook_installed = true
    local canlaugh_get_chip_bonus_ref = Card.get_chip_bonus

    function Card:get_chip_bonus()
        if canlaugh_has_mathematician() and not self.ability.extra_enhancement then
            local adjusted_chips = MATHEMATICIAN_CHIPS[self:get_id()]

            if adjusted_chips
                and self.ability.effect ~= "Stone Card"
                and not self.config.center.replace_base_card
            then
                return adjusted_chips + self.ability.bonus + (self.ability.perma_bonus or 0)
            end
        end

        return canlaugh_get_chip_bonus_ref(self)
    end
end

SMODS.Joker({
    key = "mathematician",
    name = "Mathematician",
    atlas = "mathematician",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    loc_txt = {
        name = "Mathematician",
        text = {
            "{C:attention}Face cards{} and {C:attention}Aces{}",
            "have been adjusted for linearity",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
})
