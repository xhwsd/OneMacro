---@class Runner:AceAddon-2.0 运行器模块 xhwsd@qq.com 2025-6-27
OneMacroRunner = OneMacro:NewModule("Runner")

--[[ 依赖 ]]

local Array = AceLibrary("KuBa-Array-1.0")

--[[ 事件 ]]

---初始化
function OneMacroRunner:OnInitialize()

end

---启用
function OneMacroRunner:OnEnable()

end

---禁用
function OneMacroRunner:OnDisable()

end

---执行策略
---@param config table 配置
---@param weights table<string,OM_WeightSpace> 权重
---@param detects table<string,OM_DetectSpace> 检测
---@param actions table<string,table<string,OM_Action>> 动作
---@param strategy OM_Strategy 策略
---@return boolean success 成功
function OneMacroRunner:ExecuteStrategy(config, weights, detects, actions, strategy)
	config = config or {}
	weights = weights or {}
	detects = detects or {}
	actions = actions or {}
	strategy = strategy or {}

	for index, rule in ipairs(strategy.rules) do
		-- 禁用规则
		if rule.disable ~= true then
			local name = rule.name or tostring(index)
			local success, unit = self:CheckRule(config, weights, detects, rule)
			if not success then
				OneMacro:DebugError(2, "规则(%s)执行失败", name)
				return false
			elseif unit == nil then
				OneMacro:DebugWarning(3, "规则(%s)未满足条件", name)
			else
				-- 执行操作
				local operations = rule.operations or {}
				if self:ExecuteOperations(config, actions, operations, unit) == false then
					OneMacro:DebugError(2, "规则(%s)动作执行失败", name)
					return false
				end

				if unit == "" then
					-- 空字符串为未筛选单位
					OneMacro:DebugInfo(3, "规则(%s)执行完成", name)
				else
					local target = OneMacroRoster:ToName(unit) or UnitName(unit) or ""
					OneMacro:DebugInfo(3, "规则(%s)筛选到(%s)执行完成", name, target)
				end

				-- 终止运行
				if not rule.continue then
					break
				end
			end
		end
	end
	return true
end

---检验规则
---@param config table 配置
---@param weights table<string,OM_WeightSpace> 权重
---@param detects table<string,OM_DetectSpace> 检测
---@param rule OM_Rule 规则
---@return boolean success 成功
---@return string|nil unit 单位；空字符串为无筛选，通过条件检测
function OneMacroRunner:CheckRule(config, weights, detects, rule)
	local conditions = rule.conditions or {}
	local filter = rule.filter or {}

	if type(filter.scopes) == "table" and table.getn(filter.scopes) > 0 then
		-- 筛选范围
		for _, scope in ipairs(filter.scopes) do
			local success, unit
			if scope == "raid" and GetNumRaidMembers() > 0 then
				-- 筛选团队
				success, unit = self:FilterRaid(config, weights, detects, conditions, filter)
			elseif scope == "team" and GetNumPartyMembers() > 0 then
				-- 筛选小队
				success, unit = self:FilterParty(config, weights, detects, conditions, filter)
			elseif scope == "party" and GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0 then
				-- 筛选队伍
				success, unit = self:FilterParty(config, weights, detects, conditions, filter)
			elseif scope == "roster" and OneMacroRoster:Count() > 0 then
				-- 筛选名单
				success, unit = self:FilterRoster(config, weights, detects, conditions, filter)
			elseif scope == "player" then
				-- 玩家
				success, unit = self:FilterUnits(config, weights, detects, conditions, filter, { "player" })
			elseif scope == "target" then
				-- 目标
				success, unit = self:FilterUnits(config, weights, detects, conditions, filter,
					{ "target", "targettarget" })
			end

			-- 终止筛选
			if success == false then
				-- 筛选失败
				return false
			elseif unit then
				-- 筛选到单位
				return true, unit
			end
		end
	else
		-- 无筛选
		local success, establish = self:CheckConditions(config, detects, conditions)
		if not success then
			return false
		elseif establish then
			return true, ""
		end
	end
	return true, nil
