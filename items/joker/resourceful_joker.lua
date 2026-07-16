local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

if SMODS and type(SMODS.add_card) == "function" and not CL.resourceful_forced_black_hole_bypass then
    CL.resourceful_forced_black_hole_bypass = true
    local canlaugh_resourceful_add_card_ref = SMODS.add_card

    function SMODS.add_card(args)
        local forced_black_hole = args
            and args.key == "c_black_hole"
            and args.bypass_discovery_center
            and args.allow_duplicates
            and G and G.GAME and G.GAME.banned_keys

        if not forced_black_hole then
            return canlaugh_resourceful_add_card_ref(args)
        end

        local old_ban = G.GAME.banned_keys.c_black_hole
        G.GAME.banned_keys.c_black_hole = nil
        local results = { pcall(canlaugh_resourceful_add_card_ref, args) }
        G.GAME.banned_keys.c_black_hole = old_ban

        if not results[1] then error(results[2]) end
        table.remove(results, 1)
        return unpack(results)
    end
end

SMODS.Atlas({
    key = "resourceful_joker",
    path = "resourceful_joker.png",
    px = 69,
    py = 93,
})

local function canlaugh_play_resourceful_sound()
    local native_sound = CL.native_sound
    if not (native_sound and type(native_sound.play) == "function") then return end

    local ok, source, err = pcall(native_sound.play, "sfx_resourcefuljoker.ogg", {
        pitch = 1,
        volume = 0.25,
        source_type = "static",
    })
    if (not ok or not source) and type(sendErrorMessage) == "function" then
        sendErrorMessage("[Canned Laughter] Failed to play Resourceful Joker sound: " .. tostring(ok and err or source))
    end
end

local function canlaugh_resourceful_state()
    G.GAME.canlaugh_resourceful = G.GAME.canlaugh_resourceful or { entries = {} }
    G.GAME.canlaugh_resourceful.entries = G.GAME.canlaugh_resourceful.entries or {}
    return G.GAME.canlaugh_resourceful
end

function CL.resourceful_ban_active(key)
    local state = G and G.GAME and G.GAME.canlaugh_resourceful

    for _, entry in ipairs(state and state.entries or {}) do
        if entry.key == key and entry.active and not entry.was_banned then
            return true
        end
    end

    return false
end

local function canlaugh_resourceful_upgraded()
    local profile = G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    if profile and profile.canlaugh_past_the_curtain then return true end
    local earned = G and G.SETTINGS and G.SETTINGS.ACHIEVEMENTS_EARNED
    return earned and (earned.past_the_curtain or earned.ach_canlaugh_past_the_curtain) or false
end

local function canlaugh_resourceful_slots()
    return canlaugh_resourceful_upgraded() and 3 or 1
end

local function canlaugh_is_consumable_card(card)
    local center = card and card.config and card.config.center

    return center
        and (center.consumeable
            or (SMODS and SMODS.ConsumableTypes and SMODS.ConsumableTypes[center.set]))
end

local function canlaugh_consumable_name(key)
    if key and G and G.P_CENTERS and G.P_CENTERS[key] then
        return localize({ type = "name_text", set = G.P_CENTERS[key].set, key = key })
    end

    return "None"
end

local function canlaugh_resourceful_shop_is_open()
    return G and G.shop ~= nil
end

local function canlaugh_restore_resourceful_entry(entry)
    if not (entry and entry.key and G and G.GAME and G.GAME.banned_keys) then return end
    if entry.was_banned then G.GAME.banned_keys[entry.key] = true
    else G.GAME.banned_keys[entry.key] = nil end
end

local function canlaugh_activate_resourceful_ban(entry)
    if not (entry and entry.key and G and G.GAME and G.GAME.banned_keys) then
        return
    end

    entry.was_banned = G.GAME.banned_keys[entry.key] and true or false
    entry.pending = nil
    entry.active = true
    G.GAME.banned_keys[entry.key] = true
end

