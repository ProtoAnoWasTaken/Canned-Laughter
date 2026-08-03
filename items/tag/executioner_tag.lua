local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local RARE_SPECTRAL_KEYS = {
    "c_soul",
    "c_black_hole",
    "c_canlaugh_tessellation",
    "c_canlaugh_crimson_king",
    "c_canlaugh_city_keeper",
    "c_canlaugh_retrospect",
}

local function canlaugh_executioner_spectral_pool()
    local pool = {}

    for _, key in ipairs(RARE_SPECTRAL_KEYS) do
        if G and G.P_CENTERS and G.P_CENTERS[key] then
            pool[#pool + 1] = key
        end
    end

    return pool
end

local function canlaugh_executioner_has_room()
    return G
        and G.consumeables
        and G.consumeables.cards
        and G.consumeables.config
        and #G.consumeables.cards + (G.GAME.consumeable_buffer or 0) < G.consumeables.config.card_limit
end

local function canlaugh_executioner_create_spectral(tag, lock)
    local key = pseudorandom_element(
        canlaugh_executioner_spectral_pool(),
        pseudoseed("canlaugh_executioner_spectral")
    )

    if not key then
        G.CONTROLLER.locks[lock] = nil
        return true
    end

    G.GAME.consumeable_buffer = (G.GAME.consumeable_buffer or 0) + 1
    G.E_MANAGER:add_event(Event({
        func = function()
            local card = create_card(
                "Spectral",
                G.consumeables,
                nil,
                nil,
                nil,
                nil,
                key,
                "canlaugh_executioner_spectral"
            )
            card:add_to_deck()
            G.consumeables:emplace(card)
            G.GAME.consumeable_buffer = math.max(0, (G.GAME.consumeable_buffer or 1) - 1)
            G.CONTROLLER.locks[lock] = nil
            return true
        end,
    }))

    return true
end

if Blind and type(Blind.set_blind) == "function" and not CL.executioner_tag_boss_hook_installed then
    CL.executioner_tag_boss_hook_installed = true
    local set_blind_ref = Blind.set_blind

    function Blind:set_blind(blind, reset, silent)
        local result = set_blind_ref(self, blind, reset, silent)
        local center = self.config and self.config.blind
        local game = G and G.GAME
        local ante = game and game.round_resets and game.round_resets.ante

        if not reset
            and blind
            and center
            and center.boss
            and self.chips
            and game
            and game.canlaugh_executioner_boss_ante == ante
        then
            self.chips = self.chips * 1.25
            self.chip_text = number_format(self.chips)
            game.canlaugh_executioner_boss_ante = nil

            if type(CL.refresh_big_blind_goal) == "function" then
                CL.refresh_big_blind_goal()
            end
        end

        return result
    end
end

SMODS.Atlas({
    key = "executioner_tag",
    path = "executioner_tag.png",
    px = 34,
    py = 34,
})

SMODS.Tag({
    key = "executioner",
    atlas = "executioner_tag",
    order = 45,
    config = { type = "immediate" },
    pos = { x = 0, y = 0 },
    loc_txt = {
        name = "Executioner's Tag",
        text = {
            "Create a random rare",
            "{C:spectral}Spectral{} card",
            "{C:attention}X1.25{} Boss Blind size",
            "this Ante",
        },
    },
    apply = function(self, tag, context)
        if not (context and context.type == "immediate") then
            return
        end

        if G and G.GAME and G.GAME.round_resets then
            G.GAME.canlaugh_executioner_boss_ante = G.GAME.round_resets.ante
        end

        tag.triggered = true
        if not canlaugh_executioner_has_room() then
            tag:nope()
            return true
        end

        local lock = tag.ID
        G.CONTROLLER.locks[lock] = true
        tag:yep("+", G.C.PURPLE, function()
            return canlaugh_executioner_create_spectral(tag, lock)
        end)
        return true
    end,
})
