---@class Editor:AceAddon-2.0 编辑器模块 xhwsd@qq.com 2025-6-27
OneMacroEditor = OneMacro:NewModule("Editor")

-- 列表框滚动步长
local LIST_BOX_STEP = 16

-- 策略列表框显示项数
local STRATEGY_LIST_BOX_DISPLAY = 25
-- 操作列表框显示项数
local OPERATION_LIST_BOX_DISPLAY = 3
-- 权重列表框显示项数
local WEIGHT_LIST_BOX_DISPLAY = 25
-- 检测列表框显示项数
local DETECT_LIST_BOX_DISPLAY = 25
-- 动作列表框显示项数
local ACTION_LIST_BOX_DISPLAY = 25
-- 通报列表框显示项数
local REPORT_LIST_BOX_DISPLAY = 25

--[[ 依赖 ]]

local Dewdrop = AceLibrary("Dewdrop-2.0")
local Array = AceLibrary("KuBa-Array-1.0")
local Prompt = AceLibrary("KuBa-Prompt-1.0")

--[[ 事件 ]]

---初始化
function OneMacroEditor:OnInitialize()
	-- 策略资料，会固化数据
	self.strategy = OneMacro.db.profile.strategy
	-- 权重资料，会固化数据
	self.weight = OneMacro.db.profile.weight
	-- 检测资料，会固化数据
	self.detect = OneMacro.db.profile.detect
	-- 动作资料，会固化数据
	self.action = OneMacro.db.profile.action
	-- 通报资料，会固化数据
	self.report = OneMacro.db.profile.report

	-- 已注册权重，由插件等动态注册
	self.weights = OneMacro.weights
	-- 已注册检测，由插件等动态注册
	self.detects = OneMacro.detects
	-- 已注册动作，由插件等动态注册
	self.actions = OneMacro.actions
end

---启用
function OneMacroEditor:OnEnable()

end

---禁用
function OneMacroEditor:OnDisable()

end

--[[ 框架 ]]

---框架载入
function OneMacroEditor:OnLoadFrame()

end

---框架显示
function OneMacroEditor:OnShowFrame()
	PlaySound("UChatScrollButton")

	-- 重置位置，解决超出屏幕
	if not OneMacroEditorFrame.clearPoints then
		OneMacroEditorFrame.clearPoints = true
		OneMacroEditorFrame:ClearAllPoints()
		OneMacroEditorFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)

		-- 初始显示选中策略
		local strategyParent, strategyChild = self:GetStrategySelected()
		self:SetStrategyEdit(strategyParent, strategyChild)

		-- 初始显示选中通报
		local reportParent, reportChild = self:GetReportSelected()
		self:SetReportEdit(reportParent, reportChild)


		-- TODO: 待清理无效展开 xhwsd@qq.com
	end
end

---框架隐藏
function OneMacroEditor:OnHideFrame()
	PlaySound("UChatScrollButton")
end

---是否可见
---@return boolean visible 可见
function OneMacroEditor:IsVisible()
	return OneMacroEditorFrame:IsVisible()
end

---显示
function OneMacroEditor:Show()
	OneMacroEditorFrame:Show()
end

---隐藏
function OneMacroEditor:Hide()
	OneMacroEditorFrame:Hide()
end

---切换显示
function OneMacroEditor:SwitchShow()
	if self:IsVisible() then
		self:Hide()
	else
		self:Show()
	end
end

----------------------------------------------------------------------------------------------

---策略新增按钮单击
function OneMacroEditor:OnClickStrategyNewButton()
	local dialog = "OneMacroEditor:OnClickStrategyNewButton"
	StaticPopupDialogs[dialog] = {
		text = "输入新增策略名称：",
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		hasEditBox = true,
		maxLetters = 30,
		OnShow = function()
			getglobal(this:GetName() .. "EditBox"):SetFocus()
		end,
		OnHide = function()
			getglobal(this:GetName() .. "EditBox"):SetText("")
		end,
		OnAccept = function()
			local name = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
			if name ~= "" then
				table.insert(self.strategy.list, {
					name = name,
					rules = {},
					expand = true,
					remark = "",
				})
				self:UpdateStrategyListBox()
			end
		end,
	}
	StaticPopup_Show(dialog)
end

---策略清空按钮单击
function OneMacroEditor:OnClickStrategyClearButton()
	local dialog = "OneMacroEditor:OnClickStrategyClearButton"
	StaticPopupDialogs[dialog] = {
		text = "确定清空策略吗？",
		button1 = OKAY,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnAccept = function()
			local error, count = OneMacro:ClearStrategys()
			if error == "" then
				Prompt:Info("清空%d个策略", count)
			else
				Prompt:Error("清空策略失败：" .. error)
			end
		end,
	}
	StaticPopup_Show(dialog)
end

---策略导入按钮单击
function OneMacroEditor:OnClickStrategyImportButton()
	local dialog = "OneMacroEditor:OnClickStrategyImportButton"
	StaticPopupDialogs[dialog] = {
		text = "输入导入策略文件名：",
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		hasEditBox = true,
		maxLetters = 30,
		OnShow = function()
			getglobal(this:GetName() .. "EditBox"):SetText(UnitClass("player") .. "-策略")
			getglobal(this:GetName() .. "EditBox"):SetFocus()
		end,
		OnHide = function()
			getglobal(this:GetName() .. "EditBox"):SetText("")
		end,
		OnAccept = function()
			local file = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
			if file ~= "" then
				local error, count = OneMacro:ImportStrategys(file)
				if error == "" then
					Prompt:Info("成功导入%d个策略", count)
				else
					Prompt:Error("导入策略失败：" .. error)
				end
			end
		end,
	}
	StaticPopup_Show(dialog)
end

---策略导出按钮单击
function OneMacroEditor:OnClickStrategyExportButton()
	local dialog = "OneMacroEditor:OnClickStrategyExportButton"
	StaticPopupDialogs[dialog] = {
		text = "输入导出策略文件名：",
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		hasEditBox = true,
		maxLetters = 30,
		OnShow = function()
			getglobal(this:GetName() .. "EditBox"):SetText(UnitClass("player") .. "-策略")
			getglobal(this:GetName() .. "EditBox"):SetFocus()
		end,
		OnHide = function()
			getglobal(this:GetName() .. "EditBox"):SetText("")
		end,
		OnAccept = function()
			local file = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
			if file ~= "" then
				local error, count = OneMacro:ExportStrategys(file)
				if error == "" then
					Prompt:Info("成功导出%d个策略", count)
				else
					Prompt:Error("导出策略失败：" .. error)
				end
			end
		end,
	}
	StaticPopup_Show(dialog)
end

---策略列表框载入
function OneMacroEditor:OnLoadStrategyListBox()
	self.StrategyListBox = this
	self.StrategyListBox:Show()
end

---策略列表框显示
function OneMacroEditor:OnShowStrategyListBox()
	self:UpdateStrategyListBox()
end

