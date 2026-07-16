local CL = rawget(_G, "CannedLaughter") or {}

CannedLaughter = CL
CL.native_sound = CL.native_sound or {}

local native_sound = CL.native_sound
local nfs = (SMODS and SMODS.NFS) or rawget(_G, "NFS")

local function clean_relative_path(path)
    if type(path) ~= "string" or path == "" then
        return nil, "sound path must be a non-empty string"
    end

    path = path:gsub("\\", "/")

    if path:sub(1, 1) == "/" or path:match("^%a:/") then
        return nil, "sound path must stay inside assets/sounds"
    end

    for segment in path:gmatch("[^/]+") do
        if segment == ".." then
            return nil, "sound path must stay inside assets/sounds"
        end
    end

    return path
end

local function default_source_type(path)
    local lower_path = path:lower()
    return (lower_path:find("music", 1, true)
        or lower_path:find("ambient", 1, true)
        or lower_path:find("stream", 1, true)) and "stream" or "static"
end

function native_sound.load(path, source_type)
    local relative_path, path_err = clean_relative_path(path)
    if not relative_path then
        return nil, path_err
    end

    if not (love and love.sound and love.audio) then
        return nil, "LÖVE audio is unavailable"
    end

    if not (nfs and type(nfs.newFileData) == "function") then
        return nil, "Steamodded native filesystem access is unavailable"
    end

    source_type = source_type or default_source_type(relative_path)
    if source_type ~= "static" and source_type ~= "stream" then
        return nil, "source type must be 'static' or 'stream'"
    end

    local mod_path = CL.mod_path or (SMODS.current_mod and SMODS.current_mod.path)
    if type(mod_path) ~= "string" or mod_path == "" then
        return nil, "Canned Laughter's mod path is unavailable"
    end

    local sound_root = mod_path:gsub("[/\\]+$", "") .. "/assets/sounds/"
    local full_path = sound_root .. relative_path
    local file_ok, file_data_or_err = pcall(nfs.newFileData, full_path)
    if not file_ok or not file_data_or_err then
        return nil, "failed to read " .. full_path .. ": " .. tostring(file_data_or_err)
    end

    local ok, source_or_err = pcall(function()
        local decoder = love.sound.newDecoder(file_data_or_err)
        return love.audio.newSource(decoder, source_type)
    end)

    if not ok then
        return nil, "failed to decode " .. full_path .. ": " .. tostring(source_or_err)
    end

    return source_or_err
end

function native_sound.play(path, options)
    options = options or {}

    local source, load_err = native_sound.load(path, options.source_type)
    if not source then
        return nil, load_err
    end

    source:setVolume(options.volume or 1)
    source:setPitch(options.pitch or 1)
    source:setLooping(options.looping == true)
    source:play()

    return source
end
