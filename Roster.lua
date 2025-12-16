---@class Roster:AceAddon-2.0 名单模块 xhwsd@qq.com 2025-6-27
OneMacroRoster = OneMacro:NewModule("Roster")

-- 列表大小
local LIST_SIZE = 10

--[[ 依赖 ]]

local RosterLib = AceLibrary("RosterLib-2.0")
local Array = AceLibrary("KuBa-Array-1.0")
local Prompt = AceLibrary("KuBa-Prompt-1.0")
local Target = AceLibrary("KuBa-Target-1.0")

--[[ 事件 ]]

---初始化
function OneMacroRoster:OnInitialize()
	-- 名单资料，会固化数据
	self.roster = OneMacro.db.profile.roster
end

---启用
function OneMacroRoster:OnEnable()
	-- 恢复窗口显示
	if self.roster.show then
		self:Show()
	end
end

---禁用
function OneMacroRoster:OnDisable()

end

---框架显示
function OneMacroRoster:OnShowFrame()
	self.roster.show = true
end

---框架隐藏
function OneMacroRoster:OnHideFrame()
	self.roster.show = false
end

---框架更新
function OneMacroRoster:OnUpdateFrame()
	-- 取上下按钮
	local prefix = this:GetName()
	local upButton = getglobal(prefix .. "UpButton")
	local downButton = getglobal(prefix .. "DownButton")

	-- 显示隐藏上下按钮
	local count = table.getn(self.roster.list)
	if count <= LIST_SIZE then
		-- 不足多页，隐藏滚动按钮
		this.offset = 0
		upButton:Hide()
		downButton:Hide()
	else
		if this.offset <= 0 then
			-- 第一项，隐藏上移和显示下移按钮
			this.offset = 0
			upButton:Hide()
			downButton:Show()
		elseif this.offset >= count - LIST_SIZE then
			-- 最后项，显示上移和隐藏下移按钮
			this.offset = count - LIST_SIZE
			upButton:Show()
			downButton:Hide()
		else
			-- 中间项，显示上移和下移按钮
			upButton:Show()
			downButton:Show()
		end
	end

	-- 显示隐藏项按钮
	for index = 1, LIST_SIZE do
		local itemButton = getglobal(prefix .. "ItemButton" .. index)
		itemButton:SetID(index + this.offset)
		itemButton.update = true
		if index <= count then
			itemButton:Show()
		else
			itemButton:Hide()
		end
	end
end

---加入按钮单击
function OneMacroRoster:OnClickJoinButton()
	-- 限可协助（治疗、施加增益等）目标
	if UnitCanAssist("player", "target") then
		local name = UnitName("target")
		if Array:InList(self.roster.list, name) then
			Prompt:Warning("<%s>已在名单中", name)
		else
			table.insert(self.roster.list, name)
			OneMacroRosterFrame.update = true
			Prompt:Info("已将<%s>加入名单", name)
		end
	else
		Prompt:Error("请选择可协助目标")
	end
end

---清空按钮单击
function OneMacroRoster:OnClickClearButton()
	self.roster.list = {}
	OneMacroRosterFrame.update = true
	Prompt:Info("已清空名单")
end

---项按钮更新
function OneMacroRoster:OnUpdateItemButton()
	local nameText = getglobal(this:GetName() .. "NameText")
	local index = tonumber(this:GetID())
	local name = self.roster.list[index]
	if name then
		nameText:SetText(index .. " " .. name)
	else
		nameText:SetText(index .. "索引异常")
	end
end

---项按钮单击
function OneMacroRoster:OnClickItemButton()
	local index = tonumber(this:GetID())
	local name = self.roster.list[index]
	if name then
		table.remove(self.roster.list, index)
		OneMacroRosterFrame.update = true
		Prompt:Info("已将<%s>移出名单", name)
	else
		Prompt:Warning("索引<%d>异常", index)
	end
end

--[[ 方法 ]]

---是否可见
---@return boolean visible 可见
function OneMacroRoster:IsVisible()
	return OneMacroRosterFrame:IsVisible()
end

---显示
function OneMacroRoster:Show()
	OneMacroRosterFrame:Show()
end

---隐藏
function OneMacroRoster:Hide()
	OneMacroRosterFrame:Hide()
end

---切换显示
function OneMacroRoster:SwitchShow()
	if self:IsVisible() then
		self:Hide()
	else
		self:Show()
	end
end

---计数
---@return number quantity 数量
function OneMacroRoster:Count()
	return table.getn(self.roster.list)
end

---是否为单位
---@param unit string 单位; 格式为`rosterN`
---@return boolean isUnit 是否单位
function OneMacroRoster:isUnit(unit)
	return self:ToIndex(unit) ~= nil
end

---到索引
---@param unit string 单位; 格式为`rosterN`
---@return number? index 索引
function OneMacroRoster:ToIndex(unit)
	if type(unit) == "string" and unit ~= "" then
		local index = string.match(unit, "^roster(%d+)$")
		if index then
			index = tonumber(index)
			if self.roster.list[index] then
				return index
			end
		end
	end
	return nil
end

---到名称
---@param unit string 单位; 格式为`rosterN`
---@return string? name 名称
---@return number? index 索引；是名单单位时非`nil`
function OneMacroRoster:ToName(unit)
	local index = self:ToIndex(unit)
	if index then
		return self.roster.list[index], index
	end
end

---到单位；名单单位到相对于队伍或团队的单位标识
---@param unit string 单位; 格式为`rosterN`
---@return string? unitId 单位；非团队、队伍、目标单位是为`nil`
---@return string? name 名称；是名单单位时非`nil`
function OneMacroRoster:ToUnit(unit)
	local name = self:ToName(unit)
	if name then
		return RosterLib:GetUnitIDFromName(name), name
	end
end

---切换到单位
---@param unit string 单位; 格式为`rosterN`
---@param handle function|string|table 处理；回调过程中`target`单位就是目标
---@param ... any 参数
---@return boolean success 成功；失败为`false`，后续返回值为错误信
---@return any ... 返回
function OneMacroRoster:SwitchTarget(unit, handle, ...)
	if type(unit) ~= "string" or unit == "" then
		return false, "单位无效"
	end

	local name = self:ToName(unit)
	if name then
		-- 优先尝试团队单位
		local unitId = RosterLib:GetUnitIDFromName(name)
		if unitId then
			return Target:SwitchUnit(unitId, handle, unpack(arg))
		else
			return Target:SwitchName(name, handle, unpack(arg))
		end
	end
	return false, "单位(" .. unit .. ")无效"
end
