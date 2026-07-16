SMODS.Atlas({
    key = "lucky_seven",
    path = "lucky_seven.png",
    px = 69,
    py = 93,
})

local function canlaugh_lucky_seven_full_scoring_hand(args)
    if not (args and args.scoring_hand and args.full_hand and G.hand and G.hand.config) then
        return false
    end

    local play_limit = G.GAME
        and G.GAME.starting_params
        and G.GAME.starting_params.play_limit
        or 5

    if #args.full_hand ~= play_limit or #args.scoring_hand ~= #args.full_hand then
        return false
    end

    for _, playing_card in ipairs(args.scoring_hand) do
        if playing_card:get_id() ~= 7 then
            return false
        end
    end

    return true
end

SMODS.Joker({
    key = "lucky_seven",
    name = "Lucky Seven",
    atlas = "lucky_seven",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 9,
    unlocked = false,
    loc_txt = {
        name = "Lucky Seven",
        text = {
            "Each scored {C:attention}7{} is retriggered",
            "for each other scored {C:attention}7{}",
        },
        unlock = {
            "Play a full hand of",
            "scoring {C:attention}7s{}",
        },
    },
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args
            and args.type == "hand"
            and canlaugh_lucky_seven_full_scoring_hand(args)
    end,
    calculate = function(self, card, context)
        if context.repetition
            and context.cardarea == G.play
            and context.other_card:get_id() == 7
        then
            local scored_sevens = 0

            for _, playing_card in ipairs(context.scoring_hand or {}) do
                if playing_card:get_id() == 7 then
                    scored_sevens = scored_sevens + 1
                end
            end

            if scored_sevens > 1 then
                return {
                    repetitions = scored_sevens - 1,
                }
            end
        end
    end,
})
