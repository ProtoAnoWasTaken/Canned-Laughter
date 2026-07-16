SMODS.Atlas({
    key = "challenged_joker",
    path = "challenged_joker.png",
    px = 69,
    py = 93,
})

local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_is_challenge_run()
    return G and G.GAME and G.GAME.challenge
end

local function canlaugh_pool_entry_key(entry)
    return type(entry) == "table" and entry.key or entry
end

local function canlaugh_pool_key_available(entry)
    local key = canlaugh_pool_entry_key(entry)

    if not key or key == "UNAVAILABLE" or key == "empty_rarity" then
        return false
    end

    return not (G and G.GAME and G.GAME.banned_keys and G.GAME.banned_keys[key])
end

local function canlaugh_pool_has_available(pool)
    for _, entry in ipairs(pool or {}) do
        if canlaugh_pool_key_available(entry) then
            return true
        end
    end

    return false
end

local function canlaugh_args_include_label(args, label)
    if not (args and label) then
        return false
    end

    if args.type == label then
        return true
    end

    for _, arg_label in ipairs(args.types or {}) do
        if arg_label == label then
            return true
        end
    end

    for _, arg_label in ipairs(args.attributes or {}) do
        if arg_label == label then
            return true
        end
    end

    return false
end

local function canlaugh_pool_is_joker_like(pool, args)
    if canlaugh_args_include_label(args, "Joker") or canlaugh_args_include_label(args, "Food") then
        return true
    end

    for _, entry in ipairs(pool or {}) do
        local key = canlaugh_pool_entry_key(entry)
        local center = G and G.P_CENTERS and G.P_CENTERS[key]
        if center and center.set == "Joker" then
            return true
        end
    end

    return false
end

local function canlaugh_challenged_fallback_pool(pool, args)
    if canlaugh_is_challenge_run()
        and canlaugh_pool_is_joker_like(pool, args)
        and not canlaugh_pool_has_available(pool)
        and G
        and G.P_CENTERS
        and G.P_CENTERS.j_canlaugh_challenged_joker
    then
        return { "j_canlaugh_challenged_joker" }
    end

    return nil
end

local function canlaugh_joker_is_permitted(center)
    return center
        and center.set == "Joker"
        and center.key ~= "j_canlaugh_challenged_joker"
        and center.rarity ~= 4
        and center.unlocked ~= false
        and not (G.GAME and G.GAME.banned_keys and G.GAME.banned_keys[center.key])
        and not (G.GAME and G.GAME.used_jokers and G.GAME.used_jokers[center.key] and not SMODS.showman(center.key))
        and SMODS.add_to_pool(center)
end

local function canlaugh_permitted_joker_pool()
    local pool = {}

    for _, center in ipairs((G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Joker) or {}) do
        if canlaugh_joker_is_permitted(center) then
            pool[#pool + 1] = center.key
        end
    end

    return pool
end

local function canlaugh_create_challenged_replacement(source)
    if not (SMODS and type(SMODS.add_card) == "function" and G and G.jokers) then
        return
    end

    local pool = canlaugh_permitted_joker_pool()
    if #pool == 0 then
        return
    end

    local key = pseudorandom_element(pool, pseudoseed("canlaugh_challenged_joker"))
    local edition = source and source.edition and copy_table(source.edition) or nil
    local card = SMODS.add_card({
        set = "Joker",
        area = G.jokers,
        key = key,
        no_edition = true,
        key_append = "canlaugh_challenged_joker",
    })

    if card and edition and next(edition) then
        card:set_edition(edition, true, true)
    end
end

if SMODS and type(SMODS.cull_pool) == "function" and not CL.challenged_joker_pool_hook_installed then
    CL.challenged_joker_pool_hook_installed = true
    local canlaugh_cull_pool_ref = SMODS.cull_pool

    function SMODS.cull_pool(pool, args)
        local result = canlaugh_cull_pool_ref(pool, args)
        local fallback = canlaugh_challenged_fallback_pool(result, args)

        if fallback then
            return fallback
        end

        return result
    end
end

if type(get_current_pool) == "function" and not CL.challenged_joker_current_pool_hook_installed then
    CL.challenged_joker_current_pool_hook_installed = true
    local canlaugh_get_current_pool_ref = get_current_pool

    function get_current_pool(_type, _rarity, _legendary, _append)
        local pool, pool_key = canlaugh_get_current_pool_ref(_type, _rarity, _legendary, _append)
        local fallback = canlaugh_challenged_fallback_pool(pool, { type = _type })

        if fallback then
            return fallback, pool_key
        end

        return pool, pool_key
    end
end

if SMODS and type(SMODS.poll_object) == "function" and not CL.challenged_joker_poll_object_hook_installed then
    CL.challenged_joker_poll_object_hook_installed = true
    local canlaugh_poll_object_ref = SMODS.poll_object

    function SMODS.poll_object(args)
        local key = canlaugh_poll_object_ref(args)

        if key == "j_joker"
            and canlaugh_is_challenge_run()
            and canlaugh_pool_is_joker_like(nil, args)
            and not canlaugh_pool_key_available(key)
            and G
            and G.P_CENTERS
            and G.P_CENTERS.j_canlaugh_challenged_joker
        then
            return "j_canlaugh_challenged_joker"
        end

        return key
    end
end

if Card and type(Card.sell_card) == "function" and not CL.challenged_joker_sell_hook_installed then
    CL.challenged_joker_sell_hook_installed = true
    local canlaugh_sell_card_ref = Card.sell_card

    function Card:sell_card(...)
        local should_replace = self
            and self.config
            and self.config.center
            and self.config.center.key == "j_canlaugh_challenged_joker"
        local edition = should_replace and self.edition and copy_table(self.edition) or nil
        local results = { canlaugh_sell_card_ref(self, ...) }

        if should_replace then
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.45,
                func = function()
                    canlaugh_create_challenged_replacement({ edition = edition })
                    return true
                end,
            }))
        end

        return unpack(results)
    end
end

SMODS.Joker({
    key = "challenged_joker",
    name = "Challenged Joker",
    atlas = "challenged_joker",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 0,
    unlocked = true,
    loc_txt = {
        name = "Challenged Joker",
        text = {
            "Sell this Joker to get",
            "one permitted in your run",
            "Otherwise, {C:mult}+#1#{} Mult",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card and card.ability and card.ability.extra or self.config.extra,
            },
        }
    end,
    config = {
        extra = 4,
    },
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    in_pool = function()
        return false
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                mult = card.ability.extra,
            }
        end
    end,
})
