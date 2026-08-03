local CL = rawget(_G, "CannedLaughter") or {}

SMODS.Atlas({
    key = "transcend",
    path = "transcend.png",
    px = 71,
    py = 95,
})

local function black_stake_or_higher()
    local current = G.P_CENTER_POOLS.Stake[G.GAME.stake]
    local black = G.P_STAKES.stake_black
    return current and black and (current.stake_level or current.order) >= (black.stake_level or black.order)
end

local function selected_jokers(required)
    local jokers = G.jokers.highlighted or {}
    if #jokers == required then
        return jokers
    end
end

local function can_modify_eternal(card)
    return card and card.ability and not card.ability.perishable
end

SMODS.Spectral({
    key = "transcend",
    atlas = "transcend",
    pos = { x = 0, y = 0 },
    cost = 4,
    config = { max_highlighted = 2 },
    loc_txt = {
        name = "Transcend",
        text = {
            "Apply or remove an {C:attention}Eternal{}",
            "{C:attention}Sticker{} on {C:attention}1{} selected Joker",
            "{C:inactive}(Cannot have {C:attention}Perishable{C:inactive}){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        CL.add_unique_tooltip(info_queue, {
            key = "eternal",
            set = "Other",
        }, card)

        if black_stake_or_higher() then
            return {
                key = "c_canlaugh_transcend_black",
                set = "Spectral",
            }
        end

        return {
            vars = {},
        }
    end,
    can_use = function()
        local cards = selected_jokers(black_stake_or_higher() and 2 or 1)
        if not cards then return false end
        if black_stake_or_higher() then
            return cards[1].ability.eternal and not cards[2].ability.eternal and can_modify_eternal(cards[2])
        end
        return can_modify_eternal(cards[1])
    end,
    use = function(self, card, area, copier)
        local cards = selected_jokers(black_stake_or_higher() and 2 or 1)
        if not cards then return end
        CL.tarot.juice_used_consumable(copier or card)
        if black_stake_or_higher() then
            cards[1]:set_eternal(false)
            cards[2]:set_eternal(true)
            cards[1]:juice_up(0.3, 0.3)
            cards[2]:juice_up(0.3, 0.3)
        else
            cards[1]:set_eternal(not cards[1].ability.eternal)
            cards[1]:juice_up(0.3, 0.3)
        end
        delay(0.3)
    end,
})

G.localization.descriptions.Spectral.c_canlaugh_transcend_black = {
    name = "Transcend",
    text = {
        "Select {C:attention}2{} Jokers, transfer an {C:attention}Eternal{}",
        "{C:attention}Sticker{} from one to another",
        "{C:inactive}(Cannot have {C:attention}Perishable{C:inactive}){}",
    },
}
