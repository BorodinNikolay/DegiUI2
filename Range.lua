--[[-------------------------------------------------------------------------
	GreenRange
	Copyright (C) 2010  Morsker
	Please contact Morsker through PM on forums.wowace.com.

	Super efficient out-of-range coloring.

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
---------------------------------------------------------------------------]]

local addonName, GreenRange = ...

-- constants
local RANGE_CHECK_INTERVAL = 0.1
local DB_VERSION = 1

-- GLOBALS: GreenRangeDB
-- GLOBALS: ATTACK_BUTTON_FLASH_TIME
-- GLOBALS: CreateFrame
-- GLOBALS: EnumerateFrames
-- GLOBALS: AnimTimerFrame

-- upvalues
local _G = _G
local pairs = pairs
local hooksecurefunc = hooksecurefunc
local ActionHasRange = ActionHasRange
local IsActionInRange = IsActionInRange
local IsUsableAction = IsUsableAction

-- local functions
local print
--((@)) local Debug
local HandleEvent
local BuildTimer
local CacheAbstractSet
--[===[@debug@
local InitDebug
--@end-debug@]===]

-- local functions (range)
local MarkOOR
local UnmarkOOR
local UpdateAllRanges
local ShouldWeWatchThis
local SupersedeBlizColors
local SnarfButton

-- local functions (flashing)
local UpdateAllFlashing
local AddFlash
local RemoveFlash

-- locals
local db
local optionsFrame = CreateFrame("Frame")
local OOR_R, OOR_G, OOR_B
local OOM_R, OOM_G, OOM_B

-- locals (range)
local nRanged = 0
local watchedForRange = {}
local watchedForRange_cache = {}
local watchedForRange_rebuild
local rangeTimer

-- locals (flashing)
local nFlashing = 0
local flashesCurrentlyRed = false
local flashingButtons = {}
local flashingButtons_cache = {}
local flashingButtons_rebuild
local flashingTimer

-- dark magics!
-- Unfortunately this technique is limited, in that you have to get the polymorphic call right, otherwise
-- the framework throws an error. (If you attempt the basic Frame :Show() on a CheckButton, it will error.)
-- The Frame_Show and Frame_Hide are safe, since GreenRange creates those frames itself. The others -might-
-- be safe, and there's only one way to find out!
local Frame_Show = optionsFrame.Show
local Frame_Hide = optionsFrame.Hide
local CheckButton_IsVisible = ActionButton1.IsVisible
local Texture_Show = ActionButton1Icon.Show
local Texture_Hide = ActionButton1Icon.Hide
local Texture_GetVertexColor = ActionButton1Icon.GetVertexColor
local Texture_SetVertexColor = ActionButton1Icon.SetVertexColor

-------------
--  Utils  --
-------------

do -- print
	local prefix = "|cff33ff99"..addonName.."|r:"
	function print(...)
		_G.print(prefix, ...)
	end
end

------------------------------------
--  Addon-Level Objects / Events  --
------------------------------------

_G.GreenRange = GreenRange
GreenRange.optionsFrame = optionsFrame

function GreenRange:SetOOR_Color(r, g, b)
	OOR_R, OOR_G, OOR_B = r, g, b
	db.oor[1], db.oor[2], db.oor[3] = r, g, b
	local EnumerateFrames = EnumerateFrames
	local frame = EnumerateFrames()
	while frame do
		if frame:IsObjectType("CheckButton") and frame.oor then
			Texture_SetVertexColor(frame.icon, r, g, b)
			Texture_SetVertexColor(frame.normalTexture, r, g, b)
		end
		frame = EnumerateFrames(frame)
	end
end

function GreenRange:SetOOM_Color(r, g, b)
	OOM_R, OOM_G, OOM_B = r, g, b
	db.oom[1], db.oom[2], db.oom[3] = r, g, b
	local EnumerateFrames = EnumerateFrames
	local frame = EnumerateFrames()
	while frame do
		if frame:IsObjectType("CheckButton") and frame.oor == false and frame.usableState == 1 then
			Texture_SetVertexColor(frame.icon, r, g, b)
			Texture_SetVertexColor(frame.normalTexture, r, g, b)
		end
		frame = EnumerateFrames(frame)
	end
