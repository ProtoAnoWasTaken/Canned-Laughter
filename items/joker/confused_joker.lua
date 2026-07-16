local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({ key = "confused_joker", path = "confused_joker.png", px = 69, py = 93 })

local function common_joker_center(card)
    local pool = {}
    for _, center in ipairs(G.P_CENTER_POOLS.Joker or {}) do
        if center.rarity == 1 and center.key ~= "j_canlaugh_confused_joker" then pool[#pool + 1] = center end
    end
    return #pool > 0 and pseudorandom_element(pool, pseudoseed("canlaugh_confused_" .. tostring(card.sort_id or ""))) or nil
end

local function copied_center(card)
    local key = card and card.ability and card.ability.extra and card.ability.extra.copied_key
    return key and G.P_CENTERS and G.P_CENTERS[key] or nil
end

local function copied_joker_ability(card, center)
    local extra = card.ability.extra
    if extra.copied_ability_key == center.key and extra.copied_ability then
        return extra.copied_ability
    end

    local config = center.config or {}
    local ability = {
        name = center.name,
        effect = center.effect,
        set = center.set,
        mult = config.mult or 0,
        h_mult = config.h_mult or 0,
        h_x_mult = config.h_x_mult or 0,
        h_dollars = config.h_dollars or 0,
        p_dollars = config.p_dollars or 0,
        t_mult = config.t_mult or 0,
        t_chips = config.t_chips or 0,
        x_mult = config.Xmult or config.x_mult or 1,
        h_chips = config.h_chips or 0,
        x_chips = config.x_chips or 1,
        h_x_chips = config.h_x_chips or 1,
        repetitions = config.repetitions or 0,
        h_size = config.h_size or 0,
        d_size = config.d_size or 0,
        extra = copy_table(config.extra) or nil,
        type = config.type or "",
        order = center.order,
    }
    for key, value in pairs(config) do
        ability[key] = type(value) == "table" and copy_table(value) or value
    end

    if ability.name == "To Do List" then
        local hands = {}
        for key in pairs(G.GAME.hands) do
            if SMODS.is_poker_hand_visible(key) then hands[#hands + 1] = key end
        end
        ability.to_do_poker_hand = pseudorandom_element(hands, pseudoseed("canlaugh_confused_to_do"))
    elseif ability.name == "Loyalty Card" then
        ability.burnt_hand = 0
        ability.loyalty_remaining = ability.extra.every
    elseif ability.name == "Yorick" then
        ability.yorick_discards = ability.extra.discards
    elseif ability.name == "Caino" then
        ability.caino_xmult = 1
    elseif ability.name == "Invisible Joker" then
        ability.invis_rounds = 0
    end

    extra.copied_ability_key = center.key
    extra.copied_ability = ability
    return ability
end

local function with_copied_joker(card, center, callback)
    local old_center, old_center_key, old_ability = card.config.center, card.config.center_key, card.ability
    card.config.center = center
    card.config.center_key = center.key
    card.ability = copied_joker_ability(card, center)
    local results = { pcall(callback) }

    if type(old_ability.extra) == "table" and type(card.ability.extra) == "table" then
        for key, value in pairs(card.ability.extra) do
            old_ability.extra[key] = type(value) == "table" and copy_table(value) or value
        end
    end

    card.config.center, card.config.center_key, card.ability = old_center, old_center_key, old_ability
    if not results[1] then error(results[2]) end
    return unpack(results, 2)
end

if type(copy_card) == "function" and not CL.confused_copy_hook_installed then
    CL.confused_copy_hook_installed = true
    local copy_card_ref = copy_card
    function copy_card(other, ...)
        if CL.confused_invisible_copy and other then
            local center = CL.confused_invisible_center
                or (other.config and other.config.center and other.config.center.key == "j_canlaugh_confused_joker"
                    and copied_center(other))
            if center then
                local copied = copy_card_ref(other, ...)
                if copied and copied.set_ability then copied:set_ability(center, nil, true) end
                return copied
            end
        end
        return copy_card_ref(other, ...)
    end
end

if Card and type(Card.add_to_deck) == "function" and type(Card.remove_from_deck) == "function"
    and CL.confused_lifecycle_hook_version ~= 1
then
    CL.confused_lifecycle_hook_version = 1
    CL.confused_add_to_deck_ref = Card.add_to_deck
    CL.confused_remove_from_deck_ref = Card.remove_from_deck

    function Card:add_to_deck(...)
        local args = { ... }
        local center = self.config and self.config.center and self.config.center.key == "j_canlaugh_confused_joker"
            and copied_center(self)
        if center then
            return with_copied_joker(self, center, function()
                return CL.confused_add_to_deck_ref(self, unpack(args))
            end)
        end
        return CL.confused_add_to_deck_ref(self, unpack(args))
    end

    function Card:remove_from_deck(...)
        local args = { ... }
        local center = self.config and self.config.center and self.config.center.key == "j_canlaugh_confused_joker"
            and copied_center(self)
        if center then
            return with_copied_joker(self, center, function()
                return CL.confused_remove_from_deck_ref(self, unpack(args))
            end)
        end
        return CL.confused_remove_from_deck_ref(self, unpack(args))
    end
end

if Card and type(Card.calculate_joker) == "function" and CL.confused_calculate_hook_version ~= 2 then
    CL.confused_calculate_hook_version = 2
    local calculate_joker_ref = Card.calculate_joker
    function Card:calculate_joker(context, ...)
        local args = { ... }
        local is_confused = self.config and self.config.center
            and self.config.center.key == "j_canlaugh_confused_joker"

        if is_confused then
            if context and context.setting_blind and not context.blueprint then
                local old_center = copied_center(self)
                if old_center and CL.confused_remove_from_deck_ref then
                    with_copied_joker(self, old_center, function()
                        local added_to_deck = self.added_to_deck
                        self.added_to_deck = true
                        CL.confused_remove_from_deck_ref(self)
                        self.added_to_deck = added_to_deck
                    end)
                end

                local center = common_joker_center(self)
                self.ability.extra.copied_key = center and center.key or nil
                self.ability.extra.copied_ability_key = nil
                self.ability.extra.copied_ability = nil
                if center then
                    copied_joker_ability(self, center)
                    if CL.confused_add_to_deck_ref then
                        with_copied_joker(self, center, function()
                            local added_to_deck = self.added_to_deck
                            self.added_to_deck = false
                            CL.confused_add_to_deck_ref(self)
                            self.added_to_deck = added_to_deck
                        end)
                    end
                end
                return center and { message = "?", colour = G.C.FILTER } or nil
            end

            local center = copied_center(self)
            if center and not (context and context.setting_blind) then
                return with_copied_joker(self, center, function()
                    local copied_is_invisible = self.ability.name == "Invisible Joker"
                    if copied_is_invisible then
                        CL.confused_invisible_copy = true
                        CL.confused_invisible_center = center
                    end
                    local results = { pcall(calculate_joker_ref, self, context, unpack(args)) }
                    CL.confused_invisible_copy = nil
                    CL.confused_invisible_center = nil
                    if not results[1] then error(results[2]) end
                    return unpack(results, 2)
                end)
            end
        end

        local is_invisible = self.ability and self.ability.name == "Invisible Joker"
            and self.ability.invis_rounds and self.ability.extra
            and self.ability.invis_rounds >= self.ability.extra
            and context and context.end_of_round and not context.blueprint
        if is_invisible then CL.confused_invisible_copy = true end
        local results = { pcall(calculate_joker_ref, self, context, unpack(args)) }
        CL.confused_invisible_copy = nil
        if not results[1] then error(results[2]) end
        return unpack(results, 2)
    end
end

SMODS.Joker({
    key = "confused_joker",
    name = "Confused Joker",
    atlas = "confused_joker",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    config = { extra = { copied_key = nil } },
    loc_txt = { name = "Confused Joker", text = {
        "At the start of each round,",
        "gain the traits of a random",
        "{C:blue}Common{} Joker",
        "{C:inactive}(Currently: {C:attention}#1#{C:inactive}){}",
    } },
    loc_vars = function(self, info_queue, card)
        local center = copied_center(card)
        if center then
            CannedLaughter.add_unique_tooltip(info_queue, center, card)
        end

        return {
            vars = { center and localize({ type = "name_text", set = center.set, key = center.key }) or "None" },
        }
    end,
})

if CannedLaughter.barter then
    CannedLaughter.barter.register_rep_modifier("confused_joker", function(phase, context)
        if phase == "availability" and context.booster_kind == "Buffoon" then context.extra_reps = context.extra_reps + 2 * #(SMODS.find_card("j_canlaugh_confused_joker") or {}); return end
        if phase == "hand" and context.booster_kind == "Buffoon" then
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_confused_joker") or {}) do
                for _, rarity in ipairs({ 1, 2 }) do
                    local rep = CannedLaughter.barter.random_buffoon_rep(rarity,
                        tostring(joker.sort_id or "") .. "_confused_" .. tostring(rarity))
                    if rep then CannedLaughter.barter.add_rep(rep, joker) end
                end
            end
        end
    end)
end
