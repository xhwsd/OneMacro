---@class CommonExtend:AceAddon-2.0 公用扩展模块 xhwsd@qq.com 2025-7-11
OneMacroCommon = OneMacro:NewModule("CommonExtend")

--[[ 依赖 ]]

local SpellCache = AceLibrary("SpellCache-1.0")
local Prompt = AceLibrary("KuBa-Prompt-1.0")
local Target = AceLibrary("KuBa-Target-1.0")
local Boss = AceLibrary("KuBa-Boss-1.0")
local Buff = AceLibrary("KuBa-Buff-1.0")
local Bleed = AceLibrary("KuBa-Bleed-1.0")
local State = AceLibrary("KuBa-State-1.0")
local Spell = AceLibrary("KuBa-Spell-1.0")
local Cast = AceLibrary("KuBa-Cast-1.0")
local Item = AceLibrary("KuBa-Item-1.0")

--[[ 事件 ]]

---初始化
function OneMacroCommon:OnInitialize()
	-- 计时列表
	self.timings = {}
end

---启用
function OneMacroCommon:OnEnable()
	self:RegisterWeights()
	self:RegisterDetects()
	self:RegisterActions()
end

---禁用
function OneMacroCommon:OnDisable()

end

---注册权重
function OneMacroCommon:RegisterWeights()
	OneMacro:RegisterWeights({
		["HealthLosePercentage"] = {
			name = "生命损失百分比",
			handle = function(config, unit, options)
				local unitId = OneMacroRoster:ToUnit(unit)
				if unitId then
					-- 团队单位
					local percentage = State:GetHealthLosePercentage(unitId)
					return percentage or 0
				elseif OneMacroRoster:isUnit(unit) then
					-- 名单单位
					local success, percentage = OneMacroRoster:SwitchTarget(unit, { State, "GetHealthLosePercentage" },
						"target")
					if success == false then
						OneMacro:DebugError(3, percentage)
						return 0
					end
					return percentage or 0
				else
					-- 其它单位
					local percentage = State:GetHealthLosePercentage(unit)
					return percentage or 0
				end
			end,
			remark = "根据单位的生命损失百分比分配权重",
		},
		["NoneBuff"] = {
			name = "无效果",
			options = {
				buff = {
					type = "string",
					name = "效果",
				},
			},
			handle = function(config, unit, options)
				local unitId = OneMacroRoster:ToUnit(unit)
				if unitId then
					-- 团队单位
					local kind = Buff:FindUnit(options.buff, unitId)
					return kind and 0 or 1
				elseif OneMacroRoster:isUnit(unit) then
					-- 名单单位
					local success, kind = OneMacroRoster:SwitchTarget(unit, { Buff, "FindUnit" }, options.buff, "target")
					if success == false then
						OneMacro:DebugError(3, percentage)
						return 0
					end
					return kind and 0 or 1
				else
					-- 其它单位
					local kind = Buff:FindUnit(options.buff, unit)
					return kind and 0 or 1
				end
			end,
			remark = "给与无指定效果的单位权重",
		},
		["HasBuff"] = {
			name = "有效果",
			options = {
				buff = {
					type = "string",
					name = "效果",
				},
			},
			handle = function(config, unit, options)
				local unitId = OneMacroRoster:ToUnit(unit)
				if unitId then
					-- 团队单位
					local kind = Buff:FindUnit(options.buff, unitId)
					return kind and 1 or 0
				elseif OneMacroRoster:isUnit(unit) then
					-- 名单单位
					local success, kind = OneMacroRoster:SwitchTarget(unit, { Buff, "FindUnit" }, options.buff, "target")
					if success == false then
						OneMacro:DebugError(3, percentage)
						return 0
					end
					return kind and 1 or 0
				else
					-- 其它单位
					local kind = Buff:FindUnit(options.buff, unit)
					return kind and 1 or 0
				end
			end,
			remark = "给与有指定效果的单位权重",
		}
	}, "Common", "公用", "公用相关权重")
end

