SMODS.Atlas({
    key = "the_odyssey",
    path = "the_odyssey.png",
    px = 69,
    py = 93,
})

local function canlaugh_defeated_showdown_on_final_hand()
    local blind = G and G.GAME and G.GAME.blind
    local blind_center = blind and blind.config and blind.config.blind

    return blind_center
        and blind_center.boss
        and blind_center.boss.showdown
        and G.GAME.current_round
        and (G.GAME.current_round.hands_left or 0) == 0
end

SMODS.Joker({
    key = "the_odyssey",
    name = "The Odyssey",
    atlas = "the_odyssey",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = {
        extra = {
            x_mult = 6,
        },
    },
    loc_txt = {
        name = "The Odyssey",
        text = {
            "{X:mult,C:white}X#1#{} Mult on",
            "final hand of round",
        },
        unlock = {
            "Defeat a {C:attention}Showdown Blind{}",
            "on your final hand",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra

        return {
            vars = {
                extra.x_mult,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args
            and args.type == "round_win"
            and canlaugh_defeated_showdown_on_final_hand()
    end,
    calculate = function(self, card, context)
        if context.joker_main
            and G
            and G.GAME
            and G.GAME.current_round
            and (G.GAME.current_round.hands_left or 0) == 0
        then
            return {
                x_mult = card.ability.extra.x_mult,
            }
        end
    end,
})
