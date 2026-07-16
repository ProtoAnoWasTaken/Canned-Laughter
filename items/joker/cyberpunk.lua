SMODS.Atlas({
    key = "cyberpunk",
    path = "cyberpunk.png",
    px = 69,
    py = 93,
})

local function canlaugh_random_tag_key()
    if type(get_next_tag_key) ~= "function" then
        return "tag_uncommon"
    end

    return get_next_tag_key("canlaugh_cyberpunk")
        or (G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.blind_tags and G.GAME.round_resets.blind_tags[G.GAME.blind_on_deck])
        or "tag_uncommon"
end

local function canlaugh_queue_tag(tag_key)
    if type(add_tag) ~= "function" or not Tag then
        return false
    end

    if G and G.E_MANAGER and Event then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.35,
            func = function()
                pcall(function()
                    add_tag(Tag(tag_key))
                end)
                return true
            end,
        }))
        return true
    end

    return pcall(function()
        add_tag(Tag(tag_key))
    end)
end

local function canlaugh_current_blind_is_boss()
    local blind = G and G.GAME and G.GAME.blind

    return blind
        and (
            blind.boss
            or (
                type(blind.get_type) == "function"
                and blind:get_type() == "Boss"
            )
        )
end

local function canlaugh_cyberpunk_event(context)
    if context.blind_defeated then
        return "defeated", "Shutdown!"
    end

    if context.blind_disabled then
        return "disabled", "Breached!"
    end
end

local function canlaugh_cyberpunk_key(event)
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

local function canlaugh_cyberpunk_extra(card)
    card.ability.extra = card.ability.extra or {}
    card.ability.extra.triggered = card.ability.extra.triggered or {}

    return card.ability.extra
end

local function canlaugh_straight_contains_2_and_7(args)
    if not (args and args.handname == "Straight" and args.scoring_hand) then
        return false
    end

    local has_two = false
    local has_seven = false

    for _, playing_card in ipairs(args.scoring_hand) do
        local id = playing_card and playing_card:get_id()
        has_two = has_two or id == 2
        has_seven = has_seven or id == 7
    end

    return has_two and has_seven
end

SMODS.Joker({
    key = "cyberpunk",
    name = "Cyberpunk",
    atlas = "cyberpunk",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = {
        extra = {
            triggered = {},
        },
    },
    loc_txt = {
        name = "Cyberpunk",
        text = {
            "Create a random {C:attention}Tag{}",
            "when the {C:attention}Boss Blind{}",
            "is defeated or disabled",
        },
        unlock = {
            "Play both a {C:attention}2{} and a {C:attention}7{}",
            "in a {C:attention}Straight{}",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args
            and args.type == "hand"
            and canlaugh_straight_contains_2_and_7(args)
    end,
    calculate = function(self, card, context)
        local event, message = canlaugh_cyberpunk_event(context)

        if not event
            or context.blueprint
            or context.retrigger_joker
            or card.getting_sliced
        then
            return
        end

        local extra = canlaugh_cyberpunk_extra(card)

        if not canlaugh_current_blind_is_boss() then
            return
        end

        local key = canlaugh_cyberpunk_key(event)

        if extra.triggered[key] then
            return
        end

        local tag_key = canlaugh_random_tag_key()

        if canlaugh_queue_tag(tag_key) then
            extra.triggered[key] = true
            return {
                message = message,
                colour = G.C.CHIPS,
            }
        end
    end,
})
