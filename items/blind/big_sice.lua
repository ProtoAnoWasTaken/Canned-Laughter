local CL = CannedLaughter
SMODS.Atlas({
    key = "big_sice",
    path = "blind_sice.png",
    px = 34,
    py = 34,
    atlas_table = "ANIMATION_ATLAS",
    frames = 21,
})

CL.register_alternate_big_blind({
    key = "sice",
    atlas = "big_sice",
    boss_colour = HEX("4BC292"),
    loc_txt = {
        name = "The Sice",
        text = {
            "After scoring, #1# in #2# chance",
            "to raise the goal by 25%",
        },
    },
    loc_vars = function(self)
        local numerator, denominator = SMODS.get_probability_vars(self, 1, 6, "canlaugh_big_sice")

        return {
            vars = {
                numerator,
                denominator,
            },
        }
    end,
    calculate = function(self, blind, context)
        if not (context and context.after and context.scoring_hand) then
            return
        end

        local round = G and G.GAME and G.GAME.current_round
        local hands_played = round and round.hands_played or 0

        if not CL.big_blind_roll(
            self,
            "canlaugh_big_sice_" .. tostring(hands_played),
            "canlaugh_big_sice"
        ) then
            return
        end

        blind.chips = blind.chips * 1.25
        blind.chip_text = number_format(blind.chips)
        CL.refresh_big_blind_goal()
    end,
})
