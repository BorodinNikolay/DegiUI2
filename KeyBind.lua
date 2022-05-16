local function PVP() -- ТРУ если в пвп зоне. надо тестить
	return select(2,IsInInstance()) == "pvp" or select(2,IsInInstance()) == "arena"
end


local function OnEvent()
	local PVP = PVP()
	if PVP then
		SetBinding("TAB","TARGETNEARESTENEMYPLAYER")
	else
		SetBinding("TAB","TARGETNEARESTENEMY")
	end


end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", OnEvent)