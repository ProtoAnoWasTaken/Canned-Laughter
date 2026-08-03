local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_pantograph_boss_blind()
    local blind = G and G.GAME and G.GAME.blind
    if not blind then
        return false
    end

    if type(blind.get_type) == "function" then
        return blind:get_type() == "Boss"
    end

    return blind.boss == true
end

local function canlaugh_pantograph_target(card)
    local jokers = G and G.jokers and G.jokers.cards or {}

    for index, joker in ipairs(jokers) do
        if joker == card then
            return jokers[index - 1]
        end
    end
end

local function canlaugh_pantograph_compatible(card)
    local target = canlaugh_pantograph_target(card)
    local center = target and target.config and target.config.center
    return target and not target.debuff and center and center.blueprint_compat == true
end

local function canlaugh_pantograph_main_end(card)
    if not (G and G.UIT and card and card.area == G.jokers) then
        return nil
    end

    local boss_blind = canlaugh_pantograph_boss_blind()
    local text_ref = "canlaugh_pantograph_status_ui"
    local bar_colour = G.C.GOLD
    local bar_func = nil

    if boss_blind then
        card.ability.blueprint_compat_ui = card.ability.blueprint_compat_ui or ""
        card.ability.blueprint_compat_check = nil
        text_ref = "blueprint_compat_ui"
        bar_colour = G.C.JOKER_GREY
        bar_func = "blueprint_compat"
    else
        card.ability.canlaugh_pantograph_status_ui = " inactive "
    end

    return {
        {
            n = G.UIT.C,
            config = {
                align = "bm",
                minh = 0.4,
            },
            nodes = {
                {
                    n = G.UIT.C,
                    config = {
                        ref_table = card,
                        align = "m",
                        colour = bar_colour,
                        r = 0.05,
                        padding = 0.06,
                        func = bar_func,
                    },
                    nodes = {
                        {
                            n = G.UIT.T,
                            config = {
                                ref_table = card.ability,
                                ref_value = text_ref,
                                colour = G.C.UI.TEXT_LIGHT,
                                scale = 0.256,
                            },
                        },
                    },
                },
            },
        },
    }
end

SMODS.Atlas({
    key = "pantograph",
    path = "pantograph.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "pantograph",
    name = "Pantograph",
    atlas = "pantograph",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    loc_txt = {
        name = "Pantograph",
        text = {
            "Copies the ability of the",
            "Joker to the left during",
            "a {C:attention}Boss Blind{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        if card and card.ability then
            if canlaugh_pantograph_boss_blind() then
                card.ability.blueprint_compat = canlaugh_pantograph_compatible(card)
                    and "compatible"
                    or "incompatible"
            else
                card.ability.blueprint_compat = "incompatible"
                card.ability.canlaugh_pantograph_status_ui = " inactive "
            end
        end

        return {
            vars = {},
            main_end = canlaugh_pantograph_main_end(card),
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if not canlaugh_pantograph_boss_blind() then
            card.ability.blueprint_compat = "incompatible"
            return
        end

        local target = canlaugh_pantograph_target(card)
        card.ability.blueprint_compat = canlaugh_pantograph_compatible(card)
            and "compatible"
            or "incompatible"

        local result = SMODS.blueprint_effect(card, target, context)
        if result then
            result.colour = G.C.BLUE
            return result
        end
    end,
})

if CL.barter then
    CL.barter.register_rep_modifier("pantograph", function(phase, context)
        if context.booster_kind ~= "Buffoon" then
            return
        end

        local jokers = G and G.jokers and G.jokers.cards or {}
        if phase == "availability" then
            for index, joker in ipairs(jokers) do
                local center = joker.config and joker.config.center
                if center and center.key == "j_canlaugh_pantograph" and jokers[index - 1] then
                    context.extra_reps = context.extra_reps + 1
                end
            end
            return
        end

        if phase == "hand" then
            for index, joker in ipairs(jokers) do
                local center = joker.config and joker.config.center
                if center and center.key == "j_canlaugh_pantograph" then
                    CL.barter.add_rep(CL.barter.buffoon_rep_for_joker(jokers[index - 1]), joker)
                end
            end
        end
    end)
end
