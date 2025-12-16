--[[
Name: KuBa-Cast-1.0
Revision: $Rev: 10001 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://gitee.com/ku-ba
Description: 施法相关库。
Dependencies: AceLibrary, AceEvent-2.0, AceHook-2.1, Gratuity-2.0, SpellCache-1.0
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-Cast-1.0"
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
	-- 事件
	"AceEvent-2.0",
	-- 钩子
	"AceHook-2.1",
	-- 提示解析
	"Gratuity-2.0",
	-- 法术缓存
	"SpellCache-1.0",
})

-- 提示解析
local Gratuity = AceLibrary("Gratuity-2.0")
-- 引入依赖库
local SpellCache = AceLibrary("SpellCache-1.0")

---施法相关库。
---@class KuBa-Cast-1.0:AceEvent-2.0,AceHook-2.1
---@field isCasting boolean 是否正施法中
---@field spellName string 法术名称
---@field spellRank string|nil 法术等级
---@field targetName string|nil 目标名称；无目标时为`nil`
---@field targetGuid string|nil 目标标识；无目标或不支持时为`nil`
---@field isPlayer boolean|nil 目标是否为玩家角色；无目标为`nil`
---@field canAssist boolean|nil 可否协助；无目标时为`nil`
---@field canAttack boolean 可否攻击；无目标时为`false`
---@field canCooperate boolean|nil 可否合作；无目标时为`nil`
local Library = {}

--------------------------------

