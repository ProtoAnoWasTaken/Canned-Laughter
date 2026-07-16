local loc = {
    descriptions = {
        Joker = {
            j_canlaugh_resourceful_rat = {
                name = "Resourceful Rat",
                text = {
                    "The last {C:attention}#1# consumable#2#{} you sold",
                    "will {C:red}NOT{} appear in the next",
                    "{C:attention}shop{} or its {C:attention}Booster Packs{}",
                    "{C:inactive}(Currently {C:attention}#3#{C:inactive}){}",
                },
            },
        },
        Other = {
            canlaugh_card_artist = {
                name = "Card Artist",
                text = {
                    "Card art by",
                    "{C:red}#1#{}",
                },
            },
        },
        Mod = {
            CannedLaughter = {
                name = "Canned Laughter",
                text = {
                    "{s:1.2}A Balatro mod made with the intent of{}",
                    "{s:1.2}a bored, amateur scripter.{}",
                    " ",
                    "Programming and management by {C:blue}ProtoAno{}",
                    "and cards edited from Balatro originals by {C:legendary,E:1}LocalThunk{},",
                    "as well as crossover content from various other",
                    "games associated with the {C:attention}Friends of Jimbo{} collabs.",
                    " ",
                    "If this mod contains any additional creators, they will be",
                    "credited where their art is featured in the mod.",
                },
            },
        },
    },
    misc = {
        v_text = {
            ch_c_canlaugh_attrition_after_ante_four = {
                "After {C:attention}Ante 4{}:",
            },
            ch_c_canlaugh_attrition_big_boss = {
                "The {C:attention}Big Blind{} is replaced with a {C:red}Boss Blind{}",
            },
            ch_c_canlaugh_attrition_boss_showdown = {
                "The {C:red}Boss Blind{} is replaced with a {C:attention}Showdown Blind{}",
            },
            ch_c_canlaugh_bananarama_jokers = {
                "Only {C:attention}Banana Jokers{} can appear",
            },
            ch_c_canlaugh_bananarama_import = {
                "{C:attention}Import Tags{} are {C:attention}2X{} more common",
            },
            ch_c_canlaugh_gift_exchange_discard = {
                "On discard, all other cards are discarded instead",
            },
            ch_c_canlaugh_illegal_deck_debuff = {
                "Playing cards are debuffed until enhanced",
            },
            ch_c_canlaugh_glitter_glue_start = {
                "Start with only {C:canlaugh_glitter}Glitter{} playing cards",
            },
            ch_c_canlaugh_glitter_glue_boosters = {
                "All Booster Pack cards are {C:canlaugh_glitter}Glitter{}",
            },
            ch_c_canlaugh_rg_department_win_condition = {
                "Win by {C:attention}Ante 8{} {C:inactive}(or 1 in special circumstances){}",
            },
            ch_c_canlaugh_attack_start = {
                "Start at {C:attention}Ante 0{}",
            },
            ch_c_canlaugh_attack_scaling = {
                "Base chips scale even faster for each Ante",
            },
        },
    },
}

if SMODS and SMODS.current_mod and SMODS.current_mod.manifest then
    local manifest = SMODS.current_mod.manifest
    local mod_desc = loc.descriptions.Mod.CannedLaughter

    if mod_desc and mod_desc.text then
        manifest.description = mod_desc.text
    end
end

return loc
