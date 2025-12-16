--[[
Name: KuBa-Boss-1.0
Revision: $Rev: 10001 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://gitee.com/ku-ba
Description: 是否是首领相关库。
Dependencies: AceLibrary
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-Boss-1.0"
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

---是否是首领相关库。
---@class KuBa-Boss-1.0
local Library = {}

--------------------------------

-- 首领名称
local BOOSS_NAMES = {
	["克尔苏加德"] = true,
	["拉格纳罗斯"] = true,
}

---是否为BOSS
---@param unit? string 单位名称；缺省为`target`
---@param health? number 血量；缺省为`100000`
---@return boolean is 是否是BOSS
function Library:Is(unit, health)
	unit = unit or "target"
	health = health or 100000

	-- 检查分类
	local class = UnitClassification(unit)
	if class == "worldboss" or class == "rareelite" then
        -- 世界首领或稀有精英
		return true
	end

	-- 检查名字
	local name = UnitName(unit)
	if BOOSS_NAMES[name] then
		return true
	end

	-- 检查血量（普通BOSS通常血量远高于玩家）
	local max = UnitHealthMax(unit)
	if max > health then
		return true
	end
	return false
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