local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local VANILLA_SPECTRALS = {
    "c_familiar",
    "c_grim",
    "c_incantation",
    "c_talisman",
    "c_aura",
    "c_wraith",
    "c_sigil",
    "c_ouija",
    "c_ectoplasm",
    "c_immolate",
    "c_ankh",
    "c_deja_vu",
    "c_hex",
    "c_trance",
    "c_medium",
    "c_cryptid",
    "c_soul",
    "c_black_hole",
}

local function canlaugh_all_vanilla_spectrals_discovered()
    for _, key in ipairs(VANILLA_SPECTRALS) do
        local center = G and G.P_CENTERS and G.P_CENTERS[key]
        if not (center and center.discovered) then
            return false
        end
    end

    return true
end

local function canlaugh_gelotomancer_cards(excluded_card)
    local cards = {}

    for _, joker in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local center = joker and joker.config and joker.config.center
        if joker ~= excluded_card
            and center
            and center.key == "j_canlaugh_gelotomancer"
            and not joker.debuff
            and not joker.removed
            and not joker.getting_sliced
        then
            cards[#cards + 1] = joker
        end
    end

    return cards
end

local function canlaugh_gelotomancer_ban_state()
    if not (G and G.GAME) then
        return nil
    end

    G.GAME.banned_keys = G.GAME.banned_keys or {}
    G.GAME.canlaugh_gelotomancer_bans = G.GAME.canlaugh_gelotomancer_bans or {}

    return G.GAME.canlaugh_gelotomancer_bans
end

local function canlaugh_gelotomancer_ban_joker(key)
    if not key then
        return false
    end

    local bans = canlaugh_gelotomancer_ban_state()
    if not bans then
        return false
    end

    if not bans[key] then
        bans[key] = {
            previous = G.GAME.banned_keys[key],
        }
    end

    G.GAME.banned_keys[key] = true
    return true
end

local function canlaugh_gelotomancer_release_bans()
    local bans = canlaugh_gelotomancer_ban_state()
    if not bans then
        return
    end

    for key, record in pairs(bans) do
        G.GAME.banned_keys[key] = record.previous
    end

    G.GAME.canlaugh_gelotomancer_bans = nil
end

local function canlaugh_gelotomancer_gain_for_sale(sold_card)
    local center = sold_card and sold_card.config and sold_card.config.center
    if not (center and center.set == "Joker") then
        return
    end

    if center.key == "j_canlaugh_gelotomancer" then
        canlaugh_gelotomancer_release_bans()
        return
    end

    local gelotomancers = canlaugh_gelotomancer_cards(sold_card)
    if #gelotomancers == 0 then
        return
    end

    canlaugh_gelotomancer_ban_joker(center.key)

    for _, gelotomancer in ipairs(gelotomancers) do
        local extra = gelotomancer.ability and gelotomancer.ability.extra
        if extra then
            extra.x_mult = (extra.x_mult or 1) + (extra.x_mult_gain or 0.25)
            card_eval_status_text(gelotomancer, "extra", nil, nil, nil, {
                message = "X" .. tostring(extra.x_mult) .. " Mult",
                colour = G.C.MULT,
            })
        end
    end
end

local function canlaugh_gelotomancer_random_rep(card)
    local barter = CL.barter
    local candidates = {}

    for _, rep in ipairs((barter and barter.buffoon_reps) or {}) do
        if rep.key ~= "j_canlaugh_gelotomancer"
            and G
            and G.P_CENTERS
            and G.P_CENTERS[rep.key]
        then
            candidates[#candidates + 1] = rep
        end
    end

    if #candidates == 0 then
        return nil
    end

    local template = pseudorandom_element(candidates, pseudoseed(
        "canlaugh_gelotomancer_buffoon_" .. tostring(card and card.sort_id or "")
    ))

    if not template then
        return nil
    end

    return {
        key = template.key,
        set = "Joker",
        kind = "joker",
        rarity = template.rarity,
        output = template.output,
        scaling = template.scaling,
        loc = template.loc,
    }
end

SMODS.Atlas({
    key = "gelotomancer",
    path = "gelotomancer.png",
    px = 69,
    py = 93,
})

SMODS.Joker({
    key = "gelotomancer",
    name = "Gelotomancer",
    atlas = "gelotomancer",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = {
        extra = {
            x_mult = 1,
            x_mult_gain = 0.25,
        },
    },
    loc_txt = {
        name = "Gelotomancer",
        text = {
            "Sold {C:attention}Jokers{} will not appear",
            "in shops or {C:attention}Booster Packs{}",
            "Gain {X:mult,C:white}X#1#{} Mult per Joker sold",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{C:inactive} Mult){}",
        },
        unlock = {
            "Discover every vanilla",
            "{C:spectral}Spectral{} card",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return {
            vars = {
                extra.x_mult_gain,
                extra.x_mult,
            },
        }
    end,
    check_for_unlock = function(self, args)
        return (args and args.type == "canlaugh_all_vanilla_spectrals")
            or canlaugh_all_vanilla_spectrals_discovered()
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                x_mult = card.ability.extra.x_mult,
            }
        end
    end,
})

if Card and type(Card.sell_card) == "function" and not CL.gelotomancer_sell_hook_installed then
    CL.gelotomancer_sell_hook_installed = true
    local sell_card_ref = Card.sell_card

    function Card:sell_card(...)
        canlaugh_gelotomancer_gain_for_sale(self)
        return sell_card_ref(self, ...)
    end
end

if type(discover_card) == "function" and not CL.gelotomancer_discovery_hook_installed then
    CL.gelotomancer_discovery_hook_installed = true
    local discover_card_ref = discover_card

    function discover_card(center, ...)
        local results = {
            discover_card_ref(center, ...),
        }

        if canlaugh_all_vanilla_spectrals_discovered() and type(check_for_unlock) == "function" then
            check_for_unlock({
                type = "canlaugh_all_vanilla_spectrals",
            })
        end

        return unpack(results)
    end
end

if CL.barter then
    CL.barter.register_rep_modifier("gelotomancer", function(phase, context)
        if phase == "availability" and context.booster_kind == "Buffoon" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_canlaugh_gelotomancer") or {})
            return
        end

        if phase == "hand" and context.booster_kind == "Buffoon" then
            for _, joker in ipairs(SMODS.find_card("j_canlaugh_gelotomancer") or {}) do
                local rep = canlaugh_gelotomancer_random_rep(joker)
                if rep then
                    CL.barter.add_rep(rep, joker)
                end
            end
        end
    end)
end