---注册检测
function OneMacroCommon:RegisterDetects()
	OneMacro:RegisterDetects({
		--[[ 状态 ]]

		["Health"] = {
			name = "生命",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "生命",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local health = State:GetHealth(unit)
					return health
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, health = OneMacroRoster:SwitchTarget(options.unit, { State, "GetHealth" }, "target")
					if success == false then
						OneMacro:DebugError(3, health)
						return
					end
					return health
				else
					-- 其它单位
					local health = State:GetHealth(options.unit)
					return health
				end
			end,
			remark = "取单位当前生命",
		},
		["HealthMax"] = {
			name = "生命上限",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "上限",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local _, max = State:GetHealth(unit)
					return max
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, message, max = OneMacroRoster:SwitchTarget(options.unit, { State, "GetHealth" }, "target")
					if success == false then
						OneMacro:DebugError(3, message)
						return
					end
					return max
				else
					-- 其它单位
					local _, max = State:GetHealth(unit)
					return max
				end
			end,
			remark = "取单位当前生命上限",
		},
		["HealthPercentage"] = {
			name = "生命百分比",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "百分比",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local percentage = State:GetHealthPercentage(unit)
					return percentage
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, percentage = OneMacroRoster:SwitchTarget(options.unit, { State, "GetHealthPercentage" }, "target")
					if success == false then
						OneMacro:DebugError(3, percentage)
						return
					end
					return percentage
				else
					-- 其它单位
					local percentage = State:GetHealthPercentage(options.unit)
					return percentage
				end
			end,
			remark = "取单位当前生命百分比",
		},
		["HealthLose"] = {
			name = "生命损失",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "损失",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local lose = State:GetHealthLose(unit)
					return lose
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, lose = OneMacroRoster:SwitchTarget(options.unit, { State, "GetHealthLose" }, "target")
					if success == false then
						OneMacro:DebugError(3, lose)
						return
					end
					return lose
				else
					-- 其它单位
					local lose = State:GetHealthLose(options.unit)
					return lose
				end
			end,
			remark = "取单位当前生命损失",
		},
		["HealthLosePercentage"] = {
			name = "生命损失百分比",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "百分比",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local percentage = State:GetHealthLosePercentage(unit)
					return percentage
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, percentage = OneMacroRoster:SwitchTarget(options.unit, { State, "GetHealthLosePercentage" }, "target")
					if success == false then
						OneMacro:DebugError(3, percentage)
						return
					end
					return percentage
				else
					-- 其它单位
					local percentage = State:GetHealthLosePercentage(options.unit)
					return percentage
				end
			end,
			remark = "取单位当前生命损失百分比",
		},
		["Mana"] = {
			name = "法力",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "法力",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local mana = State:GetMana(unit)
					return mana
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, mana = OneMacroRoster:SwitchTarget(options.unit, { State, "GetMana" }, options.unit)
					if success == false then
						OneMacro:DebugError(3, mana)
						return
					end
					return mana
				else
					-- 其它单位
					local mana = State:GetMana(options.unit)
					return mana
				end
			end,
			remark = "取当前单位法力，仅限德鲁伊、猎人、法师、圣骑士、牧师、萨满祭司、术士",
		},
		["ManaMax"] = {
			name = "法力上限",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "上限",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local _, max = State:GetMana(unit)
					return max
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, message, max = OneMacroRoster:SwitchTarget(options.unit, { State, "GetMana" }, options.unit)
					if success == false then
						OneMacro:DebugError(3, message)
						return
					end
					return max
				else
					-- 其它单位
					local _, max = State:GetMana(options.unit)
					return max
				end
			end,
			remark = "取单位当前法力上限，仅限德鲁伊、猎人、法师、圣骑士、牧师、萨满祭司、术士",
		},
		["ManaPercentage"] = {
			name = "法力百分比",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "百分比",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local percentage = State:GetManaPercentage(unit)
					return percentage
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, percentage = OneMacroRoster:SwitchTarget(options.unit, { State, "GetManaPercentage" }, "target")
					if success == false then
						OneMacro:DebugError(3, percentage)
						return
					end
					return percentage
				else
					-- 其它单位
					local percentage = State:GetManaPercentage(options.unit)
					return percentage
				end
			end,
			remark = "取单位当前法力百分比，仅限德鲁伊、猎人、法师、圣骑士、牧师、萨满祭司、术士",
		},
		["ManaLose"] = {
			name = "法力损失",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "损失",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local lose = State:GetManaLose(unit)
					return lose
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, lose = OneMacroRoster:SwitchTarget(options.unit, { State, "GetManaLose" }, "target")
					if success == false then
						OneMacro:DebugError(3, lose)
						return
					end
					return lose
				else
					-- 其它单位
					local lose = State:GetManaLose(options.unit)
					return lose
				end
			end,
			remark = "取单位当前法力损失，仅限德鲁伊、猎人、法师、圣骑士、牧师、萨满祭司、术士",
		},
		["ManaLosePercentage"] = {
			name = "法力损失百分比",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "百分比",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local percentage = State:GetManaLosePercentage(unit)
					return percentage
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, percentage = OneMacroRoster:SwitchTarget(options.unit, { State, "GetManaLosePercentage" }, "target")
					if success == false then
						OneMacro:DebugError(3, percentage)
						return
					end
					return percentage
				else
					-- 其它单位
					local percentage = State:GetManaLosePercentage(options.unit)
					return percentage
				end
			end,
			remark = "取单位当前法力损失百分比；仅限德鲁伊、猎人、法师、圣骑士、牧师、萨满祭司、术士",
		},
		["Rage"] = {
			name = "怒气",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "怒气",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local rage = State:GetRage(unit)
					return rage
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, rage = OneMacroRoster:SwitchTarget(options.unit, { State, "GetRage" },
						options.unit)
					if success == false then
						OneMacro:DebugError(3, rage)
						return
					end
					return rage
				else
					-- 其它单位
					local rage = State:GetRage(options.unit)
					return rage
				end
			end,
			remark = "取单位当前怒气，仅限德鲁伊、战士",
		},
		["Energy"] = {
			name = "能量",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "能量",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local energy = State:GetEnergy(unit)
					return energy
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, energy = OneMacroRoster:SwitchTarget(options.unit, { State, "GetEnergy" }, options.unit)
					if success == false then
						OneMacro:DebugError(3, energy)
						return
					end
					return energy
				else
					-- 其它单位
					local energy = State:GetEnergy(options.unit)
					return energy
				end
			end,
			remark = "取单位当前能量值，仅限德鲁伊、盗贼",
		},

		--[[ 效果 ]]

		["HasBuff"] = {
			name = "有无效果",
			options = {
				buff = {
					type = "string",
					name = "效果",
					require = true,
					remark = "支持匹配表达式",
				},
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "boolean",
				remark = "有无",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					return Buff:FindUnit(options.buff, unit) ~= nil
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, kind = OneMacroRoster:SwitchTarget(options.unit, { Buff, "FindUnit" }, options.buff, "target")
					if success == false then
						OneMacro:DebugError(3, kind)
						return
					end
					return kind ~= nil
				else
					-- 其它单位
					return Buff:FindUnit(options.buff, options.unit) ~= nil
				end
			end,
			remark = "检测单位是否有效果",
		},
		["BuffLayers"] = {
			name = "效果层数",
			options = {
				buff = {
					type = "string",
					name = "效果",
					require = true,
					remark = "支持匹配表达式",
				},
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "层数",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					local layers = Buff:GetLayers(options.buff, unit)
					return layers
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, layers = OneMacroRoster:SwitchTarget(options.unit, { Buff, "GetLayers" }, options.buff, "target")
					if success == false then
						OneMacro:DebugError(3, layers)
						return
					end
					return layers
				else
					-- 其它单位
					local layers = Buff:GetLayers(options.buff, unit)
					return layers
				end
			end,
			remark = "取单位指定效果层数",
		},
		["BuffLevel"] = {
			name = "效果级别",
			options = {
				buff = {
					type = "string",
					name = "效果",
					require = true,
					remark = "支持匹配表达式",
				},
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "级别",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					return Buff:GetLevel(options.buff, unit)
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, level = OneMacroRoster:SwitchTarget(options.unit, { Buff, "GetLevel" }, options.buff, "target")
					if success == false then
						OneMacro:DebugError(3, level)
						return
					end
					return level
				else
					-- 其它单位
					return Buff:GetLevel(options.buff, options.unit)
				end
			end,
			remark = "取单位指定效果对于法术等级（如3级愈合），依赖SuperWoW模组",
		},
		["BuffSeconds"] = {
			name = "效果秒数",
			options = {
				buff = {
					type = "string",
					name = "效果",
					require = true,
					remark = "支持匹配表达式",
				},
			},
			result = {
				type = "number",
				remark = "秒数",
			},
			handle = function(config, filter, options)
				local seconds = Buff:GetSeconds(options.buff)
				return seconds
			end,
			remark = "取单位指定效果剩余秒数，仅支持自身",
		},
		["CanCurse"] = {
			name = "可否诅咒",
			options = {
				buff = {
					type = "string",
					name = "效果",
					require = true,
				},
				unit = {
					type = "string",
					name = "单位",
					default = "target",
				},
			},
			result = {
				type = "boolean",
				remark = "可否",
			},
			handle = function(config, filter, options)
				return self:CanCurse(options.buff, options.unit)
			end,
			remark = "检验自己可否对单位施加诅咒（Dot），依赖Cursive插件",
		},
		["CanBleed"] = {
			name = "可否流血",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "target",
				},
			},
			result = {
				type = "boolean",
				remark = "可否",
			},
			handle = function(config, filter, options)
				return Bleed:CanBleed(options.unit)
			end,
			remark = "检验单位可否施加流血",
		},

		-- [[ 法术 ]]

		["SpellReady"] = {
			name = "法术就绪",
			options = {
				spell = {
					type = "string",
					name = "法术",
					require = true,
				},
			},
			result = {
				type = "boolean",
				remark = "就绪",
			},
			handle = function(config, filter, options)
				return Spell:IsReady(options.spell)
			end,
			remark = "检验法术是否无冷却",
		},
		["SpellCooldown"] = {
			name = "法术冷却",
			options = {
				spell = {
					type = "string",
					name = "法术",
					require = true,
				}
			},
			result = {
				type = "number",
				remark = "秒数",
			},
			handle = function(config, filter, options)
				return Spell:GetCooldown(options.spell)
			end,
			remark = "取法术冷却剩余秒数",
		},
		["SpellRange"] = {
			name = "法术范围",
			options = {
				spell = {
					type = "string",
					name = "法术",
					require = true,
				},
				unit = {
					type = "string",
					name = "单位",
					default = "target",
				},
			},
			result = {
				type = "boolean",
				remark = "已在范围为真，未在范围为假",
			},
			handle = function(config, filter, options)
				return Spell:IsRange(option.spell, options.unit)
			end,
			remark = "取法术最范围（最大距离）",
		},
		["SpellConsume"] = {
			name = "法术消耗",
			options = {
				spell = {
					type = "string",
					name = "法术",
					require = true,
					remark = "会解析法术等级"
				},
				attach = {
					type = "number",
					name = "附加",
					default = 0,
				},
			},
			result = {
				type = "number",
				remark = "消耗",
			},
			handle = function(config, filter, options)
				local name, rank = SpellCache:GetSpellData(options.spell)
				if not name then
					OneMacro:DebugError(2, "解析法术名称失败")
					return
				end

				-- 当有节能施法时，取消耗将为nil
				local consume = Spell:GetConsume(name, rank) or 0
				return consume + options.attach
			end,
			remark = "取法术需要消耗的法力、怒气、能量",
		},
		["SpellCasting"] = {
			name = "法术施法",
			options = {
				spell = {
					type = "string",
					name = "法术",
					require = true,
				}
			},
			result = {
				type = "number",
				remark = "秒数",
			},
			handle = function(config, filter, options)
				return Spell:GetCasting(options.spell)
			end,
			remark = "取法术施展需要的秒数",
		},
		["Form"] = {
			name = "形态",
			result = {
				type = "string",
				remark = "形态",
			},
			handle = function(config, filter, options)
				return Spell:GetForm()
			end,
			remark = "取当前激活的形态、姿态、守护等",
		},

		--[[ 施法 ]]

		["IsCasting"] = {
			name = "是否正在施展",
			result = {
				type = "boolea",
				remark = "是否",
			},
			handle = function(config, filter, options)
				return Cast:IsCasting()
			end,
			remark = "检验当前是否正在施法",
		},
		["CastSpellName"] = {
			name = "施放法术名称",
			result = {
				type = "string",
				remark = "名称",
			},
			handle = function(config, filter, options)
				local name = Cast:GetSpell()
				return name
			end,
			remark = "取最近施展的法术名称",
		},
		["CastSpellRank"] = {
			name = "施放法术等级",
			result = {
				type = "string",
				remark = "等级",
			},
			handle = function(config, filter, options)
				local _, rank = Cast:GetSpell()
				return rank
			end,
			remark = "取最近施展的法术等级",
		},
		["CastSpellLevel"] = {
			name = "施放法术级别",
			result = {
				type = "number",
				remark = "级别",
			},
			handle = function(config, filter, options)
				local _, _, level = Cast:GetSpell()
				return level
			end,
			remark = "取最近施展的法术级别",
		},
		["CastTargetName"] = {
			name = "施法目标名称",
			result = {
				type = "string",
				remark = "名称",
			},
			handle = function(config, filter, options)
				local name = Cast:GetTarget()
				return name
			end,
			remark = "取最近施法的目标名称，无目标时为空字符串",
		},
		["CastAssistName"] = {
			name = "施法协助名称",
			result = {
				type = "string",
				remark = "名称",
			},
			handle = function(config, filter, options)
				local name = Cast:GetAssist()
				return name
			end,
			remark = "取最近施法协助目标的名称，无目标或不可协助时为自己（自我施法）",
		},
		["CastTargetHealth"] = {
			name = "施法目标生命",
			result = {
				type = "number",
				remark = "生命",
			},
			handle = function(config, filter, options)
				local name, guid, oneself = Cast:GetAssist()
				if oneself then
					return UnitHealth("player")
				elseif SUPERWOW_VERSION and guid then
					return UnitHealth(guid)
				elseif name then
					local success, health = Target:SwitchName(name, UnitHealth, "target")
					if success == false then
						OneMacro:DebugError(3, lose)
						return
					end
					return health
				end
			end,
			remark = "取最近施法目标的生命",
		},
		["CastTargetLose"] = {
			name = "施法目标失血",
			result = {
				type = "number",
				remark = "失血",
			},
			handle = function(config, filter, options)
				local name, guid, oneself = Cast:GetAssist()
				if oneself then
					return State:GetHealthLose("player")
				elseif SUPERWOW_VERSION and guid then
					return State:GetHealthLose(guid)
				elseif name then
					local success, lose = Target:SwitchName(name, { State, "GetHealthLose" }, "target")
					if success == false then
						OneMacro:DebugError(3, lose)
						return
					end
					return lose
				end
			end,
			remark = "取最近施法目标的失血",
		},
		["CastTargetLosePercentage"] = {
			name = "施法目标失血百分比",
			result = {
				type = "number",
				remark = "百分比",
			},
			handle = function(config, filter, options)
				local name, guid, oneself = Cast:GetAssist()
				if oneself then
					return State:GetHealthLosePercentage("player")
				elseif SUPERWOW_VERSION and guid then
					return State:GetHealthLosePercentage(guid)
				elseif name then
					local success, percentage = Target:SwitchName(name, { State, "GetHealthLosePercentage" }, "target")
					if success == false then
						OneMacro:DebugError(3, percentage)
						return
					end
					return percentage
				end
			end,
			remark = "取最近施法目标的失血百分比",
		},
		["CastAssistHealth"] = {
			name = "施法协助生命",
			result = {
				type = "number",
				remark = "生命",
			},
			handle = function(config, filter, options)
				local name, guid, oneself = Cast:GetAssist()
				if oneself then
					return UnitHealth("player")
				elseif SUPERWOW_VERSION and guid then
					return UnitHealth(guid)
				elseif name then
					local success, health = Target:SwitchName(name, UnitHealth, "target")
					if success == false then
						OneMacro:DebugError(3, lose)
						return
					end
					return health
				end
			end,
			remark = "取最近施法协助目标的生命，无目标或不可协助目标时为自己（自我施法）",
		},
		["CastAssistLose"] = {
			name = "施法协助失血",
			result = {
				type = "number",
				remark = "失血",
			},
			handle = function(config, filter, options)
				local name, guid, oneself = Cast:GetAssist()
				if oneself then
					return State:GetHealthLose("player")
				elseif SUPERWOW_VERSION and guid then
					return State:GetHealthLose(guid)
				elseif name then
					local success, lose = Target:SwitchName(name, { State, "GetHealthLose" }, "target")
					if success == false then
						OneMacro:DebugError(3, lose)
						return
					end
					return lose
				end
			end,
			remark = "取最近施法协助目标的失血，无目标或不可协助目标时为自己（自我施法）",
		},
		["CastAssistLosePercentage"] = {
			name = "施法协助失血百分比",
			result = {
				type = "number",
				remark = "百分比",
			},
			handle = function(config, filter, options)
				local name, guid, oneself = Cast:GetAssist()
				if oneself then
					return State:GetHealthLosePercentage("player")
				elseif SUPERWOW_VERSION and guid then
					return State:GetHealthLosePercentage(guid)
				elseif name then
					local success, percentage = Target:SwitchName(name, { State, "GetHealthLosePercentage" }, "target")
					if success == false then
						OneMacro:DebugError(3, percentage)
						return
					end
					return percentage
				end
			end,
			remark = "取最近施法协助目标的失血百分比，无目标或不可协助目标时为自己（自我施法）",
		},

		--[[ 物品 ]]

		["HasItem"] = {
			name = "具有物品",
			options = {
				name = {
					type = "string",
					name = "名称",
					require = true,
					remark = "身上装备或包中物品名称",
				},
			},
			result = {
				type = "boolean",
				remark = "具有",
			},
			handle = function(config, filter, options)
				return Item:Find(options.name) ~= nil
			end,
			remark = "检验是否具有指定名称物品",
		},
		["ItemReady"] = {
			name = "物品就绪",
			options = {
				name = {
					type = "string",
					name = "名称",
					require = true,
					remark = "身上装备或包中物品名称",
				},
			},
			result = {
				type = "boolean",
				remark = "就绪",
			},
			handle = function(config, filter, options)
				return Item:IsReady(options.name)
			end,
			remark = "检验身上装备或包中物品是否就绪",
		},
		["ItemTotal"] = {
			name = "物品总数",
			options = {
				name = {
					type = "string",
					name = "名称",
					require = true,
					remark = "仅限包中物品名称",
				},
			},
			result = {
				type = "number",
				remark = "总数",
			},
			handle = function(config, filter, options)
				return Item:Total(options.name)
			end,
			remark = "取背包中物品总数",
		},
		["TrinketReady"] = {
			name = "饰品就绪",
			options = {
				down = {
					type = "boolean",
					name = "下饰品",
					default = false,
				},
			},
			result = {
				type = "boolean",
				remark = "就绪",
			},
			handle = function(config, filter, options)
				return Item:TrinketReady(options.down)
			end,
			remark = "检验身饰品是否就绪",
		},
		["EquipmentName"] = {
			name = "装备名称",
			options = {
				slot = {
					type = "number",
					name = "插槽",
					require = true,
				},
			},
			result = {
				type = "string",
				remark = "名称",
			},
			handle = function(config, filter, options)
				return Item:GetName(options.slot)
			end,
			remark = "取指定插槽装备名称",
		},
		["SuitCount"] = {
			name = "套装计数",
			options = {
				suit = {
					type = "string",
					name = "套装",
					require = true,
					remark = "可选值：起源套甲、梦游者",
				},
			},
			result = {
				type = "number",
				remark = "计数",
			},
			handle = function(config, filter, options)
				return Item:SuitCount(options.suit)
			end,
			remark = "取已佩戴套装计数",
		},

		--[[ 人数 ]]

		["RaidMembers"] = {
			name = "团队人数",
			result = {
				type = "number",
				remark = "人数；（1~40）含自己",
			},
			handle = function(config, filter, options)
				return GetNumRaidMembers() or 0
			end,
			remark = "取当前团队人数（1~40），不在团队时为0",
		},
		["PartyMembers"] = {
			name = "队伍人数",
			result = {
				type = "number",
				remark = "人数；（1~4）不含自己",
			},
			handle = function(config, filter, options)
				return GetNumPartyMembers() or 0
			end,
			remark = "取当前队伍人数（1~4），不在队伍时为0",
		},
		["RosterMembers"] = {
			name = "名单人数",
			result = {
				type = "number",
				remark = "人数",
			},
			handle = function(config, filter, options)
				return OneMacroRoster:Count()
			end,
			remark = "取当前名单人数（1~N）",
		},

		--[[ 天赋 ]]

		["TalentName"] = {
			name = "天赋名称",
			options = {
				tab = {
					type = "number",
					name = "标签",
					require = true,
					remark = "标签索引（1~3）",
				},
				talent = {
					type = "number",
					name = "天赋",
					require = true,
					remark = "天赋索引（从左往右，从上往下，从1开始，数图标）",
				},
			},
			result = {
				type = "string",
				remark = "名称",
			},
			handle = function(config, filter, options)
				local name = GetTalentInfo(options.tab, options.talent)
				return name
			end,
			remark = "取指定天赋名称",
		},
		["TalentRank"] = {
			name = "天赋等级",
			options = {
				tab = {
					type = "number",
					name = "标签",
					require = true,
					remark = "标签索引（1~3）",
				},
				talent = {
					type = "number",
					name = "天赋",
					require = true,
					remark = "天赋索引（从左往右，从上往下，从1开始，数图标）",
				},
			},
			result = {
				type = "number",
				remark = "等级",
			},
			handle = function(config, filter, options)
				local _, _, _, _, rank = GetTalentInfo(options.tab, options.talent)
				return rank
			end,
			remark = "取指定天赋当前等级（已点）",
		},
		["TalentRankMax"] = {
			name = "天赋等级上限",
			options = {
				tab = {
					type = "number",
					name = "标签",
					require = true,
					remark = "标签索引（1~3）",
				},
				talent = {
					type = "number",
					name = "天赋",
					require = true,
					remark = "天赋索引（从左往右，从上往下，从1开始，数图标）",
				},
			},
			result = {
				type = "number",
				remark = "上限",
			},
			handle = function(config, filter, options)
				local _, _, _, _, maxRank = GetTalentInfo(options.tab, options.talent)
				return maxRank
			end,
			remark = "取指定天赋等级上限",
		},

		--[[ 其他 ]]

		["UnitName"] = {
			name = "单位名称",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "string",
				remark = "名称",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					return UnitName(unit) or ""
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					return OneMacroRoster:ToName(options.unit) or ""
				else
					-- 其它单位
					return UnitName(options.unit) or ""
				end
			end,
			remark = "取指定单位的名称",
		},
		["UnitClass"] = {
			name = "职业名称",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
					filter = "filter",
				},
			},
			result = {
				type = "string",
				remark = "名称",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					return UnitClass(unit) or ""
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, class = OneMacroRoster:SwitchTarget(options.unit, UnitClass, "target")
					if success == false then
						OneMacro:DebugError(3, class)
						return
					end
					return class
				else
					-- 其它单位
					return UnitClass(options.unit) or ""
				end
			end,
			remark = "取指定单位的职业名称",
		},
		["DistanceInterval"] = {
			name = "距离间隔",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "target",
					filter = "filter",
				},
			},
			result = {
				type = "number",
				remark = "间隔",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					return self:GetDistance(unit)
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, distance = OneMacroRoster:SwitchTarget(options.unit, { self, "GetDistance" },
						"target")
					if success == false then
						OneMacro:DebugError(3, distance)
						return
					end
					return distance
				else
					-- 其它单位
					return self:GetDistance(options.unit)
				end
			end,
			remark = "取与指定单位的距离间隔，依赖UnitXP模组",
		},
		["IsVisual"] = {
			name = "是否可视",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "target",
				},
			},
			result = {
				type = "boolean",
				remark = "可视",
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					return self:IsVisual(unit)
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, visual = OneMacroRoster:SwitchTarget(options.unit, { self, "IsVisual" }, "target")
					if success == false then
						OneMacro:DebugError(3, visual)
						return
					end
					return visual == true
				else
					-- 其它单位
					return self:IsVisual(options.unit)
				end
			end,
			remark = "检验当前是否可看见指定单位，依赖UnitXP模组",
		},
		["CanAssist"] = {
			name = "可否协助",
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
				remark = "可否",
			},
			handle = function(config, filter, options)
				if OneMacroRoster:isUnit(options.unit) then
					-- 仅可协助目标可加入名单
					local name = OneMacroRoster:ToName(options.unit)
					return name ~= nil
				else
					-- 其它单位
					return UnitCanAssist("player", options.unit)
				end
			end,
			remark = "检验当前玩家是否可协助指定单位",
		},
		["CanAttack"] = {
			name = "可否攻击",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "target",
				},
			},
			result = {
				type = "boolean",
				remark = "可否",
			},
			handle = function(config, filter, options)
				return UnitCanAttack("player", options.unit)
			end,
			remark = "检验当前玩家是否可攻击指定单位",
		},
		["IsExists"] = {
			name = "是否存在",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "target",
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
					return UnitExists(unit)
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, exists = OneMacroRoster:SwitchTarget(options.unit, UnitExists, "target")
					if success == false then
						OneMacro:DebugError(3, exists)
						return
					end
					return result == true
				else
					-- 其它单位
					return UnitExists(options.unit)
				end
			end,
			remark = "检验单位是否存在",
		},
		["IsCombat"] = {
			name = "是否战斗中",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "player",
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
					return UnitAffectingCombat(unit) ~= nil
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, combat = OneMacroRoster:SwitchTarget(options.unit, UnitAffectingCombat, "target")
					if success == false then
						OneMacro:DebugError(3, combat)
						return
					end
					return result ~= nil
				else
					-- 其它单位
					return UnitAffectingCombat(options.unit) ~= nil
				end
			end,
			remark = "检验单位是否正在战斗中",
		},
		["IsBoss"] = {
			name = "是否为首领",
			options = {
				unit = {
					type = "string",
					name = "单位",
					default = "target",
				},
				health = {
					type = "number",
					name = "血量",
					default = 100000,
					remark = "当血量高于该值时，也视为首领"
				},
			},
			result = {
				type = "boolean",
				remark = "是否",
			},
			handle = function(config, filter, options)
				return Boss:Is(options.unit, options.health)
			end,
			remark = "检验单位是否是首领",
		},
		["TimeInterval"] = {
			name = "时间间隔",
			options = {
				name = {
					type = "string",
					name = "名称",
					default = "默认",
				},
			},
			result = {
				type = "number",
				remark = "间隔",
			},
			handle = function(config, filter, options)
				if self.timings[options.name] then
					return GetTime() - self.timings[options.name]
				end
			end,
			remark = "取与上次计时之间间隔秒数",
		},
	}, "Common", "公用", "公用相关检测")
