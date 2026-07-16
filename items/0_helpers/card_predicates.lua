local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

function CL.card_has_edition(card, edition_key)
    return card
        and card.edition
        and (card.edition.key == "e_" .. edition_key or card.edition[edition_key])
        or false
end

function CL.is_glitter(card)
    return CL.card_has_edition(card, "canlaugh_glitter")
end

function CL.is_negative(card)
    return CL.card_has_edition(card, "negative")
end

function CL.is_joker_card(card)
    return card
        and card.ability
        and card.ability.set == "Joker"
        or false
end
