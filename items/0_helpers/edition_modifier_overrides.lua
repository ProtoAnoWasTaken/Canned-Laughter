local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.edition_modifiers = CL.edition_modifiers or {}
CL.config = CL.config or {}
CL.config.disable_edition_modifier_overrides = CL.config.disable_edition_modifier_overrides or false

local EM = CL.edition_modifiers

local STANDARD_EDITIONS = {
    e_base = true,
    e_foil = true,
    e_holo = true,
    e_polychrome = true,
}

EM.OVERRIDE_SELECTED_ARGS = {
    seed_key = "canlaugh_aura_override",
    include_standard = true,
    include_negative = false,
    include_glitter = false,
}

EM.OVERRIDE_WHEEL_ARGS = {
    probability_seed = "wheel_of_fortune",
    target_seed = "wheel_of_fortune",
    edition_args = {
        seed_key = "canlaugh_wheel_of_fortune_override",
        include_standard = true,
        include_negative = false,
        include_glitter = true,
        include_plastic = true,
    },
}

EM.NON_STANDARD_SELECTED_ARGS = {
    seed_key = "canlaugh_vibe_nonstandard",
    include_standard = false,
    include_negative = true,
    include_glitter = true,
    weighted_editions = {
        { key = "e_canlaugh_plastic", weight = 55 },
        { key = "e_canlaugh_glitter", weight = 25 },
        { key = "e_canlaugh_celestial", weight = 15 },
        { key = "e_negative", weight = 5 },
    },
}

EM.NON_STANDARD_WHEEL_ARGS = {
    probability_seed = "canlaugh_wheel_of_fate",
    target_seed = "canlaugh_wheel_of_fate",
    edition_args = {
        seed_key = "canlaugh_wheel_of_fate_edition",
        include_standard = false,
        include_negative = true,
        include_glitter = true,
        weighted_editions = {
            { key = "e_canlaugh_plastic", weight = 55 },
            { key = "e_canlaugh_glitter", weight = 25 },
            { key = "e_canlaugh_celestial", weight = 15 },
            { key = "e_negative", weight = 5 },
        },
    },
}

function EM.disable_overrides()
    return CL.config and CL.config.disable_edition_modifier_overrides
end

