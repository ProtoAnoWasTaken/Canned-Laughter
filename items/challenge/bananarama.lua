local function banana_only_jokers()
    local banned = {}
    local is_banana = CannedLaughter.is_banana_center

    for _, center in pairs(G.P_CENTERS or {}) do
        if center.set == "Joker" and center.key and not (is_banana and is_banana(center)) then
            banned[#banned + 1] = { id = center.key }
        end
    end

    table.sort(banned, function(a, b)
        return a.id < b.id
    end)
    return banned
end

SMODS.Challenge({
    key = "bananarama",
    loc_txt = {
        name = "Bananarama",
    },
    rules = {
        custom = {
            { id = "canlaugh_bananarama_jokers" },
            { id = "canlaugh_bananarama_import" },
        },
        modifiers = {},
    },
    jokers = {},
    consumeables = {},
    vouchers = {},
    deck = {
        type = "Challenge Deck",
    },
    restrictions = {
        banned_cards = banana_only_jokers,
        banned_tags = {},
        banned_other = {},
    },
    calculate = function(self, context)
        if context.modify_weights and context.pool_types and context.pool_types.Tag then
            for _, entry in ipairs(context.pool or {}) do
                if entry.key == "tag_canlaugh_import" then
                    entry.weight = entry.weight * 2
                end
            end
        end
    end,
})
