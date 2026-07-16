SMODS.Atlas({
    key = "glitter_tag",
    path = "glitter_tag.png",
    px = 34,
    py = 34,
})

local function canlaugh_apply_glitter_tag(self, tag, context)
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
        card:set_edition("e_canlaugh_glitter", true)
        card.ability.couponed = true
        card:set_cost()
        G.CONTROLLER.locks[lock] = nil
        return true
    end)
    tag.triggered = true
    return true
end

local canlaugh_glitter_tag = SMODS.Tag({
    key = "glitter",
    atlas = "glitter_tag",
    order = 41,
    config = { type = "store_joker_modify", edition = "canlaugh_glitter", odds = 4 },
    pos = { x = 0, y = 0 },
    requires = "e_canlaugh_glitter",
    loc_txt = {
        name = "Glitter Tag",
        text = {
            "Next base edition",
            "shop {C:attention}Joker{} is free",
            "and becomes {C:canlaugh_glitter,T:e_canlaugh_glitter}Glitter{}",
        },
    },
    apply = canlaugh_apply_glitter_tag,
})

if canlaugh_glitter_tag then
    canlaugh_glitter_tag.original_key = "glitter_tag"
    canlaugh_glitter_tag.canlaugh_tag_alias = "glitter_tag"
end
