--[[
Name: KuBa-Array-1.0
Revision: $Rev: 10005 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://gitee.com/ku-ba
Description: 数组相关库。
Dependencies: AceLibrary
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-Array-1.0"
-- 次要版本
local MINOR_VERSION = "$Revision: 10005 $"

-- 检验AceLibrary
if not AceLibrary then
	error(MAJOR_VERSION .. " requires AceLibrary")
end

-- 检验版本（本库，单实例）
if not AceLibrary:IsNewVersion(MAJOR_VERSION, MINOR_VERSION) then
	return
end

---数组相关库。
---@class KuBa-Array-1.0
local Library = {}

--------------------------------

---计算表中成员数
---@param data any 数据
---@return number count 数量
function Library:Count(data)
    if type(data) ~= "table" then
        return 0
    end

    local count = 0
    for _ in pairs(data) do
        count = count + 1
    end
    return count
end

---检验是否是索引表，可使用`ipairs`遍历
---@param data any 数据
---@return boolean is 是否是
function Library:IsList(data)
    if type(data) ~= "table" then
        return false
    end

    local count = 0
    for key, _ in pairs(data) do
        if type(key) ~= "number" or key < 1 or math.floor(key) ~= key then
            return false
        end

        if key > count then
            count = key
        end
    end

    for index = 1, count do
        if data[index] == nil then
            return false
        end
    end
    return true
end

---检验是否是关联表，仅可使用`pairs`遍历
---@param data any 数据
---@return boolean is 是否是
function Library:IsAssoc(data)
    if type(data) ~= "table" then
        return false
    end

    for key, _ in pairs(data) do
        if type(key) ~= "number" or math.floor(key) ~= key then
            return true
        end
    end
    return false
end

---数据位与列表
---@param list table 索引表
---@param data any 数据
---@return number? index 成功返回索引，失败返回空
function Library:InList(list, data)
	if type(list) == "table" then
		for index, value in ipairs(list) do
			if value == data then
				return index
			end
		end
	end
end

---数据位与关联
---@param assoc table 关联表
---@param data any 数据
---@return string? key 成功返回键，失败返回空
function Library:InAssoc(assoc, data)
	if type(assoc) == "table" then
		for key, value in pairs(assoc) do
			if value == data then
				return key
			end
		end
	end
end

---取键名
---@param assoc table 关联表
---@return table keys
function Library:GetKeys(assoc)
    local keys = {}
	if type(assoc) == "table" then
		for key, _ in pairs(assoc) do
            table.insert(keys, key)
		end
	end
    return keys
end

---取顺序
---@param assoc table 关联表
---@param handle function 排序函数；`{key:string,data:any}`
---@return table keys 键名列表
function Library:GetOrders(assoc, handle)
    local keys = {}
    if type(assoc) == "table" then
        -- 转为索引数组
        local array = {}
        for key, value in pairs(assoc) do
            table.insert(array, {
                key = key,
                data = value
            })
        end

        -- 排序索引数组
        table.sort(array, handle)

        -- 取键名
        for _, value in ipairs(array) do
            table.insert(keys, value.key)
        end
    end
    return keys
end

---深度拷贝
---@param data table 数据
---@return table copy 复制
function Library:DeepCopy(data)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end

        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(data)
end

--------------------------------

---库激活
---@param self table 库自身对象
---@param oldLib table 旧版库对象
---@param oldDeactivate function 旧版库停用函数
local function Activate(self, oldLib, oldDeactivate)
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
local function External(self, major, instance)

end

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line
Library = nil