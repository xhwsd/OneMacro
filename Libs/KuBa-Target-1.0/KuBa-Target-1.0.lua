--[[
Name: KuBa-Target-1.0
Revision: $Rev: 10001 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://gitee.com/ku-ba
Description: 目标切换相关库。
Dependencies: AceLibrary
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-Target-1.0"
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

---目标切换相关库。
---@class KuBa-Target-1.0
local Library = {}

--------------------------------

---回调
---@param handle function|string|table|{object:table,method:function|string}|[table,function|string] 处理
---@param ... any 参数
---@return boolean success 成功；失败为`false`，后续返回值为错误信息
---@return any ... 返回
local function Callback(handle, ...)
	if type(handle) == "function" then
		-- 函数
		return pcall(handle, unpack(arg))
	elseif type(handle) == "string" then
		-- 全局函数
		if type(_G[handle]) == "function" then
			return pcall(_G[handle], unpack(arg))
		end
	elseif type(handle) == "table" then
		-- 对象方法
		local object, method
		if handle.object and handle.method then
			-- 关联表
			object, method = handle.object, handle.method
		else
			-- 索引表
			object, method = handle[1], handle[2]
		end

		if type(object) == "table" then
			-- 方法名
			if type(method) == "string" then
				method = object[method]
			end

			if type(method) == "function" then
				return pcall(method, object, unpack(arg))
			end
		end
	end
	return false, "处理无效"
end

---是否为GUID
---@param guid string GUID
---@return boolean is 是否
function Library:IsGuid(guid)
	if type(guid) == "string" and guid ~= "" then
		return string.find(guid, "^0x%w+$") ~= nil
	end
	return false
end  

---是否为单位
---@param unit string 单位
---@return boolean is 是否
function Library:IsUnit(unit)
	if type(unit) == "string" and unit ~= "" then
		-- 单位标识 https://warcraft.wiki.gg/wiki/UnitId?oldid=4454903
		local patterns = {
			-- 玩家
			"player",
			-- 宠物
			"pet",
			-- 队伍
			"party%d+",
			-- 队伍宠物
			"partypet%d+",
			-- 团队
			"raid%d+",
			-- 团队宠物
			"raidpet%d+",
			-- 目标
			"target",
			-- 鼠标悬停
			"mouseover",
			-- NPC
			"npc",
		}
		for _, pattern in ipairs(patterns) do
			-- 限定开始与结束，后缀兼容附加 target
			if string.find(unit, "^" .. pattern .. "%w*$") then
				return true
			end
		end
	end  
	return false
end

---是否为名称
---@param name string 名称；仅限可切换到目标的名称
---@return boolean is 是否
function Library:IsName(name)
	if type(name) == "string" and name ~= "" then
		if UnitExists("target") then
			-- 当前有目标
			if UnitName("target") == name then
				-- 相同目标
				return true
			else
				-- 其它目标
				TargetByName(name)
				if UnitName("target") == name then
					-- 恢复原有目标
					TargetLastTarget()
					return true
				else
					-- 恢复原有目标
					TargetLastTarget()
				end
			end
		else
			-- 当无有目标
			TargetByName(name)
			if UnitName("target") == name then
				-- 清除目标
				ClearTarget()
				return true
			else
				-- 清除目标
				ClearTarget()
			end
		end
	end  
	return false
end

---切换到目标回调，然后恢复原目标
---@param target string 目标；可选值：GUID(有SuperWoW模组时)、单位、名称
---@param handle function|string|table 处理；回调过程中`target`单位就是目标
---@param ... any 参数
---@return boolean success 成功；失败为`false`，后续返回值为错误信息
---@return any ... 返回
function Library:SwitchTarget(target, handle, ...)
	if type(target) ~= "string" or target == "" then
		return false, "目标无效"
	end

	-- GUID
	if self:IsGuid(target) then
		-- 依赖SuperWoW
		if not SUPERWOW_STRING then
			return false
		end

		return self:SwitchUnit(target, handle, unpack(arg))
	end

	-- 单位
	if self:IsUnit(target) then
		return self:SwitchUnit(target, handle, unpack(arg))
	end

	-- 名称
	return self:SwitchName(target, handle, unpack(arg))
end

---切换到单位回调，然后恢复到原目标
---@param unit string 单位；有SuperWoW模组时兼容GUID
---@param handle function|string|table 处理；回调过程中`target`单位就是目标
---@param ... any 参数
---@return boolean success 成功；失败为`false`，后续返回值为错误信息
---@return any ... 返回
function Library:SwitchUnit(unit, handle, ...)
	if type(unit) ~= "string" or unit == "" then
		return false, "单位无效"
	end

	if UnitExists(unit) then
		if UnitExists("target") then
			-- 当前有目标
			if UnitIsUnit(unit, "target") then
				-- 相同目标
				return Callback(handle, unpack(arg))
			else
				-- 其它目标
				TargetUnit(unit)
				local results = { Callback(handle, unpack(arg)) }
				-- 恢复原有目标
				TargetLastTarget()
				return unpack(results)
			end
		else
			-- 当前无目标
			TargetUnit(unit)
			local results = { Callback(handle, unpack(arg)) }
			-- 清除目标
			ClearTarget()
			return unpack(results)
		end
	end
	return false, "单位(" .. unit .. ")无效"
end

---切换到名称回调，然后恢复到原目标
---@param name string 名称
---@param handle function|string|table 处理；回调过程中`target`单位就是目标
---@param ... any 参数
---@return boolean success 成功；失败为`false`，后续返回值为错误信
---@return any ... 结果
function Library:SwitchName(name, handle, ...)
	if type(name) ~= "string" or name == "" then
		return false, "名称无效"
	end

	if UnitExists("target") then
		-- 当前有目标
		if UnitName("target") == name then
			-- 相同目标
			return Callback(handle, unpack(arg))
		else
			-- 其它目标
			TargetByName(name)
			if UnitName("target") == name then
				local results = { Callback(handle, unpack(arg)) }
				-- 恢复原有目标
				TargetLastTarget()
				return unpack(results)
			else
				-- 恢复原有目标
				TargetLastTarget()
			end
		end
	else
		-- 当前无目标
		TargetByName(name)
		if UnitName("target") == name then
			local results = { Callback(handle, unpack(arg)) }
			-- 清除目标
			ClearTarget()
			return unpack(results) 
		else
			-- 清除目标
			ClearTarget()
		end
	end
	return false, "名称(" .. name .. ")无效"
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