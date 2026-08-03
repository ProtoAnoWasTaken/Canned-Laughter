local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "plain_jane",
    path = "plain_jane.png",
    px = 69,
    py = 93,
})

local function canlaugh_plain_jane_unenhanced_count()
    local count = 0

    for _, playing_card in ipairs((G and G.playing_cards) or {}) do
        if playing_card and playing_card.ability and playing_card.ability.set == "Default" then
            count = count + 1
        end
    end

    return count
end

local function canlaugh_plain_jane_starting_size()
    return G and G.GAME and G.GAME.starting_deck_size or 52
end

local function canlaugh_plain_jane_mult(card, fallback)
    local extra = card and card.ability and card.ability.extra or fallback
    local excess_cards = math.max(0, canlaugh_plain_jane_unenhanced_count() - canlaugh_plain_jane_starting_size())

    return excess_cards * extra.mult_gain, excess_cards
end

SMODS.Joker({
    key = "plain_jane",
    name = "Plain Jane",
    atlas = "plain_jane",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            mult_gain = 4,
        },
    },
    loc_txt = {
        name = "Plain Jane",
        text = {
            "{C:mult}+#1#{} Mult for every {C:attention}unenhanced{} card",
            "over {C:attention}#3#{} in your full deck",
            "{C:inactive}(Currently {C:mult}+#2#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local mult = canlaugh_plain_jane_mult(card, self.config.extra)
        local extra = card and card.ability and card.ability.extra or self.config.extra

        return {
            vars = {
                extra.mult_gain,
                mult,
                canlaugh_plain_jane_starting_size(),
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local mult = canlaugh_plain_jane_mult(card, self.config.extra)
            if mult > 0 then
                return {
                    mult = mult,
                }
            end
        end
    end,
})
