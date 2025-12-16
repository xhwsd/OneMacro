--[[
Name: KuBa-Buff-1.0
Revision: $Rev: 10001 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://gitee.com/ku-ba
Description: 效果相关库。
Dependencies: AceLibrary, Gratuity-2.0, SpellCache-1.0
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-Buff-1.0"
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
	"Gratuity-2.0",
	-- 法术缓存
	"SpellCache-1.0",
})

-- 提示解析
local Gratuity = AceLibrary("Gratuity-2.0")
-- 法术缓存
local SpellCache = AceLibrary("SpellCache-1.0")

---效果相关库。
---@class KuBa-Buff-1.0
local Library = {}

--------------------------------

---查找增益效果
---@param name string 名称；支持匹配表达式
---@param unit? string 单位；缺省为`player`
---@return number? index 索引；从1开始
---@return string? text 文本
---@return number? layers 层数
---@return number? spell 法术
---@return string? texture 图标
function Library:FindBuff(name, unit)
	unit = unit or "player"
	local index = 1
	-- v1.18.0 返回法术ID https://luntan.turtle-wow.org/viewtopic.php?t=1571
	local texture, layers, spell = UnitBuff(unit, index)
	while texture do
		-- 匹配名称
		Gratuity:SetUnitBuff(unit, index)
		local text = Gratuity:GetLine(1)
		if text and string.find(text, name) then
			return index, text, layers, spell, texture
		end
		
		-- 取下一个
		index = index + 1
		texture, layers, spell = UnitBuff(unit, index)
	end
end

---查找减益效果
---@param name string 名称；支持匹配表达式
---@param unit? string 单位；缺省为`player`
---@return number? index 索引；从1开始
---@return string? text 文本
---@return number? layers 层数
---@return number? spell 法术
---@return string? texture 图标
---@return string? dispel 驱散；可选值：`Magic`、`Curse`、`Poison`、`Disease`
function Library:FindDebuff(name, unit)
	unit = unit or "player"
	local index = 1
	-- v1.18.0 返回法术ID https://luntan.turtle-wow.org/viewtopic.php?t=1571
	local texture, layers, dispel, spell = UnitDebuff(unit, index)
	while texture do
		-- 匹配名称
		Gratuity:SetUnitDebuff(unit, index)
		local text = Gratuity:GetLine(1)
		if text and string.find(text, name) then
			return index, text, layers, spell, texture, dispel
		end

		-- 取下一个
		index = index + 1
		texture, layers, dispel, spell = UnitDebuff(unit, index)
	end
end

---查找主手效果
---@param name string 名称；支持匹配表达式
---@return number? index 索引；从1开始
---@return string? text 文本
function Library:FindMainhand(name)
	Gratuity:SetInventoryItem("player", 16)
	for index = 1, Gratuity:NumLines() do
		local text = Gratuity:GetLine(index)
		if text and string.find(text, name) then
			return index, text
		end
	end
end

---查找副手效果
---@param name string 名称；支持匹配表达式
---@return number? index 索引；从1开始
---@return string? text 文本
function Library:FindOffhand(name, unit)
	Gratuity:SetInventoryItem("player", 17)
	for index = 1, Gratuity:NumLines() do
		local text = Gratuity:GetLine(index)
		if text and string.find(text, name) then
			return index, text
		end
	end
end

---查找单位效果
---@param name string 名称；支持匹配表达式
---@param unit? string 单位；缺省为`player`，当为`player`时会检测主副手
---@return string? kind 类型；可选值：`buff`、`debuff`、`mainhand`、`offhand`
---@return number? index 索引；从1开始
---@return string? text 文本
function Library:FindUnit(name, unit)
	unit = unit or "player"
	
	-- 增益
	local index, text = self:FindBuff(name, unit)
	if index then
		return "buff", index, text
	end

	-- 减益
	index, text = self:FindDebuff(name, unit)
	if index then
		return "debuff", index, text
	end

	-- 单位为自身
	if UnitIsUnit(unit, "player") then
		-- 主手
		index, text = self:FindMainhand(name)
		if index then
			return "mainhand", index, text
		end

		-- 副手
		index, text = self:FindOffhand(name)
		if index then
			return "offhand", index, text
		end
	end
