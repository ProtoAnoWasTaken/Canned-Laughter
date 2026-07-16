local CL = CannedLaughter
SMODS.Atlas({ key = "boss_frozen", path = "blind_frozen.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

local function frozen_trigger()
    local blind = G and G.GAME and G.GAME.blind
    local trigger = blind and blind.canlaugh_frozen_trigger

    if trigger then
        return trigger
    end

    if not blind then
        return "play"
    end

    local ante = G.GAME.round_resets and G.GAME.round_resets.ante or 0
    trigger = pseudorandom(pseudoseed("canlaugh_frozen_trigger_" .. tostring(ante))) < 0.5
        and "play"
        or "discard"
    blind.canlaugh_frozen_trigger = trigger
    return trigger
end

CL.register_standard_boss({
    key = "frozen",
    atlas = "boss_frozen",
    art = "frozen",
    boss_colour = HEX("47ACDD"),
    mult = 2,
    loc_txt = { name = "The Frozen", text = { "On #1#, gain an", "unselectable Stone Card" } },
    loc_vars = function(self)
        local trigger = frozen_trigger()
        local name = trigger == "discard" and "Discard" or "Play"
        return { vars = { name } }
    end,
    collection_loc_vars = function(self)
        return { vars = { "Play or Discard" } }
    end,
    set_blind = function(self)
        frozen_trigger()

        local blind = G and G.GAME and G.GAME.blind
        local key = blind and blind.config and blind.config.blind and blind.config.blind.key
        if key == "bl_canlaugh_frozen" then
            blind:set_text()
        end
    end,
    calculate = function(self, blind, context)
        local trigger = frozen_trigger()
        local triggered_on_play = context and context.before and trigger == "play"
        local triggered_on_discard = context and context.pre_discard and trigger == "discard"

        if not (triggered_on_play or triggered_on_discard) then
            return
        end

        if not (create_playing_card and G and G.hand and G.P_CENTERS and G.P_CENTERS.m_stone) then
            return
        end

        local card = create_playing_card({ front = G.P_CARDS.empty, center = G.P_CENTERS.m_stone }, G.hand)
        if card then
            card.ability.canlaugh_frozen_stone = true
        end
    end,
    defeat = function(self)
        for _, card in ipairs(G and G.playing_cards or {}) do
            if card.ability and card.ability.canlaugh_frozen_stone then card:start_dissolve() end
        end
    end,
})

if CardArea and not CL.frozen_selection_hook_installed then
    CL.frozen_selection_hook_installed = true
    local can_highlight_ref = CardArea.can_highlight
    local add_to_highlighted_ref = CardArea.add_to_highlighted

    function CardArea:can_highlight(card, ...)
        if card and card.ability and card.ability.canlaugh_frozen_stone then return false end
        return can_highlight_ref(self, card, ...)
    end

    function CardArea:add_to_highlighted(card, silent, ...)
        if card and card.ability and card.ability.canlaugh_frozen_stone then return end
        return add_to_highlighted_ref(self, card, silent, ...)
    end
end