---策略列表框垂直滚动
function OneMacroEditor:OnVerticalScrollStrategyListBox()
	FauxScrollFrame_OnVerticalScroll(LIST_BOX_STEP, function()
		self:UpdateStrategyListBox()
	end)
end

---策略列表项载入
function OneMacroEditor:OnLoadStrategyListItem()
	-- 注册右键菜单
	Dewdrop:Register(this,
		"point", "TOP",
		"relativePoint", "BOTTOM",
		"cursorX", true,
		"children", function()
			local parentIndex, childIndex = unpack(this.value)
			if childIndex then
				-- 规则菜单
				if self.strategy.list[parentIndex].rules[childIndex].disable == false then
					Dewdrop:AddLine(
						"text", "启用规则",
						"closeWhenClicked", true,
						"arg1", parentIndex,
						"arg2", childIndex,
						"func", function(parent, child)
							self:OnClickRuleEnabledButton(parent, child)
						end
					)
				else
					Dewdrop:AddLine(
						"text", "禁用规则",
						"closeWhenClicked", true,
						"arg1", parentIndex,
						"arg2", childIndex,
						"func", function(parent, child)
							self:OnClickRuleDisableButton(parent, child)
						end
					)
				end
				Dewdrop:AddLine(
					"text", "重命名规则",
					"closeWhenClicked", true,
					"arg1", parentIndex,
					"arg2", childIndex,
					"func", function(parent, child)
						self:OnClickRuleRenameButton(parent, child)
					end
				)
				Dewdrop:AddLine(
					"text", "删除规则",
					"closeWhenClicked", true,
					"arg1", parentIndex,
					"arg2", childIndex,
					"func", function(parent, child)
						self:OnClickRuleDeleteButton(parent, child)
					end
				)
				-- 非第一个
				if childIndex > 1 then
					Dewdrop:AddLine(
						"text", "上移规则",
						"closeWhenClicked", true,
						"arg1", parentIndex,
						"arg2", childIndex,
						"func", function(parent, child)
							self:OnClickRuleUpButton(parent, child)
						end
					)
				end
				-- 非最后一个
				if childIndex < table.getn(self.strategy.list[parentIndex].rules) then
					Dewdrop:AddLine(
						"text", "下移规则",
						"closeWhenClicked", true,
						"arg1", parentIndex,
						"arg2", childIndex,
						"func", function(parent, child)
							self:OnClickRuleDownButton(parent, child)
						end
					)
				end
			else
				-- 策略菜单
				Dewdrop:AddLine(
					"text", "新增规则",
					"closeWhenClicked", true,
					"arg1", parentIndex,
					"func", function(parent)
						self:OnClickRuleNewButton(parent)
					end
				)
				Dewdrop:AddLine(
					"text", "重命名策略",
					"closeWhenClicked", true,
					"arg1", parentIndex,
					"func", function(parent)
						self:OnClickStrategyRenameButton(parent)
					end
				)
				Dewdrop:AddLine(
					"text", "删除策略",
					"closeWhenClicked", true,
					"arg1", parentIndex,
					"func", function(parent)
						self:OnClickStrategyDeleteButton(parent)
					end
				)
				-- 非第一个
				if parentIndex > 1 then
					Dewdrop:AddLine(
						"text", "上移策略",
						"closeWhenClicked", true,
						"arg1", parentIndex,
						"func", function(parent)
							self:OnClickStrategyUpButton(parent)
						end
					)
				end
				-- 非最后一个
				if parentIndex < table.getn(self.strategy.list) then
					Dewdrop:AddLine(
						"text", "下移策略",
						"closeWhenClicked", true,
						"arg1", parentIndex,
						"func", function(parent)
							self:OnClickStrategyDownButton(parent)
						end
					)
				end
			end
			Dewdrop:AddLine(
				"text", "关闭菜单",
				"closeWhenClicked", true
			)
		end
	)
end

---策略列表项单击
function OneMacroEditor:OnClickStrategyListItem()
	local parentIndex, childIndex = unpack(this.value)
	if childIndex then
		-- 子级单击
		local path = parentIndex .. "/" .. childIndex
		if self.strategy.selected ~= path then
			self.strategy.selected = path
			self:UpdateStrategyListBox()
		end
	else
		-- 父级单击
		self.strategy.list[parentIndex].expand = not self.strategy.list[parentIndex].expand
		self:UpdateStrategyListBox()
	end
end

---规则新增钮单击
---@param parent number 父级标识
function OneMacroEditor:OnClickRuleNewButton(parent)
	local dialog = "OneMacroEditor:OnClickRuleNewButton"
	StaticPopupDialogs[dialog] = {
		text = "输入新增规则名称：",
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		hasEditBox = true,
		maxLetters = 30,
		OnShow = function()
			getglobal(this:GetName() .. "EditBox"):SetFocus()
		end,
		OnHide = function()
			getglobal(this:GetName() .. "EditBox"):SetText("")
		end,
		OnAccept = function()
			local name = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
			if name ~= "" then
				self.strategy.list[parent].expand = true
				table.insert(self.strategy.list[parent].rules, {
					name = name,
					disable = false,
					filter = nil,
					conditions = {},
					operations = {},
					continue = false,
					remark = "",
				})
				self:UpdateStrategyListBox()
			end
		end,
	}
	StaticPopup_Show(dialog)
end

---策略重命名按钮单击
---@param parent number 父级标识
function OneMacroEditor:OnClickStrategyRenameButton(parent)
	local dialog = "OneMacroEditor:OnClickStrategyRenameButton"
	StaticPopupDialogs[dialog] = {
		text = "输入重命名策略名称：",
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		hasEditBox = true,
		maxLetters = 30,
		OnShow = function()
			getglobal(this:GetName() .. "EditBox"):SetText(self.strategy.list[parent].name)
			getglobal(this:GetName() .. "EditBox"):SetFocus()
		end,
		OnHide = function()
			getglobal(this:GetName() .. "EditBox"):SetText("")
		end,
		OnAccept = function()
			local name = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
			if name ~= "" then
				self.strategy.list[parent].name = name
				self:UpdateStrategyListBox()
			end
		end,
	}
	StaticPopup_Show(dialog)
end

---策略删除按钮单击
---@param parent number 父级索引
function OneMacroEditor:OnClickStrategyDeleteButton(parent)
	local dialog = "OneMacroEditor:OnClickStrategyDeleteButton"
	StaticPopupDialogs[dialog] = {
		text = "确定删除策略吗？",
		button1 = YES,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnAccept = function()
			table.remove(self.strategy.list, parent)
			self:UpdateStrategyListBox()
		end,
	}
	StaticPopup_Show(dialog)
end

---策略上移按钮单击
---@param parent number 父级索引
function OneMacroEditor:OnClickStrategyUpButton(parent)
	self.strategy.list[parent], self.strategy.list[parent - 1] = self.strategy.list[parent - 1],
		self.strategy.list[parent]
	self:UpdateStrategyListBox()
end

---策略下移按钮单击
---@param parent number 父级索引
function OneMacroEditor:OnClickStrategyDownButton(parent)
	self.strategy.list[parent], self.strategy.list[parent + 1] = self.strategy.list[parent + 1],
		self.strategy.list[parent]
	self:UpdateStrategyListBox()
