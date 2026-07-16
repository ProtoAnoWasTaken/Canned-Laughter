SMODS.Atlas({
    key = "edge_of_the_earth",
    path = "edge_of_the_earth.png",
    px = 69,
    py = 93,
})

local function canlaugh_edge_is_boss()
    local blind = G and G.GAME and G.GAME.blind
    return blind
        and (
            blind.boss
            or (type(blind.get_type) == "function" and blind:get_type() == "Boss")
        )
end

local function canlaugh_edge_key(event)
    local blind = G and G.GAME and G.GAME.blind
    local blind_key = blind and blind.config and blind.config.blind and blind.config.blind.key
    return table.concat({
        event or "",
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or ""),
        tostring(G and G.GAME and G.GAME.blind_on_deck or ""),
        tostring(blind_key or ""),
    }, ":")
end

local function canlaugh_edge_random_tag_key(seed)
    if type(get_next_tag_key) == "function" then
        return get_next_tag_key(seed) or "tag_uncommon"
    end
    return "tag_uncommon"
end

local function canlaugh_edge_queue_tag(tag_key)
    if not (tag_key and Tag and type(add_tag) == "function") then
        return false
    end

    local add = function()
        add_tag(Tag(tag_key))
        return true
    end

    if G.E_MANAGER and Event then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.35,
            func = add,
        }))
    else
        add()
    end
    return true
end

local function canlaugh_edge_joker_present()
    for _, joker in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local center = joker.config and joker.config.center
        if center and center.key == "j_canlaugh_edge_of_the_earth" and not joker.debuff then
            return joker
        end
    end
end

if G and G.FUNCS and type(G.FUNCS.skip_blind) == "function" and not CannedLaughter.edge_skip_blind_hook_installed then
    CannedLaughter.edge_skip_blind_hook_installed = true
    local skip_blind_ref = G.FUNCS.skip_blind

    G.FUNCS.skip_blind = function(e, ...)
        local edge = canlaugh_edge_joker_present()
        if edge then
            card_eval_status_text(edge, "extra", nil, nil, nil, {
                message = "Can't skip!",
                colour = G.C.RED,
            })
            return
        end
        return skip_blind_ref(e, ...)
    end
end

SMODS.Joker({
    key = "edge_of_the_earth",
    name = "Edge of the Earth",
    atlas = "edge_of_the_earth",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = { extra = { triggered = {} } },
    loc_txt = {
        name = "Edge of the Earth",
        text = {
            "{C:red,E:1}You may not skip Blinds{}",
            "Beating a {C:attention}Boss Blind{} grants",
            "two random {C:attention}Tags{}",
        },
        unlock = {
            "Successfully barter with a",
            "{C:attention}Mega Buffoon Pack{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = {} }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_mega_buffoon_barter"
    end,
    calculate = function(self, card, context)
        if context.blind_defeated
            and canlaugh_edge_is_boss()
            and not context.blueprint
            and not context.retrigger_joker
            and not card.getting_sliced
        then
            local extra = card.ability.extra
            local key = canlaugh_edge_key("defeated")
            if not extra.triggered[key] then
                extra.triggered[key] = true
                local first = canlaugh_edge_random_tag_key("canlaugh_edge_of_the_earth_1")
                local second = canlaugh_edge_random_tag_key("canlaugh_edge_of_the_earth_2")
                canlaugh_edge_queue_tag(first)
                canlaugh_edge_queue_tag(second)
                return {
                    message = "+2 Tags",
                    colour = G.C.PURPLE,
                }
            end
        end
    end,
})

if CannedLaughter.unlocks and CannedLaughter.unlocks.register_mega_barter_joker then
    CannedLaughter.unlocks.register_mega_barter_joker(
        "Buffoon",
        "canlaugh_mega_buffoon_barter",
        "j_canlaugh_edge_of_the_earth"
    )
end
