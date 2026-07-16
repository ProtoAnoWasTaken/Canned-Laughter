local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.barter = CL.barter or {}

local BT = CL.barter

BT.trials = {}
BT.trial_by_key = {}
BT.trial_by_center_key = {}
BT.trial_center_by_key = {}
BT.skip_label = "Skip"
BT.mega_success_hooks = BT.mega_success_hooks or {}
BT.rep_modifiers = BT.rep_modifiers or {}
BT.special_reps = BT.special_reps or {}

local remove_barter_buttons
local representative_pool
local apply_rep_modifiers

function BT.register_mega_success_hook(booster_kind, key, callback)
    if not (booster_kind and key and type(callback) == "function") then
        return
    end

    BT.mega_success_hooks[booster_kind] = BT.mega_success_hooks[booster_kind] or {}
    BT.mega_success_hooks[booster_kind][key] = callback
end

function BT.register_rep_modifier(key, callback)
    if key and type(callback) == "function" then
        BT.rep_modifiers[key] = callback
    end
end

function BT.register_special_rep(booster_kind, center_key, rep)
    if not (booster_kind and center_key and rep) then return end
    BT.special_reps[booster_kind] = BT.special_reps[booster_kind] or {}
    BT.special_reps[booster_kind][center_key] = rep
end

