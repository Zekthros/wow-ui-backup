-- [[ ===================== VARIABLES ===================== ]] --

local default_settings = {
	["font"] = { ["font"] = "Friz Quadrata", ["size"] = 16, ["flags"] = { ["OUTLINE"] = true } },
	["skin"] = "Default",
	["frame"] = { ["point"] = "CENTER", ["relativeTo"] = nil, ["relativePoint"] = "CENTER", ["xOfs"] = 0, ["yOfs"] = 0, 
				["width"] = 280, ["height"] = 35 },
	["hide_blizzard_eclipse_bar"] = true,
	["always_show_eclipse_bar"] = true,
	["only_show_in_combat"] = false
};

local media_list = {
	["fonts"] = {
		["Friz Quadrata"] = "Fonts\\FRIZQT__.TTF", 
		["Arial Narrow"] = "Fonts\\ARIALN.TTF",
		["Skurri"] = "Fonts\\skurri.ttf",
		["Morpheus"] = "Fonts\\MORPHEUS.ttf"
	},
	["skins"] = {
		["Default"] = "Default",
		["Flat"] = "Flat"
	},
	["fontflags"] = {
		["OUTLINE"] = "OUTLINE",
		["THICKOUTLINE"] = "THICKOUTLINE",
		["MONOCHROME"] = "MONOCHROME"
	}
};

local eclipse_break_point = 100;
local eclipse_arrow_offset = 6;
local time_since_last_update = 0;
local update_interval = 0.2;
local current_spec = nil;

-- Variables to ensure each event is only loaded once, and in the correct order to avoid data corruption.
local addon_unloaded = nil;
local player_entered_world = nil;
local addon_loaded = nil;

local frame_options_visible = nil;
local enhanced_eclipse_bar_options = {};
local frame_locked = true;
local enhanced_eclipse_bar = {};

local font = { ["font"] = default_settings["font"]["font"], ["size"] = default_settings["font"]["size"], 
			["flags"] = default_settings["font"]["flags"] };
local skin = default_settings["skin"];
local previous_skin = nil;

local lunar_peak = nil;
local solar_peak = nil;
local empowered_solar = nil;
local empowered_lunar = nil;
local empowered_solar_stacks = nil;
local empowered_lunar_stacks = nil;
local player_in_combat = nil;

local balance_spec = 102; -- Balance, using spec_id instead of name to prevent different names with multinational clients.
local addon_version = "1.0.7"

-- Variables used for re-sizing/moving anchored frames.
local frame_anchor_buffer = {
	["pre_move"] = { ["point"] = "", ["relativeTo"] = "", ["relativePoint"] = "", ["xOfs"] = 0, ["yOfs"] = 0 },
	["post_move"] = { ["point"] = "", ["relativeTo"] = "", ["relativePoint"] = "", ["xOfs"] = 0, ["yOfs"] = 0 }
}
local pre_resize_width, pre_resize_height = 0, 0;

-- [[ ===================== METHODS ===================== ]] --

local function MoveAnchoredFrameStart(self)
	
	frame_anchor_buffer["pre_move"]["point"], frame_anchor_buffer["pre_move"]["relativeTo"], frame_anchor_buffer["pre_move"]["relativePoint"], frame_anchor_buffer["pre_move"]["xOfs"], frame_anchor_buffer["pre_move"]["yOfs"] = self:GetPoint();
	self:StartMoving();
	frame_anchor_buffer["post_move"]["point"], frame_anchor_buffer["post_move"]["relativeTo"], frame_anchor_buffer["post_move"]["relativePoint"], frame_anchor_buffer["post_move"]["xOfs"], frame_anchor_buffer["post_move"]["yOfs"] = self:GetPoint();

end

local function MoveAnchoredFrameStop(self)

	local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint();
	self:StopMovingOrSizing();
	self:ClearAllPoints();
	self:SetPoint(frame_anchor_buffer["pre_move"]["point"], frame_anchor_buffer["pre_move"]["relativeTo"], frame_anchor_buffer["pre_move"]["relativePoint"], (frame_anchor_buffer["pre_move"]["xOfs"] + (xOfs - frame_anchor_buffer["post_move"]["xOfs"])), (frame_anchor_buffer["pre_move"]["yOfs"] + (yOfs - frame_anchor_buffer["post_move"]["yOfs"])));

end

local function ResizeAnchoredFrameStart(self, anchor)
	
	pre_resize_width, pre_resize_height = self:GetWidth(), self:GetHeight(); -- Fixes a bug where the frame goes awol on OnMouseUp/Down resize.
	frame_anchor_buffer["pre_move"]["point"], frame_anchor_buffer["pre_move"]["relativeTo"], frame_anchor_buffer["pre_move"]["relativePoint"], frame_anchor_buffer["pre_move"]["xOfs"], frame_anchor_buffer["pre_move"]["yOfs"] = self:GetPoint();
	self:StartSizing(anchor);
	frame_anchor_buffer["post_move"]["point"], frame_anchor_buffer["post_move"]["relativeTo"], frame_anchor_buffer["post_move"]["relativePoint"], frame_anchor_buffer["post_move"]["xOfs"], frame_anchor_buffer["post_move"]["yOfs"] = self:GetPoint();
	self:SetWidth(pre_resize_width); self:SetHeight(pre_resize_height);
	
end

local function ResizeAnchoredFrameStop(self)

	local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint();
	self:StopMovingOrSizing();
	local width, height = self:GetWidth(), self:GetHeight();
	self:ClearAllPoints();
	self:SetPoint(frame_anchor_buffer["pre_move"]["point"], frame_anchor_buffer["pre_move"]["relativeTo"], frame_anchor_buffer["pre_move"]["relativePoint"], (frame_anchor_buffer["pre_move"]["xOfs"] + (xOfs - frame_anchor_buffer["post_move"]["xOfs"])) + ((width - pre_resize_width)/2), (frame_anchor_buffer["pre_move"]["yOfs"] + (yOfs - frame_anchor_buffer["post_move"]["yOfs"]) - ((height - pre_resize_height)/2)));
	
end

local function ChatAnnounce(message)

	print(format("|cff00ffffEEBar:|r |cffffff00%s|r", message));

end

local function AnchorEclipseBar(frame)

	local point, relativeTo, relativePoint, xOfs, yOfs = enhanced_eclipse_bar.frame:GetPoint();
	
	enhanced_eclipse_bar.frame:ClearAllPoints();
	
	if(not pcall(function()
	
		enhanced_eclipse_bar.frame:SetPoint(default_settings["frame"]["point"], frame, default_settings["frame"]["relativePoint"],
				0, 0);
	
	end)) then
	
		enhanced_eclipse_bar.frame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs);
		ChatAnnounce(format("Failed to attach the eclipse bar to the frame '%s'.", tostring(frame or "<nil>")))
	
	end