function EM.get_editions(args)
    local editions = {}
    local seen = {}
    local pool = {}

    args = args or {}

    if type(get_current_pool) == "function" then
        pool = get_current_pool("Edition", nil, nil, args.seed_key or "canlaugh_edition_pool") or {}
    elseif G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Edition then
        pool = G.P_CENTER_POOLS.Edition
    end

    for _, edition in ipairs(pool) do
        local key = type(edition) == "table" and edition.key or edition
        local center = key and G.P_CENTERS and G.P_CENTERS[key]

        if center
            and center.set == "Edition"
            and key ~= "UNAVAILABLE"
            and (args.include_negative or key ~= "e_negative")
            and (args.include_glitter or key ~= "e_canlaugh_glitter")
            and (args.include_plastic ~= false or key ~= "e_canlaugh_plastic")
            and (args.include_standard or not STANDARD_EDITIONS[key])
            and not (args.exclude_editions and args.exclude_editions[key])
            and not seen[key]
        then
            editions[#editions + 1] = key
            seen[key] = true
        end
    end

    if args.include_negative
        and G
        and G.P_CENTERS
        and G.P_CENTERS.e_negative
        and not seen.e_negative
    then
        editions[#editions + 1] = "e_negative"
    end

    return editions
end

function EM.poll_edition(args)
    local editions = EM.get_editions(args)
    local seed_key = (args and args.seed_key) or "canlaugh_edition_pool"
    local weighted_arg_editions = args and args.weighted_editions

    if #editions == 0 then
        return nil
    end

    if weighted_arg_editions then
        local available = {}
        local total_weight = 0
        local allowed = {}

        for _, edition_key in ipairs(editions) do
            allowed[edition_key] = true
        end

        for _, edition in ipairs(weighted_arg_editions) do
            if allowed[edition.key] and edition.weight and edition.weight > 0 then
                total_weight = total_weight + edition.weight
                available[#available + 1] = {
                    key = edition.key,
                    weight = edition.weight,
                }
            end
        end

        if total_weight <= 0 then
            return nil
        end

        local poll = pseudorandom(pseudoseed(seed_key)) * total_weight
        local weight_i = 0

        for _, edition in ipairs(available) do
            weight_i = weight_i + edition.weight

            if poll <= weight_i then
                return edition.key
            end
        end

        return available[#available].key
    end

    if SMODS and type(SMODS.poll_object) == "function" then
        return SMODS.poll_object({
            type = "Edition",
            seed = seed_key,
            guaranteed = true,
            pool = editions,
        })
    end

    local weighted_editions = {}
    local total_weight = 0

    for _, edition_key in ipairs(editions) do
        local center = G.P_CENTERS and G.P_CENTERS[edition_key]
        local weight = center and (center.weight or 10) or 10

        if center and type(center.get_weight) == "function" then
            weight = center:get_weight(weight, { seed = seed_key })
        end

        if weight and weight > 0 then
            total_weight = total_weight + weight
            weighted_editions[#weighted_editions + 1] = {
                key = edition_key,
                weight = weight,
            }
        end
    end

    if total_weight <= 0 then
        return nil
    end

    local poll = pseudorandom(pseudoseed(seed_key)) * total_weight
    local weight_i = 0

    for _, edition in ipairs(weighted_editions) do
        weight_i = weight_i + edition.weight

        if poll <= weight_i then
            return edition.key
        end
    end

    return weighted_editions[#weighted_editions].key
end

function EM.edition_args_for_target(args, target)
    local target_args = {}

    for key, value in pairs(args or {}) do
        target_args[key] = value
    end

    if EM.is_glitter_edition(target) then
        local exclude_editions = {}

        for key, value in pairs((args and args.exclude_editions) or {}) do
            exclude_editions[key] = value
        end

        exclude_editions.e_canlaugh_glitter = true
        target_args.exclude_editions = exclude_editions
    end

    return target_args
end

function EM.get_editions_for_target(args, target)
    return EM.get_editions(EM.edition_args_for_target(args, target))
end

function EM.poll_edition_for_target(args, target)
    return EM.poll_edition(EM.edition_args_for_target(args, target))
end

function EM.set_replacement_edition(target, edition)
    if EM.is_glitter_edition(target) and edition ~= "e_canlaugh_glitter" then
        target:set_edition(nil, true, true)
    end

    target:set_edition(edition, true)
end

function EM.selected_hand_card()
    local highlighted = G and G.hand and G.hand.highlighted

    if highlighted and #highlighted == 1 then
        return highlighted[1]
    end
end

function EM.can_use_selected_card_edition(args)
    local target = EM.selected_hand_card()

    return target ~= nil
        and (not target.edition or EM.is_glitter_edition(target))
        and #EM.get_editions_for_target(args, target) > 0
end

function EM.add_edition_info_queue(info_queue, args, card)
    if not info_queue then
        return
    end

    for _, edition_key in ipairs(EM.get_editions(args)) do
        if G.P_CENTERS[edition_key] then
            CL.add_unique_tooltip(info_queue, G.P_CENTERS[edition_key], card)
        end
    end
end

function EM.use_selected_card_edition(card, copier, args)
    local used_card = copier or card
    local target = EM.selected_hand_card()
    local edition = EM.poll_edition_for_target(args, target)

    if not (target and edition) then
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.4,
        func = function()
            EM.set_replacement_edition(target, edition)

            if G.P_CENTERS[edition] then
                discover_card(G.P_CENTERS[edition])
            end

            used_card:juice_up(0.3, 0.5)
            return true
        end,
    }))
end

function EM.is_glitter_edition(card)
    return card
        and card.edition
        and (card.edition.key == "e_canlaugh_glitter" or card.edition.canlaugh_glitter)
end

function EM.can_receive_joker_edition(card, args)
    return card
        and card.ability
        and card.ability.set == "Joker"
        and (not card.edition or EM.is_glitter_edition(card))
        and (not args or #EM.get_editions_for_target(args, card) > 0)
end

function EM.refresh_wheel_jokers(card, args)
    if not card then
        return {}
    end

    card.eligible_strength_jokers = EMPTY(card.eligible_strength_jokers or {})

    if G and G.jokers and G.jokers.cards then
        for _, joker in pairs(G.jokers.cards) do
            if EM.can_receive_joker_edition(joker, args) then
                card.eligible_strength_jokers[#card.eligible_strength_jokers + 1] = joker
            end
        end
    end

    return card.eligible_strength_jokers
end

function EM.refresh_editionless_jokers(card, args)
    if not card then
        return {}
    end

    card.eligible_editionless_jokers = EMPTY(card.eligible_editionless_jokers or {})

    if G and G.jokers and G.jokers.cards then
        for _, joker in pairs(G.jokers.cards) do
            if EM.can_receive_joker_edition(joker, args) then
                card.eligible_editionless_jokers[#card.eligible_editionless_jokers + 1] = joker
            end
        end
    end

    return card.eligible_editionless_jokers
end

function EM.refresh_edition_consumable_targets(card)
    local name = card and card.ability and card.ability.name

    if name == "The Wheel of Fortune" then
        EM.refresh_wheel_jokers(card, EM.OVERRIDE_WHEEL_ARGS.edition_args)
    elseif name == "Ectoplasm" or name == "Hex" then
        EM.refresh_editionless_jokers(card)
    end
end

function EM.can_use_wheel(card, edition_args)
    return next(EM.refresh_wheel_jokers(card, edition_args)) ~= nil
end

function EM.use_wheel_like(card, copier, args)
    stop_use()

    if not copier then
        set_consumeable_usage(card)
    end

    if card.debuff then
        return nil
    end

    local used_card = copier or card
    local target_pool = EM.refresh_wheel_jokers(card, args.edition_args)

    if not next(target_pool) then
        return
    end

    if not SMODS.pseudorandom_probability(card, args.probability_seed, 1, card.ability.extra) then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.4,
            func = function()
                attention_text({
                    text = localize("k_nope_ex"),
                    scale = 1.3,
                    hold = 1.4,
                    major = used_card,
                    backdrop_colour = G.C.SECONDARY_SET.Tarot,
                    align = "cm",
                    offset = { x = 0, y = -0.2 },
                    silent = true,
                })
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.06 * G.SETTINGS.GAMESPEED,
                    blockable = false,
                    blocking = false,
                    func = function()
                        play_sound("tarot2", 0.76, 0.4)
                        return true
                    end,
                }))
                play_sound("tarot2", 1, 0.4)
                used_card:juice_up(0.3, 0.5)
                return true
            end,
        }))
        delay(0.6)
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.4,
        func = function()
            local target = pseudorandom_element(target_pool, pseudoseed(args.target_seed))
            local edition = EM.poll_edition_for_target(args.edition_args, target)

            if not (target and edition) then
                return true
            end

            EM.set_replacement_edition(target, edition)

            if G.P_CENTERS[edition] then
                discover_card(G.P_CENTERS[edition])
            end

            check_for_unlock({ type = "have_edition" })
            used_card:juice_up(0.3, 0.5)
            return true
        end,
    }))

    delay(0.3)