end

---筛选团队
---@param config table 配置
---@param weights table<string,OM_WeightSpace> 权重
---@param detects table<string,OM_DetectSpace> 检测
---@param conditions table<string,table<string,OM_Condition>> 条件
---@param filter OM_Filter 筛选
---@return boolean success 成功
---@return string|nil filter 筛选
function OneMacroRunner:FilterRaid(config, weights, detects, conditions, filter)
	-- 遍历团队
	local list = {}
	for index = GetNumRaidMembers(), 1, -1 do
		local unit = "raid" .. index
		if type(filter.weight) == "string" and filter.weight ~= "" then
			local success, weight = self:GetWeight(config, weights, filter, unit)
			if not success then
				return false
			end
			table.insert(list, {
				unit = unit,
				weight = weight,
			})
		else
			table.insert(list, {
				unit = unit,
				weight = index,
			})
		end
	end
	return self:FilterList(config, detects, conditions, filter, list)
end

---筛选队伍
---@param config table 配置
---@param weights table<string,OM_WeightSpace> 权重
---@param detects table<string,OM_DetectSpace> 检测
---@param conditions table<string,table<string,OM_Condition>> 条件
---@param filter OM_Filter 筛选
---@return boolean success 成功
---@return string|nil unit 单位
function OneMacroRunner:FilterParty(config, weights, detects, conditions, filter)
	-- 检验自己
	local list = {}
	local unit = "player"
	if type(filter.weight) == "string" and filter.weight ~= "" then
		local success, weight = self:GetWeight(config, weights, filter, unit)
		if not success then
			return false
		end
		table.insert(list, {
			unit = unit,
			weight = weight,
		})
	else
		table.insert(list, {
			unit = unit,
			weight = 5,
		})
	end

	-- 遍历队伍（不含自己）
	for index = GetNumPartyMembers(), 1, -1 do
		unit = "party" .. index
		if type(filter.weight) == "string" and filter.weight ~= "" then
			local success, weight = self:GetWeight(config, weights, filter, unit)
			if not success then
				return false
			end
			table.insert(list, {
				unit = unit,
				weight = weight,
			})
		else
			table.insert(list, {
				unit = unit,
				weight = index,
			})
		end
	end
	return self:FilterList(config, detects, conditions, filter, list)
end

---筛选名单
---@param config table 配置
---@param weights table<string,OM_WeightSpace> 权重
---@param detects table<string,OM_DetectSpace> 检测
---@param conditions table<string,table<string,OM_Condition>> 条件
---@param filter OM_Filter 筛选
---@return boolean success 成功
---@return string|nil unit 单位
function OneMacroRunner:FilterRoster(config, weights, detects, conditions, filter)
	-- 遍历名单
	local list = {}
	for index = OneMacroRoster:Count(), 1, -1 do
		local unit = "roster" .. index
		if type(filter.weight) == "string" and filter.weight ~= "" then
			local success, weight = self:GetWeight(config, weights, filter, unit)
			if not success then
				return false
			end
			table.insert(list, {
				unit = unit,
				weight = weight,
			})
		else
			table.insert(list, {
				unit = unit,
				weight = index,
			})
		end
	end
	return self:FilterList(config, detects, conditions, filter, list)
end

