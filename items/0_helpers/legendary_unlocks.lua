local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_profile()
    return G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
end

local function canlaugh_completion_value(value)
    if value == true then
        return true
    end

    if type(value) == "number" then
        return value > 0
    end

    if type(value) == "table" then
        return value.completed == true
            or value.won == true
            or value.beaten == true
            or (type(value.count) == "number" and value.count > 0)
    end

    return false
end

local function canlaugh_challenge_keys(key, challenge)
    local keys = {}
    local seen = {}

    local function add(value)
        if type(value) == "string" and value ~= "" and not seen[value] then
            seen[value] = true
            keys[#keys + 1] = value
        end
    end

    add(key)
    if type(key) == "string" and not key:match("^c_") then
        add("c_" .. key)
        add("canlaugh_" .. key)
        add("c_canlaugh_" .. key)
    end

    if challenge then
        add(challenge.key)
        add(challenge.id)
    end

    return keys
end

function CL.challenge_completed(key, challenge)
    local profile = canlaugh_profile()
    if not profile then
        return false
    end

    if profile.all_unlocked then
        return true
    end

    local progress = profile.challenge_progress
    local completed = type(progress) == "table" and (progress.completed or progress)
    if type(completed) ~= "table" then
        return false
    end

    for _, candidate in ipairs(canlaugh_challenge_keys(key, challenge)) do
        if canlaugh_completion_value(completed[candidate]) then
            return true
        end
    end

    return false
end

function CL.all_challenges_completed()
    local profile = canlaugh_profile()
    if profile and profile.all_unlocked then
        return true
    end

    local challenges = G and G.CHALLENGES
    if type(challenges) ~= "table" then
        challenges = SMODS and SMODS.Challenges
    end

    local count = 0
    for key, challenge in pairs(challenges or {}) do
        if type(challenge) == "table" then
            count = count + 1
            if not CL.challenge_completed(key, challenge) then
                return false
            end
        end
    end

    return count > 0
end

function CL.dionysus_unlocked()
    local achievement_key = "ach_canlaugh_still_the_best_522_bce"
    local achievement = G and G.ACHIEVEMENTS and G.ACHIEVEMENTS[achievement_key]
    local earned = G and G.SETTINGS and G.SETTINGS.ACHIEVEMENTS_EARNED

    return achievement and achievement.earned
        or earned and earned[achievement_key]
end
