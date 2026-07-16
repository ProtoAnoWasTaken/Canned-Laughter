local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.playing_card_jokers = CL.playing_card_jokers or {}
local PCJ = CL.playing_card_jokers

function PCJ.is_playing_card(card)
    return card
        and card.ability
        and (card.ability.set == "Default" or card.ability.set == "Enhanced")
end

function PCJ.has_edition(card, edition_key)
    if not (card and card.edition) then
        return false
    end

    return card.edition.key == "e_" .. edition_key or card.edition[edition_key]
end

function PCJ.is_scored_playing_card(card)
    if not PCJ.is_playing_card(card) then
        return false
    end

    local scoring_hand = SMODS and SMODS.last_hand and SMODS.last_hand.scoring_hand
    if type(scoring_hand) ~= "table" then
        return false
    end

    for _, scored_card in ipairs(scoring_hand) do
        if scored_card == card then
            return true
        end
    end

    return false
end

function PCJ.sunshower_active()
    if not (SMODS and type(SMODS.find_card) == "function") then
        return false
    end

    for _, joker in ipairs(SMODS.find_card("j_canlaugh_sunshower", true)) do
        if joker and not joker.debuff then
            return true
        end
    end

    return false
end

function PCJ.oil_chamber_active()
    if not (SMODS and type(SMODS.find_card) == "function") then
        return false
    end

    for _, joker in ipairs(SMODS.find_card("j_canlaugh_oil_chamber", true)) do
        if joker and not joker.debuff then
            return true
        end
    end

    return false
end

function PCJ.should_suppress_polychrome_scoring(card)
    return PCJ.sunshower_active()
        and PCJ.is_scored_playing_card(card)
        and PCJ.has_edition(card, "polychrome")
end

function PCJ.should_suppress_holographic_scoring(card)
    return PCJ.oil_chamber_active()
        and PCJ.is_scored_playing_card(card)
        and PCJ.has_edition(card, "holo")
end

function PCJ.find_cards(area, predicate)
    local cards = {}

    for _, card in ipairs((area and area.cards) or {}) do
        if predicate(card) then
            cards[#cards + 1] = card
        end
    end

    return cards
end

function PCJ.find_playing_cards(predicate)
    local cards = {}

    for _, card in ipairs(G and G.playing_cards or {}) do
        if predicate(card) then
            cards[#cards + 1] = card
        end
    end

    return cards
end

function PCJ.apply_edition_after(target, edition_key, message_card, message, colour, opts)
    if not (target and type(target.set_edition) == "function") then
        return false
    end

    opts = opts or {}

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.25,
        func = function()
            if target and not target.removed and not target.destroyed then
                target:set_edition(edition_key, true)
                if opts.discover ~= false and G.P_CENTERS and G.P_CENTERS[edition_key] then
                    discover_card(G.P_CENTERS[edition_key])
                end
                if message_card and not message_card.removed then
                    card_eval_status_text(message_card, "extra", nil, nil, nil, {
                        message = message or "Edition!",
                        colour = colour or G.C.EDITION,
                    })
                end
            end
            return true
        end,
    }))

    return true
end

function PCJ.random_lucky_card()
    return pseudorandom_element(PCJ.find_playing_cards(function(card)
        return PCJ.is_playing_card(card)
            and card.ability
            and card.ability.effect == "Lucky Card"
            and not card.edition
    end), pseudoseed("canlaugh_whitecollar_lucky"))
end

function PCJ.score_caught_fire(score_intensity)
    if not score_intensity then
        return false
    end

    local flames = type(score_intensity.flames) == "number" and score_intensity.flames or nil
    if flames and flames > 0 then
        return true
    end

    local earned_score = score_intensity.earned_score
    local required_score = score_intensity.required_score

    if type(to_number) == "function" then
        local ok_earned, converted_earned = pcall(to_number, earned_score)
        if ok_earned then
            earned_score = converted_earned
        end

        local ok_required, converted_required = pcall(to_number, required_score)
        if ok_required then
            required_score = converted_required
        end
    end

    return type(earned_score) == "number"
        and type(required_score) == "number"
        and required_score > 0
        and earned_score >= required_score
end

function PCJ.random_last_hand_card()
    return pseudorandom_element(PCJ.find_cards(G and G.play, function(card)
        return PCJ.is_playing_card(card) and not card.edition
    end), pseudoseed("canlaugh_joker_mold_card"))
end

function PCJ.count_suits(cards)
    local suits = {}

    for _, card in ipairs(cards or {}) do
        if PCJ.is_playing_card(card) and not SMODS.has_no_suit(card) then
            suits[card.base.suit] = true
        end
    end

    local count = 0
    for _, _ in pairs(suits) do
        count = count + 1
    end

    return count
end

function PCJ.is_showdown_blind(blind)
    local blind_center = blind and blind.config and blind.config.blind or blind
    return blind_center and blind_center.boss and blind_center.boss.showdown
end

function PCJ.blind_was_one_shot_showdown()
    return G
        and G.GAME
        and G.GAME.blind
        and PCJ.is_showdown_blind(G.GAME.blind)
        and G.GAME.current_round
        and G.GAME.current_round.hands_played == 1
