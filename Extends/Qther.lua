---@class QtherExtend:AceAddon-2.0 其它扩展模块 xhwsd@qq.com 2025-9-23
OneMacroQther = OneMacro:NewModule("QtherExtend")

--[[ 依赖 ]]


--[[ 事件 ]]

---初始化
function OneMacroQther:OnInitialize()

end

---启用
function OneMacroQther:OnEnable()
	self:RegisterDetects()
	self:RegisterActions()
end

---禁用
function OneMacroQther:OnDisable()

end

---注册检测
function OneMacroQther:RegisterDetects()
	OneMacro:RegisterDetects({

	}, "Qther", "其它", "其它相关检测")
end

---注册动作
function OneMacroQther:RegisterActions()
	OneMacro:RegisterActions({
		--[[ 超级宏 ]]

		["RunMacro"] = {
			name = "运行宏",
			options = {
				name = {
					type = "string",
					name = "名称",
					require = true,
				},
			},
			handle = function(config, filter, options)
				if RunMacro then
					RunMacro(options.name)
				else
					OneMacro:DebugWarning(2, "未检测到插件(SuperMacro)")
				end
			end,
		},
		["RunSuperMacro"] = {
			name = "运行超级宏",
			options = {
				name = {
					type = "string",
					name = "名称",
					require = true,
				},
			},
			handle = function(config, filter, options)
				if RunSuperMacro then
					RunSuperMacro(options.name)
				else
					OneMacro:DebugWarning(2, "未检测到插件(SuperMacro)")
				end
			end,
		},

		--[[ 队列 ]]

		["ProhibitCastQueue"] = {
			name = "禁止施法队列",
			handle = function(config, filter, options)
				-- 记录队列状态
				if not self.castQueues then
					self.castQueues = {
						-- 读条法术队列
						["NP_QueueCastTimeSpells"] = GetCVar("NP_QueueCastTimeSpells"),
						-- 瞬发法术队列
						["NP_QueueInstantSpells"] = GetCVar("NP_QueueInstantSpells"),
						-- 引导法术队列
						["NP_QueueChannelingSpells"] = GetCVar("NP_QueueChannelingSpells"),
						-- 地面目标法术队列
						["NP_QueueTargetingSpells"] = GetCVar("NP_QueueTargetingSpells"),
						-- 攻击触发法术队列
						["NP_QueueOnSwingSpells"] = GetCVar("NP_QueueOnSwingSpells"),
					}
				end

				-- 禁止施法队列
				for key, value in pairs(self.castQueues) do
					SetCVar(key, "0")
				end
			end,
			remark = "禁止所有施法队列",
		},
		["RestoreCastQueue"] = {
			name = "恢复施法队列",
			options = {
				switch = {
					type = "boolean",
					name = "开关",
					require = true,
				},
			},
			handle = function(config, filter, options)
				-- 恢复队列状态
				if self.castQueues then
					for key, value in pairs(self.castQueues) do
						SetCVar(key, value)
					end

					self.castQueues = nil
				end
			end,
			remark = "恢复禁止施法队列前的状态",
		},
	}, "Qther", "其它", "其它相关动作")
end

--[[

一键4图腾宏：
QueueSpellByName("Windfury Totem");
QueueSpellByName("Tremor Totem");
QueueSpellByName("Mana Spring Totem");
QueueSpellByName("Flametongue Totem");

打断并释放奥术涌动宏：
/script ChannelStopCastingNextTick()
/cast Arcane Surge

一键迅捷加治疗链
if GetInventoryItemCooldown("player", 13) == 0 then
	UseInventoryItem(13);
end;
QueueSpellByName("Nature's Swiftness");
QueueSpellByName("Heal Chain");

将强制将法术排队，而不管适当的队列窗口如何。如果当前没有施放任何法术，它将立即施放。 例如，可以制作一个宏
]]
