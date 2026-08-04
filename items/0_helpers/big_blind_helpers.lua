local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

function CL.register_alternate_big_blind(def)
    def.debuff = def.debuff or {}

    if not def.pos then
        def.pos = {
            x = 0,
            y = 0,
        }
    end

    def.big = { min = 1 }
    def.canlaugh_big_blind = true
    def.canlaugh_collection_tier = 2
    def.discovered = false
    def.dollars = def.dollars or 4
    def.mult = def.mult or 1.5
    def.in_pool = function()
        return false
    end
    SMODS.Blind(def)
end

if Blind and type(Blind.set_blind) == "function" and not CL.alternate_big_blind_set_hook_installed then
    CL.alternate_big_blind_set_hook_installed = true
    local set_blind_ref = Blind.set_blind

    function Blind:set_blind(blind, reset, silent, ...)
        local game = G and G.GAME
        local selected_key = game and game.canlaugh_selected_alternate_big
        local selected_blind = selected_key and G.P_BLINDS and G.P_BLINDS[selected_key]

        if not reset
            and blind == G.P_BLINDS.bl_big
            and selected_blind
            and selected_blind.canlaugh_big_blind
        then
            blind = selected_blind
        end

        return set_blind_ref(self, blind, reset, silent, ...)
    end
end

if Blind and type(Blind.get_type) == "function" and not CL.alternate_big_blind_type_hook_installed then
    CL.alternate_big_blind_type_hook_installed = true
    local get_type_ref = Blind.get_type

    function Blind:get_type(...)
        local blind = self.config and self.config.blind

        if blind and blind.canlaugh_big_blind then
            return "Big"
        end

        return get_type_ref(self, ...)
    end
end

if G and G.FUNCS and type(G.FUNCS.select_blind) == "function" and not CL.alternate_big_blind_select_hook_installed then
    CL.alternate_big_blind_select_hook_installed = true
    local select_blind_ref = G.FUNCS.select_blind

    function G.FUNCS.select_blind(e, ...)
        local game = G and G.GAME
        local selected_blind = e and e.config and e.config.ref_table

        if game then
            game.canlaugh_selected_alternate_big = nil

            if game.blind_on_deck == "Big"
                and selected_blind
                and selected_blind.canlaugh_big_blind
            then
                game.canlaugh_selected_alternate_big = selected_blind.key
                e.config.ref_table = G.P_BLINDS.bl_big
            end
        end

        return select_blind_ref(e, ...)
    end
end

function CL.big_blind_roll(trigger_obj, seed, identifier)
    if SMODS and type(SMODS.pseudorandom_probability) == "function" then
        return SMODS.pseudorandom_probability(trigger_obj, seed, 1, 6, identifier)
    end

    if type(pseudorandom) == "function" and type(pseudoseed) == "function" then
        return pseudorandom(pseudoseed(seed)) < (1 / 6)
    end

    return math.random(6) == 1
end

function CL.big_blind_random(cards, seed)
    if not cards or #cards == 0 then
        return nil
    end

    if type(pseudorandom_element) == "function" and type(pseudoseed) == "function" then
        return pseudorandom_element(cards, pseudoseed(seed))
    end

    return cards[math.random(#cards)]
end

function CL.refresh_big_blind_debuffs()
    local blind = G and G.GAME and G.GAME.blind

    if not blind or type(blind.debuff_card) ~= "function" then
        return
    end

    for _, card in ipairs(G.playing_cards or {}) do
        blind:debuff_card(card)
    end
end

function CL.refresh_big_blind_goal()
    if not (G and G.FUNCS and G.hand_text_area and G.HUD_blind) then
        return
    end

    local blind_chips = G.hand_text_area.blind_chips

    if not blind_chips then
        return
    end

    if type(G.FUNCS.blind_chip_UI_scale) == "function" then
        G.FUNCS.blind_chip_UI_scale(blind_chips)
    end

    G.HUD_blind:recalculate()
    blind_chips:juice_up()
end

function CL.pick_alternate_big_blind()
    local game = G and G.GAME
    local choices = game and game.round_resets and game.round_resets.blind_choices

    if not choices then
        return
    end

    local ante = game.round_resets.ante or 1

    if game.canlaugh_alternate_big_blind_ante == ante then
        return
    end

    local previous_choice = game.canlaugh_alternate_big_blind_choice

    if choices.Big ~= "bl_big" and choices.Big ~= previous_choice then
        return
    end

    local roll_seed = "canlaugh_alternate_big_blind_roll_" .. tostring(ante)
    local replace_big

    if type(pseudorandom) == "function" and type(pseudoseed) == "function" then
        replace_big = pseudorandom(pseudoseed(roll_seed)) < 0.25
    else
        replace_big = math.random(4) == 1
    end

    if not replace_big then
        choices.Big = "bl_big"
        game.canlaugh_alternate_big_blind_choice = choices.Big
        game.canlaugh_alternate_big_blind_ante = ante
        return
    end

    local candidates = {}

    for key, blind in pairs(G.P_BLINDS or {}) do
        local allowed = blind.canlaugh_big_blind
            and (not game.banned_keys or not game.banned_keys[key])

        if allowed and not blind.canlaugh_big_blind and type(blind.in_pool) == "function" then
            allowed = blind:in_pool()
        end

        if allowed then
            candidates[#candidates + 1] = key
        end
    end

    table.sort(candidates)

    local choice = CL.big_blind_random(
        candidates,
        "canlaugh_alternate_big_blind_choice_" .. tostring(ante)
    )

    if choice then
        choices.Big = choice
    else
        choices.Big = "bl_big"
    end

    game.canlaugh_alternate_big_blind_choice = choices.Big
    game.canlaugh_alternate_big_blind_ante = ante
end

if type(reset_blinds) == "function" and not CL.alternate_big_blind_reset_hook_installed then
    CL.alternate_big_blind_reset_hook_installed = true
    local reset_blinds_ref = reset_blinds

    function reset_blinds(...)
        local results = { reset_blinds_ref(...) }
        CL.pick_alternate_big_blind()
        return unpack(results)
    end
end

if Game and type(Game.start_run) == "function" and not CL.alternate_big_blind_start_hook_installed then
    CL.alternate_big_blind_start_hook_installed = true
    local start_run_ref = Game.start_run

    function Game:start_run(args, ...)
        local results = { start_run_ref(self, args, ...) }

        if not (args and args.savetext) then
            CL.pick_alternate_big_blind()
        end

        return unpack(results)
    end
end
