SMODS.Atlas({
    key = "frozen_tag",
    path = "frozen_tag.png",
    px = 34,
    py = 34,
})

local function canlaugh_apply_frozen_tag(self, tag, context)
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
        card:set_edition("e_canlaugh_frozen", true)
        card.ability.couponed = true
        card:set_cost()
        G.CONTROLLER.locks[lock] = nil
        return true
    end)
    tag.triggered = true
    return true
end

local canlaugh_frozen_tag = SMODS.Tag({
    key = "frozen",
    atlas = "frozen_tag",
    order = 46,
    config = { type = "store_joker_modify", edition = "canlaugh_frozen", odds = 4 },
    pos = { x = 0, y = 0 },
    requires = "e_canlaugh_frozen",
    loc_txt = {
        name = "Frozen Tag",
        text = {
            "Next base edition",
            "shop {C:attention}Joker{} is free",
            "and becomes {C:canlaugh_frozen,T:e_canlaugh_frozen}Frozen{}",
        },
    },
    apply = canlaugh_apply_frozen_tag,
})

if canlaugh_frozen_tag then
    canlaugh_frozen_tag.original_key = "frozen_tag"
    canlaugh_frozen_tag.canlaugh_tag_alias = "frozen_tag"
end