end

---规则启用按钮单击
---@param parent number 父级索引
---@param child number 子级索引
function OneMacroEditor:OnClickRuleEnabledButton(parent, child)
	self.strategy.list[parent].rules[child].disable = false
	self:UpdateStrategyListBox()
end

---规则禁用按钮单击
---@param parent number 父级索引
---@param child number 子级索引
function OneMacroEditor:OnClickRuleDisableButton(parent, child)
	self.strategy.list[parent].rules[child].disable = true
	self:UpdateStrategyListBox()
end

---规则重命名按钮单击
---@param parent number 父级索引
---@param child number 子级索引
function OneMacroEditor:OnClickRuleRenameButton(parent, child)
	local dialog = "OneMacroEditor:OnClickRuleRenameButton"
	StaticPopupDialogs[dialog] = {
		text = "输入重命名规则名称：",
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		hasEditBox = true,
		maxLetters = 30,
		OnShow = function()
			getglobal(this:GetName() .. "EditBox"):SetText(self.strategy.list[parent].rules[child].name)
			getglobal(this:GetName() .. "EditBox"):SetFocus()
		end,
		OnHide = function()
			getglobal(this:GetName() .. "EditBox"):SetText("")
		end,
		OnAccept = function(data)
			local name = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
			if name ~= "" then
				self.strategy.list[parent].rules[child].name = name
				self:UpdateStrategyListBox()
			end
		end,
	}
	StaticPopup_Show(dialog)
end

---规则删除按钮单击
---@param parent number 父级索引
---@param child number 子级索引
function OneMacroEditor:OnClickRuleDeleteButton(parent, child)
	local dialog = "OneMacroEditor:OnClickRuleDeleteButton"
	StaticPopupDialogs[dialog] = {
		text = "确定删除规则吗？",
		button1 = YES,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnAccept = function()
			table.remove(self.strategy.list[parent].rules, child)
			self:UpdateStrategyListBox()
		end,
	}
	StaticPopup_Show(dialog)
end

---规则上移按钮单击
---@param parent number 父级索引
---@param child number 子级索引
function OneMacroEditor:OnClickRuleUpButton(parent, child)
	self.strategy.list[parent].rules[child], self.strategy.list[parent].rules[child - 1] =
	self.strategy.list[parent].rules[child - 1], self.strategy.list[parent].rules[child]
	self:UpdateStrategyListBox()
end

---规则上移按钮单击
---@param parent number 父级索引
---@param child number 子级索引
function OneMacroEditor:OnClickRuleDownButton(parent, child)
	self.strategy.list[parent].rules[child], self.strategy.list[parent].rules[child + 1] =
	self.strategy.list[parent].rules[child + 1], self.strategy.list[parent].rules[child]
	self:UpdateStrategyListBox()
end

---更新策略列表框
function OneMacroEditor:UpdateStrategyListBox()
	-- 从树转列表
	local listData = {}
	for parentIndex, parentData in ipairs(self.strategy.list) do
		-- 父级
		table.insert(listData, {
			title = (type(parentData.name) == "string" and parentData.name ~= "") and parentData.name or parentIndex,
			label = table.getn(parentData.rules),
			tooltip = parentData.remark,
			expand = parentData.expand == true,
			value = { parentIndex },
		})

		-- 子级
		if parentData.expand == true and parentData.rules then
			for childIndex, childData in ipairs(parentData.rules) do
				table.insert(listData, {
					title = (type(childData.name) == "string" and childData.name ~= "") and childData.name or childIndex,
					label = childData.disable == true and "禁用" or "",
					tooltip = childData.remark,
					value = { parentIndex, childIndex },
				})
			end
		end
	end

	-- 更新滚动框架
	local itemNumber = table.getn(listData)
	FauxScrollFrame_Update(self.StrategyListBox, itemNumber, STRATEGY_LIST_BOX_DISPLAY, LIST_BOX_STEP)

	-- 切换项显示
	local itemName = self.StrategyListBox:GetParent():GetName() .. "StrategyListItem"
	for index = 1, STRATEGY_LIST_BOX_DISPLAY do
		local itemButton = getglobal(itemName .. index)
		local itemButtonTag = getglobal(itemName .. index .. "Tag")
		local offset = index + FauxScrollFrame_GetOffset(self.StrategyListBox)
		if offset <= itemNumber then
			local itemData = listData[offset]
			itemButton.tooltip = itemData.tooltip
			itemButton.value = itemData.value
			if type(itemData.expand) == "boolean" then
				-- 父节点
				itemButton:SetText(tostring(itemData.title))
				itemButton:SetNormalTexture("Interface\\Buttons\\" ..
				(itemData.expand and "UI-MinusButton-Up" or "UI-PlusButton-Up"))
				itemButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
				itemButtonTag:SetText(tostring(itemData.label))
			else
				-- 子节点
				itemButton:SetText("  " .. itemData.title)
				itemButton:SetNormalTexture(self.strategy.selected == table.concat(itemData.value, "/") and
				"Interface\\QuestFrame\\UI-Quest-BulletPoint" or "")
				itemButton:SetHighlightTexture("")
				itemButtonTag:SetText(tostring(itemData.label))
			end
			itemButton:Show()
		else
			itemButton:Hide()
		end
	end
end

---取策略选中
---@return number? parent 父级索引
---@return number? child 子级索引
function OneMacroEditor:GetStrategySelected()
	if self.strategy.selected then
		local parent, child = string.match(self.strategy.selected, "([^/]+)/([^/]+)")
		return tonumber(parent), tonumber(child)
	end
end

---置策略编辑
---@param parent? number 父级索引
---@param child? number 子级索引
function OneMacroEditor:SetStrategyEdit(parent, child)
	self:SetFilterEdit(parent, child)
end

