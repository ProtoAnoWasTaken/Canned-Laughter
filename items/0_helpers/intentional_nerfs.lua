local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.intentional_nerfs = CL.intentional_nerfs or {}

SMODS.Atlas({
    key = "awesome_explosion_frames",
    path = "awesome_explosion_frames.png",
    px = 65,
    py = 94,
    disable_mipmap = true,
})

local FRAME_COUNT = 17
local FRAMES_PER_ROW = 5
local FRAMES_PER_SECOND = 30
local FINAL_FRAME_HOLD_DURATION = 0.2
local EFFECT_DURATION = FRAME_COUNT / FRAMES_PER_SECOND + FINAL_FRAME_HOLD_DURATION
local EFFECT_START_DELAY = 0.2

CL.intentional_nerfs.total_duration = EFFECT_START_DELAY + EFFECT_DURATION

local function canlaugh_intentional_nerfs_active()
    local ante = G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante
    return type(ante) == "number" and ante < 9
end

local function canlaugh_nerf_atlas()
    if SMODS and type(SMODS.get_atlas) == "function" then
        local atlas = SMODS.get_atlas("awesome_explosion_frames")
            or SMODS.get_atlas("canlaugh_awesome_explosion_frames")
        if atlas then
            return atlas
        end
    end

    return G
        and G.ASSET_ATLAS
        and (
            G.ASSET_ATLAS.canlaugh_awesome_explosion_frames
            or G.ASSET_ATLAS.awesome_explosion_frames
        )
end

local function canlaugh_nerf_frame_position(started_at)
    local elapsed = math.max(0, (G.TIMERS.REAL or started_at) - started_at)
    local frame = math.min(math.floor(elapsed * FRAMES_PER_SECOND), FRAME_COUNT - 1)

    return {
        x = frame % FRAMES_PER_ROW,
        y = math.floor(frame / FRAMES_PER_ROW),
    }
end

local function canlaugh_play_nerf_sound(volume)
    local native_sound = CL.native_sound
    if not native_sound or type(native_sound.play) ~= "function" then
        return false
    end

    local success, source = pcall(native_sound.play, "sfx_nerf.wav", {
        source_type = "static",
        volume = volume or 1,
    })

    return success and source ~= nil
end

function CL.intentional_nerfs.destroy(card, options)
    if not canlaugh_intentional_nerfs_active()
        or not card
        or card.removed
        or card.canlaugh_intentional_nerf
    then
        return false
    end

    local function remove_card()
        if not card.removed then
            card:remove()
        end
        return true
    end

    local function start_effect()
        if card.removed then
            return true
        end

        card.getting_sliced = true
        card.canlaugh_intentional_nerf.started_at = G.TIMERS.REAL or 0
        local sound_volume = options and options.sound_volume or 1
        canlaugh_play_nerf_sound(sound_volume)

        if G and G.E_MANAGER and Event then
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                blockable = false,
                delay = EFFECT_DURATION,
                func = remove_card,
            }))
        else
            remove_card()
        end

        return true
    end

    card.canlaugh_intentional_nerf = {}

    if not (options and options.skip_achievement)
        and type(check_for_unlock) == "function"
    then
        check_for_unlock({
            type = "canlaugh_intentional_game_design",
        })
    end

    if G and G.E_MANAGER and Event then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            blockable = false,
            delay = EFFECT_START_DELAY,
            func = start_effect,
        }))
    else
        start_effect()
    end

    return true
end

local function canlaugh_channel_capture_observer_candidates()
    local channel_capture = {}
    local observer_effect = {}

    for _, joker in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local key = joker.config and joker.config.center and joker.config.center.key
        if not joker.removed and not joker.canlaugh_intentional_nerf then
            if key == "j_canlaugh_channel_capture" then
                channel_capture[#channel_capture + 1] = joker
            elseif key == "j_canlaugh_observer_effect" then
                observer_effect[#observer_effect + 1] = joker
            end
        end
    end

    if #channel_capture == 0 or #observer_effect == 0 then
        return {}
    end

    local candidates = {}
    for _, joker in ipairs(channel_capture) do
        candidates[#candidates + 1] = joker
    end
    for _, joker in ipairs(observer_effect) do
        candidates[#candidates + 1] = joker
    end

    return candidates
end

function CL.intentional_nerfs.check_channel_capture_observer_effect()
    if not canlaugh_intentional_nerfs_active() then
        return false
    end

    local candidates = canlaugh_channel_capture_observer_candidates()
    if #candidates == 0 then
        return false
    end

    local target = pseudorandom_element(candidates, pseudoseed("canlaugh_channel_capture_observer_effect"))
    return CL.intentional_nerfs.destroy(target)
end

if Card and type(Card.add_to_deck) == "function" and not CL.intentional_nerf_add_to_deck_hook_installed then
    CL.intentional_nerf_add_to_deck_hook_installed = true
    local add_to_deck_ref = Card.add_to_deck

    function Card:add_to_deck(...)
        local results = {
            add_to_deck_ref(self, ...),
        }
        local key = self.config and self.config.center and self.config.center.key

        if key == "j_canlaugh_channel_capture" or key == "j_canlaugh_observer_effect" then
            CL.intentional_nerfs.check_channel_capture_observer_effect()
        end

        return unpack(results)
    end
end

if Card and type(Card.draw) == "function" and not CL.intentional_nerf_draw_hook_installed then
    CL.intentional_nerf_draw_hook_installed = true
    local draw_ref = Card.draw

    function Card:draw(layer, ...)
        local effect = self.canlaugh_intentional_nerf
        local center = self.children and self.children.center
        local atlas = effect and effect.started_at and center and canlaugh_nerf_atlas()

        if atlas then
            local old_atlas = center.atlas
            local old_sprite_pos = center.sprite_pos
            local old_scale = {
                x = center.scale.x,
                y = center.scale.y,
            }

            center.atlas = atlas
            center.scale = {
                x = atlas.px,
                y = atlas.py,
            }
            center:set_sprite_pos(canlaugh_nerf_frame_position(effect.started_at))

            local results = {
                pcall(draw_ref, self, layer, ...),
            }

            center.atlas = old_atlas
            center.scale = old_scale
            if old_sprite_pos then
                center:set_sprite_pos(old_sprite_pos)
            end

            if not results[1] then
                error(results[2])
            end

            return unpack(results, 2)
        end

        return draw_ref(self, layer, ...)
    end
end
