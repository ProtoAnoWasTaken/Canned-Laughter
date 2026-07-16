SMODS.Atlas({
    key = "blood_astronomia",
    path = "blood_astronomia.png",
    px = 69,
    py = 93,
})

local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_blood_astronomia_update(delta_chips, delta_mult)
    if not (G and G.jokers and G.jokers.cards) then
        return
    end

    for _, joker in ipairs(G.jokers.cards) do
        local center = joker.config and joker.config.center
        if center and center.key == "j_canlaugh_blood_astronomia" and joker.ability then
            joker.ability.extra = joker.ability.extra or { chips = 0, mult = 0 }
            joker.ability.extra.chips = (joker.ability.extra.chips or 0) + (delta_chips or 0) * 0.25
            joker.ability.extra.mult = (joker.ability.extra.mult or 0) + (delta_mult or 0) * 0.25
        end
    end
end

if Card and type(Card.use_consumeable) == "function" and not CL.blood_astronomia_planet_hook_installed then
    CL.blood_astronomia_planet_hook_installed = true
    local use_consumeable_ref = Card.use_consumeable

    function Card:use_consumeable(...)
        local center = self and self.config and self.config.center
        local hand_key = center and center.config and center.config.hand_type
        local hand = hand_key and G and G.GAME and G.GAME.hands and G.GAME.hands[hand_key]
        local before_chips = hand and hand.chips
        local before_mult = hand and hand.mult
        local results = { use_consumeable_ref(self, ...) }

        if center and center.set == "Planet" and hand then
            canlaugh_blood_astronomia_update(
                math.max(0, (hand.chips or 0) - (before_chips or hand.chips or 0)),
                math.max(0, (hand.mult or 0) - (before_mult or hand.mult or 0))
            )
        end

        return unpack(results)
    end
end

SMODS.Joker({
    key = "blood_astronomia",
    name = "Blood Astronomia",
    atlas = "blood_astronomia",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    unlocked = false,
    config = { extra = { chips = 0, mult = 0 } },
    loc_txt = {
        name = "Blood Astronomia",
        text = {
            "Gains an additional {C:attention}25%{} of the",
            "Chips and Mult from every {C:planet}Planet{} Card used",
            "{C:inactive}(Currently {C:chips}+#1#{C:inactive} Chips and {C:mult}+#2#{C:inactive} Mult){}",
        },
        unlock = {
            "Successfully barter with a",
            "{C:attention}Mega Celestial Pack{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability and card.ability.extra or self.config.extra
        return { vars = { extra.chips, extra.mult } }
    end,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    check_for_unlock = function(self, args)
        return args and args.type == "canlaugh_mega_celestial_barter"
    end,
    calculate = function(self, card, context)
        if context.joker_main
            and card.ability.extra
            and ((card.ability.extra.chips or 0) > 0 or (card.ability.extra.mult or 0) > 0)
        then
            return {
                chips = card.ability.extra.chips or 0,
                mult = card.ability.extra.mult or 0,
            }
        end
    end,
})

if CL.unlocks and CL.unlocks.register_mega_barter_joker then
    CL.unlocks.register_mega_barter_joker(
        "Celestial",
        "canlaugh_mega_celestial_barter",
        "j_canlaugh_blood_astronomia"
    )
end
