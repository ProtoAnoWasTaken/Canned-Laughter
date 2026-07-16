local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "spritz_tag",
    path = "spritz_tag.png",
    px = 34,
    py = 34,
})

local function canlaugh_spritz_has_room()
    if not (G and G.consumeables and G.consumeables.cards and G.consumeables.config) then
        return false
    end

    return #G.consumeables.cards + (G.GAME.consumeable_buffer or 0) < G.consumeables.config.card_limit
end

local function canlaugh_spritz_remove_tag(tag, delay)
    if not (G and G.E_MANAGER and Event and tag and type(tag.remove) == "function") then
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = delay or 0.2,
        blockable = false,
        blocking = false,
        func = function()
            tag:remove()
            return true
        end,
    }))
end

local function canlaugh_spritz_nope(tag)
    tag:nope()
    tag.triggered = true
    return true
end

local function canlaugh_last_consumable_name()
    local key = CL.last_played_consumable_key
    local center = key and G and G.P_CENTERS and G.P_CENTERS[key]

    if not center then
        return localize("k_none") or "None"
    end

    local ok, name = pcall(localize, {
        type = "name_text",
        key = key,
        set = center.set,
    })

    return ok and name or center.name or key
end

if Card and type(Card.use_consumeable) == "function" and not CL.spritz_last_consumable_hook_installed then
    CL.spritz_last_consumable_hook_installed = true
    local canlaugh_use_consumeable_ref = Card.use_consumeable

    function Card:use_consumeable(area, copier, ...)
        local results = { canlaugh_use_consumeable_ref(self, area, copier, ...) }

        if not copier
            and self
            and self.config
            and self.config.center
            and self.config.center.consumeable
        then
            CL.last_played_consumable_key = self.config.center.key
            if G and G.GAME then
                G.GAME.canlaugh_consumables_used = (G.GAME.canlaugh_consumables_used or 0) + 1
            end
        end

        return unpack(results)
    end
end

local function canlaugh_create_consumable_copy(key, lock, tag, unlocks_low_orbit)
    local center = key and G.P_CENTERS[key]
    if not center then
        G.CONTROLLER.locks[lock] = nil
        canlaugh_spritz_remove_tag(tag)
        return true
    end

    G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
    G.E_MANAGER:add_event(Event({
        func = function()
            local card = create_card(center.set, G.consumeables, nil, nil, nil, nil, key, "canlaugh_spritz")
            card:add_to_deck()
            G.consumeables:emplace(card)
            if unlocks_low_orbit and type(check_for_unlock) == "function" then
                check_for_unlock({ type = "canlaugh_low_orbit" })
            end
            G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 1) - 1)
            G.CONTROLLER.locks[lock] = nil
            canlaugh_spritz_remove_tag(tag)
            return true
        end,
    }))

    return true
end

SMODS.Tag({
    key = "spritz",
    atlas = "spritz_tag",
    order = 43,
    config = { type = "immediate" },
    pos = { x = 0, y = 0 },
    loc_txt = {
        name = "Spritz Tag",
        text = {
            "Create a copy of your",
            "last played consumable",
            "({C:attention}#1#{})",
            "{C:inactive}(Must have room){}",
        },
    },
    loc_vars = function(self, info_queue, tag)
        return {
            vars = {
                canlaugh_last_consumable_name(),
            },
        }
    end,
    apply = function(self, tag, context)
        if not (context and context.type == "immediate") then
            return
        end

        local key = CL.last_played_consumable_key
        local center = key and G and G.P_CENTERS and G.P_CENTERS[key]

        local unlocks_low_orbit = G and G.GAME and (G.GAME.canlaugh_consumables_used or 0) == 0

        if not center or not canlaugh_spritz_has_room() then
            return canlaugh_spritz_nope(tag)
        end

        local lock = tag.ID
        G.CONTROLLER.locks[lock] = true
        G.E_MANAGER:add_event(Event({
            func = function()
                play_sound("generic1", 0.9 + math.random() * 0.1, 0.8)
                return canlaugh_create_consumable_copy(key, lock, tag, unlocks_low_orbit)
            end,
        }))
        tag.triggered = true
        return true
    end,
})