end

local function ResetEclipseBarPosition()

	enhanced_eclipse_bar.frame:ClearAllPoints();
	enhanced_eclipse_bar.frame:SetPoint(default_settings["frame"]["point"], default_settings["frame"]["relativeTo"], 
				default_settings["frame"]["relativePoint"], default_settings["frame"]["xOfs"], default_settings["frame"]["yOfs"]);

end

local function ResetEclipseBarSize()

	enhanced_eclipse_bar.frame:SetWidth(default_settings["frame"]["width"]);
	enhanced_eclipse_bar.frame:SetHeight(default_settings["frame"]["height"]);

end

local function SetFontSizeFlags(new_font)

	local new_font_flags = "";
	
	for k, v in pairs(media_list["fontflags"]) do
		
		if(font["flags"][k]) then
		
			new_font_flags = format("%s%s, ", new_font_flags, k);
			
		end
	
	end
	
	if(string.len(new_font_flags) >= 3) then
		new_font_flags = string.sub(new_font_flags, 1, -3);
	end

	enhanced_eclipse_bar.fs_lunar_peak:SetFont(media_list["fonts"][new_font["font"]], new_font["size"], new_font_flags);
	enhanced_eclipse_bar.fs_solar_peak:SetFont(media_list["fonts"][new_font["font"]], new_font["size"], new_font_flags);
	enhanced_eclipse_bar.fs_eclipse_power:SetFont(media_list["fonts"][new_font["font"]], new_font["size"], new_font_flags);

end

local function CalculateEclipseBreakPoint()

	local mastery = GetMasteryEffect() or 0.00;
	
	local wrath_dps = (0 + ((GetSpellBonusDamage(4) or 0.00) * 1.300)) / (max(((select(4, GetSpellInfo(5176)) / 1000) or 0.0), 1.0) or 1.0);
	local starfire_dps = (0 + ((GetSpellBonusDamage(7) or 0.00) * 2.080)) / (max(((select(4, GetSpellInfo(2912)) / 1000) or 0.0), 1.0) or 1.0);
	
	local break_point = (200 * ((starfire_dps * mastery) - wrath_dps + starfire_dps)) / (mastery * (starfire_dps + wrath_dps));
	
	return math.min(200, math.max(0, break_point));

end

local function LoadSkin(name)
	
	if(previous_skin) then _G["EEBAR_SKIN_" .. string.upper(previous_skin)].remove_skin(enhanced_eclipse_bar); end
	_G["EEBAR_SKIN_" .. string.upper(name)].apply_skin(enhanced_eclipse_bar);
	
	previous_skin = name;

end

local function AddOnLoad()

	if(not pcall(function() enhanced_eclipse_bar.frame:ClearAllPoints(); enhanced_eclipse_bar.frame:SetPoint(default_settings["frame"]["point"], EEBarDB["enhanced_eclipse_bar"]["frame"]["relativeTo"], EEBarDB["enhanced_eclipse_bar"]["frame"]["relativePoint"], EEBarDB["enhanced_eclipse_bar"]["frame"]["xOfs"], EEBarDB["enhanced_eclipse_bar"]["frame"]["yOfs"]); end)) then
			
		ResetEclipseBarPosition();
			
	end
		
	if(not pcall(function() enhanced_eclipse_bar.frame:SetWidth(EEBarDB["enhanced_eclipse_bar"]["frame"]["width"]); end)) then
		
		enhanced_eclipse_bar.frame:SetWidth(default_settings["frame"]["width"]);
		
	end
		
	if(not pcall(function() enhanced_eclipse_bar.frame:SetHeight(EEBarDB["enhanced_eclipse_bar"]["frame"]["height"]); end)) then
		
		enhanced_eclipse_bar.frame:SetHeight(default_settings["frame"]["height"]);
		
	end
		
	if(not pcall(function() skin = EEBarDB["enhanced_eclipse_bar"]["skin"]; UIDropDownMenu_SetText(enhanced_eclipse_bar_options.btn_skin_drop_down_list, skin); LoadSkin(skin); end)) then
		
		skin = default_settings["skin"];
		UIDropDownMenu_SetText(enhanced_eclipse_bar_options.btn_skin_drop_down_list, skin)
		LoadSkin(skin);
		
	end
		
	if(not pcall(function() enhanced_eclipse_bar_options.cb_hide_blizzard_eclipse_bar:SetChecked(EEBarDB["enhanced_eclipse_bar"]["hide_blizzard_eclipse_bar"]);  end)) then
		
		enhanced_eclipse_bar_options.cb_hide_blizzard_eclipse_bar:SetChecked(default_settings["hide_blizzard_eclipse_bar"]);
		
	end
		
	if(not pcall(function() enhanced_eclipse_bar_options.cb_always_show_eclipse_bar:SetChecked(EEBarDB["enhanced_eclipse_bar"]["always_show_eclipse_bar"]);  end)) then
		
		enhanced_eclipse_bar_options.cb_always_show_eclipse_bar:SetChecked(default_settings["always_show_eclipse_bar"]);
		
	end
	
	if(not pcall(function() enhanced_eclipse_bar_options.cb_only_show_in_combat:SetChecked(EEBarDB["enhanced_eclipse_bar"]["only_show_in_combat"]);  end)) then
		
		enhanced_eclipse_bar_options.cb_only_show_in_combat:SetChecked(default_settings["only_show_in_combat"]);
		
	end
		
	if(not pcall(function()
			font["font"] = EEBarDB["enhanced_eclipse_bar"]["font"]["font"];
			font["size"] = EEBarDB["enhanced_eclipse_bar"]["font"]["size"];
			enhanced_eclipse_bar_options.eb_font_size:SetNumber(font["size"]);
			font["flags"] = EEBarDB["enhanced_eclipse_bar"]["font"]["flags"];
			if(type(font["flags"]) ~= "table") then font["flags"] = default_settings["font"]["flags"]; end -- Fixes a bug in a previous build where this was a string field and not a table.
			SetFontSizeFlags(font);
		end)) then
			
		font = { ["font"] = default_settings["font"]["font"], ["size"] = default_settings["font"]["size"], 
			["flags"] = default_settings["font"]["flags"] };
		enhanced_eclipse_bar_options.eb_font_size:SetNumber(font["size"]);
		SetFontSizeFlags(font);
			
	end

end

