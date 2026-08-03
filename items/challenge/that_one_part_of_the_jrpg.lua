local JRPG_MONEY_BANNED_CARDS = {
    "c_devil",
    "c_hermit",
    "c_immolate",
    "c_magician",
    "c_talisman",
    "c_temperance",
    "c_canlaugh_daguerreotype",
    "c_canlaugh_final_hoax",
    "c_canlaugh_fire_witch",
    "c_canlaugh_yellow_jester",
    "j_business",
    "j_certificate",
    "j_cloud_9",
    "j_delayed_grat",
    "j_egg",
    "j_faceless",
    "j_gift",
    "j_golden",
    "j_ticket",
    "j_mail",
    "j_matador",
    "j_midas_mask",
    "j_reserved_parking",
    "j_rocket",
    "j_rough_gem",
    "j_satellite",
    "j_to_the_moon",
    "j_trading",
    "j_canlaugh_alchemist",
    "j_canlaugh_christmas_card",
    "j_canlaugh_dark_pentacle",
    "j_canlaugh_envelope",
    "j_canlaugh_goldbeard",
    "j_canlaugh_robber_baron",
    "j_canlaugh_rules_card",
    "m_gold",
    "m_lucky",
    "Gold",
}

local JRPG_DISPLAY_BANNED_CARDS = {
    "c_devil",
    "c_hermit",
    "c_immolate",
    "c_magician",
    "c_talisman",
    "c_temperance",
    "c_canlaugh_daguerreotype",
    "c_canlaugh_final_hoax",
    "c_canlaugh_fire_witch",
    "c_canlaugh_yellow_jester",
    "j_business",
    "j_certificate",
    "j_cloud_9",
    "j_delayed_grat",
    "j_egg",
    "j_faceless",
    "j_gift",
    "j_golden",
    "j_ticket",
    "j_mail",
    "j_matador",
    "j_midas_mask",
    "j_reserved_parking",
    "j_rocket",
    "j_rough_gem",
    "j_satellite",
    "j_to_the_moon",
    "j_trading",
    "j_canlaugh_alchemist",
    "j_canlaugh_christmas_card",
    "j_canlaugh_dark_pentacle",
    "j_canlaugh_envelope",
    "j_canlaugh_goldbeard",
    "j_canlaugh_robber_baron",
    "j_canlaugh_rules_card",
}

local function canlaugh_jrpg_display_banned_cards()
    local banned_cards = {}

    for _, key in ipairs(JRPG_DISPLAY_BANNED_CARDS) do
        banned_cards[#banned_cards + 1] = {
            id = key,
        }
    end

    return banned_cards
end

SMODS.Challenge({
    key = "that_one_part_of_the_jrpg",
    loc_txt = {
        name = "That One Part of the JRPG",
    },
    rules = {
        custom = {
            { id = "canlaugh_jrpg_start" },
            { id = "canlaugh_jrpg_scaling" },
            { id = "canlaugh_jrpg_no_small_big_reward" },
            { id = "canlaugh_jrpg_win" },
        },
        modifiers = {},
    },
    jokers = {},
    consumeables = {},
    vouchers = {},
    deck = {
        type = "Challenge Deck",
    },
    restrictions = {
        banned_cards = canlaugh_jrpg_display_banned_cards(),
        banned_tags = {},
        banned_other = {},
    },
    apply = function(self)
        G.GAME.banned_keys = G.GAME.banned_keys or {}
        for _, key in ipairs(JRPG_MONEY_BANNED_CARDS) do
            G.GAME.banned_keys[key] = true
        end
        G.GAME.round_resets.ante = 0
        G.GAME.round_resets.blind_ante = 0
        G.GAME.modifiers.scaling = 3
        G.GAME.modifiers.no_blind_reward = {
            Small = true,
            Big = true,
        }
        G.GAME.win_ante = 10
        G.GAME.perscribed_bosses = G.GAME.perscribed_bosses or {}
        G.GAME.perscribed_bosses[10] = "bl_canlaugh_spilled_vessel"
        CannedLaughter.force_challenge_boss(get_new_boss())
    end,
})
