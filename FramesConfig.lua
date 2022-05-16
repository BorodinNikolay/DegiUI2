local _, class = UnitClass("player")

---------------------------------------------------
-- standard configuration
---------------------------------------------------
whoaUnitFrames = {}
whoaUnitFrames.config = {
    classColorPlayer = true,        -- true or false
    classColorTarget = true,        -- true or false
    classColorFocus = true,         -- true or false
    classColorParty = true,         -- true or false
    repositionPartyText = true,     -- true or false
    largeAuraSize = 26,             -- Blizzard default value is 21
    smallAuraSize = 20,             -- Blizzard default value is 17
--    customStatusText = true,        -- true or false (If this is false, all following points receive no consideration!)
    autoManaPercent = false,        -- true or false (If this is true, percentages where shown for mana classes!)
    thousandSeparators = true,      -- true or false
    simpleHealth = true,            -- rounds healthpoints over 199.999 (200.000 to 200 k, 3.000.000 to 3 m)
}

whoaUnitFrames.config.phrases = {
    ["1000 separator"] = " ",
    ["Dead"] = "|cFFFFFFFFDead|r",
    ["Ghost"] = "|cFFFFFFFFGhost|r",
    ["Offline"] = "|cFFFFFFFFOffline|r",
    ["kilo"] = " k",  -- simpleHealth 1.000
    ["mega"] = " m",  -- simpleHealth 1.000.000
    ["giga"] = " g",  -- simpleHealth 1.000.000.000
}

---------------------------------------------------
-- class specific configuration
---------------------------------------------------
if class == "PRIEST" then
    whoaUnitFrames.config.largeAuraSize = 21
    whoaUnitFrames.config.smallAuraSize = 17
    whoaUnitFrames.config.autoManaPercent = true
end
if class == "DRUID" then
    whoaUnitFrames.config.repositionPartyText = false
end
if class == "MAGE" then
    whoaUnitFrames.config.repositionPartyText = false
end
if class == "PALADIN" then
    whoaUnitFrames.config.repositionPartyText = false
end
if class == "SHAMAN" then
    whoaUnitFrames.config.repositionPartyText = false
end
if class == "WARLOCK" then
    whoaUnitFrames.config.repositionPartyText = false
end
if class == "DEATHKNIGHT" then
    whoaUnitFrames.config.repositionPartyText = false
end
if class == "HUNTER" then
    whoaUnitFrames.config.repositionPartyText = false
end
if class == "ROGUE" then
    whoaUnitFrames.config.autoManaPercent = true
end
if class == "WARRIOR" then
    whoaUnitFrames.config.repositionPartyText = false
end





---------------------------------------------------
-- CONFIGURATION -> config.lua
-- NOT HERE!
---------------------------------------------------
local config = whoaUnitFrames.config
local buffList = whoaUnitFrames.buffList
local _, class = UnitClass("player")
local classcolor = RAID_CLASS_COLORS[select(2, UnitClass("player"))]
local color = nil
local h, hMax, hPercent, m, mMax, mPercent = 0

-- aura positioning constants
local AURA_START_X = 5;
local AURA_START_Y = 30;
local AURA_OFFSET_Y = 3
local LARGE_AURA_SIZE = config.largeAuraSize
local SMALL_AURA_SIZE = config.smallAuraSize
local AURA_ROW_WIDTH = 122
local NUM_TOT_AURA_ROWS = 3

---------------------------------------------------
-- DK RUNES
---------------------------------------------------
if class == "DEATHKNIGHT" then
    RuneButtonIndividual1:ClearAllPoints()
    RuneButtonIndividual1:SetPoint("TOPLEFT", PlayerFrameManaBar, "BOTTOMLEFT", -1, -5)
end