---置筛选编辑
---@param parent? number 父级索引
---@param child? number 子级索引
function OneMacroEditor:SetFilterEdit(parent, child)
	-- 组件前缀
	local prefix = table.concat({
		"OneMacroEditorFrame",
		"TabFrame1",
		"RightGroupBox",
		"TabFrame1",
	})

	-- 范围组合框
	local scopeComboBox = getglobal(prefix .. "ScopeComboBox")
	scopeComboBox.values = {}
	UIDropDownMenu_Initialize(scopeComboBox, function()
		-- 列表
		local list = {
			{
				text = "团队",
				value = "raid",
			},
			{
				text = "小队",
				value = "team",
			},
			{
				text = "队伍",
				value = "party",
			},
			{
				text = "名单",
				value = "roster",
			},
			{
				text = "玩家",
				value = "player",
			},
			{
				text = "目标",
				value = "target",
			},
		}
		for _, item in ipairs(list) do
			UIDropDownMenu_AddButton({
				text = item.text,
				value = item.value,
				--checked = true,
				func = function()
					-- 增删选中值
					local index = Array:InList(scopeComboBox.values, this.value)
					if index then
						-- 移除
						table.remove(scopeComboBox.values, index)
					else
						-- 加入
						table.insert(scopeComboBox.values, this.value)
					end

					-- 置组合框文本
					local names = {
						["raid"] = "团队",
						["team"] = "小队",
						["party"] = "队伍",
						["roster"] = "名单",
						["player"] = "玩家",
						["target"] = "目标",
					}
					local texts = {}
					for _, value in ipairs(scopeComboBox.values) do
						table.insert(texts, names[value])
					end
					UIDropDownMenu_SetText(table.concat(texts, ","), scopeComboBox)
				end,
			})
		end
	end)
	UIDropDownMenu_SetWidth(210, scopeComboBox)

	-- 权重组合框
	local weightComboBox = getglobal(prefix .. "WeightComboBox")
	UIDropDownMenu_Initialize(weightComboBox, function(level)
		if not level or level == 1 then
			-- 升序空间
			local spaces = Array:GetOrders(self.weights, function(a, b)
				return (a.data.order or 0) < (b.data.order or 0)
			end)
			for _, space in ipairs(spaces) do
				UIDropDownMenu_AddButton({
					text = self.weights[space].name,
					value = space,
					--checked = true,
					func = function()
						--UIDropDownMenu_SetSelectedValue(weightComboBox, this.value)
					end,
					hasArrow = true,
				})
			end
		elseif level == 2 and self.weights[UIDROPDOWNMENU_MENU_VALUE] then
			-- 升序权重
			local weights = Array:GetOrders(self.weights[UIDROPDOWNMENU_MENU_VALUE].weights, function(a, b)
				return (a.data.order or 0) < (b.data.order or 0)
			end)
			for _, weight in ipairs(weights) do
				UIDropDownMenu_AddButton({
					text = self.weights[UIDROPDOWNMENU_MENU_VALUE].weights[weight].name,
					value = weight,
					func = function()
						--UIDropDownMenu_SetSelectedValue(weightComboBox, this.value)
					end,
				}, level)
			end
		end
	end)

	-- 排序组合框
	local sortComboBox = getglobal(prefix .. "SortComboBox")
	UIDropDownMenu_Initialize(sortComboBox, function()
		local list = {
			{
				text = "升序",
				value = "asc",
			},
			{
				text = "降序",
				value = "desc",
			},
			{
				text = "打乱",
				value = "disturb",
			},
		}
		for _, itme in ipairs(list) do
			UIDropDownMenu_AddButton({
				text = itme.text,
				value = itme.value,
				func = function()
					UIDropDownMenu_SetSelectedValue(sortComboBox, this.value)
				end,
			})
		end
	end)

	-- 选取组合框
	local chooseComboBox = getglobal(prefix .. "ChooseComboBox")
	UIDropDownMenu_Initialize(chooseComboBox, function()
		local list = {
			{
				text = "第一个",
				value = "first",
			},
			{
				text = "最后一个",
				value = "last",
			},
			{
				text = "随机一个",
				value = "random",
			},
			{
				text = "遍历每个",
				value = "traverse",
			},
		}
		for _, item in ipairs(list) do
			UIDropDownMenu_AddButton({
				text = item.text,
				value = item.value,
				func = function()
					UIDropDownMenu_SetSelectedValue(chooseComboBox, this.value)
				end,
			})
		end
	end)
end

---筛选清空按钮点击
function OneMacroEditor:OnClickMacroFilterClearButton()
	-- 置组合框文本
	local scopeComboBox = getglobal(this:GetParent():GetName() .. "ScopeComboBox")
	scopeComboBox.values = {}
	UIDropDownMenu_SetText("", scopeComboBox)

	-- 关闭下拉菜单
	CloseDropDownMenus()
end

----------------------------------------------------------------------------------------------

---操作列表框载入
function OneMacroEditor:OnLoadOperationListBox()
	self.OperationListBox = this
	self.OperationListBox:Show()
end

---操作列表框显示
function OneMacroEditor:OnShowOperationListBox()
	self:UpdateOperationListBox()
end

---操作列表框垂直滚动
function OneMacroEditor:OnVerticalScrollOperationListBox()
	FauxScrollFrame_OnVerticalScroll(OPERATION_LIST_BOX_DISPLAY, function()
		self:UpdateOperationListBox()
	end)
end

---更新操作列表框
function OneMacroEditor:UpdateOperationListBox()
	local listData = {
		{
			title = "点击",
			label = "",
			tooltip = "点击目标",
			expand = false,
			value = { "click" },
		},
		{
			title = "移动",
			label = "",
			tooltip = "移动目标",
			expand = false,
			value = { "move" },
		},
		{
			title = "点击",
			label = "",
			tooltip = "点击目标",
			expand = false,
			value = { "click" },
		},
		{
			title = "移动",
			label = "",
			tooltip = "移动目标",
			expand = false,
			value = { "move" },
		},
		{
			title = "移动",
			label = "",
			tooltip = "移动目标",
			expand = false,
			value = { "move" },
		},
		{
			title = "点击",
			label = "",
			tooltip = "点击目标",
			expand = false,
			value = { "click" },
		},
		{
			title = "移动",
			label = "",
			tooltip = "移动目标",
			expand = false,
			value = { "move" },
		},
		{
			title = "移动",
			label = "",
			tooltip = "移动目标",
			expand = false,
			value = { "move" },
		},
		{
			title = "点击",
			label = "",
			tooltip = "点击目标",
			expand = false,
			value = { "click" },
		},
		{
			title = "移动",
			label = "",
			tooltip = "移动目标",
			expand = false,
			value = { "move" },
		},
		{
			title = "移动",
			label = "",
			tooltip = "移动目标",
			expand = false,
			value = { "move" },
		},
		{
			title = "点击",
			label = "",
			tooltip = "点击目标",
			expand = false,
			value = { "click" },
		},
		{
			title = "移动",
			label = "",
			tooltip = "移动目标",
			expand = false,
			value = { "move" },
		},
		{
			title = "移动",
			label = "",
			tooltip = "移动目标",
			expand = false,
			value = { "move" },
		},
		{
			title = "点击",
			label = "",
			tooltip = "点击目标",
			expand = false,
			value = { "click" },
		},
		{
			title = "移动",
			label = "",
			tooltip = "移动目标",
			expand = false,
			value = { "move" },
		},
		{
			title = "移动",
			label = "",
			tooltip = "移动目标",
			expand = false,
			value = { "move" },
		},
		{
			title = "点击",
			label = "",
			tooltip = "点击目标",
			expand = false,
			value = { "click" },
		},
		{
			title = "移动",
			label = "",
			tooltip = "移动目标",
			expand = false,
			value = { "move" },
		},
	}

	-- 更新滚动框架
	local itemNumber = table.getn(listData)
	FauxScrollFrame_Update(self.OperationListBox, itemNumber, OPERATION_LIST_BOX_DISPLAY, 2)

	-- 切换项显示
	local itemName = self.OperationListBox:GetParent():GetName() .. "OperationListItem"
	for index = 1, OPERATION_LIST_BOX_DISPLAY do
		local item = getglobal(itemName .. index)
		local offset = index + FauxScrollFrame_GetOffset(self.OperationListBox)
		if offset <= itemNumber then
			item:Show()
		else
			item:Hide()
		end
	end
