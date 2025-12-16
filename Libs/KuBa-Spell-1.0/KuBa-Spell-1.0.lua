--[[
Name: KuBa-Spell-1.0
Revision: $Rev: 10001 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://gitee.com/ku-ba
Description: 法术相关库。
Dependencies: AceLibrary, Gratuity-2.0, SpellCache-1.0, KuBa-Action-1.0
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-Spell-1.0"
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
	-- 动作条
	"KuBa-Action-1.0",
	-- 目标切换
	"KuBa-Target-1.0",
})

-- 引入依赖库
local Gratuity = AceLibrary("Gratuity-2.0")
local SpellCache = AceLibrary("SpellCache-1.0")
local Action = AceLibrary("KuBa-Action-1.0")
local Target = AceLibrary("KuBa-Target-1.0")

---法术相关库。
---@class KuBa-Spell-1.0
local Library = {}

--------------------------------

-- 持续时间匹配文本
local DURATION_PATTERNS = {
	-- 腐蚀术：腐蚀目标，在18.69秒内造成累计828到834点伤害。
	-- 虫群：敌人被飞虫围绕，攻击命中率降低2%，在18秒内受到总计99点自然伤害。
	"在(%d+%.?%d*)秒",
	-- 精灵之火：使目标的护甲降低175点，持续40秒。在效果持续期间，目标无法潜行或隐形。
	-- 驱毒术：尝试驱散目标身上的1个中毒效果，并每2秒驱散1个中毒效果，持续8秒。
	"持续(%d+%.?%d*)秒",
}

-- 治疗匹配文本
local HEAL_PATTERNS = {
	-- 治疗之触：治疗友方目标，恢复958到1143点生命值。
	".+治疗.+",
	-- 治疗之触11：为友方目标回复2267到2677点生命值。
	".+目标回复.+",
}

-- 最少治疗量匹配文本
local MIN_HEAL_PATTERNS = {
	-- 圣光术：治疗友方目标，恢复42到51点生命值。
	-- 圣光闪现：治疗友方目标，恢复67到77点生命值。
	-- 治疗波：治疗友方目标，恢复36到47点生命值。
	-- 愈合：治疗友方目标，恢复1003到1119点生命值，并在21秒内恢复额外的1064点生命值。
	-- 治疗之触：治疗友方目标，恢复958到1143点生命值。
	"恢复(%d+)",
	-- 治疗之触11：为友方目标回复2267到2677点生命值。
	"回复(%d+)",
}

-- 最多治疗量匹配文本
local MAX_HEAL_PATTERNS = {
	-- 圣光术：治疗友方目标，恢复42到51点生命值。
	-- 圣光闪现：治疗友方目标，恢复67到77点生命值。
	-- 治疗波：治疗友方目标，恢复36到47点生命值。
	-- 愈合：治疗友方目标，恢复1003到1119点生命值，并在21秒内恢复额外的1064点生命值。
	-- 治疗之触：治疗友方目标，恢复958到1143点生命值。
	"恢复%d+到(%d+)点",
	-- 治疗之触11：为友方目标回复2267到2677点生命值。
	"回复%d+到(%d+)点",
}

-- 最少恢复量匹配文本
local MIN_RESTORE_PATTERNS = {
	-- 回春术：治疗目标，在12秒内恢复总计888点生命值。
	-- 回春术：治疗目标，在12秒内恢复总计32到36点生命值。
	"恢复总计(%d+)",
	-- 愈合：治疗友方目标，恢复1003到1119点生命值，并在21秒内恢复额外的1064点生命值。
	-- 愈合：治疗友方目标，恢复102到118点生命值，并在21秒内恢复额外的105到112点生命值。
	"恢复额外的(%d+)",
}

-- 最多恢复量匹配文本
local MAX_RESTORE_PATTERNS = {
	-- 回春术：治疗目标，在12秒内恢复总计888点生命值。
	-- 回春术：治疗目标，在12秒内恢复总计32到36点生命值。
	"恢复总计%d+到(%d+)点",
	-- 愈合：治疗友方目标，恢复1003到1119点生命值，并在21秒内恢复额外的1064点生命值。
	-- 愈合：治疗友方目标，恢复102到118点生命值，并在21秒内恢复额外的105到112点生命值。
	"恢复额外的%d+到(%d+)点",
}

-- 消耗匹配文本
local CONSUME_PATTERNS = {
	"(%d+)(法力值)",
	"(%d+)(能量)",
	"(%d+)(怒气)",
}

