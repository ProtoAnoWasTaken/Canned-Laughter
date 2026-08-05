local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

function CL.boss_active(key)
    local blind = G and G.GAME and G.GAME.blind
    if not (blind and blind.config and blind.config.blind) then
        return false
    end

    if blind.disabled then
        return false
    end

    local active_key = blind.config.blind.key
    if active_key == key then
        return true
    end

    return active_key == "bl_canlaugh_earthsea_borealis"
        and G.GAME.canlaugh_earthsea_inherited_bosses
        and G.GAME.canlaugh_earthsea_inherited_bosses[key]
end

function CL.boss_hand_size()
    return (G and G.hand and G.hand.config and G.hand.config.highlighted_limit) or 5
end

function CL.boss_random(cards, seed)
    if not cards or #cards == 0 then return nil end
    if pseudorandom_element and pseudoseed then return pseudorandom_element(cards, pseudoseed(seed)) end
    return cards[math.random(#cards)]
end

function CL.boss_most_played(hands)
    local chosen, count
    for name, hand in pairs(hands or {}) do
        if not count or (hand.played or 0) > count then chosen, count = name, hand.played or 0 end
    end
    return chosen
end

function CL.ensure_boss_usage_entries()
    local game = G and G.GAME
    if not game then return end

    game.bosses_used = game.bosses_used or {}

    for key, blind in pairs(G.P_BLINDS or {}) do
        if blind.canlaugh_boss and type(game.bosses_used[key]) ~= "number" then
            game.bosses_used[key] = 0
        end
    end
end

CL.ensure_boss_usage_entries()

if type(get_new_boss) == "function" and not CL.boss_usage_hook_installed then
    CL.boss_usage_hook_installed = true
    local get_new_boss_ref = get_new_boss

    function get_new_boss(...)
        CL.ensure_boss_usage_entries()
        return get_new_boss_ref(...)
    end
end

function CL.exchange_discard_selection()
    local challenge = G and G.GAME and G.GAME.challenge
    if not CL.boss_active("bl_canlaugh_exchange") and challenge ~= "c_canlaugh_gift_exchange" then
        return
    end

    local selected = {}

    for _, card in ipairs(G.hand.highlighted or {}) do
        selected[card] = true
    end

    G.hand:unhighlight_all()

    for _, card in ipairs(G.hand.cards or {}) do
        if not selected[card] then G.hand:add_to_highlighted(card, true) end
    end
end

if G and G.FUNCS and G.FUNCS.discard_cards_from_highlighted and not CL.exchange_discard_hook_installed then
    CL.exchange_discard_hook_installed = true
    local discard_cards_from_highlighted = G.FUNCS.discard_cards_from_highlighted

    G.FUNCS.discard_cards_from_highlighted = function(e, hook)
        CL.exchange_discard_selection()
        return discard_cards_from_highlighted(e, hook)
    end
end

function CL.register_standard_boss(def)
    def.debuff = def.debuff or {}
    def.pos = { x = 0, y = 0 }
    def.boss = { min = 1, max = 10 }
    def.canlaugh_boss = true
    def.discovered = false
    SMODS.Blind(def)
end

function CL.register_showdown_boss(def)
    def.debuff = def.debuff or {}
    def.pos = { x = 0, y = 0 }
    def.boss = { min = 1, max = 1000000, showdown = true }
    def.canlaugh_boss = true
    def.canlaugh_showdown = true
    def.discovered = false
    SMODS.Blind(def)
end

function CL.register_super_showdown_boss(def)
    def.debuff = def.debuff or {}
    def.pos = { x = 0, y = 0 }
    def.boss = { min = 1, max = 1000000, showdown = true }
    def.canlaugh_boss = true
    def.canlaugh_showdown = true
    def.canlaugh_superboss = true
    def.discovered = false
    SMODS.Blind(def)
end

function CL.catalyze_rank(card, destroy_ace, destroy_after_scoring)
    if not card or card.removed or card.destroyed or not card.base then
        return
    end

    if card.base.id == 14 then
        if not destroy_ace then
            local blazing = SMODS
                and type(SMODS.has_enhancement) == "function"
                and SMODS.has_enhancement(card, "m_canlaugh_blazing")

            if not blazing then
                return
            end
        end

        card:flip()
        play_sound("card1", 1, 0.6)
        if destroy_after_scoring then
            card.canlaugh_catalyze_destroy_after_scoring = true
            return
        end
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.2,
            func = function()
                if SMODS and type(SMODS.destroy_cards) == "function" then
                    SMODS.destroy_cards(card)
                else
                    card.destroyed = true
                    card:start_dissolve({ G.C.RED, G.C.ORANGE, G.C.YELLOW }, nil, 1.6)
                end

                return true
            end,
        }))
        return
    end

    local rank_id = card.base.id == 2 and 14 or card.base.id - 1
    local rank = CL.consumables and CL.consumables.rank_center and CL.consumables.rank_center(rank_id)

    if not rank then
        return
    end

    if CL.consumables and type(CL.consumables.tarot_flip) == "function" then
        CL.consumables.tarot_flip(card, function()
            SMODS.change_base(card, nil, rank.key)
        end)
        return
    end

    SMODS.change_base(card, nil, rank.key)
