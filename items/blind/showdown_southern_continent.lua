local CL = CannedLaughter

SMODS.Atlas({
    key = "showdown_southern_continent",
    path = "showdown_southern_continent.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

local function card_has_unnatural_suit(card)
    if not card or not card.playing_card then
        return false
    end

    if SMODS.has_no_suit(card) or SMODS.has_any_suit(card) then
        return true
    end

    return card.canlaugh_suit_changed
        or card.base and card.canlaugh_original_suit and card.base.suit ~= card.canlaugh_original_suit
end

if Card and type(Card.set_base) == "function" and not CL.southern_continent_base_hook_installed then
    CL.southern_continent_base_hook_installed = true
    local set_base_ref = Card.set_base

    function Card:set_base(base, initial, manual_sprites, ...)
        local previous_suit = self.base and self.base.suit
        local previous_rank = self.base and self.base.value
        local result = { set_base_ref(self, base, initial, manual_sprites, ...) }

        if self.playing_card and self.base and self.base.suit then
            if not self.canlaugh_original_suit then
                self.canlaugh_original_suit = previous_suit or self.base.suit
            end

            if not self.canlaugh_original_rank then
                self.canlaugh_original_rank = previous_rank or self.base.value
            end

            if self.base.suit ~= self.canlaugh_original_suit then
                self.canlaugh_suit_changed = true
            end
        end

        return unpack(result)
    end
end

CL.register_showdown_boss({
    key = "southern_continent",
    atlas = "showdown_southern_continent",
    boss_colour = HEX("4BC292"),
    mult = 2,
    loc_txt = {
        name = "Southern Continent",
        text = {
            "Unnatural suits,",
            "are debuffed",
        },
    },
    recalc_debuff = function(self, card)
        return card_has_unnatural_suit(card)
    end,
})
