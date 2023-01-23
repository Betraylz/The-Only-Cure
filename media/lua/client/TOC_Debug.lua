function TocResetEverything()
    -- This has to be run on the local player to be sure that we're correctly reassigning everything
    local player = getPlayer()
    local player_inventory = player:getInventory()
    local mod_data = player:getModData()
    mod_data.TOC = nil
    TheOnlyCure.InitTheOnlyCure(_, player)

    -- Destroy the amputation or prosthesis item
    for _, v in ipairs(GetBodyParts()) do
        --local amputated_clothing = player:getInventory():FindAndReturn(TocFindAmputatedClothingFromPartName(v))
        -- TODO make it better
        local amputation_item_name = TocFindAmputationOrProsthesisName(v, player, "Amputation")
        local prosthesis_item_name = TocFindAmputationOrProsthesisName(v, player, "Prosthesis")

        if amputation_item_name ~= nil then
            local amputation_item = player_inventory:FindAndReturn(amputation_item_name)
            if amputation_item ~= nil then
                print("Resetting " .. amputation_item:getName())
                player:removeWornItem(amputation_item)
                player:getInventory():Remove(amputation_item)
            end
            amputation_item = nil -- reset it
        end
        if prosthesis_item_name ~= nil then
            local prosthesis_item = player_inventory:FindAndReturn(prosthesis_item_name)
            if prosthesis_item ~= nil then
                print("Resetting " .. prosthesis_item:getName())
                player:removeWornItem(prosthesis_item)
                player:getInventory():Remove(prosthesis_item)
            end
            prosthesis_item = nil -- reset it
        end


    end
end
