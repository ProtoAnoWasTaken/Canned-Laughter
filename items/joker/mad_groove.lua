SMODS.Atlas({
    key = "mad_groove",
    path = "mad_groove.png",
    px = 69,
    py = 93,
})

local function canlaugh_mad_groove_consumable(card)
    local center = card and card.config and card.config.center
    return card
        and card.ability
        and card.ability.consumeable
        or center
            and (
                center.consumeable
                or (SMODS and SMODS.ConsumableTypes and SMODS.ConsumableTypes[center.set])
            )
end

local function canlaugh_mad_groove_shop_count()
    local count = 0

    for _, card in ipairs((G and G.shop_jokers and G.shop_jokers.cards) or {}) do
        if canlaugh_mad_groove_consumable(card) then
            count = count + 1
        end
    end

    for _, card in ipairs((G and G.shop_booster and G.shop_booster.cards) or {}) do
        if card and not card.removed then
            local center = card.config and card.config.center
            local contained_cards = center and center.config and center.config.extra
            count = count + (type(contained_cards) == "number" and contained_cards or 1)
        end
    end

    return count
end

local function canlaugh_mad_groove_extra(card, fallback)
    local extra = card and card.ability and card.ability.extra or fallback
    if extra and not extra.scaling_initialized then
        extra.chips = 0
        extra.chips_gain = extra.chips_gain or 5
        extra.shop_count = nil
        extra.scaling_initialized = true
    end
    if extra and extra.chips == nil then
        extra.chips = extra.mult or 0
    end
    if extra and extra.chips_gain == nil then
        extra.chips_gain = extra.mult_gain or 5
    end
    if extra then
        extra.mult = nil
        extra.mult_gain = nil
    end
    return extra
end

SMODS.Joker({
    key = "mad_groove",
    name = "Mad Groove",
    atlas = "mad_groove",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = { extra = { chips = 0, chips_gain = 5, scaling_initialized = true } },
    loc_txt = {
        name = "Mad Groove",
        text = {
            "Unpurchased {C:attention}consumables{} and",
            "cards in unpurchased {C:attention}Booster Packs{}",
            "each add {C:chips}+#1#{} Chips after the Shop",
            "{C:inactive}(Currently {C:chips}+#2#{C:inactive} Chips){}",
        },
        unlock = {
            "Successfully barter with a",
            "{C:attention}Mega Arcana Pack{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = canlaugh_mad_groove_extra(card, self.config.extra)
        return {
            vars = {
                extra.chips_gain,
                extra.chips,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_mega_arcana_barter"
    end,
    calculate = function(self, card, context)
        if context.ending_shop and not context.blueprint then
            local extra = canlaugh_mad_groove_extra(card, self.config.extra)
            local gain = canlaugh_mad_groove_shop_count() * extra.chips_gain
            if gain > 0 then
                extra.chips = extra.chips + gain
                return {
                    message = "+" .. tostring(gain) .. " Chips",
                    colour = G.C.CHIPS,
                }
            end
        end

        if context.joker_main then
            local extra = canlaugh_mad_groove_extra(card, self.config.extra)
            if extra.chips > 0 then
                return { chips = extra.chips }
            end
        end
    end,
})

if CannedLaughter.unlocks and CannedLaughter.unlocks.register_mega_barter_joker then
    CannedLaughter.unlocks.register_mega_barter_joker(
        "Arcana",
        "canlaugh_mega_arcana_barter",
        "j_canlaugh_mad_groove"
    )
end
