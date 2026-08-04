local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local BT = CL.barter
local DECK_KEY = "b_canlaugh_deck_before"
local EXECUTIONER_TAG_KEY = "tag_canlaugh_executioner"
local RARE_SPECTRAL_KEYS = {
    "c_soul",
    "c_black_hole",
    "c_canlaugh_tessellation",
    "c_canlaugh_crimson_king",
    "c_canlaugh_city_keeper",
    "c_canlaugh_retrospect",
}

local function canlaugh_deck_before_active()
    local selected_back = G and G.GAME and G.GAME.selected_back
    local center = selected_back and selected_back.effect and selected_back.effect.center

    return center and center.key == DECK_KEY
end

local function canlaugh_profile()
    return G
        and G.PROFILES
        and G.SETTINGS
        and G.PROFILES[G.SETTINGS.profile]
end

local function canlaugh_deck_before_unlocked()
    local current_profile = canlaugh_profile()
    local career_stats = current_profile and current_profile.career_stats

    return career_stats and career_stats.canlaugh_soul_barter_cashed_out == true
end

local function canlaugh_unlock_deck_before()
    local current_profile = canlaugh_profile()
    if not current_profile then
        return
    end

    current_profile.career_stats = current_profile.career_stats or {}
    current_profile.career_stats.canlaugh_soul_barter_cashed_out = true

    if type(check_for_unlock) == "function" then
        check_for_unlock({ type = "canlaugh_soul_barter_cashed_out" })
    end

    if G and type(G.save_progress) == "function" then
        G:save_progress()
    end
end

local function canlaugh_rare_spectral_pool()
    local pool = {}

    for _, key in ipairs(RARE_SPECTRAL_KEYS) do
        if G and G.P_CENTERS and G.P_CENTERS[key] then
            pool[#pool + 1] = key
        end
    end

    return pool
end

local function canlaugh_legendary_joker_pool()
    local pool = {}

    for _, center in ipairs(G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Joker or {}) do
        local rarity = center.rarity or (center.config and center.config.rarity)
        if center.key and (rarity == 4 or rarity == "Legendary" or rarity == "legendary") then
            pool[#pool + 1] = center.key
        end
    end

    return pool
end

local function canlaugh_is_legendary_joker(card)
    local center = card and card.config and card.config.center
    local rarity = center and (center.rarity or (center.config and center.config.rarity))

    return rarity == 4 or rarity == "Legendary" or rarity == "legendary"
end

local function canlaugh_starting_rare_spectral()
    local pool = canlaugh_rare_spectral_pool()
    local key = pseudorandom_element(pool, pseudoseed("canlaugh_deck_before_spectral"))

    if not (key and G and G.E_MANAGER and Event) then
        return false
    end

    G.E_MANAGER:add_event(Event({
        func = function()
            if not G.consumeables then
                return false
            end

            local card = create_card(
                "Spectral",
                G.consumeables,
                nil,
                nil,
                nil,
                nil,
                key,
                "canlaugh_deck_before_spectral"
            )
            card:add_to_deck()
            G.consumeables:emplace(card)
            return true
        end,
    }))

    return true
end

if BT and type(BT.finish_reward_phase) == "function" and not CL.deck_before_soul_cashout_hook_installed then
    CL.deck_before_soul_cashout_hook_installed = true
    local finish_reward_phase_ref = BT.finish_reward_phase

    function BT.finish_reward_phase(...)
        for _, card in ipairs(BT.reward_cards or {}) do
            local center = card and card.config and card.config.center
            if card and not card.canlaugh_barter_claimed and center and center.key == "c_soul" then
                canlaugh_unlock_deck_before()
                break
            end
        end

        return finish_reward_phase_ref(...)
    end
end

if SMODS and type(SMODS.create_card) == "function" and not CL.deck_before_legendary_shop_smods_hook_installed then
    CL.deck_before_legendary_shop_smods_hook_installed = true
    local smods_create_card_ref = SMODS.create_card

    function SMODS.create_card(args)
        local is_shop_joker = args
            and (args.set == "Joker" or args.type == "Joker")
            and args.area == G.shop_jokers

        if is_shop_joker
            and canlaugh_deck_before_active()
            and pseudorandom(pseudoseed("canlaugh_deck_before_legendary_shop")) < 0.01
        then
            local legendary_key = pseudorandom_element(
                canlaugh_legendary_joker_pool(),
                pseudoseed("canlaugh_deck_before_legendary_choice")
            )

            if legendary_key then
                local replacement_args = {}
                for argument_key, argument_value in pairs(args) do
                    replacement_args[argument_key] = argument_value
                end
                replacement_args.key = legendary_key
                args = replacement_args
            end
        end

        return smods_create_card_ref(args)
    end
end

if type(create_card) == "function" and not CL.deck_before_legendary_shop_hook_installed then
    CL.deck_before_legendary_shop_hook_installed = true
    local create_card_ref = create_card

    function create_card(card_type, area, legendary, rarity, skip_materialize, soulable, key, seed, ...)
        if card_type == "Joker"
            and area == G.shop_jokers
            and not legendary
            and not key
            and canlaugh_deck_before_active()
            and pseudorandom(pseudoseed("canlaugh_deck_before_legendary_shop")) < 0.01
        then
            key = pseudorandom_element(
                canlaugh_legendary_joker_pool(),
                pseudoseed("canlaugh_deck_before_legendary_choice")
            )
        end

        return create_card_ref(card_type, area, legendary, rarity, skip_materialize, soulable, key, seed, ...)
    end
end

if Card and type(Card.sell_card) == "function" and not CL.deck_before_legendary_sell_hook_installed then
    CL.deck_before_legendary_sell_hook_installed = true
    local sell_card_ref = Card.sell_card

    function Card:sell_card(...)
        local grants_executioner_tag = canlaugh_deck_before_active()
            and self.area == G.jokers
            and canlaugh_is_legendary_joker(self)

        if grants_executioner_tag and type(add_tag) == "function" and Tag then
            add_tag(Tag(EXECUTIONER_TAG_KEY))
        end

        return sell_card_ref(self, ...)
    end
end

SMODS.Atlas({
    key = "deck_before",
    path = "deck_before.png",
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "deck_before",
    name = "The Deck Before",
    atlas = "deck_before",
    pos = { x = 0, y = 0 },
    order = 29,
    unlocked = false,
    config = {},
    loc_txt = {
        name = "The Deck Before",
        text = {
            "Start with a random",
            "rare {C:spectral}Spectral{} card",
            "{C:legendary}Legendary{} Jokers may appear",
            "in the shop, and may",
            "be {C:attention,T:tag_canlaugh_executioner}executed{}",
        },
        unlock = {
            "Cash out {C:spectral}The Soul{}",
            "after bartering for it",
        },
    },
    check_for_unlock = function(self, args)
        return canlaugh_deck_before_unlocked()
            or (args and args.type == "canlaugh_soul_barter_cashed_out")
    end,
    apply = function()
        if G
            and G.GAME
            and not G.GAME.canlaugh_deck_before_spectral_created
            and canlaugh_starting_rare_spectral()
        then
            G.GAME.canlaugh_deck_before_spectral_created = true
        end
    end,
})
