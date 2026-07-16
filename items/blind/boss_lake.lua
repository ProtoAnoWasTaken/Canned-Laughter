local CL = CannedLaughter
SMODS.Atlas({ key = "boss_lake", path = "blind_lake.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

local function lake_flipped_cards()
    local blind = G and G.GAME and G.GAME.blind
    if not blind then
        return {}
    end

    blind.canlaugh_lake_flipped_cards = blind.canlaugh_lake_flipped_cards or {}
    return blind.canlaugh_lake_flipped_cards
end

local function lake_scored_ranks()
    local blind = G and G.GAME and G.GAME.blind
    if not blind then
        return {}
    end

    blind.canlaugh_lake_scored_ranks = blind.canlaugh_lake_scored_ranks or {}
    return blind.canlaugh_lake_scored_ranks
end

local function lake_rank_is_scored(card)
    local rank = card and card.get_id and card:get_id()
    return rank and lake_scored_ranks()[rank]
end

local function restore_lake_cards()
    local blind = G and G.GAME and G.GAME.blind
    local flipped_cards = blind and blind.canlaugh_lake_flipped_cards
    if not blind then
        return
    end

    if flipped_cards then
        for card in pairs(flipped_cards) do
            if card and card.facing == "back" then
                card:flip()
            end
        end
    end

    blind.canlaugh_lake_flipped_cards = nil
    blind.canlaugh_lake_scored_ranks = nil
end

CL.register_standard_boss({
    key = "lake",
    atlas = "boss_lake",
    boss_colour = HEX("4395D5"),
    mult = 2,
    loc_txt = { name = "The Lake", text = { "Scored ranks are turned", "face down" } },
    calculate = function(self, blind, context)
        if not (context and context.after and context.scoring_hand) then return end

        local scored_ranks = {}
        for _, card in ipairs(context.scoring_hand) do
            local rank = card and card.get_id and card:get_id()
            if rank then
                scored_ranks[rank] = true
                lake_scored_ranks()[rank] = true
            end
        end

        for _, area in ipairs({ G and G.hand, G and G.deck }) do
            for _, card in ipairs(area and area.cards or {}) do
                local rank = card and card.get_id and card:get_id()
                if scored_ranks[rank] and card.facing == "front" then
                    card:flip()
                    lake_flipped_cards()[card] = true
                end
            end
        end
    end,
    stay_flipped = function(self, area, card)
        return area == G.hand and lake_rank_is_scored(card)
    end,
    disable = function(self)
        restore_lake_cards()
    end,
    defeat = function(self)
        restore_lake_cards()
    end,
})
