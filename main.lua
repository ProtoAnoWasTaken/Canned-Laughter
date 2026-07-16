G.C.CANNED_LAUGHTER = HEX("D45A73")
G.C.CANLAUGH_GLITTER = HEX("FF87F7")
G.C.CANLAUGH_PLASTIC = HEX("84AFB8")
G.C.CANLAUGH_PHOSPHATE = HEX("EB0000")
G.C.CANLAUGH_CALCITE = HEX("FEC35C")

SMODS.current_mod.optional_features = {
    object_weights = true,
    retrigger_joker = true,
    post_trigger = true,
    quantum_enhancements = true,
}

local CL_CONFIG_ROOT = SMODS.current_mod.config or {}
local CL_CONFIG = CL_CONFIG_ROOT.CannedLaughter or CL_CONFIG_ROOT

CannedLaughter = rawget(_G, "CannedLaughter") or {}

local CL = CannedLaughter

CL.config = CL_CONFIG
CL.mod_path = SMODS.current_mod.path
CL.item_sort_info_cache = CL.item_sort_info_cache or {}

local function cl_tooltip_identity(tooltip)
    if type(tooltip) ~= "table" then
        return tostring(tooltip)
    end

    local key = tooltip.key
    local set = tooltip.set

    if not set and type(key) == "string" and key:match("^e_") then
        set = "Edition"
    end

    return tostring(set or "") .. ":" .. tostring(key or tooltip.name or tooltip.label or tooltip)
end

local function cl_card_tooltip_identities(card)
    local identities = {}

    if card and card.edition and card.edition.key then
        identities["Edition:" .. tostring(card.edition.key)] = true
    end

    if card and card.seal then
        local seal_key = tostring(card.seal)
        identities["Seal:" .. seal_key] = true
        identities[": " .. seal_key] = true
    end

    return identities
end

