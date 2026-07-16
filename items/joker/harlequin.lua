local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "harlequin",
    path = "harlequin.png",
    px = 69,
    py = 93,
})

if Card and type(Card.is_suit) == "function" and not CL.harlequin_suit_hook_installed then
    CL.harlequin_suit_hook_installed = true
    local canlaugh_harlequin_is_suit_ref = Card.is_suit

    function Card:is_suit(suit, bypass_debuff, flush_calc)
        local harlequin_active = next(SMODS.find_card("j_canlaugh_harlequin") or {}) ~= nil

        if harlequin_active and self:is_face(true) then
            return true
        end

        return canlaugh_harlequin_is_suit_ref(self, suit, bypass_debuff, flush_calc)
    end
end

SMODS.Joker({
    key = "harlequin",
    name = "Harlequin",
    atlas = "harlequin",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    loc_txt = {
        name = "Harlequin",
        text = {
            "All face cards are considered",
            "{C:attention}Wild{} but are {C:attention}half as effective{}",
            "{C:attention}+1{} Trial option",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual
            and context.cardarea == G.play
            and context.other_card:is_face()
        then
            local playing_card = context.other_card
            local base_chips = playing_card.base and playing_card.base.nominal or 0
            local edition = playing_card.edition or {}
            local effect = {
                chips = -base_chips * 0.5,
            }

            if edition.chips then
                effect.chips = effect.chips - edition.chips * 0.5
            end

            if edition.mult then
                effect.mult = -edition.mult * 0.5
            end

            if edition.x_mult and edition.x_mult ~= 0 then
                local halved_x_mult = 1 + (edition.x_mult - 1) * 0.5
                effect.x_mult = halved_x_mult / edition.x_mult
            end

            return effect
        end
    end,
})