---多模式匹配文本
---@param text string 文本
---@param patterns string[] 模式
---@return any ... 捕获
local function TextMatchs(text, patterns)
	if type(text) == "string" and type(patterns) == "table" then
		-- 遍历模式
		for _, pattern in ipairs(patterns) do
			local results = { string.match(text, pattern) }
			-- 检验结果
			if next(results) ~= nil then
				return unpack(results)
			end
		end
	end
end

---多模式查找文本
---@param text string 文本
---@param patterns string[] 模式
---@return any ... 捕获
local function TextFinds(text, patterns)
	if type(text) == "string" and type(patterns) == "table" then
		-- 遍历模式
		for _, pattern in ipairs(patterns) do
			local results = { string.find(text, pattern) }
			-- 检验结果
			if next(results) ~= nil then
				return unpack(results)
			end
		end
	end
end

---取玩家与指定单位之间的距离
---@param unit? string 单位；缺省为`target`
---@return number? distance 距离
local function GetDistance(unit)
	unit = unit or "target"

	-- 取之间距离，依赖UnitXP模组 https://codeberg.org/konaka/UnitXP_SP3
	local success, distance = pcall(UnitXP, "distanceBetween", "player", unit)
	if success and distance then
		-- 成功为数值，失败为nil
		return distance
	end

	-- 基于三维坐标计算，依赖SuperWoW模组
	if SUPERWOW_VERSION and UnitIsFriend("player", unit) then
		-- 取友善单位相对世界绝对坐标 https://github.com/balakethelock/SuperWoW/wiki/Features
		local x1, y1, z1 = UnitPosition("player")
		local x2, y2, z2 = UnitPosition(unit)
		if x1 and y1 and z1 and x2 and y2 and z2 then
			distance = ((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2) ^ 0.5
			-- 减3点模型半径
			return distance - 3
		end
	end

	-- 基于二维坐标计算
	if UnitIsUnit(unit, "player") or UnitInRaid(unit) or UnitInParty(unit) then
		-- 取自身或队友相对当前地图缩放坐标
		local x1, y1 = GetPlayerMapPosition("player")
		local x2, y2 = GetPlayerMapPosition(unit)
		if x1 > 0 and y1 > 0 and x2 > 0 and y2 > 0 then
			return math.sqrt((x1 - x2) ^ 2 + (y1 - y2) ^ 2) * 1000
		end
	end
end

---查找法术
---@param name string 名称
---@param rank? number|string 等级；缺省或无效为最后等级
---@return number? index 索引
---@return string? string 名称
---@return string? rank 等级
function Library:FindSpell(name, rank)
	if type(name) ~= "string" or name == "" then
		return
	end

	-- 级别转等级
	if type(rank) == "number" then
		rank = "等级 " .. rank
	end

	local spellIndex = 1
	local lastIndex, lastName, lastRank
	while true do
		-- 取法术
		local spellName, spellRank = GetSpellName(spellIndex, BOOKTYPE_SPELL)
		if not spellName or spellName == "" or spellName == "充能点" then
			-- 已无法术
			break
		end

		-- 匹配名称
		if name == spellName then
			lastIndex = spellIndex
			lastName = spellName
			lastRank = spellRank

			-- 匹配等级
			if rank and rank == lastRank then
				break
			end
		elseif lastIndex then
			-- 已过最后等级
			break
		end

		-- 索引递增
		spellIndex = spellIndex + 1
	end

	if lastIndex then
		return lastIndex, lastName, lastRank
	end
end

---到法术索引；会优先从缓存获取，以便提升效率
---@param name string 名称
---@param rank? number|string 等级；缺省为最高
---@return number? index 索引
---@return string? string 名称
---@return string? rank 等级
function Library:ToIndex(name, rank)
	if type(name) ~= "string" or name == "" then
		return
	end

	-- 级别转等级
	if type(rank) == "number" then
		rank = "等级 " .. rank
	end

	-- 从缓存取
	local key = name .. (rank or "")
	if not self.caches then
		self.caches = {}
	elseif self.caches[key] then
		-- 检验法术
		local spellName, spellRank = GetSpellName(self.caches[key].index, BOOKTYPE_SPELL)
		if spellName == name and (not rank or spellRank == rank) then
			return self.caches[key].index, self.caches[key].name, self.caches[key].rank
		else
			self.caches[key] = nil
		end
	end

	-- 查找法术
	local spellIndex, spellName, spellRank = self:FindSpell(name, rank)
	if not spellIndex then
		return
	end

	-- 缓存法术
	self.caches[key] = {
		index = spellIndex,
		name = spellName,
		rank = spellRank,
	}
	return spellIndex, spellName, spellRank
end

---取法术最高等级
---@param name string 名称
---@return string? rank 等级
---@return number? level 级别
---@return number? index 索引
function Library:GetMax(name)
	-- 名称到索引
	local index, _, rank = self:ToIndex(name)
	if rank then
		return rank, SpellCache:GetRankNumber(rank), index
	end
end

---取法术冷却秒数
---@param name string 名称
---@return number? seconds 秒数
---@return number? start 开始
---@return number? duration 持续
function Library:GetCooldown(name)
	-- 名称到索引
	local index = self:ToIndex(name)
	if index then
		-- 取法术冷却
		local start, duration = GetSpellCooldown(index, BOOKTYPE_SPELL)
		if start and duration then
			-- 自然迅捷不影响冷却时间
			local seconds = (start > 0) and (start + duration - GetTime()) or 0
			return seconds, start, duration
		end
	end
end

---检验法术是否就绪
---@param name string 名称
---@return boolean ready 就绪
function Library:IsReady(name)
	-- 取冷却
	local seconds = self:GetCooldown(name)
	return seconds and seconds == 0 or false
end

---取描述文本
---@param index number 索引
---@return string? describe 描述
function Library:GetDescribe(index)
	if index and index > 0 then
		-- 取最后一行文本
		Gratuity:SetSpell(index, BOOKTYPE_SPELL)
		local lines = Gratuity:NumLines()
		if lines > 0 then
			local describe = Gratuity:GetLine(lines)
			return describe
		end
	end
end

---取效果持续秒数，如HOT或Debuff
---@param name string 名称
---@param rank? number|string 等级；缺省为最高
---@return number? seconds 秒数
function Library:GetDuration(name, rank)
	-- 名称到索引
	local index = self:ToIndex(name, rank)
	if index then
		-- 取描述文本
		local describe = self:GetDescribe(index)
		if describe then
			-- 匹配描述
			local seconds = TextMatchs(describe, DURATION_PATTERNS)
			if seconds then
				return tonumber(seconds)
			end
		end
	end
end

---检验指定法术是否在治疗法术（包含恢复）
---@param name string 名称
---@return boolean is 是否
function Library:IsHeal(name)
	-- 名称到索引
	local index = self:ToIndex(name)
	if index then
		-- 取描述文本
		local describe = self:GetDescribe(index)
		if describe then
			-- 匹配描述
			local start = TextFinds(describe, HEAL_PATTERNS)
			return start ~= nil
		end
	end
end

---取直接治疗量
---@param name string 名称
---@param rank? number|string 等级；缺省为最高
---@return number? min 最少
---@return number? max 最多
function Library:GetHeal(name, rank)
	-- 名称到索引
	local index = self:ToIndex(name, rank)
	if index then
		-- 取描述文本
		local describe = self:GetDescribe(index)
		if describe then
			-- 匹配最少
			local min = TextMatchs(describe, MIN_HEAL_PATTERNS)
			if min then
				min = tonumber(min)
			end

			-- 匹配最多
			local max = TextMatchs(describe, MAX_HEAL_PATTERNS)
			if max then
				max = tonumber(max)
			end
			return min, max
		end
	end
end

---取治疗恢复量（HOT）
---@param name string 名称
---@param rank? number|string 等级；缺省为最高
---@return number? min 最小
---@return number? max 最多
function Library:GetRestore(name, rank)
	-- 名称到索引
	local index = self:ToIndex(name, rank)
	if index then
		-- 取描述文本
		local describe = self:GetDescribe(index)
		if describe then
			-- 匹配最少
			local min = TextMatchs(describe, MIN_RESTORE_PATTERNS)
			if min then
				min = tonumber(min)
			end

			-- 匹配最多
			local max = TextMatchs(describe, MAX_RESTORE_PATTERNS)
			if max then
				max = tonumber(max)
			end
			return min, max
		end
	end
end

---取法术消耗(法力值、怒气、能量)
---@param name string 名称
---@param rank? number|string 等级；缺省为最高等级
---@return number? consume 消耗，注意节能施法时为`nul`
---@return string? kind 种类；可选值：法力值、怒气、能量
function Library:GetConsume(name, rank)
	-- 名称到索引
	local index = self:ToIndex(name, rank)
	if index then
		-- 从第二行至倒数第二行查找
		Gratuity:SetSpell(index, BOOKTYPE_SPELL)
		if Gratuity:NumLines() > 2 then
			local _, _, text = Gratuity:MultiFind(2, Gratuity:NumLines() - 1, false, false, unpack(CONSUME_PATTERNS))
			if text then
				return tonumber(consume), kind
			end
		end
	end
end

---取法术范围距离
---@param name string 名称
---@param rank? number|string 等级；缺省为最高等级
---@return number? distance 距离
function Library:GetRange(name, rank)
	-- 名称到索引
	local index = self:ToIndex(name, rank)
	if index then
		-- 从第二行至倒数第二行查找
		Gratuity:SetSpell(index, BOOKTYPE_SPELL)
		if Gratuity:NumLines() > 2 then
			local _, _, text = Gratuity:Find("(%d+%.?%d*)码距离", 2, Gratuity:NumLines() - 1)
			if text then
				return tonumber(distance)
			end
		end
	end
end

---取法术施法秒数
---@param name string 名称
---@param rank? number|string 等级；缺省为最高
---@return number? seconds 秒数
function Library:GetCasting(name, rank)
	-- 名称到索引
	local index = self:ToIndex(name, rank)
	if index then
		-- 从第二行至倒数第二行查找
		Gratuity:SetSpell(index, BOOKTYPE_SPELL)
		if Gratuity:NumLines() > 2 then
			local _, _, text = Gratuity:Find("(%d+%.?%d*)秒施法时间", 2, Gratuity:NumLines() - 1)
			if text then
				return tonumber(seconds)
			end
		end
	end
end

---是否在法术范围；将尝试使用nampower、UnitXP、动作条探测，如有必要将放置首个法术到动作条
---@param spells table|string 法术；无视等级
---@param unit? string 单位；缺省为`target`
---@return boolean range 范围
function Library:IsRange(spells, unit)
	unit = unit or "target"

	-- 检验单位
	if not UnitExists(unit) then
		return false
	end

	-- 单位是自身
	if UnitIsUnit(unit, "player") then
		return true
	end

	-- 统一转为表
	if type(spells) == "string" then
		spells = { spells }
	elseif type(spells) ~= "table" then
		return false
	end

	-- 取法术名
	local name
	for _, spell in ipairs(spells) do
		name = SpellCache:GetSpellData(spell)
		if name then
			break
		end
	end
	if not name then
		return false
	end

	-- 是否在法术范围 https://gitea.com/avitasia/nampower
	if type(IsSpellInRange) == "function" then
		local result = IsSpellInRange(name, unit)
		return result == 1
	end

	-- 检测距离
	local distance = GetDistance(unit)
	if distance then
		local range = self:GetRange(name)
		if range then
			return distance <= range
		end
	end

	-- 准备插槽
	local slot = Action:FindSpell(spells)
	if not slot then
		-- 放置首个法术
		local index = self:ToIndex(name)
		if index then
			slot = Action:PlaceSpell(index)
		end
	end

	-- 动作条探测
	if slot then
		return Action:IsRange(slot, unit)
	end
	return false
end

---取当前形态
---@return string? form 形态
function Library:GetForm()
	-- 取当前形态
	for index = GetNumShapeshiftForms(), 1, -1 do
		local _, name, active = GetShapeshiftFormInfo(index)
		if active then
			return name
		end
	end
end

---切换形态，兼容重复调用
---@param form? string 形态；支持表达式，缺省取消形态
---@return boolean success 成功
function Library:SwitchForm(form)
	if form then
		-- 切换到形态
		for index = 1, GetNumShapeshiftForms() do
			local _, name, active = GetShapeshiftFormInfo(index)
			if string.find(name, form) then
				if not active then
					CastShapeshiftForm(index)
				end
				return true
			end
		end
		return false
	else
		-- 取消形态
		for index = 1, GetNumShapeshiftForms() do
			local _, _, active = GetShapeshiftFormInfo(index)
			if active then
				CastShapeshiftForm(index)
				return true
			end
		end
		return true
	end
end

---施展法术
---@param spell string 法术；兼容等级
---@param unit? string 单位；缺省为当前目标或自我施法
function Library:Cast(spell, unit)
	if unit then
		if UnitIsUnit(unit, "player") then
			-- 对自己施法
			-- 有SpellTimer插件时，自我施法异常 xhwsd@qq.com 2025-8-30
			CastSpellByName(spell, 1)
		else
			-- 对单位施法
			if SUPERWOW_VERSION then
				CastSpellByName(spell, unit)
			else
				-- 切换到单位施法
				Target:SwitchUnit(unit, CastSpellByName, spell)
			end
		end
	else
		-- 默认施法
		CastSpellByName(spell)
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
