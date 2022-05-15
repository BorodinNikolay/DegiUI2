
NiceDamage = CreateFrame("Frame", "NiceDamage");

local damagefont_FONT_NUMBER = "Interface\\AddOns\\DegiUI2\\Font\\font.ttf";

function NiceDamage:ApplySystemFonts()

DAMAGE_TEXT_FONT = damagefont_FONT_NUMBER;

end

NiceDamage:SetScript("OnEvent",
		    function() 
		       if (event == "ADDON_LOADED") then
			  NiceDamage:ApplySystemFonts()
		       end
		    end);
NiceDamage:RegisterEvent("ADDON_LOADED");

NiceDamage:ApplySystemFonts()

