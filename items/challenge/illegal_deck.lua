SMODS.Challenge({
    key = "illegal_deck",
    loc_txt = {
        name = "Illegal Deck",
    },
    rules = {
        custom = {
            { id = "canlaugh_illegal_deck_debuff" },
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
        banned_cards = {},
        banned_tags = {},
        banned_other = {},
    },
    apply = function(self)
        local enhancement_tarots = {
            "c_magician",
            "c_empress",
            "c_hierophant",
            "c_lovers",
            "c_chariot",
            "c_justice",
            "c_devil",
            "c_tower",
        }
        local edition_spectrals = {
            "c_aura",
            "c_canlaugh_vibe",
        }

        G.E_MANAGER:add_event(Event({
            func = function()
                local tarot = pseudorandom_element(enhancement_tarots, pseudoseed("canlaugh_illegal_deck_tarot"))
                local spectral = pseudorandom_element(edition_spectrals, pseudoseed("canlaugh_illegal_deck_spectral"))

                SMODS.add_card({
                    key = tarot,
                    area = G.consumeables,
                    bypass_discovery_center = true,
                })
                SMODS.add_card({
                    key = spectral,
                    area = G.consumeables,
                    bypass_discovery_center = true,
                })
                return true
            end,
        }))
    end,
})
