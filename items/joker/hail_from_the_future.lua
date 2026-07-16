SMODS.Atlas({
    key = "hail_from_the_future",
    path = "hail_from_the_future.png",
    px = 69,
    py = 93,
})

local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_hail_has_room()
    if CL.tarot and type(CL.tarot.has_consumable_room) == "function" then
        return CL.tarot.has_consumable_room(1)
    end

    return G
        and G.consumeables
        and G.GAME
        and #G.consumeables.cards + (G.GAME.consumeable_buffer or 0) < G.consumeables.config.card_limit
end

local function canlaugh_hail_create_spectral()
    if not canlaugh_hail_has_room() then
        return false
    end

    local create = function()
        local spectral = create_card("Spectral", G.consumeables, nil, nil, nil, nil, nil, "canlaugh_hail_from_the_future")
        if spectral then
            if type(spectral.set_edition) == "function" then
                spectral:set_edition({ negative = true }, true, true)
            end
            spectral:add_to_deck()
            G.consumeables:emplace(spectral)
        end
        G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 1) - 1)
        return true
    end

    G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
    if G.E_MANAGER and Event then
        G.E_MANAGER:add_event(Event({
            trigger = "before",
            delay = 0,
            func = create,
        }))
    else
        create()
    end
    return true
end

local function canlaugh_hail_extra(card)
    card.ability.extra = card.ability.extra or { x_mult_gain = 0.25, used = {} }
    card.ability.extra.used = card.ability.extra.used or {}
    return card.ability.extra
end

local function canlaugh_hail_unique_count(extra)
    local count = 0
    for _ in pairs(extra.used or {}) do
        count = count + 1
    end
    return count
end

SMODS.Joker({
    key = "hail_from_the_future",
    name = "Hail from the Future",
    atlas = "hail_from_the_future",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = { extra = { x_mult_gain = 0.25, used = {} } },
    loc_txt = {
        name = "Hail from the Future",
        text = {
            "Create a random {C:dark_edition}Negative{}",
            "{C:spectral}Spectral{} card at the start of the Blind",
            "Gains {X:mult,C:white}X#1#{} Mult for each unique",
            "{C:spectral}Spectral{} used",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult){}",
        },
        unlock = {
            "Successfully barter with a",
            "{C:attention}Mega Spectral Pack{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = canlaugh_hail_extra(card or { ability = { extra = self.config.extra } })
        local unique = canlaugh_hail_unique_count(extra)
        return {
            vars = {
                extra.x_mult_gain,
                1 + unique * extra.x_mult_gain,
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_mega_spectral_barter"
    end,
    calculate = function(self, card, context)
        local extra = canlaugh_hail_extra(card)
        local used = context.consumeable
        if not used and type(context.using_consumeable) == "table" then
            used = context.using_consumeable
        end

        if context.setting_blind and not context.blueprint and not context.retrigger_joker then
            if canlaugh_hail_create_spectral() then
                return {
                    message = "+Spectral",
                    colour = G.C.SECONDARY_SET.Spectral,
                }
            end
        end

        if context.using_consumeable
            and used
            and used.ability
            and used.ability.set == "Spectral"
            and not context.blueprint
            and not context.retrigger_joker
        then
            local key = used.config and used.config.center and used.config.center.key
            if key and not extra.used[key] then
                extra.used[key] = true
                return {
                    message = "New Spectral!",
                    colour = G.C.SECONDARY_SET.Spectral,
                    message_card = used,
                }
            end
        end

        if context.joker_main then
            local unique = canlaugh_hail_unique_count(extra)
            if unique > 0 then
                return {
                    x_mult = 1 + unique * extra.x_mult_gain,
                }
            end
        end
    end,
})

if CL.unlocks and CL.unlocks.register_mega_barter_joker then
    CL.unlocks.register_mega_barter_joker(
        "Spectral",
        "canlaugh_mega_spectral_barter",
        "j_canlaugh_hail_from_the_future"
    )
end