---筛选单位
---@param config table 配置
---@param weights table<string,OM_WeightSpace> 权重
---@param detects table<string,OM_DetectSpace> 检测
---@param conditions table<string,table<string,OM_Condition>> 条件
---@param filter OM_Filter 筛选
---@param units string[] 单位表
---@return boolean success 成功
---@return string|nil filter 筛选
function OneMacroRunner:FilterUnits(config, weights, detects, conditions, filter, units)
	local list = {}
	for index, unit in ipairs(units) do
		if UnitCanAssist("player", unit) then
			if type(filter.weight) == "string" and filter.weight ~= "" then
				local success, weight = self:GetWeight(config, weights, filter, unit)
				if not success then
					return false
				end
				table.insert(list, {
					unit = unit,
					weight = weight,
				})
			else
				table.insert(list, {
					unit = unit,
					weight = index,
				})
			end
		end
	end
	return self:FilterList(config, detects, conditions, filter, list)
end

---筛选列表
---@param config table 配置
---@param detects table<string,OM_DetectSpace> 检测
---@param conditions table<string,table<string,OM_Condition>> 条件
---@param filter OM_Filter 筛选
---@param list {unit:string,weight:number}[] 列表
---@return boolean success 成功
---@return string|nil unit 单位
function OneMacroRunner:FilterList(config, detects, conditions, filter, list)
	local count = table.getn(list)

	-- 列表排序
	if filter.sort == "disturb" then
		-- 打乱顺序
		if count >= 2 then
			for index = count, 2, -1 do
				-- 随机函数 (1.0~100.0 范围)
				local rand = math.random(100) / 100
				local source = math.floor(rand * index) + 1

				-- 交换元素
				list[index], list[source] = list[source], list[index]
			end
		end
	elseif filter.sort == "asc" then
		-- 升序排列
		table.sort(list, function(a, b)
			return a.weight < b.weight
		end)
	else
		-- 降序排列
		table.sort(list, function(a, b)
			return a.weight > b.weight
		end)
	end

	-- 选取目标
	if filter.choose == "traverse" then
		-- 限定数量
		local limit = filter.limit
		if type(limit) ~= "number" or limit <= 0 or limit > count then
			limit = count
		end

		-- 遍历每个
		for index = 1, limit do
			local success, establish = self:CheckConditions(config, detects, conditions, list[index].unit)
			if not success then
				-- 错误
				return false
			elseif establish then
				-- 成立
				return true, list[index].unit
			end
		end
	elseif filter.choose == "random" then
		-- 随机一个
		if count > 0 then
			local index = math.random(1, count)
			local success, establish = self:CheckConditions(config, detects, conditions, list[index].unit)
			if not success then
				-- 错误
				return false
			elseif establish then
				-- 成立
				return true, list[index].unit
			end
		end
	elseif filter.choose == "last" then
		-- 最后一个
		if count > 0 then
			local success, establish = self:CheckConditions(config, detects, conditions, list[count].unit)
			if not success then
				-- 错误
				return false
			elseif establish then
				-- 成立
				return true, list[count].unit
			end
		end
	else
		-- 第一个
		if count > 0 then
			local success, establish = self:CheckConditions(config, detects, conditions, list[1].unit)
			if not success then
				-- 错误
				return false
			elseif establish then
				-- 成立
				return true, list[1].unit
			end
		end
	end
	return true, nil
end

---取权重
---@param config table 配置
---@param weights table<string,OM_WeightSpace> 权重
---@param filter OM_Filter 筛选
---@param unit string 单位
---@return boolean success 成功
---@return number|nil weight 权重
function OneMacroRunner:GetWeight(config, weights, filter, unit)
	filter = filter or {}

	-- 检验别名
	if type(filter.weight) ~= "string" or filter.weight == "" then
		OneMacro:DebugError(2, "权重别名无效")
		return false
	end

	-- 解析别名
	local space, method = self:ParseAlias(filter.weight)
	if not space or not method then
		OneMacro:DebugError(2, "解析权重别名(%s)失败", filter.weight)
		return false
	end

	-- 检验检测
	if type(weights[space]) ~= "table" or type(weights[space].weights[method]) ~= "table" then
		OneMacro:DebugWarning(2, "权重(%s)未注册", filter.weight)
		return false
	end

	-- 检验选项
	local options = Array:DeepCopy(filter.options) or {} -- 因后续会修改选项表值，这里需要深度拷贝
	local defines = weights[space].weights[method].options or {}
	for key, define in pairs(defines) do
		local name = define.name or key

		-- 必需
		if define.require and options[key] == nil then
			OneMacro:DebugError(2, "权重(%s)选项(%s)缺失", filter.weight, name)
			return false
		end

		-- 类型
		if define.type and options[key] ~= nil and type(options[key]) ~= define.type then
			OneMacro:DebugError(2, "权重(%s)选项(%s)类型错误", filter.weight, name)
			return false
		end

		-- 默认值
		if define.default and options[key] == nil then
			options[key] = define.default
		end
	end

	-- 回调检测
	local success, result = self:CallbackHandle(weights[space].weights[method].handle, config, unit, options)
	if not success then
		OneMacro:DebugError(2, "回调权重(%s)失败：\n%s", alias, result)
		return false
	end
	return true, result
