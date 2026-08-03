local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local SPLASH_NERF_CHANCE = 1 / 25

local function canlaugh_should_play_nerf_splash()
    if G.SETTINGS.skip_splash == "Yes" then
        return false
    end

    if not (CL.intentional_nerfs and type(CL.intentional_nerfs.destroy) == "function") then
        return false
    end

    if not (G.P_CENTERS and G.P_CENTERS.j_canlaugh_confused_joker) then
        return false
    end

    return math.random() < SPLASH_NERF_CHANCE
end

local function canlaugh_play_nerf_splash(game)
    game:prep_stage(G.STAGES.MAIN_MENU, G.STATES.SPLASH, true)
    G.TIMERS.TOTAL = 0
    G.TIMERS.REAL = 0

    if type(check_for_unlock) == "function" then
        check_for_unlock({
            type = "canlaugh_where_am_i",
        })
    end

    local scale = 1.2
    local final_y = G.ROOM.T.h / 2 - scale * G.CARD_H / 2
    local card = Card(
        G.ROOM.T.w / 2 - scale * G.CARD_W / 2,
        10 + final_y,
        scale * G.CARD_W,
        scale * G.CARD_H,
        G.P_CARDS.empty,
        G.P_CENTERS.j_canlaugh_confused_joker,
        {
            bypass_discovery_center = true,
            bypass_discovery_ui = true,
        }
    )

    card.ambient_tilt = 1
    card.states.drag.can = false
    card.states.hover.can = false
    card.no_ui = true

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        blockable = false,
        delay = 0.2,
        func = function()
            card.T.y = final_y
            G.VIBRATION = G.VIBRATION + 2
            play_sound("whoosh1", 0.7, 0.2)
            play_sound("introPad1", 0.704, 0.6)
            return true
        end,
    }))

    local function open_main_menu()
        game:main_menu("splash")
        return true
    end

    local function start_explosion()
        local started = CL.intentional_nerfs.destroy(card, {
            skip_achievement = true,
            sound_volume = 0.35,
        })
        if not started then
            card:remove()
            return open_main_menu()
        end

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            blockable = false,
            delay = CL.intentional_nerfs.total_duration + 0.05,
            func = open_main_menu,
        }))

        return true
    end

    local function show_confused_proc()
        card_eval_status_text(card, "extra", nil, nil, nil, {
            instant = true,
            message = "?",
            colour = G.C.FILTER,
            sound = "generic1",
        })

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            blockable = false,
            delay = 2,
            func = start_explosion,
        }))

        return true
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        blockable = false,
        delay = 1,
        func = show_confused_proc,
    }))
end

if Game and type(Game.splash_screen) == "function" and not CL.splash_nerf_hook_installed then
    CL.splash_nerf_hook_installed = true
    local splash_screen_ref = Game.splash_screen

    function Game:splash_screen(...)
        if canlaugh_should_play_nerf_splash() then
            return canlaugh_play_nerf_splash(self)
        end

        return splash_screen_ref(self, ...)
    end
end
