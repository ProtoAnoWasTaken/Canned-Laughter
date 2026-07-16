local CL = CannedLaughter
SMODS.Atlas({ key = "boss_ure", path = "blind_ure.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

local function most_used_hand()
    local profile = G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    local usage = profile and profile.hand_usage or {}
    local chosen, count, order

    for handname, hand in pairs(G and G.GAME and G.GAME.hands or {}) do
        local used = usage[string.gsub(handname, " ", "")]
        local hand_count = used and used.count or 0
        local hand_order = hand.order or math.huge

        if not count or hand_count > count or (hand_count == count and hand_order < order) then
            chosen = handname
            count = hand_count
            order = hand_order
        end
    end

    return chosen or "High Card"
end

CL.register_standard_boss({
    key = "ure",
    atlas = "boss_ure",
    art = "ure",
    boss_colour = HEX("433990"),
    mult = 2,
    loc_txt = { name = "The Ure", text = { "Playing #1# sets money to $0" } },
    loc_vars = function(self)
        local hand = most_used_hand() or "High Card"
        return { vars = { localize(hand, "poker_hands") } }
    end,
    collection_loc_vars = function(self)
        return { vars = { "your most used poker hand" } }
    end,
    calculate = function(self, blind, context)
        if context and context.before then
            local hand = G.FUNCS.get_poker_hand_info(context.full_hand)
            if hand == most_used_hand() then ease_dollars(-G.GAME.dollars) end
        end
    end,
})
