local CL = CannedLaughter
SMODS.Atlas({ key = "boss_horse", path = "blind_horse.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

local function scoring_size(cards)
    local _, _, _, scoring_hand = G.FUNCS.get_poker_hand_info(cards)
    local count = 0

    for _, card in ipairs(cards) do
        local scores = SMODS.always_scores(card) or next(find_joker("Splash"))

        if not scores then
            for _, scoring_card in ipairs(scoring_hand) do
                if card == scoring_card then
                    scores = true
                    break
                end
            end
        end

        if scores and not SMODS.never_scores(card) then count = count + 1 end
    end

    return count
end

local function used_sizes()
    local game = G and G.GAME
    if not game then return {} end

    local ante = game.round_resets and game.round_resets.ante or 0
    if game.canlaugh_horse_ante ~= ante then
        game.canlaugh_horse_ante = ante
        game.canlaugh_horse_sizes = {}
    end

    game.canlaugh_horse_sizes = game.canlaugh_horse_sizes or {}
    return game.canlaugh_horse_sizes
end

CL.register_standard_boss({
    key = "horse",
    atlas = "boss_horse",
    boss_colour = HEX("9358C4"),
    mult = 1.75,
    loc_txt = { name = "The Horse", text = { "No repeat scoring", "hand sizes" } },
    set_blind = function(self)
        used_sizes()
    end,
    debuff_hand = function(self, cards, hand, handname, check)
        local size = scoring_size(cards)
        local sizes = used_sizes()
        local triggered = sizes[size] or false
        if G and G.GAME and G.GAME.blind then G.GAME.blind.triggered = triggered end
        if triggered then return true end
        if not check then sizes[size] = true end
    end,
})
