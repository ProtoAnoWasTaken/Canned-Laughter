local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "chulareh_back",
    path = "chulareh_back.png",
    px = 69,
    py = 93,
})

if CannedLaughter.barter then
    CannedLaughter.barter.register_special_rep("Arcana", "c_wheel_of_fortune", {
        key = "c_wheel_of_fortune", set = "Tarot", kind = "trial_wild", trial_booster_kind = "Arcana",
        loc = { "Representative of any", "{C:attention}Arcane Trial{}" },
    })
    CannedLaughter.barter.register_rep_modifier("chula_reh", function(phase, context)
        if phase == "availability" and context.booster_kind == "Arcana" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_chula_reh") or {}); return
        end
        if phase == "hand" and context.booster_kind == "Arcana" then
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_chula_reh") or {}) do
                CannedLaughter.barter.add_rep({
                    key = "c_wheel_of_fortune",
                    set = "Tarot",
                    kind = "trial_wild",
                    trial_booster_kind = "Arcana",
                    loc = {
                        "Representative of any",
                        "{C:attention}Arcane Trial{}",
                    },
                }, joker)
            end
        end
    end)
end

SMODS.Atlas({
    key = "chulareh_front",
    path = "chulareh_joker.png",
    px = 69,
    py = 93,
})

local function canlaugh_chula_reh_jokers()
    local cards = {}

    if not (G and G.jokers and G.jokers.cards) then
        return cards
    end

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center

        if center and center.key == "j_canlaugh_chula_reh" then
            cards[#cards + 1] = joker
        end
    end

    return cards
end

local function canlaugh_chula_reh_find_owner(sort_id)
    if not (G and G.jokers and G.jokers.cards) then
        return nil
    end

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center

        if center
            and center.key == "j_canlaugh_chula_reh"
            and (sort_id == nil or joker.sort_id == sort_id)
        then
            return joker
        end
    end

    return nil
end

local function canlaugh_chula_reh_base_denominator(card)
    local extra = card and card.ability and card.ability.extra
    return (extra and extra.wheel_denominator) or 4
end

local function canlaugh_chula_reh_wheel_of_fate_enabled()
    local center = G and G.P_CENTERS and G.P_CENTERS.c_canlaugh_wheel_of_fate
    local EM = CL.edition_modifiers

    return center
        and EM
        and type(EM.disable_overrides) == "function"
        and EM.disable_overrides()
end

local function canlaugh_chula_reh_wheel_pool()
    local wheels = { "c_wheel_of_fortune" }

    if canlaugh_chula_reh_wheel_of_fate_enabled() then
        wheels[#wheels + 1] = "c_canlaugh_wheel_of_fate"
    end

    return wheels
end

local function canlaugh_chula_reh_pick_wheel(card, index)
    local wheels = canlaugh_chula_reh_wheel_pool()

    if #wheels <= 1 then
        return wheels[1]
    end

    return pseudorandom_element(
        wheels,
        pseudoseed("canlaugh_chula_reh_wheel_" .. tostring(card and card.sort_id or "") .. "_" .. tostring(index or 1))
    )
end

local function canlaugh_chula_reh_next_denominator(card)
    local extra = card and card.ability and card.ability.extra
    local base = canlaugh_chula_reh_base_denominator(card)

    if not extra then
        return base
    end

    extra.next_wheel_denominator = math.max(
        extra.min_denominator or 1,
        extra.next_wheel_denominator or base
    )

    return extra.next_wheel_denominator
end

local function canlaugh_chula_reh_mark_failure(owner)
    if not (owner and owner.ability and owner.ability.extra) then
        return
    end

    local extra = owner.ability.extra
    local current = canlaugh_chula_reh_next_denominator(owner)

    extra.next_wheel_denominator = math.max(extra.min_denominator or 1, current - 1)

    if type(card_eval_status_text) == "function" then
        card_eval_status_text(owner, "extra", nil, nil, nil, {
            message = "Chance Up!",
            colour = G.C.GREEN,
        })
    end
end

local function canlaugh_chula_reh_mark_success(owner)
    if not (owner and owner.ability and owner.ability.extra) then
        return
    end

    owner.ability.extra.next_wheel_denominator = canlaugh_chula_reh_base_denominator(owner)
end

local function canlaugh_chula_reh_create_wheel(card, index)
    if not (G and G.GAME and G.E_MANAGER and G.consumeables and type(create_card) == "function") then
        return
    end

    local denominator = canlaugh_chula_reh_next_denominator(card)
    G.GAME.canlaugh_chula_reh_wheel_seed_count = (G.GAME.canlaugh_chula_reh_wheel_seed_count or 0) + 1
    local seed_index = G.GAME.canlaugh_chula_reh_wheel_seed_count
    local wheel_key = canlaugh_chula_reh_pick_wheel(card, seed_index)

    G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
    G.E_MANAGER:add_event(Event({
        trigger = "before",
        delay = 0.0,
        func = function()
            local wheel = create_card(
                "Tarot",
                G.consumeables,
                nil,
                nil,
                nil,
                nil,
                wheel_key,
                "canlaugh_chula_reh" .. tostring(seed_index)
            )

            wheel.ability.extra = denominator
            wheel.canlaugh_chula_reh_wheel = true
            wheel.canlaugh_chula_reh_owner_sort_id = card and card.sort_id
            wheel:add_to_deck()
            wheel:set_edition({ negative = true }, true, true)
            G.consumeables:emplace(wheel)
            G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 1) - 1)
            return true
        end,
    }))
