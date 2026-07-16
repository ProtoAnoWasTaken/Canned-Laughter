SMODS.Atlas({
    key = "daguerreotype",
    path = "daguerreotype.png",
    px = 71,
    py = 95,
})

local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_rules_card_active()
    return CL.rules_card_active and CL.rules_card_active()
end

local canlaugh_is_glitter = CL.is_glitter

local function canlaugh_collect_glitter_cards()
    local cards = {}
    local seen = {}

    local function add_card(card)
        if card and not seen[card] and canlaugh_is_glitter(card) then
            cards[#cards + 1] = card
            seen[card] = true
        end
    end

    for _, card in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        add_card(card)
    end

    for _, card in ipairs((G and G.playing_cards) or {}) do
        add_card(card)
    end

    return cards
end

local function canlaugh_sell_cost_without_edition(card)
    if not (card and type(card.set_cost) == "function") then
        return 0
    end

    local old_edition = card.edition
    local old_sell_cost = card.sell_cost
    local old_sell_cost_label = card.sell_cost_label
    local old_cost = card.cost
    local old_extra_cost = card.extra_cost

    card.edition = nil
    card:set_cost()
    local sell_cost = card.sell_cost or 0

    card.edition = old_edition
    card.sell_cost = old_sell_cost
    card.sell_cost_label = old_sell_cost_label
    card.cost = old_cost
    card.extra_cost = old_extra_cost
    card:set_cost()

    return sell_cost
end

local function canlaugh_daguerreotype_lost_value(cards)
    local lost_value = 0

    for _, card in ipairs(cards or canlaugh_collect_glitter_cards()) do
        local before = tonumber(card.sell_cost) or 0
        local after = canlaugh_sell_cost_without_edition(card)
        lost_value = lost_value + math.max(0, before - after)
    end

    return lost_value
end

local function canlaugh_daguerreotype_payout(cards)
    return math.min(50, math.floor(canlaugh_daguerreotype_lost_value(cards) * 0.25))
end

SMODS.Spectral({
    key = "daguerreotype",
    atlas = "daguerreotype",
    pos = { x = 0, y = 0 },
    cost = 4,
    weight = 0.5,
    loc_txt = {
        name = "Daguerreotype",
        text = {
            "Cleanse all {C:canlaugh_glitter}Glitter{} from",
            "your {C:attention}Jokers{} and {C:attention}playing cards{}",
            "Gain {C:money}25%{} of the lost sell value",
            "{C:inactive}(Max of {C:money}$50{C:inactive}, currently: {C:money}$#1#{C:inactive}){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            vars = {
                canlaugh_daguerreotype_payout(),
            },
        }
    end,
    can_use = function(self, card)
        return canlaugh_rules_card_active()
            or #canlaugh_collect_glitter_cards() > 0
    end,
    use = function(self, card, area, copier)
        local used_spectral = copier or card
        local glitter_cards = canlaugh_collect_glitter_cards()
        local payout = canlaugh_daguerreotype_payout(glitter_cards)

        if #glitter_cards == 0 then
            if canlaugh_rules_card_active() then
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.4,
                    func = function()
                        play_sound("tarot1")
                        used_spectral:juice_up(0.3, 0.5)
                        return true
                    end,
                }))
                delay(0.1)
            end

            return
        end

        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.4,
            func = function()
                play_sound("tarot1")
                used_spectral:juice_up(0.3, 0.5)
                return true
            end,
        }))

        for _, target in ipairs(glitter_cards) do
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.08,
                func = function()
                    if target and not target.removed and canlaugh_is_glitter(target) then
                        play_sound("whoosh2", 1.1, 0.45)
                        target:set_edition(nil, true, true)
                        target:juice_up(0.3, 0.3)
                    end
                    return true
                end,
            }))
        end

        if payout > 0 then
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.2,
                func = function()
                    ease_dollars(payout)
                    card_eval_status_text(used_spectral, "dollars", payout)
                    return true
                end,
            }))
        end

        delay(0.3)
    end,
})
