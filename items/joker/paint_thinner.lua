local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "paint_thinner", path = "paint_thinner.png", px = 69, py = 93 })

local SUITS = { "Spades", "Hearts", "Clubs", "Diamonds" }

local function has_multiple_suits(card)
    local count = 0
    for _, suit in ipairs(SUITS) do
        if card:is_suit(suit, true) then
            count = count + 1
            if count > 1 then return true end
        end
    end
    return false
end

if Blind and type(Blind.debuff_card) == "function" and not CL.paint_thinner_blind_hook_installed then
    CL.paint_thinner_blind_hook_installed = true
    local debuff_card_ref = Blind.debuff_card
    function Blind:debuff_card(card, from_blind)
        local suit = self.debuff and self.debuff.suit
        local has_paint_thinner = next(SMODS.find_card("j_canlaugh_paint_thinner") or {})
        local is_acacia_aegis = self.config and self.config.blind and self.config.blind.key == "bl_canlaugh_acacia_aegis"
        if card and card.playing_card and has_paint_thinner and has_multiple_suits(card)
            and (is_acacia_aegis or (suit and card:is_suit(suit, true))) then
            card:set_debuff(false)
            return
        end
        return debuff_card_ref(self, card, from_blind)
    end
end

SMODS.Joker({
    key = "paint_thinner",
    name = "Paint Thinner",
    atlas = "paint_thinner",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    loc_txt = { name = "Paint Thinner", text = {
        "Cards with {C:attention}more than one suit{}",
        "cannot be debuffed by a {C:attention}suit{}",
    } },
})
