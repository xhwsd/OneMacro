---@class OneMacro:AceAddon-2.0,AceConsole-2.0,AceDebug-2.0,AceDB-2.0,AceEvent-2.0,FuBarPlugin-2.0,AceModuleCore-2.0 一键宏插件 xhwsd@qq.com 2025-6-27
---@field db {profile:OM_Profile} 数据
OneMacro = AceLibrary("AceAddon-2.0"):new(
-- 控制台
	"AceConsole-2.0",
	-- 调试
	"AceDebug-2.0",
	-- 数据库
	"AceDB-2.0",
	-- 事件
	"AceEvent-2.0",
	-- 小地图菜单
	"FuBarPlugin-2.0",
	-- 模块核心
	"AceModuleCore-2.0"
)

-- 通报类型
local REPORT_KINDS = {
	["CastInstant"] = {
		name = "施法瞬发",
		remark = "施法瞬发后触发",
		expand = false,
		order = 1,
		reports = {},
	},
	["CastFailure"] = {
		name = "施法失败",
		remark = "施放失败后触发",
		expand = false,
		order = 2,
		reports = {},
	},
	["CastCastingStart"] = {
		name = "施法读条开始",
		remark = "施法读条开始触发",
		expand = false,
		order = 3,
		reports = {},
	},
	["CastCastingChange"] = {
		name = "施法读条改变",
		remark = "施法读条改变触发",
		expand = false,
		order = 4,
		reports = {},
	},
	["CastCastingFinish"] = {
		name = "施法读条完成",
		remark = "施法读条完成触发",
		expand = false,
		order = 5,
		reports = {},
	},
	["CastChannelingStart"] = {
		name = "施法引导开始",
		remark = "施法引导开始触发",
		expand = false,
		order = 6,
		reports = {},
	},
	["CastChannelingChange"] = {
		name = "施法引导改变",
		remark = "施法引导改变触发",
		expand = false,
		order = 7,
		reports = {},
	},
	["CastChannelingFinish"] = {
		name = "施法引导完成",
		remark = "施法引导完成触发",
		expand = false,
		order = 8,
		reports = {},
	},
	["AuraCancel"] = {
		name = "光环取消",
		remark = "光环取消触发",
		expand = false,
		order = 9,
		reports = {},
	},
	["BuffGain"] = {
		name = "增益获得",
		remark = "获得增益效果触发",
		expand = false,
		order = 10,
		reports = {},
	},
	["BuffLost"] = {
		name = "增益失去",
		remark = "失去增益效果触发",
		expand = false,
		order = 11,
		reports = {},
	},
	["DebuffGain"] = {
		name = "减益获得",
		remark = "获得减益效果触发",
		expand = false,
		order = 12,
		reports = {},
	},
	["DebuffLost"] = {
		name = "减益失去",
		remark = "失去减益效果触发",
		expand = false,
		order = 13,
		reports = {},
	},
	["SpellHit"] = {
		name = "法术已命中",
		remark = "法术已命中触发",
		expand = false,
		order = 14,
		reports = {},
	},
	["SpellMiss"] = {
		name = "法术未命中",
		remark = "法术未命中（抵抗、格挡、躲闪等）触发",
		expand = false,
		order = 15,
		reports = {},
	},
	["SpellLeech"] = {
		name = "法术吸收",
		remark = "法术被吸收触发",
		expand = false,
		order = 16,
		reports = {},
	},
	["SpellDispel"] = {
		name = "法术驱散",
		remark = "法术被驱散触发",
		expand = false,
		order = 17,
		reports = {},
	},
}

-- 注册数据
OneMacro:RegisterDB("OneMacroDB")

-- 注册默认值
OneMacro:RegisterDefaults("profile", {
	-- 将操作字段定义到属性下，可享受对象传址，赋值操作方便
	---@type OM_StrategyProfile 策略资料
	strategy = {
		list = {},
		selected = 0,
	},
	---@type OM_WeightProfile 权重资料
	weight = {
		expands = {},
		selected = 0,
	},
	---@type OM_DetectProfile 检测资料
	detect = {
		expands = {},
		selected = 0,
	},
	---@type OM_ActionProfile 动作资料
	action = {
		expands = {},
		selected = 0,
	},
	---@type OM_ReportProfile 通报资料
	report = {
		list = REPORT_KINDS,
		selected = 0,
	},
	---@type OM_RosterProfile 名单资料
	roster = {
		list = {},
		show = true,
	},
	-- 调试
	debug = {
		-- 开启
		enable = true,
		-- 等级
		level = 2
	},
})

---@type table<string,OM_WeightSpace> 已注册权重，由插件等动态注册
OneMacro.weights = {}
---@type table<string,OM_DetectSpace> 已注册检测，由插件等动态注册
OneMacro.detects = {}
---@type table<string,OM_ActionSpace> 已注册动作，由插件等动态注册
OneMacro.actions = {}

--[[ 依赖 ]]

