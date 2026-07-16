SMODS.Atlas({
    key = "envious_joker",
    path = "enviousjoker.png",
    px = 69,
    py = 93,
})

local function canlaugh_get_deck_suit_counts()
    local counts = {}

    for _, suit_key in ipairs(SMODS.Suit.obj_buffer or {}) do
        counts[suit_key] = 0
    end

    for _, playing_card in ipairs(G.playing_cards or {}) do
        local suit = playing_card
            and playing_card.base
            and playing_card.base.suit

        if counts[suit] ~= nil then
            counts[suit] = counts[suit] + 1
        end
    end

    return counts
end

local function canlaugh_get_represented_suits(counts)
    local represented_suits = {}

    for _, suit_key in ipairs(SMODS.Suit.obj_buffer or {}) do
        if (counts[suit_key] or 0) > 0 then
            represented_suits[#represented_suits + 1] = suit_key
        end
    end

    return represented_suits
end

local function canlaugh_get_deck_suit_signature(counts)
    local parts = {}

    for _, suit_key in ipairs(SMODS.Suit.obj_buffer or {}) do
        parts[#parts + 1] = suit_key .. ":" .. tostring(counts[suit_key] or 0)
    end

    return table.concat(parts, "|")
end

local function canlaugh_get_minority_suit(card)
    local counts = canlaugh_get_deck_suit_counts()
    local signature = canlaugh_get_deck_suit_signature(counts)
    local extra = card and card.ability and card.ability.extra

    if extra and extra.minority_signature == signature and extra.minority_suit then
        return extra.minority_suit
    end

    local suit_keys = canlaugh_get_represented_suits(counts)
    if #suit_keys == 0 then
        suit_keys = SMODS.Suit.obj_buffer or {}
    end

    local lowest_count = nil
    local minority_suits = {}

    for _, suit_key in ipairs(suit_keys) do
        local count = counts[suit_key] or 0

        if not lowest_count or count < lowest_count then
            lowest_count = count
            minority_suits = { suit_key }
        elseif count == lowest_count then
            minority_suits[#minority_suits + 1] = suit_key
        end
    end

    if #minority_suits == 0 then
        return nil
    end

    if #minority_suits == 1 then
        return minority_suits[1]
    end

    local seed = table.concat({
        "canlaugh_envious_joker",
        tostring(card and card.sort_id or ""),
        signature,
    }, "_")

    local minority_suit = pseudorandom_element(minority_suits, pseudoseed(seed))

    if extra then
        extra.minority_signature = signature
        extra.minority_suit = minority_suit
    end

    return minority_suit
end

SMODS.Joker({
    key = "envious_joker",
    name = "Envious Joker",
    atlas = "envious_joker",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 4,
    config = {
        extra = {
            mult = 3,
            minority_signature = nil,
            minority_suit = nil,
        },
    },
    loc_txt = {
        name = "Envious Joker",
        text = {
            "Played card of a {C:attention}minority suit{}",
            "gives {C:mult}+#1#{} Mult when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                card and card.ability and card.ability.extra and card.ability.extra.mult
                    or self.config.extra.mult,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.individual
            and context.cardarea == G.play
            and context.other_card
        then
            local minority_suit = canlaugh_get_minority_suit(card)

            if not (minority_suit and context.other_card:is_suit(minority_suit)) then
                return
            end

            return {
                mult = card.ability.extra.mult,
            }
        end
    end,
})
