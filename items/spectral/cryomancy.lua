local CL = rawget(_G, "CannedLaughter") or {}
local CRYOMANCY_DISSOLVE_DURATION = 1.6
local CRYOMANCY_SOUND_DURATION = 5.079375

SMODS.Atlas({
    key = "cryomancy",
    path = "cryomancy.png",
    px = 71,
    py = 95,
})

local function shuffled_hand()
    local cards = {}
    for _, card in ipairs(G.hand.cards or {}) do
        cards[#cards + 1] = card
    end
    for index = #cards, 2, -1 do
        local swap = math.floor(pseudorandom("canlaugh_cryomancy_" .. tostring(index)) * index) + 1
        cards[index], cards[swap] = cards[swap], cards[index]
    end
    return cards
end

local function play_cryomancy_sound()
    local native_sound = CL.native_sound
    if native_sound and type(native_sound.play) == "function" then
        local ok, source = pcall(native_sound.play, "sfx_cryomancy.ogg", {
            pitch = 1,
            volume = 0.8,
            source_type = "static",
        })
        if ok and source then
            return source:getDuration() / source:getPitch()
        end
    end

    play_sound("tarot1", 1, 0.8)
    return CRYOMANCY_SOUND_DURATION
end

SMODS.Spectral({
    key = "cryomancy",
    atlas = "cryomancy",
    pos = { x = 0, y = 0 },
    cost = 4,
    loc_txt = {
        name = "Cryomancy",
        text = {
            "Destroy {C:attention}2{} random cards",
            "in your hand, add {C:canlaugh_frozen}Frozen{}",
            "to all remaining cards",
        },
    },
    loc_vars = function(self, info_queue, card)
        local frozen = G and G.P_CENTERS and G.P_CENTERS.e_canlaugh_frozen

        if frozen then
            CL.add_unique_tooltip(info_queue, frozen, card)
        end

        return {
            vars = {},
        }
    end,
    can_use = function()
        return #G.hand.cards >= 3
    end,
    use = function(self, card, area, copier)
        local cards = shuffled_hand()
        local survivors = {}
        for index = 3, #cards do
            survivors[#survivors + 1] = cards[index]
        end

        CL.tarot.juice_used_consumable(copier or card)
        for index = 1, 2 do
            local target = cards[index]
            target.getting_sliced = true
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.2,
                func = function()
                    target:start_dissolve({ G.C.RED, G.C.ORANGE, G.C.YELLOW }, nil, CRYOMANCY_DISSOLVE_DURATION)
                    return true
                end,
            }))
        end
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.2 + CRYOMANCY_DISSOLVE_DURATION,
            func = function()
                for _, target in ipairs(survivors) do
                    if not target.removed then
                        target:flip()
                    end
                end
                local sound_duration = play_cryomancy_sound()
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = sound_duration,
                    func = function()
                        for _, target in ipairs(survivors) do
                            if not target.removed and not target.edition then
                                target:set_edition("e_canlaugh_frozen", true, true)
                            end
                            if not target.removed then
                                target:flip()
                                target:juice_up(0.3, 0.3)
                            end
                        end
                        return true
                    end,
                }))
                return true
            end,
        }))
        delay(0.2 + CRYOMANCY_DISSOLVE_DURATION + CRYOMANCY_SOUND_DURATION)
    end,
})
