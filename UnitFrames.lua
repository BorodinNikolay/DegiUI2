--Фрейм игрока
PlayerFrame:ClearAllPoints()PlayerFrame:SetPoint("RIGHT",UIParent,"CENTER",-85,-185)PlayerFrame.SetPoint=function()end

--Фрейм цели
TargetFrame:ClearAllPoints()TargetFrame:SetPoint("LEFT",UIParent,"CENTER",85,-185)TargetFrame.SetPoint=function()end

--Панель пета
PetActionBarFrame:ClearAllPoints()PetActionBarFrame:SetPoint("CENTER",MultiBarBottomRight,"TOP",32,24)PetActionBarFrame.SetPoint=function()end

--Фремы группы
PartyMemberFrame1:ClearAllPoints()PartyMemberFrame1:SetPoint("CENTER",PlayerFrame,"TOP",-150, 25)PartyMemberFrame1.SetPoint=function()end


--Minimap
MinimapBorderTop:Hide()
MinimapZoomIn:Hide()
MinimapZoomOut:Hide()
MiniMapWorldMapButton:Hide()
GameTimeFrame:Hide()
GameTimeFrame:UnregisterAllEvents()
GameTimeFrame.Show = kill

MiniMapTracking:Hide()
MiniMapTracking.Show = kill
MiniMapTracking:UnregisterAllEvents()

--Зум миникарты колесиком мыши
Minimap:EnableMouseWheel(true)
Minimap:SetScript("OnMouseWheel", function(self, z)
    local c = Minimap:GetZoom()
    if(z > 0 and c < 5) then
        Minimap:SetZoom(c + 1)
    elseif(z < 0 and c > 0) then
        Minimap:SetZoom(c - 1)
    end
end)

--ПКМ - календарь, средняя - трекинг
Minimap:SetScript("OnMouseUp", function(self, btn)
    if btn == "RightButton" then
        _G.GameTimeFrame:Click()
    elseif btn == "MiddleButton" then
        _G.ToggleDropDownMenu(1, nil, _G.MiniMapTrackingDropDown, self)
    else
        _G.Minimap_OnClick(self)
    end
end)

--Правая панель 1
MultiBarRight:ClearAllPoints()MultiBarRight:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",0,270)MultiBarRight.SetPoint=function()end
MultiBarRight:SetScale(0.8)


--Правая панель 2
MultiBarLeft:ClearAllPoints()MultiBarLeft:SetPoint("BOTTOMRIGHT",UIParent,"BOTTOMRIGHT",-38,270)MultiBarLeft.SetPoint=function()end
MultiBarLeft:SetScale(0.8)


--цвет ХП по классу
local UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS =
UnitIsPlayer, UnitIsConnected, UnitClass, RAID_CLASS_COLORS
local _, class, c

local function colour(statusbar, unit)
if UnitIsPlayer(unit) and UnitIsConnected(unit) and unit == statusbar.unit and UnitClass(unit) then
_, class = UnitClass(unit)
c = CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class] or RAID_CLASS_COLORS[class]
statusbar:SetStatusBarColor(c.r, c.g, c.b)
end
end

hooksecurefunc("UnitFrameHealthBar_Update", colour)
hooksecurefunc("HealthBar_OnValueChanged", function(self)
colour(self, self.unit)
end)

local sb = _G.GameTooltipStatusBar
local addon = CreateFrame("Frame", "StatusColour")
addon:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
addon:SetScript("OnEvent", function()
colour(sb, "mouseover")
end)


--скрытие названия макросов
hooksecurefunc('ActionButton_UpdateHotkeys', function(self)
    local macro = _G[self:GetName()..'Name']
    if macro then macro:Hide() end
end)


--Увеличение размера собственныз дебаффов
hooksecurefunc("TargetFrame_UpdateAuraPositions", function(self, auraName, numAuras, numOppositeAuras,largeAuraList, updateFunc, maxRowWidth, offsetX)
    local AURA_OFFSET_Y = 2
    local LARGE_AURA_SIZE = 24 -- рамеер ВАШИХ баффов/дебаффов.
    local SMALL_AURA_SIZE = 16 -- рамеер чужих баффов/дебаффов.
    local size
    local offsetY = AURA_OFFSET_Y
    local rowWidth = 0
    local firstBuffOnRow = 1
    for i=1, numAuras do
    if ( largeAuraList[i] ) then
        size = LARGE_AURA_SIZE
        offsetY = AURA_OFFSET_Y + AURA_OFFSET_Y
    else
        size = SMALL_AURA_SIZE
    end
    if ( i == 1 ) then
        rowWidth = size
        self.auraRows = self.auraRows + 1
    else
        rowWidth = rowWidth + size + offsetX
    end
    if ( rowWidth > maxRowWidth ) then
        updateFunc(self, auraName, i, numOppositeAuras, firstBuffOnRow, size, offsetX, offsetY)
        rowWidth = size
        self.auraRows = self.auraRows + 1
        firstBuffOnRow = i
        offsetY = AURA_OFFSET_Y
    else
        updateFunc(self, auraName, i, numOppositeAuras, i - 1, size, offsetX, offsetY)
    end
    end
    end)

WatchFrame:SetScale(0.5)