end

---检验所有条件；会考虑编组逻辑关系
---@param config table 配置
---@param detects table<string,OM_DetectSpace> 检测
---@param conditions OM_Condition[] 条件
---@param filter? string|nil 筛选
---@return boolean success 成功
---@return boolean|nil establish 成立
function OneMacroRunner:CheckConditions(config, detects, conditions, filter)
	-- 空条件
	local length = table.getn(conditions)
	if length == 0 then
		return true, true
	end

	-- 单条件
	if length == 1 then
		return self:CheckCondition(config, detects, conditions[1], filter)
	end

	-- 多条件
	local results = {}
	-- 分割编组条件：遇到TRUE就归前一个组，相当于用括号包裹
	local group = self:SplitCondition(conditions, "grouping", true, false)
	for _, items in ipairs(group) do
		-- 检验编组条件
		local success, establish = self:CheckGrouping(config, items, detects, filter)
		if not success then
			return false
		end

		-- 分组中第一个条件的逻辑为与前一个组的逻辑
		table.insert(results, {
			logical = items[1].logical or "and",
			establish = establish
		})
	end

	local final = false
	local establish = false
	for index, result in ipairs(results) do
		if index == 1 then
			establish = result.establish
		else
			if result.logical == "and" then
				-- AND运算
				establish = establish and result.establish
			else
				-- OR运算
				final = final or establish
				establish = result.establish
			end
		end
	end
	final = final or establish
	return true, final
end

---分割条件
---@param conditions OM_Condition[] 条件
---@param field string 字段名；分组比对字段名
---@param value any 值；比对值，如果字段值等于该值将与前面一个条件一组，否则将创建新的分组
---@param default any 默认值；缺省比对值
---@return OM_Condition[][] group 条件
function OneMacroRunner:SplitCondition(conditions, field, value, default)
	-- 空条件
	local length = table.getn(conditions)
	if length == 0 then
		return {}
	end

	-- 单条件
	if length == 1 then
		return { conditions }
	end

	-- 多条件
	local groups = {}
	local current = {}
	for index, condition in ipairs(conditions) do
		if index == 1 then
			current = { condition }
		else
			local logical = condition[field] or default
			if logical == value then
				-- 加入当前组
				table.insert(current, condition)
			else
				-- 结束当前组，创建新组
				table.insert(groups, current)
				current = { condition }
			end
		end
	end

	-- 加入最后组
	table.insert(groups, current)
	return groups
end

---检验编组条件
---@param config table 配置
---@param conditions OM_Condition[] 条件；分割编组后的条件组
---@param detects table<string,OM_DetectSpace> 检测
---@param filter? string|nil 筛选
---@return boolean success 成功
---@return boolean|nil establish 成立
function OneMacroRunner:CheckGrouping(config, conditions, detects, filter)
	-- 分割逻辑条件：遇到AND就归前一个组，相当于用OR分割，组与组之间是OR关系
	local group = self:SplitCondition(conditions, "logical", "and", "and")
	for _, items in ipairs(group) do
		local success, establish = self:CheckLogical(config, items, detects, filter)
		if not success then
			return false
		end

		-- 因为分组之间是OR关系，只要有一个成立，则整个成立
		if establish then
			return true, true
		end
	end
	return true, false
