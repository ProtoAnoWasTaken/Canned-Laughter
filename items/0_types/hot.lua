local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.hot = CL.hot or {}

local HOT = CL.hot

HOT.cards = HOT.cards or {
    "j_rocket",
    "j_campfire",
    "j_duo",
    "j_trio",
    "j_family",
    "j_order",
    "j_tribe",
    "j_burnt",
    "j_canlaugh_joker_mold",
    "j_canlaugh_the_odyssey",
    "j_canlaugh_author_avatar",
    "j_canlaugh_mccready",
    "m_canlaugh_blazing",
}

local HOT_CENTER_LOOKUP = {}

for _, key in ipairs(HOT.cards) do
    HOT_CENTER_LOOKUP[key] = true
end

CL.hot_center_keys = HOT_CENTER_LOOKUP

local function key_matches(center, key)
    if not center then
        return false
    end

    return center.key == key or center.original_key == key
end

local function mark_hot(center)
    if not center then
        return
    end

    center.pools = center.pools or {}
    center.pools.Hot = true
end

local function find_hot_center(key)
    if SMODS and SMODS.Jokers then
        for _, joker in pairs(SMODS.Jokers) do
            if joker and joker.set == "Joker" and key_matches(joker, key) then
                return joker
            end
        end
    end

    if G and G.P_CENTERS then
        for _, center in pairs(G.P_CENTERS) do
            if key_matches(center, key) then
                return center
            end
        end
    end

    return nil
end

local function apply_hot_tags()
    for _, key in ipairs(HOT.cards) do
        mark_hot(find_hot_center(key))
    end
end

local function insert_center_without_reordering(pool, center)
    if not pool or not center then
        return
    end

    for _, existing in ipairs(pool) do
        if existing == center or existing.key == center.key then
            return
        end
    end

    pool[#pool + 1] = center
end

local function remove_center_from_pool(pool, key)
    if not pool then
        return
    end

    for index = #pool, 1, -1 do
        local center = pool[index]
        if center and center.key == key then
            table.remove(pool, index)
        end
    end
end

local hot_type = SMODS and SMODS.ObjectTypes and SMODS.ObjectTypes.Hot

if hot_type then
    hot_type.cards = hot_type.cards or {}

    for _, key in ipairs(HOT.cards) do
        hot_type.cards[key] = true
    end
else
    SMODS.ObjectType({
        key = "Hot",
        default = "j_rocket",
        cards = {},
        inject_card = function(self, center)
            if center.set ~= self.key then
                insert_center_without_reordering(G.P_CENTER_POOLS[self.key], center)
            end

            center.pools = center.pools or {}
            center.pools[self.key] = true
        end,
        delete_card = function(self, center)
            if center.set ~= self.key then
                remove_center_from_pool(G.P_CENTER_POOLS[self.key], center.key)
            end

            if center.pools then
                center.pools[self.key] = nil
            end
        end,
        inject = function(self)
            SMODS.ObjectType.inject(self)

            for _, key in ipairs(HOT.cards) do
                local center = find_hot_center(key)
                if center then
                    self:inject_card(center)
                end
            end

            apply_hot_tags()
        end,
    })
end

apply_hot_tags()

function CL.center_is_hot(center)
    if not center then
        return false
    end

    if HOT_CENTER_LOOKUP[center.key] or HOT_CENTER_LOOKUP[center.original_key] then
        return true
    end

    local registered_hot_type = SMODS and SMODS.ObjectTypes and SMODS.ObjectTypes.Hot
    if registered_hot_type and registered_hot_type.cards and registered_hot_type.cards[center.key] then
        return true
    end

    if center.pools and center.pools.Hot then
        return true
    end

    local attributes = center.attributes
    if type(attributes) ~= "table" then
        return false
    end

    return attributes.Hot == true or attributes.hot == true
end

function CL.is_hot_card(card)
    if not card then
        return false
    end

    if card.seal == "canlaugh_phosphate" then
        return true
    end

    return CL.center_is_hot(card.config and card.config.center)
end