local Tablet = AceLibrary("Tablet-2.0")
local SpellStatus = AceLibrary("SpellStatus-1.0")
local AuraEvent = AceLibrary("SpecialEvents-Aura-2.0")
local Dewdrop = AceLibrary("Dewdrop-2.0")
local Parser = ParserLib:GetInstance("1.1")
local Array = AceLibrary("KuBa-Array-1.0")
local Chat = AceLibrary("KuBa-Chat-1.0")
local Prompt = AceLibrary("KuBa-Prompt-1.0")
local Cast = AceLibrary("KuBa-Cast-1.0")

--[[ 事件 ]]

---初始化
function OneMacro:OnInitialize()
	-- 精简标题
	self.title = "一键宏"
	-- 恢复调试模式
	self:SetDebugging(self.db.profile.debug.enable)
	-- 恢复调试等级
	self:SetDebugLevel(self.db.profile.debug.level)

	-- 具有图标
	self.hasIcon = true
	-- 小地图图标
	self:SetIcon("Interface\\Icons\\Ability_Warrior_Charge")
	-- 默认位置
	self.defaultPosition = "LEFT"
	-- 默认小地图位置
	self.defaultMinimapPosition = 260
	-- 无法分离提示（标签）
	self.cannotDetachTooltip = false
	-- 角色独立配置
	self.independentProfile = true
	-- 挂载时是否隐藏
	self.hideWithoutStandby = false
	-- 注册菜单项
	self.OnMenuRequest = {
		type = "group",
		handler = self,
		args = {
			editor = {
				type = "execute",
				name = "编辑器",
				desc = "切换显示编辑器",
				order = 1,
				func = function()
					OneMacroEditor:SwitchShow()
					Dewdrop:Close()
				end
			},
			roster = {
				type = "execute",
				name = "名单",
				desc = "切换显示名单",
				order = 2,
				func = function()
					OneMacroRoster:SwitchShow()
					Dewdrop:Close()
				end
			},
			debug = {
				type = "group",
				name = "调试",
				desc = "插件调试相关设置",
				order = 3,
				args = {
					level = {
						type = "range",
						name = "调试等级",
						desc = "等级越高输出信息越多",
						order = 1,
						min = 1,
						max = 3,
						step = 1,
						get = function()
							return self.db.profile.debug.level
						end,
						set = function(value)
							self:SetDebugLevel(value)
							self.db.profile.debug.level = value
						end
					},
					enable = {
						type = "toggle",
						name = "调试模式",
						desc = "关闭将不输出任何信息",
						order = 2,
						get = function()
							return self.db.profile.debug.enable
						end,
						set = function(value)
							self:SetDebugging(value)
							self.db.profile.debug.enable = value
						end
					}
				}
			}
		}
	}

	-- 注册聊天命令
	self:RegisterChatCommand({ "/OM", "/OneMacro" }, {
		type = "group",
		desc = "描述",
		args = {
			strategy = {
				type = "group",
				name = "策略",
				desc = "策略相关操作",
				order = 1,
				args = {
					execute = {
						type = "text",
						name = "执行",
						desc = "执行指定策略",
						order = 1,
						usage = "<name>",
						validate = function(name)
							return self:ToStrategy(name) ~= nil
						end,
						set = function(name)
							self:ExecuteStrategy(name)
						end,
						get = false,
					},
					import = {
						type = "text",
						name = "导入",
						desc = "从文件导入宏",
						order = 2,
						usage = "<file>",
						set = function(file)
							local error, count = self:ImportStrategys(file)
							if error == "" then
								self:PrintInfo("成功导入%d个策略", count)
							else
								self:PrintError("导入策略失败：" .. error)
							end
						end,
						get = false,
					},
					export = {
						type = "text",
						name = "导出",
						desc = "将策略导出到文件",
						order = 3,
						usage = "<file>",
						set = function(file)
							local error, count = self:ExportStrategys(file)
							if error == "" then
								self:PrintInfo("成功导出%d个策略", count)
							else
								self:PrintError("导出策略失败：" .. error)
							end
						end,
						get = false,
					},
					clear = {
						type = "execute",
						name = "清空",
						desc = "清空所有策略",
						order = 4,
						func = function()
							local error, count = self:ClearStrategys()
							if error == "" then
								self:PrintInfo("清空%d个策略", count)
							else
								self:PrintError("清空策略失败：" .. error)
							end
						end,
					},
				},
			},
			report = {
				type = "group",
				name = "通报",
				desc = "通报相关操作",
				order = 2,
				args = {
					import = {
						type = "text",
						name = "导入",
						desc = "从文件导入通报",
						order = 1,
						usage = "<file>",
						set = function(file)
							local error, count = self:ImportReports(file)
							if error == "" then
								self:PrintInfo("成功导入%d个通报", count)
							else
								self:PrintError("导入通报失败：" .. error)
							end
						end,
						get = false,
					},
					export = {
						type = "text",
						name = "导出",
						desc = "将通报导出到文件",
						order = 2,
						usage = "<file>",
						set = function(file)
							local error, count = self:ExportReports(file)
							if error == "" then
								self:PrintInfo("成功导出%d个通报", count)
							else
								self:PrintError("导出通报失败：" .. error)
							end
						end,
						get = false,
					},
					clear = {
						type = "execute",
						name = "清空",
						desc = "清空所有通报",
						order = 3,
						func = function()
							local error, count = self:ClearReports()
							if error == "" then
								self:PrintInfo("清空%d个通报", count)
							else
								self:PrintError("清空通报失败：" .. error)
							end
						end,
					},
				},
			},
			roster = {
				type = "group",
				name = "名单",
				desc = "名单相关操作",
				order = 3,
				args = {
					show = {
						type = "execute",
						name = "显示",
						desc = "切换显示名单",
						order = 1,
						func = function()
							OneMacroRoster:SwitchShow()
						end,
					},
				}
			},
			editor = {
				type = "group",
				name = "编辑器",
				desc = "切换显示",
				order = 4,
				args = {
					show = {
						type = "execute",
						name = "显示",
						order = 1,
						desc = "切换显示编辑器",
						func = function()
							OneMacroEditor:SwitchShow()
						end,
					},
				}
			},
		},
	})
