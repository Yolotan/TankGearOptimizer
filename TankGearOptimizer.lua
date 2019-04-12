local _G, pairs, tonumber
= _G, pairs, tonumber

local match = string.match
local format = string.format

local itemtips = {
    GameTooltip,
    ShoppingTooltip1,
    ShoppingTooltip2,
    ItemRefTooltip,
}

local AgiDodgeFactor = {
    ['Druid'] = 0.068,
    ['Hunter'] = 0.04,
    ['Mage'] = 0.04,
    ['Paladin'] = 0.04,
    ['Priest'] = 0.04,
    ['Rogue'] = 0.05,
    ['Shaman'] = 0.04,
    ['Warlock'] = 0.04,
    ['Warrior'] = 0.033
}

local function getAgiFactorForClass()
    local playerClass = UnitClass("player");
    for k, v in pairs(AgiDodgeFactor) do
        if playerClass == k then
            return v
        end
    end
end

local parryFactor = 0.042
local dodgeFactor = 0.053
local blockFactor = 0.127
local defFactor = 0.067
local agiFactor = getAgiFactorForClass()

local AvoidanceCases = {
    ["Equip: Increases defense rating by (%d+)"] = defFactor,
    ["(%d+) Defense Rating"] = defFactor,
    ["Equip: Increases your parry rating by (%d+)"] = parryFactor,
    ["(%d+) Parry Rating"] = parryFactor,
    ["Equip: Increases your dodge rating by (%d+)"] = dodgeFactor,
    ["(%d+) Dodge Rating"] = dodgeFactor,
    ["Equip: Increases your shield block rating by (%d+)"] = blockFactor,
    ["Equip: Increases your block rating by (%d+)"] = blockFactor,
    ["(%d+) block rating"] = blockFactor,
    ["(%d+) Agility"] = agiFactor
}

local function round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

local function OnTipSetItem(tip, name)
    local totalAvoidance = 0
    local totalStamina = 0
    for i = 1, tip:NumLines() do
        local obj = _G[format("%sTextLeft%s", name, i)]
        local text = obj:GetText()

        local staminaLine = match(text, "(%d+) Stamina")
        if staminaLine then
            local stamValue = tonumber(format("%s.", staminaLine))
            totalStamina = totalStamina + stamValue
            --            obj:SetText(stamValue)

            --            ChatFrame1:AddMessage();
        end

        for k, v in pairs(AvoidanceCases) do
            local defStat = match(text, k)
            if defStat then
                local defStatNumber = tonumber(format("%s.", defStat))
                local defStatValue = defStatNumber * v
                totalAvoidance = totalAvoidance + defStatValue
                --                obj:SetText(defStatValue)
            end
        end
    end
    if totalAvoidance > 0 then
        tip:AddLine(format("Total Avoidance: %s%%",totalAvoidance))
    end
    if totalStamina > 0 then
        tip:AddLine(format("Total Stamina: %s", totalStamina))
    end
    if totalStamina > 0 and totalAvoidance > 0 then
        tip:AddLine(format("Stamina/Avoidance factor: %s", round(totalStamina / totalAvoidance, 1)))
    end
end

local function OnSetItemRefTip()
    OnTipSetItem(ItemRefTooltip, "ItemRefTooltip")
end

for i = 1, #itemtips do
    local t = itemtips[i]
    t:HookScript("OnTooltipSetItem", function(self) OnTipSetItem(self, self:GetName()) end)
end

if AtlasLootTooltip then
    if AtlasLootTooltip:GetScript("OnShow") then
        AtlasLootTooltip:HookScript("OnShow", function(self) OnTipSetItem(self, self:GetName()) end)
    else
        AtlasLootTooltip:SetScript("OnShow", function(self) OnTipSetItem(self, self:GetName()) end)
    end
end

hooksecurefunc("SetItemRef", OnSetItemRefTip)
