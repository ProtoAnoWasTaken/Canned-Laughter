local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.challenge_keys = {
    attrition = "c_canlaugh_attrition",
    bananarama = "c_canlaugh_bananarama",
    gift_exchange = "c_canlaugh_gift_exchange",
    illegal_deck = "c_canlaugh_illegal_deck",
    scorched_earth = "c_canlaugh_scorched_earth",
    total_war = "c_canlaugh_total_war",
    glitter_glue = "c_canlaugh_glitter_glue",
    guessing_game = "c_canlaugh_guessing_game",
    rg_department = "c_canlaugh_rg_department",
    attack_of_the_fifty_foot_jester = "c_canlaugh_attack_of_the_fifty_foot_jester",
    that_one_part_of_the_jrpg = "c_canlaugh_that_one_part_of_the_jrpg",
    shiny_metal_joker = "c_canlaugh_shiny_metal_joker",
    rejected_humanity = "c_canlaugh_rejected_humanity",
    spirited_away = "c_canlaugh_spirited_away",
    burning_up = "c_canlaugh_burning_up",
    jens_mod = "c_canlaugh_jens_mod",
    double_reacharound = "c_canlaugh_double_reacharound",
    confounded = "c_canlaugh_confounded",
    slay_the_showdown = "c_canlaugh_slay_the_showdown",
}

function CL.challenge_active(key)
    return G and G.GAME and G.GAME.challenge == CL.challenge_keys[key]
end

function CL.resourceful_component_denominator()
    if CL.challenge_active("rg_department") or CL.challenge_active("double_reacharound") then
        return 50 / 3
    end

    return 50
end

