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
}

function CL.challenge_active(key)
    return G and G.GAME and G.GAME.challenge == CL.challenge_keys[key]
end

function CL.resourceful_component_denominator()
    if CL.challenge_active("rg_department") then
        return 50 / 3
    end

    return 50
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

        if center and center.boss and center.key ~= "bl_canlaugh_earthsea_borealis" then
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
        local playing_card_type = card_type == "Base"
            or card_type == "Enhanced"
            or card_type == "Playing Card"

        if active_glitter_glue()
            and card
            and (playing_card_type or area == G.pack_cards)
            and type(card.set_edition) == "function"
        then
            card:set_edition("e_canlaugh_glitter", true, true)
        end

        return unpack(results)
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

        return calculate_context_ref(context, return_table, no_resolve, ...)
    end
end
