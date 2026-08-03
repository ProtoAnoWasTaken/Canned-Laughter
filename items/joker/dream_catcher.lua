local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_active_dream_catcher()
    for _, joker in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local center = joker and joker.config and joker.config.center
        if center
            and center.key == "j_canlaugh_dream_catcher"
            and not joker.debuff
            and not joker.removed
            and not joker.getting_sliced
        then
            return joker
        end
    end
end

local function canlaugh_random_deck_card()
    local candidates = {}

    for _, card in ipairs((G and G.playing_cards) or {}) do
        if card and not card.removed and not card.destroyed then
            candidates[#candidates + 1] = card
        end
    end

    if #candidates == 0 then
        return nil
    end

    return pseudorandom_element(candidates, pseudoseed(
        "canlaugh_dream_catcher_shop_" .. tostring(G and G.GAME and G.GAME.round or "")
    ))
end

local function canlaugh_dream_catcher_shop_done()
    local round = G and G.GAME and G.GAME.current_round
    return round and round.canlaugh_dream_catcher_shop_done
end

local function canlaugh_mark_dream_catcher_shop_done()
    local round = G and G.GAME and G.GAME.current_round
    if round then
        round.canlaugh_dream_catcher_shop_done = true
    end
end

local function canlaugh_reset_dream_catcher_shop()
    local round = G and G.GAME and G.GAME.current_round
    if round then
        round.canlaugh_dream_catcher_shop_done = nil
    end
end

local function canlaugh_create_dream_shop_copy(area)
    local source = canlaugh_random_deck_card()
    if not source or type(copy_card) ~= "function" then
        return nil
    end

    local copy = copy_card(source)
    if not copy then
        return nil
    end

    if copy.ability then
        copy.ability.canlaugh_temporary = nil
        copy.ability.canlaugh_temporary_still_life = nil
    end

    if type(copy.set_cost) == "function" then
        copy:set_cost()
    end

    if type(create_shop_card_ui) == "function" then
        create_shop_card_ui(copy, copy.ability and copy.ability.set, area)
    end

    return copy
end

SMODS.Atlas({
    key = "dream_catcher",
    path = "dreamcatcher.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "dream_catcher",
    name = "Dream Catcher",
    atlas = "dream_catcher",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 5,
    loc_txt = {
        name = "Dream Catcher",
        text = {
            "When entering a {C:attention}Shop{}, the",
            "first slot has a copy of a",
            "random card from your full deck",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.ending_shop and not context.blueprint then
            canlaugh_reset_dream_catcher_shop()
        end
    end,
})

if SMODS and type(SMODS.create_shop_card) == "function" and not CL.dream_catcher_shop_hook_installed then
    CL.dream_catcher_shop_hook_installed = true
    local create_shop_card_ref = SMODS.create_shop_card

    function SMODS.create_shop_card(area)
        local first_shop_slot = area == G.shop_jokers and #((area and area.cards) or {}) == 0

        if first_shop_slot and not canlaugh_dream_catcher_shop_done() and canlaugh_active_dream_catcher() then
            canlaugh_mark_dream_catcher_shop_done()
            local copy = canlaugh_create_dream_shop_copy(area)
            if copy then
                return copy
            end
        end

        return create_shop_card_ref(area)
    end
end

if CL.barter then
    CL.barter.register_rep_modifier("dream_catcher", function(phase, context)
        if phase == "availability" then
            if (context.base_reps or 0) > 0 then
                context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_dream_catcher") or {})
            end
            return
        end

        if phase == "hand" then
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_dream_catcher") or {}) do
                local rep_pool = CL.barter.rep_pool or {}
                local rep = pseudorandom_element(rep_pool, pseudoseed(
                    "canlaugh_dream_catcher_barter_" .. tostring(joker.sort_id or "")
                ))
                if rep then
                    CL.barter.add_rep(copy_table(rep), joker)
                end
            end
        end
    end)
end