function CL.challenge_banned_cards(keys)
    local cards = {}

    for _, key in ipairs(keys or {}) do
        if G and G.P_CENTERS and G.P_CENTERS[key] then
            cards[#cards + 1] = { id = key }
        end
    end

    return cards
end

local function challenge_is_legendary_joker(center)
    local rarity = center and center.rarity

    return center
        and center.set == "Joker"
        and (rarity == 4 or rarity == "Legendary" or rarity == "legendary")
end

function CL.spirited_away_banned_cards()
    local cards = {}

    for key, center in pairs(G and G.P_CENTERS or {}) do
        local tarot_joker = key == "j_vagabond"
            or key == "j_fortune_teller"
            or key == "j_cartomancer"
            or key == "j_hallucination"
            or key == "j_canlaugh_chula_reh"
            or key == "j_canlaugh_hail_from_the_future"
            or key == "j_canlaugh_rules_card"
            or key == "j_canlaugh_spirit_world"
        local allowed = center.set == "Tarot"
            or tarot_joker
            or challenge_is_legendary_joker(center)
            or (center.set == "Booster" and (center.kind == "Arcana" or center.kind == "Standard"))
        local restricted = center.set == "Joker"
            or center.set == "Booster"
            or center.consumeable

        if restricted and not allowed then
            cards[#cards + 1] = { id = key }
        end
    end

    table.sort(cards, function(a, b)
        return a.id < b.id
    end)

    return cards
end

function CL.apply_spirited_away_bans()
    if not (G and G.GAME) then
        return
    end

    G.GAME.banned_keys = G.GAME.banned_keys or {}
    for _, card in ipairs(CL.spirited_away_banned_cards()) do
        G.GAME.banned_keys[card.id] = true
    end
end

function CL.challenge_win_run()
    if not (G and G.GAME) then
        return
    end

    G.GAME.canlaugh_double_reacharound_endless = true
    if type(win_game) == "function" then
        win_game()
    end
    G.GAME.won = true
end

function CL.force_challenge_boss(key)
    if not (G and G.GAME and G.GAME.round_resets) then
        return
    end

    G.GAME.round_resets.blind_choices = G.GAME.round_resets.blind_choices or {}
    G.GAME.round_resets.blind_choices.Boss = key
end

function CL.pick_attrition_boss(showdown, seed)
    local candidates = {}

    for key, blind in pairs(G.P_BLINDS or {}) do
        local allowed = true
        if type(blind.in_pool) == "function" then
            allowed = blind:in_pool()
        end

        if blind.boss
            and (blind.boss.showdown and true or false) == showdown
            and allowed
            and not G.GAME.banned_keys[key]
        then
            candidates[#candidates + 1] = key
        end
    end

    table.sort(candidates)

    if #candidates == 0 then
        return nil
    end

    local key = pseudorandom_element(candidates, pseudoseed(seed))
    G.GAME.bosses_used[key] = (G.GAME.bosses_used[key] or 0) + 1
    return key
end

function CL.set_attrition_blind_choices()
    if not CL.challenge_active("attrition") then
        return
    end

    local choices = G.GAME.round_resets and G.GAME.round_resets.blind_choices
    if not choices then
        return
    end

    local ante = G.GAME.round_resets.ante or 0
    if ante <= 4 then
        return
    end

    choices.Big = CL.pick_attrition_boss(false, "canlaugh_attrition_big_" .. tostring(ante))
        or choices.Big
    choices.Boss = CL.pick_attrition_boss(true, "canlaugh_attrition_showdown_" .. tostring(ante))
        or choices.Boss
end

local function is_playing_card(card)
    return card and card.playing_card
end

local function has_enhancement(card)
    local center = card and card.config and card.config.center
    local effect = card and card.ability and card.ability.effect
    local edition = card and card.edition
    local seal = card and card.seal

    return center and center.set == "Enhanced"
        or effect and effect ~= "Base"
        or edition and next(edition) ~= nil
        or seal ~= nil
end

local function glitter_edition(edition)
    if type(edition) == "string" then
        return edition == "e_canlaugh_glitter"
    end

    return type(edition) == "table"
        and (edition.key == "e_canlaugh_glitter" or edition.canlaugh_glitter)
end

local function card_is_glitter(card)
    return card
        and card.edition
        and (card.edition.key == "e_canlaugh_glitter" or card.edition.canlaugh_glitter)
end

local function active_glitter_glue()
    return CL.challenge_active("glitter_glue")
end

local function challenge_playing_card_type(card_type, card, area)
    return card_type == "Base"
        or card_type == "Enhanced"
        or card_type == "Playing Card"
        or (card and card.playing_card)
        or (card and area == G.pack_cards and card.config and card.config.center
            and (card.config.center.set == "Default" or card.config.center.set == "Enhanced"))
end

local function challenge_random_seal(seed)
    local seals = { "Gold", "Red", "Blue", "Purple" }
    return CL.big_blind_random(seals, seed) or "Gold"
end

local function challenge_make_plastic_and_sealed(card, seed)
    if not card then
        return
    end

    if type(card.set_edition) == "function" then
        card:set_edition("e_canlaugh_plastic", true, true)
    end

    if type(card.set_seal) == "function" then
        card:set_seal(challenge_random_seal(seed), true, true)
    end
end

local function challenge_apply_created_card(card, card_type, area)
    if not card then
        return
    end

    local playing_card = challenge_playing_card_type(card_type, card, area)
    if CL.challenge_active("shiny_metal_joker") and playing_card then
        card:set_ability(G.P_CENTERS.m_steel, nil, true)
    elseif CL.challenge_active("burning_up") and playing_card then
        card:set_ability(G.P_CENTERS.m_canlaugh_blazing, nil, true)
    end

    local center = card.config and card.config.center
    if CL.challenge_active("jens_mod") and (playing_card or (center and center.set == "Joker")) then
        challenge_make_plastic_and_sealed(card, "canlaugh_jens_mod_" .. tostring(card.sort_id or 0))
    end
end

function CL.apply_challenge_starting_deck()
    for _, card in ipairs(G and G.playing_cards or {}) do
        if CL.challenge_active("shiny_metal_joker") then
            card:set_ability(G.P_CENTERS.m_steel, nil, true)
        elseif CL.challenge_active("burning_up") then
            card:set_ability(G.P_CENTERS.m_canlaugh_blazing, nil, true)
        elseif CL.challenge_active("jens_mod") then
            challenge_make_plastic_and_sealed(card, "canlaugh_jens_mod_start_" .. tostring(card.sort_id or 0))
        end
    end
end

local function challenge_is_tarot_joker(center)
    local tarot_jokers = {
        j_vagabond = true,
        j_fortune_teller = true,
        j_cartomancer = true,
        j_hallucination = true,
        j_canlaugh_chula_reh = true,
        j_canlaugh_hail_from_the_future = true,
        j_canlaugh_rules_card = true,
        j_canlaugh_spirit_world = true,
    }

    return center and tarot_jokers[center.key]
end

local function challenge_spirited_pool(pool, pool_type, legendary)
    if not CL.challenge_active("spirited_away") then
        return pool
    end

    if pool_type ~= "Joker" then
        return pool
    end

    if pool_type == "Joker" and legendary and G.GAME.canlaugh_spirited_stanczyk_pending then
        G.GAME.canlaugh_spirited_stanczyk_pending = nil
        return { "j_canlaugh_stanczyk" }
    end

    if legendary then
        return pool
    end

    local allowed = {}
    for _, key in ipairs(pool or {}) do
        local center = G.P_CENTERS and G.P_CENTERS[key]
        local is_allowed = center and (
            center.set == "Tarot"
            or challenge_is_tarot_joker(center)
            or (center.set == "Booster" and (center.kind == "Arcana" or center.kind == "Standard"))
        )
        if is_allowed then
            allowed[#allowed + 1] = key
        end
    end

    if #allowed == 0 then
        allowed[1] = "j_canlaugh_spirit_world"
    end

    return allowed
end

if type(get_new_boss) == "function" and not CL.challenge_boss_hook_installed then
    CL.challenge_boss_hook_installed = true
    local get_new_boss_ref = get_new_boss

    function get_new_boss(...)
        if CL.challenge_active("attrition") then
            local ante = G.GAME.round_resets and G.GAME.round_resets.ante or 0
            if ante > 4 then
                local key = CL.pick_attrition_boss(true, "canlaugh_attrition_showdown_" .. tostring(ante))
                if key then
                    return key
                end
            end
        end

        return get_new_boss_ref(...)
    end
end

if type(get_current_pool) == "function" and not CL.challenge_spirited_pool_hook_installed then
    CL.challenge_spirited_pool_hook_installed = true
    local get_current_pool_ref = get_current_pool

    function get_current_pool(pool_type, rarity, legendary, append)
        local pool, pool_key = get_current_pool_ref(pool_type, rarity, legendary, append)
        return challenge_spirited_pool(pool, pool_type, legendary), pool_key
    end
end

if type(get_pack) == "function" and not CL.challenge_spirited_pack_hook_installed then
    CL.challenge_spirited_pack_hook_installed = true
    local get_pack_ref = get_pack

    function get_pack(key, pack_type)
        local pack = get_pack_ref(key, pack_type)
        if not CL.challenge_active("spirited_away") then
            return pack
        end

        local kind = pack and pack.kind
        if kind == "Arcana" or kind == "Standard" then
            return pack
        end

        local packs = {}
        for _, candidate in ipairs(G.P_CENTER_POOLS.Booster or {}) do
            if (candidate.kind == "Arcana" or candidate.kind == "Standard")
                and not G.GAME.banned_keys[candidate.key]
            then
                packs[#packs + 1] = candidate
            end
        end

        return CL.big_blind_random(packs, "canlaugh_spirited_pack_" .. tostring(key or "")) or pack
    end
end

if type(reset_blinds) == "function" and not CL.attrition_blind_reset_hook_installed then
    CL.attrition_blind_reset_hook_installed = true
    local reset_blinds_ref = reset_blinds

    function reset_blinds(...)
        local results = { reset_blinds_ref(...) }
        CL.set_attrition_blind_choices()
        return unpack(results)
    end
end

if Blind and type(Blind.set_blind) == "function" and not CL.challenge_boss_history_hook_installed then
    CL.challenge_boss_history_hook_installed = true
    local set_blind_ref = Blind.set_blind

    function Blind:set_blind(blind, reset, silent)
        local result = set_blind_ref(self, blind, reset, silent)
        local center = self.config and self.config.blind

        if not reset and blind and center and center.boss and self.chips then
            local multiplier = 1
            if CL.challenge_active("rejected_humanity") then
                multiplier = 1.25
            elseif CL.challenge_active("slay_the_showdown") and center.boss.showdown then
                multiplier = 2
            end

            if multiplier ~= 1 then
                self.chips = self.chips * multiplier
                self.chip_text = number_format(self.chips)
            end
        end

        if not reset and blind and center and center.boss and center.key ~= "bl_canlaugh_earthsea_borealis" then
            G.GAME.canlaugh_boss_history = G.GAME.canlaugh_boss_history or {}
            local history = G.GAME.canlaugh_boss_history
            history[#history + 1] = center.key

            while #history > 6 do
                table.remove(history, 1)
            end
        end

        return result
    end
end

if Card and type(Card.set_edition) == "function" and not CL.challenge_glitter_edition_hook_installed then
    CL.challenge_glitter_edition_hook_installed = true
    local set_edition_ref = Card.set_edition

    function Card:set_edition(edition, immediate, silent, ...)
        local center = self and self.config and self.config.center
        if CL.challenge_active("jens_mod")
            and (is_playing_card(self) or (center and center.set == "Joker"))
            and edition ~= "e_canlaugh_plastic"
        then
            edition = "e_canlaugh_plastic"
        end

        if active_glitter_glue() and is_playing_card(self) and card_is_glitter(self) and not glitter_edition(edition) then
            return
        end

        local results = { set_edition_ref(self, edition, immediate, silent, ...) }

        if CL.challenge_active("illegal_deck") and is_playing_card(self) then
            self:set_debuff(not has_enhancement(self))
        end

        return unpack(results)
    end
end

if Card and type(Card.set_seal) == "function" and not CL.challenge_illegal_deck_seal_hook_installed then
    CL.challenge_illegal_deck_seal_hook_installed = true
    local set_seal_ref = Card.set_seal

    function Card:set_seal(seal, silent, immediate, ...)
        local center = self and self.config and self.config.center
        if CL.challenge_active("jens_mod")
            and (is_playing_card(self) or (center and center.set == "Joker"))
            and not seal
        then
            seal = challenge_random_seal("canlaugh_jens_mod_reseal_" .. tostring(self.sort_id or 0))
        end

        local results = { set_seal_ref(self, seal, silent, immediate, ...) }

        if CL.challenge_active("illegal_deck") and is_playing_card(self) then
            self:set_debuff(not has_enhancement(self))
        end

        return unpack(results)
    end
end

if type(create_card) == "function" and not CL.challenge_glitter_create_card_hook_installed then
    CL.challenge_glitter_create_card_hook_installed = true
    local create_card_ref = create_card

    function create_card(card_type, area, ...)
        local results = { create_card_ref(card_type, area, ...) }
        local card = results[1]
        local playing_card_type = challenge_playing_card_type(card_type, card, area)

        if CL.challenge_active("spirited_away")
            and card_type == "Joker"
            and select(1, ...)
            and G.GAME.canlaugh_spirited_stanczyk_pending
            and card
        then
            card:set_ability(G.P_CENTERS.j_canlaugh_stanczyk, nil, true)
            G.GAME.canlaugh_spirited_stanczyk_pending = nil
        end

        if active_glitter_glue()
            and card
            and (playing_card_type or area == G.pack_cards)
            and type(card.set_edition) == "function"
        then
            card:set_edition("e_canlaugh_glitter", true, true)
        end

        if CL.challenge_active("spirited_away") and card_type == "Tarot" and area == G.pack_cards then
            local center = card.config and card.config.center
            local first_soul = not G.GAME.canlaugh_spirited_first_soul_seen
            local should_create_soul = first_soul
                and center
                and center.key ~= "c_soul"
                and pseudorandom(pseudoseed("canlaugh_spirited_soul_" .. tostring(card.sort_id or 0))) < 0.01

            if should_create_soul then
                card:set_ability(G.P_CENTERS.c_soul, nil, true)
                center = card.config and card.config.center
            end

            if first_soul and center and center.key == "c_soul" then
                G.GAME.canlaugh_spirited_first_soul_seen = true
                G.GAME.canlaugh_spirited_stanczyk_pending = true
            end
        end

        challenge_apply_created_card(card, card_type, area)

        return unpack(results)
    end
end

if type(create_playing_card) == "function" and not CL.challenge_material_create_playing_card_hook_installed then
    CL.challenge_material_create_playing_card_hook_installed = true
    local create_playing_card_ref = create_playing_card

    function create_playing_card(args, area, ...)
        local card = create_playing_card_ref(args, area, ...)
        challenge_apply_created_card(card, "Playing Card", area)
        return card
    end
end

if Game and type(Game.start_run) == "function" and not CL.challenge_material_start_hook_installed then
    CL.challenge_material_start_hook_installed = true
    local start_run_ref = Game.start_run

    function Game:start_run(args, ...)
        local results = { start_run_ref(self, args, ...) }

        if not (args and args.savetext) then
            CL.apply_challenge_starting_deck()
        end

        return unpack(results)
    end
end

if Card and type(Card.set_ability) == "function" and not CL.challenge_material_set_ability_hook_installed then
    CL.challenge_material_set_ability_hook_installed = true
    local set_ability_ref = Card.set_ability

    function Card:set_ability(center, initial, delay_sprites, ...)
        if is_playing_card(self) and CL.challenge_active("shiny_metal_joker") then
            center = G.P_CENTERS.m_steel
        elseif is_playing_card(self) and CL.challenge_active("burning_up") then
            center = G.P_CENTERS.m_canlaugh_blazing
        end

        return set_ability_ref(self, center, initial, delay_sprites, ...)
    end
end

if SMODS and SMODS.current_mod and not CL.challenge_illegal_deck_hook_installed then
    CL.challenge_illegal_deck_hook_installed = true
    local mod = SMODS.current_mod
    local set_debuff_ref = mod.set_debuff

    mod.set_debuff = function(card)
        local result = set_debuff_ref and set_debuff_ref(card)
        if result == "prevent_debuff" then
            return result
        end

        if CL.challenge_active("illegal_deck") and is_playing_card(card) and not has_enhancement(card) then
            return true
        end

        return result
    end
end

if Card and type(Card.add_to_deck) == "function" and not CL.challenge_illegal_deck_add_hook_installed then
    CL.challenge_illegal_deck_add_hook_installed = true
    local add_to_deck_ref = Card.add_to_deck

    function Card:add_to_deck(from_debuff, ...)
        local results = { add_to_deck_ref(self, from_debuff, ...) }

        if CL.challenge_active("illegal_deck") and is_playing_card(self) and not has_enhancement(self) then
            self:set_debuff(true)
        end

        return unpack(results)
    end
end

if Card and type(Card.set_ability) == "function" and not CL.challenge_illegal_deck_ability_hook_installed then
    CL.challenge_illegal_deck_ability_hook_installed = true
    local set_ability_ref = Card.set_ability

    function Card:set_ability(center, initial, delay_sprites, ...)
        local results = { set_ability_ref(self, center, initial, delay_sprites, ...) }

        if CL.challenge_active("illegal_deck") and is_playing_card(self) then
            self:set_debuff(not has_enhancement(self))
        end

        return unpack(results)
    end
end

if SMODS and type(SMODS.calculate_context) == "function" and not CL.challenge_rg_loop_hook_installed then
    CL.challenge_rg_loop_hook_installed = true
    local calculate_context_ref = SMODS.calculate_context

    function SMODS.calculate_context(context, return_table, no_resolve, ...)
        if context and context.end_of_round and context.beat_boss and G and G.GAME and G.GAME.blind then
            local center = G.GAME.blind.config and G.GAME.blind.config.blind
            local defeated_count = center and center.key == "bl_canlaugh_earthsea_borealis" and 6 or 1
            G.GAME.canlaugh_bosses_defeated = (G.GAME.canlaugh_bosses_defeated or 0) + defeated_count
        end

        if CL.challenge_active("rg_department")
            and context
            and context.ante_change
            and G.GAME.canlaugh_rg_left_ante_one
        then
            local ante = G.GAME.round_resets and G.GAME.round_resets.ante or 0
            if ante <= 1 and SMODS.find_card("j_canlaugh_resourceful_joker") then
                G.STATE = G.STATES.GAME_OVER
                G.STATE_COMPLETE = false
            end
        end

        if CL.challenge_active("rg_department")
            and context
            and context.ante_change
            and (G.GAME.round_resets and G.GAME.round_resets.ante or 0) > 1
        then
            G.GAME.canlaugh_rg_left_ante_one = true
        end

        if CL.challenge_active("burning_up") and context and context.ante_change then
            for _, card in ipairs(G.playing_cards or {}) do
                CL.catalyze_rank(card, false)
            end
        end

        if CL.challenge_active("double_reacharound") and context and context.ante_change then
            local ante = G.GAME.round_resets and G.GAME.round_resets.ante or 0
            if ante > 8 and not G.GAME.canlaugh_double_reacharound_endless then
                G.GAME.canlaugh_double_reacharound_resetting = true
                ease_ante(-(ante - 1))
                G.GAME.canlaugh_double_reacharound_resetting = nil
            end
        end

        if CL.challenge_active("double_reacharound")
            and context
            and context.selling_card
            and SMODS.find_card("j_canlaugh_resourceful_joker")
            and context.card
            and context.card.config
            and context.card.config.center
            and context.card.config.center.consumeable
        then
            CL.challenge_win_run()
        end

        return calculate_context_ref(context, return_table, no_resolve, ...)
    end
end
