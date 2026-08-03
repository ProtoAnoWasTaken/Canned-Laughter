local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({
    key = "equivalence",
    path = "equivalence.png",
    px = 71,
    py = 95,
})

local function shuffled_hand()
    local cards = {}
    for _, card in ipairs(G.hand.cards or {}) do
        cards[#cards + 1] = card
    end
    for index = #cards, 2, -1 do
        local swap = math.floor(pseudorandom("canlaugh_equivalence_" .. tostring(index)) * index) + 1
        cards[index], cards[swap] = cards[swap], cards[index]
    end
    return cards
end

SMODS.Spectral({
    key = "equivalence",
    atlas = "equivalence",
    pos = { x = 0, y = 0 },
    cost = 4,
    loc_txt = {
        name = "Equivalence",
        text = {
            "Destroy {C:attention}3{} random cards",
            "in your hand, apply {C:dark_edition}Negative{}",
            "to {C:attention}3{} others",
        },
    },
    can_use = function()
        return #G.hand.cards >= 6
    end,
    use = function(self, card, area, copier)
        local cards = shuffled_hand()
        CL.tarot.juice_used_consumable(copier or card)
        for index = 1, 3 do
            local target = cards[index]
            target.getting_sliced = true
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.2,
                func = function()
                    target:start_dissolve({ G.C.RED, G.C.ORANGE, G.C.YELLOW }, nil, 1.6)
                    return true
                end,
            }))
        end
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.5,
            func = function()
                for index = 4, 6 do
                    local target = cards[index]
                    if not target.removed then
                        target:set_edition({ negative = true }, true, true)
                        target:juice_up(0.3, 0.3)
                    end
                end
                return true
            end,
        }))
        delay(0.3)
    end,
})
