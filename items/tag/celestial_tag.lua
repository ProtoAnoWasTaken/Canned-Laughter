SMODS.Atlas({
    key = "celestial_tag",
    path = "celestial_tag.png",
    px = 34,
    py = 34,
})

local function canlaugh_apply_celestial_tag(self, tag, context)
    local card = context and context.card

    if not (context and context.type == "store_joker_modify")
        or not card
        or card.edition
        or card.temp_edition
        or not (card.ability and card.ability.set == "Joker")
    then
        return
    end

    local lock = tag.ID
    G.CONTROLLER.locks[lock] = true
    card.temp_edition = true
    tag:yep("+", G.C.DARK_EDITION, function()
        card.temp_edition = nil
        card:set_edition("e_canlaugh_celestial", true)
        card.ability.couponed = true
        card:set_cost()
        G.CONTROLLER.locks[lock] = nil
        return true
    end)
    tag.triggered = true
    return true
end

local canlaugh_celestial_tag = SMODS.Tag({
    key = "celestial",
    atlas = "celestial_tag",
    order = 42,
    config = { type = "store_joker_modify", edition = "canlaugh_celestial", odds = 4 },
    pos = { x = 0, y = 0 },
    requires = "e_canlaugh_celestial",
    loc_txt = {
        name = "Celestial Tag",
        text = {
            "Next base edition",
            "shop {C:attention}Joker{} is free",
            "and becomes {C:dark_edition,T:e_canlaugh_celestial}Celestial{}",
        },
    },
    apply = canlaugh_apply_celestial_tag,
})

if canlaugh_celestial_tag then
    canlaugh_celestial_tag.original_key = "celestial_tag"
    canlaugh_celestial_tag.canlaugh_tag_alias = "celestial_tag"
end