end

function EM.use_ectoplasm(card, copier)
    stop_use()

    if not copier then
        set_consumeable_usage(card)
    end

    if card.debuff then
        return nil
    end

    local used_card = copier or card
    local target_pool = EM.refresh_editionless_jokers(card)
    local glitter_pool = {}

    for _, target in ipairs(target_pool) do
        if EM.is_glitter_edition(target) then
            glitter_pool[#glitter_pool + 1] = target
        end
    end

    if next(glitter_pool) then
        target_pool = glitter_pool
    end

    if not next(target_pool) then
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.4,
        func = function()
            local target = pseudorandom_element(target_pool, pseudoseed("ectoplasm"))

            if not target then
                return true
            end

            EM.set_replacement_edition(target, "e_negative")

            if G.P_CENTERS.e_negative then
                discover_card(G.P_CENTERS.e_negative)
            end

            check_for_unlock({ type = "have_edition" })
            G.GAME.ecto_minus = G.GAME.ecto_minus or 1
            G.hand:change_size(-G.GAME.ecto_minus)
            G.GAME.ecto_minus = G.GAME.ecto_minus + 1
            used_card:juice_up(0.3, 0.5)
            return true
        end,
    }))

    delay(0.3)
end

function EM.use_hex(card, copier)
    stop_use()

    if not copier then
        set_consumeable_usage(card)
    end

    if card.debuff then
        return nil
    end

    local used_card = copier or card
    local target_pool = EM.refresh_editionless_jokers(card)
    local glitter_pool = {}

    for _, target in ipairs(target_pool) do
        if EM.is_glitter_edition(target) then
            glitter_pool[#glitter_pool + 1] = target
        end
    end

    if next(glitter_pool) then
        target_pool = glitter_pool
    end

    if not next(target_pool) then
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.4,
        func = function()
            local target = pseudorandom_element(target_pool, pseudoseed("hex"))

            if not target then
                return true
            end

            EM.set_replacement_edition(target, "e_polychrome")

            if G.P_CENTERS.e_polychrome then
                discover_card(G.P_CENTERS.e_polychrome)
            end

            check_for_unlock({ type = "have_edition" })

            local first_dissolve = nil

            for _, joker in pairs(G.jokers.cards) do
                if joker ~= target and not SMODS.is_eternal(joker, card) then
                    joker.getting_sliced = true
                    joker:start_dissolve(nil, first_dissolve)
                    first_dissolve = true
                end
            end

            used_card:juice_up(0.3, 0.5)
            return true
        end,
    }))

    delay(0.3)
