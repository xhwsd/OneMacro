---@class RemoteExtend:AceAddon-2.0 远程扩展模块 xhwsd@qq.com 2025-9-23
OneMacroRemote = OneMacro:NewModule("RemoteExtend")

--[[ 依赖 ]]


--[[ 事件 ]]

---初始化
function OneMacroRemote:OnInitialize()

end

---启用
function OneMacroRemote:OnEnable()
	self:RegisterDetects()
	self:RegisterActions()
end

---禁用
function OneMacroRemote:OnDisable()

end

---注册检测
function OneMacroRemote:RegisterDetects()
	OneMacro:RegisterDetects({

	}, "Remote", "远程", "远程相关检测")
end

---注册动作
function OneMacroRemote:RegisterActions()
	OneMacro:RegisterActions({

	}, "Remote", "远程", "远程相关动作")
end
