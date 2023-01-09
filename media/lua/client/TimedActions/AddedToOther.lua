require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISEquipWeaponAction"
local burnFact = 1.3

function ISBaseTimedAction:adjustMaxTime(maxTime)
    if maxTime ~= -1 then
        local maxTime_org = maxTime
        -- add a slight maxtime if the character is unhappy
        maxTime = maxTime + ((self.character:getMoodles():getMoodleLevel(MoodleType.Unhappy)) * 10)

        -- add more time if the character have his hands wounded
        if not self.ignoreHandsWounds then
            for i=BodyPartType.ToIndex(BodyPartType.Hand_L), BodyPartType.ToIndex(BodyPartType.ForeArm_R) do
                local part = self.character:getBodyDamage():getBodyPart(BodyPartType.FromIndex(i));
                maxTime = maxTime + part:getPain();
            end
        end

        -- Apply a multiplier based on body temperature.
        maxTime = maxTime * self.character:getTimedActionTimeModifier();

        if self.noAfectByCut then return maxTime; end
        --Added if cut
        local modData = getPlayer():getModData()
        local protPartNames = {"RightHand", "RightForearm", "LeftHand", "LeftForearm"}
        local otherPartNames = {"RightArm", "LeftArm"}

        for i,name in ipairs(protPartNames) do
            if modData.TOC[name].IsCut then
                if modData.TOC[name].IsEquiped then
                    maxTime = maxTime * modData.TOC[name].EquipFact;
                else
                    maxTime = maxTime * 2;
                end
                if modData.TOC[name].IsBurn then maxTime = maxTime * burnFact end
            end
        end

        for i,name in ipairs(otherPartNames) do
            if modData.TOC[name].IsCut then
                maxTime = maxTime * 2
                if modData.TOC[name].IsBurn then maxTime = maxTime * burnFact end
            end
        end

        -- Protheses perks stuff
        if modData.TOC.RightHand.IsCut then maxTime = maxTime * (1 + (9 - self.character:getPerkLevel(Perks.RightHand)) / 20) end
        if modData.TOC.LeftHand.IsCut then maxTime = maxTime * (1 + (9 - self.character:getPerkLevel(Perks.LeftHand)) / 20) end

        if maxTime > 10 * maxTime_org then maxTime = 10 * maxTime_org end
    end
    return maxTime;
end

function ISEquipWeaponAction:perform()
    if self.sound then
        self.character:getEmitter():stopSound(self.sound)
    end

    self.item:setJobDelta(0.0);

    if self:isAlreadyEquipped(self.item) then
        ISBaseTimedAction.perform(self);
        return
    end

    if self.character:isEquippedClothing(self.item) then
        self.character:removeWornItem(self.item)
        triggerEvent("OnClothingUpdated", self.character)
    end

    self.item:getContainer():setDrawDirty(true);
    forceDropHeavyItems(self.character)

    if self.fromHotbar then
        local hotbar = getPlayerHotbar(self.character:getPlayerNum());
        hotbar.chr:removeAttachedItem(self.item);
        self:setOverrideHandModels(self.item, nil)
    end

    if not self.twoHands then
        -- equip primary weapon
        if(self.primary) then
            -- if the previous weapon need to be equipped in both hands, we then remove it
            if self.character:getSecondaryHandItem() and self.character:getSecondaryHandItem():isRequiresEquippedBothHands() then
                self.character:setSecondaryHandItem(nil);
            end
            -- if this weapon is already equiped in the 2nd hand, we remove it
            if(self.character:getSecondaryHandItem() == self.item or self.character:getSecondaryHandItem() == self.character:getPrimaryHandItem()) then
                self.character:setSecondaryHandItem(nil);
            end
            if not self.character:getPrimaryHandItem() or self.character:getPrimaryHandItem() ~= self.item then
                self.character:setPrimaryHandItem(nil);
                self.character:setPrimaryHandItem(self.item);
            end
        else -- second hand weapon
            -- if the previous weapon need to be equipped in both hands, we then remove it
            if self.character:getPrimaryHandItem() and self.character:getPrimaryHandItem():isRequiresEquippedBothHands() then
                self.character:setPrimaryHandItem(nil);
            end
            -- if this weapon is already equiped in the 1st hand, we remove it
            if(self.character:getPrimaryHandItem() == self.item or self.character:getSecondaryHandItem() == self.character:getPrimaryHandItem()) then
                self.character:setPrimaryHandItem(nil);
            end
            if not self.character:getSecondaryHandItem() or self.character:getSecondaryHandItem() ~= self.item then
                self.character:setSecondaryHandItem(nil);
                self.character:setSecondaryHandItem(self.item);
            end
        end
    else
        self.character:setPrimaryHandItem(nil);
        self.character:setSecondaryHandItem(nil);

        self.character:setPrimaryHandItem(self.item);
        self.character:setSecondaryHandItem(self.item);
    end

    local modData = self.character:getModData()
    if not self.item:isRequiresEquippedBothHands() then
        if modData.TOC.RightHand.IsCut then
            if modData.TOC.RightForearm.IsCut then
                if not modData.TOC.RightForearm.IsEquiped then
                    self.character:setPrimaryHandItem(nil);
                    self.character:setSecondaryHandItem(self.item);
                end
            else
                if not modData.TOC.RightHand.IsEquiped then
                    self.character:setPrimaryHandItem(nil);
                    self.character:setSecondaryHandItem(self.item);
                end
            end
        end
        if modData.TOC.LeftHand.IsCut then
            if modData.TOC.LeftForearm.IsCut then
                if not modData.TOC.LeftForearm.IsEquiped then
                    self.character:setPrimaryHandItem(self.item);
                    self.character:setSecondaryHandItem(nil);
                end
            else
                if not modData.TOC.LeftHand.IsEquiped then
                    self.character:setPrimaryHandItem(self.item);
                    self.character:setSecondaryHandItem(nil);
                end
            end
        end
        if (modData.TOC.RightHand.IsCut and not (modData.TOC.RightHand.IsEquiped or modData.TOC.RightForearm.IsEquiped)) and (modData.TOC.LeftHand.IsCut and not (modData.TOC.LeftHand.IsEquiped or modData.TOC.LeftForearm.IsEquiped)) then
            self.character:dropHandItems();
        end
    end

    if self.item:isRequiresEquippedBothHands() and ((modData.TOC.RightHand.IsCut and not modData.TOC.RightHand.IsEquiped) or (modData.TOC.RightForearm.IsCut and not modData.TOC.RightForearm.IsEquiped) or (modData.TOC.LeftHand.IsCut and not modData.TOC.LeftHand.IsEquiped) or (modData.TOC.LeftForearm.IsCut and not modData.TOC.LeftForearm.IsEquiped)) then
        self.character:dropHandItems();
    end

    --if self.item:canBeActivated() and ((instanceof("Drainable", self.item) and self.item:getUsedDelta() > 0) or not instanceof("Drainable", self.item)) then
    if self.item:canBeActivated() then
        self.item:setActivated(true);
    end
    getPlayerInventory(self.character:getPlayerNum()):refreshBackpacks();

    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self);
end