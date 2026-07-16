local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

CL.infuriating_tags = CL.infuriating_tags or {
    joker = { tag_key = "tag_canlaugh_infuriating_joker", center_key = "j_joker" },
    oracle_attack = { tag_key = "tag_canlaugh_infuriating_oracle_attack", center_key = "j_canlaugh_oracle_attack" },
    mystic_summit = { tag_key = "tag_canlaugh_infuriating_mystic_summit", center_key = "j_mystic_summit" },
    bootstrap_paradox = { tag_key = "tag_canlaugh_infuriating_bootstrap_paradox", center_key = "j_canlaugh_bootstrap_paradox" },
    black_hole = { tag_key = "tag_canlaugh_infuriating_black_hole", center_key = "c_black_hole" },
}

function CL.infuriating_profile()
    local profile = G and G.PROFILES and G.SETTINGS and G.PROFILES[G.SETTINGS.profile]
    if not profile then return nil end
    profile.canlaugh_infuriating_tags = profile.canlaugh_infuriating_tags or {}
    return profile
end

function CL.infuriating_collected(id)
    local profile = CL.infuriating_profile()
    return profile and profile.canlaugh_infuriating_tags[id] == true or false
end

function CL.infuriating_all_collected()
    for id in pairs(CL.infuriating_tags) do
        if not CL.infuriating_collected(id) then return false end
    end
    return true
end

function CL.collect_infuriating_tag(id)
    local profile = CL.infuriating_profile()
    if not profile then return end
    profile.canlaugh_infuriating_tags[id] = true
    if type(save_settings) == "function" then save_settings() end
end

local tag_defs = {
    {
        id = "joker", atlas = "infuriating_tag_joker",
        text = {
            "The first, the worst! The point of entrance!",
            "It's with this one I'll find my temperance...",
            "{C:inactive}-R.J.{}",
        },
    },
    {
        id = "oracle_attack", atlas = "infuriating_tag_oracleattack",
        text = {
            "The perceiver, undead-deceiver, they lay in wait;",
            "then, with visions, they turn the weight.",
            "{C:inactive}-R.J.{}",
        },
    },
    {
        id = "mystic_summit", atlas = "infuriating_tag_mysticsummit",
        text = {
            "This place reminds me of the chambers below —",
            "with the stuttering staircases and devilish glow...",
            "{C:inactive}-R.J.{}",
        },
    },
    {
        id = "bootstrap_paradox", atlas = "infuriating_tag_bootstrapparadox",
        text = {
            "The treated skin of bovine divine pushes the weight",
            "of temporum sublime; if only there were simply more time.",
            "{C:inactive}-R.J.{}",
        },
    },
    {
        id = "black_hole", atlas = "infuriating_tag_blackhole",
        text = {
            "I'll find all I need at the center of mass; past the horizon,",
            "gravity rising, the soul of stardust's past. Surely now",
            "I may pass the impasse... {C:inactive}-R.J.{}",
        },
    },
}

local function remove_collected_tag(tag)
    if G and G.E_MANAGER and Event then
        G.E_MANAGER:add_event(Event({
            trigger = "after", delay = 0.25, blocking = false, blockable = false,
            func = function()
                if tag and type(tag.remove) == "function" then tag:remove() end
                return true
            end,
        }))
    elseif tag and type(tag.remove) == "function" then
        tag:remove()
    end
end

for index, def in ipairs(tag_defs) do
    local current = def
    SMODS.Atlas({ key = current.atlas, path = current.atlas .. ".png", px = 34, py = 34 })
    SMODS.Tag({
        key = "infuriating_" .. current.id,
        atlas = current.atlas,
        order = 90 + index,
        config = { type = "immediate", infuriating_id = current.id },
        pos = { x = 0, y = 0 },
        loc_txt = { name = "Infuriating Tag", text = current.text },
        in_pool = function() return false end,
        apply = function(self, tag, context)
            if not (context and context.type == "immediate" and context.canlaugh_tag_click) then return end
            CL.collect_infuriating_tag(current.id)
            tag:yep("Collected!", G.C.FILTER, function()
                remove_collected_tag(tag)
                return true
            end)
            tag.triggered = true
            return true
        end,
    })
end

if Tag and type(Tag.generate_UI) == "function" and not CL.infuriating_tag_click_hook then
    CL.infuriating_tag_click_hook = true
    local generate_UI_ref = Tag.generate_UI

    function Tag:generate_UI(...)
        local results = { generate_UI_ref(self, ...) }
        local id = self.config and self.config.infuriating_id
        local sprite = self.tag_sprite or results[2]
        if id and sprite then
            local tag = self
            sprite.states.click.can = true
            local click_ref = sprite.click
            function sprite:click(...)
                if not tag.triggered then
                    tag:apply_to_run({ type = "immediate", canlaugh_tag_click = true })
                    return
                end
                if click_ref then return click_ref(self, ...) end
            end
        end
        return unpack(results)
    end
end
