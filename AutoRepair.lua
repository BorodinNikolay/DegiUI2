function arInit()
	frmautorepair:SetScript("Onevent", arevent);
	frmautorepair:RegisterEvent("MERCHANT_SHOW");
	frmautorepair:RegisterEvent("VARIABLES_LOADED");
end


local armode=2

function arevent(self, event)
	if armode==nil then
		armode=0;
	end

	if (event=="MERCHANT_SHOW" and CanMerchantRepair()==1) then
		repairAllCost, canRepair = GetRepairAllCost();
		if (canRepair==1) then
			if(armode<=1) then
				if( repairAllCost<=GetMoney() ) then
					RepairAllItems(0);
					DEFAULT_CHAT_FRAME:AddMessage("Your items have been repaired for "..GetCoinText(repairAllCost,", ")..".",255,255,0);
				else
					DEFAULT_CHAT_FRAME:AddMessage("You don't have enough money for repair!",255,0,0);
				end
			end

			if(armode==2 or armode==3)then
				RepairAllItems(1);
			end

			if(armode==2) then
				if( repairAllCost<=GetMoney() ) then
					RepairAllItems(0);
					DEFAULT_CHAT_FRAME:AddMessage("Стоимость починки: "..GetCoinTextureString(repairAllCost,", ")..".",255,255,255);
				else
					DEFAULT_CHAT_FRAME:AddMessage("Недостаточно денег для починки!",255,0,0);
				end
			end		
		end
	end
end