---[文档](https://warcraft.wiki.gg/wiki/SPELLCAST_START)
---施法开始 (如果有施法时间才触发，瞬发法术仅触发SPELLCAST_STOP)
function Library:SPELLCAST_START()
	self.isCasting = true
	self.spellName = arg1
	-- self:LevelDebug(3, "施法开始；法术：%s；目标：%s", cast.spell, cast.target)
end

---[文档](https://warcraft.wiki.gg/wiki/SPELLCAST_STOP)
---施法停止
function Library:SPELLCAST_STOP()
	self.isCasting = false
	-- self:LevelDebug(3, "施法停止；法术：%s；目标：%s", cast.spell, cast.target)
end

---[文档](https://warcraft.wiki.gg/wiki/SPELLCAST_FAILED)
---施法失败
function Library:SPELLCAST_FAILED()
	self.isCasting = false
	-- self:LevelDebug(3, "施法失败；法术：%s；目标：%s", cast.spell, cast.target)
end

---[文档](https://warcraft.wiki.gg/wiki/API_UseAction?oldid=4762983)
---使用动作条
---@param slotId number 动作条插槽ID
---@param checkCursor? boolean 是否检查鼠标是否悬停在施法物品上
---@param onSelf? boolean|number|string 是否自我施法
function Library:UseAction(slotId, checkCursor, onSelf)
	-- self:LevelDebug(3, "UseAction", slotId, checkCursor, onSelf)
	self.hooks.UseAction(slotId, checkCursor, onSelf)
	
	-- 正在施法
	if self.isCasting then
		return
	end

	-- 空插槽
	if not HasAction(slotId) then
		return
	end

	-- 宏有文本
	if GetActionText(slotId) then
		return
	end

	-- 插槽信息
	Gratuity:SetAction(slotId)
	local name, rank = SpellCache:GetSpellData(Gratuity:GetLine(1), Gratuity:GetLine(1, true))

	-- 目标单位
	local unit 
	if onSelf == true or onSelf == 1 or onSelf == "1" then
		-- 自我施法
		unit = "player"
	elseif type(onSelf) == "string" and onSelf ~= "" then
		-- 指定单位
		unit = onSelf
	elseif UnitExists("target") then
		unit = "target"
	end
	
	-- 处理施法
	self:HandleCast(name, rank, unit)
end

---[文档](https://warcraft.wiki.gg/wiki/API_CastSpell?oldid=2527575)
---施展法术
---@param spellId number 法术ID
---@param spellbookType? string 法术书类型；`BOOKTYPE_SPELL`为法术书，其他值为其他类型
function Library:CastSpell(spellId, spellbookType)
	-- self:LevelDebug(3, "CastSpell", spellId, spellbookType)
	self.hooks.CastSpell(spellId, spellbookType)

	-- 正在施法
	if self.isCasting then
		return
	end

	-- 法术信息
	local name, rank = GetSpellName(spellId, spellbookType)
	-- 目标单位
	local unit = UnitExists("target") and "target" or nil
	-- 处理施法
	self:HandleCast(name, rank, unit)
end

---[文档](https://warcraft.wiki.gg/wiki/API_CastSpellByName?oldid=3246269)
---按名称施展法术
---@param spellName string 法术名称
---@param onSelf? boolean|number|string 是否自我施法
function Library:CastSpellByName(spellName, onSelf)
	-- self:LevelDebug(3, "CastSpellByName", spellName, onSelf)
	self.hooks.CastSpellByName(spellName, onSelf)

	-- 正在施法
	if self.isCasting then
		return
	end

	-- 法术信息
	local name, rank = SpellCache:GetSpellData(spellName)

	-- 目标单位
	local unit
	if onSelf == true or onSelf == 1 or onSelf == "1" then
		-- 自我施法
		unit = "player"
	elseif type(onSelf) == "string" and string.len(onSelf) >= 2 then
		-- 指定单位
		unit = onSelf
	elseif UnitExists("target") then
		unit = "target"
	end

	-- 处理施法
	self:HandleCast(name, rank, unit)
end

---处理施法
---@param spellName string 法术名称
---@param spellRank? string 法术等级；空为无等级（最高等级）
---@param targetUnit? string 目标单位；空为无目标
function Library:HandleCast(spellName, spellRank, targetUnit)
	-- 法术信息
	self.spellName = spellName
	self.spellRank = spellRank

	--- 单位信息
	if targetUnit then
		-- 有目标
		self.targetName = UnitName(targetUnit)
		_, self.targetGuid = UnitExists(targetUnit)
		-- 在这里就取值，是为兼容无SuperWoW模组情况
		self.isPlayer = UnitIsPlayer(targetUnit)
		self.canAssist = UnitCanAssist("player", targetUnit)
		self.canAttack = UnitCanAttack("player", targetUnit)
		self.canCooperate = UnitCanCooperate("player", targetUnit)
	else
		-- 无目标
		self.targetName = nil
		self.targetGuid = nil
		self.isPlayer = nil
		self.canAssist = nil
		self.canAttack = false
		self.canCooperate = nil
	end
end

---是否在施法中
---@return boolean is 是否
function Library:IsCasting()
	return self.isCasting
end

---取法术
---@return string? name 名称；可能物品、装备等
---@return string? rank 等级
---@return number? level 级别
function Library:GetSpell()
	local level
	if self.spellRank then
		level = SpellCache:GetRankNumber(self.spellRank)
	end
	return self.spellName, self.spellRank, level
end

---是否具有目标；注意自我施法时可以无目标
---@return boolean has 具有
function Library:HasTarget()
	return self.targetName ~= nil
end

---是否为玩家（不限自己）
---@return boolean is 是否
function Library:IsPlayer()
	return self.isPlayer == true and self.targetName ~= nil
end

---是否为自身
---@return boolean is 是否
function Library:IsSelf()
	return self.isPlayer == true and self.targetName == UnitName("player")
end

---可否协助
---@return boolean can 可否
function Library:CanAssist()
	return self.targetName ~= nil and self.canAssist == true
end

---可否攻击
---@return boolean can 可否
function Library:CanAttack()
	return self.targetName ~= nil and self.canAttack == true
end

---可否合作
---@return boolean can 可否
function Library:CanCooperate()
	return self.targetName ~= nil and self.canCooperate == true
end 

---取目标
---@return string? name 名称
---@return string? guid GUID
---@return boolean? oneself 自己
function Library:GetTarget()
	return self.targetName, self.targetGuid, self:IsSelf()
end

---取协助目标；无目标或不可协助时为自己，相当于自我施法
---@return string? name 名称
---@return string? guid GUID
---@return boolean? oneself 自己
function Library:GetAssist()
	-- 有可协助的目标
	if self.canAssist and self.targetName then
		return self.targetName, self.targetGuid, self:IsSelf()
	end

	-- 自我施法无目标
	if self.spellName then
		local name = UnitName("player")
		local _, guid = UnitExists("player")
		return name, guid, true
	end
end

---取攻击目标
---@return string? name 名称
---@return string? guid GUID
function Library:GetAttack()
	if self.canAttack and self.targetName then
		return self.targetName, self.targetGuid
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
		oldLib:UnregisterAllEvents()
		oldLib:CancelAllScheduledEvents()
		oldLib:UnhookAll()
	end

	-- 新版本初始化
	self.isCasting = false
	self.spellName = nil
	self.spellRank = nil
	self.targetName = nil
	self.targetGuid = nil
	self.isPlayer = nil
	self.canAssist = nil
	self.canAttack = false
	self.canCooperate = nil

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
	if major == "AceEvent-2.0" then
		-- 混入事件
		instance:embed(self)

		-- 注册事件
		self:RegisterEvent("SPELLCAST_START")
		self:RegisterEvent("SPELLCAST_STOP")
		self:RegisterEvent("SPELLCAST_FAILED")
		self:RegisterEvent("SPELLCAST_INTERRUPTED", "SPELLCAST_FAILED")
	elseif major == "AceHook-2.1" then
		-- 混入钩子
		instance:embed(self)

		-- 挂接函数
		self:Hook("UseAction")
		self:Hook("CastSpell")
		self:Hook("CastSpellByName")

		-- self:Hook("SpellTargetUnit")
		-- self:Hook("SpellStopTargeting")
		-- self:Hook("TargetUnit")
		-- self:HookScript(WorldFrame, "OnMouseDown")
	end
end

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line
Library = nil