end

---启用
function OneMacro:OnEnable()
	self:PrintWarning("如有建议或错误请至 https://gitee.com/ku-ba/OneMacro 反馈！")

	self.debugFrame = OneMacroHelper:GetChatWindow("调试")

	-- 施法瞬发
	self:RegisterEvent("SpellStatus_SpellCastInstant")
	-- 施法失败
	self:RegisterEvent("SpellStatus_SpellCastFailure")
	-- 施法施展开始
	self:RegisterEvent("SpellStatus_SpellCastCastingStart")
	-- 施法施展改变
	self:RegisterEvent("SpellStatus_SpellCastCastingChange")
	-- 施法施展完成
	self:RegisterEvent("SpellStatus_SpellCastCastingFinish")
	-- 施法引导开始
	self:RegisterEvent("SpellStatus_SpellCastChannelingStart")
	-- 施法引导改变
	self:RegisterEvent("SpellStatus_SpellCastChannelingChange")
	-- 施法引导完成
	self:RegisterEvent("SpellStatus_SpellCastChannelingFinish")
	-- 施法取消光环（效果）
	self:RegisterEvent("SpellStatus_SpellCastCancelAura")

	-- 自身增益获得
	self:RegisterEvent("SpecialEvents_PlayerBuffGained")
	-- 自身增益失去
	self:RegisterEvent("SpecialEvents_PlayerBuffLost")
	-- 自身减益获得
	self:RegisterEvent("SpecialEvents_PlayerDebuffGained")
	-- 自身减益失去
	self:RegisterEvent("SpecialEvents_PlayerDebuffLost")

	-- 自身施放伤害法术（如月火术）
	Parser:RegisterEvent(
		"OneMacro",
		"CHAT_MSG_SPELL_SELF_DAMAGE",
		function(event, info)
			self:OnParserSelfDamage(event, info)
		end
	)
	-- 自身增益（或物品）造成伤害（如荆棘术）
	Parser:RegisterEvent(
		"OneMacro",
		"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",
		function(event, info)
			self:OnParserSelfDamage(event, info)
		end
	)
end

---禁用
function OneMacro:OnDisable()
	-- 注销事件
	self:UnregisterAllEvents()
	self:CancelAllScheduledEvents()
	Parser:UnregisterAllEvents("OneMacro")
end

---提示更新
function OneMacro:OnTooltipUpdate()
	-- 置标题
	Tablet:SetTitle(self.title .. " v" .. self.version)
	-- 置提示
	Tablet:SetHint("\n左键-编辑器\n右键-菜单\nALT+左键-名单")
end

---小地图图标单击
---@param button string 按钮
function OneMacro:OnClick(button)
	if button == "LeftButton" then
		-- 左键按下
		if IsAltKeyDown() then
			-- 按住ALT
			OneMacroRoster:SwitchShow()
		else
			OneMacroEditor:SwitchShow()
		end
	end
end

---施法瞬发
---@param id number 法术标识
---@param name string 法术名称
---@param rank string 法术等级
---@param fullName string 法术全名
function OneMacro:SpellStatus_SpellCastInstant(id, name, rank, fullName)
	self:EventReport("CastInstant", name, {
		SpellName = name,
	})
end

---施法失败
---@param id number 法术标识
---@param name string 法术名称
---@param rank string 法术等级
---@param fullName string 法术全名
---@param isActiveSpell boolean 是否主动施法
---@param UIEM_Message string 施法失败消息
---@param CMSFLP_SpellName string 施法失败消息
---@param CMSFLP_Message string 施法失败消息
function OneMacro:SpellStatus_SpellCastFailure(id, name, rank, fullName, isActiveSpell, UIEM_Message,
											   CMSFLP_SpellName, CMSFLP_Message)
	self:EventReport("CastFailure", name, {
		SpellName = name,
	})
end

---施法施展开始
---@param id number 法术标识
---@param name string 法术名称
---@param rank string 法术等级
---@param fullName string 法术全名
---@param castStartTime number 施法开始时间
---@param castStopTime number 施法结束时间
---@param castDuration number 施法持续时间
function OneMacro:SpellStatus_SpellCastCastingStart(id, name, rank, fullName, castStartTime, castStopTime,
													castDuration)
	self:EventReport("CastCastingStart", name, {
		SpellName = name,
	})
