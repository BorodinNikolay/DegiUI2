-- all position are relative to the center onf the screen

b_CastingBars = {}
b_CastingBars.config = {
	-- player cast bar
	pcb_scale = 1,
	pcb_x = 0,
	pcb_y = -240,
	
	-- target cast bar
	tcb_scale = 1.6,
	tcb_x = 0,
	tcb_y = -50,
	
	-- focus cast bar
	fcb_scale = 1,
	fcb_x = 0,
	fcb_y = 200,
}

-- Player castbar 
local config = b_CastingBars.config
local cbf = "CastingBarFrame"
local cbbs = "Interface\\CastingBar\\UI-CastingBar-Border-Small"
local cbfs = "Interface\\CastingBar\\UI-CastingBar-Flash-Small"

_G[cbf]:SetSize(175,20)
_G[cbf.."Border"]:SetSize(240,32)
--_G[cbf.."Border"]:SetPoint("TOP", _G[cbf], 0, 32)
--_G[cbf.."Border"]:SetTexture(cbbs)
_G[cbf.."Border"]:ClearAllPoints()
_G[cbf.."Flash"]:ClearAllPoints()
--_G[cbf.."Flash"]:SetSize(240,32)
--_G[cbf.."Flash"]:SetPoint("TOP", _G[cbf], 0, 32)
--_G[cbf.."Flash"]:SetTexture(cbfs)
_G[cbf]:SetScale(config.pcb_scale)
_G[cbf.."Text"]:SetPoint("TOP", _G[cbf], 0, 0)
_G[cbf.."Text"]:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
_G[cbf]:ClearAllPoints()
_G[cbf]:SetPoint("TOP", WorldFrame, "CENTER", config.pcb_x, config.pcb_y) --0, 100
_G[cbf].SetPoint = function() end
_G[cbf.."Icon"]:Show()
_G[cbf.."Icon"]:SetHeight(20)
_G[cbf.."Icon"]:SetWidth(20)

-- Castbar timer from thek 
_G[cbf].timer = _G[cbf]:CreateFontString(nil)
_G[cbf].timer:SetFont("Fonts\\ARIALN.ttf", 10, "OUTLINE")
_G[cbf].timer:SetPoint("RIGHT", _G[cbf], "RIGHT", 2, -16)
_G[cbf].update = .1

local tcbf = "TargetFrameSpellBar"
_G[tcbf].timer = _G[tcbf]:CreateFontString(nil)
_G[tcbf].timer:SetFont("Fonts\\ARIALN.ttf", 8, "OUTLINE")
_G[tcbf].timer:SetPoint("RIGHT", _G[tcbf], "RIGHT", 36, 0)
_G[tcbf].update = .1

local fcbf = "FocusFrameSpellBar"
_G[fcbf].timer = _G[fcbf]:CreateFontString(nil)
_G[fcbf].timer:SetFont("Fonts\\ARIALN.ttf", 10, "OUTLINE")
_G[fcbf].timer:SetPoint("RIGHT", _G[fcbf], "RIGHT", 52, 0)
_G[fcbf].update = .1

hooksecurefunc("CastingBarFrame_OnUpdate", function(self, elapsed)
	if not self.timer then return end
	if self.update and self.update < elapsed then
		if self.casting then
			self.timer:SetText(format("%.1f", max(self.maxValue - self.value, 0)) .. " / " .. format("%.1f", max(self.maxValue, 0)))
		elseif self.channeling then
			self.timer:SetText(format("%.1f", max(self.value, 0)))
		else
			self.timer:SetText("")
		end
		self.update = .1
	else
		self.update = self.update - elapsed
	end
end)

-- Focus Castbar 
hooksecurefunc(FocusFrameSpellBar, "Show", function()
    --FocusFrameSpellBar:SetScale(config.fcb_scale)
	FocusFrameSpellBar:ClearAllPoints()
	--FocusFrameSpellBarBorder:ClearAllPoints()
	--FocusFrameSpellBar:SetPoint("CENTER", UIParent, "CENTER", config.fcb_x, config.fcb_y)
	FocusFrameSpellBar.SetPoint = function() end
end)
FocusFrameSpellBar:SetStatusBarColor(0,0.45,0.9); FocusFrameSpellBar.SetStatusBarColor = function() end

-- Target Castbar
hooksecurefunc(TargetFrameSpellBar, "Show", function()
	TargetFrameSpellBar:SetScale(config.tcb_scale)
	TargetFrameSpellBar:ClearAllPoints()
	TargetFrameSpellBarBorder:Hide()
	TargetFrameSpellBarText:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
	TargetFrameSpellBar:SetPoint("CENTER", UIParent, "CENTER", config.tcb_x, config.tcb_y)
	TargetFrameSpellBar.SetPoint = function() end
end)
