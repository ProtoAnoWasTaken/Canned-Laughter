local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.stanczyk_face_joker_keys = CL.stanczyk_face_joker_keys or {
    j_business = true,
    j_midas_mask = true,
    j_photograph = true,
    j_scary_face = true,
    j_smiley = true,
    j_sock_and_buskin = true,
    j_triboulet = true,
    j_canlaugh_christmas_card = true,
}

function CL.register_stanczyk_face_joker(key)
    if type(key) == "string" and key ~= "" then
        CL.stanczyk_face_joker_keys[key] = true
    end
end

local function canlaugh_stanczyk_active()
    for _, joker in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local center = joker and joker.config and joker.config.center
        if center
            and center.key == "j_canlaugh_stanczyk"
            and not joker.debuff
            and not joker.removed
            and not joker.getting_sliced
        then
            return true
        end
    end

    return false
end

local function canlaugh_stanczyk_effect_returned(result, post)
    if post or result == true then
        return true
    end

    return type(result) == "table" and next(result) ~= nil
end

local function canlaugh_stanczyk_merge(first, second)
    if not first then
        return second
    end

    if not second then
        return first
    end

    if SMODS and type(SMODS.merge_effects) == "function" then
        return SMODS.merge_effects({ first }, { second })
    end

    first.extra = second
    return first
end

local function canlaugh_stanczyk_proxy(rank)
    return {
        ability = {
            set = "Joker",
        },
        canlaugh_stanczyk_proxy = true,
        get_id = function()
            return rank
        end,
        is_face = function()
            return true
        end,
        is_suit = function()
            return false
        end,
        get_nominal = function()
            return rank
        end,
        get_chip_mult = function()
            return 0
        end,
    }
end

local function canlaugh_stanczyk_scoring_context(context)
    return context
        and (
            context.joker_main
            or context.individual and context.cardarea == G.play
            or context.repetition and context.cardarea == G.play
        )
end

local function canlaugh_stanczyk_proxy_context(context, rank)
    local proxy_context = {}

    for key, value in pairs(context) do
        proxy_context[key] = value
    end

    proxy_context.joker_main = nil
    proxy_context.before = nil
    proxy_context.after = nil
    proxy_context.final_scoring_step = nil
    proxy_context.individual = true
    proxy_context.cardarea = G.play
    proxy_context.other_card = canlaugh_stanczyk_proxy(rank)
    proxy_context.canlaugh_stanczyk_proxy = true
    return proxy_context
end

local function canlaugh_stanczyk_face_effects(context, source)
    local effects = nil

    for _, target in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local center = target and target.config and target.config.center
        if target ~= source
            and center
            and CL.stanczyk_face_joker_keys[center.key]
            and not target.debuff
            and not target.removed
            and not target.getting_sliced
        then
            for _, rank in ipairs({ 12, 13 }) do
                local result = target:calculate_joker(canlaugh_stanczyk_proxy_context(context, rank))
                if type(result) == "table" then
                    result.card = result.card or target
                end
                effects = canlaugh_stanczyk_merge(effects, result)
            end
        end
    end

    return effects
end

if Card and type(Card.calculate_joker) == "function" and CL.stanczyk_calculate_hook_version ~= 1 then
    CL.stanczyk_calculate_hook_version = 1
    local canlaugh_stanczyk_calculate_ref = Card.calculate_joker

    function Card:calculate_joker(context, ...)
        local result, post = canlaugh_stanczyk_calculate_ref(self, context, ...)
        local center = self.config and self.config.center

        if center
            and center.set == "Joker"
            and context
            and not context.canlaugh_stanczyk_proxy
            and not context.retrigger_joker_check
            and canlaugh_stanczyk_active()
            and canlaugh_stanczyk_scoring_context(context)
            and canlaugh_stanczyk_effect_returned(result, post)
        then
            local proxy_effects = canlaugh_stanczyk_face_effects(context, self)
            result = canlaugh_stanczyk_merge(result, proxy_effects)
        end

        return result, post
    end
end

SMODS.Atlas({
    key = "stanczyk_back",
    path = "stanczyk_back.png",
    px = 69,
    py = 93,
})

SMODS.Atlas({
    key = "stanczyk_front",
    path = "stanczyk_front.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "stanczyk",
    name = "????????",
    atlas = "stanczyk_back",
    soul_atlas = "stanczyk_front",
    pos = { x = 0, y = 0 },
    soul_pos = { x = 0, y = 0 },
    rarity = 4,
    cost = 20,
    unlocked = false,
    discovered = false,
    unlock_condition = {
        type = "",
        extra = "",
        hidden = true,
    },
    loc_txt = {
        name = "????????",
        text = {
            "Jokers are considered {C:attention}Kings{}",
            "and {C:attention}Queens{} for scoring purposes",
            "{C:inactive,s:0.8}(Or... are Kings and Queens Jokers?){}",
        },
    },
    loc_vars = function()
        return {
            key = CL.challenge_completed("spirited_away") and "j_canlaugh_stanczyk_revealed" or nil,
            vars = {},
        }
    end,
    locked_loc_vars = function(self, info_queue, card)
        return {
            not_hidden = true,
            vars = {},
        }
    end,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_stanczyk_soul_discovered"
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
})