---------------------------------------------------
-- PARTY
---------------------------------------------------
local function whoa_partyMembersChanged()
    local partyMembers = GetNumPartyMembers()
    if not InCombatLockdown() and partyMembers > 0 then
        for i = 1, partyMembers do
            color = RAID_CLASS_COLORS[select(2, UnitClass("party"..i))]
            if color then
                _G["PartyMemberFrame"..i.."HealthBar"]:SetStatusBarColor(color.r, color.g, color.b)
                _G["PartyMemberFrame"..i.."HealthBar"].lockColor = true
            end
            if config.repositionPartyText then
                _G["PartyMemberFrame"..i.."HealthBarText"]:ClearAllPoints()
                _G["PartyMemberFrame"..i.."HealthBarText"]:SetPoint("LEFT", _G["PartyMemberFrame"..i.."HealthBar"], "RIGHT", 0, 0)
                _G["PartyMemberFrame"..i.."ManaBarText"]:ClearAllPoints()
                _G["PartyMemberFrame"..i.."ManaBarText"]:SetPoint("LEFT", _G["PartyMemberFrame"..i.."ManaBar"], "RIGHT", 0, 0)
            end    
        end
    end
end

---------------------------------------------------
-- PLAYERFRAME
---------------------------------------------------
local function whoa_playerFrame()
    if not UnitHasVehicleUI("player") then
        PlayerName:SetWidth(0.01)
        PlayerFrameGroupIndicatorText:ClearAllPoints()
        PlayerFrameGroupIndicatorText:SetPoint("BOTTOMLEFT", PlayerFrame, "TOP", 0, -20)
        PlayerFrameGroupIndicatorLeft:Hide()
        PlayerFrameGroupIndicatorMiddle:Hide()
        PlayerFrameGroupIndicatorRight:Hide()
        PlayerFrameHealthBar:ClearAllPoints()
        PlayerFrameHealthBar:SetPoint("TOPLEFT", 107, -24)
        PlayerFrameHealthBar:SetHeight(18)
        if classcolor and config.classColorPlayer then
            PlayerFrameHealthBar:SetStatusBarColor(classcolor.r, classcolor.g, classcolor.b)
            PlayerFrameHealthBar.lockColor = true
        else
            color = FACTION_BAR_COLORS[8] -- 8 is exalted
            if color then
                PlayerFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
                PlayerFrameHealthBar.lockColor = true
            end
        end
        PlayerFrameHealthBarText:ClearAllPoints()
        PlayerFrameHealthBarText:SetPoint("CENTER", PlayerFrameHealthBar, "CENTER", 0, 0)
        PlayerFrameManaBar:ClearAllPoints()
        PlayerFrameManaBar:SetPoint("TOPLEFT", 107, -45)
        PlayerFrameManaBar:SetHeight(17)
        PlayerFrameManaBarText:ClearAllPoints()
        PlayerFrameManaBarText:SetPoint("CENTER", PlayerFrameManaBar, "CENTER", 0, 0)
    else
        if config.classColorPlayer then
            color = FACTION_BAR_COLORS[8] -- 8 is exalted
            if color then
                PlayerFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
                PlayerFrameHealthBar.lockColor = true
            end
        end
        PlayerFrameHealthBar:SetHeight(12)
        PlayerFrameManaBar:SetHeight(12)
    end
end
hooksecurefunc("PlayerFrame_UpdateArt", whoa_playerFrame)
hooksecurefunc("PlayerFrame_SequenceFinished", whoa_playerFrame)

---------------------------------------------------
-- TARGETFRAME
---------------------------------------------------
local function whoa_targetFrame()
    TargetFrame.nameBackground:Hide()
    TargetFrame.deadText:ClearAllPoints()
    TargetFrame.deadText:SetPoint("CENTER", TargetFrameHealthBar, "CENTER", 0, 0)
    TargetFrameTextureFrameName:ClearAllPoints()
    TargetFrameTextureFrameName:SetPoint("BOTTOMRIGHT", TargetFrame, "TOP", 0, -20)
    TargetFrameHealthBar:ClearAllPoints()
    TargetFrameHealthBar:SetPoint("TOPLEFT", 5, -24)
    TargetFrameHealthBar:SetHeight(18)
    TargetFrameTextureFrameHealthBarText:ClearAllPoints()
    TargetFrameTextureFrameHealthBarText:SetPoint("CENTER", TargetFrameHealthBar, "CENTER", 0, 0)
    TargetFrameManaBar:ClearAllPoints()
    TargetFrameManaBar:SetPoint("TOPLEFT", 5, -45)
    TargetFrameManaBar:SetHeight(17)
    TargetFrameTextureFrameManaBarText:ClearAllPoints()
    TargetFrameTextureFrameManaBarText:SetPoint("CENTER", TargetFrameManaBar, "CENTER", 0, 0)
    TargetFrame.threatNumericIndicator:SetPoint("BOTTOM", PlayerFrame, "TOP", 75, -22)
