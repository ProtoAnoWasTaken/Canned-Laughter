local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_masked_joker_boss_active(blind)
    blind = blind or (G and G.GAME and G.GAME.blind)
    if not blind then
        return false
    end

    if type(blind.get_type) == "function" then
        return blind:get_type() == "Boss"
    end

    return blind.boss == true
end

local function canlaugh_masked_joker_active()
    local jokers = G and G.jokers and G.jokers.cards or {}

    for _, joker in ipairs(jokers) do
        local center = joker.config and joker.config.center
        if center and center.key == "j_canlaugh_masked_joker"
            and not joker.debuff
            and not joker.getting_sliced
            and not joker.removed then
            return true
        end
    end

    return false
end

SMODS.Atlas({
    key = "masked_joker",
    path = "masked_joker.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "masked_joker",
    name = "Masked Joker",
    atlas = "masked_joker",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    loc_txt = {
        name = "Masked Joker",
        text = {
            "Prevent debuffs caused",
            "by {C:attention}Boss Blinds{}",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if canlaugh_masked_joker_boss_active() and (context.debuff_card or context.debuff_hand) then
            return {
                prevent_debuff = true,
            }
        end
    end,
})

if Blind and type(Blind.debuff_card) == "function" and not CL.masked_joker_debuff_card_hook_installed then
    CL.masked_joker_debuff_card_hook_installed = true
    local canlaugh_masked_joker_debuff_card = Blind.debuff_card

    function Blind:debuff_card(target, from_blind)
        if canlaugh_masked_joker_boss_active(self) and canlaugh_masked_joker_active() then
            if target and target.debuffed_by_blind and type(target.set_debuff) == "function" then
                target:set_debuff(false)
            end

            if target then
                target.debuffed_by_blind = false
            end

            return
        end

        return canlaugh_masked_joker_debuff_card(self, target, from_blind)
    end
end

if Blind and type(Blind.debuff_hand) == "function" and not CL.masked_joker_debuff_hand_hook_installed then
    CL.masked_joker_debuff_hand_hook_installed = true
    local canlaugh_masked_joker_debuff_hand = Blind.debuff_hand

    function Blind:debuff_hand(cards, hand, handname, check)
        if canlaugh_masked_joker_boss_active(self) and canlaugh_masked_joker_active() then
            self.triggered = false
            SMODS.debuff_text = nil
            SMODS.hand_debuff_source = nil
            return false
        end

        return canlaugh_masked_joker_debuff_hand(self, cards, hand, handname, check)
    end
end