local function canlaugh_clear_resourceful_ban(preserve_ante_holds)
    if not (G and G.GAME) then
        return
    end

    local state = G.GAME.canlaugh_resourceful
    local kept = {}
    local ante = G.GAME.round_resets and G.GAME.round_resets.ante
    for _, entry in ipairs(state and state.entries or {}) do
        if preserve_ante_holds and entry.hold_ante ~= nil and entry.hold_ante == ante then
            kept[#kept + 1] = entry
        else
            if entry.active then canlaugh_restore_resourceful_entry(entry) end
        end
    end

    if #kept > 0 then
        state.entries = kept
    else
        G.GAME.canlaugh_resourceful = nil
    end
end

local function canlaugh_set_resourceful_ban(key, defer_until_current_shop_exits)
    if not (key and G and G.GAME and G.GAME.banned_keys) then
        return
    end

    local state = canlaugh_resourceful_state()
    for i = #state.entries, 1, -1 do
        if state.entries[i].key == key then
            local old = table.remove(state.entries, i)
            if old.active then canlaugh_restore_resourceful_entry(old) end
        end
    end
    while #state.entries >= canlaugh_resourceful_slots() do
        local old = table.remove(state.entries, 1)
        if old.active then canlaugh_restore_resourceful_entry(old) end
    end

    local entry = {
        key = key,
        hold_ante = key == "c_black_hole"
            and G.GAME.round_resets and G.GAME.round_resets.ante or nil,
    }
    state.entries[#state.entries + 1] = entry

    if defer_until_current_shop_exits then
        entry.pending = true
        return
    end

    canlaugh_activate_resourceful_ban(entry)
end

local function canlaugh_holds_black_hole(card)
    for _, key in ipairs(card and card.ability and card.ability.extra and card.ability.extra.current_keys or {}) do
        if key == "c_black_hole" then return true end
    end
    return false
end

local function canlaugh_start_black_hole_pulse(card)
    if not (card and type(juice_card_until) == "function") then return end
    if card.canlaugh_black_hole_pulsing then return end
    card.canlaugh_black_hole_pulsing = true
    juice_card_until(card, function()
        local active = card
            and not card.getting_sliced
            and canlaugh_holds_black_hole(card)
            and CL.infuriating_all_collected
            and CL.infuriating_all_collected()
        if not active and card then card.canlaugh_black_hole_pulsing = nil end
        return active
    end, true)
end

local function canlaugh_resourceful_current_names(card)
    local keys = card and card.ability and card.ability.extra and card.ability.extra.current_keys or {}
    local names = {}
    for _, key in ipairs(keys or {}) do names[#names + 1] = canlaugh_consumable_name(key) end
    return #names > 0 and table.concat(names, ", ") or "None"
end

local function canlaugh_infuriating_candidates()
    local candidates = {}
    for id, def in pairs(CL.infuriating_tags or {}) do
        local center = G and G.P_CENTERS and G.P_CENTERS[def.center_key]
        if center and center.discovered and not CL.infuriating_collected(id) then
            candidates[#candidates + 1] = def.tag_key
        end
    end
    table.sort(candidates)
    return candidates
end

local function canlaugh_create_infuriating_tag(card)
    local candidates = canlaugh_infuriating_candidates()
    if #candidates == 0 then return end
    local denominator = CL.resourceful_component_denominator and CL.resourceful_component_denominator() or 50
    if not SMODS.pseudorandom_probability(card, "canlaugh_infuriating_tag", 1, denominator) then return end
    local key = pseudorandom_element(candidates, pseudoseed("canlaugh_infuriating_pick"))
    if key and type(add_tag) == "function" and Tag then
        add_tag(Tag(key))
        return { message = "Infuriated!", colour = G.C.FILTER }
    end
end

local function canlaugh_complete_past(card)
    if not (G and G.GAME and G.GAME.canlaugh_resourceful_past_pending) then return end
    G.GAME.canlaugh_resourceful_past_pending = nil
    G.GAME.round_resets.ante = 0

    local profile = CL.infuriating_profile and CL.infuriating_profile()
    if profile then
        profile.canlaugh_past_the_curtain = true
        if type(save_settings) == "function" then save_settings() end
    end
    if type(check_for_unlock) == "function" then
        check_for_unlock({ type = "canlaugh_past_the_curtain" })
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 2.0,
        func = function()
            if card and not card.removed then
                canlaugh_play_resourceful_sound()
                card.getting_sliced = true
                card:start_dissolve({ G.C.RED }, nil, 1.6)
            end
            return true
        end,
    }))
    G.E_MANAGER:add_event(Event({
        trigger = "after", delay = 2.4,
        func = function()
            if type(add_tag) == "function" and Tag then add_tag(Tag("tag_buffoon")) end
            return true
        end,
    }))
end

SMODS.Joker({
    key = "resourceful_joker",
    name = "Resourceful Joker",
    atlas = "resourceful_joker",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    config = {
        extra = {
            current_keys = {},
        },
    },
    loc_txt = {
        name = "Resourceful Joker",
        text = {
            "The last {C:attention}#1# consumable#2#{} you sold",
            "will {C:red}NOT{} appear in the next",
            "{C:attention}shop{} or its {C:attention}Booster Packs{}",
            "{C:inactive}(Currently {C:attention}#3#{C:inactive}){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        local keys = extra and extra.current_keys or {}

        for _, key in ipairs(keys) do
            if G and G.P_CENTERS and G.P_CENTERS[key] then
                CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS[key], card)
            end
        end

        local upgraded = canlaugh_resourceful_upgraded()
        return {
            key = upgraded
                and "j_canlaugh_resourceful_rat"
                or nil,
            vars = {
                canlaugh_resourceful_slots(),
                canlaugh_resourceful_slots() == 1 and "" or "s",
                canlaugh_resourceful_current_names(card),
                #canlaugh_infuriating_candidates(),
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.selling_card and canlaugh_is_consumable_card(context.card) then
            local key = context.card.config.center.key
            card.ability.extra.current_keys = card.ability.extra.current_keys or {}
            for i = #card.ability.extra.current_keys, 1, -1 do
                if card.ability.extra.current_keys[i] == key then table.remove(card.ability.extra.current_keys, i) end
            end
            card.ability.extra.current_keys[#card.ability.extra.current_keys + 1] = key
            while #card.ability.extra.current_keys > canlaugh_resourceful_slots() do
                table.remove(card.ability.extra.current_keys, 1)
            end
            canlaugh_set_resourceful_ban(key, canlaugh_resourceful_shop_is_open())

            if key == "c_black_hole" and CL.infuriating_all_collected and CL.infuriating_all_collected() then
                G.GAME.canlaugh_resourceful_past_pending = true
                canlaugh_start_black_hole_pulse(card)
            elseif not canlaugh_holds_black_hole(card) then
                G.GAME.canlaugh_resourceful_past_pending = nil
            end

            if key == "c_hanged_man" and type(check_for_unlock) == "function" then
                check_for_unlock({ type = "canlaugh_resourceful_hanged_man" })
            end

            return {
                message = "Blocked!",
                colour = G.C.FILTER,
            }
        end

        if context.after and not context.blueprint and not context.retrigger_joker then
            return canlaugh_create_infuriating_tag(card)
        end

        if context.setting_blind and canlaugh_holds_black_hole(card)
            and CL.infuriating_all_collected and CL.infuriating_all_collected() then
            G.GAME.canlaugh_resourceful_past_pending = true
            canlaugh_start_black_hole_pulse(card)
        end

        if context.end_of_round and context.beat_boss and not context.blueprint then
            canlaugh_complete_past(card)
        end

        if context.ending_shop then
            local state = G and G.GAME and G.GAME.canlaugh_resourceful

            local activated = false
            for _, entry in ipairs(state and state.entries or {}) do
                if entry.pending then
                    canlaugh_activate_resourceful_ban(entry)
                    activated = true
                end
            end
            if activated then
                return
            end

            canlaugh_clear_resourceful_ban(true)
            card.ability.extra.current_keys = {}
            for _, entry in ipairs(G.GAME.canlaugh_resourceful and G.GAME.canlaugh_resourceful.entries or {}) do
                card.ability.extra.current_keys[#card.ability.extra.current_keys + 1] = entry.key
            end
            if canlaugh_holds_black_hole(card)
                and CL.infuriating_all_collected and CL.infuriating_all_collected() then
                canlaugh_start_black_hole_pulse(card)
            end
        end
    end,
})