end

----------------------------------------------------------------------------------------------

---权重列表框载入
function OneMacroEditor:OnLoadWeightListBox()
	self.WeightListBox = this
	self.WeightListBox:Show()
end

---权重列表框显示
function OneMacroEditor:OnShowWeightListBox()
	self:UpdateWeightListBox()
end

---权重列表框垂直滚动
function OneMacroEditor:OnVerticalScrollWeightListBox()
	FauxScrollFrame_OnVerticalScroll(LIST_BOX_STEP, function()
		self:UpdateWeightListBox()
	end)
end

---更新权重列表框
function OneMacroEditor:UpdateWeightListBox()
	-- 从树转列表
	local listData = {}
	-- 升序排列
	local parentKeys = Array:GetOrders(self.weights, function(a, b)
		return (a.data.order or 0) < (b.data.order or 0)
	end)
	for _, parentKey in ipairs(parentKeys) do
		-- 父级
		local parentData = self.weights[parentKey]
		table.insert(listData, {
			title = (type(parentData.name) == "string" and parentData.name ~= "") and parentData.name or parentKey,
			label = Array:Count(parentData.weights),
			tooltip = parentData.remark,
			expand = self.weight.expands[parentKey] == true,
			value = { parentKey },
		})

		-- 子级
		if self.weight.expands[parentKey] == true and parentData.weights then
			-- 升序排列
			local childKeys = Array:GetOrders(parentData.weights, function(a, b)
				return (a.data.order or 0) < (b.data.order or 0)
			end)
			for _, childKey in ipairs(childKeys) do
				local childData = parentData.weights[childKey]
				table.insert(listData, {
					title = (type(childData.name) == "string" and childData.name ~= "") and childData.name or childKey,
					label = "",
					tooltip = childData.remark,
					value = { parentKey, childKey },
				})
			end
		end
	end

	-- 更新滚动框架
	local itemNumber = table.getn(listData)
	FauxScrollFrame_Update(self.WeightListBox, itemNumber, WEIGHT_LIST_BOX_DISPLAY, LIST_BOX_STEP)

	-- 切换项显示
	local itemName = self.WeightListBox:GetParent():GetName() .. "WeightListItem"
	for index = 1, WEIGHT_LIST_BOX_DISPLAY do
		local itemButton = getglobal(itemName .. index)
		local itemButtonTag = getglobal(itemName .. index .. "Tag")
		local offset = index + FauxScrollFrame_GetOffset(self.WeightListBox)
		if offset <= itemNumber then
			local itemData = listData[offset]
			itemButton.tooltip = itemData.tooltip
			itemButton.value = itemData.value
			if type(itemData.expand) == "boolean" then
				-- 父节点
				itemButton:SetText(tostring(itemData.title))
				itemButton:SetNormalTexture("Interface\\Buttons\\" ..
				(itemData.expand and "UI-MinusButton-Up" or "UI-PlusButton-Up"))
				itemButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
				itemButtonTag:SetText(tostring(itemData.label))
			else
				-- 子节点
				itemButton:SetText("  " .. itemData.title)
				itemButton:SetNormalTexture(self.weight.selected == table.concat(itemData.value, "/") and
				"Interface\\QuestFrame\\UI-Quest-BulletPoint" or "")
				itemButton:SetHighlightTexture("")
				itemButtonTag:SetText(tostring(itemData.label))
			end
			itemButton:Show()
		else
			itemButton:Hide()
		end
	end
end

---权重列表项载入
function OneMacroEditor:OnLoadWeightListItem()

end

---权重列表项单击
function OneMacroEditor:OnClickWeightListItem()
	local parentKey, childKey = unpack(this.value)
	if childKey then
		-- 子级单击
		local path = parentKey .. "/" .. childKey
		if self.weight.selected ~= path then
			self.weight.selected = path
			self:UpdateWeightListBox()
		end
	else
		-- 父级单击
		self.weight.expands[parentKey] = not self.weight.expands[parentKey]
		self:UpdateWeightListBox()
	end
end

---权重列表项进入
function OneMacroEditor:OnEnterWeightListItem()

end

---权重列表项离开
function OneMacroEditor:OnLeaveWeightListItem()

end

----------------------------------------------------------------------------------------------

---检测列表框载入
function OneMacroEditor:OnLoadDetectListBox()
	self.DetectListBox = this
	self.DetectListBox:Show()
end

---检测列表框显示
function OneMacroEditor:OnShowDetectListBox()
	self:UpdateDetectListBox()
end

---检测列表框垂直滚动
function OneMacroEditor:OnVerticalScrollDetectListBox()
	FauxScrollFrame_OnVerticalScroll(LIST_BOX_STEP, function()
		self:UpdateDetectListBox()
	end)
end

---更新检测列表框
function OneMacroEditor:UpdateDetectListBox()
	-- 从树转列表
	local listData = {}
	-- 升序排列
	local parentKeys = Array:GetOrders(self.detects, function(a, b)
		return (a.data.order or 0) < (b.data.order or 0)
	end)
	for _, parentKey in ipairs(parentKeys) do
		-- 父级
		local parentData = self.detects[parentKey]
		table.insert(listData, {
			title = (type(parentData.name) == "string" and parentData.name ~= "") and parentData.name or parentKey,
			label = Array:Count(parentData.detects),
			tooltip = parentData.remark,
			expand = self.detect.expands[parentKey] == true,
			value = { parentKey },
		})

		-- 子级
		if self.detect.expands[parentKey] == true and parentData.detects then
			-- 升序排列
			local childKeys = Array:GetOrders(parentData.detects, function(a, b)
				return (a.data.order or 0) < (b.data.order or 0)
			end)
			for _, childKey in ipairs(childKeys) do
				local childData = parentData.detects[childKey]
				table.insert(listData, {
					title = (type(childData.name) == "string" and childData.name ~= "") and childData.name or childKey,
					label = "",
					tooltip = childData.remark,
					value = { parentKey, childKey },
				})
			end
		end
	end

	-- 更新滚动框架
	local itemNumber = table.getn(listData)
	FauxScrollFrame_Update(self.DetectListBox, itemNumber, DETECT_LIST_BOX_DISPLAY, LIST_BOX_STEP)

	-- 切换项显示
	local itemName = self.DetectListBox:GetParent():GetName() .. "DetectListItem"
	for index = 1, DETECT_LIST_BOX_DISPLAY do
		local itemButton = getglobal(itemName .. index)
		local itemButtonTag = getglobal(itemName .. index .. "Tag")
		local offset = index + FauxScrollFrame_GetOffset(self.DetectListBox)
		if offset <= itemNumber then
			local itemData = listData[offset]
			itemButton.tooltip = itemData.tooltip
			itemButton.value = itemData.value
			if type(itemData.expand) == "boolean" then
				-- 父节点
				itemButton:SetText(tostring(itemData.title))
				itemButton:SetNormalTexture("Interface\\Buttons\\" ..
				(itemData.expand and "UI-MinusButton-Up" or "UI-PlusButton-Up"))
				itemButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
				itemButtonTag:SetText(tostring(itemData.label))
			else
				-- 子节点
				itemButton:SetText("  " .. itemData.title)
				itemButton:SetNormalTexture(self.detect.selected == table.concat(itemData.value, "/") and
				"Interface\\QuestFrame\\UI-Quest-BulletPoint" or "")
				itemButton:SetHighlightTexture("")
				itemButtonTag:SetText(tostring(itemData.label))
			end
			itemButton:Show()
		else
			itemButton:Hide()
		end
	end