local function AddOnUnload()

	EEBarDB = {};

	EEBarDB["enhanced_eclipse_bar"] = {};
	EEBarDB["enhanced_eclipse_bar"]["frame"] = {};
	local point, relativeTo, relativePoint, xOfs, yOfs = enhanced_eclipse_bar.frame:GetPoint();
	pcall(function() relativeTo = relativeTo:GetName(); end); -- Not sure if optimized, but it works.
	EEBarDB["enhanced_eclipse_bar"]["frame"]["point"], EEBarDB["enhanced_eclipse_bar"]["frame"]["relativeTo"], EEBarDB["enhanced_eclipse_bar"]["frame"]["relativePoint"], EEBarDB["enhanced_eclipse_bar"]["frame"]["xOfs"], EEBarDB["enhanced_eclipse_bar"]["frame"]["yOfs"] = point, relativeTo, relativePoint, xOfs, yOfs;
	EEBarDB["enhanced_eclipse_bar"]["frame"]["width"] = enhanced_eclipse_bar.frame:GetWidth();
	EEBarDB["enhanced_eclipse_bar"]["frame"]["height"] = enhanced_eclipse_bar.frame:GetHeight();
	EEBarDB["enhanced_eclipse_bar"]["font"] = {};
	EEBarDB["enhanced_eclipse_bar"]["font"]["font"] = font["font"];
	EEBarDB["enhanced_eclipse_bar"]["font"]["size"] = font["size"];
	EEBarDB["enhanced_eclipse_bar"]["font"]["flags"] = font["flags"];
	EEBarDB["enhanced_eclipse_bar"]["skin"] = skin;
	EEBarDB["enhanced_eclipse_bar"]["hide_blizzard_eclipse_bar"] = enhanced_eclipse_bar_options.cb_hide_blizzard_eclipse_bar:GetChecked();
	EEBarDB["enhanced_eclipse_bar"]["always_show_eclipse_bar"] = enhanced_eclipse_bar_options.cb_always_show_eclipse_bar:GetChecked();
	EEBarDB["enhanced_eclipse_bar"]["only_show_in_combat"] = enhanced_eclipse_bar_options.cb_only_show_in_combat:GetChecked();
	
end

local function HideFrame()

	if(enhanced_eclipse_bar.frame:IsVisible()) then

		enhanced_eclipse_bar.frame:Hide();
	
	end

end

local function ShowFrame()

	if(not enhanced_eclipse_bar.frame:IsVisible()) then
	
		enhanced_eclipse_bar.frame:Show();
		
	end

end

function LockFrame()

	if(not frame_locked) then

		enhanced_eclipse_bar.frame:RegisterForDrag();
		enhanced_eclipse_bar.frame:SetMovable(false);
		enhanced_eclipse_bar.frame:EnableMouse(false);
		enhanced_eclipse_bar.frame:SetResizable(false);
		enhanced_eclipse_bar.frame:SetFrameStrata("MEDIUM");
		
		enhanced_eclipse_bar.sb_eclipse_bar_lunar:Show();
		enhanced_eclipse_bar.sb_eclipse_bar_solar:Show();
		enhanced_eclipse_bar.icon_center_pin:Show();
		enhanced_eclipse_bar.icon_lunar:Show();
		enhanced_eclipse_bar.icon_solar:Show();
		enhanced_eclipse_bar.icon_eclipse_arrow:Show();
		
		enhanced_eclipse_bar.icon_drag_handle:Hide();
		
		frame_locked = true;
	
	end

end

function UnlockFrame()

	if(frame_locked) then

		enhanced_eclipse_bar.frame:RegisterForDrag("LeftButton");
		enhanced_eclipse_bar.frame:SetMovable(true);
		enhanced_eclipse_bar.frame:EnableMouse(true);
		enhanced_eclipse_bar.frame:SetResizable(true);
		enhanced_eclipse_bar.frame:SetFrameStrata("HIGH");
		
		enhanced_eclipse_bar.sb_eclipse_bar_lunar:Hide();
		enhanced_eclipse_bar.sb_eclipse_bar_solar:Hide();
		enhanced_eclipse_bar.icon_center_pin:Hide();
		enhanced_eclipse_bar.icon_lunar:Hide();
		enhanced_eclipse_bar.icon_solar:Hide();
		enhanced_eclipse_bar.icon_eclipse_arrow:Hide();
		
		enhanced_eclipse_bar.icon_drag_handle:Show();
		
		frame_locked = false;
	
	end

end

local function ToggleOptionsFrame()

	if(not frame_options_visible) then
	
		enhanced_eclipse_bar_options.frame:ClearAllPoints();
		enhanced_eclipse_bar_options.frame:SetPoint("CENTER", nil, "CENTER", 0, 0);
		enhanced_eclipse_bar_options.frame:Show();
	
		frame_options_visible = true;
	
	else
	
		enhanced_eclipse_bar_options.frame:Hide();
	
		frame_options_visible = nil;
	
	end

end

local function CheckSpecialization()

	local specialization = GetSpecialization();
	if(specialization) then current_spec = GetSpecializationInfo(specialization) else current_spec = nil; end

	if(current_spec == balance_spec) then
		
		ShowFrame();
			
	else
		
		HideFrame();
		
	end

end

local function CombatLogEventUnfiltered(...)

	local timestamp, event, hide_caster, source_guid, source_name, source_flags, source_flags2, dest_guid, dest_name, dest_flags, dest_flags2, spell_id, spell_name = ...;
	
	if(source_name == UnitName("player")) then

		if(event == "SPELL_AURA_APPLIED") then -- or event == "SPELL_AURA_REFRESHED") then
		
			if(spell_id == 171743) then -- Lunar Peak
			
				lunar_peak = GetTime() + 5;
				ActionButton_ShowOverlayGlow(enhanced_eclipse_bar.icon_lunar);
				
			elseif(spell_id == 171744) then -- Solar Peak
				
				solar_peak = GetTime() + 5;
				ActionButton_ShowOverlayGlow(enhanced_eclipse_bar.icon_solar);
			
			elseif(spell_id == 164547) then -- Lunar Empowerment
			
				empowered_lunar = GetTime() + 30;
				empowered_lunar_stacks = 2;
			
			elseif(spell_id == 164545) then -- Solar Empowerment
		
				empowered_solar = GetTime() + 30;
				empowered_solar_stacks = 3;
		
			end
				
		elseif(event == "SPELL_AURA_REMOVED") then
			
			if(spell_id == 171743) then -- Lunar Peak
				
				lunar_peak = nil;
				ActionButton_HideOverlayGlow(enhanced_eclipse_bar.icon_lunar);
				
			elseif(spell_id == 171744) then -- Solar Peak
				
				solar_peak = nil;
				ActionButton_HideOverlayGlow(enhanced_eclipse_bar.icon_solar);
				
			elseif(spell_id == 164547) then -- Lunar Empowerment
			
				empowered_lunar = nil;
				empowered_lunar_stacks = nil;
			
			elseif(spell_id == 164545) then -- Solar Empowerment
		
				empowered_solar = nil;
				empowered_solar_stacks = nil;
		
			end
			
		elseif(event == "SPELL_CAST_SUCCESS") then
			
			if(spell_id == 5176) then -- Wrath
				
				if(empowered_solar_stacks) then 
					empowered_solar_stacks = empowered_solar_stacks - 1;
					if(empowered_solar_stacks < 1) then empowered_solar_stacks = nil; empowered_solar = nil; end
				end
			
			elseif(spell_id == 2912) then -- Starfire
			
				if(empowered_lunar_stacks) then 
					empowered_lunar_stacks = empowered_lunar_stacks - 1;
					if(empowered_lunar_stacks < 1) then empowered_lunar_stacks = nil; empowered_lunar = nil; end
				end
		
			end
			
		end
		
	end

