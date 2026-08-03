local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local MAGPIES_EYE_KEY = "v_canlaugh_magpies_eye"
local MAGICIANS_EYE_KEY = "v_canlaugh_magicians_eye"
local B_SIDE_KEY = "v_canlaugh_b_side"
local VINYL_PRINT_KEY = "v_canlaugh_vinyl_print"

local function canlaugh_sprite_deck_unlocked()
    local required_keys = {
        MAGICIANS_EYE_KEY,
        VINYL_PRINT_KEY,
    }

    for _, key in ipairs(required_keys) do
        local center = G and G.P_CENTERS and G.P_CENTERS[key]
        if not (center and center.discovered) then
            return false
        end
    end

    return true
end

SMODS.Atlas({
    key = "sprite_deck",
    path = "sprite_deck.png",
    px = 69,
    py = 93,
})

SMODS.Back({
    key = "sprite_deck",
    name = "Sprite Deck",
    atlas = "sprite_deck",
    pos = { x = 0, y = 0 },
    order = 28,
    unlocked = false,
    config = {},
    loc_txt = {
        name = "Sprite Deck",
        text = {
            "Start with the {C:tarot,T:v_canlaugh_b_side}B-Side{}",
            "and {C:attention,T:v_canlaugh_magpies_eye}Magpie's Eye{} Vouchers",
        },
        unlock = {
            "Redeem {C:attention}Magician's Eye{}",
            "and {C:attention}Vinyl Print{}",
        },
    },
    check_for_unlock = function()
        return canlaugh_sprite_deck_unlocked()
    end,
    apply = function()
        if not (G and G.GAME) or G.GAME.canlaugh_sprite_deck_vouchers_applied then
            return
        end

        G.GAME.canlaugh_sprite_deck_vouchers_applied = true
        G.GAME.used_vouchers = G.GAME.used_vouchers or {}
        G.GAME.used_vouchers[MAGPIES_EYE_KEY] = true
        G.GAME.used_vouchers[B_SIDE_KEY] = true

        if G.hand and type(G.hand.change_size) == "function" then
            G.hand:change_size(1)
        end
    end,
})
