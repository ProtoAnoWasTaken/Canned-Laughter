SMODS.Atlas({
    key = "maurelii",
    path = "maurelii.png",
    px = 69,
    py = 93,
})

local EXTINCTION_FLAGS = {
    "gros_michel_extinct",
    "canlaugh_plantain_extinct",
    "canlaugh_cavendish_extinct",
    "canlaugh_ingens_extinct",
}

local function canlaugh_maurelii_extinction_cycles()
    local flags = G and G.GAME and G.GAME.pool_flags or {}
    local cycles = 0

    for _, key in ipairs(EXTINCTION_FLAGS) do
        if flags[key] then
            cycles = cycles + 1
        end
    end

    return cycles
end

SMODS.Joker({
    key = "maurelii",
    name = "Maurelii",
    atlas = "maurelii",
    pos = { x = 0, y = 0 },
    rarity = 2,
    cost = 7,
    yes_pool_flag = "gros_michel_extinct",
    config = {
        extra = {
            chips = 250,
            gain = 250,
        },
    },
    loc_txt = {
        name = "Maurelii",
        text = {
            "{C:chips}+#1#{} Chips",
            "Gains {C:chips}+#2#{} Chips per",
            "{C:attention}extinction cycle{}",
            "{C:inactive}(Currently {C:chips}+#3#{C:inactive} Chips)",
        },
    },
    loc_vars = function(self, info_queue, card)
        local extra = card and card.ability.extra or self.config.extra
        local current_chips = extra.chips + extra.gain * canlaugh_maurelii_extinction_cycles()

        return {
            vars = {
                extra.chips,
                extra.gain,
                current_chips,
            },
        }
    end,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    pools = {
        Food = true,
    },
    calculate = function(self, card, context)
        if context.joker_main then
            local extra = card.ability.extra
            return {
                chips = extra.chips + extra.gain * canlaugh_maurelii_extinction_cycles(),
            }
        end
    end,
})
