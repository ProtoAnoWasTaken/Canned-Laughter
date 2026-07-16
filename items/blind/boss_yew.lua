local CL = CannedLaughter
SMODS.Atlas({ key = "boss_yew", path = "blind_yew.png", px = 34, py = 34, atlas_table = "ANIMATION_ATLAS", frames = 21 })

CL.register_standard_boss({
    key = "yew",
    atlas = "boss_yew",
    art = "yew",
    boss_colour = HEX("E5724F"),
    mult = 2,
    loc_txt = { name = "The Yew", text = { "The leftmost card becomes the", "rightmost card before scoring" } },
    press_play = function(self)
        local cards = G.hand and G.hand.highlighted or {}
        if #cards <= 1 then
            return
        end

        local leftmost = cards[1]
        local rightmost = cards[1]

        for _, card in ipairs(cards) do
            if card.T.x < leftmost.T.x then
                leftmost = card
            end

            if card.T.x > rightmost.T.x then
                rightmost = card
            end
        end

        leftmost:flip()
        play_sound("card1")
        leftmost:juice_up(0.3, 0.3)
        delay(0.2)
        copy_card(rightmost, leftmost)
        delay(0.1)
        leftmost:flip()
        play_sound("tarot2", 1, 0.6)
        leftmost:juice_up(0.3, 0.3)
        delay(0.2)
    end,
})
