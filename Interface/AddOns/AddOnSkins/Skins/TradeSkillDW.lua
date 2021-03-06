local AS = unpack(AddOnSkins)

if not AS:CheckAddOn('TradeSkillDW') then return end

function AS:TradeSkillDW()
	local HORZ_BAR_FNAME = [[Interface\ClassTrainerFrame\UI-ClassTrainer-HorizontalBar]]
	local TradeSkillHorizontalBarRight
	for i, region in ipairs({TradeSkillFrame:GetRegions()}) do
		if region:IsObjectType("Texture") then
			if (region:GetTexture() == HORZ_BAR_FNAME) then
				if not(region:GetName()) then
					TradeSkillHorizontalBarRight = region
					break
				end
			end
		end
	end

	AS:SkinFrame(TradeSkillFrame)

	TradeSkillHorizontalBarRight:SetTexture(HORZ_BAR_FNAME)
	TradeSkillHorizontalBarRight:Kill()

	AS:SkinCloseButton(TradeSkillFrameCloseButton)

	AS:SkinFrame(TradeSkillGuildFrame)
	AS:SkinFrame(TradeSkillGuildFrameContainer)
	AS:SkinCloseButton(TradeSkillGuildFrameCloseButton)

	AS:SkinStatusBar(TradeSkillRankFrame)
	AS:SkinButton(TradeSkillCreateButton, true)
	AS:SkinNextPrevButton(TradeSkillDecrementButton)
	AS:SkinNextPrevButton(TradeSkillIncrementButton)
	AS:SkinButton(TradeSkillCancelButton, true)
	AS:SkinButton(TradeSkillFilterButton, true)
	AS:SkinButton(TradeSkillCreateAllButton, true)
	AS:SkinButton(TradeSkillViewGuildCraftersButton, true)
	AS:SkinScrollBar(TradeSkillDetailScrollFrameScrollBar)
	AS:SkinScrollBar(TradeSkillListScrollFrameScrollBar)

	local function SkinTabs(self)
		for i = 1, self:GetNumChildren() do
			local Child = select(i, self:GetChildren())
			if Child:IsObjectType('CheckButton') and not Child.IsSkinned then
				Child:DisableDrawLayer('BACKGROUND')
				AS:CreateBackdrop(Child)
				AS:SkinTexture(Child:GetNormalTexture())
				Child:GetNormalTexture():SetInside()
				Child:GetNormalTexture().SetPoint = AS.Noop
				Child:GetNormalTexture().SetTexCoord = AS.Noop
				AS:StyleButton(Child)
				Child.IsSkinned = true
			end
		end
	end

	TradeSkillFrame:HookScript('OnUpdate', function(self)
		if not TradeSkillDWExpandButton then return end
		if self.isSkinned then return end
		AS:SkinButton(TradeSkillDWExpandButton)
		TradeSkillDWExpandButton.Text = TradeSkillDWExpandButton:CreateFontString(nil, 'OVERLAY')
		TradeSkillDWExpandButton.Text:SetFont(AS.LSM:Fetch('font', 'Arial Narrow'), 24)
		TradeSkillDWExpandButton.SetNormalTexture = AS.Noop
		TradeSkillDWExpandButton.SetPushedTexture = AS.Noop
		TradeSkillDWExpandButton:HookScript('OnUpdate', function(self)
			if self.expanded then
				self.Text:SetText('◄')
				self.Text:SetPoint('CENTER', -2, 0)
			else
				self.Text:SetText('►')
				self.Text:SetPoint('CENTER', -1, 0)
			end
		end)
		AS:StripTextures(TradeSkillListScrollFrame, true)
		SkinTabs(self)
		self.isSkinned = true
	end)

	AS:SkinEditBox(TradeSkillFrameSearchBox)
	AS:SkinEditBox(TradeSkillInputBox)

	AS:StripTextures(TradeSkillDetailScrollFrame, true)
	AS:StripTextures(TradeSkillFrameInset, true)
	AS:StripTextures(TradeSkillExpandButtonFrame, true)
	AS:StripTextures(TradeSkillDetailScrollChildFrame, true)

	TradeSkillGuildFrame:Point('BOTTOMLEFT', TradeSkillFrame, 'BOTTOMRIGHT', 3, 19)

	TradeSkillFrame:Height(TradeSkillFrame:GetHeight() + 12)
	TradeSkillLinkButton:GetNormalTexture():SetTexCoord(0.25, 0.7, 0.37, 0.75)
	TradeSkillLinkButton:GetPushedTexture():SetTexCoord(0.25, 0.7, 0.45, 0.8)
	TradeSkillLinkButton:GetHighlightTexture():Kill()
	TradeSkillLinkButton:Size(17, 14)
	TradeSkillLinkButton:Point('LEFT', TradeSkillLinkFrame, 'LEFT', 5, -1)
	TradeSkillIncrementButton:Point('RIGHT', TradeSkillCreateButton, 'LEFT', -13, 0)

	local once = false
	hooksecurefunc('TradeSkillFrame_SetSelection', function(id)
		if not TradeSkillSkillIcon.isSkinned then
			AS:StyleButton(TradeSkillSkillIcon)
			AS:SetTemplate(TradeSkillSkillIcon, 'Default')
			TradeSkillSkillIcon.isSkinned = true
		end
		if TradeSkillSkillIcon:GetNormalTexture() then
			AS:SkinTexture(TradeSkillSkillIcon:GetNormalTexture())
			TradeSkillSkillIcon:GetNormalTexture():ClearAllPoints()
			TradeSkillSkillIcon:GetNormalTexture():SetInside()
		end
		for i = 1, MAX_TRADE_SKILL_REAGENTS do
			local button = _G['TradeSkillReagent'..i]
			local icon = _G['TradeSkillReagent'..i..'IconTexture']
			local count = _G['TradeSkillReagent'..i..'Count']

			if not button.isSkinned then
				AS:SkinTexture(icon)
				icon.SetTexCoord = AS.Noop
				icon:SetDrawLayer('ARTWORK')
				icon.backdrop = CreateFrame('Frame', nil, button)
				icon.backdrop:SetFrameLevel(button:GetFrameLevel() - 1)
				AS:SkinFrame(icon.backdrop)
				icon.backdrop:SetOutside(icon)
				icon:SetParent(icon.backdrop)
				count:SetParent(icon.backdrop)
				count:SetDrawLayer('OVERLAY')
				_G['TradeSkillReagent'..i..'NameFrame']:Kill()
				button.isSkinned = true
			end
			if i > 2 and once == false then
				local point, anchoredto, point2, x, y = button:GetPoint()
				button:ClearAllPoints()
				button:Point(point, anchoredto, point2, x, y - 3)
				once = true
			end
		end
	end)

	AS:SkinFrame(TradeSkillDW_QueueFrame, nil, nil, true)
	AS:SkinCloseButton(TradeSkillDW_QueueFrameCloseButton)
	AS:StripTextures(TradeSkillDW_QueueFrameInset, true)
	AS:SkinButton(TradeSkillDW_QueueFrameClear, true)
	AS:SkinButton(TradeSkillDW_QueueFrameDown, true)
	AS:SkinButton(TradeSkillDW_QueueFrameUp, true)
	AS:SkinButton(TradeSkillDW_QueueFrameDo, true)
	AS:StripTextures(TradeSkillDW_QueueFrameDetailScrollFrame)
	AS:StripTextures(TradeSkillDW_QueueFrameDetailScrollFrameChildFrame)

	for i = 1, 8 do
		AS:StripTextures(_G['TradeSkillDW_QueueFrameDetailScrollFrameChildFrameReagent'..i])
		AS:SkinTexture(_G['TradeSkillDW_QueueFrameDetailScrollFrameChildFrameReagent'..i..'IconTexture'])
	end

	AS:SkinScrollBar(TradeSkillDW_QueueFrameDetailScrollFrameScrollBar)
end

AS:RegisterSkin('TradeSkillDW', AS.TradeSkillDW)