end

---施法施展改变
---@param id number 法术标识
---@param name string 法术名称
---@param rank string 法术等级
---@param fullName string 法术全名
---@param castStartTime number 施法开始时间
---@param castStopTime number 施法结束时间
---@param castDuration number 施法持续时间
---@param castDelay number 施法延迟
---@param castDelayTotal number 施法总延迟
function OneMacro:SpellStatus_SpellCastCastingChange(id, name, rank, fullName, castStartTime, castStopTime,
													 castDuration, castDelay, castDelayTotal)
	self:EventReport("CastCastingChange", name, {
		SpellName = name,
	})
end

---施法施展完成
---@param id number 法术标识
---@param name string 法术名称
---@param rank string 法术等级
---@param fullName string 法术全名
---@param castStartTime number 施法开始时间
---@param castStopTime number 施法结束时间
---@param castDuration number 施法持续时间
---@param castDelayTotal number 施法总延迟
function OneMacro:SpellStatus_SpellCastCastingFinish(id, name, rank, fullName, castStartTime, castStopTime,
													 castDuration, castDelayTotal)
	self:EventReport("CastCastingFinish", name, {
		SpellName = name,
	})
end

---施法引导开始
---@param id number 法术标识
---@param name string 法术名称
---@param rank string 法术等级
---@param fullName string 法术全名
---@param castStartTime number 施法开始时间
---@param castStopTime number 施法结束时间
---@param castDuration number 施法持续时间
---@param action number 施法动作
function OneMacro:SpellStatus_SpellCastChannelingStart(id, name, rank, fullName, castStartTime, castStopTime,
													   castDuration, action)
	self:EventReport("CastChannelingStart", name, {
		SpellName = name,
	})
end

---施法引导改变
---@param id number 法术标识
---@param name string 法术名称
---@param rank string 法术等级
---@param fullName string 法术全名
---@param castStartTime number 施法开始时间
---@param castStopTime number 施法结束时间
---@param castDuration number 施法持续时间
---@param action number 施法动作
---@param castDisruption number 施法中断
---@param castDisruptionTotal number 施法总中断
function OneMacro:SpellStatus_SpellCastChannelingChange(id, name, rank, fullName, castStartTime, castStopTime,
														castDuration, action, castDisruption, castDisruptionTotal)
	self:EventReport("CastChannelingChange", name, {
		SpellName = name,
	})
end

---施法引导完成
---@param id number 法术标识
---@param name string 法术名称
---@param rank string 法术等级
---@param fullName string 法术全名
---@param castStartTime number 施法开始时间
---@param castStopTime number 施法结束时间
---@param castDuration number 施法持续时间
---@param action number 施法动作
---@param castDisruptionTotal number 施法总中断
function OneMacro:SpellStatus_SpellCastChannelingFinish(id, name, rank, fullName, castStartTime, castStopTime,
														castDuration, action, castDisruptionTotal)
	self:EventReport("CastChannelingFinish", name, {
		SpellName = name,
	})
end

---施法取消光环（效果）
---@param id number 法术标识
---@param name string 法术名称
---@param rank string 法术等级
---@param fullName string 法术全名
---@param time number 施法时间
function OneMacro:SpellStatus_SpellCastCancelAura(id, name, rank, fullName, time)
	self:EventReport("AuraCancel", name, {
		BuffName = name,
	})
end

---玩家增益获得
---@param name string 增益名称
---@param index number 增益索引
function OneMacro:SpecialEvents_PlayerBuffGained(name, index)
	self:EventReport("BuffGain", name, {
		BuffName = name,
	})
end

---玩家增益失去
---@param name string 增益名称
---@param index number 增益索引
function OneMacro:SpecialEvents_PlayerBuffLost(name, index)
	self:EventReport("BuffLost", name, {
		BuffName = name,
	})
end

---玩家减益获得
---@param name string 增减益名称
---@param index number 增益索引
function OneMacro:SpecialEvents_PlayerDebuffGained(name, index)
	self:EventReport("DebuffGain", name, {
		DebuffName = name,
	})
end

---玩家减益失去
---@param name string 减益名称
---@param index number 减益索引
function OneMacro:SpecialEvents_PlayerDebuffLost(name, index)
	self:EventReport("DebuffLost", name, {
		DebuffName = name,
	})
end