local function available_representative_count(booster_kind)
    local pool = representative_pool(booster_kind)
    apply_rep_modifiers("pool", { booster_kind = booster_kind, pool = pool, preview = true })
    local context = { booster_kind = booster_kind, base_reps = #pool, extra_reps = 0 }
    apply_rep_modifiers("availability", context)
    return #pool + (context.extra_reps or 0)
end

apply_rep_modifiers = function(phase, context)
    for _, callback in pairs(BT.rep_modifiers or {}) do
        callback(phase, context)
    end
end

function BT.dispatch_mega_success(booster_kind)
    for _, callback in pairs((BT.mega_success_hooks and BT.mega_success_hooks[booster_kind]) or {}) do
        local ok, err = pcall(callback)
        if not ok and sendErrorMessage then
            sendErrorMessage("[Canned Laughter] Mega barter reward failed: " .. tostring(err))
        end
    end
end

local function ensure_trial_type()
    if not (G and SMODS) then
        return
    end

    G.P_CENTER_POOLS = G.P_CENTER_POOLS or {}
    G.P_CENTER_POOLS.Trial = G.P_CENTER_POOLS.Trial or {}
    G.C = G.C or {}
    G.C.SET = G.C.SET or {}
    G.C.SECONDARY_SET = G.C.SECONDARY_SET or {}
    G.C.UI = G.C.UI or {}
    G.C.SET.Trial = G.C.SET.Trial or HEX("1b0433")
    G.C.SECONDARY_SET.Trial = G.C.SECONDARY_SET.Trial or HEX("1b0433")
    G.C.UI.Trial = G.C.UI.Trial or HEX("f2d5e3")

    G.localization = G.localization or {}
    G.localization.descriptions = G.localization.descriptions or {}
    G.localization.descriptions.Trial = G.localization.descriptions.Trial or {}
    G.localization.misc = G.localization.misc or {}
    G.localization.misc.dictionary = G.localization.misc.dictionary or {}
    G.localization.misc.dictionary.k_trial = G.localization.misc.dictionary.k_trial or "Trial"
    G.localization.misc.dictionary.b_trial_cards = G.localization.misc.dictionary.b_trial_cards or "Trial Cards"

    if SMODS.ObjectType and not (SMODS.ObjectTypes and SMODS.ObjectTypes.Trial) then
        SMODS.ObjectType({
            key = "Trial",
        })
    end
end

local function center_key_for_trial(def)
    return "c_canlaugh_" .. def.key
end

local function trial_placeholder(def)
    local set = def.placeholder_set or "Tarot"
    local undiscovered = set == "Planet" and G.p_undiscovered
        or set == "Joker" and G.j_undiscovered
        or set == "Spectral" and G.s_undiscovered
        or G.t_undiscovered
    return set, (undiscovered and undiscovered.pos) or { x = 6, y = 2 }
end

local function draw_arcane_trial_icon(card, scale_mod, rotate_mod)
    if not (card and card.children and card.children.floating_sprite and card.children.center) then
        return
    end

    local center = card.config and card.config.center or {}
    local draw_scale = 1.5 + 0.3 * scale_mod
    local configured_offset = center.canlaugh_icon_offset
    local offset = configured_offset or {
        x = 1.5 * card.T.w * (71 - 34) / (2 * 71),
        y = 1.5 * card.T.h * (95 - 34) / (2 * 95),
    }

    card.children.floating_sprite:draw_from(
        card.children.center,
        draw_scale - 1,
        0.3 * rotate_mod,
        offset.x,
        offset.y
    )
end

BT.spectral_reps = BT.spectral_reps or {
    { key = "c_grim", kind = "aces", loc = { "Representative of {C:attention}2{} Aces" } },
    { key = "c_familiar", kind = "faces", loc = { "Representative of {C:attention}6{} face cards" } },
    { key = "c_incantation", kind = "numbers", loc = { "Representative of {C:attention}5{} number cards" } },
    { key = "c_aura", kind = "edition", editions = { foil = true, holo = true }, loc = { "Representative of a {C:dark_edition}Foil{} or {C:dark_edition}Holographic{} card" } },
    { key = "c_hex", kind = "edition", editions = { polychrome = true }, loc = { "Representative of a {C:dark_edition}Polychrome{} card" } },
    { key = "c_ectoplasm", kind = "edition", editions = { negative = true }, loc = { "Representative of a {C:dark_edition}Negative{} card" } },
}

local function spectral_card_edition(card)
    local edition = card and card.edition
    if type(edition) ~= "table" then return nil end
    if edition.polychrome or edition.e_polychrome or edition.key == "e_polychrome" then return "polychrome" end
    if edition.negative or edition.e_negative or edition.key == "e_negative" then return "negative" end
    if edition.foil or edition.e_foil or edition.key == "e_foil" then return "foil" end
    if edition.holo or edition.e_holo or edition.key == "e_holo" then return "holo" end
end

local function spectral_playing_cards()
    local cards = {}
    for _, card in ipairs(G.playing_cards or {}) do cards[#cards + 1] = card end
    for _, card in ipairs(G.jokers and G.jokers.cards or {}) do cards[#cards + 1] = card end
    return cards
end

local function spectral_representative_pool()
    local pool = {}
    local aces, faces, numbers = 0, 0, 0
    local edition_counts = { foil = 0, holo = 0, polychrome = 0, negative = 0 }

    for _, card in ipairs(G.playing_cards or {}) do
        local id = card.base and card.base.id
        if id == 14 or (card.base and card.base.value == "Ace") then
            aces = aces + 1
        elseif type(id) == "number" and id >= 2 and id <= 10 then
            numbers = numbers + 1
        end
        if card.is_face and card:is_face(true) then faces = faces + 1 end
    end

    for _, card in ipairs(spectral_playing_cards()) do
        local edition = spectral_card_edition(card)
        if edition then edition_counts[edition] = edition_counts[edition] + 1 end
    end

    local function add(key, count, metadata)
        local center = G.P_CENTERS and G.P_CENTERS[key]
        if not center then return end
        for i = 1, count do
            local rep = { key = key, set = "Spectral", kind = metadata.kind, loc = metadata.loc }
            rep.identity = key .. "_" .. tostring(i)
            for field, value in pairs(metadata) do rep[field] = value end
            pool[#pool + 1] = rep
        end
    end

    add("c_grim", math.floor(aces / 2), BT.spectral_reps[1])
    add("c_familiar", math.floor(faces / 6), BT.spectral_reps[2])
    add("c_incantation", math.floor(numbers / 5), BT.spectral_reps[3])
    add("c_aura", edition_counts.foil + edition_counts.holo, BT.spectral_reps[4])
    add("c_hex", edition_counts.polychrome, BT.spectral_reps[5])
    add("c_ectoplasm", edition_counts.negative, BT.spectral_reps[6])

    local aura_index = 0
    for _, rep in ipairs(pool) do
        if rep.key == "c_aura" then
            aura_index = aura_index + 1
            rep.edition = aura_index <= edition_counts.foil and "foil" or "holo"
        elseif rep.key == "c_hex" then
            rep.edition = "polychrome"
        elseif rep.key == "c_ectoplasm" then
            rep.edition = "negative"
        end
    end
    return pool
end

local rep_centers = {
    Diamonds = 
    { key = "c_star", kind = "suit", suit = "Diamonds", loc = 
        {
            "Representative of",
            "{C:attention}3{} {C:diamonds}Diamond{} cards",
            "in your deck"
        }
    },
    Clubs = 
    { key = "c_moon", kind = "suit", suit = "Clubs", loc =
        {
            "Representative of",
            "{C:attention}3{} {C:clubs}Club{} cards",
            "in your deck"
        }
    },
    Hearts = 
    { key = "c_sun",  kind = "suit", suit = "Hearts", loc = 
        {
            "Representative of",
            "{C:attention}3{} {C:hearts}Heart{} cards",
            "in your deck"
        }
    },
    Spades = 
    { key = "c_world", kind = "suit", suit = "Spades", loc = 
        { 
            "Representative of",
            "{C:attention}3{} {C:spades}Spade{} cards",
            "in your deck"
        }
    },
    face = 
    { key = "c_strength", kind = "face", loc = 
        { 
            "Representative of",
            "{C:attention}4{} face cards",
            "in your deck"
        }
    },
    stone = 
    { key = "c_tower", kind = "no_suit", loc = 
        {
            "Representative of",
            "{C:attention}1{} card with no suit",
            "in your deck"
        }
    },
    wild = 
    { key = "c_lovers", kind = "multi_suit", loc = 
        {
            "Representative of",
            "{C:attention}1{} card with",
            "more than one suit",
            "in your deck"
        }
    },
}

BT.rep_loc_by_center_key = {}
for _, rep in pairs(rep_centers) do
    BT.rep_loc_by_center_key[rep.key] = rep.loc
end

BT.buffoon_reps = BT.buffoon_reps or {
    { key = "j_joker", rarity = 1, output = "mult", scaling = false, loc = { "Representative of a {C:attention}Common{}", "{C:mult}Mult{} Joker that does not scale" } },
    { key = "j_canlaugh_jester", rarity = 1, output = "chips", scaling = false, loc = { "Representative of a {C:attention}Common{}", "{C:chips}Chips{} Joker that does not scale" } },
    { key = "j_smeared", rarity = 2, output = "effect", scaling = false, loc = { "Representative of an {C:attention}Uncommon{}", "effect-providing Joker that does not scale" } },
    { key = "j_stone", rarity = 2, output = "chips", scaling = true, loc = { "Representative of an {C:attention}Uncommon{}", "{C:chips}Chips{} Joker that scales" } },
    { key = "j_burnt", rarity = 3, output = "effect", scaling = true, loc = { "Representative of a {C:attention}Rare{}", "effect-providing Joker that scales" } },
    { key = "j_ancient", rarity = 3, output = "mult", scaling = false, loc = { "Representative of a {C:attention}Rare{}", "{C:mult}Mult{} Joker that does not scale" } },
    { key = "j_canlaugh_mccready", rarity = 4, output = "mult", scaling = true, loc = { "Representative of a {C:attention}Legendary{}", "{C:mult}Mult{} Joker that scales" } },
    { key = "j_canlaugh_chula_reh", rarity = 4, output = "effect", scaling = true, loc = { "Representative of a {C:attention}Legendary{}", "effect-providing Joker that scales" } },
}

function BT.random_buffoon_rep(rarity, seed_append)
    rarity = tonumber(rarity) or 1
    local candidates = {}
    for _, rep in ipairs(BT.buffoon_reps) do
        if rep.rarity == rarity and G.P_CENTERS and G.P_CENTERS[rep.key] then
            candidates[#candidates + 1] = rep
        end
    end
    if #candidates == 0 then return nil end
    local template = pseudorandom_element(candidates, pseudoseed(
        "canlaugh_buffoon_rarity_" .. tostring(rarity) .. "_" .. tostring(seed_append or "")
    ))
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

local function buffoon_rep_for_joker(card)
    local center = card and card.config and card.config.center
    local rarity = tonumber(center and center.rarity) or 1
    return BT.random_buffoon_rep(rarity, card and card.sort_id)
end
BT.buffoon_rep_for_joker = buffoon_rep_for_joker

local function buffoon_representative_pool()
    local pool = {}

    for _, joker in ipairs(G.jokers and G.jokers.cards or {}) do
        local key = joker.config and joker.config.center and joker.config.center.key
        local rep = key ~= "j_canlaugh_confused_joker" and buffoon_rep_for_joker(joker) or nil
        if rep then pool[#pool + 1] = rep end
    end

    return pool
end

BT.planet_bodies = BT.planet_bodies or {
    c_mercury = "terrestrial",
    c_venus = "terrestrial",
    c_earth = "terrestrial",
    c_mars = "terrestrial",
    c_pluto = "terrestrial",
    c_planet_x = "terrestrial",
    c_ceres = "terrestrial",
    c_eris = "terrestrial",
    c_jupiter = "gaseous",
    c_saturn = "gaseous",
    c_uranus = "gaseous",
    c_neptune = "gaseous",
}

BT.planet_requirements = BT.planet_requirements or {
    ["Pair"] = { pair = true },
    ["Two Pair"] = { pair = true },
    ["Three of a Kind"] = { pair = true },
    ["Full House"] = { pair = true },
    ["Four of a Kind"] = { pair = true },
    ["Five of a Kind"] = { pair = true },
    ["Straight"] = { straight = true },
    ["Flush"] = { flush = true },
    ["Straight Flush"] = { straight = true, flush = true },
    ["Flush House"] = { pair = true, flush = true },
    ["Flush Five"] = { pair = true, flush = true },
}

BT.secret_hand_keys = BT.secret_hand_keys or {
    ["Five of a Kind"] = true,
    ["Flush House"] = true,
    ["Flush Five"] = true,
}

function BT.register_planet_body(planet_key, body)
    if planet_key and (body == "terrestrial" or body == "gaseous") then
        BT.planet_bodies[planet_key] = body
    end
end

function BT.register_planet_requirements(hand_key, requirements)
    if hand_key and type(requirements) == "table" then
        BT.planet_requirements[hand_key] = requirements
    end
end

function BT.planet_body(planet)
    if not planet then
        return nil
    end

    return planet.canlaugh_celestial_body
        or (planet.config and planet.config.canlaugh_celestial_body)
        or BT.planet_bodies[planet.key]
end

function BT.planet_for_hand(hand_key)
    for _, planet in ipairs(G.P_CENTER_POOLS and G.P_CENTER_POOLS.Planet or {}) do
        if planet.config and planet.config.hand_type == hand_key then
            return planet
        end
    end
end

function BT.is_secret_hand(hand_key, hand)
    return BT.secret_hand_keys[hand_key]
        or (hand and hand.canlaugh_celestial_secret)
        or false
end

function BT.has_unlocked_secret_hand()
    for _, hand_key in ipairs(G.handlist or {}) do
        local hand = G.GAME and G.GAME.hands and G.GAME.hands[hand_key]
        if hand and BT.is_secret_hand(hand_key, hand) and hand.visible ~= false then
            return true
        end
    end
    return false
end

local function celestial_representation(center, hand_key, level)
    local secret = BT.is_secret_hand(hand_key, G.GAME and G.GAME.hands and G.GAME.hands[hand_key])
    local body = BT.planet_body(center)
    local hand_name = hand_key
    if type(localize) == "function" then
        hand_name = localize(hand_key, "poker_hands")
    end

    return {
        key = center.key,
        set = center.set or "Planet",
        kind = "planet",
        hand_key = hand_key,
        body = body,
        requirements = BT.planet_requirements[hand_key] or {},
        secret = secret,
        loc = {
            "Representative of {C:attention}" .. tostring(hand_name) .. "{}",
            body and ("{C:inactive}" .. body:sub(1, 1):upper() .. body:sub(2) .. " body{}") or "",
        },
    }
end

local function celestial_representative_pool()
    local pool = {}
    local surplus_levels = 0
    local registered_hands = 0

    for _, hand_key in ipairs(G.handlist or {}) do
        local hand = G.GAME and G.GAME.hands and G.GAME.hands[hand_key]
        if hand then
            registered_hands = registered_hands + 1
            local level = math.max(1, hand.level or 1)
            local copies = math.max(0, level - 1)
            local secret_played = BT.is_secret_hand(hand_key, hand) and (hand.played or 0) > 0
            if secret_played and copies == 0 then
                copies = 1
            end

            local planet = BT.planet_for_hand(hand_key)
            if planet then
                for _ = 1, copies do
                    pool[#pool + 1] = celestial_representation(planet, hand_key, level)
                end
            end
            surplus_levels = surplus_levels + math.max(0, level - 1)
        end
    end

    local black_hole = G.P_CENTERS and G.P_CENTERS.c_black_hole
    if black_hole and registered_hands > 0 then
        local black_holes = math.min(#pool, math.floor(surplus_levels / registered_hands))
        for _ = 1, black_holes do
            local index = math.floor(pseudorandom("canlaugh_barter_black_hole") * #pool) + 1
            table.remove(pool, index)
            pool[#pool + 1] = {
                key = black_hole.key,
                set = black_hole.set or "Spectral",
                kind = "hand_wild",
                loc = {
                    "Representative of any",
                    "{C:attention}poker hand{}",
                },
            }
        end
    end

    return pool
end

function BT.representative_collection_pool(booster_kind)
    if booster_kind == "Celestial" then
        local pool = {}
        for _, center in ipairs(G.P_CENTER_POOLS and G.P_CENTER_POOLS.Planet or {}) do
            pool[#pool + 1] = center
        end
        if G.P_CENTERS and G.P_CENTERS.c_black_hole then
            pool[#pool + 1] = G.P_CENTERS.c_black_hole
        end
        for key in pairs(BT.special_reps[booster_kind] or {}) do
            local center = G.P_CENTERS and G.P_CENTERS[key]
            if center then pool[#pool + 1] = center end
        end
        return pool
    end

    if booster_kind == "Buffoon" then
        local pool = {}
        for _, rep in ipairs(BT.buffoon_reps or {}) do
            local center = G.P_CENTERS and G.P_CENTERS[rep.key]
            if center then pool[#pool + 1] = center end
        end
        for key in pairs(BT.special_reps[booster_kind] or {}) do
            local center = G.P_CENTERS and G.P_CENTERS[key]
            if center then pool[#pool + 1] = center end
        end
        return pool
    end

    if booster_kind == "Spectral" then
        local pool = {}
        for _, rep in ipairs(BT.spectral_reps or {}) do
            local center = G.P_CENTERS and G.P_CENTERS[rep.key]
            if center then pool[#pool + 1] = center end
        end
        for key in pairs(BT.special_reps[booster_kind] or {}) do
            local center = G.P_CENTERS and G.P_CENTERS[key]
            if center then pool[#pool + 1] = center end
        end
        return pool
    end

    local keys = { "c_star", "c_moon", "c_sun", "c_world", "c_strength", "c_tower", "c_lovers" }
    local pool = {}

    for _, key in ipairs(keys) do
        if G.P_CENTERS and G.P_CENTERS[key] then
            pool[#pool + 1] = G.P_CENTERS[key]
        end
    end
    for key in pairs(BT.special_reps[booster_kind] or {}) do
        local center = G.P_CENTERS and G.P_CENTERS[key]
        if center then pool[#pool + 1] = center end
    end

    return pool
end

function BT.collection_representative(center, booster_kind)
    if not center then
        return nil
    end

    local special = BT.special_reps[booster_kind] and BT.special_reps[booster_kind][center.key]
    if special then return copy_table(special) end

    if booster_kind == "Celestial" then
        if center.key == "c_black_hole" then
            return {
                key = center.key,
                set = center.set or "Spectral",
                kind = "hand_wild",
                loc = {
                    "Representative of any",
                    "{C:attention}poker hand{}",
                },
            }
        end

        local hand_key = center.config and center.config.hand_type
        if hand_key then
            local hand = G.GAME and G.GAME.hands and G.GAME.hands[hand_key]
            return celestial_representation(center, hand_key, (hand and hand.level) or 1)
        end
        return nil
    end

    if booster_kind == "Buffoon" then
        for _, buffoon_rep in ipairs(BT.buffoon_reps or {}) do
            if buffoon_rep.key == center.key then
                return {
                    key = center.key,
                    set = "Joker",
                    kind = "joker",
                    rarity = buffoon_rep.rarity,
                    output = buffoon_rep.output,
                    scaling = buffoon_rep.scaling,
                    loc = buffoon_rep.loc,
                }
            end
        end
        return nil
    end

    if booster_kind == "Spectral" then
        for _, spectral_rep in ipairs(BT.spectral_reps or {}) do
            if spectral_rep.key == center.key then
                return {
                    key = center.key,
                    set = "Spectral",
                    kind = spectral_rep.kind,
                    loc = spectral_rep.loc,
                }
            end
        end
        return nil
    end

    local loc = BT.rep_loc_by_center_key and BT.rep_loc_by_center_key[center.key]
    if loc then
        return { kind = "representative", loc = loc }
    end
end

function BT.add_collection_rep(center, booster_kind, source_card)
    local rep = BT.collection_representative(center, booster_kind)
    if rep then BT.add_rep(rep, source_card) end
    return rep
end

function BT.trial_collection_pool(booster_kind)
    local pool = {}
    local seen = {}

    for _, trial in ipairs(BT.trials or {}) do
        if not booster_kind or BT.trial_applies_to_booster(trial, booster_kind) then
            local center = (G.P_CENTERS and trial.center_key and G.P_CENTERS[trial.center_key])
                or (SMODS and SMODS.Centers and trial.center_key and SMODS.Centers[trial.center_key])
                or trial.center
            if center and not seen[center.key] then
                seen[center.key] = true
                pool[#pool + 1] = center
            end
        end
    end

    return pool
end

BT.center_key_for_trial = center_key_for_trial

local function ensure_other_loc(key, name, text)
    if not key then
        return
    end

    local parse_string = type(loc_parse_string) == "function"
        and loc_parse_string
        or function(line)
            return { { strings = { line or "" }, control = {} } }
        end

    local function parsed_lines(lines)
        local parsed = {}
        for _, line in ipairs(lines or {}) do
            if type(line) == "table" then
                local box = {}
                for _, box_line in ipairs(line) do
                    box[#box + 1] = parse_string(box_line)
                end
                parsed[#parsed + 1] = box
            else
                parsed[#parsed + 1] = parse_string(line)
            end
        end
        return parsed
    end

    G.localization = G.localization or {}
    G.localization.descriptions = G.localization.descriptions or {}
    G.localization.descriptions.Other = G.localization.descriptions.Other or {}
    G.localization.descriptions.Other[key] = {
        name = name,
        text = text,
        unlock = {},
        name_parsed = { parse_string(name or key) },
        text_parsed = parsed_lines(text),
        unlock_parsed = {},
    }
end

local function ensure_trial_undiscovered_loc()
    ensure_other_loc("undiscovered_trial", "Not Discovered", {
        "Defeat this trial",
        "to discover it",
    })
end

function BT.representative_loc_center(center_key, tooltip, rep)
    local loc = (rep and rep.loc) or (BT.rep_loc_by_center_key and BT.rep_loc_by_center_key[center_key])
    if not loc then
        return nil
    end

    local rep_suffix = rep and table.concat({ rep.hand_key or "", rep.body or "", rep.kind or "" }, "_") or center_key
    local loc_key = "canlaugh_barter_rep_" .. (tooltip and "tooltip_" or "main_") .. tostring(center_key) .. "_" .. rep_suffix
    local name = "Trial Representation"
    if not tooltip then
        local center = G.P_CENTERS and G.P_CENTERS[center_key]
        local ok, localized_name = pcall(localize, {
            type = "name_text",
            key = center_key,
            set = center and center.set or "Tarot",
        })
        name = ok and localized_name or (center and center.name) or center_key
    end

    ensure_other_loc(loc_key, name, loc)
    return {
        key = loc_key,
        set = "Other",
        name = name,
    }
end

function BT.register_trial(def)
    if not (def and def.key and def.name and def.kind and def.need and def.loc) then
        return
    end

    if BT.trial_by_key[def.key] then
        return BT.trial_by_key[def.key]
    end

    def.booster_kinds = def.booster_kinds or { "Arcana" }
    BT.trials[#BT.trials + 1] = def
    BT.trial_by_key[def.key] = def
    ensure_trial_type()
    local expected_center_key = center_key_for_trial(def)
    ensure_other_loc(expected_center_key, def.name, def.loc)
    ensure_trial_undiscovered_loc()
    G.localization.descriptions.Trial[expected_center_key] = G.localization.descriptions.Other[expected_center_key]

    local placeholder_set, placeholder_pos = trial_placeholder(def)
    local trial_mod = SMODS.current_mod
    local trial_suffix = def.key:match("^[^_]+_(.+)$") or def.key
    local inferred_icon_atlas = trial_mod and trial_mod.prefix
        and (trial_mod.prefix .. "_trial_" .. trial_suffix)
        or nil
    local icon_atlas = def.icon_atlas
        or (inferred_icon_atlas and SMODS.Atlases and SMODS.Atlases[inferred_icon_atlas] and inferred_icon_atlas)
    local icon_pos = icon_atlas and (def.icon_pos or { x = 0, y = 0 })
    local center = SMODS.Center({
        key = def.key,
        name = def.name,
        set = "Trial",
        atlas = placeholder_set,
        canlaugh_placeholder_set = placeholder_set,
        class_prefix = "c",
        prefix_config = {
            atlas = false,
        },
        pos = placeholder_pos,
        soul_atlas = icon_atlas,
        canlaugh_icon_offset = def.icon_offset,
        soul_pos = icon_pos and {
            x = icon_pos.x or 0,
            y = icon_pos.y or 0,
            draw = def.icon_draw or draw_arcane_trial_icon,
        } or nil,
        cost = 0,
        unlocked = true,
        discovered = false,
        consumeable = false,
        config = {
            max_highlighted = 5,
        },
        in_pool = function()
            return false
        end,
        loc_txt = {
            name = def.name,
            text = def.loc,
        },
        can_use = function(self, card)
            return BT.active
                and not BT.play_mode
                and BT.hand_area
                and BT.hand_area.highlighted
                and #BT.hand_area.highlighted > 0
                and (G.GAME.current_round.hands_left or 0) > 0
        end,
        use = function(self, card, area, copier)
            BT.resolve_trial(card)
        end,
    })

    center = center or (SMODS.Centers and SMODS.Centers[expected_center_key])
    center = center or {
        key = expected_center_key,
        original_key = def.key,
        name = def.name,
        set = "Trial",
        atlas = placeholder_set,
        pos = placeholder_pos,
        cost = 0,
        unlocked = true,
        discovered = false,
        consumeable = false,
        config = {
            max_highlighted = 5,
        },
        loc_txt = {
            name = def.name,
            text = def.loc,
        },
        mod = SMODS.current_mod,
        canlaugh_placeholder_set = placeholder_set,
    }
    if center then
        def.center = center
        def.center_key = center.key
        BT.trial_center_by_key[def.key] = center
        BT.trial_by_center_key[center.key] = def
        G.localization.descriptions.Trial[center.key] = G.localization.descriptions.Trial[center.key] or G.localization.descriptions.Other[expected_center_key]
        if G.P_CENTERS then
            G.P_CENTERS[center.key] = G.P_CENTERS[center.key] or center
        end
        if G.P_CENTER_POOLS and G.P_CENTER_POOLS.Trial then
            local found = false
            for _, existing in ipairs(G.P_CENTER_POOLS.Trial) do
                if existing.key == center.key then
                    found = true
                    break
                end
            end
            if not found then
                G.P_CENTER_POOLS.Trial[#G.P_CENTER_POOLS.Trial + 1] = center
            end
        end
    else
        BT.trial_by_center_key[expected_center_key] = def
    end

    return def
end

local function remove_all_from_area(area, dissolve)
    if not (area and area.cards) then
        return
    end

    for i = #area.cards, 1, -1 do
        local card = area.cards[i]
        area:remove_card(card)
        if card then
            if dissolve then
                card:start_dissolve(nil, i == #area.cards)
            else
                card:remove()
            end
        end
    end
end

local function clear_barter_selections()
    local function unhighlight(area)
        if area and type(area.unhighlight_all) == "function" then
            area:unhighlight_all()
        end
    end

    unhighlight(BT.hand_area)
    unhighlight(G and G.pack_cards)
    unhighlight(G and G.consumeables)
end

local function ensure_barter_storage_areas()
    if not (G and G.hand and CardArea) then return end

    if not G.canlaugh_barter_saved_hand then
        G.canlaugh_barter_saved_hand = CardArea(
            G.hand.T.x, G.TILE_H + 3, G.hand.T.w, G.hand.T.h,
            { card_limit = 1000, type = "hand", highlight_limit = 0, no_card_count = true }
        )
    end
    if not G.canlaugh_barter_saved_rewards then
        G.canlaugh_barter_saved_rewards = CardArea(
            G.hand.T.x, G.TILE_H + 5, G.hand.T.w, G.hand.T.h,
            { card_limit = 1000, type = "consumeable", highlight_limit = 0, no_card_count = true }
        )
    end
end

local function remove_barter_storage_areas()
    for _, key in ipairs({ "canlaugh_barter_saved_hand", "canlaugh_barter_saved_rewards" }) do
        local area = G and G[key]
        if area and area.cards and #area.cards == 0 then
            if area.remove then area:remove() end
            G[key] = nil
        end
    end
end

local function opened_booster_card()
    return SMODS and SMODS.OPENED_BOOSTER
end

local function area_position(area)
    if not (area and area.T) then
        return nil
    end

    return {
        x = area.T.x,
        y = area.T.y,
        w = area.T.w,
        h = area.T.h,
    }
end

local function set_area_target(area, pos)
    if not (area and area.T and pos) then
        return
    end

    area.T.x = pos.x or area.T.x
    area.T.y = pos.y or area.T.y
    area.T.w = pos.w or area.T.w
    area.T.h = pos.h or area.T.h
    if area.align_cards then
        area:align_cards()
    end
end

local function move_run_areas_offscreen()
    BT.saved_area_positions = {}

    if G.consumeables then
        BT.saved_area_positions.consumeables = area_position(G.consumeables)
        set_area_target(G.consumeables, {
            x = G.consumeables.T.x,
            y = -G.consumeables.T.h - 1,
        })
    end

    if G.deck then
        BT.saved_area_positions.deck = area_position(G.deck)
        set_area_target(G.deck, {
            x = G.deck.T.x,
            y = G.TILE_H + 1,
        })
    end
end

local function restore_run_areas()
    if not BT.saved_area_positions then
        return
    end

    set_area_target(G.consumeables, BT.saved_area_positions.consumeables)
    set_area_target(G.deck, BT.saved_area_positions.deck)
    BT.saved_area_positions = nil
end

local function refresh_round_counter_ui()
    if not (G and G.HUD and G.HUD.get_UIE_by_ID) then
        return
    end

    local hand_UI = G.HUD:get_UIE_by_ID("hand_UI_count")
    local discard_UI = G.HUD:get_UIE_by_ID("discard_UI_count")
    if hand_UI and hand_UI.config and hand_UI.config.object then
        hand_UI.config.object:update()
    end
    if discard_UI and discard_UI.config and discard_UI.config.object then
        discard_UI.config.object:update()
    end
    G.HUD:recalculate()
end

function BT.is_arcana_booster(center)
    if not center then
        return false
    end

    local key = tostring(center.key or "")
    local name = tostring(center.name or "")
    return center.kind == "Arcana" or key:lower():find("arcana", 1, true) or name:find("Arcana", 1, true)
end

function BT.is_celestial_booster(center)
    if not center then
        return false
    end

    local key = tostring(center.key or "")
    local name = tostring(center.name or "")
    return center.kind == "Celestial" or key:lower():find("celestial", 1, true) or name:find("Celestial", 1, true)
end

function BT.is_buffoon_booster(center)
    if not center then
        return false
    end

    local key = tostring(center.key or "")
    local name = tostring(center.name or "")
    return center.kind == "Buffoon" or key:lower():find("buffoon", 1, true) or name:find("Buffoon", 1, true)
end

function BT.is_spectral_booster(center)
    if not center then return false end
    local key = tostring(center.key or "")
    local name = tostring(center.name or "")
    return center.kind == "Spectral" or key:lower():find("spectral", 1, true) or name:find("Spectral", 1, true)
end

function BT.booster_kind(center)
    if BT.is_arcana_booster(center) then
        return "Arcana"
    end
    if BT.is_celestial_booster(center) then
        return "Celestial"
    end
    if BT.is_buffoon_booster(center) then
        return "Buffoon"
    end
    if BT.is_spectral_booster(center) then
        return "Spectral"
    end
end

function BT.trial_applies_to_booster(trial, booster_kind)
    if not (trial and booster_kind) then
        return false
    end

    for _, kind in ipairs(trial.booster_kinds or {}) do
        if kind == booster_kind then
            return true
        end
    end

    return false
end

function BT.trial_pool_for(booster_kind)
    local pool = {}

    for _, trial in ipairs(BT.trials or {}) do
        if BT.trial_applies_to_booster(trial, booster_kind)
            and (not trial.in_pool or trial.in_pool())
        then
            pool[#pool + 1] = trial
        end
    end

    return pool
end

function BT.required_trials(card)
    local center = card and card.config and card.config.center
    local key = tostring((center and center.key) or (card and card.config and card.config.center_key) or ""):lower()
    local name = tostring((center and center.name) or (card and card.ability and card.ability.name) or ""):lower()

    local privilege = next(SMODS.find_card("j_canlaugh_jesters_privilege") or {}) and 1 or 0
    if key:find("mega", 1, true) or name:find("mega", 1, true) then
        return math.max(1, 3 - privilege)
    end
    if key:find("jumbo", 1, true) or name:find("jumbo", 1, true) then
        return math.max(1, 3 - privilege)
    end
    return 1
end

local function minimum_representatives_for(card)
    return 3 * BT.required_trials(card)
end

local function is_jumbo_booster(card)
    local center = card and card.config and card.config.center
    local key = tostring((center and center.key) or ""):lower()
    local name = tostring((center and center.name) or ""):lower()
    return key:find("jumbo", 1, true) or name:find("jumbo", 1, true)
end

function BT.is_mega_booster(card)
    local center = card and card.config and card.config.center
    local key = tostring((center and center.key) or ""):lower()
    local name = tostring((center and center.name) or ""):lower()
    return key:find("mega", 1, true) or name:find("mega", 1, true)
end

function BT.can_start()
    local booster_card = opened_booster_card()
    local center = booster_card and booster_card.config and booster_card.config.center
    local booster_kind = BT.booster_kind(center)

    return not BT.active
        and not BT.reward_phase
        and not BT.starting
        and not (booster_card and booster_card.canlaugh_barter_locked)
        and G
        and G.pack_cards
        and G.pack_cards.cards
        and #G.pack_cards.cards > 0
        and G.hand
        and G.hand.cards
        and booster_kind
        and #BT.trial_pool_for(booster_kind) > 0
        and available_representative_count(booster_kind) >= minimum_representatives_for(booster_card)
end

local function is_stone(card)
    return card
        and card.config
        and card.config.center
        and (card.config.center.key == "m_stone" or card.config.center.replace_base_card or (card.ability and card.ability.effect == "Stone Card"))
end

local function is_wild(card)
    if not card then
        return false
    end

    local harlequin_active = next(SMODS.find_card("j_canlaugh_harlequin") or {}) ~= nil
    if harlequin_active and card.is_face and card:is_face(true) then
        return true
    end

    return type(SMODS.has_any_suit) == "function"
        and SMODS.has_any_suit(card)
end

representative_pool = function(booster_kind)
    if booster_kind == "Celestial" then
        return celestial_representative_pool()
    end

    if booster_kind == "Buffoon" then
        return buffoon_representative_pool()
    end

    if booster_kind == "Spectral" then
        return spectral_representative_pool()
    end

    local counts = {
        Diamonds = 0,
        Clubs = 0,
        Hearts = 0,
        Spades = 0,
        face = 0,
        stone = 0,
        wild = 0,
    }

    for _, card in ipairs(G.playing_cards or {}) do
        if not card.canlaugh_barter_rep then
            if is_stone(card) or (type(SMODS.has_no_suit) == "function" and SMODS.has_no_suit(card)) then
                counts.stone = counts.stone + 1
            elseif is_wild(card) then
                counts.wild = counts.wild + 1
            else
                local suit = card.base and card.base.suit
                if counts[suit] then
                    counts[suit] = counts[suit] + 1
                end
                if card.is_face and card:is_face(true) then
                    counts.face = counts.face + 1
                end
            end
        end
    end

    local pool = {}
    local function add_reps(count_key, rep)
        local cards_per_rep = ({ face = 4, stone = 1, wild = 1 })[count_key] or 3
        for _ = 1, math.floor((counts[count_key] or 0) / cards_per_rep) do
            pool[#pool + 1] = rep
        end
    end

    add_reps("Diamonds", rep_centers.Diamonds)
    add_reps("Clubs", rep_centers.Clubs)
    add_reps("Hearts", rep_centers.Hearts)
    add_reps("Spades", rep_centers.Spades)
    add_reps("face", rep_centers.face)
    add_reps("stone", rep_centers.stone)
    add_reps("wild", rep_centers.wild)

    return pool
end

function BT.has_representatives_for(booster_kind)
    return available_representative_count(booster_kind) > 0
end

local function take_random_rep()
    if not (BT.rep_pool and #BT.rep_pool > 0) then
        return nil
    end

    local idx = math.floor(pseudorandom("canlaugh_barter_rep") * #BT.rep_pool) + 1
    local rep = BT.rep_pool[idx]
    table.remove(BT.rep_pool, idx)
    return rep
end

local function create_representative_card(rep)
    local args = {
        set = rep.set or "Tarot",
        area = BT.hand_area,
        key = rep.key,
        no_edition = true,
        skip_materialize = true,
        key_append = "canlaugh_barter_rep",
    }
    local banned_keys = G and G.GAME and G.GAME.banned_keys
    local bypass_resourceful_ban = rep.key
        and banned_keys
        and banned_keys[rep.key]
        and CL.resourceful_ban_active
        and CL.resourceful_ban_active(rep.key)

    if not bypass_resourceful_ban then
        return SMODS.create_card(args)
    end

    local previous_ban = banned_keys[rep.key]
    banned_keys[rep.key] = nil
    local results = { pcall(SMODS.create_card, args) }
    banned_keys[rep.key] = previous_ban

    if not results[1] then
        error(results[2])
    end

    table.remove(results, 1)
    return unpack(results)
end

function BT.draw_reps(count)
    if not BT.hand_area then
        return
    end

    for _ = 1, count do
        if #BT.hand_area.cards >= BT.hand_area.config.card_limit then
            return
        end

        local rep = take_random_rep()
        if not rep then
            return
        end

        BT.draw_rep(rep)
    end
end

function BT.draw_rep(rep)
    if not (rep and BT.hand_area and BT.hand_area.cards and BT.hand_area.config) then
        return false
    end

    if #BT.hand_area.cards >= BT.hand_area.config.card_limit then
        return false
    end

    local card
    if rep.set == "Joker" and G.P_CENTERS and G.P_CENTERS[rep.key] then
        card = Card(
            BT.hand_area.T.x + BT.hand_area.T.w / 2,
            BT.hand_area.T.y,
            G.CARD_W,
            G.CARD_H,
            G.P_CARDS.empty,
            G.P_CENTERS[rep.key],
            { bypass_discovery_center = true, bypass_discovery_ui = true }
        )
    else
        card = create_representative_card(rep)
    end

    if not card then
        return false
    end

    card.canlaugh_barter_rep = rep
    card.canlaugh_no_consumeable_use_button = true
    card.states.visible = true
    BT.hand_area:emplace(card)
    card.states.drag.can = false
    card:start_materialize({ G.C.WHITE, G.C.WHITE }, nil, 0.7 * G.SETTINGS.GAMESPEED)
    return true
end

function BT.add_rep(rep, source_card)
    if not rep then return false end
    local dealt = BT.active and BT.draw_rep(rep)

    if not dealt then
        BT.bonus_rep_queue = BT.bonus_rep_queue or {}
        BT.bonus_rep_queue[#BT.bonus_rep_queue + 1] = rep
    end

    if source_card then
        if type(source_card.juice_up) == "function" then source_card:juice_up(0.3, 0.3) end
        if type(card_eval_status_text) == "function" then
            card_eval_status_text(source_card, "extra", nil, nil, nil, {
                message = "+Rep",
                colour = G.C.FILTER,
            })
        end
    end
    return true
end

local function deal_bonus_reps_after_first_trial()
    if BT.bonus_reps_dealt or not (BT.hand_area and BT.bonus_rep_queue) then return end
    BT.bonus_reps_dealt = true

    local bonus_reps = BT.bonus_rep_queue
    BT.bonus_rep_queue = {}
    if #bonus_reps == 0 then return end

    BT.hand_area.config.card_limit = math.max(
        BT.hand_area.config.card_limit or 0,
        #BT.hand_area.cards + #bonus_reps
    )
    local normal_pool = BT.rep_pool
    BT.rep_pool = bonus_reps
    BT.draw_reps(#bonus_reps)
    BT.rep_pool = normal_pool
end

local function tuck_real_hand()
    BT.saved_hand_cards = {}
    ensure_barter_storage_areas()

    if G.hand then
        if G.hand.states then G.hand.states.visible = false end
        G.hand:unhighlight_all()
        for i = 1, #G.hand.cards do
            BT.saved_hand_cards[i] = G.hand.cards[i]
        end
        for i = #BT.saved_hand_cards, 1, -1 do
            local card = BT.saved_hand_cards[i]
            G.hand:remove_card(card)
            if card then
                card.states.visible = false
                card.states.hover.can = false
                card.T.y = G.TILE_H + 2
                card.T.r = 0
                if G.canlaugh_barter_saved_hand then
                    G.canlaugh_barter_saved_hand:emplace(card)
                end
            end
        end
    end
end

local function tuck_late_real_hand_cards()
    if not (BT.active and G.hand and G.hand.cards and BT.saved_hand_cards) then
        return
    end

    local tucked = false
    for i = #G.hand.cards, 1, -1 do
        local card = G.hand.cards[i]
        if card and not card.canlaugh_barter_rep then
            BT.saved_hand_cards[#BT.saved_hand_cards + 1] = card
            G.hand:remove_card(card)
            card.states.visible = false
            card.states.hover.can = false
            card.T.y = G.TILE_H + 2
            card.T.r = 0
            if G.canlaugh_barter_saved_hand then
                G.canlaugh_barter_saved_hand:emplace(card)
            end
            tucked = true
        end
    end

    if tucked and G.hand.align_cards then
        G.hand:align_cards()
    end
end

local function schedule_late_hand_tucks()
    if not (G.E_MANAGER and Event) then
        tuck_late_real_hand_cards()
        return
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = 0,
        timer = "REAL",
        blocking = false,
        blockable = false,
        func = function()
            tuck_late_real_hand_cards()
            return not BT.active
        end,
    }))
end

local function restore_real_hand()
    if not (G.hand and BT.saved_hand_cards) then
        return
    end

    BT.restoring_real_hand = true
    if G.hand.states then G.hand.states.visible = true end
    for _, card in ipairs(BT.saved_hand_cards) do
        if card then
            if card.area then card.area:remove_card(card) end
            card.states.visible = true
            card.states.hover.can = true
            G.hand:emplace(card)
        end
    end
    BT.restoring_real_hand = nil
    BT.saved_hand_cards = nil
    remove_barter_storage_areas()
end

if CardArea and type(CardArea.emplace) == "function" and not BT.real_hand_emplace_wrapped then
    BT.real_hand_emplace_wrapped = true
    local card_area_emplace_ref = CardArea.emplace

    function CardArea:emplace(card, ...)
        local results = { card_area_emplace_ref(self, card, ...) }
        if G and self == G.hand
            and BT.active
            and not BT.restoring_real_hand
            and card
            and not card.canlaugh_barter_rep
        then
            ensure_barter_storage_areas()
            BT.saved_hand_cards = BT.saved_hand_cards or {}
            BT.saved_hand_cards[#BT.saved_hand_cards + 1] = card
            self:remove_card(card)
            card.states.visible = false
            card.states.hover.can = false
            card.T.y = G.TILE_H + 2
            card.T.r = 0
            if G.canlaugh_barter_saved_hand then
                G.canlaugh_barter_saved_hand:emplace(card)
            end
        end
        return unpack(results)
    end
end

local function create_barter_hand()
    local hand_limit = (G.hand and G.hand.config and G.hand.config.card_limit) or 8
    local highlight_limit = (G.hand and G.hand.config and G.hand.config.highlighted_limit) or 5

    BT.hand_area = CardArea(
        G.hand.T.x,
        G.hand.T.y,
        G.hand.T.w,
        G.hand.T.h,
        {
            card_limit = hand_limit,
            type = "hand",
            highlight_limit = math.max(5, highlight_limit),
            no_card_count = true,
        }
    )
    BT.hand_area.canlaugh_barter_hand = true
    G.canlaugh_barter_hand = BT.hand_area
    BT.draw_reps(hand_limit)
end

local function sample_trials(count, booster_kind)
    local pool = BT.trial_pool_for(booster_kind)
    local picked = {}

    for _ = 1, math.min(count, #pool) do
        local idx = math.floor(pseudorandom("canlaugh_barter_trial") * #pool) + 1
        picked[#picked + 1] = pool[idx]
        table.remove(pool, idx)
    end
    return picked
end

local function replace_pack_with_trials()
    BT.reward_cards = {}
    BT.pack_card_slots = {}
    ensure_barter_storage_areas()

    for i = 1, #G.pack_cards.cards do
        local card = G.pack_cards.cards[i]
        BT.reward_cards[i] = card
        BT.pack_card_slots[i] = card and card.VT and {
            x = card.VT.x,
            y = card.VT.y,
            r = card.VT.r,
            scale = card.VT.scale,
        } or nil
    end
    for i = #BT.reward_cards, 1, -1 do
        local card = BT.reward_cards[i]
        G.pack_cards:remove_card(card)
        if card then
            card.states.hover.can = false
            card.T.y = G.TILE_H + 2
            card.T.r = 0
            if G.canlaugh_barter_saved_rewards then
                G.canlaugh_barter_saved_rewards:emplace(card)
            end
        end
    end

    local trial_count = ((BT.required or 1) > 1 and 4 or 3) + #(SMODS.find_card("j_canlaugh_harlequin") or {})
    local trial_slots = BT.pack_card_slots
    if trial_count == 3 and #BT.pack_card_slots == 3 then
        trial_slots = {}
        local pack_mid_x = G.pack_cards.T.x + G.pack_cards.T.w / 2
        for i, slot in ipairs(BT.pack_card_slots) do
            if slot and slot.x then
                trial_slots[i] = {
                    x = pack_mid_x + (slot.x - pack_mid_x) * 1.18,
                    y = slot.y,
                    r = slot.r,
                    scale = slot.scale,
                }
            end
        end
    end
    G.pack_cards.config.card_limit = math.max(G.pack_cards.config.card_limit or 0, trial_count)
    G.pack_cards.config.highlight_limit = 1

    for i, trial in ipairs(sample_trials(trial_count, BT.active_booster_kind)) do
        local center = trial.center
            or (trial.center_key and G.P_CENTERS and G.P_CENTERS[trial.center_key])
            or (trial.center_key and SMODS and SMODS.Centers and SMODS.Centers[trial.center_key])
        local card = center and Card(
            G.pack_cards.T.x + G.pack_cards.T.w / 2,
            G.pack_cards.T.y,
            G.CARD_W,
            G.CARD_H,
            G.P_CARDS.empty,
            center,
            {
                bypass_discovery_center = true,
                bypass_discovery_ui = true,
            }
        )

        if card then
            card.canlaugh_trial_card = true
            card.canlaugh_trial_def = trial
            if card.ability then
                card.ability.consumeable = false
                card.ability.set = "Trial"
            end
            G.pack_cards:emplace(card)
            local slot = trial_slots[i]
            if slot then
                card.VT.x = slot.x
                card.VT.y = slot.y
                card.VT.r = slot.r or card.VT.r
                card.VT.scale = slot.scale or card.VT.scale
            end
            card:start_materialize({ G.C.WHITE, G.C.WHITE }, nil, 1.0 * G.SETTINGS.GAMESPEED)
        end
    end
end

function BT.start()
    if not BT.can_start() then
        return
    end

    BT.starting = true
    BT.ransacked_counted = nil
    BT.bonus_rep_queue = {}
    BT.bonus_reps_dealt = nil
    local booster_card = opened_booster_card()
    local booster_center = booster_card and booster_card.config and booster_card.config.center

    local shop_id = tostring(G.GAME.round or 0) .. ":" .. tostring(G.GAME.round_resets and G.GAME.round_resets.ante or 0)
    if not G.GAME.canlaugh_shop_barter_achievement
        or G.GAME.canlaugh_shop_barter_achievement.id ~= shop_id then
        G.GAME.canlaugh_shop_barter_achievement = {
            id = shop_id,
            target = #((G.shop_booster and G.shop_booster.cards) or {}) + 1,
            completed = 0,
        }
    end

    BT.active = true
    BT.finish_pending = nil
    BT.active_booster_kind = BT.booster_kind(booster_center)
    BT.required = BT.required_trials(booster_card)
    BT.successes = 0
    BT.failures = 0
    BT.skip_label = "Forfeit"
    BT.saved_hands_left = G.GAME.current_round.hands_left
    BT.saved_discards_left = G.GAME.current_round.discards_left
    BT.vanilla_pack_choices = G.GAME.pack_choices
    BT.saved_pack_config = {
        card_limit = G.pack_cards.config.card_limit,
        highlight_limit = G.pack_cards.config.highlight_limit,
    }
    BT.jumbo_fallback = is_jumbo_booster(booster_card)
    BT.opened_booster_card = booster_card
    BT.joker_effect_state = {}
    BT.rep_pool = representative_pool(BT.active_booster_kind)
    apply_rep_modifiers("pool", { booster_kind = BT.active_booster_kind, pool = BT.rep_pool })

    G.GAME.pack_choices = BT.required

    move_run_areas_offscreen()
    tuck_real_hand()
    create_barter_hand()
    apply_rep_modifiers("hand", { booster_kind = BT.active_booster_kind })
    replace_pack_with_trials()
    schedule_late_hand_tucks()
    remove_barter_buttons()
    BT.starting = nil
end

local function selected_reps()
    if BT.hand_area and BT.hand_area.highlighted then
        return BT.hand_area.highlighted
    end
    return {}
end

local function smeared_suits_match(first_suit, second_suit)
    if first_suit == second_suit then
        return true
    end
    if not (SMODS and next(SMODS.find_card("j_smeared") or {})) then
        return false
    end

    return ({
        Hearts = "Diamonds",
        Diamonds = "Hearts",
        Spades = "Clubs",
        Clubs = "Spades",
    })[first_suit] == second_suit
end

function BT.count_selected_for(trial)
    local count = 0
    local distinct_hands = {}
    local distinct_rarities = {}
    local spectral_card_counts = {}
    local spectral_editions = {}
    local spectral_cards = 0
    local spectral_reflective = 0
    local spectral_has_ace = false
    local spectral_has_negative = false
    local spectral_has_high_edition = false
    local spectral_lesser_editions = 0
    local wild_cards = 0

    for _, card in ipairs(selected_reps()) do
        local rep = card.canlaugh_barter_rep
        if rep then
            if (rep.kind == "trial_wild" and rep.trial_booster_kind == BT.active_booster_kind)
                or rep.any_trial
            then
                count = count + 1
            elseif trial.kind == "suit" and rep.kind == "suit" and smeared_suits_match(rep.suit, trial.suit) then
                count = count + 1
            elseif trial.kind == "face" and rep.kind == "face" then
                count = count + 1
            elseif trial.kind == "no_suit" and rep.kind == "no_suit" then
                count = count + 1
            elseif trial.kind == "multi_suit" and rep.kind == "multi_suit" then
                count = count + 1
            elseif trial.kind == "hand_requirement" then
                if rep.kind == "hand_wild" then
                    count = count + 1
                elseif rep.kind == "planet" and rep.requirements and rep.requirements[trial.requirement] then
                    count = count + 1
                end
            elseif trial.kind == "body" then
                if rep.kind == "hand_wild" or (rep.kind == "planet" and rep.body == trial.body) then
                    count = count + 1
                end
            elseif trial.kind == "secret_hand" then
                if rep.kind == "hand_wild" or (rep.kind == "planet" and rep.secret) then
                    count = count + 1
                end
            elseif trial.kind == "different_hands" then
                if rep.kind == "hand_wild" then
                    wild_cards = wild_cards + 1
                elseif rep.kind == "planet" and rep.hand_key then
                    distinct_hands[rep.hand_key] = true
                end
            elseif trial.kind == "joker_rarity" and rep.kind == "joker" and rep.rarity == trial.rarity then
                count = count + 1
            elseif trial.kind == "joker_output" and rep.kind == "joker" and rep.output == trial.output then
                count = count + 1
            elseif trial.kind == "joker_different_rarities" and rep.kind == "joker" and rep.rarity then
                distinct_rarities[rep.rarity] = true
            elseif trial.kind == "joker_rarity_or" and rep.kind == "joker" then
                if rep.rarity == trial.rarity_a then
                    count = count + 1
                elseif rep.rarity == trial.rarity_b then
                    distinct_rarities[rep.rarity] = (distinct_rarities[rep.rarity] or 0) + 1
                end
            elseif rep.kind == "aces" or rep.kind == "faces" or rep.kind == "numbers" or rep.kind == "edition" then
                if not spectral_card_counts[rep.key] then
                    spectral_cards = spectral_cards + 1
                end
                spectral_card_counts[rep.key] = (spectral_card_counts[rep.key] or 0) + 1
                spectral_has_ace = spectral_has_ace or rep.kind == "aces"
                local represented_edition = rep.edition or "base"
                spectral_editions[represented_edition] = true
                if rep.edition then
                    spectral_has_negative = spectral_has_negative or rep.edition == "negative"
                    spectral_has_high_edition = spectral_has_high_edition
                        or rep.edition == "polychrome" or rep.edition == "negative"
                    if rep.edition == "foil" or rep.edition == "holo" then
                        spectral_reflective = spectral_reflective + 1
                        spectral_lesser_editions = spectral_lesser_editions + 1
                    end
                end
            end
        end
    end

    if trial.kind == "different_hands" then
        for _ in pairs(distinct_hands) do
            count = count + 1
        end
        count = math.min(trial.need, count + wild_cards)
    elseif trial.kind == "joker_different_rarities" then
        for _ in pairs(distinct_rarities) do
            count = count + 1
        end
    elseif trial.kind == "joker_rarity_or" then
        if count >= (trial.need_a or 1) or (distinct_rarities[trial.rarity_b] or 0) >= (trial.need_b or 1) then
            return trial.need
        end
    elseif trial.kind == "spectral_same_card" then
        for _, same_count in pairs(spectral_card_counts) do
            count = math.max(count, same_count)
        end
    elseif trial.kind == "spectral_same_edition" then
        local edition_counts = {}
        for _, card in ipairs(selected_reps()) do
            local rep = card.canlaugh_barter_rep
            if rep then
                local represented_edition = rep.edition or "base"
                edition_counts[represented_edition] = (edition_counts[represented_edition] or 0) + 1
            end
        end
        for _, same_count in pairs(edition_counts) do
            count = math.max(count, same_count)
        end
    elseif trial.kind == "spectral_unique_cards" then
        count = spectral_cards
    elseif trial.kind == "spectral_unique_editions" then
        for _ in pairs(spectral_editions) do count = count + 1 end
    elseif trial.kind == "spectral_reflective" then
        count = spectral_reflective
    elseif trial.kind == "spectral_possession" then
        count = spectral_has_ace and spectral_has_negative and trial.need or 0
    elseif trial.kind == "spectral_transmutation" then
        count = spectral_has_high_edition and spectral_lesser_editions >= 2 and trial.need or 0
    end

    return count
end

local function set_pack_choice_after_trial()
    local needed = math.max(0, (BT.required or 1) - (BT.successes or 0))
    G.GAME.pack_choices = needed
end

function BT.destroy_selected_reps()
    local chosen = {}
    for i, card in ipairs(selected_reps()) do
        chosen[i] = card
    end

    if BT.hand_area then
        BT.hand_area:unhighlight_all()
    end

    for i = #chosen, 1, -1 do
        local card = chosen[i]
        if card and card.area == BT.hand_area then
            BT.hand_area:remove_card(card)
            card:start_dissolve(nil, i == #chosen)
        end
    end

    BT.draw_reps(#chosen)
end

function BT.fail_threshold()
    return math.floor((BT.required or 1) / 2) + 1
end

local function remaining_trial_cards()
    for _, pack_card in ipairs(G.pack_cards and G.pack_cards.cards or {}) do
        if pack_card and pack_card.canlaugh_trial_card and not pack_card.canlaugh_trial_resolved then
            return true
        end
    end
    return false
end

local function exit_failed_barter()
    BT.prepare_finish("fail")
    if G.FUNCS and G.FUNCS.skip_booster then
        G.FUNCS.skip_booster()
    end
end

function BT.resolve_trial(card)
    if not BT.active then
        return
    end

    local center = card and card.config and card.config.center
    local trial = card and card.canlaugh_trial_def
        or (center and BT.trial_by_center_key[center.key])
        or (center and center.original_key and BT.trial_by_key[center.original_key])
        or (center and center.key and BT.trial_by_key[center.key])
    if not trial then
        return
    end

    card.canlaugh_trial_resolved = true
    if card.config and card.config.center then
        discover_card(card.config.center)
    end
    ease_hands_played(-1, true)

    local chosen_reps = {}
    for _, selected in ipairs(selected_reps()) do
        if selected.canlaugh_barter_rep then chosen_reps[#chosen_reps + 1] = selected.canlaugh_barter_rep end
    end
    local passed = BT.count_selected_for(trial) >= trial.need
    apply_rep_modifiers("resolved", {
        booster_kind = BT.active_booster_kind,
        trial = trial,
        passed = passed,
        selected_reps = chosen_reps,
    })
    if passed then
        BT.successes = (BT.successes or 0) + 1
        for _, pack_rat in ipairs(SMODS.find_card("j_canlaugh_pack_rat") or {}) do
            local extra = pack_rat.ability.extra
            extra.trials = (extra.trials or 0) + 1
            local new_slots = 1 + math.floor(extra.trials / 2)
            if new_slots > (extra.slots or 1) then
                local gain = new_slots - (extra.slots or 1)
                extra.slots = new_slots
                G.consumeables.config.card_limit = G.consumeables.config.card_limit + gain
                card_eval_status_text(pack_rat, "extra", nil, nil, nil, { message = "+" .. gain .. " Slot", colour = G.C.FILTER })
            end
        end
        card_eval_status_text(card, "extra", nil, nil, nil, { message = "Passed!", colour = G.C.GREEN })
        BT.destroy_selected_reps()
    else
        BT.failures = (BT.failures or 0) + 1
        card_eval_status_text(card, "extra", nil, nil, nil, { message = "Failed...", colour = G.C.RED })
        BT.destroy_selected_reps()
    end


    deal_bonus_reps_after_first_trial()

    if G.pack_cards and card.area == G.pack_cards then
        G.pack_cards:remove_card(card)
        card:start_dissolve(nil, true)
    end

    if (BT.successes or 0) >= (BT.required or 1) then
        BT.enter_reward_phase()
    elseif not remaining_trial_cards() then
        if BT.jumbo_fallback and (BT.successes or 0) >= math.ceil((BT.required or 1) / 2) then
            BT.return_to_normal_pack()
        else
            exit_failed_barter()
        end
    elseif (BT.failures or 0) >= BT.fail_threshold() or (G.GAME.current_round.hands_left or 0) <= 0 then
        if BT.jumbo_fallback and (BT.successes or 0) >= math.ceil((BT.required or 1) / 2) then
            BT.return_to_normal_pack()
        else
            BT.finish_pending = "fail"
            G.GAME.pack_choices = 1
        end
    else
        set_pack_choice_after_trial()
    end
end

local function reward_card_area(card)
    if not card then
        return nil
    end

    if card.ability and card.ability.consumeable then
        return G.consumeables
    end
    if card.ability and card.ability.set == "Joker" then
        return G.jokers
    end
    if card.ability and (card.ability.set == "Default" or card.ability.set == "Enhanced") then
        return G.deck
    end
end

local function reward_card_area_key(card)
    local area = reward_card_area(card)
    if area == G.consumeables then
        return "consumeables"
    end
    if area == G.jokers then
        return "jokers"
    end
    if area == G.deck then
        return "deck"
    end
end

local function grant_rewards()
    for _, card in ipairs(BT.reward_cards or {}) do
        if card and (not card.area or card.area == G.canlaugh_barter_saved_rewards) then
            if card.area then card.area:remove_card(card) end
            local area = reward_card_area(card)
            local has_room = area and area.config and area.cards and #area.cards < area.config.card_limit

            if area == G.deck then
                has_room = true
            end

            if has_room then
                card:add_to_deck()
                card.states.visible = true
                card.states.hover.can = true
            end

            if has_room and card.ability.consumeable and G.consumeables then
                G.consumeables:emplace(card)
            elseif has_room and card.ability.set == "Joker" and G.jokers then
                G.jokers:emplace(card)
            elseif has_room and (card.ability.set == "Default" or card.ability.set == "Enhanced") and G.deck then
                G.playing_card = (G.playing_card and G.playing_card + 1) or 1
                card.playing_card = G.playing_card
                G.deck:emplace(card)
                table.insert(G.playing_cards, card)
            end
        end
    end
end

local function sell_unclaimed_rewards(on_complete)
    local function cash_out_value(value)
        if next(SMODS.find_card("j_canlaugh_goldbeard") or {}) then
            return math.floor(value * 1.5)
        end
        return value
    end

    local unclaimed = {}
    for _, card in ipairs(BT.reward_cards or {}) do
        if card and not card.canlaugh_barter_claimed and card.area == G.pack_cards then
            unclaimed[#unclaimed + 1] = card
        end
    end

    if not (G.E_MANAGER and Event) then
        for _, card in ipairs(unclaimed) do
            local center_cost = card.config and card.config.center and card.config.center.cost
            ease_dollars(cash_out_value(center_cost or card.cost or card.sell_cost or 0))
            if card.area then card.area:remove_card(card) end
            card:remove()
        end
        if on_complete then on_complete() end
        return
    end

    for _, card in ipairs(unclaimed) do
        local reward_card = card
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.25,
            func = function()
                play_sound("coin2")
                reward_card:juice_up(0.3, 0.4)
                card_eval_status_text(reward_card, "extra", nil, nil, nil, {
                    message = "Sold!",
                    colour = G.C.MONEY,
                    instant = true,
                    no_juice = true,
                })
                return true
            end,
        }))
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.2,
            func = function()
                local center_cost = reward_card.config and reward_card.config.center and reward_card.config.center.cost
                local value = center_cost or reward_card.cost or reward_card.sell_cost or 0
                if reward_card.ability and reward_card.ability.consumeable
                    and next(SMODS.find_card("j_canlaugh_jesters_privilege") or {})
                then
                    value = math.floor(value * 0.5)
                end
                ease_dollars(cash_out_value(value))
                if reward_card.area then reward_card.area:remove_card(reward_card) end
                reward_card:start_dissolve({ G.C.GOLD })
                return true
            end,
        }))
    end

    G.E_MANAGER:add_event(Event({
        trigger = "after",
        delay = #unclaimed > 0 and 0.35 or 0,
        func = function()
            if on_complete then on_complete() end
            return true
        end,
    }))
end

local function clear_trial_state(keep_rewards)
    BT.active = false
    BT.starting = nil
    BT.skip_label = "Skip"
    BT.finish_pending = nil
    BT.required = nil
    BT.successes = nil
    BT.failures = nil
    if not keep_rewards then
        BT.reward_cards = nil
    end
    BT.rep_pool = nil
    BT.bonus_rep_queue = nil
    BT.bonus_reps_dealt = nil
    BT.joker_effect_state = nil
    BT.rep_drag_select = nil
    BT.rep_drag_active = nil
    BT.rep_mouse_down = nil
    BT.active_booster_kind = nil
    BT.pack_card_slots = nil
    BT.vanilla_pack_choices = nil
    BT.saved_pack_config = nil
    BT.jumbo_fallback = nil
    BT.opened_booster_card = nil
    BT.mega_success_dispatched = nil
    if not keep_rewards and G and G.GAME then
        G.GAME.canlaugh_barter_save = nil
    end
    remove_barter_storage_areas()
end

local function remove_rewards()
    for _, card in ipairs(BT.reward_cards or {}) do
        if card then
            if card.area then
                card.area:remove_card(card)
            end
            card:remove()
        end
    end
end

function BT.prepare_finish(mode)
    if not BT.active then
        return
    end

    mode = mode or BT.finish_pending or "fail"
    clear_barter_selections()

    if BT.hand_area then
        remove_all_from_area(BT.hand_area, false)
        if BT.hand_area.remove then
            BT.hand_area:remove()
        end
        BT.hand_area = nil
        G.canlaugh_barter_hand = nil
    end
    if remove_barter_buttons then
        remove_barter_buttons()
    end

    if G.pack_cards then
        remove_all_from_area(G.pack_cards, false)
    end

    restore_real_hand()
    restore_run_areas()

    G.GAME.current_round.hands_left = BT.saved_hands_left or G.GAME.current_round.hands_left
    G.GAME.current_round.discards_left = BT.saved_discards_left or G.GAME.current_round.discards_left
    refresh_round_counter_ui()

    if mode == "success" then
        grant_rewards()
    else
        remove_rewards()
    end

    clear_trial_state(false)
end

function BT.return_to_normal_pack()
    if not BT.active then
        return
    end

    clear_barter_selections()

    if BT.hand_area then
        remove_all_from_area(BT.hand_area, false)
        if BT.hand_area.remove then BT.hand_area:remove() end
        BT.hand_area = nil
        G.canlaugh_barter_hand = nil
    end
    if remove_barter_buttons then remove_barter_buttons() end
    if G.pack_cards then
        remove_all_from_area(G.pack_cards, false)
        if BT.saved_pack_config then
            G.pack_cards.config.card_limit = BT.saved_pack_config.card_limit or G.pack_cards.config.card_limit
            G.pack_cards.config.highlight_limit = BT.saved_pack_config.highlight_limit or G.pack_cards.config.highlight_limit
        end
    end

    restore_real_hand()
    restore_run_areas()
    G.GAME.current_round.hands_left = BT.saved_hands_left or G.GAME.current_round.hands_left
    G.GAME.current_round.discards_left = BT.saved_discards_left or G.GAME.current_round.discards_left
    refresh_round_counter_ui()

    for i, card in ipairs(BT.reward_cards or {}) do
        if card and (not card.area or card.area == G.canlaugh_barter_saved_rewards) and G.pack_cards then
            if card.area then card.area:remove_card(card) end
            card.canlaugh_barter_reward = nil
            card.states.visible = true
            card.states.hover.can = true
            G.pack_cards:emplace(card)
            local slot = BT.pack_card_slots and BT.pack_card_slots[i]
            if slot then
                card.VT.x = slot.x
                card.VT.y = slot.y
                card.VT.r = slot.r or card.VT.r
                card.VT.scale = slot.scale or card.VT.scale
            end
            card:start_materialize({ G.C.WHITE, G.C.WHITE }, nil, 0.7 * G.SETTINGS.GAMESPEED)
        end
    end

    G.GAME.pack_choices = BT.vanilla_pack_choices or 1
    if BT.opened_booster_card then
        BT.opened_booster_card.canlaugh_barter_locked = true
    end
    clear_trial_state(false)
    BT.skip_label = "Skip"
end

function BT.enter_reward_phase()
    if not BT.active then
        return
    end

    if not BT.ransacked_counted then
        BT.ransacked_counted = true
        local tracker = G and G.GAME and G.GAME.canlaugh_shop_barter_achievement
        if tracker then
            tracker.completed = (tracker.completed or 0) + 1
            if tracker.completed >= (tracker.target or 1) and type(check_for_unlock) == "function" then
                check_for_unlock({ type = "canlaugh_ransacked" })
            end
        end
    end

    if not BT.mega_success_dispatched and BT.is_mega_booster(BT.opened_booster_card) then
        BT.mega_success_dispatched = true
        BT.dispatch_mega_success(BT.active_booster_kind)
    end

    clear_barter_selections()

    if BT.hand_area then
        remove_all_from_area(BT.hand_area, false)
        if BT.hand_area.remove then
            BT.hand_area:remove()
        end
        BT.hand_area = nil
        G.canlaugh_barter_hand = nil
    end
    if remove_barter_buttons then
        remove_barter_buttons()
    end

    if G.pack_cards then
        remove_all_from_area(G.pack_cards, false)
        G.pack_cards.config.card_limit = math.max(G.pack_cards.config.card_limit or 0, #(BT.reward_cards or {}))
        G.pack_cards.config.highlight_limit = 1
    end

    restore_real_hand()
    restore_run_areas()

    G.GAME.current_round.hands_left = BT.saved_hands_left or G.GAME.current_round.hands_left
    G.GAME.current_round.discards_left = BT.saved_discards_left or G.GAME.current_round.discards_left
    refresh_round_counter_ui()

    local reward_count = 0
    for i, card in ipairs(BT.reward_cards or {}) do
        if card and (not card.area or card.area == G.canlaugh_barter_saved_rewards) and G.pack_cards then
            if card.area then card.area:remove_card(card) end
            reward_count = reward_count + 1
            card.canlaugh_barter_reward = true
            card.canlaugh_barter_claimed = nil
            card.states.visible = true
            card.states.hover.can = true
            if card.ability then
                card.ability.card_limit = card.ability.card_limit or 0
                card.ability.extra_slots_used = card.ability.extra_slots_used or 0
            end
            G.pack_cards:emplace(card)
            local slot = BT.pack_card_slots and BT.pack_card_slots[i]
            if slot then
                card.VT.x = slot.x
                card.VT.y = slot.y
                card.VT.r = slot.r or card.VT.r
                card.VT.scale = slot.scale or card.VT.scale
            end
            card:start_materialize({ G.C.WHITE, G.C.WHITE }, nil, 1.0 * G.SETTINGS.GAMESPEED)
        end
    end

    G.GAME.pack_choices = reward_count
    BT.reward_phase = true
    clear_trial_state(true)
    BT.skip_label = "Cash Out"
    remove_barter_storage_areas()
end

function BT.finish_reward_phase(on_complete)
    if not BT.reward_phase or BT.cashing_out then
        return
    end

    BT.cashing_out = true
    sell_unclaimed_rewards(function()
        clear_barter_selections()
        for _, card in ipairs(BT.reward_cards or {}) do
            if card then
                card.canlaugh_barter_reward = nil
                card.canlaugh_barter_claimed = nil
            end
        end
        BT.reward_cards = nil
        BT.reward_phase = nil
        BT.cashing_out = nil
        BT.skip_label = "Skip"
        if G and G.GAME then G.GAME.canlaugh_barter_save = nil end
        remove_barter_storage_areas()
        if on_complete then on_complete() end
    end)
end

local function barter_save_snapshot()
    if not (G and G.GAME and (BT.active or BT.reward_phase)) then return nil end

    local hand_reps = {}
    for i, card in ipairs(BT.hand_area and BT.hand_area.cards or {}) do
        hand_reps[i] = card.canlaugh_barter_rep
    end

    return {
        version = 1,
        phase = BT.reward_phase and "reward" or "trial",
        active_booster_kind = BT.active_booster_kind,
        required = BT.required,
        successes = BT.successes,
        failures = BT.failures,
        finish_pending = BT.finish_pending,
        rep_pool = BT.rep_pool,
        bonus_rep_queue = BT.bonus_rep_queue,
        bonus_reps_dealt = BT.bonus_reps_dealt,
        hand_reps = hand_reps,
        joker_effect_state = BT.joker_effect_state,
        pack_card_slots = BT.pack_card_slots,
        vanilla_pack_choices = BT.vanilla_pack_choices,
        saved_pack_config = BT.saved_pack_config,
        saved_area_positions = BT.saved_area_positions,
        jumbo_fallback = BT.jumbo_fallback,
        saved_hands_left = BT.saved_hands_left,
        saved_discards_left = BT.saved_discards_left,
        mega_success_dispatched = BT.mega_success_dispatched,
    }
end

local function load_deferred_barter_area(key, fallback_area, area_type)
    local saved = G and G["load_" .. key]
    if not saved then return G and G[key] end

    local source = fallback_area or G.hand
    local area = CardArea(
        source.T.x, source.T.y, source.T.w, source.T.h,
        { card_limit = 1000, type = area_type or "hand", highlight_limit = 5, no_card_count = true }
    )
    G[key] = area
    G["load_" .. key] = nil
    area:load(saved)
    return area
end

function BT.restore_saved_barter()
    local saved = G and G.GAME and G.GAME.canlaugh_barter_save
    if not saved then return true end
    if not G.pack_cards or not G.hand then return false end

    local saved_hand_area = load_deferred_barter_area("canlaugh_barter_saved_hand", G.hand, "hand")
    local saved_reward_area = load_deferred_barter_area("canlaugh_barter_saved_rewards", G.hand, "consumeable")
    BT.saved_hand_cards = saved_hand_area and saved_hand_area.cards or {}
    for _, card in ipairs(BT.saved_hand_cards) do
        if card and card.states then
            card.states.visible = false
            card.states.hover.can = false
        end
    end
    BT.saved_hands_left = saved.saved_hands_left
    BT.saved_discards_left = saved.saved_discards_left
    BT.pack_card_slots = saved.pack_card_slots
    BT.saved_pack_config = saved.saved_pack_config
    BT.saved_area_positions = saved.saved_area_positions
    BT.vanilla_pack_choices = saved.vanilla_pack_choices
    BT.jumbo_fallback = saved.jumbo_fallback
    BT.mega_success_dispatched = saved.mega_success_dispatched
    BT.opened_booster_card = opened_booster_card()

    if saved.phase == "reward" then
        if G.hand.states then G.hand.states.visible = true end
        BT.active = false
        BT.reward_phase = true
        BT.reward_cards = {}
        for _, card in ipairs(G.pack_cards.cards or {}) do
            card.canlaugh_barter_reward = true
            BT.reward_cards[#BT.reward_cards + 1] = card
        end
        BT.skip_label = "Cash Out"
        remove_barter_storage_areas()
        return true
    end

    BT.active = true
    if G.hand.states then G.hand.states.visible = false end
    BT.reward_phase = nil
    BT.active_booster_kind = saved.active_booster_kind
    BT.required = saved.required
    BT.successes = saved.successes
    BT.failures = saved.failures
    BT.finish_pending = saved.finish_pending
    BT.rep_pool = saved.rep_pool or {}
    BT.bonus_rep_queue = saved.bonus_rep_queue or {}
    BT.bonus_reps_dealt = saved.bonus_reps_dealt
    BT.joker_effect_state = saved.joker_effect_state or {}
    BT.reward_cards = saved_reward_area and saved_reward_area.cards or {}
    BT.hand_area = load_deferred_barter_area("canlaugh_barter_hand", G.hand, "hand")
    G.canlaugh_barter_hand = BT.hand_area
    if BT.hand_area then
        BT.hand_area.canlaugh_barter_hand = true
        for i, card in ipairs(BT.hand_area.cards or {}) do
            card.canlaugh_barter_rep = saved.hand_reps and saved.hand_reps[i]
            card.canlaugh_no_consumeable_use_button = true
            card.states.drag.can = false
        end
    end
    for _, card in ipairs(G.pack_cards.cards or {}) do
        local center = card.config and card.config.center
        local trial = center and (BT.trial_by_center_key[center.key]
            or BT.trial_by_key[center.original_key or center.key])
        if trial then
            card.canlaugh_trial_card = true
            card.canlaugh_trial_def = trial
        end
    end
    if not BT.saved_area_positions then move_run_areas_offscreen() end
    schedule_late_hand_tucks()
    BT.skip_label = "Skip"
    return true
end

if type(save_run) == "function" and not BT.save_run_wrapped then
    BT.save_run_wrapped = true
    local save_run_ref = save_run
    save_run = function(...)
        if G and G.F_NO_SAVING then
            return save_run_ref(...)
        end

        if not (BT.active or BT.reward_phase) then return save_run_ref(...) end

        G.GAME.canlaugh_barter_save = barter_save_snapshot()
        local pack_state = G.STATE
        G.STATE = G.STATES.BLIND_SELECT
        local results = { pcall(save_run_ref, ...) }
        G.STATE = pack_state
        if G.culled_table then G.culled_table.STATE = pack_state end
        if G.ARGS and G.ARGS.save_run then G.ARGS.save_run.STATE = pack_state end
        if not results[1] then
            error(results[2])
        end
        return unpack(results, 2)
    end
end

if Game and type(Game.start_run) == "function" and not BT.start_run_wrapped then
    BT.start_run_wrapped = true
    local start_run_ref = Game.start_run
    function Game:start_run(args)
        BT.active = false
        BT.reward_phase = nil
        BT.starting = nil
        BT.cashing_out = nil
        BT.hand_area = nil
        BT.reward_cards = nil
        G.canlaugh_barter_hand = nil

        local results = { start_run_ref(self, args) }
        if G and G.GAME and G.GAME.canlaugh_barter_save then
            if G.E_MANAGER and Event then
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = 0.1,
                    blocking = false,
                    blockable = false,
                    func = function()
                        return BT.restore_saved_barter()
                    end,
                }))
            else
                BT.restore_saved_barter()
            end
        end
        return unpack(results)
    end
end

remove_barter_buttons = function()
    if G.canlaugh_barter_buttons then
        G.canlaugh_barter_buttons:remove()
        G.canlaugh_barter_buttons = nil
    end
end

local function node_has_button(node, button)
    if type(node) ~= "table" then return false end
    if node.config and node.config.button == button then return true end
    for _, child in ipairs(node.nodes or {}) do
        if node_has_button(child, button) then return true end
    end
    return false
end

local function find_button_column_parent(node, button)
    if type(node) ~= "table" then return nil end
    for _, child in ipairs(node.nodes or {}) do
        local parent, index = find_button_column_parent(child, button)
        if parent then return parent, index end
    end
    for i, child in ipairs(node.nodes or {}) do
        if child.n == G.UIT.C and node_has_button(child, button) then
            return node, i
        end
    end
end

local function find_button_node(node, button)
    if type(node) ~= "table" then return nil end
    if node.config and node.config.button == button then return node end
    for _, child in ipairs(node.nodes or {}) do
        local found = find_button_node(child, button)
        if found then return found end
    end
end

local function first_text_node(node)
    if type(node) ~= "table" then return nil end
    if node.n == G.UIT.T and node.config then return node end
    for _, child in ipairs(node.nodes or {}) do
        local found = first_text_node(child)
        if found then return found end
    end
end

local function build_barter_column(skip_column)
    local column_config = (skip_column and skip_column.config) or {}
    local skip_button = find_button_node(skip_column, "skip_booster") or {}
    local button_config = skip_button.config or {}
    local skip_text = first_text_node(skip_button) or {}
    local text_config = skip_text.config or {}
    local spacer = skip_column and skip_column.nodes and skip_column.nodes[1]
    local spacer_config = (spacer and spacer.config) or {}

    return {
        n = G.UIT.C,
        config = {
            align = column_config.align or "tm",
            padding = column_config.padding or 0.05,
            minw = column_config.minw or 2.4,
        },
        nodes = {
            { n = G.UIT.R, config = { minh = spacer_config.minh or 0.2 }, nodes = {} },
            {
                n = G.UIT.R,
                config = {
                    align = button_config.align or "tm",
                    padding = button_config.padding or 0.2,
                    minh = button_config.minh or 1.2,
                    minw = button_config.minw or 1.8,
                    r = button_config.r or 0.15,
                    colour = G.C.UI.BACKGROUND_INACTIVE,
                    one_press = true,
                    button = "canlaugh_start_barter",
                    hover = true,
                    shadow = button_config.shadow ~= false,
                    func = "canlaugh_can_barter",
                },
                nodes = {
                    {
                        n = G.UIT.T,
                        config = {
                            text = "Barter",
                            scale = text_config.scale or 0.5,
                            colour = text_config.colour or G.C.WHITE,
                            shadow = text_config.shadow ~= false,
                        },
                    },
                },
            },
        },
    }
end

local function bind_skip_label(node)
    if type(node) ~= "table" then
        return
    end

    if node.config and node.config.button == "skip_booster" then
        local function bind_text(child)
            if type(child) ~= "table" then
                return false
            end
            if child.n == G.UIT.T and child.config and child.config.text then
                child.config.ref_table = BT
                child.config.ref_value = "skip_label"
                child.config.text = BT.skip_label
                return true
            end
            for _, grandchild in ipairs(child.nodes or {}) do
                if bind_text(grandchild) then
                    return true
                end
            end
            return false
        end

        bind_text(node)
    end

    for _, child in ipairs(node.nodes or {}) do
        bind_skip_label(child)
    end
end

function BT.decorate_uibox(t, booster_center)
    if not (t and BT.booster_kind(booster_center)) then
        return t
    end
    if t.canlaugh_barter_decorated then
        return t
    end
    t.canlaugh_barter_decorated = true
    bind_skip_label(t)

    local controls_row, skip_index = find_button_column_parent(t, "skip_booster")
    if controls_row and skip_index then
        local barter_column = build_barter_column(controls_row.nodes[skip_index])
        table.insert(controls_row.nodes, skip_index, barter_column)
    end

    return t
end

function G.FUNCS.canlaugh_can_barter(e)
    if BT.can_start() then
        e.config.colour = G.C.CANNED_LAUGHTER or G.C.PURPLE
        e.config.button = "canlaugh_start_barter"
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    end
end

function G.FUNCS.canlaugh_can_attempt_trial(e)
    local card = e and e.config and e.config.ref_table
    if BT.active
        and card
        and card.canlaugh_trial_card
        and not card.canlaugh_trial_resolved
        and BT.hand_area
        and BT.hand_area.highlighted
        and #BT.hand_area.highlighted > 0
        and (G.GAME.current_round.hands_left or 0) > 0
    then
        e.config.colour = G.C.CANNED_LAUGHTER or G.C.PURPLE
        e.config.button = "canlaugh_attempt_trial"
    else
        e.config.colour = G.C.UI.BACKGROUND_INACTIVE
        e.config.button = nil
    end
end

function G.FUNCS.canlaugh_attempt_trial(e)
    local card = e and e.config and e.config.ref_table
    if card and card.canlaugh_trial_card and not card.canlaugh_trial_resolved then
        BT.resolve_trial(card)
    end
end

function G.FUNCS.canlaugh_start_barter(e)
    BT.start()
end

if not BT.skip_booster_wrapped then
    BT.skip_booster_wrapped = true
    local skip_booster_ref = G.FUNCS.skip_booster

    G.FUNCS.skip_booster = function(e, ...)
        local args = { ... }
        if BT.active then
            BT.prepare_finish(BT.finish_pending or "fail")
        elseif BT.reward_phase then
            BT.finish_reward_phase(function()
                skip_booster_ref(e, unpack(args))
            end)
            return
        end
        return skip_booster_ref(e, unpack(args))
    end
end

local function wrap_booster_ui(owner)
    if not (owner and type(owner.create_UIBox) == "function") or rawget(owner, "canlaugh_barter_ui_wrapped") then
        return
    end

    owner.canlaugh_barter_ui_wrapped = true
    local create_UIBox_ref = owner.create_UIBox

    owner.create_UIBox = function(self, ...)
        return BT.decorate_uibox(create_UIBox_ref(self, ...), self)
    end
end

wrap_booster_ui(SMODS.Booster)

if G and G.P_CENTER_POOLS and G.P_CENTER_POOLS.Booster then
    for _, center in ipairs(G.P_CENTER_POOLS.Booster) do
        if BT.booster_kind(center) then
            wrap_booster_ui(center)
        end
    end
end

if not BT.end_consumeable_wrapped then
    BT.end_consumeable_wrapped = true
    local end_consumeable_ref = G.FUNCS.end_consumeable

    G.FUNCS.end_consumeable = function(e, delayfac)
        if BT.active then
            BT.prepare_finish(BT.finish_pending or "fail")
        elseif BT.reward_phase then
            BT.finish_reward_phase(function()
                end_consumeable_ref(e, delayfac)
            end)
            return
        end
        return end_consumeable_ref(e, delayfac)
    end
end

if G and G.UIDEF and type(G.UIDEF.use_and_sell_buttons) == "function" and not BT.use_button_wrapped then
    BT.use_button_wrapped = true
    local use_and_sell_buttons_ref = G.UIDEF.use_and_sell_buttons

    function G.UIDEF.use_and_sell_buttons(card)
        if card
            and card.canlaugh_barter_reward
            and BT.reward_phase
            and card.area == G.pack_cards
        then
            return {
                n = G.UIT.ROOT,
                config = {
                    padding = 0,
                    colour = G.C.CLEAR,
                },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = {
                            ref_table = card,
                            r = 0.08,
                            padding = 0.1,
                            align = "bm",
                            minw = 0.5 * card.T.w - 0.15,
                            maxw = 0.9 * card.T.w - 0.15,
                            minh = 0.3 * card.T.h,
                            hover = true,
                            shadow = true,
                            colour = G.C.UI.BACKGROUND_INACTIVE,
                            one_press = true,
                            button = "use_card",
                            func = "can_select_from_booster",
                        },
                        nodes = {
                            {
                                n = G.UIT.T,
                                config = {
                                    text = localize("b_select"),
                                    colour = G.C.UI.TEXT_LIGHT,
                                    scale = 0.45,
                                    shadow = true,
                                },
                            },
                        },
                    },
                },
            }
        end

        if card and card.canlaugh_trial_card and BT.active then
            return {
                n = G.UIT.ROOT,
                config = { padding = 0, colour = G.C.CLEAR },
                nodes = {
                    {
                        n = G.UIT.R,
                        config = {
                            ref_table = card,
                            r = 0.08,
                            padding = 0.1,
                            align = "bm",
                            minw = 0.5 * card.T.w - 0.15,
                            minh = 0.8 * card.T.h,
                            maxw = 0.7 * card.T.w - 0.15,
                            hover = true,
                            shadow = true,
                            colour = G.C.UI.BACKGROUND_INACTIVE,
                            one_press = true,
                            button = "canlaugh_attempt_trial",
                            func = "canlaugh_can_attempt_trial",
                        },
                        nodes = {
                            { n = G.UIT.T, config = { text = "ATTEMPT", colour = G.C.UI.TEXT_LIGHT, scale = 0.45, shadow = true } },
                        },
                    },
                },
            }
        end
        if card and card.canlaugh_no_consumeable_use_button and BT.active then
            return { n = G.UIT.ROOT, config = { padding = 0, colour = G.C.CLEAR }, nodes = {} }
        end
        return use_and_sell_buttons_ref(card)
    end
end

if Card and type(Card.can_use_consumeable) == "function" and not BT.rep_can_use_wrapped then
    BT.rep_can_use_wrapped = true
    local can_use_consumeable_ref = Card.can_use_consumeable

    function Card:can_use_consumeable(...)
        if self and self.canlaugh_no_consumeable_use_button and BT.active then
            return false
        end
        return can_use_consumeable_ref(self, ...)
    end
end

if SMODS and type(SMODS.card_select_area) == "function" and not BT.reward_select_area_wrapped then
    BT.reward_select_area_wrapped = true
    local card_select_area_ref = SMODS.card_select_area

    function SMODS.card_select_area(card, pack)
        if card and card.canlaugh_barter_reward and BT.reward_phase and card.area == G.pack_cards then
            return reward_card_area_key(card)
        end

        return card_select_area_ref(card, pack)
    end
end

if Card and type(Card.selectable_from_pack) == "function" and not BT.reward_select_wrapped then
    BT.reward_select_wrapped = true
    local selectable_from_pack_ref = Card.selectable_from_pack

    function Card:selectable_from_pack(pack, ...)
        if self and self.canlaugh_barter_reward and BT.reward_phase and self.area == G.pack_cards then
            local area = reward_card_area(self)
            local has_room = area and area.config and area.cards and #area.cards < area.config.card_limit
            if area == G.deck then has_room = true end
            return has_room and reward_card_area_key(self) or nil, false
        end
        return selectable_from_pack_ref(self, pack, ...)
    end
end

if G and G.FUNCS and type(G.FUNCS.use_card) == "function" and not BT.reward_use_wrapped then
    BT.reward_use_wrapped = true
    local use_card_ref = G.FUNCS.use_card

    G.FUNCS.use_card = function(e, ...)
        local card = e and e.config and e.config.ref_table
        local reward_card = card
            and card.canlaugh_barter_reward
            and BT.reward_phase
            and card.area == G.pack_cards
        local results = { use_card_ref(e, ...) }
        if reward_card and card.area ~= G.pack_cards then
            card.canlaugh_barter_claimed = true
            card.canlaugh_barter_reward = nil
        end
        return unpack(results)
    end
end

if Card and type(Card.generate_UIBox_ability_table) == "function" and not BT.rep_loc_wrapped then
    BT.rep_loc_wrapped = true
    local generate_UIBox_ability_table_ref = Card.generate_UIBox_ability_table

    function Card:generate_UIBox_ability_table(vars_only)
        if self and self.canlaugh_barter_rep and not self.canlaugh_rep_tooltip_bypass and not vars_only then
            local center_key = self.config and self.config.center and self.config.center.key
            if self.canlaugh_barter_rep.kind == "collection" then
                return generate_UIBox_ability_table_ref(self, vars_only)
            end

            local main_center = BT.representative_loc_center(center_key, false, self.canlaugh_barter_rep)
            if main_center then
                return generate_card_ui(main_center, nil, nil, "Other", nil, nil, nil, nil, self)
            end
        end

        if self
            and self.ability
            and self.ability.set == "Trial"
            and self.config
            and self.config.center
            and not self.config.center.discovered
            and not self.bypass_discovery_ui
            and not vars_only
        then
            ensure_trial_undiscovered_loc()
            return generate_card_ui(self.config.center, nil, nil, "Undiscovered", nil, true, nil, nil, self)
        end

        return generate_UIBox_ability_table_ref(self, vars_only)
    end
end

BT.register_rep_modifier("vanilla_joker_trial_compat", function(phase, context)
    if phase == "availability" then
        if context.booster_kind == "Buffoon" then
            local jokers = G.jokers and G.jokers.cards or {}
            for index, joker in ipairs(jokers) do
                local key = joker.config and joker.config.center and joker.config.center.key
                if key == "j_blueprint" and jokers[index + 1] then
                    context.extra_reps = context.extra_reps + 1
                elseif key == "j_brainstorm" and jokers[1] then
                    context.extra_reps = context.extra_reps + 1
                elseif key == "j_invisible" and joker.ability.invis_rounds and joker.ability.extra
                    and joker.ability.invis_rounds >= joker.ability.extra and #jokers > 1
                then
                    context.extra_reps = context.extra_reps + 1
                end
            end
        elseif context.booster_kind == "Arcana" then
            context.extra_reps = context.extra_reps + #(SMODS.find_card("j_cartomancer") or {})
        end
        return
    end
    if phase == "hand" and context.booster_kind == "Buffoon" then
        local jokers = G.jokers and G.jokers.cards or {}
        for index, joker in ipairs(G.jokers and G.jokers.cards or {}) do
            local key = joker.config and joker.config.center and joker.config.center.key
            if key == "j_blueprint" then
                BT.add_rep(BT.buffoon_rep_for_joker(jokers[index + 1]), joker)
            elseif key == "j_brainstorm" then
                BT.add_rep(BT.buffoon_rep_for_joker(jokers[1]), joker)
            elseif key == "j_invisible" and joker.ability.invis_rounds and joker.ability.extra
                and joker.ability.invis_rounds >= joker.ability.extra and #jokers > 1
            then
                local choices = {}
                for _, candidate in ipairs(jokers) do if candidate ~= joker then choices[#choices + 1] = candidate end end
                local pick = math.floor(pseudorandom("canlaugh_invisible_trial") * #choices) + 1
                BT.add_rep(BT.buffoon_rep_for_joker(choices[pick]), joker)
            end
        end
    elseif phase == "hand" and context.booster_kind == "Arcana" then
        for _, joker in ipairs(SMODS.find_card("j_cartomancer") or {}) do
            local cards = BT.hand_area and BT.hand_area.cards or {}
            local source = cards[math.floor(pseudorandom("canlaugh_cartomancer_trial") * #cards) + 1]
            if source and source.canlaugh_barter_rep then BT.add_rep(copy_table(source.canlaugh_barter_rep), joker) end
        end
    elseif phase == "resolved" and context.passed and context.booster_kind == "Celestial" then
        local state = BT.joker_effect_state or {}
        BT.joker_effect_state = state
        local used_hands, wild = {}, false
        for _, rep in ipairs(context.selected_reps or {}) do
            if rep.kind == "hand_wild" then wild = true end
            if rep.hand_key then used_hands[rep.hand_key] = true end
        end

        if used_hands["Straight Flush"] and not state.seance then
            local seances = SMODS.find_card("j_seance") or {}
            if #seances > 0 and G.consumeables and #G.consumeables.cards < G.consumeables.config.card_limit then
                state.seance = true
                local spectral = create_card("Spectral", G.consumeables, nil, nil, nil, nil, nil, "canlaugh_seance_trial")
                spectral:add_to_deck(); G.consumeables:emplace(spectral)
                card_eval_status_text(seances[1], "extra", nil, nil, nil, { message = localize("k_plus_spectral"), colour = G.C.SECONDARY_SET.Spectral })
            end
        end

        if not wild then
            local most_played = -1
            for hand_key, hand in pairs(G.GAME.hands or {}) do
                if SMODS.is_poker_hand_visible(hand_key) then most_played = math.max(most_played, hand.played or 0) end
            end
            local used_most = false
            for hand_key in pairs(used_hands) do
                used_most = used_most or ((G.GAME.hands[hand_key] and G.GAME.hands[hand_key].played or 0) >= most_played)
            end
            if next(used_hands) and not used_most then
                local scoring_name = next(used_hands) or "High Card"
                for _, obelisk in ipairs(SMODS.find_card("j_obelisk") or {}) do
                    obelisk:calculate_joker({ before = true, scoring_name = scoring_name, scoring_hand = {}, full_hand = {}, poker_hands = {} })
                end
            end
        end
    end
end)

if Controller and type(Controller.queue_R_cursor_press) == "function" and not BT.right_click_wrapped then
    BT.right_click_wrapped = true
    local queue_R_cursor_press_ref = Controller.queue_R_cursor_press

    function Controller:queue_R_cursor_press(x, y, ...)
        if BT.active and BT.hand_area and BT.hand_area.highlighted and BT.hand_area.highlighted[1] then
            BT.hand_area:unhighlight_all()
            BT.rep_drag_select = nil
            BT.rep_drag_active = nil
            return
        end
        return queue_R_cursor_press_ref(self, x, y, ...)
    end
end

if Card and type(Card.update) == "function" and not BT.rep_drag_update_wrapped then
    BT.rep_drag_update_wrapped = true
    local card_update_ref = Card.update

    function Card:update(dt, ...)
        card_update_ref(self, dt, ...)

        if BT.active and BT.hand_area and self.area == BT.hand_area and self.states and self.states.drag then
            self.states.drag.can = false
        end

        if not (BT.active and BT.hand_area and love and love.mouse and love.mouse.isDown) then
            return
        end

        if not love.mouse.isDown(1) then
            BT.rep_drag_select = nil
            BT.rep_mouse_down = nil
            return
        end

        if not BT.rep_mouse_down then
            BT.rep_drag_active = nil
            BT.rep_mouse_down = true
        end

        if self.area == BT.hand_area
            and self.states
            and self.states.hover
            and self.states.hover.is
            and not (G.CONTROLLER and G.CONTROLLER.dragging and G.CONTROLLER.dragging.target)
        then
            if BT.rep_drag_select == nil then
                BT.rep_drag_select = not self.highlighted
            end
            BT.rep_drag_active = true

            if BT.rep_drag_select and not self.highlighted then
                BT.hand_area:add_to_highlighted(self)
            elseif not BT.rep_drag_select and self.highlighted then
                BT.hand_area:remove_from_highlighted(self)
            end
        end
    end
end

if Card and type(Card.click) == "function" and not BT.rep_drag_click_wrapped then
    BT.rep_drag_click_wrapped = true
    local card_click_ref = Card.click

    function Card:click(...)
        if BT.active and self.area == BT.hand_area and BT.rep_drag_active then
            BT.rep_drag_select = nil
            BT.rep_drag_active = nil
            return
        end
        return card_click_ref(self, ...)
    end
end
