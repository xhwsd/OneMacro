---@class Helper:AceAddon-2.0 辅助模块 xhwsd@qq.com 2025-6-27
OneMacroHelper = OneMacro:NewModule("Helper")

--[[ 依赖 ]]

local Array = AceLibrary("KuBa-Array-1.0")

--[[ 事件 ]]

---初始化
function OneMacroHelper:OnInitialize()

end

---启用
function OneMacroHelper:OnEnable()

end

---禁用
function OneMacroHelper:OnDisable()

end

--[[ 方法 ]]

---取聊天框
---@param name string 名称；支持匹配表达式
---@return Frame|nil frame 聊天框
function OneMacroHelper:GetChatWindow(name)
	for index = 1, NUM_CHAT_WINDOWS do
		local text = GetChatWindowInfo(index)
		if text and string.find(text, name) then
			return getglobal("ChatFrame" .. index)
		end
	end
end

---序列化
---@param data any 数据；仅支持字符串、数字、布尔值、表
---@param indent? string 缩进；仅用于表
---@return string text 文本
function OneMacroHelper:Serialize(data, indent)
	local kind = type(data)
	if kind == "string" then
		-- %q 将字符串格式化为Lua的字符串字面量
		return string.format("%q", data)
	elseif kind == "number" or kind == "boolean" then
		return tostring(data)
	elseif kind == "table" then
		indent = indent or ""
		local childIndent = indent .. "  "
		local result
		if Array:IsList(data) then
			result = { "{ " }
			for _, value in ipairs(data) do
				table.insert(result, self:Serialize(value, childIndent) .. ", ")
			end
			table.insert(result, "}")
		else
			result = { "{\n" }
			for key, value in pairs(data) do
				local name
				if type(key) == "string" and string.find(key, "^[_%a][_%w]*$") then
					-- 键是下划线、字母、数字
					name = key
				else
					-- 需要方括号包裹
					name = "[" .. self:Serialize(key, childIndent) .. "]"
				end
				table.insert(result, childIndent .. name .. " = " .. self:Serialize(value, childIndent) .. ",\n")
			end
			table.insert(result, indent .. "}")
		end
		return table.concat(result)
	else
		return '"<unsupported type>"'
	end
end

---反序列化
---@param text string 文本
---@return boolean success 成功
---@return any ... 数据
function OneMacroHelper:Unserialize(text)
	local chunk, error = loadstring("return " .. text)
	if not chunk or error then
		return false
	end
	return true, chunk()
end

---检验文本
---@param text string 文本
---@return boolean valid 有效
function OneMacroHelper:CheckText(text)
	return type(text) == "string" and text ~= ""
end

---有效文本
---@param text string 文本
---@param default string 默认
---@return string text 文本
function OneMacroHelper:ValidText(text, default)
	if self:CheckText(text) then
		return text
	else
		return default
	end
end

---替换插值
---@param text string 文本
---@param data table<string,any> 数据；兼容非字符串值
---@param left? string 左标记；缺省为`{`
---@param right? string 右标记；缺省为`}`
---@return string text 文本
function OneMacroHelper:ReplaceInterpolation(text, data, left, right)
	data = data or {}
	left = left or "{"
	right = right or "}"

	for key, value in pairs(data) do
		if type(value) == "nil" then
			value = ""
		elseif type(value) ~= "string" then
			value = tostring(value)
		end
		text = string.gsub(text, left .. key .. right, value)
	end
	return text
end

-- 队列框架
local queueFrame

---队列处理
---@param handle function 处理函数
---@param ... any 参数
function OneMacroHelper:QueueHandle(handle, ...)
	if not queueFrame then
		-- 初始化框架
		queueFrame = CreateFrame("Frame")
		queueFrame.tasks = {}
		queueFrame.interval = TOOLTIP_UPDATE_TIME

		-- 处理任务
		queueFrame.HandleTask = function()
			-- 执行函数
			local item = table.remove(queueFrame.tasks, 1)
			if type(item.handle) == "function" then
				item.handle(unpack(item.params))
			end

			-- 已无任务
			if table.getn(queueFrame.tasks) == 0 then
				-- 隐藏框架，停止触发`OnUpdate`事件
				queueFrame:Hide()
			end
		end

		-- 框架更新
		queueFrame:SetScript("OnUpdate", function()
			-- 累加时间
			this.time = (this.time or 0) + arg1
			-- 已到间隔
			while (this.time > this.interval) do
				-- 处理任务
				this.HandleTask()
				-- 重置时间
				this.time = this.time - this.interval
			end
		end)
	end

	-- 添加任务
	table.insert(queueFrame.tasks, {
		handle = handle,
		params = arg,
	})

	-- 显示框架，开始触发`OnUpdate`事件
	queueFrame:Show()
end

-- 延时框架
local delayFrame

---延时处理
---@param name string 名称；可用于取消延时
---@param delay number 延时秒数
---@param handle function 处理函数
---@param ... any 参数
function OneMacroHelper:DelayHandle(name, delay, handle, ...)
	if not delayFrame then
		-- 初始化框架
		delayFrame = CreateFrame("Frame")
		delayFrame.tasks = {}
		delayFrame.interval = TOOLTIP_UPDATE_TIME

		-- 框架更新
		delayFrame:SetScript("OnUpdate", function()
			-- 遍历任务
			local time = GetTime()
			local length = table.getn(delayFrame.tasks)
			for index = length, 1, -1 do
				-- 检验时间
				local task = delayFrame.tasks[index]
				if time >= task.time then
					-- 执行任务
					if type(task.handle) == "function" then
						task.handle(unpack(task.params))
					end
					-- 移除任务
					table.remove(delayFrame.tasks, index)
				end
			end

			-- 已无任务
			if table.getn(delayFrame.tasks) == 0 then
				-- 停止更新
				delayFrame:Hide()
			end
		end)
	end

	-- 添加任务
	table.insert(delayFrame.tasks, {
		name = name,
		handle = handle,
		params = arg,
		time = GetTime() + delay
	})

	-- 时间排序（从大到小）
	table.sort(delayFrame.tasks, function(a, b)
		return a.time > b.time
	end)

	-- 开始更新
	delayFrame:Show()
end

---取消延时
---@param name string? 名称
---@return number count 计数
function OneMacroHelper:CancelDelay(name)
	local count = 0
	if delayFrame then
		if name then
			-- 指定任务
			local length = table.getn(delayFrame.tasks)
			for index = length, 1, -1 do
				if delayFrame.tasks[index].name == name then
					table.remove(delayFrame.tasks, index)
					count = count + 1
				end
			end
		else
			-- 清空任务
			count = table.getn(delayFrame.tasks)
			delayFrame.tasks = {}
		end

		-- 停止更新
		if table.getn(delayFrame.tasks) == 0 then
			delayFrame:Hide()
		end
	end
	return count
end

---分割文本
---@param text string 文本
---@param delimiter string 分隔符
---@return string[] list 列表
function OneMacroHelper:splitText(text, delimiter)
	local list = {}
	if type(text) == "string" then
		-- 构建匹配模式：匹配一个或多个非分隔符的字符
		local pattern = string.format("([^%s]+)", delimiter)
		for match in string.gmatch(text, pattern) do
			table.insert(list, match)
		end
	end
	return list
end