end

function PCJ.current_joker_slots()
    return G and G.jokers and G.jokers.config and G.jokers.config.card_limit or 0
end

function PCJ.refund_hand(card)
    if not (G and G.GAME and G.GAME.current_round) then
        return
    end

    if ease_hands_played then
        ease_hands_played(1)
    else
        G.GAME.current_round.hands_left = (G.GAME.current_round.hands_left or 0) + 1
    end
    card_eval_status_text(card, "extra", nil, nil, nil, {
        message = localize("k_again_ex"),
        colour = G.C.BLUE,
    })
end

function PCJ.blood_money_multiplier()
    local dollars = G and G.GAME and G.GAME.dollars or 0
    local steps = math.max(0, math.floor(dollars / 25))
    local discount = 0.5 - (0.5 ^ (steps + 1))

    if CL.rules_card_active and CL.rules_card_active() and steps > 10 then
        discount = math.min(0.95, discount + ((steps - 10) * 0.05))
    end

    local multiplier = 1 - discount

    return multiplier, steps, (1 - multiplier) * 100
end

function PCJ.queue_negative_tag()
    if not (Tag and type(add_tag) == "function") then
        return false
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.35,
        func = function()
            add_tag(Tag("tag_negative"))
            return true
        end,
    }))

    return true
end

function PCJ.is_food_joker(card)
    if not card then
        return false
    end

    if card.is_food and card:is_food() then
        return true
    end

    local center = card.config and card.config.center

    return center
        and (
            (center.pools and center.pools.Food)
            or (CL.center_is_food and CL.center_is_food(center))
        )
end

function PCJ.should_double_food_scaling(target, scalar_value, args)
    if type(scalar_value) ~= "number" or scalar_value <= 0 or not PCJ.is_food_joker(target) then
        return false
    end

    return args
        and (
            args.operation == "-"
            or args.message_key == "a_mult_minus"
            or args.message_key == "a_xmult_minus"
            or args.message_key == "a_chips_minus"
            or args.message_key == "a_handsize_minus"
        )
end

function PCJ.gain_mold_joker_mult(card)
    if not (card and card.ability and card.ability.extra) then
        return
    end

    local mult_gain = card.ability.extra.mult_gain or 0
    card.ability.extra.mult = (card.ability.extra.mult or 0) + mult_gain
    card_eval_status_text(card, "extra", nil, nil, nil, {
        message = "+" .. tostring(mult_gain) .. " Mult",
        colour = G.C.MULT,
    })
end

