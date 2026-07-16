local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_copy_table(t)
    local copy = {}
    for key, value in pairs(t or {}) do
        copy[key] = value
    end
    return copy
end

local function canlaugh_collection_colour(key, fallback)
    local ui = G.ACTIVE_MOD_UI and G.ACTIVE_MOD_UI.ui_config
    return ui and (ui[key] or ui[key:gsub("^collection_", "")]) or fallback
end

local function canlaugh_collection_back_func(args)
    if args and args.back_func then
        return args.back_func
    end

    return G.ACTIVE_MOD_UI and ("openModUI_" .. G.ACTIVE_MOD_UI.id) or "your_collection"
end

local function canlaugh_preview_front(context, item_set, center)
    if item_set == "Trial" or (item_set == "Edition" and center and not center.discovered) then
        return G.P_CARDS.empty
    end

    if context == "joker" then
        return G.P_CARDS.empty
    end

    return G.P_CARDS.S_A or G.P_CARDS.empty
end

local function canlaugh_preview_center(context, item_set, center)
    if item_set == "Edition" and center and not center.discovered then
        return center
    end

    if context == "joker" then
        if item_set == "Joker" then
            return center
        end
        return G.P_CENTERS.j_joker
    end

    if item_set == "Edition" or item_set == "Seal" then
        return G.P_CENTERS.c_base
    end

    return nil
end

local function canlaugh_mark_preview_card(card, center, item_set, context)
    card.canlaugh_collection_preview_center = center
    card.canlaugh_collection_preview_set = item_set
    card.canlaugh_collection_preview_context = context
    card.canlaugh_collection_preview_hidden = (item_set == "Edition" or item_set == "Trial") and center and not center.discovered or nil
    card.undiscovered = card.canlaugh_collection_preview_hidden or nil

    if context == "joker" then
        card.canlaugh_collection_joker_preview = true
    else
        card.canlaugh_collection_playing_card_preview = true
    end
end

local function canlaugh_set_preview_seal(card, center, context)
    if not (card and center and center.key and G.P_SEALS and G.P_SEALS[center.key]) then
        return
    end

    local joker_incompatible = context == "joker"
        and CL.can_joker_receive_seal
        and not CL.can_joker_receive_seal(card, center.key)

    if not joker_incompatible then
        card:set_seal(center.key, true, true)
    end

    if card.seal ~= center.key then
        card.seal = center.key
        card.ability = card.ability or {}
        card.ability.seal = {}
        for key, value in pairs(G.P_SEALS[center.key].config or {}) do
            card.ability.seal[key] = type(value) == "table" and canlaugh_copy_table(value) or value
        end
    end

    if joker_incompatible then
        card.debuff = true
    end

    if context ~= "joker" and CL.prepare_paired_seal_collection_card then
        CL.prepare_paired_seal_collection_card(card, center)
    end
end

local function canlaugh_apply_preview_item(card, center, item_set, context)
    if item_set == "Edition" then
        canlaugh_mark_preview_card(card, center, item_set, context)
        if center.discovered then
            card:set_edition(center.key, true, true)
        end
    elseif item_set == "Seal" then
        canlaugh_mark_preview_card(card, center, item_set, context)
        canlaugh_set_preview_seal(card, center, context)
    elseif item_set == "Trial" then
        canlaugh_mark_preview_card(card, center, item_set, context)
    end
end

