local skin_name = "Default"

_G["EEBAR_SKIN_" .. string.upper(skin_name)] = {
	apply_skin = function(enhanced_eclipse_bar)
		enhanced_eclipse_bar.frame:SetBackdrop({ bgFile = "Hurr-DURR.pnga6fd54af4asdf - asd" });
		enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
		enhanced_eclipse_bar.sb_eclipse_bar_solar:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
		enhanced_eclipse_bar.icon_lunar:SetBackdrop({ bgFile = "Interface\\Icons\\ability_druid_eclipse" });
		enhanced_eclipse_bar.icon_solar:SetBackdrop({ bgFile = "Interface\\Icons\\ability_druid_eclipseorange" });
		enhanced_eclipse_bar.icon_center_pin:SetBackdrop({ bgFile = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_6.blp" });
		enhanced_eclipse_bar.icon_eclipse_arrow:SetBackdrop({ bgFile = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_3.blp" });
		enhanced_eclipse_bar.background_empowerment:SetBackdrop({ bgFile = "Hurr-DURR.pnga6fd54af4asdf - asd" });
		enhanced_eclipse_bar.sb_empowered_lunar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar");
		enhanced_eclipse_bar.sb_empowered_solar:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar");
		
		enhanced_eclipse_bar.frame:SetBackdropColor(0.11, 0.07, 0.05, 1.00);
		enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetStatusBarColor(0.17, 0.30, 0.52);
		enhanced_eclipse_bar.sb_eclipse_bar_solar:SetVertexColor(0.59, 0.59, 0.00);
		enhanced_eclipse_bar.background_empowerment:SetBackdropColor(0.11, 0.07, 0.05, 1.00);
		enhanced_eclipse_bar.sb_empowered_lunar:SetStatusBarColor(0.17, 0.30, 0.52);
		enhanced_eclipse_bar.sb_empowered_solar:SetStatusBarColor(0.59, 0.59, 0.00);
	end,
	remove_skin = function(enhanced_eclipse_bar)
		enhanced_eclipse_bar.frame:SetBackdrop({ bgFile = nil });
		enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetStatusBarTexture(nil)
		enhanced_eclipse_bar.sb_eclipse_bar_solar:SetTexture(nil)
		enhanced_eclipse_bar.icon_lunar:SetBackdrop({ bgFile = nil });
		enhanced_eclipse_bar.icon_solar:SetBackdrop({ bgFile = nil });
		enhanced_eclipse_bar.icon_center_pin:SetBackdrop({ bgFile = nil });
		enhanced_eclipse_bar.icon_eclipse_arrow:SetBackdrop({ bgFile = nil });
		enhanced_eclipse_bar.background_empowerment:SetBackdrop({ bgFile = nil });
		enhanced_eclipse_bar.sb_empowered_lunar:SetStatusBarTexture(nil);
		enhanced_eclipse_bar.sb_empowered_solar:SetStatusBarTexture(nil);
	
		enhanced_eclipse_bar.frame:SetBackdropColor(1,1, 1, 1.00);
		enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetStatusBarColor(1, 1, 1);
		enhanced_eclipse_bar.sb_eclipse_bar_solar:SetVertexColor(1, 1, 1);
		enhanced_eclipse_bar.background_empowerment:SetBackdropColor(1, 1, 1, 1.00);
		enhanced_eclipse_bar.sb_empowered_lunar:SetStatusBarColor(1, 1, 1);
		enhanced_eclipse_bar.sb_empowered_solar:SetStatusBarColor(1, 1, 1);
	end
};
