---@class MeleeExtend:AceAddon-2.0 近战扩展模块 xhwsd@qq.com 2025-9-23
OneMacroMelee = OneMacro:NewModule("MeleeExtend")

--[[ 依赖 ]]

local Item = AceLibrary("KuBa-Item-1.0")

--[[ 事件 ]]

---初始化
function OneMacroMelee:OnInitialize()

end

---启用
function OneMacroMelee:OnEnable()
	self:RegisterDetects()
	self:RegisterActions()
end

---禁用
function OneMacroMelee:OnDisable()

end

---注册检测
function OneMacroMelee:RegisterDetects()
	OneMacro:RegisterDetects({
		["ComboPoints"] = {
			name = "连击点数",
			result = {
				type = "number",
				remark = "点数（0~5）",
			},
			handle = function(config, filter, options)
				return GetComboPoints()
			end,
		},
		["IsRange"] = {
			name = "是否在范围",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "target",
					filter = "filter",
				},
			},
			result = {
				type = "boolean",
				remark = "是否",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					return self:IsRange(unit)
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, range = OneMacroRoster:SwitchTarget(options.unit, { self, "IsRange" }, "target")
					if success == false then
						OneMacro:DebugError(3, range)
						return
					end
					return range
				else
					-- 其它单位
					return self:IsRange(options.unit)
				end
			end,
		},
		["IsBehind"] = {
			name = "是否在背后",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "target",
					filter = "filter",
				},
			},
			result = {
				type = "boolean",
				remark = "是否",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					return self:IsBehind(unit)
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, behind = OneMacroRoster:SwitchTarget(options.unit, { self, "IsBehind" }, "target")
					if success == false then
						OneMacro:DebugError(3, behind)
						return
					end
					return behind
				else
					-- 其它单位
					return self:IsBehind(options.unit)
				end
			end,
		},
		["TransformRestore"] = {
			name = "变形恢复",
			options = {
				rage = {
					type = "boolean",
					name = "怒气",
					default = false,
					remark = "是否为怒气",
				},
			},
			result = {
				type = "number",
				remark = "恢复",
			},
			handle = function(config, filter, options)
				return self:GetTransformRestore(options.rage)
			end,
			remark = "取德鲁伊变形恢复可恢复的能力或怒气值"
		},

		--[[ Attackbar ]]

		["StartTime"] = {
			name = "开始时间",
			result = {
				type = "time",
				remark = "时间",
			},
			handle = function(config, filter, options)
				-- 检测插件
				if type(Abar_Mhr) == "table" then
					return Abar_Mhr.st
				else
					OneMacro:DebugWarning(2, "未检测到插件(Attackbar)")
				end
			end,
			remark = "距离下次攻击开始时间",
		},
		["StartSeconds"] = {
			name = "开始秒数",
			result = {
				type = "seconds",
				remark = "秒数",
			},
			handle = function(config, filter, options)
				-- 检测插件
				if type(Abar_Mhr) == "table" then
					return Abar_Mhr.st - GetTime()
				else
					OneMacro:DebugWarning(2, "未检测到插件(Attackbar)")
				end
			end,
			remark = "距离下次攻击开始秒数",
		},
		["EndTime"] = {
			name = "结束时间",
			result = {
				type = "time",
				remark = "时间",
			},
			handle = function(config, filter, options)
				-- 检测插件
				if type(Abar_Mhr) == "table" then
					return Abar_Mhr.et
				else
					OneMacro:DebugWarning(2, "未检测到插件(Attackbar)")
				end
			end,
			remark = "距离下次攻击结束时间",
		},
		["EndSeconds"] = {
			name = "结束秒数",
			result = {
				type = "seconds",
				remark = "秒数",
			},
			handle = function(config, filter, options)
				-- 检测插件
				if type(Abar_Mhr) == "table" then
					return Abar_Mhr.et - GetTime()
				else
					OneMacro:DebugWarning(2, "未检测到插件(Attackbar)")
				end
			end,
			remark = "距离下次攻击结束秒数",
		},
	}, "Melee", "近战", "近战相关检测")
end

---注册动作
function OneMacroMelee:RegisterActions()
	OneMacro:RegisterActions({
		["AutoAttack"] = {
			name = "自动攻击",
			handle = function(config, filter, options)
				self:AutoAttack()
			end,
			remark = "开启自动近战攻击，兼容重复调用",
		},
	}, "Melee", "近战", "近战相关动作")
end

---是否近战范围
---@param unit string? 单位；缺省为`target`
---@return boolean melee 近战
function OneMacroMelee:IsRange(unit)
	unit = unit or "target"

	-- 不在10码内
	if not CheckInteractDistance(unit, 3) then
		return false
	end

	-- 在近战范围内 https://github.com/MarcelineVQ/UnitXP_SP3
	local success, result = pcall(UnitXP, "distanceBetween", "player", unit, "meleeAutoAttack")
	if not success then
		OneMacro:DebugWarning(2, "未检测到模组(UnitXP)")
		return false
	end

	-- 在近战范围为0，不在近战范围为非0，失败为nil
	return result == 0
end

---是否在目标背后
---@param unit? string 单位；缺省为`target`，兼容GUID
---@return boolean behind 背后
function OneMacroMelee:IsBehind(unit)
	unit = unit or "target"

	-- 近战范围
	if not self:IsRange(unit) then
		return false
	end

	-- 是否在目标背后 https://github.com/MarcelineVQ/UnitXP_SP3
	local success, result = pcall(UnitXP, "behind", "player", unit)
	if not success then
		OneMacro:DebugWarning(2, "未检测到模组(UnitXP)")
		return false
	end

	-- 在背后为true，不在背后为false，失败为nil
	return result == true
end

---取德鲁伊变形恢复
---@param rage? boolean 怒气
---@return number restore 恢复；备注：激怒天赋（10怒气、40能量）、狼心附魔（5怒气、20能量）
function OneMacroMelee:GetTransformRestore(rage)
	local restore = 0
	local class = UnitClass("player")
	if class ~= "德鲁伊" then
		OneMacro:DebugWarning(3, "非德鲁伊职业(%s)", class)
		return restore
	end

	-- 激怒 Rank 0/5
	-- 在你有[20/40/60/80/100]%的几率在进入熊形态和巨熊形态时获得10点怒气值，或者在进入猎豹形态时获得40点能量值。
	local _, _, _, _, rank = GetTalentInfo(3, 2)
	if rank > 0 then
		if rage then
			-- 概率恢复10点怒气
			restore = restore + 10
		else
			-- 概率恢复40点能量
			restore = restore + 40
		end
	end

	-- 头盔装备槽标识为1，狼心附魔标识为3004
	-- 描述 https://database.turtle-wow.org/?item=61081
	local link = GetInventoryItemLink("player", 1)
	if link and Item:LinkToEnchant(link) == 3004 then
		if rage then
			-- 恢复5点怒气
			restore = restore + 5
		else
			-- 恢复20点能量
			restore = restore + 20
		end
	end

	OneMacro:DebugNote(3, "德鲁伊变形恢复(%d)", restore)
	return restore
end

---自动近战攻击
function OneMacroMelee:AutoAttack()
	if not PlayerFrame.inCombat then
		CastSpellByName("攻击")
	end
end
