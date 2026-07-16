local CL = CannedLaughter
SMODS.Atlas({ key = "boss_bridge", path = "blind_bridge.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "bridge",
    atlas = "boss_bridge",
    art = "bridge",
    boss_colour = HEX("69D36D"),
    mult = 2,
    loc_txt = { name = "The Bridge", text = { "After Play, random cards", "are debuffed" } },
    press_play = function(self)
        local cards = {}
        local selected = {}

        for _, card in ipairs(G and G.hand and G.hand.highlighted or {}) do
            selected[card] = true
        end

        for _, card in ipairs(G and G.hand and G.hand.cards or {}) do
            if not selected[card] then cards[#cards + 1] = card end
        end

        local amount = math.min(#cards, pseudorandom(pseudoseed("canlaugh_bridge_amount"), 1, 5))

        for _ = 1, amount do
            local index = pseudorandom(pseudoseed("canlaugh_bridge_card"), 1, #cards)
            local card = table.remove(cards, index)
            card.ability.canlaugh_bridge_debuff = true
            card:set_debuff(true)
        end
    end,
    recalc_debuff = function(self, card)
        return card and card.playing_card and card.ability and card.ability.canlaugh_bridge_debuff
    end,
    disable = function(self)
        for _, card in ipairs(G and G.playing_cards or {}) do
            if card.ability then
                card.ability.canlaugh_bridge_debuff = nil
                card:set_debuff(false)
            end
        end
    end,
    defeat = function(self)
        self:disable()
    end,
})
