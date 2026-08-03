local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local PRIME_RANKS = {
    [2] = true,
    [3] = true,
    [5] = true,
    [7] = true,
    [11] = true,
    [13] = true,
}

local function canlaugh_dionysus_main_start()
    local rolls = {}

    for roll = 0, 13 do
        rolls[#rolls + 1] = tostring(roll)
    end

    return {
        {
            n = G.UIT.T,
            config = {
                text = "Retrigger scored prime ranks ",
                colour = G.C.UI.TEXT_DARK,
                scale = 0.32,
            },
        },
        {
            n = G.UIT.O,
            config = {
                object = DynaText({
                    string = rolls,
                    colours = { G.C.RED },
                    pop_in_rate = 9999999,
                    silent = true,
                    random_element = true,
                    pop_delay = 0.5,
                    scale = 0.32,
                    min_cycle_time = 0,
                }),
            },
        },
        {
            n = G.UIT.O,
            config = {
                object = DynaText({
                    string = {
                        { string = " time(s)", colour = G.C.UI.TEXT_DARK },
                        { string = " rand()", colour = G.C.JOKER_GREY },
                        { string = " #@JK", colour = G.C.RED },
                    },
                    colours = { G.C.UI.TEXT_DARK },
                    pop_in_rate = 9999999,
                    silent = true,
                    random_element = true,
                    pop_delay = 0.2011,
                    scale = 0.32,
                    min_cycle_time = 0,
                }),
            },
        },
    }
end

local function canlaugh_dionysus_prime_copies(rank, scoring_hand)
    local count = 0

    for _, playing_card in ipairs(scoring_hand or {}) do
        if playing_card:get_id() == rank then
            count = count + 1
        end
    end

    return count
end

local function canlaugh_dionysus_roll(card, target)
    local seed = table.concat({
        "canlaugh_dionysus",
        tostring(card.sort_id or ""),
        tostring(target and target.sort_id or ""),
        tostring(G and G.GAME and G.GAME.round or ""),
        tostring(G and G.GAME and G.GAME.current_round and G.GAME.current_round.hands_played or ""),
    }, "_")

    return pseudorandom(pseudoseed(seed), 0, 13)
end

SMODS.Atlas({
    key = "dionysus",
    path = "dionysus.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "dionysus",
    name = "Divine Jester",
    atlas = "dionysus",
    pos = { x = 0, y = 0 },
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
            min_repetitions = 0,
            max_repetitions = 13,
        },
    },
    loc_txt = {
        name = "Divine Jester",
        text = {
            "",
            "Plus once for every other scored",
            "card of the same rank",
            "{C:inactive}(2, 3, 5, 7, J, K){}",
        },
        unlock = {
            "{C:inactive,s:1.3}??????{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return {
            key = CL.all_challenges_completed() and "j_canlaugh_dionysus_revealed" or nil,
            vars = {},
            main_start = canlaugh_dionysus_main_start(),
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
    in_pool = function()
        return CL.dionysus_unlocked()
    end,
    check_for_unlock = function(self, args)
        return CL.dionysus_unlocked()
            and args
            and args.type == "ach_canlaugh_still_the_best_522_bce"
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.repetition
            and context.cardarea == G.play
            and context.other_card
            and PRIME_RANKS[context.other_card:get_id()]
        then
            local rank = context.other_card:get_id()
            local base_repetitions = canlaugh_dionysus_roll(card, context.other_card)
            local same_rank_repetitions = canlaugh_dionysus_prime_copies(rank, context.scoring_hand) - 1
            local repetitions = base_repetitions + same_rank_repetitions

            if repetitions > 0 then
                return {
                    message = localize("k_again_ex"),
                    repetitions = repetitions,
                    card = card,
                }
            end
        end
    end,
})