end

---检验逻辑条件
---@param config table 配置
---@param conditions OM_Condition[] 条件；分割逻辑后的条件组，条件之间是AND关系
---@param detects table<string,OM_DetectSpace> 检测
---@param filter? string|nil 筛选
---@return boolean success 成功
---@return boolean|nil establish 成立
function OneMacroRunner:CheckLogical(config, conditions, detects, filter)
	-- 空条件
	local length = table.getn(conditions)
	if length == 0 then
		return true, true
	end

	-- 单条件
	if length == 1 then
		return self:CheckCondition(config, detects, conditions[1], filter)
	end

	-- 多条件
	for _, condition in ipairs(conditions) do
		local success, establish = self:CheckCondition(config, detects, condition, filter)
		if not success then
			return false
		end

		-- 因条件之间是AND关系，只要有一个不成立，则整个不成立
		if establish == false then
			return true, false
		end
	end
	return true, true
end

---检验单个条件
---@param config table 配置
---@param detects table<string,OM_DetectSpace> 检测
---@param condition OM_Condition 条件
---@param filter? string|nil 筛选
---@return boolean success 成功
---@return boolean|nil establish 成立
function OneMacroRunner:CheckCondition(config, detects, condition, filter)
	condition = condition or {}

	-- 左值
	local left
	local value = condition.left or {}
	if type(value.detect) == "string" and value.detect ~= "" then
		-- 检测值
		local success, result = self:GetDetect(config, detects, value, filter)
		if not success then
			return false
		end
		left = result
	else
		left = value.value
	end

	-- 符号
	local comparison = condition.comparison or "="

	-- 右值
	local right
	value = condition.right or {}
	if type(value.detect) == "string" and value.detect ~= "" then
		-- 检测值
		local success, result = self:GetDetect(config, detects, value, filter)
		if not success then
			return false
		end
		right = result
	else
		right = value.value
	end

	-- 比对
	local establish = self:ComparisonValue(comparison, left, right)
	return true, establish
end

---取检测结果
---@param config table 配置
---@param detects table<string,OM_DetectSpace> 检测
---@param value OM_Value 值
---@param filter? string|nil 筛选
---@return boolean success 成功
---@return any result 结果
function OneMacroRunner:GetDetect(config, detects, value, filter)
	-- 检验条件
	if type(value) ~= "table" then
		OneMacro:DebugError(2, "条件值无效")
		return false
	end

	if type(value.detect) ~= "string" or value.detect == "" then
		OneMacro:DebugError(2, "检测别名无效")
		return false
	end

	-- 解析检测名
	local space, method = self:ParseAlias(value.detect)
	if not space or not method then
		OneMacro:DebugError(2, "解析检测(%s)失败", value.detect)
		return false
	end

	-- 检验检测
	if type(detects[space]) ~= "table" or type(detects[space].detects[method]) ~= "table" then
		OneMacro:DebugError(2, "检测(%s)未注册", value.detect)
		return false
	end

	-- 检验选项
	local options = Array:DeepCopy(value.options) or {} -- 因后续会修改选项表值，这里需要深度拷贝
	local defines = detects[space].detects[method].options or {}
	for key, define in pairs(defines) do
		local name = define.name or key

		-- 必需
		if define.require and options[key] == nil then
			OneMacro:DebugError(2, "检测(%s)选项(%s)缺失", value.detect, name)
			return false
		end

		-- 类型
		if define.type and options[key] ~= nil and type(options[key]) ~= define.type then
			OneMacro:DebugError(2, "检测(%s)选项(%s)类型错误", value.detect, name)
			return false
		end

		-- 默认值
		if define.default and options[key] == nil then
			options[key] = define.default
		end

		-- 当前筛选单位
		if define.type == "string" and define.filter and options[key] == define.filter then
			options[key] = filter
		end
	end

	-- 回调检测
	local success, result = self:CallbackHandle(detects[space].detects[method].handle, config, filter, options)
	if not success then
		OneMacro:DebugError(2, "回调检测(%s)失败：\n%s", value.detect, result)
		return false
	end
	return true, result
