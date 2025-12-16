--[[
Name: KuBa-Action-1.0
Revision: $Rev: 10001 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://gitee.com/ku-ba
Description: 动作条相关库。
Dependencies: AceLibrary, Gratuity-2.0, SpellCache-1.0, KuBa-Target-1.0
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-Action-1.0"
--次要版本
local MINOR_VERSION = "$Revision: 10001 $"

-- 检验AceLibrary
if not AceLibrary then
	error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
	return
end

---检查依赖库
---@param dependencies table 依赖库名称列表
local function CheckDependency(dependencies)
	for _, value in ipairs(dependencies) do
		if not AceLibrary:HasInstance(value) then 
			error(format("%s requires %s to function properly", MAJOR_VERSION, value))
		end
	end
end

CheckDependency({
	-- 提示解析
	"Gratuity-2.0",
	-- 法术缓存
	"SpellCache-1.0",
	-- 目标切换
	"KuBa-Target-1.0",
})

-- 引入依赖库
local Gratuity = AceLibrary("Gratuity-2.0")
local SpellCache = AceLibrary("SpellCache-1.0")
local Target = AceLibrary("KuBa-Target-1.0")

---动作条相关库。
---@class KuBa-Action-1.0
local Library = {}

--------------------------------

---检验值是否包含于索引数组中
---@param list any 列表
---@param value any 值
---@return number? index 索引
local function InList(list, value)
	if type(list) == "table" then
		for index, data in ipairs(list) do
			if data == value then
				return index
			end
		end
	end
end

---检验插槽是否为宏
---@param slot number 插槽；从1开始
---@return boolean is 是否
function Library:IsMacro(slot)
	return type(slot) == "number"
		and HasAction(slot) -- 非空插槽
		and GetActionText(slot) ~= nil -- 有文本（是宏）
end

---检验插槽是否法术
---@param slot number 插槽；从1开始
---@return boolean is 是否
function Library:IsSpell(slot)
	return type(slot) == "number"
		and HasAction(slot) -- 非空插槽
		and not GetActionText(slot) -- 无文本（非宏）
		and not IsConsumableAction(slot) -- 非消耗品
		and not IsEquippedAction(slot) -- 非已佩戴装备
end

---检验插槽是否物品（装备或消耗品）
---@param slot number 插槽；从1开始
---@return boolean is 是否
function Library:IsItem(slot)
	return type(slot) == "number"
		and HasAction(slot) -- 非空插槽
		and not GetActionText(slot) -- 无文本（非宏）
		and (
			IsConsumableAction(slot) -- 消耗品
			or
			IsEquippedAction(slot) -- 已佩戴装备
		)
end

---取插槽法术
---@param slot number 插槽；从1开始
---@return string? name 名称
---@return string? rank 等级
---@return number? level 级别
function Library:GetSpell(slot)
	-- 仅限法术插槽
	if self:IsSpell(slot) then
		-- 取提示文本
		Gratuity:SetAction(slot)
		local spellName, spellRank = Gratuity:GetLine(1), Gratuity:GetLine(1, true)
		if spellName then
			-- 取法术数据
			local name, rank, _, _, level = SpellCache:GetSpellData(spellName, spellRank)
			return name, rank, level
		end
	end
end

---查找法术在动作条的插槽
---@param spells table|string 法术；无视等级
---@return number? slot 插槽；可选值：1~120
---@return string? spell 法术
function Library:FindSpell(spells)
	-- 统一转为表
	if type(spells) == "string" then
		spells = { spells }
	elseif type(spells) ~= "table" then
		return
	end
	
	-- 取法术名
	local names = {}
	for _, spell in ipairs(spells) do
		spell = SpellCache:GetSpellData(spell)
		if spell then
			table.insert(names, spell)
		end
	end
	if table.getn(names) == 0 then
		return
	end

	-- 从缓存取
	if not self.caches then
		-- 初始缓存
		self.caches = {}
	else
		for _, name in ipairs(names) do
			if self.caches[name] then
				-- 检验插槽
				if self:GetSpell(self.caches[name]) == name then
					return self.caches[name], name
				else
					self.caches[name] = nil
				end
			end
		end
	end

	-- 查找插槽
	for slot = 1, 120 do
		-- 取插槽法术
		local name = self:GetSpell(slot)
		if name then
			-- 缓存法术
			self.caches[name] = slot

			-- 匹配法术
			if InList(names, name) then
				return slot, name
			end
		end
	end
end

---查找空插槽
---@param asc boolean? 升序
---@return number? slot 插槽；可选值：1~120
function Library:FindEmpty(asc)
	if asc then
		for slot = 1, 120 do
			if not HasAction(slot) then
				return slot
			end
		end
	else
		for slot = 120, 1, -1 do
			if not HasAction(slot) then
				return slot
			end
		end
	end
end

---放置法术
---@param spellIndex number 法术索引
---@param slot number? 插槽；缺省为空插槽，可选值：1~120
---@return number? slot 插槽
function Library:PlaceSpell(spellIndex, slot)
	if type(spellIndex) ~= "number" or spellIndex <= 0 then
		return
	end

	slot = slot or self:FindEmpty()
	if slot then
		ClearCursor()
		PickupSpell(spellIndex, BOOKTYPE_SPELL)
		PlaceAction(slot)
		ClearCursor()
		return slot
	end
end

---检验是否在插槽法术范围
---@param slot number
---@param unit string? 单位；缺省为`target`
---@return boolean range 范围
function Library:IsRange(slot, unit)
	unit = unit or "target"

	-- 空插槽
	if not HasAction(slot) then
		return false
	end

	-- 检验单位
	if not UnitExists(unit) then
		return false
	end

	-- 单位是自身
	if UnitIsUnit(unit, "player") then
		return true
	end

	-- 检验范围
	local success, result = Target:SwitchUnit(unit, IsActionInRange, slot)
	return success and result == 1
end

--------------------------------

---库激活
---@param self table 库自身对象
---@param oldLib table 旧版库对象
---@param oldDeactivate function 旧版库停用函数
local function activate(self, oldLib, oldDeactivate)
	-- 使用新版本
	Library = self

	if oldLib then
		-- 旧版本施放操作
		-- 旧版本数据传递到新版本
		-- ...
	end

	-- 新版本初始化
	-- ...

	-- 停用旧版本
	if oldDeactivate then
		oldDeactivate(oldLib)
	end
end

---外部库加载
---@param self table 库自身对象
---@param major string 外部库主版本
---@param instance table 外部库实例
local function external(self, major, instance)

end

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line
Library = nil