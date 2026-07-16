local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "import_tag",
    path = "import_tag.png",
    px = 34,
    py = 34,
})

local KNOWN_BANANA_LEVELS = {
    j_gros_michel = 1,
    j_canlaugh_plantain = 1,
    j_cavendish = 2,
    j_canlaugh_maurelii = 2,
    j_canlaugh_ingens = 3,
}

local function canlaugh_import_nope(tag)
    tag:nope()
    tag.triggered = true
    return true
end

local function canlaugh_import_has_room()
    if not (G and G.jokers and G.jokers.cards and G.jokers.config) then
        return false
    end

    return #G.jokers.cards + (G.GAME.joker_buffer or 0) < G.jokers.config.card_limit
end

local function canlaugh_center_is_banana_like(center)
    if not center then
        return false
    end

    if KNOWN_BANANA_LEVELS[center.key] then
        return true
    end

    if center.banana
        or center.is_banana
        or center.pools and center.pools.Banana
        or center.config and center.config.banana
    then
        return true
    end

    local text = string.lower(tostring(center.key or "") .. " " .. tostring(center.name or ""))
    if not (
        string.find(text, "banana", 1, true)
        or string.find(text, "gros", 1, true)
        or string.find(text, "cavendish", 1, true)
        or string.find(text, "ingens", 1, true)
    ) then
        return false
    end

    return not CL.center_is_food or CL.center_is_food(center)
end

CL.is_banana_center = canlaugh_center_is_banana_like

local function canlaugh_banana_level(center)
    if not center then
        return nil
    end

    if KNOWN_BANANA_LEVELS[center.key] then
        return KNOWN_BANANA_LEVELS[center.key]
    end

    if center.yes_pool_flag == "canlaugh_cavendish_extinct" or center.yes_pool_flag == "cavendish_extinct" then
        return 3
    end

    if center.yes_pool_flag == "gros_michel_extinct" then
        return 2
    end

    if center.no_pool_flag == "gros_michel_extinct" or not center.yes_pool_flag then
        return 1
    end

    return nil
end

local function canlaugh_collect_banana_candidates()
    local levels = {
        {},
        {},
        {},
    }

    if not (G and G.P_CENTERS) then
        return levels
    end

    for key, center in pairs(G.P_CENTERS) do
        if center and center.set == "Joker" and canlaugh_center_is_banana_like(center) then
            local level = canlaugh_banana_level(center)
            if level and levels[level] then
                levels[level][#levels[level] + 1] = key
            end
        end
    end

    return levels
end

local function canlaugh_owned_bananas()
    local owned = {}

    if not (G and G.jokers and G.jokers.cards) then
        return owned
    end

    for _, card in ipairs(G.jokers.cards) do
        local center = card and card.config and card.config.center
        if canlaugh_center_is_banana_like(center) and center.key ~= "j_canlaugh_maurelii" then
            owned[#owned + 1] = card
        end
    end

    return owned
end

local function canlaugh_next_banana_level()
    local flags = G and G.GAME and G.GAME.pool_flags or {}

    if not flags.gros_michel_extinct then
        return 1
    end

    if not flags.canlaugh_cavendish_extinct then
        return 2
    end

    if not flags.canlaugh_ingens_extinct then
        return 3
    end

    return nil
end

local function canlaugh_choose_random(list, seed)
    if not list or #list == 0 then
        return nil
    end

    if pseudorandom_element then
        return pseudorandom_element(list, pseudoseed(seed))
    end

    return list[math.random(#list)]
end

local function canlaugh_catalyze_banana(card)
    local extra = card and card.ability and card.ability.extra

    if type(extra) ~= "table" or type(extra.odds) ~= "number" then
        return false
    end

    extra.odds = math.max(1, math.floor(extra.odds * 0.75 + 0.5))
    card:juice_up(0.3, 0.4)
    card_eval_status_text(card, "extra", nil, nil, nil, {
        message = "Catalyzed!",
        colour = G.C.GREEN,
    })
    return true
end

local function canlaugh_import_pending_banana()
    local pending = CL.import_pending_banana

    if not (pending and pending.key) then
        return nil
    end

    return pending
end

local function canlaugh_reserve_import_banana(key)
    G.GAME.joker_buffer = (G.GAME.joker_buffer or 0) + 1
    CL.import_pending_banana = {
        key = key,
        catalysts = 0,
    }
    return CL.import_pending_banana
end

local function canlaugh_catalyze_pending_import_banana()
    local pending = canlaugh_import_pending_banana()

    if not pending then
        return false
    end

    pending.catalysts = (pending.catalysts or 0) + 1
    return true
end

local function canlaugh_create_import_banana(pending, lock)
    G.E_MANAGER:add_event(Event({
        func = function()
            local key = pending and pending.key
            if not key then
                G.GAME.joker_buffer = math.max(0, (G.GAME.joker_buffer or 1) - 1)
                G.CONTROLLER.locks[lock] = nil
                return true
            end

            local card = create_card("Joker", G.jokers, nil, nil, nil, nil, key, "canlaugh_import")
            card.from_tag = true
            card:add_to_deck()
            G.jokers:emplace(card)
            card:start_materialize()

            for _ = 1, pending.catalysts or 0 do
                canlaugh_catalyze_banana(card)
            end

            if CL.import_pending_banana == pending then
                CL.import_pending_banana = nil
            end
            G.GAME.joker_buffer = math.max(0, (G.GAME.joker_buffer or 1) - 1)
            G.CONTROLLER.locks[lock] = nil
            return true
        end,
    }))

    return true
end

local function canlaugh_apply_import_tag(self, tag, context)
    if not (context and context.type == "immediate") then
        return
    end

    local lock = tag.ID
    local pending_banana = canlaugh_import_pending_banana()

    if pending_banana then
        canlaugh_catalyze_pending_import_banana()
        G.CONTROLLER.locks[lock] = true
        tag:yep("+", G.C.GREEN, function()
            G.CONTROLLER.locks[lock] = nil
            return true
        end)
        tag.triggered = true
        return true
    end

    local owned_bananas = canlaugh_owned_bananas()

    if #owned_bananas > 0 then
        local target = canlaugh_choose_random(owned_bananas, "canlaugh_import_catalyze")
        if not target then
            return canlaugh_import_nope(tag)
        end

        G.CONTROLLER.locks[lock] = true
        tag:yep("+", G.C.GREEN, function()
            canlaugh_catalyze_banana(target)
            G.CONTROLLER.locks[lock] = nil
            return true
        end)
        tag.triggered = true
        return true
    end

    if not canlaugh_import_has_room() then
        return canlaugh_import_nope(tag)
    end

    local level = canlaugh_next_banana_level()
    local candidates = level and canlaugh_collect_banana_candidates()[level] or nil
    local key = canlaugh_choose_random(candidates, "canlaugh_import_banana")

    if not key then
        return canlaugh_import_nope(tag)
    end

    local pending = canlaugh_reserve_import_banana(key)
    G.CONTROLLER.locks[lock] = true
    tag:yep("+", G.C.YELLOW, function()
        return canlaugh_create_import_banana(pending, lock)
    end)
    tag.triggered = true
    return true
end

SMODS.Tag({
    key = "import",
    atlas = "import_tag",
    order = 44,
    config = { type = "immediate" },
    pos = { x = 0, y = 0 },
    loc_txt = {
        name = "Import Tag",
        text = {
            "Create or catalyze",
            "your next {C:attention}Banana{}",
            "{C:inactive}(Must have room){}",
        },
    },
    apply = canlaugh_apply_import_tag,
})
