local function canned_laughter_joker_pool()
    local pool = {}

    for _, center in ipairs(G.P_CENTER_POOLS and G.P_CENTER_POOLS.Joker or {}) do
        local rarity = center.rarity or (center.config and center.config.rarity)
        local is_canned_laughter = type(center.key) == "string"
            and center.key:match("^j_canlaugh_")

        if is_canned_laughter
            and center.unlocked
            and (rarity == 1 or rarity == 2)
            and not center.no_pool_flag
        then
            pool[#pool + 1] = center
        end
    end

    return pool
end

SMODS.Atlas({
    key = "barred_deck",
    path = "barred_deck.png",
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "barred_deck",
    name = "Barred Deck",
    atlas = "barred_deck",
    pos = { x = 0, y = 0 },
    order = 27,
    unlocked = true,

    config = {},

    loc_txt = {
        name = "Barred Deck",
        text = {
            "Start the run with any",
            "{C:canned_laughter}Canned Laughter{} Joker",
            "{C:inactive}(Cannot be rarer than Uncommon)",
        },
    },

    apply = function(self, back)
        G.E_MANAGER:add_event(Event({
            func = function()
                local pool = canned_laughter_joker_pool()

                if #pool > 0 then
                    local center = pseudorandom_element(
                        pool,
                        pseudoseed("canlaugh_barred_deck")
                    )
                    local card = create_card(
                        "Joker",
                        G.jokers,
                        nil,
                        nil,
                        nil,
                        nil,
                        center.key,
                        "canlaugh_barred_deck"
                    )

                    card:add_to_deck()
                    G.jokers:emplace(card)
                end

                return true
            end,
        }))
    end,
})
