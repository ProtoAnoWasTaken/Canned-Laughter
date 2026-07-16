SMODS.Atlas({
    key = "death_card",
    path = "deathcard.png",
    px = 69,
    py = 93,
})

if CannedLaughter.barter then
    CannedLaughter.barter.register_rep_modifier("death_card", function(phase, context)
        if phase == "availability" and context.booster_kind == "Spectral" then context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_death_card") or {}); return end
        if phase == "hand" and context.booster_kind == "Spectral" then
            local center = G.P_CENTERS and G.P_CENTERS.c_grim
            if center then
                for _, joker in ipairs(SMODS.find_card("j_canlaugh_death_card") or {}) do
                    CannedLaughter.barter.add_collection_rep(center, "Spectral", joker)
                end
            end
        end
    end)
end

local function canlaugh_face_cards()
    local cards = {}

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card
            and not playing_card.removed
            and not playing_card.destroyed
            and type(playing_card.is_face) == "function"
            and playing_card:is_face()
        then
            cards[#cards + 1] = playing_card
        end
    end

    return cards
end

local function canlaugh_destroy_playing_card(card)
    if not card then
        return
    end

    if SMODS and type(SMODS.destroy_cards) == "function" then
        SMODS.destroy_cards(card, {
            bypass_eternal = true,
            immediate = true,
        })
    elseif type(card.start_dissolve) == "function" then
        card.destroyed = true
        card:start_dissolve()
    end
end

local function canlaugh_create_ace_of_spades()
    if not (G and G.P_CARDS and G.P_CARDS.S_A and G.deck and type(create_playing_card) == "function") then
        return
    end

    local new_card = create_playing_card({
        front = G.P_CARDS.S_A,
        center = G.P_CENTERS and G.P_CENTERS.c_base,
    }, G.deck, nil, nil, nil)

    if type(playing_card_joker_effects) == "function" and new_card then
        playing_card_joker_effects({ new_card })
    end
end

local function canlaugh_create_ace_of_spades_after_destruction()
    if G and G.E_MANAGER and type(Event) == "function" then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.8,
            func = function()
                canlaugh_create_ace_of_spades()
                return true
            end,
        }))
        return
    end

    canlaugh_create_ace_of_spades()
end

SMODS.Joker({
    key = "death_card",
    name = "Death Card",
    atlas = "death_card",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    loc_txt = {
        name = "Death Card",
        text = {
            "When {C:attention}Blind{} is selected,",
            "destroy a random {C:attention}face card{}",
            "and create an {C:spades}Ace of Spades{}",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.setting_blind and not context.blueprint then
            local face_cards = canlaugh_face_cards()
            local target = #face_cards > 0
                and pseudorandom_element(face_cards, pseudoseed("canlaugh_death_card"))

            if not target then
                return
            end

            canlaugh_destroy_playing_card(target)
            canlaugh_create_ace_of_spades_after_destruction()

            return {
                message = "Transformed!",
                colour = G.C.SPADES,
            }
        end
    end,
})