end

local function ToggleFontFontFlag(...)

	local new_flag = select(2, ...);

	UIDropDownMenu_SetText(enhanced_eclipse_bar_options.btn_fontflags_drop_down_list, new_flag)
	if(not font["flags"][new_flag]) then
		font["flags"][new_flag] = true;
	else
		font["flags"][new_flag] = nil;
	end
	SetFontSizeFlags(font);

	CloseDropDownMenus()
	
end

local function SetFontSize(new_size)

	font["size"] = new_size;
	SetFontSizeFlags(font);

end

local function SetFontFont(...)
	local new_font = select(2, ...);

	UIDropDownMenu_SetText(enhanced_eclipse_bar_options.btn_font_drop_down_list, new_font)
	font["font"] = new_font;
	SetFontSizeFlags(font);

	CloseDropDownMenus()
end

local function SetSkin(...)
	local new_skin = select(2, ...);

	skin = new_skin;
	UIDropDownMenu_SetText(enhanced_eclipse_bar_options.btn_skin_drop_down_list, skin)
	LoadSkin(media_list["skins"][skin]);

	CloseDropDownMenus()
end

local function UpdateFrameVisibility(form)

	if(current_spec == balance_spec) then
	
		if(enhanced_eclipse_bar_options.cb_hide_blizzard_eclipse_bar:GetChecked()) then
		
			EclipseBarFrame:Hide();
		
		end
		
		if(enhanced_eclipse_bar_options.cb_only_show_in_combat:GetChecked() and not player_in_combat) then
		
			HideFrame();
			return;
		
		end

		if((form == nil or form == MOONKIN_FORM) or enhanced_eclipse_bar_options.cb_always_show_eclipse_bar:GetChecked()) then
		
			ShowFrame();
		
		elseif(not enhanced_eclipse_bar_options.cb_always_show_eclipse_bar:GetChecked()) then
		
			HideFrame();
		
		end
	
	end

end

-- [[ ===================== CONTROL EVENTS ===================== ]] --

function enhanced_eclipse_bar:OnSizeChanged(self, width, height)

	local icon_bar_height = height - 4; -- -8
	local bar_width = width - (icon_bar_height * 2) - 12; -- -16

	enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetWidth(bar_width);
	enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetHeight(icon_bar_height - 6);
	
	enhanced_eclipse_bar.icon_lunar:SetWidth(icon_bar_height);
	enhanced_eclipse_bar.icon_lunar:SetHeight(icon_bar_height);
	enhanced_eclipse_bar.icon_lunar:SetPoint("CENTER", enhanced_eclipse_bar.frame, "CENTER", ((bar_width / 2) + (icon_bar_height / 2) + 4) * -1, 0);
	
	enhanced_eclipse_bar.icon_solar:SetWidth(icon_bar_height);
	enhanced_eclipse_bar.icon_solar:SetHeight(icon_bar_height);
	enhanced_eclipse_bar.icon_solar:SetPoint("CENTER", enhanced_eclipse_bar.frame, "CENTER", ((bar_width / 2) + (icon_bar_height / 2) + 4), 0);
	
	enhanced_eclipse_bar.icon_center_pin:SetWidth(4);
	enhanced_eclipse_bar.icon_center_pin:SetHeight(icon_bar_height - 6);
	
	enhanced_eclipse_bar.icon_eclipse_arrow:SetWidth(icon_bar_height - 10);
	enhanced_eclipse_bar.icon_eclipse_arrow:SetHeight(icon_bar_height - 10);
	
	enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetMinMaxValues(0, bar_width);
	
	enhanced_eclipse_bar.background_empowerment:SetWidth(width);
	
	enhanced_eclipse_bar.sb_empowered_lunar:SetWidth((width / 2) - 16);
	enhanced_eclipse_bar.sb_empowered_solar:SetWidth((width / 2) - 16);
	
end

function enhanced_eclipse_bar:OnUpdate(self, elapsed)

	local power = UnitPower("player" , SPELL_POWER_ECLIPSE) or 100;

	enhanced_eclipse_bar.icon_eclipse_arrow:SetPoint("CENTER", enhanced_eclipse_bar.icon_center_pin, "CENTER", ((enhanced_eclipse_bar.sb_eclipse_bar_lunar:GetWidth() / 2) - eclipse_arrow_offset) * (power / 100), 0)

	time_since_last_update = time_since_last_update + elapsed;
	
	if (time_since_last_update >= update_interval) then
		
		eclipse_break_point = CalculateEclipseBreakPoint();
		
		enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetValue(((select(2, enhanced_eclipse_bar.sb_eclipse_bar_lunar:GetMinMaxValues()) - (eclipse_arrow_offset * 2)) * (eclipse_break_point / 200)) + eclipse_arrow_offset);
		
		time_since_last_update = time_since_last_update - update_interval;
    
	end
	
	if(lunar_peak) then
	
		enhanced_eclipse_bar.fs_lunar_peak:SetText(format("%.0f", max(0, (lunar_peak or GetTime()) - GetTime())));
		
		if(not enhanced_eclipse_bar.fs_lunar_peak:IsVisible()) then enhanced_eclipse_bar.fs_lunar_peak:Show(); end
	
	elseif(enhanced_eclipse_bar.fs_lunar_peak:IsVisible()) then
	
		enhanced_eclipse_bar.fs_lunar_peak:Hide();
	
	end
	
	if(solar_peak) then
	
		enhanced_eclipse_bar.fs_solar_peak:SetText(format("%.0f", max(0, (solar_peak or GetTime()) - GetTime())));
		
		if(not enhanced_eclipse_bar.fs_solar_peak:IsVisible()) then enhanced_eclipse_bar.fs_solar_peak:Show(); end
	
	elseif(enhanced_eclipse_bar.fs_solar_peak:IsVisible()) then
	
		enhanced_eclipse_bar.fs_solar_peak:Hide();
	
	end
	
	if(power < 0) then power = power * -1; end
	
	enhanced_eclipse_bar.fs_eclipse_power:SetText(power);
	enhanced_eclipse_bar.fs_eclipse_power:SetAlpha(((power / 100) * 0.8) + 0.2)
	
	enhanced_eclipse_bar.sb_empowered_lunar:SetMinMaxValues(0, 30);
	enhanced_eclipse_bar.sb_empowered_lunar:SetValue(max(0, (empowered_lunar or 0) - GetTime()));
	enhanced_eclipse_bar_options.fs_empowered_lunar:SetText(string.format("|cff00ffff%s|r", (empowered_lunar_stacks or "")));
	
	enhanced_eclipse_bar.sb_empowered_solar:SetMinMaxValues(0, 30);
	enhanced_eclipse_bar.sb_empowered_solar:SetValue(max(0,(empowered_solar or 0) - GetTime()));
	enhanced_eclipse_bar_options.fs_empowered_solar:SetText(string.format("|cff00ffff%s|r", (empowered_solar_stacks or "")));
	