end

local function set_description(set, key, text)
    if G.localization
        and G.localization.descriptions
        and G.localization.descriptions[set]
        and G.localization.descriptions[set][key]
    then
        G.localization.descriptions[set][key].text = text
    end
end

function EM.configure_aura_and_wheel()
    if EM.disable_overrides() then
        return
    end

    local aura = G and G.P_CENTERS and G.P_CENTERS.c_aura
    local wheel = G and G.P_CENTERS and G.P_CENTERS.c_wheel_of_fortune
    local aura_text = {
        "Applies any",
        "{C:dark_edition}non-Negative{} edition",
        "to {C:attention}1{} selected card",
    }
    local wheel_text = {
        "{C:green}#1# in #2#{} chance to add",
        "any {C:dark_edition}non-Negative{} edition",
        "to a random {C:attention}Joker{}",
    }

    if aura then
        aura.config = aura.config or {}
        aura.config.max_highlighted = 1
        aura.config.mod_num = 1
        aura.config.min_highlighted = 1
        aura.loc_txt = aura.loc_txt or {}
        aura.loc_txt.text = aura_text
        aura.loc_vars = function(self, info_queue, card)
            EM.add_edition_info_queue(info_queue, EM.OVERRIDE_SELECTED_ARGS, card)
            return { vars = {} }
        end
    end

    if wheel then
        wheel.loc_txt = wheel.loc_txt or {}
        wheel.loc_txt.text = wheel_text
        wheel.loc_vars = function(self, info_queue, card)
            EM.add_edition_info_queue(info_queue, EM.OVERRIDE_WHEEL_ARGS.edition_args, card)
            return {
                vars = {
                    SMODS.get_probability_vars(
                        card,
                        1,
                        (card and card.ability and card.ability.extra) or self.config.extra,
                        "wheel_of_fortune"
                    ),
                },
            }
        end
    end

    set_description("Spectral", "c_aura", aura_text)
    set_description("Tarot", "c_wheel_of_fortune", wheel_text)
end

