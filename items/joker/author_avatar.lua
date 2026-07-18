local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

SMODS.Atlas({
    key = "author_avatar",
    path = "author_avatar.png",
    px = 69,
    py = 93,
})

local function earthsea_defeated()
    local profile = G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    local earned = G and G.SETTINGS and G.SETTINGS.ACHIEVEMENTS_EARNED

    return profile and (profile.canlaugh_earthsea_borealis_defeated or profile.all_unlocked)
        or earned and earned.canlaugh_still_the_best_2026
end

local function author_avatar_active()
    local cards = SMODS and SMODS.find_card and SMODS.find_card("j_canlaugh_author_avatar") or {}

    for _, card in ipairs(cards) do
        if not card.debuff then
            return true
        end
    end

    return false
end

local function author_avatar_x_mult()
    local count = G and G.GAME and G.GAME.canlaugh_bosses_defeated or 0
    if count <= 0 then
        return 1
    end

    return 3 * count
end

if Card and type(Card.is_face) == "function" and not CL.author_avatar_face_hook_installed then
    CL.author_avatar_face_hook_installed = true
    local is_face_ref = Card.is_face

    function Card:is_face(from_boss, ...)
        if author_avatar_active() then
            return true
        end

        return is_face_ref(self, from_boss, ...)
    end
end

SMODS.Joker({
    key = "author_avatar",
    name = "Author Avatar",
    atlas = "author_avatar",
    pos = { x = 0, y = 0 },
    rarity = 4,
    cost = 20,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = false,
    discovered = false,
    loc_txt = {
        name = "Author Avatar",
        text = {
            "{X:mult,C:white}X3{} Mult for each {C:attention}Boss Blind{}",
            "defeated this run",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{C:inactive} Mult){}",
            "All cards are considered",
            "{C:attention}face cards{}",
        },
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { author_avatar_x_mult() } }
    end,
    in_pool = function(self)
        return earthsea_defeated()
    end,
    check_for_unlock = function(self, args)
        return earthsea_defeated()
            and args
            and args.type == "canlaugh_earthsea_borealis_defeated"
    end,
    calculate = function(self, card, context)
        if context.joker_main then
            return {
                x_mult = author_avatar_x_mult(),
            }
        end
    end,
})