end

function enhanced_eclipse_bar:OnEvent(self, event, ...)
	
	if(event == "COMBAT_LOG_EVENT_UNFILTERED") then
		
		CombatLogEventUnfiltered(...);

	elseif(event == "PLAYER_ENTERING_WORLD") then
	
		if(not player_entered_world) then
		
			CheckSpecialization();
			UpdateFrameVisibility(GetShapeshiftFormID());
			player_entered_world = true;
		
		end
	
	elseif(event == "ACTIVE_TALENT_GROUP_CHANGED") then
	
		CheckSpecialization();
	
	elseif(event == "ADDON_LOADED" and not addon_loaded) then
	
		AddOnLoad();
		UpdateFrameVisibility(GetShapeshiftFormID());
		addon_loaded = true;
	
	elseif(event == "PLAYER_LOGOUT" and not addon_unloaded and addon_loaded) then
	
		AddOnUnload();
		addon_unloaded = true;
		
	elseif(event == "UPDATE_SHAPESHIFT_FORM") then
	
		UpdateFrameVisibility(GetShapeshiftFormID());
		
	elseif(event == "PLAYER_REGEN_DISABLED") then
		
		player_in_combat = true;
		UpdateFrameVisibility(GetShapeshiftFormID());
	
	elseif(event == "PLAYER_REGEN_ENABLED") then
	
		player_in_combat = nil;
		UpdateFrameVisibility(GetShapeshiftFormID());
	
	end
	
end

function SlashHandler(input)

	local lower_input = string.lower(input)
	
	if(lower_input == "show") then
	
		ShowFrame();
	
	elseif(lower_input == "hide") then
	
		HideFrame();
		
	elseif(lower_input == "lock") then
	
		LockFrame();
		
	elseif(lower_input == "unlock") then
	
		UnlockFrame();
		
	elseif(lower_input == "conf" or lower_input == "config") then
	
		ToggleOptionsFrame();
		
	elseif(lower_input == "help") then
	
		ChatAnnounce("lock/unlock - resize or move the bar.");
		ChatAnnounce("hide/show - hide or show the bar.");
		ChatAnnounce("conf/config - toggle the configuration frame.");
	
	end

end

-- [[ ===================== ADDON INITIALIZATION ===================== ]] --

