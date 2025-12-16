--[[
Name: KuBa-Item-1.0
Revision: $Rev: 10001 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://gitee.com/ku-ba
Description: 物品（装备、消耗品等）相关库。
Dependencies: AceLibrary
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-Item-1.0"
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

---物品（装备、消耗品等）相关库。
---@class KuBa-Item-1.0
local Library = {}

--------------------------------

-- 套装列表，[插槽标识](https://warcraft.wiki.gg/wiki/InventorySlotID)
local SUIT_LIST = {
	-- T2.5猫德
	["起源套甲"] = {
		["起源皮盔"] = 1,
		["起源肩垫"] = 3,
		["起源长袍"] = 5,
		["起源短裤"] = 7,
		["起源便靴"] = 8
	},
	-- T3奶德
	["梦游者"] = {
		["梦游者头饰"] = 1,
		["梦游者肩饰"] = 3,
		["梦游者外套"] = 5,
		["梦游者束带"] = 6,
		["梦游者护腿"] = 7,
		["梦游者长靴"] = 8,	
		["梦游者腕甲"] = 9,
		["梦游者护手"] = 10,
		["梦游者之戒"] = {11, 12},
	}
}

---链接转名称
---@param link string 链接；支持装备和物品
---@return string? name 名称
function Library:LinkToName(link)
	if link then
		local name = string.gsub(link, "^.*%[(.*)%].*$", "%1")
		return name
	end
end

---链接到附魔
---@param link string 物品链接
---@return number? enchant 附魔
function Library:LinkToEnchant(link)
	if type(link) == "number" then
		return link
	elseif type(link) == "string" then
		local _, _, id = string.find(link, "item:%d+:(%d+):%d+:%d+")
		if id then
			return tonumber(id)
		end
	end
end

---取名称
---@param index number 索引；装备插槽或背包索引
---@param slot? number 插槽；传递视为背包插槽
---@return string? name 名称
---@return string? link 链接
function Library:GetName(index, slot)
	local link
	if index and slot then
		-- 包中物品
		link = GetContainerItemLink(index, slot)
	elseif index then
		-- 身上装备
		link = GetInventoryItemLink("player", index)
	end

	-- 有效链接
	if link then
		return self:LinkToName(link), link
	end
end

---查找物品，支持身上装备或包中物品
---@param name string 名称
---@return number? index 背包索引或装备插槽
---@return number? slot 背包插槽；非`nil`为背包插槽
---@return string? name 名称
---@return string? link 链接
function Library:Find(name)
	-- 到小写
	name = string.lower(name)

	-- 遍历装备
	for index = 1, 23 do
		local item, link = self:GetName(index)
		if item then
			if item and string.lower(item) == name then
				return index, nil, item, link
			end
		end
	end

	-- 遍历背包
	for bag = 0, NUM_BAG_FRAMES do
		-- 遍历背包插槽
		for slot = 1, MAX_CONTAINER_ITEMS do
			local item, link = self:GetName(bag, slot)
			if item and string.lower(item) == name then
				return bag, slot, item, link
			end
		end
	end
end

---取物品冷却
---@param name string 名称；支持身上装备或包中物品
---@return number? seconds 秒数
---@return number? start 开始
---@return number? duration 持续
function Library:GetCooldown(name)
	-- 冷却文档 https://warcraft.wiki.gg/wiki/Cooldown
	
	-- 查找物品
	local start, duration, enable
	local index, slot = self:Find(name)
	if index and slot then
		-- 包中物品
		start, duration, enable = GetContainerItemCooldown(index, slot)
	elseif index then
		-- 身上装备
		start, duration, enable = GetInventoryItemCooldown("player", index)
	end

	-- 可使用物品
	if enable == 1 then
		local seconds = 0
		if start > 0 then
			seconds = start + duration - GetTime()
		end
		return seconds, start, duration
	end
end

---是否就绪
---@param name string 名称；支持身上装备或包中物品
---@return boolean ready 就绪；不可使用为`false`
function Library:IsReady(name)
	local seconds = self:GetCooldown(name)
	if seconds then
		return seconds == 0
	else
		return false
	end
end

---使用物品
---@param name string 名称；支持身上装备或包中物品
---@return number? index 背包索引或装备索引
---@return number? slot 插槽索引；非`nil`为背包插槽索引
function Library:Use(name)
	-- 查找物品
	local index, slot = self:Find(name)
	if index and slot then
		-- 使用包中物品
		UseContainerItem(index, slot)
		return index, slot
	elseif bag then
		-- 使用身上装备
		UseInventoryItem(bag)
		return bag
	end
end

---总数
---@param name string 名称；仅限包中物品
---@return number total 总数
function Library:Total(name)
	local total = 0

	-- 到小写
	name = string.lower(name)

	-- 遍历背包
	for bag = 0, NUM_BAG_FRAMES do
		-- 遍历插槽
		for slot = 1, MAX_CONTAINER_ITEMS do
			local item = self:GetName(bag, slot)
			if item and string.lower(item) == name then
				local _, count = GetContainerItemInfo(bag, slot)
				total = total + count
			end
		end
	end
	return total
end

---饰品冷却
---@param down? boolean 为下饰品
---@return number? seconds 秒数
---@return number? start 开始
---@return number? duration 持续
function Library:TrinketCooldown(down)
	down = down or false

	-- 13.上饰品 14.下饰品
	local slot = down and 14 or 13
	local start, duration = GetInventoryItemCooldown("player", slot)

	-- 可使用物品
	if enable == 1 then
		local seconds = 0
		if start > 0 then
			seconds = start + duration - GetTime()
		end
		return seconds, start, duration
	end
end

---饰品就绪
---@param down? boolean 为下饰品
---@return boolean ready 就绪；不可使用为`false`
function Library:TrinketReady(down)
	-- 取冷却
	local seconds = self:TrinketCooldown(down)
	if seconds then
		return seconds == 0
	else
		return false
	end
end

---使用饰品
---@param down? boolean 为下饰品
function Library:UseTrinket(down)
	down = down or false
	-- 13.上饰品 14.下饰品
	local slot = down and 14 or 13 
	UseInventoryItem(slot)
end

---套装计数
---@param suit string 套装；可选值：起源套甲、梦游者
---@return number count 计数
function Library:SuitCount(suit)
	local count = 0
	if SUIT_LIST[suit] then
		for name, slots in pairs(SUIT_LIST[suit]) do
			name = string.lower(name)
			if type(slots) == "number" then
				local item = self:GetName(slots)
				if item and string.lower(item) == name then
					count = count + 1
				end
			elseif type(slots) == "table" then
				-- 如戒指或饰品支持多插槽
				for _, slot in ipairs(slots) do
					local item = self:GetName(slot)
					if item and string.lower(item) == name then
						count = count + 1
					end
				end
			end
		end
	end
	return count
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