function CL.add_unique_tooltip(info_queue, tooltip, card)
    if not (info_queue and tooltip) then
        return false
    end

    local identity = cl_tooltip_identity(tooltip)
    local card_identities = cl_card_tooltip_identities(card)

    if card_identities[identity] then
        return false
    end

    for _, existing in ipairs(info_queue) do
        if cl_tooltip_identity(existing) == identity then
            return false
        end
    end

    info_queue[#info_queue + 1] = tooltip
    return true
end

function CL.dedupe_tooltip_queue(info_queue, card)
    if type(info_queue) ~= "table" then
        return
    end

    local current_mt = getmetatable(info_queue)
    if current_mt and current_mt.canlaugh_dedupe_tooltips then
        return
    end

    local seen = {}
    for _, existing in ipairs(info_queue) do
        seen[cl_tooltip_identity(existing)] = true
    end

    local previous_newindex = current_mt and current_mt.__newindex
    local mt = {}

    if current_mt then
        for key, value in pairs(current_mt) do
            mt[key] = value
        end
    end

    mt.canlaugh_dedupe_tooltips = true
    mt.__newindex = function(t, key, value)
        if type(key) == "number" and type(value) == "table" then
            local identity = cl_tooltip_identity(value)

            if seen[identity] then
                return
            end

            seen[identity] = true
        end

        if type(previous_newindex) == "function" then
            previous_newindex(t, key, value)
        elseif type(previous_newindex) == "table" then
            previous_newindex[key] = value
        else
            rawset(t, key, value)
        end
    end

    setmetatable(info_queue, mt)
end

local function cl_wrap_generate_ui(object)
    if not object or type(object.generate_ui) ~= "function" or object.canlaugh_tooltip_dedupe_wrapped then
        return
    end

    object.canlaugh_tooltip_dedupe_wrapped = true
    local generate_ui_ref = object.generate_ui

    object.generate_ui = function(self, info_queue, card, ...)
        CL.dedupe_tooltip_queue(info_queue, card)
        return generate_ui_ref(self, info_queue, card, ...)
    end
end

cl_wrap_generate_ui(SMODS.Center)
cl_wrap_generate_ui(SMODS.Booster)
cl_wrap_generate_ui(SMODS.Edition)
cl_wrap_generate_ui(SMODS.Enhancement)

if type(loc_colour) == "function" and not CL.edition_colour_hook_installed then
    CL.edition_colour_hook_installed = true
    local cl_loc_colour_ref = loc_colour

    function loc_colour(colour_key, default)
        if colour_key == "canned_laughter" then
            return G.C.CANNED_LAUGHTER or default
        end
        if colour_key == "canlaugh_glitter" then
            return G.C.CANLAUGH_GLITTER or default
        end
        if colour_key == "canlaugh_plastic" then
            return G.C.CANLAUGH_PLASTIC or default
        end
        if colour_key == "canlaugh_shadow" then
            return G.C.CANLAUGH_SHADOW or default
        end
        if colour_key == "canlaugh_phosphate" then
            return G.C.CANLAUGH_PHOSPHATE or default
        end
        if colour_key == "canlaugh_calcite" then
            return G.C.CANLAUGH_CALCITE or default
        end

        return cl_loc_colour_ref(colour_key, default)
    end
end

local MOD_ID = "Canned Laughter"
local FS_PREFIX = "Mods/" .. MOD_ID .. "/"

local function cl_parse_named_sort_infos(rel_path, fs_item_path)
    local contents = love.filesystem.read(fs_item_path)
    if not contents then
        return {}
    end

    local sort_infos = {}
    local source_index = 0

    for _, object_type in ipairs({
        "Joker",
        "Back",
        "Blind",
        "Seal",
        "Voucher",
        "Tarot",
        "Spectral",
        "Booster",
        "Tag",
        "Achievement",
        "Challenge",
        "Consumable",
        "Edition",
        "Enhancement",
        "ObjectType",
    }) do
        for block in contents:gmatch("SMODS%." .. object_type .. "%s*%(%s*(%b{})") do
            source_index = source_index + 1
            local rarity = tonumber(block:match("rarity%s*=%s*(%d+)")) or 999
            local order = tonumber(block:match("order%s*=%s*(%-?%d+%.?%d*)"))
            local name = block:match("name%s*=%s*'([^']+)'")
                or block:match('name%s*=%s*"([^"]+)"')
                or block:match("loc_txt%s*=%s*%b{}.-name%s*=%s*'([^']+)'")
                or block:match('loc_txt%s*=%s*%b{}.-name%s*=%s*"([^"]+)"')
                or rel_path
            local key = block:match("key%s*=%s*'([^']+)'") or block:match('key%s*=%s*"([^"]+)"')

            if key then
                sort_infos[#sort_infos + 1] = {
                    rel_path = rel_path,
                    source_index = source_index,
                    key = key,
                    object_type = object_type,
                    order = order,
                    rarity = rarity,
                    name = name:lower(),
                }
            end
        end
    end

    return sort_infos
end

local function cl_get_item_sort_infos(rel_path, fs_item_path)
    local cache_key = rel_path:lower()
    if CL.item_sort_info_cache[cache_key] ~= nil then
        return CL.item_sort_info_cache[cache_key] or {}
    end

    local sort_infos = cl_parse_named_sort_infos(rel_path, fs_item_path)
    CL.item_sort_info_cache[cache_key] = sort_infos
    return sort_infos
end

local function cl_get_item_sort_info(rel_path, fs_item_path)
    local sort_infos = cl_get_item_sort_infos(rel_path, fs_item_path)
    return sort_infos[1]
end

local function cl_compare_item_sort_info(a, b)
    if a.object_type ~= b.object_type then
        return tostring(a.object_type) < tostring(b.object_type)
    end

    if a.order or b.order then
        local order_a = a.order or 999999
        local order_b = b.order or 999999
        if order_a ~= order_b then
            return order_a < order_b
        end
    end

    if a.rarity ~= b.rarity then
        return a.rarity < b.rarity
    end

    if a.rel_path == b.rel_path and a.source_index ~= b.source_index then
        return a.source_index < b.source_index
    end

    if a.name ~= b.name then
        return a.name < b.name
    end

    return a.rel_path:lower() < b.rel_path:lower()
end

local function cl_get_collection_mod(center)
    local mod = center and (center.mod or center.original_mod)
    if not mod or mod.id == "Balatro" or mod.id == "Steamodded" then
        return nil
    end
    return mod
end

local function cl_get_collection_mod_priority(mod)
    return tonumber(mod and mod.priority)
        or tonumber(mod and mod.manifest and mod.manifest.priority)
        or 0
end

local function cl_get_collection_sort_rarity(center)
    return tonumber(center and center.rarity) or 999
end

local function cl_get_collection_sort_name(center)
    return tostring((center and (center.name or center.original_key or center.key)) or ""):lower()
end

local function cl_is_showdown_blind(center)
    return center and (center.canlaugh_showdown or (center.boss and center.boss.showdown))
end

local function cl_compare_collection_entries(a, b)
    if a.mod ~= b.mod then
        if not a.mod then
            return true
        end
        if not b.mod then
            return false
        end

        local priority_a = cl_get_collection_mod_priority(a.mod)
        local priority_b = cl_get_collection_mod_priority(b.mod)
        if priority_a ~= priority_b then
            return priority_a < priority_b
        end

        local id_a = tostring(a.mod.id or "")
        local id_b = tostring(b.mod.id or "")
        if id_a ~= id_b then
            return id_a < id_b
        end
    end

    if (a.center.canlaugh_boss and b.center.canlaugh_boss) or (a.mod and b.mod and tostring(a.mod.id or a.mod) == tostring(b.mod.id or b.mod) and (a.center.boss or a.center.canlaugh_showdown) and (b.center.boss or b.center.canlaugh_showdown)) then
        local showdown_a = cl_is_showdown_blind(a.center)
        local showdown_b = cl_is_showdown_blind(b.center)
        if showdown_a ~= showdown_b then return not showdown_a end
    end

    if a.mod and b.mod then
        local rarity_a = cl_get_collection_sort_rarity(a.center)
        local rarity_b = cl_get_collection_sort_rarity(b.center)
        if rarity_a ~= rarity_b then
            return rarity_a < rarity_b
        end

        local name_a = cl_get_collection_sort_name(a.center)
        local name_b = cl_get_collection_sort_name(b.center)
        if name_a ~= name_b then
            return name_a < name_b
        end
    end

    return a.index < b.index
end

local function cl_reorder_center_pool(pool)
    if type(pool) ~= "table" or not pool[1] then
        return
    end

    if pool[1].set == "Voucher" then
        return
    end

    local entries = {}
    for index, center in ipairs(pool) do
        entries[index] = {
            center = center,
            mod = cl_get_collection_mod(center),
            index = index,
        }
    end

    table.sort(entries, cl_compare_collection_entries)

    local mod_counts = {}
    for index, entry in ipairs(entries) do
        if entry.mod then
            local mod_key = tostring(entry.mod.id or entry.mod)
            mod_counts[mod_key] = (mod_counts[mod_key] or 0) + 1
            entry.center.order = 1000000000 + cl_get_collection_mod_priority(entry.mod) + (mod_counts[mod_key] / 10000)
        end
        pool[index] = entry.center
    end
end

local function cl_reorder_keyed_collection(collection)
    if type(collection) ~= "table" then
        return
    end

    local entries = {}
    for key, center in pairs(collection) do
        local mod = cl_get_collection_mod(center)
        if mod or center.canlaugh_boss then
            entries[#entries + 1] = {
                center = center,
                mod = mod,
                index = tonumber(center.order) or #entries + 1,
                key = tostring(key),
            }
        end
    end

    table.sort(entries, function(a, b)
        if cl_compare_collection_entries(a, b) then
            return true
        end
        if cl_compare_collection_entries(b, a) then
            return false
        end
        return a.key < b.key
    end)

    for index, entry in ipairs(entries) do
        entry.center.order = 1000000000 + cl_get_collection_mod_priority(entry.mod) + (index / 10000)
    end
end

local function cl_normalize_collection_order()
    if G and G.P_CENTER_POOLS then
        for _, pool in pairs(G.P_CENTER_POOLS) do
            cl_reorder_center_pool(pool)
        end
    end

    cl_reorder_keyed_collection(G and G.P_TAGS)
    cl_reorder_keyed_collection(G and G.P_BLINDS)
end

local function cl_recheck_unlocks()
    if type(check_for_unlock) ~= "function" then
        return
    end

    local fired = {}
    CL.unlock_recheck_failures = CL.unlock_recheck_failures or {}

    local function fire_unlock(args)
        if not (G and G.GAME) then
            return
        end

        local unlock_type = args and args.type
        if not unlock_type or fired[unlock_type] then
            return
        end

        fired[unlock_type] = true
        local ok, err = pcall(check_for_unlock, args)
        if not ok and not CL.unlock_recheck_failures[unlock_type] then
            CL.unlock_recheck_failures[unlock_type] = true
            if type(sendErrorMessage) == "function" then
                sendErrorMessage("[Canned Laughter] Unlock recheck failed for " .. tostring(unlock_type) .. ": " .. tostring(err))
            end
        end
    end

    if G and G.DISCOVER_TALLIES and G.DISCOVER_TALLIES.total then
        fire_unlock({
            type = "discover_amount",
            amount = G.DISCOVER_TALLIES.total.tally or 0,
        })
    end

    local earned = {}

    if G and G.ACHIEVEMENTS then
        for achievement_key, achievement in pairs(G.ACHIEVEMENTS) do
            if achievement
                and achievement.earned
                and type(achievement_key) == "string"
                and achievement_key:match("^ach_canlaugh_")
            then
                earned[achievement_key] = true
            end
        end
    end

    if G and G.SETTINGS and G.SETTINGS.ACHIEVEMENTS_EARNED then
        for achievement_key, is_earned in pairs(G.SETTINGS.ACHIEVEMENTS_EARNED) do
            if is_earned
                and type(achievement_key) == "string"
                and achievement_key:match("^ach_canlaugh_")
            then
                earned[achievement_key] = true
            end
        end
    end

    for achievement_key in pairs(earned) do
        fire_unlock({ type = achievement_key })
    end

    if G
        and G.PROFILES
        and G.SETTINGS
        and G.PROFILES[G.SETTINGS.profile]
        and G.PROFILES[G.SETTINGS.profile].voucher_usage
    then
        fire_unlock({ type = "run_redeem" })
    end

    local profile = G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    if profile and profile.canlaugh_earthsea_borealis_defeated then
        fire_unlock({ type = "canlaugh_earthsea_borealis_defeated" })
    end

    for _, deck_key in ipairs({ "b_red", "b_blue", "b_yellow", "b_green" }) do
        local usage = profile and profile.deck_usage and profile.deck_usage[deck_key]
        if usage and (next(usage.wins_by_key or {}) or next(usage.wins or {})) then
            pcall(check_for_unlock, { type = "win_deck", deck = deck_key })
        end
    end

end

local function cl_install_unlock_recheck_hook()
    if not SMODS or type(SMODS.SAVE_UNLOCKS) ~= "function" or CL.unlock_recheck_hook_installed then
        return
    end

    CL.unlock_recheck_hook_installed = true
    local cl_save_unlocks_ref = SMODS.SAVE_UNLOCKS

    function SMODS.SAVE_UNLOCKS(...)
        local results = { cl_save_unlocks_ref(...) }
        cl_recheck_unlocks()
        return unpack(results)
    end
end

local function load_folder(rel_folder)
    local fs_path = FS_PREFIX .. rel_folder
    if not love.filesystem.getInfo(fs_path) then
        return
    end

    local items = love.filesystem.getDirectoryItems(fs_path)
    table.sort(items, function(a, b)
        local rel_a = rel_folder .. "/" .. a
        local rel_b = rel_folder .. "/" .. b
        local fs_a = FS_PREFIX .. rel_a
        local fs_b = FS_PREFIX .. rel_b
        local info_a = love.filesystem.getInfo(fs_a)
        local info_b = love.filesystem.getInfo(fs_b)

        if info_a and info_b and info_a.type ~= info_b.type then
            return info_a.type == "directory"
        end

        local sort_a = cl_get_item_sort_info(rel_a, fs_a)
        local sort_b = cl_get_item_sort_info(rel_b, fs_b)

        if sort_a and sort_b then
            return cl_compare_item_sort_info(sort_a, sort_b)
        end

        return a:lower() < b:lower()
    end)

    for _, item in ipairs(items) do
        local rel_path = rel_folder .. "/" .. item
        local fs_item_path = FS_PREFIX .. rel_path
        local info = love.filesystem.getInfo(fs_item_path)

        if info then
            if info.type == "file" and item:lower():match("%.lua$") then
                local init, err = SMODS.load_file(rel_path)
                if init then
                    local ok, result = pcall(init)
                    if not ok then
                        sendErrorMessage("[Canned Laughter] Error in " .. rel_path .. ": " .. tostring(result))
                    end
                else
                    sendErrorMessage("[Canned Laughter] Failed to load " .. rel_path .. ": " .. tostring(err))
                end
            elseif info.type == "directory" then
                load_folder(rel_path)
            end
        end
    end
end

load_folder("localization")
load_folder("items")
cl_normalize_collection_order()
cl_install_unlock_recheck_hook()

if type(set_main_menu_UI) == "function" and not CL.main_menu_unlock_recheck_hook_installed then
    CL.main_menu_unlock_recheck_hook_installed = true
    local cl_set_main_menu_ui_ref = set_main_menu_UI

    function set_main_menu_UI(...)
        local results = { cl_set_main_menu_ui_ref(...) }
        cl_recheck_unlocks()
        return unpack(results)
    end
end

if G and G.UIDEF and type(G.UIDEF.run_setup_option) == "function" and not CL.run_setup_order_hook_installed then
    CL.run_setup_order_hook_installed = true
    local cl_run_setup_option_ref = G.UIDEF.run_setup_option

    function G.UIDEF.run_setup_option(...)
        cl_normalize_collection_order()
        return cl_run_setup_option_ref(...)
    end
end

if type(create_UIBox_your_collection_blinds) == "function" and not CL.blind_collection_order_hook_installed then
    CL.blind_collection_order_hook_installed = true
    local cl_create_blind_collection_ref = create_UIBox_your_collection_blinds

    function create_UIBox_your_collection_blinds(...)
        cl_normalize_collection_order()
        return cl_create_blind_collection_ref(...)
    end
end

if Card and type(Card.hover) == "function" and not CL.collection_edition_alert_hook_installed then
    CL.collection_edition_alert_hook_installed = true
    local cl_card_hover_ref = Card.hover

    function Card:hover(...)
        local results = { cl_card_hover_ref(self, ...) }
        local edition = self.edition
        local edition_key = edition and (edition.key or (edition.type and "e_" .. edition.type))
        local edition_center = edition_key and G and G.P_CENTERS and G.P_CENTERS[edition_key]

        if self.area and self.area.config.collection and edition_center and edition_center.discovered and not edition_center.alerted then
            edition_center.alerted = true
            G:save_progress()
        end

        return unpack(results)
    end
end
