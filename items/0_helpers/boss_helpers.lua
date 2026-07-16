local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

function CL.boss_active(key)
    if not (G and G.GAME and G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind) then
        return false
    end

    local active_key = G.GAME.blind.config.blind.key
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
    def.pos = { x = 0, y = 0 }
    def.boss = { min = 1, max = 10 }
    def.canlaugh_boss = true
    def.discovered = true
    SMODS.Blind(def)
end

function CL.register_showdown_boss(def)
    def.pos = { x = 0, y = 0 }
    def.boss = { min = 1, max = 1000000, showdown = true }
    def.canlaugh_boss = true
    def.canlaugh_showdown = true
    def.discovered = true
    SMODS.Blind(def)
end

function CL.baton_select_all()
    if not CL.boss_active("bl_canlaugh_tyrian_baton") then return end

    local cards = G.hand and G.hand.cards or {}
    G.hand:unhighlight_all()

    for _, card in ipairs(cards) do
        G.hand:add_to_highlighted(card, true)
    end
end

if G and G.FUNCS and G.FUNCS.play_cards_from_highlighted and not CL.baton_play_hook_installed then
    CL.baton_play_hook_installed = true
    local play_cards_from_highlighted = G.FUNCS.play_cards_from_highlighted

    G.FUNCS.play_cards_from_highlighted = function(e)
        if not CL.boss_active("bl_canlaugh_tyrian_baton") then return play_cards_from_highlighted(e) end

        local limit = G.hand.config.highlighted_limit
        G.hand.config.highlighted_limit = #G.hand.cards
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

if SMODS and SMODS.always_scores and not CL.baton_scoring_hook_installed then
    CL.baton_scoring_hook_installed = true
    local always_scores = SMODS.always_scores

    function SMODS.always_scores(card)
        if CL.boss_active("bl_canlaugh_tyrian_baton") then return true end
        return always_scores(card)
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
                                    string = "All cards score",
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