end

---检测列表项载入
function OneMacroEditor:OnLoadDetectListItem()

end

---检测列表项单击
function OneMacroEditor:OnClickDetectListItem()
	local parentKey, childKey = unpack(this.value)
	if childKey then
		-- 子级单击
		local path = parentKey .. "/" .. childKey
		if self.detect.selected ~= path then
			self.detect.selected = path
			self:UpdateDetectListBox()
		end
	else
		-- 父级单击
		self.detect.expands[parentKey] = not self.detect.expands[parentKey]
		self:UpdateDetectListBox()
	end
end

----------------------------------------------------------------------------------------------

---动作列表框载入
function OneMacroEditor:OnLoadActionListBox()
	self.ActionListBox = this
	self.ActionListBox:Show()
end

---动作列表框显示
function OneMacroEditor:OnShowActionListBox()
	self:UpdateActionListBox()
end

---动作列表框垂直滚动
function OneMacroEditor:OnVerticalScrollActionListBox()
	FauxScrollFrame_OnVerticalScroll(LIST_BOX_STEP, function()
		self:UpdateActionListBox()
	end)
end

---更新动作列表框
function OneMacroEditor:UpdateActionListBox()
	-- 从树转列表
	local listData = {}
	-- 升序排列
	local parentKeys = Array:GetOrders(self.actions, function(a, b)
		return (a.data.order or 0) < (b.data.order or 0)
	end)
	for _, parentKey in ipairs(parentKeys) do
		-- 父级
		local parentData = self.actions[parentKey]
		table.insert(listData, {
			title = (type(parentData.name) == "string" and parentData.name ~= "") and parentData.name or parentKey,
			label = Array:Count(parentData.actions),
			tooltip = parentData.remark,
			expand = self.action.expands[parentKey] == true,
			value = { parentKey },
		})

		-- 子级
		if self.action.expands[parentKey] == true and parentData.actions then
			-- 升序排列
			local childKeys = Array:GetOrders(parentData.actions, function(a, b)
				return (a.data.order or 0) < (b.data.order or 0)
			end)
			for _, childKey in ipairs(childKeys) do
				local childData = parentData.actions[childKey]
				table.insert(listData, {
					title = (type(childData.name) == "string" and childData.name ~= "") and childData.name or childKey,
					label = "",
					tooltip = childData.remark,
					value = { parentKey, childKey },
				})
			end
		end
	end

	-- 更新滚动框架
	local itemNumber = table.getn(listData)
	FauxScrollFrame_Update(self.ActionListBox, itemNumber, ACTION_LIST_BOX_DISPLAY, LIST_BOX_STEP)

	-- 切换项显示
	local itemName = self.ActionListBox:GetParent():GetName() .. "ActionListItem"
	for index = 1, ACTION_LIST_BOX_DISPLAY do
		local itemButton = getglobal(itemName .. index)
		local itemButtonTag = getglobal(itemName .. index .. "Tag")
		local offset = index + FauxScrollFrame_GetOffset(self.ActionListBox)
		if offset <= itemNumber then
			local itemData = listData[offset]
			itemButton.tooltip = itemData.tooltip
			itemButton.value = itemData.value
			if type(itemData.expand) == "boolean" then
				-- 父节点
				itemButton:SetText(tostring(itemData.title))
				itemButton:SetNormalTexture("Interface\\Buttons\\" ..
				(itemData.expand and "UI-MinusButton-Up" or "UI-PlusButton-Up"))
				itemButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
				itemButtonTag:SetText(tostring(itemData.label))
			else
				-- 子节点
				itemButton:SetText("  " .. itemData.title)
				itemButton:SetNormalTexture(self.action.selected == table.concat(itemData.value, "/") and
				"Interface\\QuestFrame\\UI-Quest-BulletPoint" or "")
				itemButton:SetHighlightTexture("")
				itemButtonTag:SetText(tostring(itemData.label))
			end
			itemButton:Show()
		else
			itemButton:Hide()
		end
	end
end

---动作列表项载入
function OneMacroEditor:OnLoadActionListItem()

end

---动作列表项单击
function OneMacroEditor:OnClickActionListItem()
	local parentKey, childKey = unpack(this.value)
	if childKey then
		-- 子级单击
		local path = parentKey .. "/" .. childKey
		if self.action.selected ~= path then
			self.action.selected = path
			self:UpdateActionListBox()
		end
	else
		-- 父级单击
		self.action.expands[parentKey] = not self.action.expands[parentKey]
		self:UpdateActionListBox()
	end
end

----------------------------------------------------------------------------------------------

---通报清空按钮单击
function OneMacroEditor:OnClickReportClearButton()
	local dialog = "OneMacroEditor:OnClickReportClearButton"
	StaticPopupDialogs[dialog] = {
		text = "确定清空通报吗？",
		button1 = OKAY,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnAccept = function()
			local error, count = OneMacro:ClearReports()
			if error == "" then
				Prompt:Info("清空%d个通报", count)
			else
				Prompt:Error("清空通报失败：" .. error)
			end
		end,
	}
	StaticPopup_Show(dialog)
end

---通报导入按钮单击
function OneMacroEditor:OnClickReportImportButton()
	local dialog = "OneMacroEditor:OnClickReportImportButton"
	StaticPopupDialogs[dialog] = {
		text = "输入导入通报文件名：",
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		hasEditBox = true,
		maxLetters = 30,
		OnShow = function()
			getglobal(this:GetName() .. "EditBox"):SetText(UnitClass("player") .. "-通报")
			getglobal(this:GetName() .. "EditBox"):SetFocus()
		end,
		OnHide = function()
			getglobal(this:GetName() .. "EditBox"):SetText("")
		end,
		OnAccept = function()
			local file = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
			if file ~= "" then
				local error, count = OneMacro:ImportReports(file)
				if error == "" then
					Prompt:Info("成功导入%d个通报", count)
				else
					Prompt:Error("导入通报失败：" .. error)
				end
			end
		end,
	}
	StaticPopup_Show(dialog)
end

