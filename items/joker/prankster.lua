SMODS.Atlas({
    key = "prankster",
    path = "prankster.png",
    px = 69,
    py = 93,
})

local CL = CannedLaughter
local canlaugh_is_glitter = CL.is_glitter
local canlaugh_is_negative = CL.is_negative

local canlaugh_is_joker_card = CL.is_joker_card

local function canlaugh_max_selected_cards()
    return (G and G.hand and G.hand.config and G.hand.config.highlighted_limit)
        or (G and G.GAME and G.GAME.starting_params and G.GAME.starting_params.play_limit)
        or 5
end

local function canlaugh_full_scoring_glitter_hand(args)
    local scoring_hand = args and args.scoring_hand
    local full_hand = args and args.full_hand
    local max_selected = canlaugh_max_selected_cards()

    if not (scoring_hand and full_hand) then
        return false
    end

    if #scoring_hand ~= max_selected or #full_hand ~= max_selected then
        return false
    end

    for _, playing_card in ipairs(scoring_hand) do
        if not canlaugh_is_glitter(playing_card) then
            return false
        end
    end

    return true
end

local function canlaugh_glitter_consumable_targets()
    local targets = {}

    for _, consumable in ipairs((G.consumeables and G.consumeables.cards) or {}) do
        if consumable
            and not canlaugh_is_glitter(consumable)
            and not canlaugh_is_negative(consumable)
        then
            targets[#targets + 1] = consumable
        end
    end

    return targets
end

local function canlaugh_glitter_consumables_after_message(targets)
    if #targets == 0 then
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.35,
        func = function()
            for _, consumable in ipairs(targets) do
                if consumable
                    and not consumable.removed
                    and not consumable.destroyed
                    and not canlaugh_is_glitter(consumable)
                    and not canlaugh_is_negative(consumable)
                then
                    consumable:set_edition("e_canlaugh_glitter", true)
                end
            end

            return true
        end,
    }))
end

SMODS.Joker({
    key = "prankster",
    name = "Prankster",
    atlas = "prankster",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    loc_txt = {
        name = "Prankster",
        text = {
            "Applies {C:canlaugh_glitter,T:e_canlaugh_glitter}Glitter{}",
            "to all {C:attention}consumables{}",
            "when a {C:attention}Joker{} is sold",
        },
        unlock = {
            "Play a full hand of",
            "scoring {C:canlaugh_glitter}Glitter{} cards",
        },
    },
    loc_vars = function(self, info_queue, card)
        if G and G.P_CENTERS and G.P_CENTERS.e_canlaugh_glitter then
            CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS.e_canlaugh_glitter, card)
        end

        return { vars = {} }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args
            and args.type == "hand"
            and canlaugh_full_scoring_glitter_hand(args)
    end,
    calculate = function(self, card, context)
        if context.selling_card
            and not context.blueprint
            and context.card ~= card
            and canlaugh_is_joker_card(context.card)
        then
            local targets = canlaugh_glitter_consumable_targets()

            if #targets > 0 then
                canlaugh_glitter_consumables_after_message(targets)
                return {
                    message = "Glitter!",
                    colour = G.C.CANLAUGH_GLITTER,
                }
            end
        end
    end,
})
