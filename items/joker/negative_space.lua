SMODS.Atlas({
    key = "negative_space",
    path = "negativespace.png",
    px = 69,
    py = 93,
})

local CL = rawget(_G, "CannedLaughter") or {}
_G.CannedLaughter = CL

local function canlaugh_has_negative_space()
    if not (G and G.jokers and G.jokers.cards) then
        return false
    end

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker and joker.config and joker.config.center
        if center and center.key == "j_canlaugh_negative_space" then
            return true
        end
    end

    return false
end

local function canlaugh_suit_counts(cards)
    local counts = {}

    for _, playing_card in ipairs(cards or {}) do
        for _, suit_key in ipairs(SMODS.Suit.obj_buffer or {}) do
            if playing_card:is_suit(suit_key, nil, true) then
                counts[suit_key] = (counts[suit_key] or 0) + 1
            end
        end
    end

    return counts
end

local function canlaugh_has_suit_majority(cards)
    local majority = math.floor(#(cards or {}) / 2) + 1

    for _, count in pairs(canlaugh_suit_counts(cards)) do
        if count >= majority then
            return true
        end
    end

    return false
end

local function canlaugh_apply_negative_space(poker_hands)
    if not (poker_hands and canlaugh_has_negative_space()) then
        return
    end

    if next(poker_hands["Full House"] or {}) and not next(poker_hands["Flush House"] or {}) then
        poker_hands["Flush House"] = poker_hands["Full House"]
    end

    if next(poker_hands["Four of a Kind"] or {}) and not next(poker_hands["Five of a Kind"] or {}) then
        local four_kind = poker_hands["Four of a Kind"]
        if canlaugh_has_suit_majority(four_kind[1] or {}) then
            poker_hands["Flush Five"] = four_kind
        else
            poker_hands["Five of a Kind"] = four_kind
        end
    end
end

if not CL.negative_space_hook_installed then
    CL.negative_space_hook_installed = true
    local canlaugh_get_poker_hand_info_ref = G.FUNCS.get_poker_hand_info

    G.FUNCS.get_poker_hand_info = function(_cards)
        local text, loc_disp_text, poker_hands, scoring_hand, disp_text =
            canlaugh_get_poker_hand_info_ref(_cards)

        canlaugh_apply_negative_space(poker_hands)

        if next(poker_hands["Flush Five"] or {}) then
            text = "Flush Five"
            scoring_hand = poker_hands["Flush Five"][1]
        elseif next(poker_hands["Flush House"] or {}) then
            text = "Flush House"
            scoring_hand = poker_hands["Flush House"][1]
        elseif next(poker_hands["Five of a Kind"] or {}) then
            text = "Five of a Kind"
            scoring_hand = poker_hands["Five of a Kind"][1]
        end

        if text == "Flush Five" or text == "Flush House" or text == "Five of a Kind" then
            disp_text = text
            loc_disp_text = localize(disp_text, "poker_hands")
        end

        return text, loc_disp_text, poker_hands, scoring_hand, disp_text
    end
end

SMODS.Joker({
    key = "negative_space",
    name = "Negative Space",
    atlas = "negative_space",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    loc_txt = {
        name = "Negative Space",
        text = {
            "{C:attention}Poker hands{} may contribute",
            "to their closest {C:attention}secret hand{}",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
})

if CL.barter then
    CL.barter.register_rep_modifier("negative_space", function(phase, context)
        if phase == "pool" and context.booster_kind == "Celestial"
            and #(SMODS.find_card("j_canlaugh_negative_space") or {}) > 0
        then
            for _, rep in ipairs(context.pool or {}) do
                if rep.hand_key == "Full House" or rep.hand_key == "Four of a Kind" then
                    rep.secret = true
                    rep.negative_space_parity = true
                end
            end
        end
    end)
end
