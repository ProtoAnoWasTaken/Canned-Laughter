local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "plastic_tag",
    path = "plastic_tag.png",
    px = 34,
    py = 34,
})

local PLASTIC_TAG_SEALS = {
    "Red",
    "Gold",
    "Blue",
    "Purple",
}

local function canlaugh_rules_card_active()
    return CL.rules_card_active and CL.rules_card_active()
end

local function canlaugh_plastic_tag_waiting()
    if not (G and G.GAME and G.GAME.tags) then
        return false
    end

    for _, tag in ipairs(G.GAME.tags) do
        if tag
            and not tag.triggered
            and (tag.key == "tag_canlaugh_plastic" or tag.name == "Plastic Tag")
        then
            return true
        end
    end

    return false
end

local function canlaugh_center_can_receive_joker_seal(center)
    return center
        and center.set == "Joker"
        and center.rarity ~= 4
        and center.rarity ~= "Legendary"
        and center.rarity ~= "legendary"
        and center.blueprint_compat == true
end

local function canlaugh_center_can_appear_in_shop(center)
    if not canlaugh_center_can_receive_joker_seal(center) then
        return false
    end

    if G and G.GAME and G.GAME.used_jokers and G.GAME.used_jokers[center.key] then
        if not (SMODS and type(SMODS.showman) == "function" and SMODS.showman(center.key)) then
            return false
        end
    end

    if SMODS and type(SMODS.add_to_pool) == "function" and not SMODS.add_to_pool(center) then
        return false
    end

    return true
end

local function canlaugh_random_sealable_shop_joker()
    local candidates = {}
    local pool = G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Joker

    for _, center in ipairs(pool or {}) do
        if canlaugh_center_can_appear_in_shop(center) then
            candidates[#candidates + 1] = center.key
        end
    end

    if #candidates == 0 then
        return nil
    end

    return pseudorandom_element(candidates, pseudoseed("canlaugh_plastic_tag_shop_joker"))
end

if SMODS and type(SMODS.calculate_context) == "function" and not CL.plastic_tag_shop_joker_hook_installed then
    CL.plastic_tag_shop_joker_hook_installed = true
    local canlaugh_calculate_context_ref = SMODS.calculate_context

    function SMODS.calculate_context(context, return_table, no_resolve)
        local flags = canlaugh_calculate_context_ref(context, return_table, no_resolve) or return_table or {}

        if context
            and context.create_shop_card
            and context.cardarea == G.shop_jokers
            and canlaugh_plastic_tag_waiting()
        then
            local center = context.key and G.P_CENTERS and G.P_CENTERS[context.key]
            if not canlaugh_center_can_receive_joker_seal(center) then
                local key = canlaugh_random_sealable_shop_joker()
                if key then
                    flags.shop_create_flags = flags.shop_create_flags or {}
                    flags.shop_create_flags.type = "Joker"
                    flags.shop_create_flags.key = key
                end
            end
        end

        return flags
    end
end

local function canlaugh_plastic_tag_seal_pool()
    local pool = {}

    for _, seal_key in ipairs(PLASTIC_TAG_SEALS) do
        if G.P_SEALS and G.P_SEALS[seal_key] and CL.joker_seal_effects and CL.joker_seal_effects[seal_key] then
            pool[#pool + 1] = seal_key
        end
    end

    return pool
end

local function canlaugh_apply_plastic_tag(self, tag, context)
    local card = context and context.card

    if not (context and context.type == "store_joker_modify") or not card then
        return
    end

    if card.ability and card.ability.set == "Joker" then
        local center = card.config and card.config.center
        if not canlaugh_center_can_receive_joker_seal(center) or card.seal then
            return true
        end
    end

    if card.edition
        or card.temp_edition
        or not (card.ability and card.ability.set == "Joker")
    then
        return
    end

    local seals = canlaugh_plastic_tag_seal_pool()
    if #seals == 0 then
        return true
    end

    local seal_key = pseudorandom_element(seals, pseudoseed("canlaugh_plastic_tag_seal"))

    if not seal_key or not CL.can_joker_receive_seal(card, seal_key) then
        return
    end

    local lock = tag.ID
    G.CONTROLLER.locks[lock] = true
    card.temp_edition = true
    tag:yep("+", G.C.DARK_EDITION, function()
        card.temp_edition = nil
        card:set_edition("e_canlaugh_plastic", true)
        card:set_seal(seal_key, true, true)
        card.ability.couponed = true
        card:set_cost()
        G.CONTROLLER.locks[lock] = nil
        return true
    end)
    tag.triggered = true
    return true
end

local canlaugh_plastic_tag = SMODS.Tag({
    key = "plastic",
    atlas = "plastic_tag",
    order = 40,
    config = { type = "store_joker_modify", edition = "canlaugh_plastic", seal = "joker_compatible", odds = 3 },
    pos = { x = 0, y = 0 },
    requires = "e_canlaugh_plastic",
    loc_txt = {
        name = "Plastic Tag",
        text = {
            "Next base edition",
            "shop {C:attention}Joker{} is free",
            "and becomes {C:canlaugh_plastic,T:e_canlaugh_plastic}Plastic{}",
            "with a random {C:attention}Seal{}",
        },
    },
    apply = canlaugh_apply_plastic_tag,
})

if canlaugh_plastic_tag then
    canlaugh_plastic_tag.original_key = "plastic_tag"
    canlaugh_plastic_tag.canlaugh_tag_alias = "plastic_tag"
end
