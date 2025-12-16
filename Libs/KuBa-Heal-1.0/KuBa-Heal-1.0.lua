--[[
Name: KuBa-Heal-1.0
Revision: $Rev: 10001 $
Author(s): 树先生
Website: https://gitee.com/ku-ba
Description: 治愈相关库。
Dependencies: AceLibrary, AceEvent-2.0
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-Heal-1.0"
-- 次要版本
local MINOR_VERSION = "$Revision: 10001 $"

-- 检验AceLibrary
if not AceLibrary then
	error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验AceEvent2.0
if not AceLibrary:HasInstance("AceEvent-2.0") then
	error(MAJOR_VERSION .. " requires AceEvent-2.0")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
	return
end

---@class KuBa-Heal-1.0 治愈相关库。
local Library = {}

--------------------------------

---治疗法术列表
local HEAL_SPELLS = {
	-- 德鲁伊
	["愈合"] = true,
	["治疗之触"] = true,
	-- 圣骑士
	["圣光术" ]= true,
	["圣光闪现"] = true,
	-- 牧师
	["次级治疗术"] = true,
	["治疗术"] = true,
	["快速治疗"] = true,
	-- 萨满祭司
	["次级治疗波"] = true,
	["治疗波"] = true,
	["治疗链"] = true,
}

---单位到GUID
---@param unit any 单位；兼容GUID
---@return string? guid
local function ToGuid(unit)
	if type(unit) == "string" and unit ~= "" then
		-- 是GUID
		if string.find(unit, "^0x%w+$") ~= nil then
			return unit
		end
		
		-- 非GUID
		local _, guid = UnitExists(unit)
		return guid
	end
end

---当玩家登录时触发
function Library:PLAYER_LOGIN()
	local _, playerGuid = UnitExists("player")
	self.playerGuid = playerGuid
	self.heals = {}
end

---当玩家登录游戏、加载界面或进入/离开副本区域时触发
function Library:PLAYER_ENTERING_WORLD()
	-- 回收所有
	self.heals = {}
end

---当附加施法时触发
---@param casterGuid string 施法者Guid
---@param targetGuid string 目标Guid
---@param event string 施法事件
---@param spellId number 施放法术ID
---@param castDuration number 施法时长；单位秒
function Library:UNIT_CASTEVENT(casterGuid, targetGuid, event, spellId, castDuration)
	if self.playerGuid and UnitCanAssist(self.playerGuid, casterGuid) then
		local spellName, spellRank = SpellInfo(spellId)
		if spellName and HEAL_SPELLS[spellName] then
			if event == "START" then
				-- 施法开始
				if castDuration > 0 then
					-- 自我施法
					if targetGuid == "" then
						-- 无目标
						targetGuid = casterGuid
					elseif not UnitCanAssist(casterGuid, targetGuid) then
						-- 无法协助目标
						targetGuid = casterGuid
					end

					-- 初始收益者
					if not self.heals[targetGuid] then
						self.heals[targetGuid] = {}
					end

					-- 置施法者信息
					local time = GetTime()
					self.heals[targetGuid][casterGuid] = {
						spellId = spellId,
						spellName = spellName,
						spellRank = spellRank,
						startTime = time,
						endTime = castDuration / 1000 + time,
						castDuration = castDuration,
					}
				end
			elseif event == "CAST" then
				-- 施法结束
				self:ClearCaster(casterGuid)
			elseif event == "FAIL" then
				-- 施法失败
				self:ClearCaster(casterGuid)
			end
		end
	end
end

---清除施法者相关协助信息
---@param caster string 施法者；支持标识、GUID
function Library:ClearCaster(caster)
	-- 到唯一标识
	local guid = ToGuid(caster)
	if not guid then
		return
	end

	for gainer in pairs(self.heals) do
		-- 如果施法者正在施法时，玩家远离了施法者，会如何？
		if self.heals[gainer][guid] then
			self.heals[gainer][guid] = nil
			-- 回收收益者
			if next(self.heals[gainer]) == nil then
				self.heals[gainer] = nil
			end
		end
	end
end

---取收益者的施法者列表
---@param gainer string 收益者；支持标识、GUID
---@param filter? fun(item:table):boolean 筛选；缺省不筛选
---@return table casters 施法者列表
function Library:GetList(gainer, filter)
	-- 到唯一标识
	local guid = ToGuid(gainer)
	if not guid or not self.heals[guid] then
		return {}
	end

	-- 转索引列表
	local list = {}
	for caster, data in pairs(self.heals[guid]) do
		-- 施法信息
		local item = {
			casterGuid = caster,
			spellId = data.spellId,
			spellName = data.spellName,
			spellRank = data.spellRank,
			startTime = data.startTime,
			endTime = data.endTime,
			castDuration = data.castDuration,
		}

		-- 是否满足条件
		local satisfy = true
		if type(filter) == "function" then
			satisfy = filter(item)
		end

		-- 添加到列表
		if satisfy then
			table.insert(list, item)
		end
	end

	-- 升序排列
	table.sort(list, function(a, b)
		return a.endTime < b.endTime 
	end)
	return list
end

---取早于（等于）指定时间的施法者列表
---@param gainer string 收益者；支持标识、GUID
---@param time number 时间；单位秒
---@return table casters 施法者列表
function Library:GetEarlier(gainer, time)
	-- 检验时间
	if type(time) ~= "number" or time <= 0 then
		return {}
	end

	-- 比对结束时间筛选
	return self:GetList(gainer, function(item) 
		return item.endTime <= time
	end)
end

---计数早于（等于）指定时间的施法者
---@param gainer string 收益者；支持标识、GUID
---@param time number 时间；单位秒
---@return number count 计数
function Library:CountEarlier(gainer, time)
	local list = self:GetEarlier(gainer, time)
	return table.getn(list)
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
	self.assists = {}

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
		self:RegisterEvent("PLAYER_LOGIN")
		self:RegisterEvent("PLAYER_ENTERING_WORLD")
		self:RegisterEvent("UNIT_CASTEVENT")
	end
end

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line
Library = nil
