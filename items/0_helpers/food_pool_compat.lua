local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local BASE_GAME_FOOD_KEYS = {
    j_gros_michel = true,
    j_egg = true,
    j_ice_cream = true,
    j_cavendish = true,
    j_turtle_bean = true,
    j_diet_cola = true,
    j_popcorn = true,
    j_ramen = true,
    j_selzer = true,
}

CL.food_center_keys = CL.food_center_keys or BASE_GAME_FOOD_KEYS

local function canlaugh_center_has_attribute(center, attribute)
    local attributes = center and center.attributes

    if type(attributes) ~= "table" then
        return false
    end

    if attributes[attribute] then
        return true
    end

    for _, value in pairs(attributes) do
        if value == attribute then
            return true
        end
    end

    return false
end

function CL.center_is_food(center)
    if not center then
        return false
    end

    if CL.food_center_keys[center.key] or CL.food_center_keys[center.original_key] then
        return true
    end

    if center.pools and center.pools.Food then
        return true
    end

    if canlaugh_center_has_attribute(center, "food") or canlaugh_center_has_attribute(center, "Food") then
        return true
    end

    local aspirant_food = rawget(_G, "Aspirant")
        and Aspirant.food
        and Aspirant.food.is_food_center

    if type(aspirant_food) == "function" then
        local ok, is_food = pcall(aspirant_food, center)
        if ok and is_food then
            return true
        end
    end

    return false
end

local function canlaugh_mark_food_center(center)
    if not CL.center_is_food(center) then
        return false
    end

    center.pools = center.pools or {}
    center.pools.Food = true
    return true
end

if SMODS and SMODS.ObjectType and not (SMODS.ObjectTypes and SMODS.ObjectTypes.Food) then
    SMODS.ObjectType({
        key = "Food",
        cards = BASE_GAME_FOOD_KEYS,
    })
end

function CL.sync_food_pool_center(center)
    if not canlaugh_mark_food_center(center) then
        return
    end

    local food_type = SMODS and SMODS.ObjectTypes and SMODS.ObjectTypes.Food
    if food_type and type(food_type.inject_card) == "function" and G and G.P_CENTER_POOLS then
        food_type:inject_card(center)
    end
end

function CL.sync_food_pool()
    if not (G and G.P_CENTERS) then
        return
    end

    for _, center in pairs(G.P_CENTERS) do
        CL.sync_food_pool_center(center)
    end
end

if SMODS and SMODS.Center and type(SMODS.Center.inject) == "function" and not CL.food_pool_center_inject_hook_installed then
    CL.food_pool_center_inject_hook_installed = true
    local canlaugh_center_inject_ref = SMODS.Center.inject

    function SMODS.Center:inject(...)
        canlaugh_mark_food_center(self)
        local results = { canlaugh_center_inject_ref(self, ...) }
        CL.sync_food_pool_center(self)
        return unpack(results)
    end
end

if SMODS and SMODS.ObjectType and type(SMODS.ObjectType.inject) == "function" and not CL.food_pool_object_type_inject_hook_installed then
    CL.food_pool_object_type_inject_hook_installed = true
    local canlaugh_object_type_inject_ref = SMODS.ObjectType.inject

    function SMODS.ObjectType:inject(...)
        local results = { canlaugh_object_type_inject_ref(self, ...) }

        if self and self.key == "Food" then
            CL.sync_food_pool()
        end

        return unpack(results)
    end
end