end

---注册动作
function OneMacroCommon:RegisterActions()
	OneMacro:RegisterActions({
		--[[ 输出 ]]

		["Chat"] = {
			name = "聊天",
			options = {
				content = {
					type = "string",
					name = "内容",
					default = "嗨！",
					remark =
					"支持插值：{PlayerName}、{PlayerHealth}、{PlayerMana}、{TargetName}、{TargetTargetName}、{FilterName}、{AssistName}、{SpellName}",
				},
				type = {
					type = "string",
					name = "类型",
					default = "SAY",
					remark = "类型可选值：SAY、YELL、PARTY、RAID",
				},
			},
			handle = function(config, filter, options)
				-- 准备数据
				local data = {
					PlayerName = UnitName("player"),
					PlayerHealth = UnitHealth("player"),
					PlayerMana = UnitMana("player"),
					TargetName = UnitName("target"),
					TargetTargetName = UnitName("targettarget"),
					AssistName = Cast:GetAssist(),
					SpellName = Cast:GetSpell(),
				}

				-- 筛选名称
				if not filter or filter == "" then
					data["FilterName"] = nil
				elseif OneMacroRoster:isUnit(filter) then
					data["FilterName"] = OneMacroRoster:ToName(filter)
				else
					data["FilterName"] = UnitName(filter)
				end

				-- 替换插值
				options.content = OneMacroHelper:ReplaceInterpolation(options.content, data)

				-- 聊天
				SendChatMessage(options.content, options.type)
			end,
		},
		["Prompt"] = {
			name = "提示",
			options = {
				content = {
					type = "string",
					name = "内容",
					default = "嗨！",
					remark =
					"支持插值：{PlayerName}、{PlayerHealth}、{PlayerMana}、{TargetName}、{TargetTargetName}、{FilterName}、{AssistName}、{SpellName}",
				},
				type = {
					type = "string",
					name = "类型",
					default = "default",
					remark = "类型可选值：default、info、warning、error",
				},
			},
			handle = function(config, filter, options)
				-- 准备数据
				local data = {
					PlayerName = UnitName("player"),
					PlayerHealth = UnitHealth("player"),
					PlayerMana = UnitMana("player"),
					TargetName = UnitName("target"),
					TargetTargetName = UnitName("targettarget"),
					AssistName = Cast:GetAssist(),
					SpellName = Cast:GetSpell(),
				}

				-- 筛选名称
				if not filter or filter == "" then
					data["FilterName"] = nil
				elseif OneMacroRoster:isUnit(filter) then
					data["FilterName"] = OneMacroRoster:ToName(filter)
				else
					data["FilterName"] = UnitName(filter)
				end

				-- 替换插值
				options.content = OneMacroHelper:ReplaceInterpolation(options.content, data)

				-- 提示
				if options.type == "info" then
					Prompt:Info(options.content)
				elseif options.type == "warning" then
					Prompt:Warning(options.content)
				elseif options.type == "error" then
					Prompt:Error(options.content)
				else
					Prompt:Add(options.content)
				end
			end,
		},
		["Print"] = {
			name = "打印",
			options = {
				content = {
					type = "string",
					name = "内容",
					default = "嗨！",
					remark =
					"支持插值：{PlayerName}、{PlayerHealth}、{PlayerMana}、{TargetName}、{TargetTargetName}、{FilterName}、{AssistName}、{SpellName}",
				},
			},
			handle = function(config, filter, options)
				-- 准备数据
				local data = {
					PlayerName = UnitName("player"),
					PlayerHealth = UnitHealth("player"),
					PlayerMana = UnitMana("player"),
					TargetName = UnitName("target"),
					TargetTargetName = UnitName("targettarget"),
					AssistName = Cast:GetAssist(),
					SpellName = Cast:GetSpell(),
				}

				-- 筛选名称
				if not filter or filter == "" then
					data["FilterName"] = nil
				elseif OneMacroRoster:isUnit(filter) then
					data["FilterName"] = OneMacroRoster:ToName(filter)
				else
					data["FilterName"] = UnitName(filter)
				end

				-- 替换插值
				options.content = OneMacroHelper:ReplaceInterpolation(options.content, data)

				-- 打印
				print(options.content)
			end,
		},
		["Debug"] = {
			name = "调试",
			options = {
				content = {
					type = "string",
					name = "内容",
					default = "嗨！",
					remark =
					"支持插值：{PlayerName}、{PlayerHealth}、{PlayerMana}、{TargetName}、{TargetTargetName}、{FilterName}、{AssistName}、{SpellName}",
				},
				type = {
					type = "string",
					name = "类型",
					default = "default",
					remark = "类型可选值：default、info、warning、error",
				},
			},
			handle = function(config, filter, options)
				-- 准备数据
				local data = {
					PlayerName = UnitName("player"),
					PlayerHealth = UnitHealth("player"),
					PlayerMana = UnitMana("player"),
					TargetName = UnitName("target"),
					TargetTargetName = UnitName("targettarget"),
					AssistName = Cast:GetAssist(),
					SpellName = Cast:GetSpell(),
				}

				-- 筛选名称
				if not filter or filter == "" then
					data["FilterName"] = nil
				elseif OneMacroRoster:isUnit(filter) then
					data["FilterName"] = OneMacroRoster:ToName(filter)
				else
					data["FilterName"] = UnitName(filter)
				end

				-- 替换插值
				options.content = OneMacroHelper:ReplaceInterpolation(options.content, data)

				-- 调试输出
				if options.type == "info" then
					OneMacro:DebugInfo(2, options.content)
				elseif options.type == "warning" then
					OneMacro:DebugWarning(2, options.content)
				elseif options.type == "error" then
					OneMacro:DebugError(2, options.content)
				else
					OneMacro:Debug(options.content)
				end
			end,
		},

		--[[ 法术 ]]

		["CastSpell"] = {
			name = "施放法术",
			options = {
				spell = {
					type = "string",
					name = "法术",
					require = true,
				},
				unit = {
					type = "string",
					name = "单位",
					default = "target",
					filter = "filter",
				},
			},
			handle = function(config, filter, options)
				local unit = OneMacroRoster:ToUnit(options.unit)
				if unit then
					-- 团队单位
					Spell:Cast(options.spell, unit)
				elseif OneMacroRoster:isUnit(options.unit) then
					-- 名单单位
					local success, message = OneMacroRoster:SwitchTarget(options.unit, { Spell, "Cast" },
						options.spell, "target", options.queue)
					if success == false then
						OneMacro:DebugError(3, message)
						return
					end
				else
					-- 其它单位
					Spell:Cast(options.spell, options.unit)
				end
			end,
			remark = "施放指定名称法术",
		},
		["SwitchForm"] = {
			name = "切换形态",
			options = {
				form = {
					type = "string",
					name = "形态",
					require = true,
					remark = "支持形态名称，如`*熊形态`",
				}
			},
			handle = function(config, filter, options)
				Spell:SwitchForm(options.form)
			end,
			remark = "切换到指定形态，兼容重复调用",
		},

		--[[ 施法 ]]

		["StopCasting"] = {
			name = "停止施展",
			handle = function(config, filter, options)
				-- 打断施放
				SpellStopCasting()
			end,
			remark = "停止当前正在施展的法术",
		},

		--[[ 物品 ]]

		["UseItem"] = {
			name = "使用物品",
			options = {
				name = {
					type = "string",
					name = "name",
					require = true,
					remark = "身上装备或包中物品名称",
				},
			},
			handle = function(config, filter, options)
				Item:Use(options.name)
			end,
			remark = "如果可以将切换装备",
		},
		["UseTrinket"] = {
			name = "使用饰品",
			options = {
				down = {
					type = "boolean",
					name = "饰品",
					remark = "是否为下饰品",
				},
			},
			handle = function(config, filter, options)
				Item:UseTrinket(options.down)
			end,
		},

		--[[ 其它 ]]

		["RecordTime"] = {
			name = "记录时间",
			options = {
				name = {
					type = "string",
					name = "名称",
					default = "默认",
				},
			},
			handle = function(config, filter, options)
				self.timings[options.name] = GetTime()
			end,
			remark = "记录当前时间",
		},
	}, "Common", "公用", "公用相关动作")