---解析自身有害法术
---@param event string 事件名称
---@param info table 事件信息
function OneMacro:OnParserSelfDamage(event, info)
	-- self:Debug(
	-- 	"解析事件；类型：%s；法术：%s；发起：%s；目标：%s；事件：%s；消息：%s",
	-- 	info.type,
	-- 	info.skill,
	-- 	info.source,
	-- 	info.victim,
	-- 	event,
	-- 	info.message
	-- )

	-- 忽略无效法术
	if not info.skill then
		return
	end

	if info.type == "hit" or info.type == "cast" then
		-- 已命中
		self:EventReport("SpellHit", info.skill, {
			SpellName = info.skill,
			VictimName = info.victim,
		})
	elseif info.type == "miss" then
		-- 未命中
		local names = {
			resist = "抵抗",
			immune = "免疫",
			block = "阻挡",
			deflect = "偏移",
			dodge = "躲闪",
			evade = "回避",
			absorb = "吸收",
			parry = "招架",
			reflect = "反射",
		}
		self:EventReport("SpellMiss", info.skill, {
			SpellName = info.skill,
			VictimName = info.victim,
			MissType = names[info.missType] or info.missType,
		})
	elseif info.type == "leech" then
		-- 吸收
		self:EventReport("SpellLeech", info.skill, {
			SpellName = info.skill,
			VictimName = info.victim,
		})
	elseif info.type == "dispel" then
		-- 驱散
		self:EventReport("SpellDispel", info.skill, {
			SpellName = info.skill,
			VictimName = info.victim,
		})
	end
end

--[[ 方法 ]]

---打印错误
---@param content string 内容
---@param ... any 参数
function OneMacro:PrintError(content, ...)
	-- 红色 #FF0000 -> (1.00, 0.00, 0.00)
	self:CustomPrint(1.00, 0.00, 0.00, DEFAULT_CHAT_FRAME, nil, nil, content, unpack(arg))
end

---打印警告
---@param content string 内容
---@param ... any 参数
function OneMacro:PrintWarning(content, ...)
	-- 黄色 #FFC800 -> (1.00, 0.78, 0.00)
	self:CustomPrint(1.00, 0.78, 0.00, DEFAULT_CHAT_FRAME, nil, nil, content, unpack(arg))
end

---打印信息
---@param content string 内容
---@param ... any 参数
function OneMacro:PrintInfo(content, ...)
	-- 蓝色 #0069FF -> (0.00, 0.41, 1.00)
	self:CustomPrint(0.00, 0.41, 1.00, DEFAULT_CHAT_FRAME, nil, nil, content, unpack(arg))
end

---打印注释
---@param content string 内容
---@param ... any 参数
function OneMacro:PrintNote(content, ...)
	-- 灰色 #696969 -> (0.41, 0.41, 0.41)
	self:CustomPrint(0.41, 0.41, 0.41, DEFAULT_CHAT_FRAME, nil, nil, content, unpack(arg))
end

---调试错误
---@param level number 等级；可选值：1.底层，2.运行，3.调试
---@param content string 内容
---@param ... any 参数
function OneMacro:DebugError(level, content, ...)
	if level == 1 then
		-- 深红 #B0171F -> (0.69, 0.09, 0.12)
		self:CustomLevelDebug(level, 0.69, 0.09, 0.12, nil, nil, content, unpack(arg))
	elseif level == 2 then
		-- 中红 #DC143C -> (0.86, 0.08, 0.24)
		self:CustomLevelDebug(level, 0.86, 0.08, 0.24, nil, nil, content, unpack(arg))
	else
		-- 浅红 #FFB6C1 -> (1.00, 0.71, 0.76)
		self:CustomLevelDebug(level, 1.00, 0.71, 0.76, nil, nil, content, unpack(arg))
	end
end

---调试警告
---@param level number 等级；可选值：1.底层，2.运行，3.调试
---@param content string 内容
---@param ... any 参数
function OneMacro:DebugWarning(level, content, ...)
	if level == 1 then
		-- 深黄 #FF9912 -> (1.00, 0.60, 0.07)
		self:CustomLevelDebug(level, 1.00, 0.60, 0.07, nil, nil, content, unpack(arg))
	elseif level == 2 then
		-- 中黄 #FFE384 -> (1.00, 0.89, 0.52)
		self:CustomLevelDebug(level, 1.00, 0.89, 0.52, nil, nil, content, unpack(arg))
	else
		-- 浅黄 #FFFAAB -> (1.00, 0.98, 0.67)
		self:CustomLevelDebug(level, 1.00, 0.98, 0.67, nil, nil, content, unpack(arg))
	end
end

---调试信息
---@param level number 等级；可选值：1.底层，2.运行，3.调试
---@param content string 内容
---@param ... any 参数
function OneMacro:DebugInfo(level, content, ...)
	if level == 1 then
		-- 深蓝 #191970 -> (0.10, 0.10, 0.44)
		self:CustomLevelDebug(level, 0.10, 0.10, 0.44, nil, nil, content, unpack(arg))
	elseif level == 2 then
		-- 中蓝 #4169E1 -> (0.25, 0.41, 0.88)
		self:CustomLevelDebug(level, 0.25, 0.41, 0.88, nil, nil, content, unpack(arg))
	else
		-- 浅蓝 #ADD8E6 -> (0.68, 0.85, 0.90)
		self:CustomLevelDebug(level, 0.68, 0.85, 0.90, nil, nil, content, unpack(arg))
	end
end

