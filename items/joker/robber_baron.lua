local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "robber_baron",
    path = "robber_baron.png",
    px = 69,
    py = 93,
})

local function robber_baron_source(card)
    return "canlaugh_robber_baron_" .. tostring(card)
end

local function lucky_card(card)
    return card
        and card.playing_card
        and (card.ability and card.ability.effect == "Lucky Card"
            or SMODS and type(SMODS.has_enhancement) == "function" and SMODS.has_enhancement(card, "m_lucky"))
end

local function debuff_lucky_cards(card)
    local source = robber_baron_source(card)
    local count = 0

    for _, playing_card in ipairs(G.playing_cards or {}) do
        local sources = playing_card.ability and playing_card.ability.debuff_sources
        if lucky_card(playing_card) and not (sources and sources[source]) then
            SMODS.debuff_card(playing_card, true, source)
            count = count + 1
            card_eval_status_text(playing_card, "extra", nil, nil, nil, {
                message = localize("k_debuffed"),
                colour = G.C.RED,
            })
        end
    end

    return count
end

local function clear_lucky_card_debuffs(card)
    local source = robber_baron_source(card)

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card.ability and playing_card.ability.debuff_sources and playing_card.ability.debuff_sources[source] ~= nil then
            SMODS.debuff_card(playing_card, false, source)
        end
    end
end

SMODS.Joker({
    key = "robber_baron",
    name = "Robber Baron",
    atlas = "robber_baron",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    loc_txt = {
        name = "Robber Baron",
        text = {
            "When {C:attention}Blind{} is selected,",
            "debuff all {C:attention}Lucky Cards{}",
            "Earn {C:money}$5{} for each",
            "card debuffed this way",
        },
    },
    remove_from_deck = function(self, card, from_debuff)
        if not from_debuff then
            clear_lucky_card_debuffs(card)
        end
    end,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            local count = debuff_lucky_cards(card)
            if count > 0 then
                return {
                    dollars = count * 5,
                }
            end
        end
    end,
})