end

function GreenRange.HandleEvent(frame, event, ...)
	if event == "PLAYER_ENTERING_WORLD" then
		if nRanged > 0 then
			rangeTimer:Play()
		end
		if nFlashing > 0 then
			flashingTimer:Play()
		end
	elseif event == "PLAYER_LEAVING_WORLD" then
		rangeTimer:Stop()
		flashingTimer:Stop()
	end
end

optionsFrame:SetScript("OnEvent", function(frame, event, name)
	if name ~= addonName then return end

	frame:UnregisterEvent("ADDON_LOADED")
	frame:SetScript("OnEvent", GreenRange.HandleEvent)
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PLAYER_LEAVING_WORLD")

	-- Init!
	if not GreenRangeDB then
		GreenRangeDB = {
			db_version = DB_VERSION,
			oor = { 1.0, 0.2, 0.2 },
			oom = { 0.2, 0.2, 1.0 },
		}
	end
	db = GreenRangeDB
	OOR_R, OOR_G, OOR_B = db.oor[1], db.oor[2], db.oor[3]
	OOM_R, OOM_G, OOM_B = db.oom[1], db.oom[2], db.oom[3]

	-- range stuff
	rangeTimer = BuildTimer(RANGE_CHECK_INTERVAL, UpdateAllRanges, true)
	hooksecurefunc("ActionButton_OnUpdate", SnarfButton)
	--((@)) hooksecurefunc("ActionButton_OnUpdate", function(...) Debug("Snarfed from ActionButton_OnUpdate") end)
	hooksecurefunc("ActionButton_UpdateUsable", SupersedeBlizColors)
	--((@)) hooksecurefunc("ActionButton_UpdateUsable", function(...) Debug("ActionButton_UpdateUsable") end)
	hooksecurefunc("ActionButton_Update", ShouldWeWatchThis)

	-- flash stuff
	flashingTimer = BuildTimer(ATTACK_BUTTON_FLASH_TIME, UpdateAllFlashing, true)
	flashingTimer:SetScript("OnStop", function() flashesCurrentlyRed = false end)
	hooksecurefunc("ActionButton_StartFlash", AddFlash)
	hooksecurefunc("ActionButton_StopFlash", RemoveFlash)

	--[===[@debug@
	InitDebug()
	--@end-debug@]===]
end)
optionsFrame:RegisterEvent("ADDON_LOADED")

-- Builds an AnimationGroup that calls 'func' on 'interval'.
-- Returns the AnimationGroup without starting it. Call :Play() to start it.
-- REQUIREMENT: func receives an internal frame as its first and only argument. It must hide this frame.
--
-- Implements some bucketing, for the pathological case where the frame rate is lower than the
-- interval. The animation actually only shows an internal frame, deferring the action until the
-- frame's next OnUpdate. This is why 'func' has to hide the frame, so that it only receives one
-- call instead of being spammed by OnUpdate.
function BuildTimer(interval, func, fireOnPlay)
	local bucketFrame = CreateFrame("Frame")
	local function ShowBucketFrame()
		Frame_Show(bucketFrame)
	end
	Frame_Hide(bucketFrame)
	bucketFrame:SetScript("OnUpdate", func)

	local animGroup = AnimTimerFrame:CreateAnimationGroup()
	if fireOnPlay then
		animGroup:SetScript("OnPlay", ShowBucketFrame)
	end
	local anim = animGroup:CreateAnimation("Animation")
	anim:SetDuration(interval)
	anim:SetOrder(1)
	anim:SetScript("OnFinished", ShowBucketFrame)
	animGroup:SetLooping("REPEAT")
	return animGroup
end

---------------
--  Caching  --
---------------

-- We track "sets" of button objects that need to be checked for things.
--
-- The 'hashVersion' is the authoritative version of the data that the cache must be made consistent with.
-- The 'arrayVersion' is the cache that's faster to iterate on.
-- The values in 'hashVersion' are ignored. It's the keys that are populated into 'arrayVersion'.