end

local function whoa_targetChanged()
    if UnitIsPlayer("target") and config.classColorTarget then
        color = RAID_CLASS_COLORS[select(2, UnitClass("target"))]
    else
        --color = FACTION_BAR_COLORS[UnitReaction("target", "player")]
        --print (UnitReaction("target", "player"))
        if UnitReaction("target", "player") ~= nil and UnitReaction("target", "player") <= 3 then color = {r = 1, g = 0, b = 0, s = 1}
            elseif UnitReaction("target", "player") == 4 then color = {r = 1, g = 1, b = 0, s = 1}
            else color = {r = 0, g = 1, b = 0, s = 1}
        end
    end
    if ( not UnitPlayerControlled("target") and UnitIsTapped("target") and not UnitIsTappedByPlayer("target") and not UnitIsTappedByAllThreatList("target") ) then
        TargetFrameHealthBar:SetStatusBarColor(0.5, 0.5, 0.5)
    else
        if color then
            TargetFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
            TargetFrameHealthBar.lockColor = true
        end
    end
end
hooksecurefunc("TargetFrame_CheckFaction", whoa_targetChanged)

---------------------------------------------------
-- FOCUSFRAME
---------------------------------------------------
local function whoa_focusFrame()
    FocusFrame.nameBackground:Hide()
    FocusFrame.deadText:ClearAllPoints()
    FocusFrame.deadText:SetPoint("CENTER", FocusFrameHealthBar, "CENTER", 0, 0)
    FocusFrameTextureFrameName:ClearAllPoints()
    FocusFrameHealthBar:ClearAllPoints()
    FocusFrameHealthBar:SetPoint("TOPLEFT", 5, -24)
    FocusFrameHealthBar:SetHeight(18)
    FocusFrameManaBar:ClearAllPoints()
    FocusFrameManaBar:SetPoint("TOPLEFT", 5, -45)
    FocusFrameManaBar:SetHeight(17)
    FocusFrame.threatNumericIndicator:SetWidth(0.01)
    FocusFrame.threatNumericIndicator.bg:Hide()
    FocusFrame.threatNumericIndicator.text:Hide()
    FocusFrameTextureFrameHealthBarText:ClearAllPoints()
    FocusFrameTextureFrameHealthBarText:SetPoint("CENTER", FocusFrameHealthBar, "CENTER", 0, 0)
    FocusFrameTextureFrameManaBarText:ClearAllPoints()
    FocusFrameTextureFrameManaBarText:SetPoint("CENTER", FocusFrameManaBar, "CENTER", 0, 0)
end

local function whoa_focusChanged()
    if UnitIsPlayer("focus") and config.classColorFocus then
        color = RAID_CLASS_COLORS[select(2, UnitClass("focus"))]
    else
        --color = FACTION_BAR_COLORS[UnitReaction("focus", "player")]

        if UnitExists("focus") and UnitReaction("focus", "player") <= 3 then color = {r = 1, g = 0, b = 0, s = 1}
            elseif UnitReaction("focus", "player") == 4 then color = {r = 1, g = 1, b = 0, s = 1}
            else color = {r = 0, g = 1, b = 0, s = 1}
        end



    end
    if color then
        FocusFrameHealthBar:SetStatusBarColor(color.r, color.g, color.b)
        FocusFrameHealthBar.lockColor = true
    end
end

---------------------------------------------------
-- TARGETBUFFS
---------------------------------------------------
local function whoa_targetUpdateAuraPositions(self, auraName, numAuras, numOppositeAuras, largeAuraList, updateFunc, maxRowWidth, offsetX, mirrorAurasVertically)
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
            updateFunc(self, auraName, i, numOppositeAuras, firstBuffOnRow, size, offsetX, offsetY, mirrorAurasVertically)
            rowWidth = size
            self.auraRows = self.auraRows + 1
            firstBuffOnRow = i
            offsetY = AURA_OFFSET_Y
        else
            updateFunc(self, auraName, i, numOppositeAuras, i - 1, size, offsetX, offsetY, mirrorAurasVertically)
        end
    end
