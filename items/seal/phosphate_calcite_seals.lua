local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

G.C.CANLAUGH_PHOSPHATE = G.C.CANLAUGH_PHOSPHATE or HEX("EB0000")
G.C.CANLAUGH_CALCITE = G.C.CANLAUGH_CALCITE or HEX("FEC35C")

local PHOSPHATE_SEAL = "canlaugh_phosphate"
local CALCITE_SEAL = "canlaugh_calcite"
local PHOSPHATE_BACKER = "m_canlaugh_phosphate_backer"
local CALCITE_BACKER = "m_canlaugh_calcite_backer"

if CL.register_probability_seal then
    CL.register_probability_seal(CALCITE_SEAL)
end

local PAIRED_SEAL_TO_BACKER = {
    [PHOSPHATE_SEAL] = PHOSPHATE_BACKER,
    [CALCITE_SEAL] = CALCITE_BACKER,
}

local function canlaugh_center_key(card)
    return card
        and card.config
        and card.config.center
        and card.config.center.key
end

local function canlaugh_is_default_center(card)
    local center = card and card.config and card.config.center
    if not center then
        return true
    end

    return center.key == "c_base" or center.set == "Default"
end

local function canlaugh_has_paired_seal(card)
    return card and PAIRED_SEAL_TO_BACKER[card.seal] ~= nil
end

local function canlaugh_can_receive_paired_seal(card, seal)
    if not card or not PAIRED_SEAL_TO_BACKER[seal] then
        return false
    end

    if card.seal and card.seal ~= seal then
        return false
    end

    return canlaugh_is_default_center(card)
end

local function canlaugh_clear_real_paired_backer(card)
    local center_key = canlaugh_center_key(card)

    if not (card and PAIRED_SEAL_TO_BACKER[card.seal] == center_key) then
        return
    end

    if G and G.P_CENTERS and G.P_CENTERS.c_base and type(card.set_ability) == "function" then
        CL.paired_seal_internal_change = true
        card:set_ability(G.P_CENTERS.c_base, nil, true)
        CL.paired_seal_internal_change = nil
    end
end

local function canlaugh_apply_phosphate_xmult(card)
    if not card or card.debuff then
        return
    end

    SMODS.calculate_effect({
        x_mult = 2,
        card = card,
        message_card = card,
        colour = G.C.MULT,
    }, card)
end

local function canlaugh_force_phosphate_cards_front(cards)
    if not cards then
        return
    end

    for _, card in ipairs(cards) do
        if card and not card.removed then
            if card.ability then
                card.ability.wheel_flipped = nil
            end

            if card.facing ~= "front" then
                card.facing = "front"
            end

            if card.sprite_facing ~= "front" then
                card.sprite_facing = "front"
            end
        end
    end
end

local function canlaugh_unflip_returned_phosphate_cards(cards)
    if not cards or #cards == 0 then
        return
    end

    canlaugh_force_phosphate_cards_front(cards)

    if not (G and G.E_MANAGER) then
        return
    end

    local delays = { 0.05, 0.15, 0.3, 0.6, 1.0 }

    for _, delay in ipairs(delays) do
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = delay,
            func = function()
                canlaugh_force_phosphate_cards_front(cards)
                return true
            end,
        }))
    end
end

local function canlaugh_remove_card_reference(area, card)
    if not (area and area.cards and card) then
        return
    end

    for i = #area.cards, 1, -1 do
        if area.cards[i] == card then
            table.remove(area.cards, i)
        end
    end

    if area.config then
        area.config.card_count = #area.cards
    end
end

local function canlaugh_scrub_duplicate_phosphate_card_refs(card)
    if not card then
        return
    end

    local areas = {
        G and G.play,
        G and G.discard,
        G and G.deck,
    }

    if card.area == G.hand then
        for _, area in ipairs(areas) do
            canlaugh_remove_card_reference(area, card)
        end
    end

    if G and G.hand and G.hand.cards then
        local found = false

        for i = #G.hand.cards, 1, -1 do
            if G.hand.cards[i] == card then
                if found then
                    table.remove(G.hand.cards, i)
                else
                    found = true
                end
            end
        end

        if G.hand.config then
            G.hand.config.card_count = #G.hand.cards
        end
    end

    if G and G.playing_cards then
        local found = false

        for i = #G.playing_cards, 1, -1 do
            if G.playing_cards[i] == card then
                if found then
                    table.remove(G.playing_cards, i)
                else
                    found = true
                end
            end
        end
    end
