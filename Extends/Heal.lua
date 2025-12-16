---@class HealExtend:AceAddon-2.0 治疗扩展模块 xhwsd@qq.com 2025-7-11
OneMacroHeal = OneMacro:NewModule("HealExtend")

-- 原治疗法术信息；原施法秒数和原持续秒数
-- 非瞬发法术：`casting > 0`
-- 瞬发法术：`casting == 0`
-- 持续法术：`duration > 0`
local HEAL_SPELLS = {
	["德鲁伊"] = {
		["回春术"] = {
			duration = 12,
		},
		["愈合"] = {
			casting = 2,
			duration = 21,
		},
		["治疗之触"] = {
			casting = {
				-- 共11级
				1.5, 2, 2.5, 3, 3.5, 3.5, 3.5, 3.5, 3.5, 3.5, 3.5,
			}
		},
	},
	["圣骑士"] = {
		["圣光术"] = {
			casting = 2.5,
		},
		["圣光闪现"] = {
			casting = 1.5,
		},
		-- 这是个近战法术，但会治疗单个目标
		["神圣震击"] = {
			casting = 0,
		}
		-- 神圣打击是AOE治疗不预估治疗
	},
	["牧师"] = {
		["次级治疗术"] = {
			-- 共4级
			casting = {
				3, 3, 3, 4,
			}
		},
		["治疗术"] = {
			-- 共3级
			casting = {
				1.5, 2, 2.5,
			}
		},
		["快速治疗"] = {
			casting = 1.5,
		},
		["恢复"] = {
			duration = 15,
		},
	},
	["萨满祭司"] = {
		["次级治疗波"] = {
			casting = 1.5,
		},
		["治疗波"] = {
			-- 共10级
			casting = {
				1.5, 2, 2.5, 3, 3, 3, 3, 3, 3, 3,
			},
		},
		-- 这是个指向目标治疗法术，但又跳跃治疗其它3个目标
		["治疗链"] = {
			casting = 2.5,
		},
	},
}

--[[ 依赖 ]]

local SpellCache = AceLibrary("SpellCache-1.0")
local Buff = AceLibrary("KuBa-Buff-1.0")
local State = AceLibrary("KuBa-State-1.0")
local Spell = AceLibrary("KuBa-Spell-1.0")
local Heal = AceLibrary("KuBa-Heal-1.0")

--[[ 事件 ]]

---初始化
function OneMacroHeal:OnInitialize()

end

---启用
function OneMacroHeal:OnEnable()
	self:RegisterDetects()
	self:RegisterActions()
end

---禁用
function OneMacroHeal:OnDisable()

end

---注册检测
function OneMacroHeal:RegisterDetects()
	OneMacro:RegisterDetects({
		["IsRange"] = {
			name = "是否在范围",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter"
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
			remark = "检验单位是否在治疗法术范围内",
		},
		["CanHeal"] = {
			name = "可否治疗",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
				sight = {
					type = "boolean",
					name = "视线",
					default = true,
					remark = "检验是否在视线范围",
				}
			},
			result = {
				type = "boolean",
				remark = "可否",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					return self:CanHeal(unit, options.sight)
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, heal = OneMacroRoster:SwitchTarget(options.unit, { self, "CanHeal" }, "target",
						options.sight)
					if success == false then
						OneMacro:DebugError(3, heal)
						return
					end
					return heal
				else
					-- 其它单位
					return self:CanHeal(options.unit, options.sight)
				end
			end,
			remark = "检验单位能否接受治疗的所有条件",
		},
		["CasterCount"] = {
			name = "施法者计数",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
					remark = "收益者单位",
				},
				time = {
					type = "number",
					name = "时间",
					remark = "限定施法结束时间",
				}
			},
			result = {
				type = "number",
				remark = "计数",
			},
			handle = function(config, filter, options)
				-- 检测SuperWoW模组
				if not SUPERWOW_VERSION then
					OneMacro:DebugWarning(2, "未检测到模组(SuperWoW)")
					return
				end

				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					return Heal:CountEarlier(unit, options.time)
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, result = OneMacroRoster:SwitchTarget(options.unit, { Heal, "CountEarlier" }, "target",
						options.time)
					if success == false then
						OneMacro:DebugError(3, result)
						return
					end
					return result
				else
					-- 其它单位
					return Heal:CountEarlier(options.unit, options.time)
				end
			end,
			remark = "取收益者当前正在治愈的施法者计数，依赖SuperWoW模组",
		},
	}, "Heal", "治疗", "治疗相关检测")
