local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

local function canlaugh_survivor_requirement_met()
    for _, key in ipairs({
        "j_canlaugh_mad_groove",
        "j_canlaugh_blood_astronomia",
        "j_canlaugh_hail_from_the_future",
        "j_canlaugh_edge_of_the_earth",
    }) do
        if not (G and G.P_CENTERS and G.P_CENTERS[key] and G.P_CENTERS[key].discovered) then
            return false
        end
    end
    return true
end

SMODS.Atlas({
    key = "survivors_deck",
    path = "randomazzo.png",
    px = 56,
    py = 80,
})

SMODS.Back({
    key = "survivors_deck",
    name = "Survivor's Deck",
    atlas = "survivors_deck",
    pos = { x = 0, y = 0 },
    unlocked = false,
    order = 22,
    config = {
        hands = 1,
    },
    loc_txt = {
        name = "Survivor's Deck",
        text = {
            "{C:blue}+1{} hand",
            "Create a {C:attention}Buffoon Tag{}",
            "after every {C:attention}Boss Blind{}",
            "All items are {C:money}25%{} cheaper",
            "Required score scales faster",
            "for each {C:attention}Ante{}",
        },
        unlock = {
            "Complete the {C:attention}Darkanist{} achievement",
        },
    },
    check_for_unlock = function(self, args)
        return canlaugh_survivor_requirement_met() or (args and (
            args.type == "canlaugh_darkanist"
            or args.type == "darkanist"
            or args.type == "ach_canlaugh_darkanist"
        ))
    end,
    apply = function(self, back)
        G.GAME.discount_percent = math.max(G.GAME.discount_percent or 0, 25)
        G.GAME.modifiers.scaling = (G.GAME.modifiers.scaling or 1) + 1
    end,
    calculate = function(self, back, context)
        if context.setting_blind then
            G.GAME.canlaugh_survivor_buffoon_this_round = nil
        end

        if context.end_of_round
            and context.beat_boss
            and context.main_eval
            and not context.game_over
            and not context.individual
            and not context.repetition
            and not G.GAME.canlaugh_survivor_buffoon_this_round
        then
            G.GAME.canlaugh_survivor_buffoon_this_round = true
            if type(add_tag) == "function" and Tag then
                add_tag(Tag("tag_buffoon"))
            end
            return {
                message = "+Buffoon Tag",
                colour = G.C.FILTER,
            }
        end

    end,
})