function CacheAbstractSet(hashVersion, arrayVersion)
	local i, last = 0, #arrayVersion
	for k,_ in pairs(hashVersion) do
		i = i + 1
		arrayVersion[i] = k
	end
	while i < last do
		arrayVersion[last] = nil
		last = last - 1
	end
end

-------------------------
--  Range-Check Timer  --
-------------------------

function UpdateAllRanges(internalFrame)
	Frame_Hide(internalFrame)
	local IsActionInRange = IsActionInRange
	local watchedForRange_cache = watchedForRange_cache

	-- validate cache
	if watchedForRange_rebuild then
		--((@)) Debug("rebuild watchedForRange")
		CacheAbstractSet(watchedForRange, watchedForRange_cache)
		watchedForRange_rebuild = nil
	end

	-- iterate on cache
	for i = 1,#watchedForRange_cache do
		local button = watchedForRange_cache[i]
		local newOOR = not not (IsActionInRange(button.action) == 0)

		if newOOR ~= button.oor then
			local ToggleMark = newOOR and MarkOOR or UnmarkOOR
			ToggleMark(button)
		end
	end
end

------------------------------------------
--  Add / Remove for our "Watch" table  --
-------------------------------------------

-- 'watchedForRange' has buttons iff they have a ranged action -and- are shown.
-- Adding a button does an initial range check and may set OOR.
-- Removing a button strips OOR status if it's set.
--
-- Originally I had separate hooks for OnShow / OnHide / ActionButton_Update.
-- But ActionButton_Update is the most common event by far, and optimizing for it makes OnShow and OnHide redundant.
-- So we only need this one handler.

function ShouldWeWatchThis(button)
	--((@)) Debug("ShouldWeWatchThis")
	local isWatched = watchedForRange[button]
	local shouldWatch = button.eventsRegistered and ActionHasRange(button.action) and CheckButton_IsVisible(button)

	if isWatched then
		if not shouldWatch then
			-- Lost our range-sensitive action. Stop watching.
			if button.oor then
				UnmarkOOR(button)
			end
			watchedForRange[button] = nil
			watchedForRange_rebuild = 1
			nRanged = nRanged - 1
			if nRanged == 0 then
				--((@)) Debug("rangeTimer: Stop!")
				rangeTimer:Stop()
			end
		end
	else
		if shouldWatch then
			-- Gained a range-sensitive action. Start watching.
			if button.oor == nil then
				--((@)) Debug("Snarfed from ShouldWeWatchThis")
				SnarfButton(button)
			end
			if IsActionInRange(button.action) == 0 then
				MarkOOR(button)
			end
			watchedForRange[button] = 1
			watchedForRange_rebuild = 1
			nRanged = nRanged + 1
			if nRanged == 1 then
				--((@)) Debug("rangeTimer: Play!")
				rangeTimer:Play()
			end
		end
	end
end

-- Flag the button as 'oor', and turn it red.
function MarkOOR(button)
	--((@)) Debug("MarkOOR")
	button.oor = true
	local r, g, b = OOR_R, OOR_G, OOR_B
	local Texture_SetVertexColor = Texture_SetVertexColor
	Texture_SetVertexColor(button.icon, r, g, b)
	Texture_SetVertexColor(button.normalTexture, r, g, b)
end

-- Unflag the button as 'oor', and apply any color changes noted by the hooks.
function UnmarkOOR(button)
	--((@)) Debug("UnmarkOOR")
	button.oor = false

	local usableState = button.usableState
	local r1, g1, b1, r2, g2, b2 = 1, 1, 1, 1, 1, 1 -- defaults
	if usableState == 0 then
		-- defaults white
	elseif usableState == 1 then
		-- oom
		r1, g1, b1 = OOM_R, OOM_G, OOM_B
		r2, g2, b2 = r1, g1, b1
	else
		-- unusable. second half defaults white.
		r1, g1, b1 = 0.4, 0.4, 0.4
	end
	local Texture_SetVertexColor = Texture_SetVertexColor
	Texture_SetVertexColor(button.icon, r1, g1, b1)
	Texture_SetVertexColor(button.normalTexture, r2, g2, b2)
end

------------------
--  Main Hooks  --
------------------