if Card and type(Card.can_use_consumeable) == "function" and not CL.edition_modifier_can_use_hook_installed then
    CL.edition_modifier_can_use_hook_installed = true
    local can_use_consumeable_ref = Card.can_use_consumeable

    function Card:can_use_consumeable(any_state, skip_check, ...)
        EM.refresh_edition_consumable_targets(self)

        if not EM.disable_overrides()
            and self.ability
            and (self.ability.name == "Aura" or self.ability.name == "The Wheel of Fortune")
        then
            if not skip_check and ((G.play and #G.play.cards > 0)
                or G.CONTROLLER.locked
                or (G.GAME.STOP_USE and G.GAME.STOP_USE > 0))
            then
                return false
            end

            if (G.STATE ~= G.STATES.HAND_PLAYED
                and G.STATE ~= G.STATES.DRAW_TO_HAND
                and G.STATE ~= G.STATES.PLAY_TAROT)
                or any_state
            then
                if self.ability.name == "Aura" then
                    return EM.can_use_selected_card_edition(EM.OVERRIDE_SELECTED_ARGS)
                end

                if self.ability.name == "The Wheel of Fortune" then
                    return EM.can_use_wheel(self, EM.OVERRIDE_WHEEL_ARGS.edition_args)
                end
            end

            return false
        end

        return can_use_consumeable_ref(self, any_state, skip_check, ...)
    end
end

if Card and type(Card.set_ability) == "function" and not CL.edition_modifier_set_ability_hook_installed then
    CL.edition_modifier_set_ability_hook_installed = true
    local set_ability_ref = Card.set_ability

    function Card:set_ability(...)
        local results = { set_ability_ref(self, ...) }
        EM.refresh_edition_consumable_targets(self)
        return unpack(results)
    end
end

if Card and type(Card.use_consumeable) == "function" and not CL.edition_modifier_use_hook_installed then
    CL.edition_modifier_use_hook_installed = true
    local use_consumeable_ref = Card.use_consumeable

    function Card:use_consumeable(area, copier, ...)
        EM.refresh_edition_consumable_targets(self)

        if not EM.disable_overrides() and self.ability and self.ability.name == "Aura"
            and EM.can_use_selected_card_edition(EM.OVERRIDE_SELECTED_ARGS)
        then
            stop_use()
            if not copier then
                set_consumeable_usage(self)
            end
            if self.debuff then
                return nil
            end
            EM.use_selected_card_edition(self, copier, EM.OVERRIDE_SELECTED_ARGS)
            delay(0.3)
            return
        end

        if not EM.disable_overrides()
            and self.ability
            and self.ability.name == "The Wheel of Fortune"
            and EM.can_use_wheel(self, EM.OVERRIDE_WHEEL_ARGS.edition_args)
        then
            return EM.use_wheel_like(self, copier, EM.OVERRIDE_WHEEL_ARGS)
        end

        if not EM.disable_overrides()
            and self.ability
            and self.ability.name == "Ectoplasm"
            and next(EM.refresh_editionless_jokers(self))
        then
            return EM.use_ectoplasm(self, copier)
        end

        if not EM.disable_overrides()
            and self.ability
            and self.ability.name == "Hex"
            and next(EM.refresh_editionless_jokers(self))
        then
            return EM.use_hex(self, copier)
        end

        return use_consumeable_ref(self, area, copier, ...)
    end
end

SMODS.current_mod.config_tab = function()
    return {
        n = G.UIT.ROOT,
        config = { align = "cm", padding = 0.05, colour = G.C.CLEAR },
        nodes = {
            {
                n = G.UIT.C,
                config = { align = "cm", padding = 0.1 },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = { align = "cm", padding = 0.02 },
                        nodes = {
                            create_toggle({
                                label = "Disable edition-modifier overrides",
                                ref_table = CL.config,
                                ref_value = "disable_edition_modifier_overrides",
                            }),
                        },
                    },
                },
            },
        },
    }
end

SMODS.Atlas({
    key = "vibe",
    path = "vibe.png",
    px = 71,
    py = 95,
})

SMODS.Atlas({
    key = "wheel_of_fate",
    path = "wheel_of_fate.png",
    px = 71,
    py = 95,
})

EM.configure_aura_and_wheel()