end

local function canlaugh_dedupe_playing_card_refs()
    if not (G and G.playing_cards) then
        return
    end

    local seen = {}

    for i = #G.playing_cards, 1, -1 do
        local card = G.playing_cards[i]

        if card and seen[card] then
            table.remove(G.playing_cards, i)
        elseif card then
            seen[card] = true
        end
    end
end

local function canlaugh_move_phosphate_cards_to_hand(cards)
    if not cards or #cards == 0 or not (G and G.hand) then
        return
    end

    for _, card in ipairs(cards) do
        if card and not card.removed then
            if card.area ~= G.hand then
                if card.area and type(draw_card) == "function" then
                    draw_card(card.area, G.hand, 100, "up", true, card, nil, nil, false)
                else
                    if card.area and type(card.area.remove_card) == "function" then
                        card.area:remove_card(card)
                    end

                    if type(G.hand.emplace) == "function" then
                        G.hand:emplace(card)
                    end
                end
            end

            canlaugh_scrub_duplicate_phosphate_card_refs(card)
        end
    end

    canlaugh_unflip_returned_phosphate_cards(cards)
end

local function canlaugh_queue_phosphate_cards_return(cards)
    if not cards or #cards == 0 then
        return
    end

    if not (G and G.E_MANAGER) then
        canlaugh_move_phosphate_cards_to_hand(cards)
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.8,
        func = function()
            canlaugh_move_phosphate_cards_to_hand(cards)
            return true
        end,
    }))
end

local function canlaugh_trigger_phosphate_joker_scoring(context)
    if CL.phosphate_joker_scoring_done then
        return
    end

    CL.phosphate_joker_scoring_done = true

    for _, card in ipairs(context.scoring_hand or {}) do
        if card
            and card.seal == PHOSPHATE_SEAL
            and card:can_calculate()
        then
            canlaugh_apply_phosphate_xmult(card)
        end
    end
end

