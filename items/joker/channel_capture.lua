local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "channel_capture",
    path = "channel_capture.png",
    px = 69,
    py = 93,
})

local function canlaugh_channel_capture_copy(value)
    if type(value) ~= "table" then
        return value
    end

    if type(copy_table) == "function" then
        return copy_table(value)
    end

    local copied = {}
    for key, entry in pairs(value) do
        copied[key] = canlaugh_channel_capture_copy(entry)
    end
    return copied
end

local function canlaugh_channel_capture_track_taken_tag(tag)
    if not (G and G.GAME and tag and tag.key) then
        return
    end

    G.GAME.canlaugh_channel_capture_last_taken_tag = {
        key = tag.key,
        ability = canlaugh_channel_capture_copy(tag.ability),
    }
end

local function canlaugh_channel_capture_saved_tag(tag)
    if not (tag and tag.key) then
        return nil
    end

    return {
        key = tag.key,
        ability = canlaugh_channel_capture_copy(tag.ability),
    }
end

local function canlaugh_channel_capture_last_tag()
    local last_taken_tag = G and G.GAME and G.GAME.canlaugh_channel_capture_last_taken_tag
    if last_taken_tag and last_taken_tag.key then
        return last_taken_tag
    end

    local tags = G and G.GAME and G.GAME.tags
    for index = #(tags or {}), 1, -1 do
        local tag = tags[index]
        if tag and tag.key and not tag.triggered then
            return canlaugh_channel_capture_saved_tag(tag)
        end
    end

    return nil
end

if type(add_tag) == "function" and not CL.channel_capture_add_tag_hook_installed then
    CL.channel_capture_add_tag_hook_installed = true
    local add_tag_ref = add_tag

    function add_tag(tag, ...)
        local tags = G and G.GAME and G.GAME.tags
        local tag_count = #(tags or {})
        local results = { add_tag_ref(tag, ...) }

        if tags and #tags > tag_count then
            canlaugh_channel_capture_track_taken_tag(tags[#tags])
        else
            canlaugh_channel_capture_track_taken_tag(tag)
        end

        return unpack(results)
    end
end

local function canlaugh_channel_capture_is_boss()
    local blind = G and G.GAME and G.GAME.blind

    return blind
        and (
            blind.boss
            or (type(blind.get_type) == "function" and blind:get_type() == "Boss")
        )
end

local function canlaugh_channel_capture_negative_count()
    local count = 0
    for _, candidate in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local edition = candidate.edition
        if edition and (edition.negative or edition.key == "e_negative" or edition.type == "negative") then
            count = count + 1
        end
    end

    return count
end

local function canlaugh_channel_capture_last_tag_name()
    local last_tag = canlaugh_channel_capture_last_tag()
    if not (last_tag and last_tag.key) then
        return "None"
    end

    if type(localize) == "function" then
        local name = localize({
            type = "name_text",
            set = "Tag",
            key = last_tag.key,
        })
        if name and name ~= "ERROR" then
            return name
        end
    end

    local center = G and G.P_TAGS and G.P_TAGS[last_tag.key]
    return center and center.name or last_tag.key
end

local function canlaugh_channel_capture_add_tags(count)
    local last_tag = canlaugh_channel_capture_last_tag()
    if not (last_tag and last_tag.key and Tag and type(add_tag) == "function") then
        return false
    end

    local function add_copies()
        for _ = 1, count do
            local copy = Tag(last_tag.key)
            if last_tag.ability then
                copy.ability = canlaugh_channel_capture_copy(last_tag.ability)
            end
            add_tag(copy)
        end
        return true
    end

    if G and G.E_MANAGER and Event then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.35,
            func = add_copies,
        }))
    else
        add_copies()
    end

    return true
end

local function canlaugh_channel_capture_trigger_key()
    local blind = G and G.GAME and G.GAME.blind
    local blind_key = blind and blind.config and blind.config.blind and blind.config.blind.key

    return table.concat({
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or ""),
        tostring(blind_key or ""),
    }, ":")
end

local function canlaugh_channel_capture_won_deck(deck_key)
    if not deck_key then
        return false
    end

    local profile = G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    local usage = profile and profile.deck_usage and profile.deck_usage[deck_key]

    return usage and (
        next(usage.wins or {}) ~= nil
        or next(usage.wins_by_key or {}) ~= nil
    )
end

if CL.barter then
    CL.barter.register_rep_modifier("channel_capture", function(phase, context)
        if phase == "availability" and context.booster_kind == "Spectral" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_channel_capture") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Spectral" then
            local center = G.P_CENTERS and G.P_CENTERS.c_ectoplasm
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_channel_capture") or {}) do
                local rep = center and CL.barter.collection_representative(center, "Spectral")
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end

SMODS.Joker({
    key = "channel_capture",
    name = "Channel Capture",
    atlas = "channel_capture",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = {
        extra = {
            triggered = {},
        },
    },
    loc_txt = {
        name = "Channel Capture",
        text = {
            "After defeating a {C:attention}Boss Blind{},",
            "create a copy of the most recent {C:attention}Tag{}",
            "plus {C:attention}1{} copy for every",
            "{C:dark_edition}Negative{} Joker you have",
            "{C:inactive}(Last taken: {C:attention}#1#{C:inactive}){}",
        },
        unlock = {
            "Win a run with the",
            "{C:attention}Anaglyph Deck{}",
        },
    },
    loc_vars = function()
        return {
            vars = {
                canlaugh_channel_capture_last_tag_name(),
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        if not (args and args.type == "win_deck") then
            return false
        end

        local selected_back = G and G.GAME and G.GAME.selected_back
        local selected_key = selected_back
            and selected_back.effect
            and selected_back.effect.center
            and selected_back.effect.center.key

        return args.deck == "b_anaglyph"
            or selected_key == "b_anaglyph"
            or canlaugh_channel_capture_won_deck("b_anaglyph")
    end,
    calculate = function(self, card, context)
        if not context.blind_defeated
            or context.blueprint
            or context.retrigger_joker
            or card.getting_sliced
            or not canlaugh_channel_capture_is_boss()
        then
            return
        end

        local extra = card.ability.extra
        local trigger_key = canlaugh_channel_capture_trigger_key()
        if extra.triggered[trigger_key] then
            return
        end

        local copies = 1 + canlaugh_channel_capture_negative_count()
        if canlaugh_channel_capture_add_tags(copies) then
            extra.triggered[trigger_key] = true
            return {
                message = "+" .. tostring(copies) .. " Tag",
                colour = G.C.PURPLE,
            }
        end
    end,
})