end
hooksecurefunc("TargetFrame_UpdateAuraPositions", whoa_targetUpdateAuraPositions)

local function whoa_targetUpdateBuffAnchor(self, buffName, index, numDebuffs, anchorIndex, size, offsetX, offsetY, mirrorVertically)
    local point, relativePoint
    local startY, auraOffsetY
    if ( mirrorVertically ) then
        point = "BOTTOM"
        relativePoint = "TOP"
        startY = -8
        offsetY = -offsetY
        auraOffsetY = -AURA_OFFSET_Y
    else
        point = "TOP"
        relativePoint="BOTTOM"
        startY = AURA_START_Y
        auraOffsetY = AURA_OFFSET_Y
    end
     
    local buff = _G[buffName..index]
    if ( index == 1 ) then
        if ( UnitIsFriend("player", self.unit) or numDebuffs == 0 ) then
            buff:SetPoint(point.."LEFT", self, relativePoint.."LEFT", AURA_START_X, startY)           
        else
            buff:SetPoint(point.."LEFT", self.debuffs, relativePoint.."LEFT", 0, -offsetY)
        end
        self.buffs:SetPoint(point.."LEFT", buff, point.."LEFT", 0, 0)
        self.buffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY)
        self.spellbarAnchor = buff
    elseif ( anchorIndex ~= (index-1) ) then
        buff:SetPoint(point.."LEFT", _G[buffName..anchorIndex], relativePoint.."LEFT", 0, -offsetY)
        self.buffs:SetPoint(relativePoint.."LEFT", buff, relativePoint.."LEFT", 0, -auraOffsetY)
        self.spellbarAnchor = buff
    else
        buff:SetPoint(point.."LEFT", _G[buffName..anchorIndex], point.."RIGHT", offsetX, 0)
    end

    buff:SetWidth(size)
    buff:SetHeight(size)
end
hooksecurefunc("TargetFrame_UpdateBuffAnchor", whoa_targetUpdateBuffAnchor)



local function whoa_cvarUpdate()
    if GetCVarBool("fullSizeFocusFrame") then
        FocusFrameTextureFrameName:SetPoint("BOTTOMRIGHT", FocusFrame, "TOP", 0, -20)
    else
        FocusFrameTextureFrameName:SetPoint("BOTTOMRIGHT", FocusFrame, "TOP", 10, -20)
    end
end

---------------------------------------------------
-- EVENTS
---------------------------------------------------
local w = CreateFrame("Frame")
w:RegisterEvent("PLAYER_ENTERING_WORLD")
w:RegisterEvent("PLAYER_REGEN_ENABLED")
w:RegisterEvent("PLAYER_TARGET_CHANGED")
w:RegisterEvent("PLAYER_FOCUS_CHANGED")
w:RegisterEvent("CVAR_UPDATE")
w:RegisterEvent("UNIT_HEALTH")
w:RegisterEvent("UNIT_POWER")
if config.classColorParty then
    w:RegisterEvent("PARTY_MEMBERS_CHANGED")
end
function w:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        SlashCmdList['RELOAD'] = function() ReloadUI() end
        SLASH_RELOAD1 = '/rl'
        --SlashCmdList['WHOA'] = function() InterfaceOptionsFrame_OpenToCategory(name) end
        --SLASH_WHOA1 = '/whoa'
        whoa_playerFrame()
        whoa_targetFrame()
        whoa_focusFrame()
        whoa_cvarUpdate()
        --whoa_unitText("player")
    elseif event == "PLAYER_REGEN_ENABLED" then
        whoa_playerFrame()
    elseif event == "PLAYER_TARGET_CHANGED" then
        whoa_targetChanged()
        --whoa_unitText("target")
    elseif event == "PLAYER_FOCUS_CHANGED" then
        whoa_focusChanged()
        --whoa_unitText("focus")
    elseif event == "UNIT_HEALTH" or event == "UNIT_POWER" then
        local unit = ...
        --whoa_unitText(unit)
    elseif event == "CVAR_UPDATE" then
        whoa_cvarUpdate()
    elseif event == "PARTY_MEMBERS_CHANGED" then
        whoa_partyMembersChanged()
    end
end
w:SetScript("OnEvent", w.OnEvent)