---调试注释
---@param level number 等级；可选值：1.底层，2.运行，3.调试
---@param content string 内容
---@param ... any 参数
function OneMacro:DebugNote(level, content, ...)
	if level == 1 then
		-- 深灰 #5A5A5A -> (0.35, 0.35, 0.35)
		self:CustomLevelDebug(level, 0.35, 0.35, 0.35, nil, nil, content, unpack(arg))
	elseif level == 2 then
		-- 中灰 #969696 -> (0.59, 0.59, 0.59)
		self:CustomLevelDebug(level, 0.59, 0.59, 0.59, nil, nil, content, unpack(arg))
	else
		-- 浅灰 #D2D2D2 -> (0.82, 0.82, 0.82)
		self:CustomLevelDebug(level, 0.82, 0.82, 0.82, nil, nil, content, unpack(arg))
	end
end

---事件通报
---@param kind string|ReportKinds 种类
---@param spell string 法术
---@param data table<string,any> 数据
---@return boolean success 成功
function OneMacro:EventReport(kind, spell, data)
	-- 检验通报
	if not self.db.profile.report.list[kind] or not self.db.profile.report.list[kind].reports[spell] then
		return false
	end
	local report = self.db.profile.report.list[kind].reports[spell]

	-- 检验禁用
	if report.disable == true then
		return false
	end

	-- 检验消息
	if type(report.message) ~= "string" or report.message == "" then
		return false
	end

	-- 通报消息
	data = data or {}
	data["KindName"] = REPORT_KINDS[kind].name
	data["ReportName"] = spell
	data["PlayerName"] = UnitName("player")
	data["PlayerHealth"] = UnitHealth("player")
	data["PlayerMana"] = UnitMana("player")
	data["TargetName"] = Cast:GetTarget() or "未知目标"
	local message = OneMacroHelper:ReplaceInterpolation(report.message, data)

	-- 输出
	local mode = report.mode or "SAY"
	if mode == "PRINT" then
		-- 打印
		print(message)
	elseif mode == "PROMPT" then
		-- 提示
		UIErrorsFrame:AddMessage(message)
	else
		SendChatMessage(message, mode)
	end
	return true
end

---注册通报；覆盖更新
---@param kind string|ReportKinds 种类
---@param spell string 法术
---@param message string 消息
---@param mode? string|ReportModes 方式；缺省为`SAY`
---@param remark? string 备注
---@param order? number 顺序；缺省为通报计数递增
---@return boolean success 成功
function OneMacro:RegisterReport(kind, spell, message, mode, remark, order)
	if not REPORT_KINDS[kind] then
		self:DebugError(2, "通报种类(%s)无效", kind)
		return false
	end

	-- 初始种类
	if not self.db.profile.report.list[kind] then
		self.db.profile.report.list[kind] = REPORT_KINDS[kind]
	end

	-- 置通报信息
	self.db.profile.report.list[kind].reports[spell] = {
		mode = mode or "SAY",
		message = message,
		remark = remark or "",
		disable = false,
		order = order or Array:Count(self.db.profile.report.list[kind].reports) + 1,
	}

	-- 更新通报列表框
	if OneMacroEditor:IsVisible() then
		-- 置为当前选中
		self.db.profile.report.selected = kind .. "/" .. spell
		OneMacroEditor:UpdateReportListBox()
		OneMacroEditor:SetReportEdit(kind, spell)
	end
	return true
end

---注销通报
---@param kind? string|ReportKinds 种类；缺省将清空所有通报
---@param spell? string 法术
function OneMacro:CancellationReport(kind, spell)
	local parent, child = OneMacroEditor:GetReportSelected()
	if kind and spell then
		-- 注销通报
		self.db.profile.report.list[kind].reports[spell] = nil
		if kind == parent and spell == child then
			self.db.profile.report.selected = nil
			OneMacroEditor:SetReportEdit()
		end
	elseif kind then
		-- 注销种类
		self.db.profile.report.list[kind] = REPORT_KINDS[kind]
		if kind == parent then
			self.db.profile.report.selected = nil
			OneMacroEditor:SetReportEdit()
		end
	else
		-- 注销所有
		self.db.profile.report.list = REPORT_KINDS[kind]
		self.db.profile.report.selected = nil
		OneMacroEditor:SetReportEdit()
	end

	-- 更新通报列表框
	if OneMacroEditor:IsVisible() then
		OneMacroEditor:UpdateReportListBox()
	end
end

-- 导出通报
---@param file? string 文件；缺省为`OM-R`
---@return string error 错误；成功为空字符串，失败为错误信息
---@return number count 计数
function OneMacro:ExportReports(file)
	file = file or "OM-R"

	-- 检验SuperWoW
	if not SUPERWOW_VERSION then
		return "未检测到模组(SuperWoW)"
	end

	-- 通报计数
	local count = 0
	for _, kind in pairs(self.db.profile.report.list) do
		count = count + Array:Count(kind.reports)
	end
	if count == 0 then
		return "未检测到通报"
	end

	-- 序列化
	local text = OneMacroHelper:Serialize(self.db.profile.report.list)
	if not text or text == "" then
		return "序列化失败"
	end

	-- 导出文件
	ExportFile(file, text) -- 函数来至SuperWoW
	return "", count
end

