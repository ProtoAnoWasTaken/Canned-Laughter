local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.colored_tarot = CL.colored_tarot or {}
CL.consumables = CL.consumables or {}

local special_keys = {
    "c_soul",
    "c_black_hole",
    "c_canlaugh_city_keeper",
    "c_canlaugh_crimson_king",
    "c_canlaugh_retrospect",
    "c_canlaugh_tessellation",
    "c_canlaugh_virtual_insanity",
}

function CL.colored_tarot.pool()
    local pool = {}
    local seen = {}

    for _, center in pairs(G.P_CENTERS or {}) do
        local is_colored_tarot = center.set == "Tarot" and center.weight == 0.5
        local is_canned_laughter_tarot = center.set == "Tarot"
            and type(center.key) == "string"
            and center.key:match("^c_canlaugh_")
            and center.key ~= "c_canlaugh_wheel_of_fate"
            and center.key ~= "c_canlaugh_etiology"
            and center.key ~= "c_canlaugh_virtual_insanity"

        if is_colored_tarot or is_canned_laughter_tarot then
            pool[#pool + 1] = center
            seen[center.key] = true
        end
    end

    if CL.rules_card_active and CL.rules_card_active() then
        for _, key in ipairs(special_keys) do
            local center = G.P_CENTERS and G.P_CENTERS[key]
            if center and not seen[key] then
                pool[#pool + 1] = center
                seen[key] = true
            end
        end
    end

    return pool
end

function CL.colored_tarot.random_center(seed)
    local pool = CL.colored_tarot.pool()
    if #pool == 0 then
        return nil
    end

    return pseudorandom_element(pool, pseudoseed(seed or "canlaugh_colored_tarot"))
end

function CL.consumables.selected_hand_cards(minimum, maximum)
    local cards = G and G.hand and G.hand.highlighted or {}
    if #cards < (minimum or 1) or #cards > (maximum or minimum or 1) then
        return nil
    end

    return cards
end

function CL.consumables.sort_left_to_right(cards)
    local sorted = {}
    for _, card in ipairs(cards or {}) do
        sorted[#sorted + 1] = card
    end

    table.sort(sorted, function(left, right)
        local left_x = left.T and left.T.x or 0
        local right_x = right.T and right.T.x or 0
        return left_x < right_x
    end)

    return sorted
end

function CL.consumables.tarot_flip(card, callback)
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.15,
        func = function()
            card:flip()
            play_sound("card1", 1, 0.6)
            return true
        end,
    }))
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.2,
        func = function()
            callback()
            return true
        end,
    }))
    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0.15,
        func = function()
            card:flip()
            play_sound("tarot2", 1, 0.6)
            card:juice_up(0.3, 0.3)
            return true
        end,
    }))
end

function CL.consumables.rank_center(id)
    for _, rank in pairs(SMODS.Ranks or {}) do
        if rank.id == id or rank.sort_id == id - 1 then
            return rank
        end
    end
end

function CL.consumables.can_target_jokers()
    for _, card in ipairs(G and G.consumeables and G.consumeables.cards or {}) do
        local key = card.config and card.config.center and card.config.center.key
        if key == "c_canlaugh_use_the_force" or key == "c_canlaugh_transcend" then
            return true
        end
    end
    return false
end

if CardArea and type(CardArea.add_to_highlighted) == "function" and not CL.consumables_joker_selection_hook_installed then
    CL.consumables_joker_selection_hook_installed = true
    local add_to_highlighted_ref = CardArea.add_to_highlighted

    function CardArea:add_to_highlighted(card, silent, ...)
        if self == G.jokers and CL.consumables.can_target_jokers() then
            self.config.highlighted_limit = math.max(self.config.highlighted_limit or 1, 2)
        end
        return add_to_highlighted_ref(self, card, silent, ...)
    end
end