---通报导出按钮单击
function OneMacroEditor:OnClickReportExportButton()
	local dialog = "OneMacroEditor:OnClickReportExportButton"
	StaticPopupDialogs[dialog] = {
		text = "输入导出通报文件名：",
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		hasEditBox = true,
		maxLetters = 30,
		OnShow = function()
			getglobal(this:GetName() .. "EditBox"):SetText(UnitClass("player") .. "-通报")
			getglobal(this:GetName() .. "EditBox"):SetFocus()
		end,
		OnHide = function()
			getglobal(this:GetName() .. "EditBox"):SetText("")
		end,
		OnAccept = function()
			local file = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
			if file ~= "" then
				local error, count = OneMacro:ExportReports(file)
				if error == "" then
					Prompt:Info("成功导出%d个通报", count)
				else
					Prompt:Error("导出通报失败：" .. error)
				end
			end
		end,
	}
	StaticPopup_Show(dialog)
end

---通报列表框载入
function OneMacroEditor:OnLoadReportListBox()
	self.ReportListBox = this
	self.ReportListBox:Show()
end

---通报列表框显示
function OneMacroEditor:OnShowReportListBox()
	self:UpdateReportListBox()
end

---通报列表框垂直滚动
function OneMacroEditor:OnVerticalScrollReportListBox()
	FauxScrollFrame_OnVerticalScroll(LIST_BOX_STEP, function()
		self:UpdateReportListBox()
	end)
end

---更新通报列表框
function OneMacroEditor:UpdateReportListBox()
	-- 从树转列表
	local listData = {}
	-- 升序排列
	local parentKeys = Array:GetOrders(self.report.list, function(a, b)
		return (a.data.order or 0) < (b.data.order or 0)
	end)
	for _, parentKey in ipairs(parentKeys) do
		-- 父级
		local parentData = self.report.list[parentKey]
		table.insert(listData, {
			title = (type(parentData.name) == "string" and parentData.name ~= "") and parentData.name or parentKey,
			label = Array:Count(parentData.reports),
			tooltip = parentData.remark,
			expand = parentData.expand == true,
			value = { parentKey },
		})

		-- 子级
		if parentData.expand == true and parentData.reports then
			-- 升序排列
			local childKeys = Array:GetOrders(parentData.reports, function(a, b)
				return (a.data.order or 0) < (b.data.order or 0)
			end)
			for _, childKey in ipairs(childKeys) do
				local childData = parentData.reports[childKey]
				table.insert(listData, {
					title = childKey,
					label = childData.disable == true and "禁用" or "",
					tooltip = childData.remark,
					value = { parentKey, childKey },
				})
			end
		end
	end

	-- 更新滚动框架
	local itemNumber = table.getn(listData)
	FauxScrollFrame_Update(self.ReportListBox, itemNumber, REPORT_LIST_BOX_DISPLAY, LIST_BOX_STEP)

	-- 切换项显示
	local itemName = self.ReportListBox:GetParent():GetName() .. "ReportListItem"
	for index = 1, REPORT_LIST_BOX_DISPLAY do
		local itemButton = getglobal(itemName .. index)
		local itemButtonTag = getglobal(itemName .. index .. "Tag")
		local offset = index + FauxScrollFrame_GetOffset(self.ReportListBox)
		if offset <= itemNumber then
			local itemData = listData[offset]
			itemButton.tooltip = itemData.tooltip
			itemButton.value = itemData.value
			if type(itemData.expand) == "boolean" then
				-- 父节点
				itemButton:SetText(tostring(itemData.title))
				itemButton:SetNormalTexture("Interface\\Buttons\\" ..
				(itemData.expand and "UI-MinusButton-Up" or "UI-PlusButton-Up"))
				itemButton:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight")
				itemButtonTag:SetText(tostring(itemData.label))
			else
				-- 子节点
				itemButton:SetText("  " .. itemData.title)
				itemButton:SetNormalTexture(self.report.selected == table.concat(itemData.value, "/") and
				"Interface\\QuestFrame\\UI-Quest-BulletPoint" or "")
				itemButton:SetHighlightTexture("")
				itemButtonTag:SetText(tostring(itemData.label))
			end
			itemButton:Show()
		else
			itemButton:Hide()
		end
	end
end

---通报列表项载入
function OneMacroEditor:OnLoadReportListItem()
	-- 注册右键菜单
	Dewdrop:Register(this,
		"point", "TOP",
		"relativePoint", "BOTTOM",
		"cursorX", true,
		"children", function()
			local parentKey, childKey = unpack(this.value)
			if childKey then
				-- 通报菜单
				if self.report.list[parentKey].reports[childKey].disable == true then
					Dewdrop:AddLine(
						"text", "启用通报",
						"closeWhenClicked", true,
						"arg1", parentKey,
						"arg2", childKey,
						"func", function(parent, child)
							self:OnClickReportEnabledButton(parent, child)
						end
					)
				else
					Dewdrop:AddLine(
						"text", "禁用通报",
						"closeWhenClicked", true,
						"arg1", parentKey,
						"arg2", childKey,
						"func", function(parent, child)
							self:OnClickReportDisableButton(parent, child)
						end
					)
				end
				Dewdrop:AddLine(
					"text", "删除通报",
					"closeWhenClicked", true,
					"arg1", parentKey,
					"arg2", childKey,
					"func", function(parent, child)
						self:OnClickReportDeleteButton(parent, child)
					end
				)
			else
				-- 种类菜单
				Dewdrop:AddLine(
					"text", "新增通报",
					"closeWhenClicked", true,
					"arg1", parentKey,
					"func", function(parent)
						self:OnClickReportNewButton(parent)
					end
				)
			end
			Dewdrop:AddLine(
				"text", "关闭菜单",
				"closeWhenClicked", true
			)
		end
	)
end

---通报列表项单击
function OneMacroEditor:OnClickReportListItem()
	local parentKey, childKey = unpack(this.value)
	if childKey then
		-- 子级单击
		local path = parentKey .. "/" .. childKey
		if self.report.selected ~= path then
			self.report.selected = path
			self:UpdateReportListBox()
			self:SetReportEdit(parentKey, childKey)
		end
	else
		-- 父级单击
		self.report.list[parentKey].expand = not self.report.list[parentKey].expand
		self:UpdateReportListBox()
	end
end

---通报新增按钮单击
---@param parent string 父级标识
function OneMacroEditor:OnClickReportNewButton(parent)
	local dialog = "OneMacroEditor:OnClickReportNewButton"
	StaticPopupDialogs[dialog] = {
		text = "输入新增通报法术名：",
		button1 = ACCEPT,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		hasEditBox = true,
		maxLetters = 30,
		OnShow = function()
			getglobal(this:GetName() .. "EditBox"):SetFocus()
		end,
		OnHide = function()
			getglobal(this:GetName() .. "EditBox"):SetText("")
		end,
		OnAccept = function()
			local spell = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
			if spell ~= "" then
				OneMacro:RegisterReport(parent, spell, "通报：{KindName}.{ReportName}")
			end
		end,
	}
	StaticPopup_Show(dialog)
end

---通报启用按钮单击
---@param parent string 父级标识
---@param child string 子级标识
function OneMacroEditor:OnClickReportEnabledButton(parent, child)
	self.report.list[parent].reports[child].disable = false
	self:UpdateReportListBox()
end