---导入通报；覆盖更新
---@param file? string 文件；缺省为`OM-R`
---@return string error 错误；成功为空字符串，失败为错误信息
---@return number count 计数
function OneMacro:ImportReports(file)
	file = file or "OM-R"

	-- 检验SuperWoW
	if not SUPERWOW_VERSION then
		return "未检测到模组(SuperWoW)"
	end

	-- 导入文件
	local text = ImportFile(file) -- 函数来至SuperWoW
	if not text or text == "" then
		return "读取文件(" .. file .. ")失败"
	end

	-- 反序列化
	local success, kinds = OneMacroHelper:Unserialize(text)
	if not success then
		return "反序列化失败"
	end

	-- 检验数据
	if not Array:IsAssoc(kinds) then
		return "数据异常"
	end

	-- 增量种类
	local count = 0
	for kindKey, kindData in pairs(kinds) do
		if not REPORT_KINDS[kindKey] then
			return "通报种类(" .. kindKey .. ")无效"
		end

		if type(kindData.reports) ~= "table" then
			return "通报种类(" .. kindKey .. ")的通报列表无效"
		end

		-- 初始种类
		if not self.db.profile.report.list[kindKey] then
			self.db.profile.report.list[kindKey] = REPORT_KINDS[kindKey]
		end

		-- 增量通报
		for reportKey, reportData in pairs(kindData.reports) do
			self.db.profile.report.list[kindKey].reports[reportKey] = reportData
			count = count + 1
		end
	end

	-- 更新通报列表框
	if OneMacroEditor:IsVisible() then
		OneMacroEditor:UpdateReportListBox()
	end
	return "", count
end

---清空通报
---@return string error 错误；成功为空字符串，失败为错误信息
---@return number count 计数
function OneMacro:ClearReports()
	-- 通报计数
	local count = 0
	for _, kind in pairs(self.db.profile.report.list) do
		count = count + Array:Count(kind.reports)
	end

	self.db.profile.report.list = REPORT_KINDS
	self.db.profile.report.selected = nil

	-- 更新通报列表框
	if OneMacroEditor:IsVisible() then
		OneMacroEditor:UpdateReportListBox()
	end
	return "", count
end

---注册权重；覆盖更新
---@param weights table<string,OM_Weight> 权重表
---@param space string 空间
---@param name? string 名称；初始缺省为空间键名
---@param remark? string 备注；初始缺省为空字符串
---@param order? number 顺序；初始缺省为空间计数递增
---@return boolean success 成功
function OneMacro:RegisterWeights(weights, space, name, remark, order)
	-- 检验检测
	if type(weights) ~= "table" then
		self:DebugError(2, "权重表无效")
		return false
	end

	-- 检验空间
	if type(space) ~= "string" or space == "" then
		self:DebugError(2, "权重空间名无效")
		return false
	end

	-- 注册空间
	if not self.weights[space] then
		self.weights[space] = {
			name = name or space,
			remark = remark or "",
			order = order or Array:Count(self.weights) + 1,
			weights = {},
		}
	else
		if type(name) == "string" and name ~= "" then
			self.weights[space].name = name
		end
		if type(remark) == "string" then
			self.weights[space].remark = remark
		end
		if type(order) == "number" then
			self.weights[space].order = order
		end
	end

	-- 注册检测；覆盖更新
	for key, weight in pairs(weights) do
		if type(weight) ~= "table" or not weight.handle then
			self:DebugError(2, "权重(%s.%s)无效", space, key)
			return false
		end
		self.weights[space].weights[key] = weight
	end

	-- 更新权重列表框
	if OneMacroEditor:IsVisible() then
		OneMacroEditor:UpdateWeightListBox()
	end
	return true
end

---注册检测；覆盖更新
---@param detects table<string,OM_Detect> 检测表
---@param space string 空间
---@param name? string 名称；初始缺省为空间键名
---@param remark? string 备注；初始缺省为空字符串
---@param order? number 顺序；初始缺省为空间计数递增
---@return boolean success 成功
function OneMacro:RegisterDetects(detects, space, name, remark, order)
	-- 检验检测
	if type(detects) ~= "table" then
		self:DebugError(2, "检测表无效")
		return false
	end

	-- 检验空间
	if type(space) ~= "string" or space == "" then
		self:DebugError(2, "检测空间名无效")
		return false
	end

	-- 注册空间
	if not self.detects[space] then
		self.detects[space] = {
			name = name or space,
			remark = remark or "",
			order = order or Array:Count(self.detects) + 1,
			detects = {},
		}
	else
		if type(name) == "string" and name ~= "" then
			self.detects[space].name = name
		end
		if type(remark) == "string" then
			self.detects[space].remark = remark
		end
		if type(order) == "number" then
			self.detects[space].order = order
		end
	end

	-- 注册检测
	for key, detect in pairs(detects) do
		if type(detect) ~= "table" or not detect.handle then
			self:DebugError(2, "检测(%s.%s)无效", space, key)
			return false
		end
		self.detects[space].detects[key] = detect
	end

	-- 更新检测列表框
	if OneMacroEditor:IsVisible() then
		OneMacroEditor:UpdateDetectListBox()
	end
	return true