end

---比对值
---@param symbol string|OM_Comparisons 符号
---@param left any 左值
---@param right any 右值
---@return boolean establish 成立
function OneMacroRunner:ComparisonValue(symbol, left, right)
	-- print(symbol, left, right)
	if symbol == "=" then
		-- 等于
		return left == right
	elseif symbol == "!=" then
		-- 不等于
		return left ~= right
	elseif symbol == "<" then
		-- 左值
		if left == nil then
			left = 0
		elseif type(left) ~= "number" then
			left = tonumber(left) or 0
		end

		-- 右值
		if right == nil then
			right = 0
		elseif type(right) ~= "number" then
			right = tonumber(right) or 0
		end

		-- 小于
		return left < right
	elseif symbol == "<=" then
		-- 左值
		if left == nil then
			left = 0
		elseif type(left) ~= "number" then
			left = tonumber(left) or 0
		end

		-- 右值
		if right == nil then
			right = 0
		elseif type(right) ~= "number" then
			right = tonumber(right) or 0
		end

		-- 小于等于
		return left <= right
	elseif symbol == ">" then
		-- 左值
		if left == nil then
			left = 0
		elseif type(left) ~= "number" then
			left = tonumber(left) or 0
		end

		-- 右值
		if right == nil then
			right = 0
		elseif type(right) ~= "number" then
			right = tonumber(right) or 0
		end

		-- 大于
		return left > right
	elseif symbol == ">=" then
		-- 左值
		if left == nil then
			left = 0
		elseif type(left) ~= "number" then
			left = tonumber(left) or 0
		end

		-- 右值
		if right == nil then
			right = 0
		elseif type(right) ~= "number" then
			right = tonumber(right) or 0
		end

		-- 大于等于
		return left >= right
	elseif symbol == "?" then
		if type(left) == "table" then
			-- 索引数组
			for _, value in ipairs(left) do
				if self:ComparisonValue(symbol, value, right) then
					return true
				end
			end
		else
			-- 左值
			if left == nil then
				left = ""
			elseif type(left) ~= "string" then
				left = tostring(left) or ""
			end

			-- 右值
			if right == nil then
				right = ""
			elseif type(right) ~= "string" then
				right = tostring(right) or ""
			end

			-- 包含
			return string.find(left, right) ~= nil
		end
	elseif symbol == "!?" then
		if type(left) == "table" then
			-- 索引数组
			for _, value in ipairs(left) do
				if not self:ComparisonValue(symbol, value, right) then
					return true
				end
			end
		else
			-- 左值
			if left == nil then
				left = ""
			elseif type(left) ~= "string" then
				left = tostring(left) or ""
			end

			-- 右值
			if right == nil then
				right = ""
			elseif type(right) ~= "string" then
				right = tostring(right) or ""
			end

			-- 不包含
			return string.find(left, right) == nil
		end
	elseif symbol == "%" then
		if type(left) == "table" then
			-- 索引数组
			for _, value in ipairs(left) do
				if not self:ComparisonValue(symbol, value, right) then
					return true
				end
			end
		else
			-- 左值
			if left == nil then
				left = ""
			elseif type(left) ~= "string" then
				left = tostring(left) or ""
			end

			-- 右值
			if right == nil then
				right = ""
			elseif type(right) ~= "string" then
				right = tostring(right) or ""
			end

			-- 匹配
			return string.match(left, right) ~= nil
		end
	elseif symbol == "!%" then
		if type(left) == "table" then
			-- 索引数组
			for _, value in ipairs(left) do
				if not self:ComparisonValue(symbol, value, right) then
					return true
				end
			end
		else
			-- 左值
			if left == nil then
				left = ""
			elseif type(left) ~= "string" then
				left = tostring(left) or ""
			end

			-- 右值
			if right == nil then
				right = ""
			elseif type(right) ~= "string" then
				right = tostring(right) or ""
			end

			-- 不匹配
			return string.match(left, right) == nil
		end
	else
		OneMacro:DebugError(2, "未知比对符(%s)", tostring(symbol))
	end
	return false
