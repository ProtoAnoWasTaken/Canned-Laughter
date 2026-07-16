SMODS.Atlas({
    key = "ingens_back",
    path = "ingens_back.png",
    px = 69,
    py = 93,
})

SMODS.Atlas({
    key = "ingens_front",
    path = "ingens_front.png",
    px = 69,
    py = 93,
})

local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_hook_ingens_food_pool()
    local ingens = G and G.P_CENTERS and G.P_CENTERS.j_canlaugh_ingens
    local food_type = SMODS and SMODS.ObjectTypes and SMODS.ObjectTypes.Food

    if not (ingens and food_type and type(food_type.inject_card) == "function") then
        return
    end

    ingens.pools = ingens.pools or {}
    ingens.pools.Food = true
    food_type:inject_card(ingens)
end

CL.hook_ingens_food_pool = canlaugh_hook_ingens_food_pool

if SMODS and SMODS.ObjectType and type(SMODS.ObjectType.inject) == "function" and not CL.ingens_food_object_type_hook_installed then
    CL.ingens_food_object_type_hook_installed = true
    local canlaugh_object_type_inject_ref = SMODS.ObjectType.inject

    function SMODS.ObjectType:inject(...)
        local results = { canlaugh_object_type_inject_ref(self, ...) }

        if self and self.key == "Food" then
            canlaugh_hook_ingens_food_pool()
        end

        return unpack(results)
    end
end

local function canlaugh_play_ingens_sound()
    local native_sound = CL.native_sound

    if not (native_sound and type(native_sound.play) == "function") then
        return
    end

    local ok, err = pcall(native_sound.play, "sfx_ingens.ogg", {
        pitch = 1,
        volume = 0.45,
        source_type = "static",
    })

    if not ok and type(sendErrorMessage) == "function" then
        sendErrorMessage("[Canned Laughter] Failed to play Ingens sound: " .. tostring(err))
    end
end

local function canlaugh_queue_ingens_sound()
    local function play_sound_event()
        canlaugh_play_ingens_sound()
        return true
    end

    if G and G.E_MANAGER and Event then
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0,
            blockable = false,
            func = play_sound_event,
        }))
    else
        play_sound_event()
    end
end

local function canlaugh_ingens_draw(card, scale_mod, rotate_mod)
    if not (card and card.children and card.children.floating_sprite) then
        return
    end

    card.hover_tilt = card.hover_tilt * 1.5
    card.children.floating_sprite:draw_from(card.children.center, 2 * scale_mod, 2 * rotate_mod)
    card.hover_tilt = card.hover_tilt / 1.5
end

if Card and type(Card.calculate_joker) == "function" and not CL.ingens_cavendish_hook_installed then
    CL.ingens_cavendish_hook_installed = true
    local canlaugh_calculate_joker_ref = Card.calculate_joker

    function Card:calculate_joker(context, ...)
        local result, post = canlaugh_calculate_joker_ref(self, context, ...)

        if self
            and self.config
            and self.config.center
            and self.config.center.key == "j_cavendish"
            and result
            and result.message == localize("k_extinct_ex")
            and G
            and G.GAME
            and G.GAME.pool_flags
        then
            G.GAME.pool_flags.canlaugh_cavendish_extinct = true
        end

        return result, post
    end
end

if Card and type(Card.add_to_deck) == "function" and not CL.ingens_sound_hook_installed then
    CL.ingens_sound_hook_installed = true
    local canlaugh_add_to_deck_ref = Card.add_to_deck

    function Card:add_to_deck(from_debuff, ...)
        local should_play_sound = not from_debuff
            and not self.added_to_deck
            and self.config
            and self.config.center
            and self.config.center.key == "j_canlaugh_ingens"

        local results = { canlaugh_add_to_deck_ref(self, from_debuff, ...) }

        if should_play_sound then
            canlaugh_queue_ingens_sound()
            if type(check_for_unlock) == "function" then
                check_for_unlock({ type = "canlaugh_oh_banana" })
            end
        end

        return unpack(results)
    end
end

SMODS.Joker({
    key = "ingens",
    name = "Ingens",
    atlas = "ingens_back",
    soul_atlas = "ingens_front",
    pos = { x = 0, y = 0 },
    soul_pos = {
        x = 0,
        y = 0,
        draw = canlaugh_ingens_draw,
    },
    rarity = 2,
    cost = 8,
    unlocked = true,
    yes_pool_flag = "canlaugh_cavendish_extinct",
    config = {
        extra = {
            x_mult = 12,
            odds = 10000,
        },
    },
    loc_txt = {
        name = "Ingens",
        text = {
            "{X:mult,C:white}X#1#{} Mult",
            "{C:green}#2# in #3#{} chance this",
            "card is destroyed at",
            "end of round",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        local numerator, denominator = SMODS.get_probability_vars(card, 1, extra.odds, "canlaugh_ingens")

        return {
            vars = {
                extra.x_mult,
                numerator,
                denominator,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = false,
    perishable_compat = true,
    pools = {
        Food = true,
    },
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                x_mult = card.ability.extra.x_mult,
            }
        end

        if context.end_of_round
            and not context.individual
            and not context.repetition
            and not context.blueprint
        then
            if SMODS.pseudorandom_probability(card, "canlaugh_ingens", 1, card.ability.extra.odds) then
                SMODS.destroy_cards(card, nil, nil, true)
                if G and G.GAME and G.GAME.pool_flags then
                    G.GAME.pool_flags.canlaugh_ingens_extinct = true
                end
                return {
                    message = localize("k_extinct_ex"),
                }
            end

            return {
                message = localize("k_safe_ex"),
            }
        end
    end,
})

canlaugh_hook_ingens_food_pool()
