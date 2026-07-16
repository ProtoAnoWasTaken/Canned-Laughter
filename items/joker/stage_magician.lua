SMODS.Atlas({
    key = "stage_magician",
    path = "stage_magician.png",
    px = 69,
    py = 93,
})

local CL = CannedLaughter
local canlaugh_is_glitter = CL.is_glitter
local canlaugh_is_negative = CL.is_negative

local function canlaugh_random_glitter_playing_card()
    local candidates = {}

    for _, playing_card in ipairs(G.playing_cards or {}) do
        if playing_card
            and not playing_card.removed
            and not canlaugh_is_glitter(playing_card)
            and not canlaugh_is_negative(playing_card)
        then
            candidates[#candidates + 1] = playing_card
        end
    end

    if #candidates == 0 then
        return nil
    end

    return pseudorandom_element(candidates, pseudoseed("canlaugh_stage_magician"))
end

local function canlaugh_apply_stage_magician_glitter(card)
    if card.canlaugh_stage_magician_applied then
        return
    end

    card.canlaugh_stage_magician_applied = true

    local target = canlaugh_random_glitter_playing_card()

    if not target then
        return
    end

    target:set_edition("e_canlaugh_glitter", true)

    if type(card.juice_up) == "function" then
        card:juice_up(0.3, 0.3)
    end

    if type(card_eval_status_text) == "function" then
        card_eval_status_text(card, "extra", nil, nil, nil, {
            message = "Glitter!",
            colour = G.C.CANLAUGH_GLITTER,
        })
    end
end

SMODS.Joker({
    key = "stage_magician",
    name = "Stage Magician",
    atlas = "stage_magician",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    config = {
        extra = {
            chips = 15,
        },
    },
    loc_txt = {
        name = "Stage Magician",
        text = {
            "Applies {C:canlaugh_glitter,T:e_canlaugh_glitter}Glitter{} to one random",
            "{C:attention}playing card{} when acquired",
            "Cards with {C:canlaugh_glitter,T:e_canlaugh_glitter}Glitter{} give",
            "{C:chips}+#1#{} Chips when scored",
        },
    },
    loc_vars = function(self, info_queue, card)
        if G and G.P_CENTERS and G.P_CENTERS.e_canlaugh_glitter then
            CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS.e_canlaugh_glitter, card)
        end

        local extra = card and card.ability and card.ability.extra or self.config.extra

        return {
            vars = {
                extra.chips,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    add_to_deck = function(self, card, from_debuff)
        if from_debuff then
            return
        end

        canlaugh_apply_stage_magician_glitter(card)
    end,
    calculate = function(self, card, context)
        if context.individual
            and context.cardarea == G.play
            and context.other_card
            and canlaugh_is_glitter(context.other_card)
        then
            return {
                chips = card.ability.extra.chips,
                card = card,
            }
        end
    end,
})
