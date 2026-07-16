local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "secretino_back",
    path = "secretino_back.png",
    px = 69,
    py = 93,
})

SMODS.Atlas({
    key = "secretino_front",
    path = "secretino_joker.png",
    px = 69,
    py = 93,
})

local function canlaugh_secretino_hand_kind_count()
    local count = 0

    if G and G.GAME and G.GAME.hands then
        for _, hand_key in ipairs(G.handlist or {}) do
            if G.GAME.hands[hand_key] then
                count = count + 1
            end
        end
    end

    if count > 0 then
        return count
    end

    return 13
end

local function canlaugh_secretino_unlock_secret_hands()
    if not (G and G.GAME and G.GAME.hands) then
        return 0
    end

    local unlocked = 0

    for _, hand_key in ipairs(G.handlist or {}) do
        local hand = G.GAME.hands[hand_key]

        if hand
            and hand.visible == false
            and (hand.played or 0) == 0
        then
            hand.visible = true
            unlocked = unlocked + 1
        end
    end

    return unlocked
end

local function canlaugh_secretino_ensure_counter(card)
    local extra = card and card.ability and card.ability.extra

    if not extra then
        return canlaugh_secretino_hand_kind_count()
    end

    local hand_kinds = canlaugh_secretino_hand_kind_count()
    extra.hands_left = extra.hands_left or hand_kinds

    return hand_kinds
end

local function canlaugh_secretino_tick(card)
    local extra = card and card.ability and card.ability.extra

    if not extra then
        return
    end

    local hand_kinds = canlaugh_secretino_ensure_counter(card)
    extra.hands_left = (extra.hands_left or hand_kinds) - 1

    if extra.hands_left > 0 then
        return
    end

    repeat
        extra.x_mult = (extra.x_mult or 1) * (extra.x_mult_gain or 2)
        extra.hands_left = extra.hands_left + hand_kinds
    until extra.hands_left > 0

    if type(card_eval_status_text) == "function" then
        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = localize({ type = "variable", key = "a_xmult", vars = { extra.x_mult } }),
            colour = G.C.MULT,
        })
    end
end

SMODS.Joker({
    key = "secretino",
    name = "Secretino",
    atlas = "secretino_back",
    soul_atlas = "secretino_front",
    pos = { x = 0, y = 0 },
    soul_pos = { x = 0, y = 0 },
    rarity = 4,
    cost = 20,
    unlocked = false,
    unlock_condition = {
        type = "",
        extra = "",
        hidden = true,
    },
    config = {
        extra = {
            x_mult = 1,
            x_mult_gain = 2,
            hands_left = nil,
        },
    },
    loc_txt = {
        name = "Secretino",
        text = {
            "Unlocks all unplayed",
            "{C:attention}secret hands{}",
            "Gains {X:mult,C:white}X#1#{} Mult every",
            "{C:attention}#2#{} hands played",
            "{C:inactive}(Hands left: #3#){}",
            "{C:inactive}(Currently {X:mult,C:white}X#4#{C:inactive} Mult){}",
        },
        unlock = {
            "{C:inactive,s:1.3}??????{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        local hand_kinds = canlaugh_secretino_hand_kind_count()

        CannedLaughter.add_unique_tooltip(info_queue, {
            key = "canlaugh_card_artist",
            set = "Other",
            vars = { "Faowbot" },
        }, card)

        return {
            vars = {
                extra.x_mult_gain,
                hand_kinds,
                extra.hands_left or hand_kinds,
                extra.x_mult or 1,
            },
        }
    end,
    locked_loc_vars = function(self, info_queue, card)
        if not (G and G.P_CENTERS and G.P_CENTERS.c_soul and G.P_CENTERS.c_soul.discovered) then
            return {
                not_hidden = true,
                vars = {},
            }
        end

        return {
            key = "joker_locked_legendary",
            set = "Other",
            vars = {},
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    add_to_deck = function(self, card, from_debuff)
        if not from_debuff then
            canlaugh_secretino_unlock_secret_hands()
        end

        canlaugh_secretino_ensure_counter(card)
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            canlaugh_secretino_unlock_secret_hands()
            canlaugh_secretino_ensure_counter(card)
        end

        if context.after and not context.blueprint then
            canlaugh_secretino_tick(card)
        end

        if context.joker_main and (card.ability.extra.x_mult or 1) > 1 then
            return {
                x_mult = card.ability.extra.x_mult,
            }
        end
    end,
})