local function canlaugh_collection_grid(pool, rows, args)
    args = args or {}
    args.w_mod = args.w_mod or 1
    args.h_mod = args.h_mod or 1
    args.card_scale = args.card_scale or 1

    local item_set = args.canlaugh_item_set
    local context = args.canlaugh_context or "card"
    local deck_tables = {}
    local collection_pool = args.raw_pool and (pool or {}) or SMODS.collection_pool(pool)
    local collection_areas = {}

    G.your_collection = collection_areas

    local cards_per_page = 0
    local row_totals = {}
    for j = 1, #rows do
        if cards_per_page >= #collection_pool and args.collapse_single_page then
            rows[j] = nil
        else
            row_totals[j] = cards_per_page
            cards_per_page = cards_per_page + rows[j]
            collection_areas[j] = CardArea(
                0,
                0,
                (args.w_mod * rows[j] + 0.25) * G.CARD_W,
                args.h_mod * G.CARD_H,
                { card_limit = rows[j], type = args.area_type or "title", highlight_limit = 0, collection = true }
            )
            deck_tables[#deck_tables + 1] = {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.07, no_fill = true },
                nodes = {
                    { n = G.UIT.O, config = { object = collection_areas[j] } },
                },
            }
        end
    end

    if cards_per_page <= 0 then
        cards_per_page = 1
    end

    local page_count = math.max(1, math.ceil(#collection_pool / cards_per_page))
    local options = {}
    for i = 1, page_count do
        options[#options + 1] = localize("k_page") .. " " .. tostring(i) .. "/" .. tostring(page_count)
    end

    local page_func = args.canlaugh_page_func or "canlaugh_collection_variant_page"
    G.FUNCS[page_func] = function(e)
        if not e or not e.cycle_config then
            return
        end

        for j = 1, #collection_areas do
            for i = #collection_areas[j].cards, 1, -1 do
                local card = collection_areas[j]:remove_card(collection_areas[j].cards[i])
                card:remove()
            end
        end

        for j = 1, #rows do
            for i = 1, rows[j] do
                local center = collection_pool[i + row_totals[j] + (cards_per_page * (e.cycle_config.current_option - 1))]
                if not center then
                    break
                end

                local card_center = canlaugh_preview_center(context, item_set, center) or center
                local card = Card(
                    0,
                    0,
                    G.CARD_W * args.card_scale,
                    G.CARD_H * args.card_scale,
                    args.canlaugh_preview_front or canlaugh_preview_front(context, item_set, center),
                    card_center,
                    args.canlaugh_bypass_discovery and {
                        bypass_discovery_center = true,
                        bypass_discovery_ui = true,
                    } or nil
                )

                canlaugh_apply_preview_item(card, center, item_set, context)

                if args.modify_card then
                    args.modify_card(card, center, i, j)
                end
                if not args.no_materialize then
                    card:start_materialize(nil, i > 1 or j > 1)
                end

                collection_areas[j]:emplace(card)
            end
        end

        for j = 1, #collection_areas do
            for _, card in ipairs(collection_areas[j].cards) do
                card:update_alert()
            end
        end
    end

    if G.E_MANAGER and Event then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.1,
            timer = "REAL",
            blocking = false,
            blockable = false,
            func = function()
                if G.FUNCS[page_func] then
                    G.FUNCS[page_func]({ cycle_config = { current_option = 1 } })
                end
                return true
            end,
        }))
    else
        G.FUNCS[page_func]({ cycle_config = { current_option = 1 } })
    end

    local grid_node = { n = G.UIT.R, config = { align = "cm", r = 0.1, colour = G.C.BLACK, emboss = 0.05 }, nodes = deck_tables }
    local page_node = (not args.hide_single_page or cards_per_page < #collection_pool) and {
        n = G.UIT.R,
        config = { align = "cm", padding = 0.04 },
        nodes = {
            create_option_cycle({
                options = options,
                w = 4.5,
                cycle_shoulders = true,
                opt_callback = page_func,
                current_option = 1,
                colour = canlaugh_collection_colour("collection_option_cycle_colour", G.C.RED),
                no_pips = true,
                focus_args = { snap_to = true, nav = "wide" },
            }),
        },
    } or nil

    local nodes = args.controls_before_grid
        and { page_node, args.mode_selector or nil, grid_node }
        or { grid_node, page_node, args.mode_selector or nil }

    return {
        n = G.UIT.C,
        config = { align = "cm", padding = args.grid_padding or 0 },
        nodes = nodes,
    }
end

