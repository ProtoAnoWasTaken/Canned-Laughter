SMODS.Atlas({
    key = "trickster_joker",
    path = "trickster_joker.png",
    px = 69,
    py = 93,
})

local CL = CannedLaughter
local canlaugh_is_glitter = CL.is_glitter

local function canlaugh_glitter_joker_count()
    local count = 0

    for _, joker in ipairs((G.jokers and G.jokers.cards) or {}) do
        if canlaugh_is_glitter(joker) then
            count = count + 1
        end
    end

    return count
end

SMODS.Joker({
    key = "trickster_joker",
    name = "Trickster Joker",
    atlas = "trickster_joker",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 6,
    loc_txt = {
        name = "Trickster Joker",
        text = {
            "{X:mult,C:white}X#1#{} Mult for every",
            "{C:attention}Joker{} with {C:canlaugh_glitter,T:e_canlaugh_glitter}Glitter{}",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        if G and G.P_CENTERS and G.P_CENTERS.e_canlaugh_glitter then
            CannedLaughter.add_unique_tooltip(info_queue, G.P_CENTERS.e_canlaugh_glitter, card)
        end

        return {
            vars = {
                1,
                math.max(1, canlaugh_glitter_joker_count()),
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            local count = canlaugh_glitter_joker_count()

            if count > 1 then
                return {
                    x_mult = count,
                }
            end
        end
    end,
})
