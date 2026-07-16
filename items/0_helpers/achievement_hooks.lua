local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local discovery_groups = {
    canlaugh_pilgrimage = {
        "c_canlaugh_final_hoax",
        "c_canlaugh_fire_witch",
        "c_canlaugh_ivy_gardener",
        "c_canlaugh_purple_piper",
        "c_canlaugh_yellow_jester",
        "c_canlaugh_city_keeper",
        "c_canlaugh_crimson_king",
    },
    canlaugh_darkanist = {
        "j_canlaugh_edge_of_the_earth",
        "j_canlaugh_blood_astronomia",
        "j_canlaugh_hail_from_the_future",
        "j_canlaugh_mad_groove",
    },
}

local challenge_discoverable_joker_keys = {
    j_canlaugh_challenged_joker = true,
    j_canlaugh_author_avatar = true,
}

local function all_discovered(keys)
    for _, key in ipairs(keys) do
        local center = G and G.P_CENTERS and G.P_CENTERS[key]
        if not (center and center.discovered) then
            return false
        end
    end

    return true
end

local function can_force_challenge_joker_discovery(center)
    return center
        and center.set == "Joker"
        and type(center.key) == "string"
        and G
        and G.GAME
        and G.GAME.challenge
        and challenge_discoverable_joker_keys[center.key]
end

local function force_discover_canned_laughter_joker(center)
    if not (G and G.P_CENTERS and can_force_challenge_joker_discovery(center)) then
        return center
    end

    local persistent_center = G.P_CENTERS[center.key] or center
    if persistent_center.discovered then
        return persistent_center
    end

    persistent_center.alert = true
    persistent_center.discovered = true

    local round_scores = G.GAME and G.GAME.round_scores
    local new_collection = round_scores and round_scores.new_collection
    if new_collection then
        new_collection.amt = (new_collection.amt or 0) + 1
    end

    if type(set_discover_tallies) == "function" then
        set_discover_tallies()
    end

    if type(G.save_progress) == "function" then
        G:save_progress()
    end

    return persistent_center
end

local function update_challenge_achievement_restrictions()
    if not (SMODS and SMODS.config) then
        return
    end

    if G and G.GAME and G.GAME.challenge then
        if not CL.challenge_achievement_settings then
            CL.challenge_achievement_settings = {
                achievements = SMODS.config.achievements,
                no_achievements = G.F_NO_ACHIEVEMENTS,
            }
        end

        SMODS.config.achievements = 3
        G.F_NO_ACHIEVEMENTS = false
        return
    end

    local settings = CL.challenge_achievement_settings
    if not settings then
        return
    end

    SMODS.config.achievements = settings.achievements
    if G then
        G.F_NO_ACHIEVEMENTS = settings.no_achievements
    end
    CL.challenge_achievement_settings = nil
end

local function check_discovery_achievement(event)
    update_challenge_achievement_restrictions()

    if type(check_for_unlock) == "function" then
        check_for_unlock({ type = event })
    end
end

local function check_discovery_achievements(center)
    if not center then
        return
    end

    if center.key == "j_canlaugh_challenged_joker" then
        check_discovery_achievement("canlaugh_blacklist")
    elseif center.key == "j_canlaugh_ingens" then
        check_discovery_achievement("canlaugh_oh_banana")
    end

    for event, keys in pairs(discovery_groups) do
        if all_discovered(keys) then
            check_discovery_achievement(event)
        end
    end
end

local function check_original_sin_unlock()
    if not (G and G.jokers and G.jokers.cards and G.jokers.config) then
        return
    end

    if #G.jokers.cards > G.jokers.config.card_limit and type(check_for_unlock) == "function" then
        check_for_unlock({ type = "canlaugh_invisible_joker_over_limit" })
    end
end

local function queue_original_sin_unlock_check()
    if G and G.E_MANAGER and type(Event) == "function" then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0,
            func = function()
                check_original_sin_unlock()
                return true
            end,
        }))
        return
    end

    check_original_sin_unlock()
end

local function synchronize_current_jokers()
    if not (G and G.jokers and G.jokers.cards) then
        return
    end

    for _, card in ipairs(G.jokers.cards) do
        local center = card and card.config and card.config.center
        center = force_discover_canned_laughter_joker(center)
        check_discovery_achievements(center)
    end
end

local function synchronize_discovery_achievements()
    if CL.discovery_achievement_synchronizing
        or not (G and G.GAME and G.P_CENTERS)
    then
        return
    end

    CL.discovery_achievement_synchronizing = true

    synchronize_current_jokers()

    local challenged_joker = G.P_CENTERS.j_canlaugh_challenged_joker
    if challenged_joker and challenged_joker.discovered then
        check_discovery_achievement("canlaugh_blacklist")
    end

    for event, keys in pairs(discovery_groups) do
        if all_discovered(keys) then
            check_discovery_achievement(event)
        end
    end

    CL.discovery_achievement_synchronizing = nil
end

if type(discover_card) == "function" and not CL.achievement_discovery_hook then
    CL.achievement_discovery_hook = true
    local discover_card_ref = discover_card

    function discover_card(center, ...)
        local results = { discover_card_ref(center, ...) }
        center = force_discover_canned_laughter_joker(center)
        check_discovery_achievements(center)
        return unpack(results)
    end
end

if Card and type(Card.add_to_deck) == "function" and not CL.achievement_discovery_add_hook then
    CL.achievement_discovery_add_hook = true
    local add_to_deck_ref = Card.add_to_deck

    function Card:add_to_deck(...)
        local original_sin = CL.original_sin_pending
        local center = self and self.config and self.config.center
        local is_original_sin_copy = original_sin
            and center
            and center.set == "Joker"
            and self ~= original_sin.source
        local results = { add_to_deck_ref(self, ...) }

        if is_original_sin_copy then
            original_sin.copy_added = true
            CL.original_sin_pending = nil
            queue_original_sin_unlock_check()
        end

        if center
            and center.key == "j_canlaugh_author_avatar"
            and type(check_for_unlock) == "function"
        then
            check_for_unlock({ type = "canlaugh_author_avatar_added" })
        end

        center = force_discover_canned_laughter_joker(center)
        check_discovery_achievements(center)
        return unpack(results)
    end
end

if type(fetch_achievements) == "function" and not CL.achievement_collection_sync_hook then
    CL.achievement_collection_sync_hook = true
    local fetch_achievements_ref = fetch_achievements

    function fetch_achievements(...)
        local results = { fetch_achievements_ref(...) }
        synchronize_discovery_achievements()
        return unpack(results)
    end
end

if Game and type(Game.update) == "function" and not CL.challenge_achievement_update_hook then
    CL.challenge_achievement_update_hook = true
    local game_update_ref = Game.update

    function Game:update(...)
        update_challenge_achievement_restrictions()
        return game_update_ref(self, ...)
    end
end

function CL.record_egg_man_egg()
    local profile = G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    if not profile then
        return
    end

    profile.canlaugh_egg_man_eggs = (profile.canlaugh_egg_man_eggs or 0) + 1
    if type(save_settings) == "function" then
        save_settings()
    end

    if profile.canlaugh_egg_man_eggs >= 5 and type(check_for_unlock) == "function" then
        check_for_unlock({ type = "canlaugh_room_in_between" })
    end
end