function PCJ.active_mold_jokers()
    local jokers = {}

    for _, joker in ipairs(SMODS.find_card("j_canlaugh_mold_joker", true)) do
        if joker and not joker.debuff then
            jokers[#jokers + 1] = joker
        end
    end

    return jokers
end

function PCJ.gain_all_mold_jokers()
    for _, joker in ipairs(PCJ.active_mold_jokers()) do
        PCJ.gain_mold_joker_mult(joker)
    end
end

function PCJ.mark_scale_card_food_decay(target)
    CL.mold_joker_scale_card_decay_targets = CL.mold_joker_scale_card_decay_targets or {}
    CL.mold_joker_scale_card_decay_targets[target] = true
end

local function canlaugh_snapshot_numeric_expiry(card)
    local snapshot = {}
    local ability = card and card.ability
    if type(ability) ~= "table" then
        return snapshot
    end

    for key, value in pairs(ability) do
        if type(value) == "number" then
            snapshot[#snapshot + 1] = { table = ability, key = key, value = value }
        end
    end

    if type(ability.extra) == "table" then
        for key, value in pairs(ability.extra) do
            if type(value) == "number" then
                snapshot[#snapshot + 1] = { table = ability.extra, key = key, value = value }
            end
        end
    end

    return snapshot
end

local function canlaugh_apply_extra_manual_food_decay(card, snapshot)
    if CL.mold_joker_scale_card_decay_targets and CL.mold_joker_scale_card_decay_targets[card] then
        CL.mold_joker_scale_card_decay_targets[card] = nil
        return nil
    end

    if not PCJ.is_food_joker(card) then
        return nil
    end

    local decayed = false
    local displayed_remaining = nil
    for _, entry in ipairs(snapshot) do
        local current = entry.table and entry.table[entry.key]
        if type(current) == "number" and current < entry.value then
            entry.table[entry.key] = current - (entry.value - current)
            decayed = true
            if type(entry.key) == "string" and entry.key:find("remaining") then
                displayed_remaining = entry.table[entry.key]
            end
        end
    end

    if decayed then
        PCJ.gain_all_mold_jokers()
    end

    return displayed_remaining
end

function PCJ.should_mold_expire_turtle_bean(card, context)
    if not (
        context
        and context.end_of_round
        and not context.individual
        and not context.repetition
        and not context.blueprint
        and card
        and card.ability
        and card.ability.name == "Turtle Bean"
        and type(card.ability.extra) == "table"
    ) then
        return false
    end

    local mold_count = #PCJ.active_mold_jokers()
    if mold_count <= 0 then
        return false
    end

    local h_size = card.ability.extra.h_size
    local h_mod = card.ability.extra.h_mod
    if type(h_size) ~= "number" or type(h_mod) ~= "number" or h_mod <= 0 then
        return false
    end

    if h_size - h_mod <= 0 then
        return false
    end

    return h_size - (h_mod * (2 ^ mold_count)) <= 0
end

if Card and type(Card.calculate_joker) == "function" and not CL.mold_joker_manual_food_decay_hook_installed then
    CL.mold_joker_manual_food_decay_hook_installed = true
    local calculate_joker_ref = Card.calculate_joker

    function Card:calculate_joker(context, ...)
        if PCJ.should_mold_expire_turtle_bean(self, context) then
            SMODS.destroy_cards(self, nil, nil, true)
            PCJ.gain_all_mold_jokers()
            return {
                card = self,
                message = localize("k_eaten_ex"),
                colour = G.C.FILTER,
            }
        end

        local watch = context
            and not context.blueprint
            and self
            and self.config
            and self.config.center
            and self.config.center.key ~= "j_canlaugh_mold_joker"
            and PCJ.is_food_joker(self)
            and next(PCJ.active_mold_jokers()) ~= nil
        local snapshot = watch and canlaugh_snapshot_numeric_expiry(self) or nil
        local results = { calculate_joker_ref(self, context, ...) }

        if snapshot then
            local displayed_remaining = canlaugh_apply_extra_manual_food_decay(self, snapshot)
            if displayed_remaining and type(results[1]) == "table" and type(results[1].message) == "string" and results[1].message:find("left") then
                results[1].message = tostring(displayed_remaining) .. " left"
            end
        end

        return unpack(results)
    end
end

local NATURAL_EDITIONS = {
    j_canlaugh_debossed_joker = "e_foil",
    j_canlaugh_oil_chamber = "e_holo",
    j_canlaugh_sunshower = "e_polychrome",
    j_canlaugh_observer_effect = "e_negative",
}

if Card and type(Card.set_ability) == "function" and not CL.playing_card_joker_natural_edition_hook_installed then
    CL.playing_card_joker_natural_edition_hook_installed = true
    local set_ability_ref = Card.set_ability

    function Card:set_ability(center, initial, delay_sprites, ...)
        local results = { set_ability_ref(self, center, initial, delay_sprites, ...) }
        local center_key = self.config and self.config.center and self.config.center.key
        local edition_key = center_key and NATURAL_EDITIONS[center_key]

        if initial
            and edition_key
            and not self.edition
            and type(self.set_edition) == "function"
        then
            self:set_edition(edition_key, true, true)
        end

        return unpack(results)
    end
end

if Card and type(Card.draw) == "function" and not CL.observer_effect_draw_hook_installed then
    CL.observer_effect_draw_hook_installed = true
    local draw_ref = Card.draw

    if CL.observer_effect_window_focused == nil then
        CL.observer_effect_window_focused = true
    end

    if love and not CL.observer_effect_focus_hook_installed then
        CL.observer_effect_focus_hook_installed = true

        local love_focus_ref = love.focus
        function love.focus(focused, ...)
            CL.observer_effect_window_focused = focused ~= false
            if type(love_focus_ref) == "function" then
                return love_focus_ref(focused, ...)
            end
        end

        local love_visible_ref = love.visible
        function love.visible(visible, ...)
            if visible ~= nil then
                CL.observer_effect_window_focused = visible ~= false
            end
            if type(love_visible_ref) == "function" then
                return love_visible_ref(visible, ...)
            end
        end
    end

    local function canlaugh_balatro_window_focused()
        if CL.observer_effect_window_focused ~= nil then
            return CL.observer_effect_window_focused
        end

        return not (love and love.window and type(love.window.hasFocus) == "function")
            or love.window.hasFocus()
    end

    local function canlaugh_observed_atlas()
        if SMODS and type(SMODS.get_atlas) == "function" then
            local atlas = SMODS.get_atlas("observed") or SMODS.get_atlas("canlaugh_observed")
            if atlas then
                return atlas
            end
        end

        return G and G.ASSET_ATLAS and (G.ASSET_ATLAS.canlaugh_observed or G.ASSET_ATLAS.observed)
    end

    local function canlaugh_rules_card_active()
        return CL.rules_card_active and CL.rules_card_active()
    end

    function Card:draw(layer, ...)
        if self.config
            and self.config.center
            and self.config.center.key == "j_canlaugh_observer_effect"
            and self.area == G.jokers
            and canlaugh_balatro_window_focused()
            and not canlaugh_rules_card_active()
            and self.children
            and self.children.center
        then
            local atlas = canlaugh_observed_atlas()
            if atlas then
                local center = self.children.center
                local old_atlas = center.atlas
                local old_sprite_pos = center.sprite_pos

                center.atlas = atlas
                center:set_sprite_pos({ x = 0, y = 0 })

                local results = { draw_ref(self, layer, ...) }

                center.atlas = old_atlas
                if old_sprite_pos then
                    center:set_sprite_pos(old_sprite_pos)
                end

                return unpack(results)
            end
        end

        return draw_ref(self, layer, ...)
    end
end