end

--[[ 效果 ]]

---可否对单位施加诅咒；依赖`Cursive`插件，否则仅在无debuff时可施放
---@param debuff string 减益
---@param unit? string 单位；缺省为`target`
---@return boolean can 可否
function OneMacroCommon:CanCurse(debuff, unit)
	unit = unit or "target"

	if type(Cursive) == "table" then
		-- 有Cursive插件
		local _, guid = UnitExists(unit)
		if guid then
			return Cursive.curses:HasCurse(debuff, guid) ~= true
		else
			return false
		end
	else
		-- 仅在确定没debuff时，可施放
		-- 注意：怪物会使用deuff位
		return not Buff:FindUnit(debuff, unit)
	end
end

--[[ 其它 ]]

---取自身与单位之间距离
---@param unit? string 单位；缺省为`target`
---@return number? distance 距离
function OneMacroCommon:GetDistance(unit)
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

	OneMacro:DebugWarning(2, "未检测到模组(UnitXP)")
end

---是否可视；检验单位是否在玩家视线内
---@param unit string? 单位；缺省为`target`
---@return boolean visual 可视
function OneMacroCommon:IsVisual(unit)
	unit = unit or "target"

	-- 单位是自己
	if UnitIsUnit(unit, "player") then
		return true
	end

	-- 单位存在
	local exist, guid = UnitExists(unit)
	if not exist then
		return false
	end

	-- 客户端不可见
	if not UnitIsVisible(unit) then
		return false
	end

	-- 初始缓存
	if not self.sights then
		self.sights = {}
	end

	-- 从读取缓存
	local x1, y1, z1 = self:GetPosition("player")
	local x2, y2, z2 = self:GetPosition(unit)
	if guid and self.sights[guid] then
		if
			self.sights[guid].x1 == x1 and self.sights[guid].y1 == y1 and self.sights[guid].z1 == z1
			and
			self.sights[guid].x2 == x2 and self.sights[guid].y2 == y2 and self.sights[guid].z2 == z2
		then
			return self.sights[guid].visual
		end
	end

	-- 检查视线 https://github.com/MarcelineVQ/UnitXP_SP3
	local success, result = pcall(UnitXP, "inSight", "player", unit)
	if not success then
		OneMacro:DebugWarning(2, "未检测到模组(UnitXP)")
		return false
	end

	-- 在视线内为true，不在视线内为false，错误为nil
	result = result == true

	-- 缓存结果
	if guid and x1 and y1 and z1 and x2 and y2 and z2 then
		self.sights[guid] = {
			x1 = x1,
			y1 = y1,
			z1 = z1,
			x2 = x2,
			y2 = y2,
			z2 = z2,
			visual = result
		}
	end
	return result
end

---取单位位置
---@param unit string? 单位；缺省为`player`
---@return number? x X坐标
---@return number? y Y坐标
---@return number? z Z坐标
function OneMacroCommon:GetPosition(unit)
	unit = unit or "player"

	-- 取三维坐标，依赖SuperWoW模组
	if SUPERWOW_VERSION and UnitIsFriend("player", unit) then
		-- 取友善单位相对世界绝对坐标 https://github.com/balakethelock/SuperWoW/wiki/Features
		return UnitPosition(unit)
	end

	-- 取二维坐标
	if UnitIsUnit(unit, "player") or UnitInRaid(unit) or UnitInParty(unit) then
		-- 取自身或队友相对当前地图缩放坐标
		local x, y = GetPlayerMapPosition(unit)
		if x > 0 and y > 0 then
			return x, y, 0
		end
	end
end