local function canlaugh_collection_tabs(pool, rows, args)
    args = args or {}
    local item_set = args.canlaugh_item_set
    local mode = args.canlaugh_mode or "card"
    if mode ~= "joker" then
        mode = "card"
    end

    local card_args = canlaugh_copy_table(args)
    card_args.canlaugh_context = "card"
    card_args.canlaugh_page_func = "canlaugh_" .. string.lower(item_set) .. "_card_collection_page"

    local joker_args = canlaugh_copy_table(args)
    joker_args.canlaugh_context = "joker"
    joker_args.canlaugh_page_func = "canlaugh_" .. string.lower(item_set) .. "_joker_collection_page"

    local active_args = mode == "joker" and joker_args or card_args
    local open_cards_func = "canlaugh_" .. string.lower(item_set) .. "_collection_cards"
    local open_jokers_func = "canlaugh_" .. string.lower(item_set) .. "_collection_jokers"

    G.FUNCS[open_cards_func] = function()
        G.SETTINGS.paused = true
        G.FUNCS.overlay_menu({
            definition = item_set == "Edition"
                and create_UIBox_your_collection_editions("card")
                or create_UIBox_your_collection_seals("card"),
        })
    end

    G.FUNCS[open_jokers_func] = function()
        G.SETTINGS.paused = true
        G.FUNCS.overlay_menu({
            definition = item_set == "Edition"
                and create_UIBox_your_collection_editions("joker")
                or create_UIBox_your_collection_seals("joker"),
        })
    end

    active_args.mode_selector = {
        n = G.UIT.R,
        config = { align = "cm", padding = 0.04 },
        nodes = {
            {
                n = G.UIT.C,
                config = {
                    align = "cm",
                    padding = 0.03,
                    minw = 2.0,
                    minh = 0.55,
                    r = 0.1,
                    hover = mode ~= "card",
                    button = mode ~= "card" and open_cards_func or nil,
                    colour = mode == "card" and canlaugh_collection_colour("collection_option_cycle_colour", G.C.RED) or G.C.BLACK,
                    emboss = 0.05,
                },
                nodes = {
                    { n = G.UIT.T, config = { text = "Cards", scale = 0.38, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
                },
            },
            {
                n = G.UIT.C,
                config = {
                    align = "cm",
                    padding = 0.03,
                    minw = 2.0,
                    minh = 0.55,
                    r = 0.1,
                    hover = mode ~= "joker",
                    button = mode ~= "joker" and open_jokers_func or nil,
                    colour = mode == "joker" and canlaugh_collection_colour("collection_option_cycle_colour", G.C.RED) or G.C.BLACK,
                    emboss = 0.05,
                },
                nodes = {
                    { n = G.UIT.T, config = { text = "Jokers", scale = 0.38, colour = G.C.UI.TEXT_LIGHT, shadow = true } },
                },
            },
        },
    }

    return create_UIBox_generic_options({
        colour = canlaugh_collection_colour("collection_colour"),
        bg_colour = canlaugh_collection_colour("collection_bg_colour"),
        back_colour = canlaugh_collection_colour("collection_back_colour"),
        outline_colour = canlaugh_collection_colour("collection_outline_colour"),
        back_func = canlaugh_collection_back_func(args),
        snap_back = args.snap_back,
        infotip = args.infotip,
        contents = {
            {
                n = G.UIT.C,
                config = { padding = 0.08, align = "cm" },
                nodes = {
                    canlaugh_collection_grid(pool, canlaugh_copy_table(rows), active_args),
                },
            },
        },
    })
end

if Card and type(Card.generate_UIBox_ability_table) == "function" and not CL.collection_variant_tooltip_hook_installed then
    CL.collection_variant_tooltip_hook_installed = true
    local canlaugh_generate_UIBox_ability_table_ref = Card.generate_UIBox_ability_table

    local function canlaugh_generate_hidden_preview_ui(card, center, vars_only)
        local old_center = card.config and card.config.center
        local old_center_key = card.config and card.config.center_key
        local old_ability_set = card.ability and card.ability.set
        local old_ability_name = card.ability and card.ability.name
        local old_preview_center = card.canlaugh_collection_preview_center
        local old_preview_set = card.canlaugh_collection_preview_set
        local old_preview_context = card.canlaugh_collection_preview_context

        card.canlaugh_collection_preview_center = nil
        card.canlaugh_collection_preview_set = nil
        card.canlaugh_collection_preview_context = nil

        if card.config then
            card.config.center = center
            card.config.center_key = center.key
        end
        if card.ability then
            card.ability.set = center.set
            card.ability.name = center.name
        end

        local ok, results = pcall(function()
            return { canlaugh_generate_UIBox_ability_table_ref(card, vars_only) }
        end)

        card.canlaugh_collection_preview_center = old_preview_center
        card.canlaugh_collection_preview_set = old_preview_set
        card.canlaugh_collection_preview_context = old_preview_context

        if card.config then
            card.config.center = old_center
            card.config.center_key = old_center_key
        end
        if card.ability then
            card.ability.set = old_ability_set
            card.ability.name = old_ability_name
        end

        if not ok then
            error(results)
        end

        return unpack(results)
    end

    local function canlaugh_generate_negative_playing_card_ui(card, vars_only)
        local old_center = card.config and card.config.center
        local old_center_key = card.config and card.config.center_key
        local old_ability_set = card.ability and card.ability.set
        local old_ability_name = card.ability and card.ability.name
        local old_preview_center = card.canlaugh_collection_preview_center
        local old_preview_set = card.canlaugh_collection_preview_set
        local old_preview_context = card.canlaugh_collection_preview_context

        card.canlaugh_collection_preview_center = nil
        card.canlaugh_collection_preview_set = nil
        card.canlaugh_collection_preview_context = nil

        if card.config and G.P_CENTERS and G.P_CENTERS.c_base then
            card.config.center = G.P_CENTERS.c_base
            card.config.center_key = "c_base"
        end
        if card.ability then
            card.ability.set = "Default"
            card.ability.name = "Default Base"
        end

        local ok, results = pcall(function()
            return { canlaugh_generate_UIBox_ability_table_ref(card, vars_only) }
        end)

        card.canlaugh_collection_preview_center = old_preview_center
        card.canlaugh_collection_preview_set = old_preview_set
        card.canlaugh_collection_preview_context = old_preview_context

        if card.config then
            card.config.center = old_center
            card.config.center_key = old_center_key
        end
        if card.ability then
            card.ability.set = old_ability_set
            card.ability.name = old_ability_name
        end

        if not ok then
            error(results)
        end

        return unpack(results)
    end

    function Card:generate_UIBox_ability_table(vars_only)
        local center = self.canlaugh_collection_preview_center
        local item_set = self.canlaugh_collection_preview_set
        local context = self.canlaugh_collection_preview_context

        if center and not center.discovered and item_set == "Edition" and not vars_only then
            return canlaugh_generate_hidden_preview_ui(self, center, vars_only)
        end

        if center and not center.discovered and item_set == "Trial" and not vars_only then
            return generate_card_ui(center, nil, nil, "Undiscovered", nil, true, nil, nil, self)
        end

        if center
            and center.key == "e_negative"
            and item_set == "Edition"
            and context == "card"
            and center.discovered
            and not vars_only
        then
            return canlaugh_generate_negative_playing_card_ui(self, vars_only)
        end

        if center and item_set and not vars_only then
            return generate_card_ui(center, nil, nil, item_set, nil, nil, nil, nil, self)
        end

        return canlaugh_generate_UIBox_ability_table_ref(self, vars_only)
    end
end

if Card and type(Card.update_alert) == "function" and not CL.collection_variant_alert_hook_installed then
    CL.collection_variant_alert_hook_installed = true
    local canlaugh_update_alert_ref = Card.update_alert

    function Card:update_alert(...)
        local center = self.canlaugh_collection_preview_center
        if not (center and self.config) then
            return canlaugh_update_alert_ref(self, ...)
        end

        local old_center = self.config.center
        local old_center_key = self.config.center_key
        self.config.center = center
        self.config.center_key = center.key

        local results = { canlaugh_update_alert_ref(self, ...) }

        self.config.center = old_center
        self.config.center_key = old_center_key

        return unpack(results)
    end
end

if SMODS
    and SMODS.DrawSteps
    and SMODS.DrawSteps.center
    and type(SMODS.DrawSteps.center.func) == "function"
    and not CL.collection_variant_draw_hook_installed
then
    CL.collection_variant_draw_hook_installed = true
    local canlaugh_center_draw_ref = SMODS.DrawSteps.center.func

    SMODS.DrawSteps.center.func = function(card, layer)
        if card
            and card.canlaugh_collection_preview_hidden
            and card.canlaugh_collection_preview_set == "Edition"
            and card.canlaugh_collection_preview_context == "card"
            and card.ability
        then
            local old_set = card.ability.set

            card.ability.set = "Tarot"
            local ok, results = pcall(function()
                return { canlaugh_center_draw_ref(card, layer) }
            end)
            card.ability.set = old_set

            if not ok then
                error(results)
            end

            return unpack(results)
        end

        return canlaugh_center_draw_ref(card, layer)
    end
end

if SMODS and not CL.collection_variant_tabs_installed then
    CL.collection_variant_tabs_installed = true

    function create_UIBox_your_collection_editions(mode)
        return canlaugh_collection_tabs(G.P_CENTER_POOLS.Edition, { 5, 5 }, {
            canlaugh_item_set = "Edition",
            canlaugh_mode = mode,
            snap_back = true,
            h_mod = 1.03,
            infotip = localize("ml_edition_seal_enhancement_explanation"),
            hide_single_page = true,
            collapse_single_page = true,
        })
    end

    function create_UIBox_your_collection_seals(mode)
        return canlaugh_collection_tabs(G.P_CENTER_POOLS.Seal, { 5, 5 }, {
            canlaugh_item_set = "Seal",
            canlaugh_mode = mode,
            snap_back = true,
            infotip = localize("ml_edition_seal_enhancement_explanation"),
            hide_single_page = true,
            collapse_single_page = true,
            h_mod = 1.03,
        })
    end

    function create_UIBox_your_collection_tarots()
        return create_UIBox_generic_options({
            colour = canlaugh_collection_colour("collection_colour"),
            bg_colour = canlaugh_collection_colour("collection_bg_colour"),
            back_colour = canlaugh_collection_colour("collection_back_colour"),
            outline_colour = canlaugh_collection_colour("collection_outline_colour"),
            back_func = canlaugh_collection_back_func({}),
            snap_back = true,
            contents = {
                    {
                        n = G.UIT.C,
                        config = { padding = 0.08, align = "cm" },
                        nodes = {
                            canlaugh_collection_grid((G.P_CENTER_POOLS and G.P_CENTER_POOLS.Tarot) or {}, { 5, 6 }, {
                                canlaugh_item_set = "Tarot",
                                hide_single_page = true,
                                collapse_single_page = true,
                            }),
                    },
                },
            },
        })
    end

    G.FUNCS.your_collection_tarots = function()
        G.SETTINGS.paused = true
        G.FUNCS.overlay_menu({
            definition = create_UIBox_your_collection_tarots(),
        })
    end

    local canlaugh_refresh_trial_collection
    CL.trial_collection_view = CL.trial_collection_view or { mode = "trials", booster_kind = "Celestial" }

    local function canlaugh_trial_collection_grid(mode, booster_kind)
        local BT = CL.barter
        local pool = mode == "trials"
            and (BT and BT.trial_collection_pool and BT.trial_collection_pool(booster_kind) or {})
            or (BT and BT.representative_collection_pool and BT.representative_collection_pool(booster_kind) or {})
        local collection_rows = { 4, 3 }

        local buffoon_representatives = mode == "representatives" and booster_kind == "Buffoon"
        local spectral_representatives = mode == "representatives" and booster_kind == "Spectral"
        local grid_args = {
            raw_pool = true,
            canlaugh_item_set = mode == "trials" and "Trial" or (buffoon_representatives and "Joker" or "Tarot"),
            canlaugh_context = buffoon_representatives and "joker" or "card",
            canlaugh_bypass_discovery = buffoon_representatives or spectral_representatives,
            canlaugh_page_func = mode == "trials" and "canlaugh_trial_collection_page" or "canlaugh_representative_collection_page",
            back_func = "your_collection_other_gameobjects",
            hide_single_page = true,
            collapse_single_page = true,
            no_materialize = false,
            controls_before_grid = true,
        }

        if mode == "trials" then
            grid_args.modify_card = function(card, center)
                card.canlaugh_trial_card = true
                card.canlaugh_no_consumeable_use_button = true
                if card.ability then
                    card.ability.consumeable = false
                    card.ability.set = "Trial"
                end
                if center and not center.discovered and card.children and card.children.center then
                    local placeholder_set = center.canlaugh_placeholder_set or center.atlas or "Tarot"
                    local undiscovered = placeholder_set == "Planet" and G.p_undiscovered
                        or placeholder_set == "Joker" and G.j_undiscovered
                        or placeholder_set == "Spectral" and G.s_undiscovered
                        or G.t_undiscovered
                    if undiscovered then
                        card.children.center.atlas = G.ASSET_ATLAS[placeholder_set]
                        card.children.center:set_sprite_pos(undiscovered.pos)
                    end
                end
            end
        else
            grid_args.canlaugh_preview_front = G.P_CARDS.empty
            grid_args.modify_card = function(card, center)
                card.front_hidden = not buffoon_representatives
                local rep = BT and BT.collection_representative and BT.collection_representative(center, booster_kind)
                if rep then
                    card.canlaugh_barter_rep = rep
                    if buffoon_representatives then
                        card.bypass_discovery_center = true
                        card.bypass_discovery_ui = true
                    end
                    if card.ability then
                        card.ability.consumeable = false
                    end
                end
            end
        end

        return {
            n = G.UIT.C,
            config = { align = "tm", minw = 5.0, padding = 0 },
            nodes = { canlaugh_collection_grid(pool, collection_rows, grid_args) },
        }
    end

    canlaugh_refresh_trial_collection = function()
        local target = G.OVERLAY_MENU and G.OVERLAY_MENU:get_UIE_by_ID("canlaugh_trial_collection_grid")
        if not (target and target.config and target.config.object) then
            return false
        end

        target.config.object:remove()
        target.config.object = UIBox({
            definition = canlaugh_trial_collection_grid(CL.trial_collection_view.mode, CL.trial_collection_view.booster_kind),
            config = { align = "cm", parent = target },
        })
        return true
    end

    G.FUNCS.canlaugh_trial_collection_mode = function(e)
        CL.trial_collection_view.mode = e and e.cycle_config and e.cycle_config.current_option == 2
            and "representatives" or "trials"
        canlaugh_refresh_trial_collection()
    end

    G.FUNCS.canlaugh_trial_collection_category = function(e)
        local option = e and e.cycle_config and e.cycle_config.current_option or 1
        CL.trial_collection_view.booster_kind = option == 4 and "Buffoon"
            or option == 3 and "Spectral"
            or option == 2 and "Arcana" or "Celestial"
        canlaugh_refresh_trial_collection()
    end

    function create_UIBox_your_collection_trials(mode, booster_kind)
        CL.trial_collection_view.mode = mode == "representatives" and "representatives" or "trials"
        CL.trial_collection_view.booster_kind = booster_kind == "Spectral" and "Spectral"
            or booster_kind == "Buffoon" and "Buffoon"
            or booster_kind == "Arcana" and "Arcana" or "Celestial"

        local view = CL.trial_collection_view
        local menu = create_UIBox_generic_options({
            colour = canlaugh_collection_colour("collection_colour"),
            bg_colour = canlaugh_collection_colour("collection_bg_colour"),
            back_colour = canlaugh_collection_colour("collection_back_colour"),
            outline_colour = canlaugh_collection_colour("collection_outline_colour"),
            back_func = "your_collection_other_gameobjects",
            snap_back = true,
            minw = 14.4,
            contents = {
                {
                    n = G.UIT.C,
                    config = { align = "cm", minw = 14.4, minh = 7.0, padding = 0.15 },
                    nodes = {
                        {
                            n = G.UIT.C,
                            config = { align = "cm", minw = 5.2, minh = 7.0, padding = 0.01 },
                            nodes = {
                                {
                                    n = G.UIT.R,
                                    config = { align = "cm", padding = 0.01 },
                                    nodes = {
                                        create_option_cycle({
                                            options = { "Trials", "Representatives" },
                                            w = 4.5,
                                            cycle_shoulders = true,
                                            opt_callback = "canlaugh_trial_collection_mode",
                                            current_option = view.mode == "representatives" and 2 or 1,
                                            colour = canlaugh_collection_colour("collection_option_cycle_colour", G.C.RED),
                                            no_pips = true,
                                            focus_args = { snap_to = true, nav = "wide" },
                                        }),
                                    },
                                },
                                {
                                    n = G.UIT.R,
                                    config = { align = "cm", padding = 0.01 },
                                    nodes = {
                                        create_option_cycle({
                                            options = { "Celestial", "Arcane", "Spectral", "Buffoon" },
                                            w = 4.5,
                                            cycle_shoulders = true,
                                            opt_callback = "canlaugh_trial_collection_category",
                                            current_option = view.booster_kind == "Buffoon" and 4
                                                or view.booster_kind == "Spectral" and 3
                                                or view.booster_kind == "Arcana" and 2 or 1,
                                            colour = canlaugh_collection_colour("collection_option_cycle_colour", G.C.RED),
                                            no_pips = true,
                                            focus_args = { nav = "wide" },
                                        }),
                                    },
                                },
                            },
                        },
                        {
                            n = G.UIT.C,
                            config = { align = "cm", minw = 7.5, minh = 7.0, padding = 0 },
                            nodes = {
                                {
                                    n = G.UIT.O,
                                    config = {
                                        id = "canlaugh_trial_collection_grid",
                                        w = 8.25,
                                        h = 7.0,
                                        object = Moveable(),
                                    },
                                },
                            },
                        },
                    },
                },
            },
        })

        if G.E_MANAGER and Event then
            G.E_MANAGER:add_event(Event({
                func = function()
                    canlaugh_refresh_trial_collection()
                    return true
                end,
            }))
        end

        return menu
    end

    G.FUNCS.your_collection_trials = function()
        G.SETTINGS.paused = true
        G.FUNCS.overlay_menu({ definition = create_UIBox_your_collection_trials("trials") })
    end

    local function canlaugh_trial_collection_button()
        local tally = { tally = 0, of = 0 }
        local BT = CL.barter
        for _, center in ipairs(BT and BT.trial_collection_pool and BT.trial_collection_pool() or {}) do
            if not center.no_collection then
                tally.of = tally.of + 1
                if center.discovered then
                    tally.tally = tally.tally + 1
                end
            end
        end

        return UIBox_button({
            button = "your_collection_trials",
            label = { "Trials" },
            count = tally,
            minw = 5,
            id = "your_collection_trials",
        })
    end

    local mod = SMODS.current_mod
    if mod and not CL.trial_collection_tab_installed then
        CL.trial_collection_tab_installed = true
        local old_custom_collection_tabs = mod.custom_collection_tabs
        mod.custom_collection_tabs = function()
            local tabs = old_custom_collection_tabs and old_custom_collection_tabs() or {}
            tabs[#tabs + 1] = canlaugh_trial_collection_button()
            return tabs
        end
    end
end