local function canlaugh_collect_phosphate_cards_from_play()
    local return_cards = {}

    if not (G and G.play and G.play.cards) then
        return return_cards
    end

    for _, card in ipairs(G.play.cards) do
        if card
            and card.seal == PHOSPHATE_SEAL
            and card.ability
            and not card.ability.canlaugh_phosphate_returned_this_round
            and not card.shattered
            and not card.destroyed
        then
            card.ability.canlaugh_phosphate_returned_this_round = true
            return_cards[#return_cards + 1] = card
        end
    end

    return return_cards
end

local function canlaugh_reset_phosphate_returns()
    if not (G and G.playing_cards) then
        return
    end

    for _, card in ipairs(G.playing_cards) do
        if card and card.ability then
            card.ability.canlaugh_phosphate_returned_this_round = nil
        end
    end

    canlaugh_dedupe_playing_card_refs()
end

local function canlaugh_install_phosphate_return_hook()
    if not (G and G.FUNCS and type(G.FUNCS.draw_from_play_to_discard) == "function") then
        return
    end

    if CL.phosphate_return_hook_installed then
        return
    end

    CL.phosphate_return_hook_installed = true

    local cl_draw_from_play_to_discard_ref = G.FUNCS.draw_from_play_to_discard

    function G.FUNCS.draw_from_play_to_discard(e)
        local return_cards = canlaugh_collect_phosphate_cards_from_play()
        local results = { cl_draw_from_play_to_discard_ref(e) }

        canlaugh_queue_phosphate_cards_return(return_cards)

        return unpack(results)
    end
end

local function canlaugh_is_collection_preview(card)
    return card
        and card.area
        and card.area.config
        and card.area.config.collection
end

local function canlaugh_clear_collection_rank_suit(card)
    if not card then
        return
    end

    card.canlaugh_paired_seal_collection_preview = true
end

function CL.prepare_paired_seal_collection_card(card, center)
    if center and PAIRED_SEAL_TO_BACKER[center.key] then
        canlaugh_clear_collection_rank_suit(card)
    end
end

local function canlaugh_collection_backer_key(card)
    if not (card and card.canlaugh_paired_seal_collection_preview) then
        return nil
    end

    return PAIRED_SEAL_TO_BACKER[card.seal]
end

local function canlaugh_paired_backer_key(card)
    if not card then
        return nil
    end

    if card.canlaugh_collection_joker_preview then
        return nil
    end

    if card.canlaugh_paired_seal_collection_preview then
        return canlaugh_collection_backer_key(card)
    end

    return PAIRED_SEAL_TO_BACKER[card.seal]
end

local function canlaugh_get_collection_backer_sprite(backer_key)
    if not (backer_key and G and G.P_CENTERS and SMODS and type(SMODS.create_sprite) == "function") then
        return nil
    end

    local backer = G.P_CENTERS[backer_key]
    if not (backer and backer.atlas and backer.pos) then
        return nil
    end

    G.shared_canlaugh_paired_seal_backers = G.shared_canlaugh_paired_seal_backers or {}

    if not G.shared_canlaugh_paired_seal_backers[backer_key] then
        local atlas = SMODS.get_atlas(backer.atlas) or backer.atlas
        G.shared_canlaugh_paired_seal_backers[backer_key] =
            SMODS.create_sprite(0, 0, G.CARD_W, G.CARD_H, atlas, backer.pos)
    end

    return G.shared_canlaugh_paired_seal_backers[backer_key]
end

local function canlaugh_draw_collection_backer(card)
    local backer_key = canlaugh_paired_backer_key(card)
    local sprite = canlaugh_get_collection_backer_sprite(backer_key)

    if sprite and card and card.children and card.children.center then
        sprite.role.draw_major = card
        sprite:draw_shader("dissolve", nil, nil, nil, card.children.center)
    end
end

if not CL.phosphate_calcite_card_hooks_installed then
    CL.phosphate_calcite_card_hooks_installed = true

    local cl_set_seal_ref = Card.set_seal

    function Card:set_seal(_seal, silent, immediate, ...)
        if not CL.paired_seal_internal_change then
            if canlaugh_has_paired_seal(self) and _seal ~= self.seal then
                return
            end

            if PAIRED_SEAL_TO_BACKER[_seal]
                and not CL.paired_seal_grafting
                and not canlaugh_can_receive_paired_seal(self, _seal)
            then
                return
            end
        end

        local results = { cl_set_seal_ref(self, _seal, silent, immediate, ...) }

        if PAIRED_SEAL_TO_BACKER[_seal] then
            if CL.paired_seal_collection_building or canlaugh_is_collection_preview(self) then
                canlaugh_clear_collection_rank_suit(self)
            else
                canlaugh_clear_real_paired_backer(self)
            end
        end

        return unpack(results)
    end

    local cl_set_ability_ref = Card.set_ability

    function Card:set_ability(center, initial, delay_sprites, ...)
        if canlaugh_has_paired_seal(self) and not CL.paired_seal_internal_change then
            local target_key = type(center) == "string" and center or center and center.key

            if target_key and target_key ~= "c_base" then
                return
            end
        end

        return cl_set_ability_ref(self, center, initial, delay_sprites, ...)
    end
end

if Card and type(Card.generate_UIBox_ability_table) == "function" and not CL.phosphate_calcite_tooltip_hook_installed then
    CL.phosphate_calcite_tooltip_hook_installed = true

    local cl_generate_UIBox_ability_table_ref = Card.generate_UIBox_ability_table

    function Card:generate_UIBox_ability_table(vars_only)
        if canlaugh_has_paired_seal(self) then
            canlaugh_clear_real_paired_backer(self)

            if canlaugh_is_collection_preview(self) or self.canlaugh_paired_seal_collection_preview then
                return generate_card_ui(G.P_SEALS[self.seal], nil, nil, "Seal", nil, nil, nil, nil, self)
            end

            local old_center = self.config and self.config.center
            local old_center_key = self.config and self.config.center_key
            local old_ability_set = self.ability and self.ability.set
            local old_ability_name = self.ability and self.ability.name

            if self.config and G.P_CENTERS and G.P_CENTERS.c_base then
                self.config.center = G.P_CENTERS.c_base
                self.config.center_key = "c_base"
            end
            if self.ability then
                self.ability.set = "Default"
                self.ability.name = "Default Base"
            end

            local results = { cl_generate_UIBox_ability_table_ref(self, vars_only) }

            if self.config then
                self.config.center = old_center
                self.config.center_key = old_center_key
            end
            if self.ability then
                self.ability.set = old_ability_set
                self.ability.name = old_ability_name
            end

            return unpack(results)
        end

        return cl_generate_UIBox_ability_table_ref(self, vars_only)
    end
end

if SMODS and type(SMODS.calculate_context) == "function" and not CL.phosphate_calcite_context_hook_installed then
    CL.phosphate_calcite_context_hook_installed = true

    local cl_phosphate_calcite_calculate_context_ref = SMODS.calculate_context

    function SMODS.calculate_context(context, return_table, no_resolve, ...)
        canlaugh_install_phosphate_return_hook()

        if context and context.initial_scoring_step then
            CL.phosphate_joker_scoring_done = nil
        end

        local results = { cl_phosphate_calcite_calculate_context_ref(context, return_table, no_resolve, ...) }

        if context and context.joker_main and not CL.phosphate_joker_scoring_running then
            CL.phosphate_joker_scoring_running = true
            local ok, err = pcall(canlaugh_trigger_phosphate_joker_scoring, context)
            CL.phosphate_joker_scoring_running = nil

            if not ok and type(sendErrorMessage) == "function" then
                sendErrorMessage("[Canned Laughter] Phosphate Seal failed to score: " .. tostring(err))
            end
        elseif context and context.final_scoring_step and not CL.phosphate_joker_scoring_done then
            CL.phosphate_joker_scoring_running = true
            local ok, err = pcall(canlaugh_trigger_phosphate_joker_scoring, context)
            CL.phosphate_joker_scoring_running = nil

            if not ok and type(sendErrorMessage) == "function" then
                sendErrorMessage("[Canned Laughter] Phosphate Seal failed to score: " .. tostring(err))
            end
        end

        if context and context.setting_blind then
            canlaugh_reset_phosphate_returns()
        end

        return unpack(results)
    end
end

if type(eval_card) == "function" and not CL.phosphate_calcite_eval_card_hook_installed then
    CL.phosphate_calcite_eval_card_hook_installed = true

    local cl_eval_card_ref = eval_card

    function eval_card(card, context, ...)
        if context
            and context.joker_main
            and not CL.phosphate_joker_scoring_done
            and not CL.phosphate_joker_scoring_running
        then
            CL.phosphate_joker_scoring_running = true
            local ok, err = pcall(canlaugh_trigger_phosphate_joker_scoring, context)
            CL.phosphate_joker_scoring_running = nil

            if not ok and type(sendErrorMessage) == "function" then
                sendErrorMessage("[Canned Laughter] Phosphate Seal failed to score: " .. tostring(err))
            end
        end

        return cl_eval_card_ref(card, context, ...)
    end
end

canlaugh_install_phosphate_return_hook()

if SMODS and type(SMODS.card_collection_UIBox) == "function" and not CL.phosphate_calcite_collection_hook_installed then
    CL.phosphate_calcite_collection_hook_installed = true

    local cl_card_collection_UIBox_ref = SMODS.card_collection_UIBox

    function SMODS.card_collection_UIBox(pool, rows, args)
        if pool == G.P_CENTER_POOLS.Seal then
            local original_args = args or {}
            local original_modify_card = original_args.modify_card
            local seal_args = {}

            for key, value in pairs(original_args) do
                seal_args[key] = value
            end

            seal_args.modify_card = function(card, center, ...)
                if original_modify_card then
                    CL.paired_seal_collection_building = true
                    original_modify_card(card, center, ...)
                    CL.paired_seal_collection_building = nil
                end

                CL.prepare_paired_seal_collection_card(card, center)
            end

            return cl_card_collection_UIBox_ref(pool, rows, seal_args)
        end

        return cl_card_collection_UIBox_ref(pool, rows, args)
    end
end

if SMODS and SMODS.DrawSteps and SMODS.DrawSteps.center and SMODS.DrawSteps.front and not CL.phosphate_calcite_front_draw_hook_installed then
    CL.phosphate_calcite_front_draw_hook_installed = true

    local cl_center_draw_ref = SMODS.DrawSteps.center.func

    SMODS.DrawSteps.center.func = function(card, layer)
        canlaugh_clear_real_paired_backer(card)

        local results = { cl_center_draw_ref(card, layer) }
        canlaugh_draw_collection_backer(card)
        return unpack(results)
    end

    local cl_front_draw_ref = SMODS.DrawSteps.front.func

    SMODS.DrawSteps.front.func = function(card, layer)
        if card and card.canlaugh_paired_seal_collection_preview and card.config and card.config.center then
            local center = card.config.center
            local old_no_suit = center.no_suit
            local old_no_rank = center.no_rank

            center.no_suit = true
            center.no_rank = true

            local results = { cl_front_draw_ref(card, layer) }

            center.no_suit = old_no_suit
            center.no_rank = old_no_rank

            return unpack(results)
        end

        return cl_front_draw_ref(card, layer)
    end
end

SMODS.Atlas({
    key = "phosphate_seal",
    path = "phosphate_seal.png",
    px = 69,
    py = 93,
})

SMODS.Atlas({
    key = "phosphate_enhancement",
    path = "phosphate_enhancement.png",
    px = 69,
    py = 93,
})

SMODS.Atlas({
    key = "calcite_seal",
    path = "calcite_seal.png",
    px = 69,
    py = 93,
})

SMODS.Atlas({
    key = "calcite_enhancement",
    path = "calcite_enhancement.png",
    px = 69,
    py = 93,
})

SMODS.Enhancement({
    key = "phosphate_backer",
    atlas = "phosphate_enhancement",
    pos = { x = 0, y = 0 },
    discovered = true,
    no_collection = true,
    no_doe = true,
    loc_txt = {
        name = "Phosphate Backer",
        text = {},
    },
    in_pool = function()
        return false
    end,
})

SMODS.Enhancement({
    key = "calcite_backer",
    atlas = "calcite_enhancement",
    pos = { x = 0, y = 0 },
    discovered = true,
    no_collection = true,
    no_doe = true,
    loc_txt = {
        name = "Calcite Backer",
        text = {},
    },
    in_pool = function()
        return false
    end,
})

SMODS.Seal({
    key = "phosphate",
    atlas = "phosphate_seal",
    pos = { x = 0, y = 0 },
    badge_colour = G.C.CANLAUGH_PHOSPHATE,
    discovered = true,
    in_pool = function()
        return false
    end,
    loc_txt = {
        label = "Phosphate Seal",
        name = "Phosphate Seal",
        text = {
            "Gives {X:mult,C:white}X2{} Mult",
            "during {C:attention}Joker scoring{}",
            "Drawn back to hand",
            "after {C:attention}first play{}",
            "{C:inactive}This card cannot be{}",
            "{C:inactive}sealed or enhanced{}",
        },
    },
    calculate = function(self, card, context)
        canlaugh_clear_real_paired_backer(card)
    end,
})

SMODS.Seal({
    key = "calcite",
    atlas = "calcite_seal",
    pos = { x = 0, y = 0 },
    badge_colour = G.C.CANLAUGH_CALCITE,
    discovered = true,
    in_pool = function()
        return false
    end,
    loc_txt = {
        label = "Calcite Seal",
        name = "Calcite Seal",
        text = {
            "Gives {X:mult,C:white}X2{} Mult",
            "when {C:attention}held in hand{}",
            "{C:green}#1# in #2#{} chance",
            "to {C:attention}retrigger{}",
            "{C:inactive}This card cannot be{}",
            "{C:inactive}sealed or enhanced{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local numerator, denominator = SMODS.get_probability_vars(card, 1, 2, "canlaugh_calcite_retrigger")
        return {
            vars = { numerator, denominator },
        }
    end,
    calculate = function(self, card, context)
        canlaugh_clear_real_paired_backer(card)

        if context.cardarea == G.hand
            and context.main_scoring
            and not context.repetition
        then
            return {
                x_mult = 2,
                card = card,
            }
        end

        if context.repetition
            and context.cardarea == G.hand
            and card:can_calculate()
            and SMODS.pseudorandom_probability(card, "canlaugh_calcite_retrigger", 1, 2)
        then
            return {
                message = localize("k_again_ex"),
                repetitions = 1,
                card = card,
            }
        end
    end,
})
