local CL = CannedLaughter
SMODS.Atlas({ key = "showdown_acacia_aegis", path = "showdown_acaciaaegis.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

local suits = { "Spades", "Hearts", "Clubs", "Diamonds" }

local function protected_suit()
    local game = G and G.GAME
    local blind = game and game.blind
    if not blind then return "Spades" end

    blind.debuff = blind.debuff or {}
    if blind.debuff.suit then return blind.debuff.suit end

    local ante = game.round_resets and game.round_resets.ante or 0
    local suit

    if game.canlaugh_acacia_aegis_ante == ante then
        suit = game.canlaugh_acacia_aegis_suit
    end

    suit = suit or CL.boss_random(suits, "canlaugh_acacia_aegis_" .. tostring(ante))
    game.canlaugh_acacia_aegis_ante = ante
    game.canlaugh_acacia_aegis_suit = suit
    blind.debuff.suit = suit
    return suit
end

CL.register_showdown_boss({
    key = "acacia_aegis",
    atlas = "showdown_acacia_aegis",
    boss_colour = HEX("FD7F00"),
    mult = 2,
    loc_txt = { name = "Acacia Aegis", text = { "All suits but #1#", "are debuffed" } },
    set_blind = function(self)
        protected_suit()
    end,
    loc_vars = function(self)
        return { vars = { localize(protected_suit(), "suits_plural") } }
    end,
    collection_loc_vars = function(self)
        return { vars = { "one random suit" } }
    end,
    recalc_debuff = function(self, card)
        return card and card.playing_card and not card:is_suit(protected_suit(), true)
    end,
})
