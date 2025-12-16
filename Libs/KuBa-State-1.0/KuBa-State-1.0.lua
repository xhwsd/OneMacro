--[[
Name: KuBa-State-1.0
Revision: $Rev: 10001 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://gitee.com/ku-ba
Description: 状态（生命、法力等）相关库。
Dependencies: AceLibrary, KuBa-Buff-1.0
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-State-1.0"
-- 次要版本
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
	"KuBa-Buff-1.0",
})

---状态（生命、法力等）相关库。
---@class KuBa-State-1.0
local Library = {}

--------------------------------

---取生命
---@param unit? string 单位；缺省为`player`
---@return number? health 生命
---@return number? max 上限
function Library:GetHealth(unit)
	unit = unit or "player"
	return UnitHealth(unit), UnitHealthMax(unit)
end

---取生命百分比
---@param unit? string 单位；缺省为`player`
---@return number? percentage 百分比
---@return number? health 生命
---@return number? max 上限
function Library:GetHealthPercentage(unit)
	unit = unit or "player"
	local health, max = self:GetHealth(unit)
	if health and max then
		-- 百分比 = 部分 / 整体 * 100
		return math.floor(health / max * 100), current, max
	end
end

---取生命损失
---@param unit? string 单位；缺省为`player`
---@return number? lose 损失
---@return number? health 生命
---@return number? max 上限
function Library:GetHealthLose(unit)
	unit = unit or "player"
	local health, max = self:GetHealth(unit)
	if health and max then
		return max - health, health, max
	end
end

---取生命损失百分比
---@param unit? string 单位；缺省为`player`
---@return number? percentage 百分比
---@return number? lose 损失
---@return number? health 生命
---@return number? max 上限
function Library:GetHealthLosePercentage(unit)
	unit = unit or "player"
	local lose, health, max = self:GetHealthLose(unit)
	if health and max then
		-- 百分比 = 部分 / 整体 * 100
		return math.floor(lose / max * 100), lose, health, max
	end
end

---取法力；仅限德鲁伊、猎人、法师、圣骑士、牧师、萨满祭司、术士
---@param unit string? 单位；缺省为`player`
---@return number? mana 法力
---@return number? max 上限
function Library:GetMana(unit)
	unit = unit or "player"
	if UnitPowerType(unit) == 0 then -- 法力
		return UnitMana(unit), UnitManaMax(unit)
	elseif UnitIsUnit(unit, "player") and UnitClass("player") == "德鲁伊" then -- 职业
		-- v1.18.0 支持返回返回法力
		local _, mana = UnitMana(unit)
		local  _, max = UnitManaMax(unit)
		return mana, max
	end
end

---取法力百分比；仅限德鲁伊、猎人、法师、圣骑士、牧师、萨满祭司、术士
---@param unit? string 单位；缺省为`player`
---@return number? percentage 百分比
---@return number? lose 损失
---@return number? mana 法力
---@return number? max 上限
function Library:GetManaPercentage(unit)
	unit = unit or "player"
	local mana, max = self:GetMana(unit)
	if mana and max then
		-- 百分比 = 部分 / 整体 * 100
		return math.floor(mana / max * 100), mana, max
	end
end

---取法力损失；仅限德鲁伊、猎人、法师、圣骑士、牧师、萨满祭司、术士
---@param unit? string 单位；缺省为`player`
---@return number? lose 损失
---@return number? mana 法力
---@return number? max 上限
function Library:GetManaLose(unit)
	unit = unit or "player"
	local mana, max = self:GetMana(unit)
	if mana and max then
		return max - mana, mana, max
	end
end

---取法力损失百分比；仅限德鲁伊、猎人、法师、圣骑士、牧师、萨满祭司、术士
---@param unit? string 单位；缺省为`player`
---@return number? percentage 百分比
---@return number? lose 损失
---@return number? mana 法力
---@return number? max 上限
function Library:GetManaLosePercentage(unit)
	unit = unit or "player"
	local lose, mana, max = self:GetManaLose(unit)
	if max then
		-- 百分比 = 部分 / 整体 * 100
		return math.floor(lose / max * 100), lose, mana, max
	end
end

---取怒气；仅限德鲁伊、战士
---@param unit? string 单位；缺省为`player`
---@return number? rage 怒气
---@return number? max 上限
function Library:GetRage(unit)
	unit = unit or "player"
	if UnitPowerType(unit) == 1 then -- 怒气（德鲁伊会随形态返回）
		return UnitMana(unit), UnitManaMax(unit)
	elseif UnitClass(unit) == "德鲁伊" then -- 职业
		if Buff:FindBuff("*熊形态", unit) then
			return UnitMana(unit), UnitManaMax(unit)
		else
			return 0, 100
		end
	end
end     

---取能量；仅限德鲁伊、盗贼
---@param unit? string 单位；缺省为`player`
---@return number? energy 能量
---@return number? max 上限
function Library:GetEnergy(unit)
	unit = unit or "player"
	if UnitPowerType(unit) == 3 then -- 能量（德鲁伊会随形态返回）
		return UnitMana(unit), UnitManaMax(unit)
	elseif UnitClass(unit) == "德鲁伊" then -- 职业
		if Buff:FindBuff("猎豹形态", unit) then
			return UnitMana(unit), UnitManaMax(unit)
		else
			return 100, 100
		end
	end
end

--------------------------------

---库激活
---@param self table 库自身对象
---@param oldLib table 旧版库对象
---@param oldDeactivate function 旧版库停用函数
local function activate(self, oldLib, oldDeactivate)
	-- 新版本使用
	Library = self

	-- 旧版本释放
	if oldLib then
		-- ...
	end

	-- 新版本初始化
	-- ...

	-- 旧版本停用
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