-- Make the button use our colors, but keep track of how the Bliz code wants it colored.
function SupersedeBlizColors(button)
	--((@)) Debug("SupersedeBlizColors")
	local oor = button.oor
	if oor ~= nil then
		local isUsable, notEnoughMana = IsUsableAction(button.action)
		local usableState = isUsable and 0 or (notEnoughMana and 1 or 2)
		button.usableState = usableState

		if oor then
			local r, g, b = OOR_R, OOR_G, OOR_B
			local Texture_SetVertexColor = Texture_SetVertexColor
			Texture_SetVertexColor(button.icon, r, g, b)
			Texture_SetVertexColor(button.normalTexture, r, g, b)
		elseif usableState == 1 then
			local r, g, b = OOM_R, OOM_G, OOM_B
			local Texture_SetVertexColor = Texture_SetVertexColor
			Texture_SetVertexColor(button.icon, r, g, b)
			Texture_SetVertexColor(button.normalTexture, r, g, b)
		end
	end
end

-- Steal the button the first time it tries to update, and make it use our code instead.
function SnarfButton(button)
	--((@)) Debug("SnarfButton")
	button.icon = _G[button:GetName().."Icon"] -- unnecessary after 4.0, but harmless
	button.normalTexture = button:GetNormalTexture()
	button.oor = false
	SupersedeBlizColors(button)

	button:SetScript("OnUpdate", nil)
	ShouldWeWatchThis(button)
	button:HookScript("OnShow", ShouldWeWatchThis)
	button:HookScript("OnHide", ShouldWeWatchThis)
	--((@)) button:HookScript("OnShow", function(...) Debug("OnShow hook") end)
	--((@)) button:HookScript("OnHide", function(...) Debug("OnHide hook") end)
end

----------------
--  Flashing  --
----------------

-- Other than the boilerplate code to check the cache and iterate over it, this is just a toggle on
-- the 'flashesCurrentlyRed' upvalue.
-- 'flashesCurrentlyRed' is initialized false, so starting the timer always makes it true on the next
-- update, immediately turning 'flashing' buttons red. It then switches state every
-- ATTACK_BUTTON_FLASH_TIME seconds. Stopping the timer always restores the initial state, making
-- 'flashesCurrentlyRed' false again, so the next restart sends buttons immediately to red.

function UpdateAllFlashing(internalFrame)
	Frame_Hide(internalFrame)
	local flashingButtons_cache = flashingButtons_cache

	-- validate cache
	if flashingButtons_rebuild then
		--((@)) Debug("rebuild flashingButtons")
		CacheAbstractSet(flashingButtons, flashingButtons_cache)
		flashingButtons_rebuild = nil
	end

	flashesCurrentlyRed = not flashesCurrentlyRed
	local ShowOrHide = flashesCurrentlyRed and Texture_Show or Texture_Hide

	-- iterate on cache
	for i = 1,#flashingButtons_cache do
		ShowOrHide(flashingButtons_cache[i].flash)
	end
end

-- 'flashingButtons' has buttons iff they're shown -and- have .flashing == 1
-- (.flashing == 1 is the logic used by ActionButton_IsFlashing. We just inline it.)
-- These need to sanity-check that the button isn't being double-added or double-removed, because
-- we get here by hooking ActionButton_StartFlash / ActionButton_StopFlash and there's no guarantee
-- they're used sanely.

function AddFlash(button)
	--((@)) Debug("AddFlash")
	if not flashingButtons[button] then
		local flash = button.flash
		if not flash then
			flash = _G[button:GetName().."Flash"]
			button.flash = flash
		end
		if flashesCurrentlyRed then
			Texture_Show(flash)
		end
		flashingButtons[button] = 1
		flashingButtons_rebuild = 1
		nFlashing = nFlashing + 1
		if nFlashing == 1 then
			--((@)) Debug("flashingTimer: Play!")
			flashingTimer:Play()
		end
	end
end

function RemoveFlash(button)
	--((@)) Debug("RemoveFlash")
	if flashingButtons[button] then
		flashingButtons[button] = nil
		flashingButtons_rebuild = 1
		nFlashing = nFlashing - 1
		if nFlashing == 0 then
			--((@)) Debug("flashingTimer: Stop!")
			flashingTimer:Stop()
		end
	end
end