end

---注册动作
function OneMacroHeal:RegisterActions()
	OneMacro:RegisterActions({
		["CastHeal"] = {
			name = "施法治疗",
			options = {
				spell = {
					type = "string",
					name = "法术",
					required = true,
					remark = "如果含等级将限定为最高等级",
				},
				unit = {
					type = "string",
					name = "目标",
					default = "player",
					filter = "filter",
				},
				percentage = {
					type = "number",
					name = "百分比",
					default = 100,
					remark = "治疗百分比，范围1-100，默认100",
				},
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					self:CastHeal(options.spell, unit, options.percentage)
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, message = OneMacroRoster:SwitchTarget(options.unit, { self, "CastHeal" },
						options.spell, "target", options.percentage)
					if success == false then
						OneMacro:DebugError(3, message)
						return
					end
				else
					-- 其它单位
					self:CastHeal(options.spell, options.unit, options.percentage)
				end
			end,
			remark = "施法适配等级的治疗法术",
		},
	}, "Heal", "治疗", "治疗相关动作")
end

---是否在治疗范围
---@param unit? string 单位；缺省为`player`
---@return boolean is 是否
function OneMacroHeal:IsRange(unit)
	unit = unit or "player"

	-- 单位不存在
	if not UnitExists(unit) then
		return false
	end

	-- 在跟随范围内（实测20码 2025-8-10）
	if CheckInteractDistance(unit, 4) then
		return true
	end

	-- 取治疗法术
	local spells = self:GetHealSpells()
	if not spells then
		return false
	end

	-- 超出治疗法术距离
	if not Spell:IsRange(spells, unit) then
		return false
	end
	return true
end

---可否治疗
---@param unit? string 单位；缺省为`player`
---@param sight? boolean 视线；缺省为`true`，是否检验视线，太耗资源
---@return boolean can 可否
function OneMacroHeal:CanHeal(unit, sight)
	unit = unit or "player"
	sight = type(sight) == "boolean" and sight or true

	-- 单位不存在
	if not UnitExists(unit) then
		return false
	end

	-- 死亡或灵魂
	if UnitIsDeadOrGhost(unit) then
		return false
	end

	-- 自己
	if UnitIsUnit(unit, "player") then
		return true
	end

	-- 离线
	if not UnitIsConnected(unit) then
		return false
	end

	-- 客户端不可见
	if not UnitIsVisible(unit) then
		return false
	end

	-- 无法协助
	if not UnitCanAssist("player", unit) then
		return false
	end

	-- 在治疗范围外
	if not self:IsRange(unit) then
		return false
	end

	-- 检验视线
	if sight and OneMacroCommon:IsVisual(unit) then
		return true
	end
	return false
end

---取治疗法术
---@return table|nil names 名称；成功返回表，否则返回空
function OneMacroHeal:GetHealSpells()
	-- 取治疗法术
	local class = UnitClass("player")
	local spells = HEAL_SPELLS[class]
	if not spells then
		OneMacro:DebugWarning(2, "无职业(%s)治疗法术", class)
		return
	end

	local names = {}
	for name in pairs(spells) do
		table.insert(names, name)
	end
	return names
end

---施放适配等级的治疗法术
---@param spell string 法术名称
---@param unit? string 治疗单位；缺省为`player`
---@param percentage? number 百分比；范围0-100，默认100
function OneMacroHeal:CastHeal(spell, unit, percentage)
	unit = unit or "player"
	percentage = percentage or 100

	-- 限定等级
	local name, _, _, _, rank = SpellCache:GetSpellData(spell)
	if not name then
		name = spell
	end
	if rank then
		rank = tonumber(rank)
	end

	local adapt = self:AdaptHeal(name, unit, rank, percentage)
	if adapt then
		Spell:Cast(adapt, unit)
	else
		OneMacro:DebugError(2, "目标(%s)适配治疗法术(%s)等级失败", UnitName(unit), spell)
		Spell:Cast(spell, unit)
	end
end

---适配等级的治疗法术
---@param spell string 法术名称
---@param unit? string 治疗单位；缺省为`player`
---@param limit? number 限定最高等级；缺省不限
---@param percentage? number 折算百分比；范围0-100，默认100
---@return string|nil spell 法术名称；成功为名称，否则为空
function OneMacroHeal:AdaptHeal(spell, unit, limit, percentage)
	unit = unit or "player"
	percentage = percentage or 100

	-- 治疗法术
	if not self:IsHealSpell(spell) then
		OneMacro:DebugWarning(2, "适配非治疗法术(%s)", spell)
		return
	end

	-- 最高级别
	local _, _, max = Spell:GetMax(spell)
	if not max then
		OneMacro:DebugError(2, "取法术(%s)最高级别失败", spell)
		return
	end

	-- 限定级别
	if limit and limit <= max then
		max = limit
		OneMacro:DebugNote(3, "适配法术(%s)限定等级(%d)", spell, max)
	end

	-- 装备强度
	local equipment = self:GetEquipmentPower()
	-- 天赋加成
	local talentHeal, talentHot = self:GetTalentBonus(spell, unit)

	-- 适配等级
	local adapt = max
	local lose = State:GetHealthLose(unit)
	for level = 1, max do
		local estimate = self:EstimateHeal(spell, level, equipment, talentHeal, talentHot) * (percentage / 100)
		OneMacro:DebugNote(3, "法术(%s)等级(%d)预估(%d)", spell, level, estimate)
		if estimate >= lose then
			adapt = level
			break
		end
	end

	OneMacro:DebugNote(3, "目标(%s)失血(%d)适配治疗法术(%s)等级(%d)", UnitName(unit), lose, spell, adapt)
	return string.format("%s(等级 %d)", spell, adapt)
end

---取天赋治疗加成
---@param spell string 法术名称
---@param unit? string 治疗单位；缺省为`player`
---@return number heal 治疗加成；从`1`起始
---@return number hot 恢复加成；从`1`起始
function OneMacroHeal:GetTalentBonus(spell, unit)
	unit = unit or "player"

	-- 天赋模拟器 https://talents.turtle-wow.org/paladin
	-- 天赋索引（从左往右，从上往下，从1开始，数图标）
	-- 加成 = 加成 * (进步数 * 天赋等级 / 100 + 1)

	local rank
	local heal = 1
	local hot = 1
	local class = UnitClass("player")
	if class == "德鲁伊" then
		if spell == "治疗之触" then
			-- 自然赐福 Rank 0/5
			-- 使你的所有治疗法术的效果提高[2/4/6/8/10]%。
			_, _, _, _, rank = GetTalentInfo(3, 9)
			heal = heal * (2 * rank / 100 + 1)

			-- 生命之树形态 Rank 0/1
			-- 变成生命之树，附近所有队友的治疗效果提高，数值相当于你的精神总值的20%。
			-- 你的移动速度降低20%，并且你不能施放伤害性法术或治疗之触，但其他治疗法术所消耗的法力值也降低20%.
			-- 变身可以解除施法者身上的一切变形和移动限制效果。
			-- _, _, _, _, rank = GetTalentInfo(3, 16)
		elseif spell == "回春术" then
			-- 起源 Rank 0/3
			-- 使你法术技能的持续伤害效果和持续治疗效果提高[5/10/15]%
			_, _, _, _, rank = GetTalentInfo(3, 7)
			hot = hot * (5 * rank / 100 + 1)

			-- 自然赐福 Rank 0/5
			-- 使你的所有治疗法术的效果提高[2/4/6/8/10]%。
			_, _, _, _, rank = GetTalentInfo(3, 9)
			hot = hot * (2 * rank / 100 + 1)

			-- 生命之树形态 Rank 0/1
			-- 变成生命之树，附近所有队友的治疗效果提高，数值相当于你的精神总值的20%。
			-- 你的移动速度降低20%，并且你不能施放伤害性法术或治疗之触，但其他治疗法术所消耗的法力值也降低20%.
			-- 变身可以解除施法者身上的一切变形和移动限制效果。
			-- _, _, _, _, rank = GetTalentInfo(3, 16)
		elseif spell == "愈合" then
			-- 起源 Rank 0/3
			-- 使你法术技能的持续伤害效果和持续治疗效果提高[5/10/15]%
			_, _, _, _, rank = GetTalentInfo(3, 7)
			hot = hot * (5 * rank / 100 + 1)

			-- 自然赐福 Rank 0/5
			-- 使你的所有治疗法术的效果提高[2/4/6/8/10]%。
			_, _, _, _, rank = GetTalentInfo(3, 9)
			hot = hot * (2 * rank / 100 + 1)
			heal = heal * (2 * rank / 100 + 1)

			-- 庇佑 Rank 0/3
			-- 如果目标身上存在回春效果，愈合的持续治疗效果增加[10/20/30]%。
			_, _, _, _, rank = GetTalentInfo(3, 13)
			if rank and Buff:FindBuff("回春术", unit) then
				hot = hot * (10 * rank / 100 + 1)
			end

			-- 强化愈合 Rank 0/5
			-- 使你的愈合法术产生极效治疗效果的几率提高[10/20/30/40/50]%。
			_, _, _, _, rank = GetTalentInfo(3, 14)
			-- 将暴击概率也作为治疗加成 xhwsd@qq.com 2025-11-13
			heal = heal * (10 * rank / 100 + 1)

			-- 生命之树形态 Rank 0/1
			-- 变成生命之树，附近所有队友的治疗效果提高，数值相当于你的精神总值的20%。
			-- 你的移动速度降低20%，并且你不能施放伤害性法术或治疗之触，但其他治疗法术所消耗的法力值也降低20%.
			-- 变身可以解除施法者身上的一切变形和移动限制效果。
			-- _, _, _, _, rank = GetTalentInfo(3, 16)
		end
	elseif class == "圣骑士" then
		if spell == "圣光术" then
			-- 治疗之光 Rank 0/3
			-- 使你的圣光术、圣光闪现和神圣震击的治疗效果提高[4/8/12]%。
			_, _, _, _, rank = GetTalentInfo(1, 6)
			heal = heal * (4 * rank / 100 + 1)

			-- 已在装备治疗强度统计
			-- 铁壁 Rank 0/2
			-- 增加你的法术造成的治疗效果，数值相当于你从装备获得护甲值的[1/2]%。
			_, _, _, _, rank = GetTalentInfo(1, 12)
			if rank then
				-- 取装备护甲
				local armor = self:GetEquipmentArmor()
				if armor then
					armor = armor * (rank / 100)
					-- 待补算法 xhwsd@qq.com 2025-11-13
				end
			end

			-- 神圣强化 Rank 0/3
			-- 使你的圣光术和圣光闪现造成致命一击的几率提高[2/4/6]%。
			_, _, _, _, rank = GetTalentInfo(1, 15)
			-- 将暴击概率也作为治疗加成 xhwsd@qq.com 2025-11-13
			heal = heal * (2 * rank / 100 + 1)
		elseif spell == "圣光闪现" then
			-- 治疗之光 Rank 0/3
			-- 使你的圣光术、圣光闪现和神圣震击的治疗效果提高[4/8/12]%。
			_, _, _, _, rank = GetTalentInfo(1, 6)
			heal = heal * (4 * rank / 100 + 1)

			-- 已在装备治疗强度统计
			-- 铁壁 Rank 0/2
			-- 增加你的法术造成的治疗效果，数值相当于你从装备获得护甲值的[1/2]%。
			-- _, _, _, _, rank = GetTalentInfo(1, 12)

			-- 神圣强化 Rank 0/3
			-- 使你的圣光术和圣光闪现造成致命一击的几率提高[2/4/6]%。
			_, _, _, _, rank = GetTalentInfo(1, 15)
			-- 将暴击概率也作为治疗加成 xhwsd@qq.com 2025-11-13
			heal = heal * (2 * rank / 100 + 1)
		elseif spell == "神圣震击" then
			-- 治疗之光 Rank 0/3
			-- 使你的圣光术、圣光闪现和神圣震击的治疗效果提高[4/8/12]%。
			_, _, _, _, rank = GetTalentInfo(1, 6)
			heal = heal * (4 * rank / 100 + 1)

			-- 已在装备治疗强度统计
			-- 铁壁 Rank 0/2
			-- 增加你的法术造成的治疗效果，数值相当于你从装备获得护甲值的[1/2]%。
			-- _, _, _, _, rank = GetTalentInfo(1, 12)

			-- 神恩术 Rank 0/5
			-- 提高你使用神圣震击造成致命一击的几率[10/20/30/40/50]%。
			_, _, _, _, rank = GetTalentInfo(1, 13)
			-- 将暴击概率也作为治疗加成 xhwsd@qq.com 2025-11-13
			heal = heal * (10 * rank / 100 + 1)
		end
	elseif class == "牧师" then
		if spell == "次级治疗术" then
			-- 神圣专精 Rank 0/5
			-- 使你的神圣和戒律法术造成致命一击的几率提高[1/2/3/4/5]%。
			_, _, _, _, rank = GetTalentInfo(2, 3)
			-- 将暴击概率也作为治疗加成 xhwsd@qq.com 2025-11-13
			heal = heal * (1 * rank / 100 + 1)

			-- 迅速恢复 Rank 0/2
			-- 目标存在恢复效果时，你的治疗法术的效果提高[3/6]%。
			_, _, _, _, rank = GetTalentInfo(2, 10)
			if rank and Buff:FindBuff("恢复", unit) then
				heal = heal * (3 * rank / 100 + 1)
			end

			-- 已在装备治疗强度统计
			-- 精神指引 Rank 0/5
			-- 使你的法术的治疗和伤害效果提高，数值最多相当于你的精神值的[5/10/15/20/25]%。
			_, _, _, _, rank = GetTalentInfo(2, 12)
			if rank then
				-- 取装备护甲
				local spirit = self:GetSpirit()
				if spirit then
					rank = 5 * rank
					spirit = spirit * (rank / 100)
					-- 待补算法 xhwsd@qq.com 2025-11-13
				end
			end

			-- 精神治疗 Rank 0/5
			-- 使你的治疗法术的治疗效果提高[6/12/18/24/30]%
			_, _, _, _, rank = GetTalentInfo(2, 15)
			heal = heal * (6 * rank / 100 + 1)
		elseif spell == "治疗术" then
			-- 神圣专精 Rank 0/5
			-- 使你的神圣和戒律法术造成致命一击的几率提高[1/2/3/4/5]%。
			_, _, _, _, rank = GetTalentInfo(2, 3)
			-- 将暴击概率也作为治疗加成 xhwsd@qq.com 2025-11-13
			heal = heal * (1 * rank / 100 + 1)

			-- 迅速恢复 Rank 0/2
			-- 目标存在恢复效果时，你的治疗法术的效果提高[3/6]%。
			_, _, _, _, rank = GetTalentInfo(2, 10)
			if rank and Buff:FindBuff("恢复", unit) then
				heal = heal * (3 * rank / 100 + 1)
			end

			-- 已在装备治疗强度统计
			-- 精神指引 Rank 0/5
			-- 使你的法术的治疗和伤害效果提高，数值最多相当于你的精神值的[5/10/15/20/25]%。
			-- _, _, _, _, rank = GetTalentInfo(2, 12)

			-- 精神治疗 Rank 0/5
			-- 使你的治疗法术的治疗效果提高[6/12/18/24/30]%
			_, _, _, _, rank = GetTalentInfo(2, 15)
			heal = heal * (6 * rank / 100 + 1)
		elseif spell == "快速治疗" then
			-- 神圣专精 Rank 0/5
			-- 使你的神圣和戒律法术造成致命一击的几率提高[1/2/3/4/5]%。
			_, _, _, _, rank = GetTalentInfo(2, 3)
			-- 将暴击概率也作为治疗加成 xhwsd@qq.com 2025-11-13
			heal = heal * (1 * rank / 100 + 1)

			-- 迅速恢复 Rank 0/2
			-- 目标存在恢复效果时，你的治疗法术的效果提高[3/6]%。
			_, _, _, _, rank = GetTalentInfo(2, 10)
			if rank and Buff:FindBuff("恢复", unit) then
				heal = heal * (3 * rank / 100 + 1)
			end

			-- 已在装备治疗强度统计
			-- 精神指引 Rank 0/5
			-- 使你的法术的治疗和伤害效果提高，数值最多相当于你的精神值的[5/10/15/20/25]%。
			-- _, _, _, _, rank = GetTalentInfo(2, 12)

			-- 精神治疗 Rank 0/5
			-- 使你的治疗法术的治疗效果提高[6/12/18/24/30]%
			_, _, _, _, rank = GetTalentInfo(2, 15)
			heal = heal * (6 * rank / 100 + 1)
		elseif spell == "恢复" then
			-- 强化恢复 Rank 0/3
			-- 使你的恢复法术的治疗效果提高[5/10/15]%
			_, _, _, _, rank = GetTalentInfo(2, 1)
			hot = hot * (5 * rank / 100 + 1)
		end
	elseif class == "萨满祭司" then
		if spell == "次级治疗波" then
			-- 潮汐掌握 Rank 0/5
			-- 使你的治疗法术和闪电法术的致命一击几率提高[1/2/3/4/5]%。
			-- 将暴击概率也作为治疗加成 xhwsd@qq.com 2025-11-13
			_, _, _, _, rank = GetTalentInfo(3, 5)
			heal = heal * (1 * rank / 100 + 1)

			-- 治疗之道 Rank 0/3
			-- 你的治疗波和次级治疗波有[33/66/100]%的几率使你下一次治疗波或次级治疗波对该目标的治疗效果提高6%，持续15 sec，可叠加3次。
			_, _, _, _, rank = GetTalentInfo(3, 6)
			if rank then
				local layers = Buff:GetLayers("治疗之道", unit)
				if layers then
					heal = heal * (6 * layers / 100 + 1)
				end
			end
		elseif spell == "治疗波" then
			-- 潮汐掌握 Rank 0/5
			-- 使你的治疗法术和闪电法术的致命一击几率提高[1/2/3/4/5]%。
			-- 将暴击概率也作为治疗加成 xhwsd@qq.com 2025-11-13
			_, _, _, _, rank = GetTalentInfo(3, 5)
			heal = heal * (1 * rank / 100 + 1)

			-- 治疗之道 Rank 0/3
			-- 你的治疗波和次级治疗波有[33/66/100]%的几率使你下一次治疗波或次级治疗波对该目标的治疗效果提高6%，持续15 sec，可叠加3次。
			_, _, _, _, rank = GetTalentInfo(3, 6)
			if rank then
				local layers = Buff:GetLayers("治疗之道", unit)
				if layers then
					-- 这相当于不用天赋等级改用层数来加成
					heal = heal * (6 * layers / 100 + 1)
				end
			end
		elseif spell == "治疗链" then

		end
	end

	OneMacro:DebugNote(3, "天赋对法术(%s)治疗加成(%.3f)和恢复加成(%.3f)", spell, heal, hot)
	return heal, hot
end

---预估法术治疗量
---@param spell string 法术名称
---@param level? number 法术级别；缺省为最高
---@param equipment? number 装备加成；缺省为`1`
---@param talentHeal? number 天赋治疗加成；缺省为`1`
---@param talentHot? number 天赋恢复加成；缺省为`1`
---@return number estimate 预估量；失败为`0`
function OneMacroHeal:EstimateHeal(spell, level, equipment, talentHeal, talentHot)
	equipment = equipment or 1
	talentHeal = talentHeal or 1
	talentHot = talentHot or 1

	-- 治疗法术
	if not self:IsHealSpell(spell) then
		return 0
	end

	-- 持续秒数
	local duration = self:GetSpellDuration(spell, level)
	if duration > 0 then
		-- 最小持续秒数 = 取最小(原持续秒数, 15秒)
		duration = math.min(duration, 15)
	end

	-- 施法秒数
	local casting = self:GetSpellCasting(spell, level)
	if casting > 0 then
		-- 最小施法秒数 = 取最小(原施法秒数, 3.5秒)
		casting = math.min(casting, 3.5)
	end

	-- 预估量
	local estimate = 0
	if casting > 0 and duration > 0 then -- 施法直接治疗和持续恢复（愈合）
		-- 持续恢复量
		local restore = Spell:GetRestore(spell, level)
		-- 预估恢复量 = (最小持续秒数 / 15秒 * 装备强度 / 2 + 持续恢复量) / 3（HOT部分仅算三分一） * 天赋恢复加成
		restore = (duration / 15 * equipment / 2 + restore) / 3 * talentHot
		-- 直接治疗量
		local heal = Spell:GetHeal(spell, level)
		-- 预估治疗量 = (最小施法秒数 / 3.5秒 / 2 * 装备强度 + 直接治疗量) * 天赋治疗加成
		heal = (casting / 3.5 / 2 * equipment + heal) * talentHeal
		-- 预估量 = 预估恢复量 + 预估治疗量
		estimate = restore + heal
	elseif casting > 0 and duration == 0 then -- 施法直接治疗（治疗之触）
		-- 直接治疗量
		local heal = Spell:GetHeal(spell, level)
		-- 预估量 = (最小施法秒数 / 3.5秒 * 装备强度 + 直接治疗量) * 天赋治疗加成
		estimate = (casting / 3.5 * equipment + heal) * talentHeal
	elseif casting == 0 and duration > 0 then -- 瞬发持续恢复（回春术）
		-- 持续恢复量
		local restore = Spell:GetRestore(spell, level)
		-- 预估量 = (最小持续秒数 / 15秒 * 装备强度 + 持续恢复量) * 天赋恢复加成
		estimate = (duration / 15 * equipment + restore) * talentHot
	elseif casting == 0 and duration == 0 then -- 瞬发直接治疗（神圣震击）
		-- 直接治疗量
		local heal = Spell:GetHeal(spell, level)
		-- 预估量 = (缺省1.5秒 * 装备强度 + 直接治疗量) * 天赋治疗加成
		estimate = (1.5 * equipment + heal) * talentHeal
	end

	-- 向下取整
	return math.floor(estimate)
end

---是否为当前玩家的治疗法术
---@param spell string 法术名称
---@return boolean is 是否
function OneMacroHeal:IsHealSpell(spell)
	local class = UnitClass("player")
	if type(spell) == "string" and spell ~= "" and HEAL_SPELLS[class] and HEAL_SPELLS[class][spell] then
		return true
	else
		return false
	end
end

---取当前玩家的原治疗法术信息
---@param spell string 法术名称
---@param name? string 属性名称
---@return any info 信息
function OneMacroHeal:GetHealInfo(spell, name)
	local class = UnitClass("player")
	if type(spell) == "string" and spell ~= "" and HEAL_SPELLS[class] and HEAL_SPELLS[class][spell] then
		if type(name) == "string" and name ~= "" then
			return HEAL_SPELLS[class][spell][name]
		else
			return HEAL_SPELLS[class][spell]
		end
	end
end

---取法术原施法秒数
---@param spell string 法术名称
---@param level? number 法术级别；缺省为最高
---@return number seconds 秒数
function OneMacroHeal:GetSpellCasting(spell, level)
	local casting = self:GetHealInfo(spell, "casting")
	if type(casting) == "table" then
		if level and casting[level] then
			-- 已适配等级
			return casting[level]
		else
			-- 未适配等级
			local count = table.getn(casting)
			return casting[count]
		end
	elseif casting then
		-- 无等级
		return casting
	else
		return 0
	end
end

---取法术原持续秒数
---@param spell string 法术名称
---@param level? number 法术级别；缺省为最高
---@return number seconds 秒数
function OneMacroHeal:GetSpellDuration(spell, level)
	local duration = self:GetHealInfo(spell, "duration")
	if type(duration) == "table" then
		if level and duration[level] then
			-- 已适配等级
			return duration[level]
		else
			-- 未适配等级
			local count = table.getn(duration)
			return duration[count]
		end
	elseif duration then
		-- 无等级
		return duration
	else
		return 0
	end
end

---取装备治疗强度；注意数据有延迟（如切换装备等）
---@return number? power 强度；成功为数值，否则为空
function OneMacroHeal:GetEquipmentPower()
	local power, plugin
	if BCS then
		local spellPower, _, _, damagePower = BCS:GetSpellPower()
		local healingPower = BCS:GetHealingPower()
		if not damagePower then
			spellPower, _, _, damagePower = BCS:GetLiveSpellPower()
			healingPower = BCS:GetLiveHealingPower()
		end
		healingPower = healingPower or 0
		spellPower = spellPower or 0
		damagePower = damagePower or 0
		power = tonumber(spellPower) + tonumber(healingPower) - tonumber(damagePower)
		plugin = "BetterCharacterStats"
	elseif BonusScanner then
		power = tonumber(BonusScanner:GetBonus("HEAL"))
		plugin = "BonusScanner"
	else
		OneMacro:DebugWarning(2, "未检测到插件(BetterCharacterStats或BonusScanner)，无法获取装备治疗强度")
		return
	end

	OneMacro:DebugNote(3, "通过插件(%s)获取装备强度(%d)", plugin, power)
	return power
end

---取装备护甲值
---@return number? armor 护甲
function OneMacroHeal:GetEquipmentArmor()
	local armor, plugin
	if BCS then
		armor = BCS:GetOnlyGearArmor()
		plugin = "BetterCharacterStats"
	elseif BonusScanner then
		armor = tonumber(BonusScanner:GetBonus("ARMOR"))
		plugin = "BonusScanner"
	else
		OneMacro:DebugWarning(2, "未检测到插件(BetterCharacterStats或BonusScanner)，无法获取装备护甲值")
		return
	end

	OneMacro:DebugNote(3, "通过插件(%s)获取装备护甲值(%d)", plugin, armor)
	return armor
end

---取精神值
---@return number? spirit 精神值
function OneMacroHeal:GetSpirit()
	local spirit, plugin
	if BCS then
		-- TODO 待实现 xhwsd@qq.com 2025-11-13
		spirit = 0
		plugin = "BetterCharacterStats"
	elseif BonusScanner then
		spirit = tonumber(BonusScanner:GetBonus("SPI"))
		plugin = "BonusScanner"
	else
		OneMacro:DebugWarning(2, "未检测到插件(BetterCharacterStats或BonusScanner)，无法获取精神值")
		return
	end

	OneMacro:DebugNote(3, "通过插件(%s)获取精神值(%d)", plugin, armor)
	return spirit
end