end

---取效果层数
---@param name string 名称；支持匹配表达式
---@param unit string? 单位；缺省为`player`
---@return number? layers 层数
---@return number? index 索引；从1开始
---@return string? text 文本
---@return string? kind 种类；可选值：`buff`、`debuff`
function Library:GetLayers(name, unit)
	unit = unit or "player"

	-- 增益
	local index, text, layers = self:FindBuff(name, unit)
	if index then
		return layers, index, text, "buff"
	end
	
	-- 减益
	index, text, layers = self:FindDebuff(name, unit)
	if index then
		return layers, index, text, "debuff"
	end
end

---取效果法术标识
---@param name string 名称；支持匹配表达式
---@param unit string? 单位；缺省为`player`
---@return number? spell 法术
---@return number? index 索引；从1开始
---@return string? text 文本
---@return string? kind 种类；可选值：`buff`、`debuff`
function Library:GetSpell(name, unit)
	unit = unit or "player"

	-- 增益
	local index, text, _, spell = self:FindBuff(name, unit)
	if index then
		return spell, index, text, "buff"
	end

	-- 减益
	index, text, _, spell = self:FindDebuff(name, unit)
	if index then
		return spell, index, text, "debuff"
	end
end

---取效果法术级别；依赖`SuperWoW`模组
---@param name string 名称；支持匹配表达式
---@param unit string? 单位；缺省为`player`
---@return number? level 级别
---@return number? spell 法术
---@return number? index 索引；从1开始
---@return string? kind 种类；可选值：`buff`、`debuff`
function Library:GetLevel(name, unit)
	if SUPERWOW_VERSION then
		unit = unit or "player"
		local spell, index, kind = self:GetSpell(name, unit)
		if spell then
			-- SuperWoW函数
			-- 名称, 等级, 纹理，最小范围, 最大范围
			local _, rank = SpellInfo(spell)
			if rank then
				return SpellCache:GetRankNumber(rank), spell, index, kind
			end
		end
	end
end

---取减益效果驱散类型
---@param name string 名称；支持匹配表达式
---@param unit string? 单位；缺省为`player`
---@return string? dispel 驱散；可选值：`Magic`、`Curse`、`Poison`、`Disease`
---@return number? index 索引；从1开始
---@return string? text 文本
function Library:GetDispel(name, unit)
	unit = unit or "player"
	local index, text, _, _, _, dispel = self:FindDebuff(name, unit)
	if index then
		return dispel, index, text
	end
end

---查找自身效果；会检测到因`SuperWoW`模组而显示的效果
---@param name string 名称；支持匹配表达式
---@return number? index 索引；从1开始
---@return string? text 文本
---@return boolean? cancel 取消
function Library:FindPlayer(name)
	-- 确认 buffId 从0开
	for id = 0, 64 do
		-- https://warcraft.wiki.gg/wiki/API_GetPlayerBuff?oldid=3951140
		local index, cancel = GetPlayerBuff(id)
		-- 确认 buffIndex 从0开始
		if index >= 0 then
			-- https://warcraft.wiki.gg/wiki/API_GameTooltip_SetPlayerBuff
			-- 注意该函数会检测到因使用`SuperWoW`模组而的显示效果
			Gratuity:SetPlayerBuff(index)
			local text = Gratuity:GetLine(1)
			if text and string.find(text, name) then
				return index, text, cancel == 1
			end
		end
	end
end

---取效果剩余秒数
---@param name string 名称；支持匹配表达式
---@return number? seconds 秒数；直到取消的为-1
---@return number? index 索引；从1开始
---@return string? text 文本
function Library:GetSeconds(name)
	local index, text, cancel = self:FindPlayer(name)
	if index then
		local seconds = -1
		if not cancel then
			seconds = GetPlayerBuffTimeLeft(index)
		end
		return seconds, index, text
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