---通报禁用按钮单击
---@param parent string 父级标识
---@param child string 子级标识
function OneMacroEditor:OnClickReportDisableButton(parent, child)
	self.report.list[parent].reports[child].disable = true
	self:UpdateReportListBox()
end

---通报删除按钮单击
---@param parent string 父级标识
---@param child string 子级标识
function OneMacroEditor:OnClickReportDeleteButton(parent, child)
	self.report.list[parent].reports[child] = nil
	self:UpdateReportListBox()
end

---通报重置按钮单击
function OneMacroEditor:OnClickReportResetButton()
	local parent, child = self:GetReportSelected()
	if parent and child then
		self:SetReportEdit(parent, child)
	else
		self:SetReportEdit()
	end
end

---通报保存按钮单击
function OneMacroEditor:OnClickReportSaveButton()
	-- 组件前缀
	local prefix = table.concat({
		"OneMacroEditorFrame",
		"TabFrame5",
		"RightGroupBox",
	})

	-- 种类组合框
	local kindComboBox = getglobal(prefix .. "KindComboBox")
	local kind = UIDropDownMenu_GetSelectedValue(kindComboBox)

	-- 名称编辑框
	local nameEditBox = getglobal(prefix .. "NameEditBox")
	local name = nameEditBox:GetText()
	if name == "" then
		local dialog = "OneMacroEditor:OnClickReportSaveButton1"
		StaticPopupDialogs[dialog] = {
			text = "请输入通报名称！",
			button1 = OKAY,
			timeout = 0,
			exclusive = true,
			whileDead = true,
			hideOnEscape = true1
		}
		StaticPopup_Show(dialog)
		nameEditBox:SetFocus()
		return
	end

	-- 消息编辑框
	local messageEditBox = getglobal(prefix .. "MessageEditBox")
	local message = messageEditBox:GetText()
	if message == "" then
		local dialog = "OneMacroEditor:OnClickReportSaveButton2"
		StaticPopupDialogs[dialog] = {
			text = "请输入通报消息！",
			button1 = OKAY,
			timeout = 0,
			exclusive = true,
			whileDead = true,
			hideOnEscape = true1
		}
		StaticPopup_Show(dialog)
		messageEditBox:SetFocus()
		return
	end

	-- 方式组合框
	local modeComboBox = getglobal(prefix .. "ModeComboBox")
	local mode = UIDropDownMenu_GetSelectedValue(modeComboBox)

	-- 禁用复选框
	local disableCheckBox = getglobal(prefix .. "DisableCheckBox")
	local disable = disableCheckBox:GetChecked() ~= nil -- 数值转布尔

	-- 备注编辑框
	local remarkEditBox = getglobal(prefix .. "RemarkEditBox")
	local remark = remarkEditBox:GetText() or ""

	-- 保存通报
	self.report.list[kind].reports[name] = {
		message = message,
		mode = mode,
		disable = disable,
		remark = remark,
	}

	-- 更新列表框
	self:UpdateReportListBox()
end

---取通报选中
---@return string parent? 父级标识
---@return string child? 子级标识
function OneMacroEditor:GetReportSelected()
	if self.report.selected then
		local parent, child = string.match(self.report.selected, "([^/]+)/([^/]+)")
		return parent, child
	end
end

---置通报编辑
---@param parent? string 父级标识
---@param child? string 子级标识
function OneMacroEditor:SetReportEdit(parent, child)
	-- 组件前缀
	local prefix = table.concat({
		"OneMacroEditorFrame",
		"TabFrame5",
		"RightGroupBox",
	})

	-- 种类组合框
	local kindComboBox = getglobal(prefix .. "KindComboBox")
	UIDropDownMenu_Initialize(kindComboBox, function()
		-- 升序键名
		local keys = Array:GetOrders(self.report.list, function(a, b)
			return (a.data.order or 0) < (b.data.order or 0)
		end)

		-- 添加下拉项
		for _, key in ipairs(keys) do
			local item = self.report.list[key]
			UIDropDownMenu_AddButton({
				text = item.name,
				value = key,
				func = function()
					UIDropDownMenu_SetSelectedValue(kindComboBox, this.value)
				end,
			})
		end
	end)

	-- 恢复种类选中项
	if parent then
		UIDropDownMenu_SetSelectedValue(kindComboBox, parent)
	end

	-- 名称编辑框
	local nameEditBox = getglobal(prefix .. "NameEditBox")
	if parent and child then
		nameEditBox:SetText(child)
	else
		nameEditBox:SetText("")
	end

	-- 消息编辑框
	local messageEditBox = getglobal(prefix .. "MessageEditBox")
	if parent and child then
		messageEditBox:SetText(self.report.list[parent].reports[child].message or "")
	else
		messageEditBox:SetText("")
	end

	-- 方式组合框
	local modeComboBox = getglobal(prefix .. "ModeComboBox")
	UIDropDownMenu_Initialize(modeComboBox, function()
		-- 方式
		local list = {
			{
				value = "SAY",
				text = "说",
			},
			{
				value = "YELL",
				text = "大喊",
			},
			{
				value = "PARTY",
				text = "小队",
			},
			{
				value = "RAID",
				text = "团队",
			},
			{
				value = "PRINT",
				text = "打印",
			},
			{
				value = "PROMPT",
				text = "提示",
			},
		}

		-- 添加下拉项
		for _, item in ipairs(list) do
			UIDropDownMenu_AddButton({
				text = item.text,
				value = item.value,
				func = function()
					UIDropDownMenu_SetSelectedValue(modeComboBox, this.value)
				end,
			})
		end
	end)

	-- 恢复方式选中项
	if parent and child then
		UIDropDownMenu_SetSelectedValue(modeComboBox, self.report.list[parent].reports[child].mode)
	end

	-- 禁用复选框
	local disableCheckBox = getglobal(prefix .. "DisableCheckBox")
	if parent and child then
		disableCheckBox:SetChecked(self.report.list[parent].reports[child].disable)
	else
		disableCheckBox:SetChecked(false)
	end

	-- 备注编辑框
	local remarkEditBox = getglobal(prefix .. "RemarkEditBox")
	if parent and child then
		remarkEditBox:SetText(self.report.list[parent].reports[child].remark or "")
	else
		remarkEditBox:SetText("")
	end
end

----------------------------------------------------------------------------------------------

---自述编辑框显示
function OneMacroEditor:OnShowReadmeEditBox()
	local editBox = getglobal(this:GetName() .. "EditBox")
	--editBox:ClearFocus()
	--editBox:EnableMouse(false)
	--editBox:SetTextColor(0.5, 0.5, 0.5)
	--this:EnableMouse(false)
	editBox:SetText(table.concat({
		OneMacro.title,
		OneMacro.notes,
		"",
		"版本：" .. OneMacro.version,
		"作者：" .. OneMacro.author,
		"邮箱：" .. OneMacro.email,
		"网站：" .. OneMacro.website,
		"",
		"如有建议或错误请至 https://gitee.com/ku-ba/OneMacro/issues 反馈！"
	}, "\n"))
end
