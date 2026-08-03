local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "widow_normal",
    path = "widow_normal.png",
    px = 69,
    py = 93,
})

SMODS.Atlas({
    key = "widow_arachnophobia",
    path = "widow_arachnophobia.png",
    px = 69,
    py = 93,
})

local function canlaugh_widow_atlas()
    local prefix = CL.mod and CL.mod.prefix or "canlaugh"
    if CL.config and CL.config.arachnophobia then
        return prefix .. "_widow_arachnophobia"
    end

    return prefix .. "_widow_normal"
end

function CL.refresh_widow_sprites()
    local atlas = SMODS and SMODS.get_atlas and SMODS.get_atlas(canlaugh_widow_atlas())
    if not atlas then
        return
    end

    for _, card in ipairs(G and G.I and G.I.CARD or {}) do
        local center = card.config and card.config.center
        if center
            and center.key == "j_canlaugh_widow"
            and card.children
            and card.children.center
        then
            card.children.center.atlas = atlas
            card.children.center:set_sprite_pos({ x = 0, y = 0 })
        end
    end
end

if Card and type(Card.set_sprites) == "function" and not CL.widow_sprite_hook_installed then
    CL.widow_sprite_hook_installed = true
    local set_sprites_ref = Card.set_sprites

    function Card:set_sprites(center, front, ...)
        if center and center.key == "j_canlaugh_widow" then
            local sprite_center = setmetatable({
                atlas = canlaugh_widow_atlas(),
            }, {
                __index = center,
            })
            return set_sprites_ref(self, sprite_center, front, ...)
        end

        return set_sprites_ref(self, center, front, ...)
    end
end

SMODS.Joker({
    key = "widow",
    name = "Widow",
    atlas = "widow_normal",
    pos = { x = 0, y = 0 },
    rarity = 3,
    cost = 8,
    config = {
        extra = {
            flipped_cards = {},
            free_discard_used = false,
        },
    },
    loc_txt = {
        name = "Widow",
        text = {
            "First {C:attention}drawn hand{} is drawn",
            "{C:attention}face down{}",
            "First {C:red}discard{} is {C:blue}free{}",
        },
    },
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    calculate = function(self, card, context)
        local extra = card.ability.extra

        if context.setting_blind and not context.blueprint then
            extra.free_discard_used = false
        end

        if context.first_hand_drawn and context.hand_drawn and not context.blueprint then
            extra.flipped_cards = {}
            for _, playing_card in ipairs(context.hand_drawn) do
                if playing_card.facing == "front" then
                    playing_card:flip()
                    extra.flipped_cards[#extra.flipped_cards + 1] = playing_card
                end
            end
        end

        if context.after and not context.blueprint then
            for _, playing_card in ipairs(extra.flipped_cards or {}) do
                if playing_card.facing == "back" then
                    playing_card:flip()
                end
            end
            extra.flipped_cards = {}
        end

        if context.discard and not context.blueprint and not extra.free_discard_used then
            extra.free_discard_used = true
            ease_discard(1)
            return {
                message = "Free!",
                colour = G.C.BLUE,
            }
        end

        if context.selling_self and not context.blueprint then
            for _, playing_card in ipairs(extra.flipped_cards or {}) do
                if playing_card.facing == "back" then
                    playing_card:flip()
                end
            end
            extra.flipped_cards = {}
        end
    end,
})