end

function CL.apply_chula_reh_money(amount)
    if not (G and G.GAME and amount and amount > 0) then
        return
    end

    for _, joker in ipairs(canlaugh_chula_reh_jokers()) do
        local extra = joker.ability and joker.ability.extra

        if extra then
            local dollars = extra.dollars or 9
            extra.money_buffer = (extra.money_buffer or 0) + amount

            local wheel_count = math.floor(extra.money_buffer / dollars)
            extra.money_buffer = extra.money_buffer - (wheel_count * dollars)

            if wheel_count > 0 then
                for i = 1, wheel_count do
                    canlaugh_chula_reh_create_wheel(joker, i)
                end

                if type(card_eval_status_text) == "function" then
                    card_eval_status_text(joker, "extra", nil, nil, nil, {
                        message = localize("k_plus_tarot"),
                        colour = G.C.PURPLE,
                    })
                end
            end
        end
    end
end

if SMODS and type(SMODS.pseudorandom_probability) == "function" and not CL.chula_reh_probability_hook_installed then
    CL.chula_reh_probability_hook_installed = true
    local canlaugh_chula_reh_probability_ref = SMODS.pseudorandom_probability

    function SMODS.pseudorandom_probability(card, seed, numerator, denominator, ...)
        local results = { canlaugh_chula_reh_probability_ref(card, seed, numerator, denominator, ...) }

        if card
            and card.canlaugh_chula_reh_wheel
            and tostring(seed or ""):find("wheel")
        then
            local owner = canlaugh_chula_reh_find_owner(card.canlaugh_chula_reh_owner_sort_id)

            if results[1] == false then
                canlaugh_chula_reh_mark_failure(owner)
            elseif results[1] == true then
                canlaugh_chula_reh_mark_success(owner)
            end
        end

        return unpack(results)
    end
end

SMODS.Joker({
    key = "chula_reh",
    name = "Chula-Reh",
    atlas = "chulareh_back",
    soul_atlas = "chulareh_front",
    pos = { x = 0, y = 0 },
    soul_pos = { x = 0, y = 0 },
    rarity = 4,
    cost = 20,
    unlocked = false,
    unlock_condition = {
        type = "",
        extra = "",
        hidden = true,
    },
    config = {
        extra = {
            dollars = 9,
            wheel_denominator = 4,
            next_wheel_denominator = 4,
            min_denominator = 1,
            money_buffer = 0,
        },
    },
    loc_txt = {
        name = "Chula-Reh",
        text = {
            "Create {C:dark_edition}Negative{}",
            "{C:tarot}Wheels{} for every",
            "{C:money}$#1#{} you gain",
            "Failure raises the next",
            "created Wheel's chance by {C:attention}1{}",
            "{C:inactive}(Next Wheel: {C:green}#2# in #3#{C:inactive}){}",
        },
        unlock = {
            "{C:inactive,s:1.3}??????{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra

        CannedLaughter.add_unique_tooltip(info_queue, {
            key = "canlaugh_card_artist",
            set = "Other",
            vars = { "Faowbot" },
        }, card)

        local numerator, denominator = SMODS.get_probability_vars(
            card,
            1,
            extra.next_wheel_denominator or extra.wheel_denominator,
            "canlaugh_chula_reh"
        )

        return {
            vars = {
                extra.dollars,
                numerator,
                denominator,
            },
        }
    end,
    locked_loc_vars = function(self, info_queue, card)
        if not (G and G.P_CENTERS and G.P_CENTERS.c_soul and G.P_CENTERS.c_soul.discovered) then
            return {
                not_hidden = true,
                vars = {},
            }
        end

        return {
            key = "joker_locked_legendary",
            set = "Other",
            vars = {},
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
})
