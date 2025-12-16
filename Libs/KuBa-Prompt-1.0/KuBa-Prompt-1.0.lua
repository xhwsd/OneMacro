--[[
Name: KuBa-Prompt-1.0
Revision: $Rev: 10002 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://gitee.com/ku-ba
Description: 提示相关库。
Dependencies: AceLibrary
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-Prompt-1.0"
-- 次要版本
local MINOR_VERSION = "$Revision: 10002 $"

-- 检验AceLibrary
if not AceLibrary then
	error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
	return
end

---提示相关库。
---@class KuBa-Prompt-1.0
local Library = {}

--------------------------------

---添加
---@param message string 消息
---@param red? number 红色；取值0.0-1.0
---@param green? number 绿色；取值0.0-1.0
---@param blue? number 蓝色；取值0.0-1.0
---@param alpha? number 透明度；取值0.0-1.0
---@param duration? number 持续时间；单位为妙
function Library:Add(message, red, green, blue, alpha, duration)
	if not message or message == "" then
		return
	end

	-- UIErrorsFrame:AddMessage https://warcraft.wiki.gg/wiki/API_MessageFrame_AddMessage?oldid=1772162
	UIErrorsFrame:AddMessage(message, red, green, blue, alpha, duration)
end

---信息
---@param message string 消息
---@param ... any 参数
function Library:Info(message, ...)
	if not message or message == "" then
		return
	end

	if arg.n then
		message = string.format(message, unpack(arg))
	end
	self:Add(message, 0.0, 1.0, 0.0, 53, 5)
end

---警告
---@param message string 消息
---@param ... any 参数
function Library:Warning(message, ...)
	if not message or message == "" then
		return
	end

	if arg.n then
		message = string.format(message, unpack(arg))
	end
	self:Add(message, 1.0, 1.0, 0.0, 53, 5)
end

---错误
---@param message string 消息
---@param ... any 参数
function Library:Error(message, ...)
	if not message or message == "" then
		return
	end

	if arg.n then
		message = string.format(message, unpack(arg))
	end
	self:Add(message, 1.0, 0.0, 0.0, 53, 5)
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