end

---执行多个操作
---@param config table 配置
---@param actions table<string,table<string,OM_Action>> 动作表
---@param operations OM_Operation[] 操作表
---@param filter? string|nil 筛选
---@return boolean success 成功
function OneMacroRunner:ExecuteOperations(config, actions, operations, filter)
	for _, operation in ipairs(operations) do
		if operation.disable ~= true and self:ExecuteOperation(config, actions, operation, filter) == false then
			return false
		end
	end
	return true
end

---执行操作
---@param config table 配置
---@param actions table<string,OM_ActionSpace> 动作
---@param operation OM_Operation 操作
---@param filter? string|nil 筛选
---@return boolean success 成功
function OneMacroRunner:ExecuteOperation(config, actions, operation, filter)
	-- 检验别名
	if type(operation.action) ~= "string" or operation.action == "" then
		OneMacro:DebugError(2, "动作别名无效")
		return false
	end

	-- 解析动作名
	local space, method = self:ParseAlias(operation.action)
	if not space or not method then
		OneMacro:DebugError(2, "解析动作(%s)失败", operation.action)
		return false
	end

	-- 检验动作
	if not actions[space] or not actions[space].actions[method] then
		OneMacro:DebugError(2, "动作(%s)未注册", operation.action)
		return false
	end

	-- 检验选项
	local options = Array:DeepCopy(operation.options) or {} -- 因后续会修改选项表值，这里需要深度拷贝

	local defines = actions[space].actions[method].options or {}
	for key, define in pairs(defines) do
		local name = define.name or key

		-- 必需
		if define.require and options[key] == nil then
			OneMacro:DebugError(2, "检测(%s)选项(%s)缺失", value.detect, name)
			return false
		end

		-- 类型
		if define.type and options[key] ~= nil and type(options[key]) ~= define.type then
			OneMacro:DebugError(2, "检测(%s)选项(%s)类型错误", value.detect, name)
			return false
		end

		-- 默认值
		if define.default and options[key] == nil then
			options[key] = define.default
		end

		-- 当前筛选单位
		if define.type == "string" and define.filter and options[key] == define.filter then
			options[key] = filter
		end
	end

	-- 回调动作
	local success, result = self:CallbackHandle(actions[space].actions[method].handle, config, filter, options)
	if not success then
		OneMacro:DebugError(2, "回调动作(%s)失败：\n%s", operation.action, result)
		return false
	end
	return true
end

---解析别名
---@param alias string 别名；格式为`空间名.方法名`
---@return string|nil space 空间名
---@return string|nil method 方法名
function OneMacroRunner:ParseAlias(alias)
	if type(alias) ~= "string" or alias == "" then
		return nil, nil
	end

	local pos = string.find(alias, "%.")
	if pos then
		local space = string.sub(alias, 1, pos - 1)
		local method = string.sub(alias, pos + 1)
		return space, method
	else
		return "Base", alias
	end
end

---回调处理
---@param handle function|string|table|{object:table,method:function|string}|[table,function|string] 处理
---@param ... any 参数
---@return boolean success  成功；失败为`false`，后续返回值为错误信息
---@return any ... 返回
function OneMacroRunner:CallbackHandle(handle, ...)
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
