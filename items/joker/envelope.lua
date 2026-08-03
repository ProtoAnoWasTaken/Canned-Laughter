local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "envelope",
    path = "envelope.png",
    px = 69,
    py = 93,
})

local function canlaugh_envelope_ante()
    return G and G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante
end

local function canlaugh_juice_active_envelopes()
    for _, joker in ipairs((G and G.jokers and G.jokers.cards) or {}) do
        local center = joker and joker.config and joker.config.center
        if center
            and center.key == "j_canlaugh_envelope"
            and not joker.debuff
            and not joker.removed
        then
            joker:juice_up(0.3, 0.5)
        end
    end
end

if Card and type(Card.set_seal) == "function" and not CL.envelope_seal_hook_installed then
    CL.envelope_seal_hook_installed = true
    local set_seal_ref = Card.set_seal

    function Card:set_seal(seal, ...)
        local previous_seal = self.seal
        local results = { set_seal_ref(self, seal, ...) }

        if seal and self.seal == seal and previous_seal ~= seal and G and G.GAME then
            local ante = canlaugh_envelope_ante()
            local first_seal_this_ante = ante and G.GAME.canlaugh_envelope_sealed_ante ~= ante
            G.GAME.canlaugh_envelope_sealed_ante = ante

            if first_seal_this_ante then
                canlaugh_juice_active_envelopes()
            end
        end

        return unpack(results)
    end
end

local function canlaugh_envelope_is_boss(context)
    local blind = context and context.blind

    return blind
        and (
            blind.boss
            or (type(blind.get_type) == "function" and blind:get_type() == "Boss")
        )
end

local function canlaugh_envelope_gain(card)
    local seed = "canlaugh_envelope_" .. tostring(card and card.sort_id or "")
    local total = 0

    for roll = 1, 6 do
        total = total + pseudorandom(seed .. "_" .. tostring(roll))
    end

    return math.floor((total / 6) * 41) - 10
end

SMODS.Joker({
    key = "envelope",
    name = "Envelope",
    atlas = "envelope",
    pos = { x = 0, y = 0 },
    rarity = 1,
    cost = 4,
    config = {
        extra = {
            last_boss_ante = nil,
        },
    },
    loc_txt = {
        name = "Envelope",
        text = {
            "If a {C:attention}seal{} was applied this Ante,",
            "gain {C:money}-$10{} to {C:money}$30{} at the start",
            "of the {C:attention}Boss Blind{}",
            "{C:inactive}(Active: {C:attention}#1#{C:inactive}){}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local ante = canlaugh_envelope_ante()
        local sealed_this_ante = ante
            and G
            and G.GAME
            and G.GAME.canlaugh_envelope_sealed_ante == ante
        local active = sealed_this_ante or (card and card.seal)

        return {
            vars = {
                active and "Yes" or "No",
            },
        }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        if not context.setting_blind
            or context.blueprint
            or context.retrigger_joker
            or not canlaugh_envelope_is_boss(context)
        then
            return
        end

        local ante = canlaugh_envelope_ante()
        local extra = card.ability.extra
        local sealed_this_ante = G.GAME.canlaugh_envelope_sealed_ante == ante
        if not ante
            or extra.last_boss_ante == ante
            or not (sealed_this_ante or card.seal)
        then
            return
        end

        extra.last_boss_ante = ante
        local dollars = canlaugh_envelope_gain(card)
        local message = dollars >= 0 and "+$" .. tostring(dollars) or "-$" .. tostring(math.abs(dollars))
        card:juice_up(0.3, 0.5)

        return {
            dollars = dollars,
            message = message,
            colour = dollars >= 0 and G.C.MONEY or G.C.RED,
        }
    end,
})