local function InitializeComponents()
	
	-- Don't bother to load anything if the player is not a druid.
	if(select(2, UnitClass("player")) ~= "DRUID") then return; end
	
	-- Eclipse bar frame.
	enhanced_eclipse_bar.frame = CreateFrame("Frame", nil, UIParent);
	enhanced_eclipse_bar.frame:SetBackdrop({ bgFile = nil });
	enhanced_eclipse_bar.frame:SetMinResize(16, 16);
	enhanced_eclipse_bar.frame:SetScript("OnEvent", function(self, event, ...) enhanced_eclipse_bar:OnEvent(self, event, ...); end);
	enhanced_eclipse_bar.frame:SetScript("OnMouseDown", function(self, button) if(button == "LeftButton" and not frame_locked) then MoveAnchoredFrameStart(self); end end);
	enhanced_eclipse_bar.frame:SetScript("OnMouseUp", function(self, button) if(button == "LeftButton" and not frame_locked) then MoveAnchoredFrameStop(self); end end);
	enhanced_eclipse_bar.frame:SetScript("OnSizeChanged", function(self, width, height) enhanced_eclipse_bar:OnSizeChanged(self, width, height); end);
	enhanced_eclipse_bar.frame:SetFrameStrata("MEDIUM");
	
	enhanced_eclipse_bar.icon_drag_handle = CreateFrame("Frame", nil, enhanced_eclipse_bar.frame);
	enhanced_eclipse_bar.icon_drag_handle:SetBackdrop({ bgFile = "Interface\\AddOns\\EEBar\\Textures\\DragHandle.tga" });
	enhanced_eclipse_bar.icon_drag_handle:SetPoint("BOTTOMRIGHT", 0, 0);
	enhanced_eclipse_bar.icon_drag_handle:SetWidth(16);
	enhanced_eclipse_bar.icon_drag_handle:SetHeight(16);
	enhanced_eclipse_bar.icon_drag_handle:SetScript("OnMouseDown", function() if(not frame_locked) then ResizeAnchoredFrameStart(enhanced_eclipse_bar.frame, "BOTTOMRIGHT"); end end);
	enhanced_eclipse_bar.icon_drag_handle:SetScript("OnMouseUp", function() if(not frame_locked) then ResizeAnchoredFrameStop(enhanced_eclipse_bar.frame); end end);
	enhanced_eclipse_bar.icon_drag_handle:Hide();
	
	enhanced_eclipse_bar.sb_eclipse_bar_lunar = CreateFrame("StatusBar", nil, enhanced_eclipse_bar.frame);
	enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetPoint("CENTER", enhanced_eclipse_bar.frame, "CENTER", 0, 0);
	enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetStatusBarTexture(nil);
	enhanced_eclipse_bar.sb_eclipse_bar_solar = enhanced_eclipse_bar.sb_eclipse_bar_lunar:CreateTexture(nil, "BACKGROUND");
	enhanced_eclipse_bar.sb_eclipse_bar_solar:SetTexture(nil);
	enhanced_eclipse_bar.sb_eclipse_bar_solar:SetAllPoints();
	enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetMinMaxValues(0, 200);
	enhanced_eclipse_bar.sb_eclipse_bar_lunar:SetValue(135);
	
	enhanced_eclipse_bar.icon_lunar = CreateFrame("Frame", nil, enhanced_eclipse_bar.frame);
	enhanced_eclipse_bar.icon_lunar:SetBackdrop({ bgFile = nil });
	
	enhanced_eclipse_bar.icon_solar = CreateFrame("Frame", nil, enhanced_eclipse_bar.frame);
	enhanced_eclipse_bar.icon_solar:SetBackdrop({ bgFile = nil });
	
	enhanced_eclipse_bar.icon_center_pin = CreateFrame("Frame", nil, enhanced_eclipse_bar.sb_eclipse_bar_lunar);
	enhanced_eclipse_bar.icon_center_pin:SetBackdrop({ bgFile = nil });
	enhanced_eclipse_bar.icon_center_pin:SetPoint("CENTER", enhanced_eclipse_bar.sb_eclipse_bar_lunar, "CENTER", 0, 0);
	
	enhanced_eclipse_bar.icon_eclipse_arrow = CreateFrame("Frame", nil, enhanced_eclipse_bar.icon_center_pin);
	enhanced_eclipse_bar.icon_eclipse_arrow:SetBackdrop({ bgFile = nil });
	
	enhanced_eclipse_bar.fs_lunar_peak = enhanced_eclipse_bar.icon_lunar:CreateFontString();
	enhanced_eclipse_bar.fs_lunar_peak:SetFont(media_list["fonts"][font["font"]], font["size"], font["flags"]);
	enhanced_eclipse_bar.fs_lunar_peak:SetPoint("CENTER", 0, 0);
	
	enhanced_eclipse_bar.fs_solar_peak = enhanced_eclipse_bar.icon_solar:CreateFontString();
	enhanced_eclipse_bar.fs_solar_peak:SetFont(media_list["fonts"][font["font"]], font["size"], font["flags"]);
	enhanced_eclipse_bar.fs_solar_peak:SetPoint("CENTER", 0, 0);
	
	enhanced_eclipse_bar.fs_eclipse_power = enhanced_eclipse_bar.icon_center_pin:CreateFontString();
	enhanced_eclipse_bar.fs_eclipse_power:SetFont(media_list["fonts"][font["font"]], font["size"], font["flags"]);
	enhanced_eclipse_bar.fs_eclipse_power:SetPoint("CENTER", 0, 0);
	
	enhanced_eclipse_bar.background_empowerment = CreateFrame("Frame", nil, enhanced_eclipse_bar.frame);
	enhanced_eclipse_bar.background_empowerment:SetBackdrop({ bgFile = nil });
	enhanced_eclipse_bar.background_empowerment:SetPoint("BOTTOM", enhanced_eclipse_bar.frame, "TOP", 0, 0);
	enhanced_eclipse_bar.background_empowerment:SetHeight(16);
	
	enhanced_eclipse_bar.icon_empowerment_lunar = CreateFrame("Frame", nil, enhanced_eclipse_bar.background_empowerment);
	enhanced_eclipse_bar.icon_empowerment_lunar:SetBackdrop({ bgFile = "Interface\\Icons\\spell_arcane_starfire" });
	enhanced_eclipse_bar.icon_empowerment_lunar:SetWidth(14);
	enhanced_eclipse_bar.icon_empowerment_lunar:SetHeight(14);
	enhanced_eclipse_bar.icon_empowerment_lunar:SetPoint("LEFT", enhanced_eclipse_bar.background_empowerment, "LEFT", 1, 0);
	
	enhanced_eclipse_bar.icon_empowerment_solar = CreateFrame("Frame", nil, enhanced_eclipse_bar.background_empowerment);
	enhanced_eclipse_bar.icon_empowerment_solar:SetBackdrop({ bgFile = "Interface\\Icons\\spell_nature_wrathv2" });
	enhanced_eclipse_bar.icon_empowerment_solar:SetWidth(14);
	enhanced_eclipse_bar.icon_empowerment_solar:SetHeight(14);
	enhanced_eclipse_bar.icon_empowerment_solar:SetPoint("RIGHT", enhanced_eclipse_bar.background_empowerment, "RIGHT", -1, 0);
	
	enhanced_eclipse_bar.sb_empowered_lunar = CreateFrame("StatusBar", nil, enhanced_eclipse_bar.background_empowerment);
	enhanced_eclipse_bar.sb_empowered_lunar:SetPoint("RIGHT", enhanced_eclipse_bar.background_empowerment, "CENTER", -1, 0);
	enhanced_eclipse_bar.sb_empowered_lunar:SetStatusBarTexture(nil);
	enhanced_eclipse_bar.sb_empowered_lunar:SetMinMaxValues(0, 200);
	enhanced_eclipse_bar.sb_empowered_lunar:SetHeight(10);
	
	enhanced_eclipse_bar_options.fs_empowered_lunar = enhanced_eclipse_bar.icon_empowerment_lunar:CreateFontString();
	enhanced_eclipse_bar_options.fs_empowered_lunar:SetFont("Fonts\\FRIZQT__.TTF", 14, "THICKOUTLINE");
	enhanced_eclipse_bar_options.fs_empowered_lunar:SetPoint("CENTER", 0, 0);
	
	enhanced_eclipse_bar.sb_empowered_solar = CreateFrame("StatusBar", nil, enhanced_eclipse_bar.background_empowerment);
	enhanced_eclipse_bar.sb_empowered_solar:SetPoint("LEFT", enhanced_eclipse_bar.background_empowerment, "CENTER", 1, 0);
	enhanced_eclipse_bar.sb_empowered_solar:SetStatusBarTexture(nil);
	enhanced_eclipse_bar.sb_empowered_solar:SetMinMaxValues(0, 200);
	enhanced_eclipse_bar.sb_empowered_solar:SetValue(100);
	enhanced_eclipse_bar.sb_empowered_solar:SetHeight(10);
	enhanced_eclipse_bar.sb_empowered_solar:SetReverseFill(true)
	
	enhanced_eclipse_bar_options.fs_empowered_solar = enhanced_eclipse_bar.icon_empowerment_solar:CreateFontString();
	enhanced_eclipse_bar_options.fs_empowered_solar:SetFont("Fonts\\FRIZQT__.TTF", 14, "THICKOUTLINE");
	enhanced_eclipse_bar_options.fs_empowered_solar:SetPoint("CENTER", 0, 0);
	
	LoadSkin("Default");
	
	enhanced_eclipse_bar.sb_eclipse_bar_lunar:GetStatusBarTexture():SetHorizTile(false);
	enhanced_eclipse_bar.sb_eclipse_bar_lunar:GetStatusBarTexture():SetVertTile(false);
	
	-- Options frame
	enhanced_eclipse_bar_options.frame = CreateFrame("Frame", nil, UIParent);
	enhanced_eclipse_bar_options.frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = nil,
	tileSize = 0,
	edgeSize = 14,
	insets = { left = 3, right = 3, top = 3, bottom = 3 }});
	enhanced_eclipse_bar_options.frame:SetPoint("CENTER", nil, "CENTER", 0, 0);
	enhanced_eclipse_bar_options.frame:SetWidth(280);
	enhanced_eclipse_bar_options.frame:SetHeight(365);
	enhanced_eclipse_bar_options.frame:RegisterForDrag("LeftButton");
	enhanced_eclipse_bar_options.frame:SetMovable(true);
	enhanced_eclipse_bar_options.frame:EnableMouse(true);
	enhanced_eclipse_bar_options.frame:SetResizable(true);
	enhanced_eclipse_bar_options.frame:SetScript("OnMouseDown", function(self, button) if(button ~= "LeftButton") then return; end self:StartMoving(); end);
	enhanced_eclipse_bar_options.frame:SetScript("OnMouseUp", function(self, button) if(button ~= "LeftButton") then return; end self:StopMovingOrSizing(); end);
	enhanced_eclipse_bar_options.frame:SetFrameStrata("HIGH");
	enhanced_eclipse_bar_options.frame:Hide();
	
	enhanced_eclipse_bar_options.frame.fs_eebar = enhanced_eclipse_bar_options.frame:CreateFontString();
	enhanced_eclipse_bar_options.frame.fs_eebar:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE");
	enhanced_eclipse_bar_options.frame.fs_eebar:SetPoint("TOP", 0, -5);
	enhanced_eclipse_bar_options.frame.fs_eebar:SetText("Enhanced Eclipse Bar (" .. addon_version .. ")");
	
	enhanced_eclipse_bar_options.btn_close_frame = CreateFrame("Button", nil, enhanced_eclipse_bar_options.frame, "UIPanelCloseButton");
	enhanced_eclipse_bar_options.btn_close_frame:SetPoint("TOPRIGHT", -5, -5);
	enhanced_eclipse_bar_options.btn_close_frame:SetHeight(23);
	enhanced_eclipse_bar_options.btn_close_frame:SetWidth(23);
	enhanced_eclipse_bar_options.btn_close_frame:SetScript("OnClick", function() enhanced_eclipse_bar_options.frame:Hide(); frame_options_visible = nil; end);
	
	enhanced_eclipse_bar_options.cb_hide_blizzard_eclipse_bar = CreateFrame("CheckButton", "enhanced_eclipse_bar_options_cb_hide_blizzard_eclipse_bar_global", enhanced_eclipse_bar_options.frame, "UICheckButtonTemplate");
	enhanced_eclipse_bar_options.cb_hide_blizzard_eclipse_bar:SetPoint("TOP", -65, -25);
	enhanced_eclipse_bar_options_cb_hide_blizzard_eclipse_bar_globalText:SetText("Hide Blizzard Eclipse Bar");
	enhanced_eclipse_bar_options.cb_hide_blizzard_eclipse_bar:SetHeight(20);
	enhanced_eclipse_bar_options.cb_hide_blizzard_eclipse_bar:SetWidth(20);
	EclipseBarFrame:Show();
	
	enhanced_eclipse_bar_options.cb_always_show_eclipse_bar = CreateFrame("CheckButton", "enhanced_eclipse_bar_options_cb_always_show_eclipse_bar_global", enhanced_eclipse_bar_options.frame, "UICheckButtonTemplate");
	enhanced_eclipse_bar_options.cb_always_show_eclipse_bar:SetPoint("TOP", -65, -45);
	enhanced_eclipse_bar_options_cb_always_show_eclipse_bar_globalText:SetText("Show No Matter Shapeshift");
	enhanced_eclipse_bar_options.cb_always_show_eclipse_bar:SetHeight(20);
	enhanced_eclipse_bar_options.cb_always_show_eclipse_bar:SetWidth(20);
	enhanced_eclipse_bar_options.cb_always_show_eclipse_bar:SetScript("OnClick", function(self) UpdateFrameVisibility(GetShapeshiftFormID()); end);
	
	enhanced_eclipse_bar_options.cb_only_show_in_combat = CreateFrame("CheckButton", "enhanced_eclipse_bar_options_cb_only_show_in_combat_global", enhanced_eclipse_bar_options.frame, "UICheckButtonTemplate");
	enhanced_eclipse_bar_options.cb_only_show_in_combat:SetPoint("TOP", -65, -65);
	enhanced_eclipse_bar_options_cb_only_show_in_combat_globalText:SetText("Only Show Bar In Combat");
	enhanced_eclipse_bar_options.cb_only_show_in_combat:SetHeight(20);
	enhanced_eclipse_bar_options.cb_only_show_in_combat:SetWidth(20);
	enhanced_eclipse_bar_options.cb_only_show_in_combat:SetScript("OnClick", function(self) UpdateFrameVisibility(GetShapeshiftFormID()); end);
	
	enhanced_eclipse_bar_options.fs_font = enhanced_eclipse_bar_options.frame:CreateFontString();
	enhanced_eclipse_bar_options.fs_font:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE");
	enhanced_eclipse_bar_options.fs_font:SetPoint("TOP", 0, -85);
	enhanced_eclipse_bar_options.fs_font:SetText("Font");
	
	enhanced_eclipse_bar_options.eb_font_size = CreateFrame("EditBox", nil, enhanced_eclipse_bar_options.frame);
	enhanced_eclipse_bar_options.eb_font_size:SetPoint("TOP", 0, -105);
	enhanced_eclipse_bar_options.eb_font_size:SetHeight(23);
	enhanced_eclipse_bar_options.eb_font_size:SetWidth(30);
	enhanced_eclipse_bar_options.eb_font_size:SetMultiLine(false);
	enhanced_eclipse_bar_options.eb_font_size:SetNumeric(true);
	enhanced_eclipse_bar_options.eb_font_size:SetAutoFocus(false);
	enhanced_eclipse_bar_options.eb_font_size:SetNumber(font["size"]);
	enhanced_eclipse_bar_options.eb_font_size:SetMaxLetters(2);
	enhanced_eclipse_bar_options.eb_font_size:SetFontObject("GameFontHighlight")
	enhanced_eclipse_bar_options.eb_font_size:SetBackdrop({ bgFile = nil, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
				tile = false, tileSize = 16, edgeSize = 16,
				insets = { left = 3, right = 3, top = 3, bottom = 3 } });
	enhanced_eclipse_bar_options.eb_font_size:SetTextInsets(4, 4, 3, 3);
	enhanced_eclipse_bar_options.eb_font_size:SetScript("OnEscapePressed", function(self) self:ClearFocus(); self:SetNumber(font["size"]); end);
	enhanced_eclipse_bar_options.eb_font_size:SetScript("OnEnterPressed", 
	function(self)
		self:ClearFocus();
		local value = min(50, max(1, self:GetNumber()));
		self:SetNumber(value);
		SetFontSize(value);
	end);
	
	enhanced_eclipse_bar_options.btn_font_drop_down_list = CreateFrame("Frame", "enhanced_eclipse_bar_options_btn_font_drop_down_list_global", enhanced_eclipse_bar_options.frame, "UIDropDownMenuTemplate");
	UIDropDownMenu_SetWidth(enhanced_eclipse_bar_options.btn_font_drop_down_list, 120)
	enhanced_eclipse_bar_options.btn_font_drop_down_list:SetPoint("TOP", 0, -130);
	UIDropDownMenu_SetText(enhanced_eclipse_bar_options.btn_font_drop_down_list, font["font"])
	UIDropDownMenu_Initialize(enhanced_eclipse_bar_options.btn_font_drop_down_list, function(self)
		local info = UIDropDownMenu_CreateInfo()
		info.func = SetFontFont
		for k, v in pairs(media_list["fonts"]) do
			info.text, info.checked, info.arg1 = k, (k == font["font"]), k
			UIDropDownMenu_AddButton(info)
		end
	end);
	
	enhanced_eclipse_bar_options.btn_fontflags_drop_down_list = CreateFrame("Frame", "enhanced_eclipse_bar_options_btn_fontflags_drop_down_list_global", enhanced_eclipse_bar_options.frame, "UIDropDownMenuTemplate");
	UIDropDownMenu_SetWidth(enhanced_eclipse_bar_options.btn_fontflags_drop_down_list, 120)
	enhanced_eclipse_bar_options.btn_fontflags_drop_down_list:SetPoint("TOP", 0, -160);
	UIDropDownMenu_SetText(enhanced_eclipse_bar_options.btn_fontflags_drop_down_list, "OUTLINE")
	UIDropDownMenu_Initialize(enhanced_eclipse_bar_options.btn_fontflags_drop_down_list, function(self)
		local info = UIDropDownMenu_CreateInfo()
		info.func = ToggleFontFontFlag
		for k, v in pairs(media_list["fontflags"]) do
			info.text, info.checked, info.arg1 = k, (font["flags"][k] ~= nil), k
			UIDropDownMenu_AddButton(info)
		end
	end);
	
	enhanced_eclipse_bar_options.fs_skin = enhanced_eclipse_bar_options.frame:CreateFontString();
	enhanced_eclipse_bar_options.fs_skin:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE");
	enhanced_eclipse_bar_options.fs_skin:SetPoint("TOP", 0, -200);
	enhanced_eclipse_bar_options.fs_skin:SetText("Skin");
	
	enhanced_eclipse_bar_options.btn_skin_drop_down_list = CreateFrame("Frame", "enhanced_eclipse_bar_options_btn_skin_drop_down_list_global", enhanced_eclipse_bar_options.frame, "UIDropDownMenuTemplate");
	UIDropDownMenu_SetWidth(enhanced_eclipse_bar_options.btn_skin_drop_down_list, 120)
	enhanced_eclipse_bar_options.btn_skin_drop_down_list:SetPoint("TOP", 0, -220);
	UIDropDownMenu_SetText(enhanced_eclipse_bar_options.btn_skin_drop_down_list, default_settings["skin"])
	UIDropDownMenu_Initialize(enhanced_eclipse_bar_options.btn_skin_drop_down_list, function(self)
		local info = UIDropDownMenu_CreateInfo()
		info.func = SetSkin
		for k, v in pairs(media_list["skins"]) do
			info.text, info.checked, info.arg1 = k, (k == skin), k
			UIDropDownMenu_AddButton(info)
		end
	end);
	
	enhanced_eclipse_bar_options.fs_reset = enhanced_eclipse_bar_options.frame:CreateFontString();
	enhanced_eclipse_bar_options.fs_reset:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE");
	enhanced_eclipse_bar_options.fs_reset:SetPoint("TOP", 0, -260);
	enhanced_eclipse_bar_options.fs_reset:SetText("Reset");
	
	enhanced_eclipse_bar_options.btn_reset_position = CreateFrame("Button", nil, enhanced_eclipse_bar_options.frame, "UIPanelButtonTemplate");
	enhanced_eclipse_bar_options.btn_reset_position:SetPoint("TOP", 0, -275);
	enhanced_eclipse_bar_options.btn_reset_position:SetHeight(23);
	enhanced_eclipse_bar_options.btn_reset_position:SetWidth(120);
	enhanced_eclipse_bar_options.btn_reset_position:SetText("Position");
	enhanced_eclipse_bar_options.btn_reset_position:SetScript("OnClick", function() ResetEclipseBarPosition(); end);
	
	enhanced_eclipse_bar_options.btn_reset_size = CreateFrame("Button", nil, enhanced_eclipse_bar_options.frame, "UIPanelButtonTemplate");
	enhanced_eclipse_bar_options.btn_reset_size:SetPoint("TOP", 0, -300);
	enhanced_eclipse_bar_options.btn_reset_size:SetHeight(23);
	enhanced_eclipse_bar_options.btn_reset_size:SetWidth(120);
	enhanced_eclipse_bar_options.btn_reset_size:SetText("Size");
	enhanced_eclipse_bar_options.btn_reset_size:SetScript("OnClick", function() ResetEclipseBarSize(); end);
	
	enhanced_eclipse_bar_options.fs_author = enhanced_eclipse_bar_options.frame:CreateFontString();
	enhanced_eclipse_bar_options.fs_author:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE");
	enhanced_eclipse_bar_options.fs_author:SetPoint("BOTTOM", 0, 5);
	enhanced_eclipse_bar_options.fs_author:SetText("Written by: |cffff7d0aKlynk|r|cff7092be#2603|r");
	
	-- Hook control events.
	enhanced_eclipse_bar.frame:SetScript("OnUpdate", function(self, elapsed) enhanced_eclipse_bar:OnUpdate(self, elapsed); end);
	
	-- Register events.
	enhanced_eclipse_bar.frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED");
	enhanced_eclipse_bar.frame:RegisterEvent("PLAYER_ENTERING_WORLD");
	enhanced_eclipse_bar.frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	enhanced_eclipse_bar.frame:RegisterEvent("ADDON_LOADED");
	enhanced_eclipse_bar.frame:RegisterEvent("PLAYER_LOGOUT");
	enhanced_eclipse_bar.frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM");
	enhanced_eclipse_bar.frame:RegisterEvent("PLAYER_REGEN_DISABLED");
	enhanced_eclipse_bar.frame:RegisterEvent("PLAYER_REGEN_ENABLED");
	
	-- Initialize the slash handler.
	SLASH_EEBAR1 = "/eebar";
	SlashCmdList["EEBAR"] = SlashHandler;

end

InitializeComponents();
