local CL = CannedLaughter
SMODS.Atlas({ key = "showdown_acacia_aegis", path = "showdown_acaciaaegis.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

local suits = { "Spades", "Hearts", "Clubs", "Diamonds" }

local function protected_suit()
    local game = G and G.GAME
    local blind = game and game.blind
    local center = blind and blind.config and blind.config.blind
    if not blind or not center or center.key ~= "bl_canlaugh_acacia_aegis" then
        return "Spades"
    end

    local ante = game.round_resets and game.round_resets.ante or 0
    if blind.canlaugh_acacia_aegis_ante == ante and blind.canlaugh_acacia_aegis_suit then
        return blind.canlaugh_acacia_aegis_suit
    end

    local suit = CL.boss_random(suits, "canlaugh_acacia_aegis_" .. tostring(ante))
    blind.canlaugh_acacia_aegis_ante = ante
    blind.canlaugh_acacia_aegis_suit = suit
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
