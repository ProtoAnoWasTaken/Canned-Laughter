local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "egg_man",
    path = "egg_man.png",
    px = 69,
    py = 93,
})

local EGG_CONTEXTS = {
    "setting_blind",
    "buying_card",
    "open_booster",
    "skip_blind",
    "ending_shop",
    "first_hand_drawn",
}

local function has_room()
    return G.jokers and #G.jokers.cards + (G.GAME.joker_buffer or 0) < G.jokers.config.card_limit
end

local function create_egg(card)
    if not has_room() then
        return
    end

    G.GAME.joker_buffer = (G.GAME.joker_buffer or 0) + 1
    G.E_MANAGER:add_event(Event({
        func = function()
            local egg = create_card(
                "Joker",
                G.jokers,
                nil,
                nil,
                nil,
                nil,
                "j_egg",
                "canlaugh_egg_man"
            )
            egg:add_to_deck()
            G.jokers:emplace(egg)
            if CL.record_egg_man_egg then CL.record_egg_man_egg() end
            G.GAME.joker_buffer = math.max(0, G.GAME.joker_buffer - 1)
            return true
        end,
    }))

    card.ability.extra.created = true
    return {
        message = "Egg!",
        colour = G.C.WHITE,
    }
end

SMODS.Joker({
    key = "egg_man",
    name = "Egg Man",
    atlas = "egg_man",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = {
        extra = {
            odds = 6,
            context = nil,
            created = false,
        },
    },
    loc_txt = {
        name = "Egg Man",
        text = {
            "Can create an {C:attention}Egg{} once every round",
            "{C:green}#1# in #2#{} chance to be forgotten",
            "{C:inactive}(Must have room)",
        },
        unlock = {
            "Not too important,",
            "not too unimportant.",
        },
    },
    loc_vars = function(self, _, card)
        local extra = card and card.ability.extra or self.config.extra
        local numerator, denominator = SMODS.get_probability_vars(
            card,
            1,
            extra.odds,
            "canlaugh_egg_man_forget"
        )
        return { vars = { numerator, denominator } }
    end,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_egg_man_unlock"
    end,
    calculate = function(self, card, context)
        local extra = card.ability.extra
        if context.setting_blind and not context.blueprint then
            extra.created = false
            extra.context = (CL.rules_card_active and CL.rules_card_active()) and "setting_blind"
                or pseudorandom_element(EGG_CONTEXTS, pseudoseed("canlaugh_egg_context"))
        end
        if not context.blueprint
            and not extra.created
            and extra.context
            and context[extra.context]
        then
            return create_egg(card)
        end

        if context.end_of_round
            and not context.individual
            and not context.repetition
            and not context.blueprint
            and SMODS.pseudorandom_probability(card, "canlaugh_egg_man_forget", 1, extra.odds)
        then
            SMODS.destroy_cards(card, nil, nil, true)
            return {
                message = "Forgotten!",
                colour = G.C.FILTER,
            }
        end
    end,
})

local function try_unlock(card)
    if card and card.config and card.config.center and card.config.center.key == "j_egg"
        and pseudorandom("canlaugh_egg_man_unlock") < 1 / 25 and check_for_unlock
    then
        check_for_unlock({ type = "canlaugh_egg_man_unlock" })
    end
end

if Card and Card.click and not CL.egg_man_click_hook then
    CL.egg_man_click_hook = true
    local click_ref = Card.click

    function Card:click(...)
        try_unlock(self)
        return click_ref(self, ...)
    end
end

if Card and Card.sell_card and not CL.egg_man_sell_hook then
    CL.egg_man_sell_hook = true
    local sell_ref = Card.sell_card

    function Card:sell_card(...)
        try_unlock(self)
        return sell_ref(self, ...)
    end
end

if CL.barter then
    CL.barter.register_special_rep("Buffoon", "j_egg", {
        key = "j_egg", set = "Joker", kind = "joker", rarity = 1, output = "effect", scaling = true,
        loc = { "Representative of a {C:attention}Common{}", "effect-providing Joker that scales" },
    })
    CL.barter.register_rep_modifier("egg_man", function(phase, context)
        if phase == "availability" and context.booster_kind == "Buffoon" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_egg_man") or {}); return
        end
        if phase == "hand" and context.booster_kind == "Buffoon" then
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_egg_man") or {}) do
                CL.barter.add_rep({
                    key = "j_egg",
                    set = "Joker",
                    kind = "joker",
                    rarity = 1,
                    output = "effect",
                    scaling = true,
                    loc = {
                        "Representative of a {C:attention}Common{}",
                        "effect-providing Joker that scales",
                    },
                }, joker)
            end
        end
    end)
end
