local CL = rawget(_G, "CannedLaughter") or {}
CannedLaughter = CL

if SMODS and type(SMODS.create_card) == "function" and not CL.card_creation_compat_installed then
    CL.card_creation_compat_installed = true
    local create_card_ref = SMODS.create_card

    function SMODS.create_card(args, ...)
        if type(args) == "table" and args.set == nil then
            local card_set = args.type

            if card_set == nil and not (args.front or args.rank or args.suit or args.enhancement) then
                local center = G and G.P_CENTERS and G.P_CENTERS[args.key]
                card_set = center and center.set
                if card_set == "Default" then
                    card_set = "Base"
                end
            end

            if card_set ~= nil then
                local normalized_args = {}
                for key, value in pairs(args) do
                    normalized_args[key] = value
                end
                normalized_args.set = card_set
                args = normalized_args
            end
        end

        return create_card_ref(args, ...)
    end
end