end

function CL.baton_select_all()
    if not CL.boss_active("bl_canlaugh_tyrian_baton") then return end

    local cards = G.hand and G.hand.cards or {}
    G.hand:unhighlight_all()

    for _, card in ipairs(cards) do
        G.hand:add_to_highlighted(card, true)
    end
end

function CL.baton_capture_scoring_cards()
    local selected_cards = {}

    for _, card in ipairs(G.hand and G.hand.highlighted or {}) do
        selected_cards[#selected_cards + 1] = card
    end

    CL.baton_scoring_cards = selected_cards
end

function CL.baton_set_expanded_scoring_cards(scoring_cards)
    local expanded_cards = {}

    for _, card in ipairs(scoring_cards or {}) do
        expanded_cards[card] = true
    end

    CL.baton_expanded_scoring_cards = expanded_cards
end

local function baton_uses_selected_scoring_cards(cards)
    if not CL.boss_active("bl_canlaugh_tyrian_baton") then
        return false
    end

    if not (G and G.play and cards == G.play.cards and #cards > 0) then
        return false
    end

    local selected_cards = CL.baton_scoring_cards
    if not selected_cards or #selected_cards == 0 then
        return false
    end

    return true
end

local function baton_contains_all_cards(cards, required_cards)
    local present = {}

    for _, card in ipairs(cards or {}) do
        present[card] = true
    end

    for _, card in ipairs(required_cards or {}) do
        if not present[card] then
            return false
        end
    end

    return true
end

local function baton_expand_flush_scoring_cards(cards, selected_scoring_cards)
    for _, suit in ipairs(SMODS and SMODS.Suit and SMODS.Suit.obj_buffer or {}) do
        local matching_cards = {}

        for _, card in ipairs(cards) do
            if card:is_suit(suit, nil, true) then
                matching_cards[#matching_cards + 1] = card
            end
        end

        if baton_contains_all_cards(matching_cards, selected_scoring_cards) then
            return matching_cards
        end
    end

    return selected_scoring_cards
end

local function baton_expand_flush_five_scoring_cards(cards, selected_scoring_cards)
    local selected_rank = selected_scoring_cards[1] and selected_scoring_cards[1]:get_id()

    if not selected_rank then
        return selected_scoring_cards
    end

    for _, card in ipairs(selected_scoring_cards) do
        if card:get_id() ~= selected_rank then
            return selected_scoring_cards
        end
    end

    for _, suit in ipairs(SMODS and SMODS.Suit and SMODS.Suit.obj_buffer or {}) do
        local matching_cards = {}

        for _, card in ipairs(cards) do
            if card:get_id() == selected_rank and card:is_suit(suit, nil, true) then
                matching_cards[#matching_cards + 1] = card
            end
        end

        if baton_contains_all_cards(matching_cards, selected_scoring_cards) then
            return matching_cards
        end
    end

    return selected_scoring_cards
end

local function baton_expand_straight_flush_scoring_cards(cards, selected_scoring_cards)
    local min_length = SMODS and type(SMODS.four_fingers) == "function" and SMODS.four_fingers("straight") or 5
    local can_skip = SMODS and type(SMODS.shortcut) == "function" and SMODS.shortcut() or false
    local can_wrap = SMODS and type(SMODS.wrap_around_straight) == "function" and SMODS.wrap_around_straight() or false

    for _, suit in ipairs(SMODS and SMODS.Suit and SMODS.Suit.obj_buffer or {}) do
        local suited_cards = {}

        for _, card in ipairs(cards) do
            if card:is_suit(suit, nil, true) then
                suited_cards[#suited_cards + 1] = card
            end
        end

        for _, straight in ipairs(get_straight(suited_cards, min_length, can_skip, can_wrap)) do
            if baton_contains_all_cards(straight, selected_scoring_cards) then
                return straight
            end
        end
    end

    return selected_scoring_cards
end

local function baton_expand_scoring_cards(cards, hand_name, selected_scoring_cards)
    if hand_name == "Flush Five" then
        return baton_expand_flush_five_scoring_cards(cards, selected_scoring_cards)
    end

    if hand_name == "Flush" then
        return baton_expand_flush_scoring_cards(cards, selected_scoring_cards)
    end

    if hand_name == "Straight Flush" then
        return baton_expand_straight_flush_scoring_cards(cards, selected_scoring_cards)
    end

    local poker_hands = evaluate_poker_hand(cards)
    local candidates = poker_hands and poker_hands[hand_name] or {}

    for _, candidate in ipairs(candidates) do
        if baton_contains_all_cards(candidate, selected_scoring_cards) then
            return candidate
        end
    end

    return selected_scoring_cards
end

local function baton_flush_five_display_name(scoring_cards)
    local size = #(scoring_cards or {})
    local flush_names = {
        [6] = "Flush Six",
        [7] = "Flush Seven",
        [8] = "Flush Eight",
        [9] = "Flush Nine",
        [10] = "Flush Ten",
        [11] = "Flush Eleven",
    }

    if size >= 12 then
        return "Flush Toilet"
    end

    return flush_names[size]
end

if G and G.FUNCS and G.FUNCS.play_cards_from_highlighted and not CL.baton_play_hook_installed then
    CL.baton_play_hook_installed = true
    local play_cards_from_highlighted = G.FUNCS.play_cards_from_highlighted

    G.FUNCS.play_cards_from_highlighted = function(e)
        if not CL.boss_active("bl_canlaugh_tyrian_baton") then return play_cards_from_highlighted(e) end

        local limit = G.hand.config.highlighted_limit
        G.hand.config.highlighted_limit = #G.hand.cards
        CL.baton_capture_scoring_cards()
        CL.baton_select_all()
        local results = { pcall(play_cards_from_highlighted, e) }
        G.hand.config.highlighted_limit = limit
        if not results[1] then
            error(results[2])
        end
        return unpack(results, 2)
    end
end

if G and G.FUNCS and G.FUNCS.discard_cards_from_highlighted and not CL.baton_discard_hook_installed then
    CL.baton_discard_hook_installed = true
    local discard_cards_from_highlighted = G.FUNCS.discard_cards_from_highlighted

    G.FUNCS.discard_cards_from_highlighted = function(e, hook)
        if not CL.boss_active("bl_canlaugh_tyrian_baton") then return discard_cards_from_highlighted(e, hook) end

        local hand_limit = G.hand.config.highlighted_limit
        local discard_limit = G.discard.config.card_limit
        G.hand.config.highlighted_limit = #G.hand.cards
        G.discard.config.card_limit = #G.hand.cards
        CL.baton_select_all()
        local results = { pcall(discard_cards_from_highlighted, e, hook) }
        G.hand.config.highlighted_limit = hand_limit
        G.discard.config.card_limit = discard_limit
        if not results[1] then
            error(results[2])
        end
        return unpack(results, 2)
    end
end

if G and G.FUNCS and type(G.FUNCS.get_poker_hand_info) == "function" and not CL.baton_hand_evaluation_hook_installed then
    CL.baton_hand_evaluation_hook_installed = true
    local get_poker_hand_info_ref = G.FUNCS.get_poker_hand_info

    G.FUNCS.get_poker_hand_info = function(cards, ...)
        if baton_uses_selected_scoring_cards(cards) then
            local results = { get_poker_hand_info_ref(CL.baton_scoring_cards, ...) }
            results[4] = baton_expand_scoring_cards(cards, results[1], results[4])
            CL.baton_set_expanded_scoring_cards(results[4])
            local display_name = results[1] == "Flush Five" and baton_flush_five_display_name(results[4])

            if display_name then
                results[2] = localize(display_name, "poker_hands")
                results[5] = display_name
            end

            return unpack(results)
        end

        return get_poker_hand_info_ref(cards, ...)
    end
end

if SMODS and type(SMODS.always_scores) == "function" and not CL.baton_expanded_scoring_hook_installed then
    CL.baton_expanded_scoring_hook_installed = true
    local always_scores_ref = SMODS.always_scores

    function SMODS.always_scores(card)
        if CL.boss_active("bl_canlaugh_tyrian_baton")
            and CL.baton_expanded_scoring_cards
            and CL.baton_expanded_scoring_cards[card]
        then
            return true
        end

        return always_scores_ref(card)
    end
end

if G and G.FUNCS and type(G.FUNCS.draw_from_play_to_discard) == "function" and not CL.baton_scoring_cards_cleanup_hook_installed then
    CL.baton_scoring_cards_cleanup_hook_installed = true
    local draw_from_play_to_discard_ref = G.FUNCS.draw_from_play_to_discard

    G.FUNCS.draw_from_play_to_discard = function(e, ...)
        local results = { pcall(draw_from_play_to_discard_ref, e, ...) }
        CL.baton_scoring_cards = nil
        CL.baton_expanded_scoring_cards = nil

        if not results[1] then
            error(results[2])
        end

        return unpack(results, 2)
    end
end

local function create_tyrian_baton_warning_text()
    return UIBox({
        definition = {
            n = G.UIT.ROOT,
            config = { align = "cm", colour = G.C.CLEAR, padding = 0.2 },
            nodes = {
                {
                    n = G.UIT.R,
                    config = { align = "cm", maxw = 1 },
                    nodes = {
                        {
                            n = G.UIT.O,
                            config = {
                                object = DynaText({
                                    scale = 0.7,
                                    string = localize("ph_unscored_hand"),
                                    maxw = 9,
                                    colours = { G.C.WHITE },
                                    float = true,
                                    shadow = true,
                                    silent = true,
                                    pop_in = 0,
                                    pop_in_rate = 6,
                                }),
                            },
                        },
                    },
                },
                {
                    n = G.UIT.R,
                    config = { align = "cm", maxw = 1 },
                    nodes = {
                        {
                            n = G.UIT.O,
                            config = {
                                object = DynaText({
                                    scale = 0.6,
                                    string = "Playing or discarding uses every card",
                                    maxw = 9,
                                    colours = { G.C.WHITE },
                                    float = true,
                                    shadow = true,
                                    silent = true,
                                    pop_in = 0,
                                    pop_in_rate = 6,
                                }),
                            },
                        },
                    },
                },
                {
                    n = G.UIT.R,
                    config = { align = "cm", maxw = 1 },
                    nodes = {
                        {
                            n = G.UIT.O,
                            config = {
                                object = DynaText({
                                    scale = 0.6,
                                    string = "Only selected cards score",
                                    maxw = 9,
                                    colours = { G.C.WHITE },
                                    float = true,
                                    shadow = true,
                                    silent = true,
                                    pop_in = 0,
                                    pop_in_rate = 6,
                                }),
                            },
                        },
                    },
                },
            },
        },
        config = {
            align = "cm",
            offset = { x = 0, y = -3.1 },
            major = G.play,
        },
    })
end

if Game and type(Game.update) == "function" and not CL.baton_warning_text_hook_installed then
    CL.baton_warning_text_hook_installed = true
    local game_update_ref = Game.update

    function Game:update(dt, ...)
        local results = { game_update_ref(self, dt, ...) }
        local blind = G and G.GAME and G.GAME.blind
        local blind_key = blind and blind.config and blind.config.blind and blind.config.blind.key

        if blind_key == "bl_canlaugh_tyrian_baton"
            and self.boss_warning_text
            and not self.boss_warning_text.canlaugh_tyrian_baton
        then
            self.boss_warning_text:remove()
            self.boss_warning_text = create_tyrian_baton_warning_text()
            self.boss_warning_text.attention_text = true
            self.boss_warning_text.states.collide.can = false
            self.boss_warning_text.canlaugh_tyrian_baton = true
        end

        return unpack(results)
    end
end

if type(ease_hands_played) == "function" and type(ease_discard) == "function" and not CL.saber_resource_hook_installed then
    CL.saber_resource_hook_installed = true
    local ease_hands_played_ref = ease_hands_played
    local ease_discard_ref = ease_discard

    function ease_hands_played(mod, ...)
        local results = { ease_hands_played_ref(mod, ...) }
        if CL.boss_active("bl_canlaugh_cinnabar_saber") and not CL.saber_syncing then
            CL.saber_syncing = true
            local synced_results = { pcall(ease_discard_ref, mod, ...) }
            CL.saber_syncing = nil
            if not synced_results[1] then
                error(synced_results[2])
            end
        end
        return unpack(results)
    end

    function ease_discard(mod, ...)
        local results = { ease_discard_ref(mod, ...) }
        if CL.boss_active("bl_canlaugh_cinnabar_saber") and not CL.saber_syncing then
            CL.saber_syncing = true
            local synced_results = { pcall(ease_hands_played_ref, mod, ...) }
            CL.saber_syncing = nil
            if not synced_results[1] then
                error(synced_results[2])
            end
        end
        return unpack(results)
    end
end
