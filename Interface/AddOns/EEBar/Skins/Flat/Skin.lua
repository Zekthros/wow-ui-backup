local skin_name = "Flat"

_G["EEBAR_SKIN_" .. string.upper(skin_name)] = {
	apply_skin = function(enhanced_eclipse_bar)
		enhanced_eclipse_bar.frame:SetBackdrop({ bgFile = "Interface\\AddOns\\EEBar\\Skins\\" .. skin_name .. "\\FrameBorder.tga" });
		enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetStatusBarTexture("Interface\\AddOns\\EEBar\\Skins\\" .. skin_name .. "\\EclipseBarLunar.tga")
		enhanced_eclipse_bar.sb_eclipse_bar_solar:SetTexture("Interface\\AddOns\\EEBar\\Skins\\" .. skin_name .. "\\EclipseBarSolar.tga")
		enhanced_eclipse_bar.icon_lunar:SetBackdrop({ bgFile = "Interface\\AddOns\\EEBar\\Skins\\" .. skin_name .. "\\LunarEclipse.tga" });
		enhanced_eclipse_bar.icon_solar:SetBackdrop({ bgFile = "Interface\\AddOns\\EEBar\\Skins\\" .. skin_name .. "\\SolarEclipse.tga" });
		enhanced_eclipse_bar.icon_center_pin:SetBackdrop({ bgFile = "Interface\\AddOns\\EEBar\\Skins\\" .. skin_name .. "\\CenterPin.tga" });
		enhanced_eclipse_bar.icon_eclipse_arrow:SetBackdrop({ bgFile = "Interface\\AddOns\\EEBar\\Skins\\" .. skin_name .. "\\EclipseArrow.tga" });
		enhanced_eclipse_bar.background_empowerment:SetBackdrop({ bgFile = "Interface\\AddOns\\EEBar\\Skins\\" .. skin_name .. "\\FrameBorder.tga" });
		enhanced_eclipse_bar.sb_empowered_lunar:SetStatusBarTexture("Interface\\AddOns\\EEBar\\Skins\\" .. skin_name .. "\\EclipseBarLunar.tga");
		enhanced_eclipse_bar.sb_empowered_solar:SetStatusBarTexture("Interface\\AddOns\\EEBar\\Skins\\" .. skin_name .. "\\EclipseBarSolar.tga");
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
	end
};