end

---注册动作；覆盖更新
---@param actions table<string,OM_Action> 动作表
---@param space string 空间
---@param name? string 名称；初始缺省为空间键名
---@param remark? string 备注；初始缺省为空字符串
---@param order? number 顺序；初始缺省为空间计数递增
---@return boolean success 成功
function OneMacro:RegisterActions(actions, space, name, remark, order)
	-- 检验空间
	if type(space) ~= "string" or space == "" then
		self:DebugError(2, "空间名无效")
		return false
	end

	-- 检验动作
	if type(actions) ~= "table" then
		self:DebugError(2, "动作表无效")
		return false
	end

	-- 注册动作
	if not self.actions[space] then
		self.actions[space] = {
			name = name or space,
			remark = remark or "",
			order = order or Array:Count(self.actions) + 1,
			actions = {},
		}
	else
		if type(name) == "string" and name ~= "" then
			self.actions[space].name = name
		end
		if type(remark) == "string" then
			self.actions[space].remark = remark
		end
		if type(order) == "number" then
			self.actions[space].order = order
		end
	end

	-- 注册动作
	for key, action in pairs(actions) do
		if type(action) ~= "table" or not action.handle then
			self:DebugError(2, "动作(%s.%s)无效", space, key)
			return false
		end
		self.actions[space].actions[key] = action
	end

	-- 更新动作列表框
	if OneMacroEditor:IsVisible() then
		OneMacroEditor:UpdateActionListBox()
	end
	return true
end

---到策略
---@param name string|number 名称或索引
---@return OM_Strategy? strategy 策略
---@return number? index 索引
function OneMacro:ToStrategy(name)
	if type(name) == "number" and name > 0 and name <= table.getn(self.db.profile.strategy.list) then
		-- 索引
		return self.db.profile.strategy.list[name], name
	elseif type(name) == "string" and name ~= "" then
		-- 名称
		for index, strategy in ipairs(self.db.profile.strategy.list) do
			if strategy.name == name then
				return strategy, index
			end
		end
	end
end

---执行策略
---@param name string|number 名称或索引
---@param config? table 配置
---@return boolean success 成功
function OneMacro:ExecuteStrategy(name, config)
	-- 检验配置
	config = config or {}
	if type(config) ~= "table" then
		self:DebugError(2, "配置无效")
		return false
	end

	-- 到策略
	local strategy, index = self:ToStrategy(name)
	if not strategy then
		self:DebugError(2, "未检测到策略(%s)", name)
		return false
	end

	self:DebugInfo(3, "执行策略(%s)", strategy.name or index)
	return OneMacroRunner:ExecuteStrategy(Array:DeepCopy(config), self.weights, self.detects, self.actions, strategy)
end

---导出策略
---@param file? string 文件；缺省为`OM-S`
---@return string error 错误；成功为空字符串，失败为错误信息
---@return number count 计数
function OneMacro:ExportStrategys(file)
	file = file or "OM-S"

	-- 策略计数
	local count = table.getn(self.db.profile.strategy.list)
	if count == 0 then
		return "未检测到策略"
	end

	-- 检验SuperWoW
	if not SUPERWOW_VERSION then
		return "未检测到模组(SuperWoW)"
	end

	-- 序列化
	local text = OneMacroHelper:Serialize(self.db.profile.strategy.list)
	if not text or text == "" then
		return "序列化失败"
	end

	-- 导出文件
	ExportFile(file, text) -- 函数来至SuperWoW
	return "", count
end

---导入策略；追加更新
---@param file? string 文件；缺省为`OM-S`
---@return string error 错误；成功为空字符串，失败为错误信息
---@return number count 计数
function OneMacro:ImportStrategys(file)
	file = file or "OM-S"

	-- 检验SuperWoW
	if not SUPERWOW_VERSION then
		return "未检测到模组(SuperWoW)"
	end

	-- 导入文件
	local text = ImportFile(file) -- 函数来至SuperWoW
	if not text or text == "" then
		return "读取文件(" .. file .. ")失败"
	end

	-- 反序列化
	local success, strategys = OneMacroHelper:Unserialize(text)
	if not success then
		return "反序列化失败"
	end

	-- 检验数据
	if not Array:IsList(strategys) then
		return "数据异常"
	end

	-- 追加策略
	for _, strategy in ipairs(strategys) do
		table.insert(self.db.profile.strategy.list, strategy)
	end

	-- 更新策略列表框
	if OneMacroEditor:IsVisible() then
		OneMacroEditor:UpdateStrategyListBox()
	end
	return "", table.getn(strategys)
end

---清空策略
---@return string error 错误；成功为空字符串，失败为错误信息
---@return number count 计数
function OneMacro:ClearStrategys()
	local count = table.getn(self.db.profile.strategy.list)
	self.db.profile.strategy.list = {}
	self.db.profile.strategy.selected = nil

	-- 更新策略列表框
	if OneMacroEditor:IsVisible() then
		OneMacroEditor:UpdateStrategyListBox()
	end
	return "", count
end
