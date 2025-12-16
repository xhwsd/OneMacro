--[[
Name: KuBa-Bleed-1.0
Revision: $Rev: 10002 $
Author(s): 树先生 (xhwsd@qq.com)
Website: https://gitee.com/ku-ba
Description: 可否流血相关库。
Dependencies: AceLibrary
]]

-- 主要版本
local MAJOR_VERSION = "KuBa-Bleed-1.0"
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

---可否流血相关库。
---@class KuBa-Bleed-1.0
local Library = {}

--------------------------------

-- 元素生物或机械的白名单
local WHITELIST = {
	-- 熔火之心
    ["加尔"] = true,

	-- 世界
    ["灌木塑根者"] = true,
    ["灌木露水收集者"] = true,
    ["长瘤的灌木兽"] = true,
}

-- 非元素生物或机械的黑名单
local BLACKLIST = {
	-- 卡拉赞上层
    ["地狱之怒碎片"] = true,
    ["噩梦爬行者"] = true,
    ["麦迪文的回响"] = true,
    ["恶魔之心"] = true,
    ["战争使者监军"] = true,
    ["兵卒"] = true,
    ["共鸣水晶"] = true,
    ["徘徊的魔法师"] = true,
    ["徘徊的占星家"] = true,
    ["徘徊的魔术师"] = true,
    ["徘徊的工匠"] = true,
    ["鬼灵训练师"] = true,
    ["荒芜的入侵者"] = true,

	-- 卡拉赞下层
    ["幻影守卫"] = true,
    ["幽灵厨师"] = true,
    ["闹鬼铁匠"] = true,
    ["幻影仆从"] = true,
    ["莫罗斯"] = true,

	-- 纳克萨玛斯
    ["瘟疫战士"] = true,
    ["白骨构造体"] = true,
    ["邪恶之斧"] = true,
    ["邪恶法杖"] = true,
    ["邪恶之剑"] = true,
    ["纳克萨玛斯之魂"] = true,
    ["纳克萨玛斯之影"] = true,
    ["憎恨吟唱者"] = true,
    ["死灵骑士"] = true,
    ["死灵骑士卫兵"] = true,
    ["骷髅骏马"] = true,

    -- 熔火之心
    ["熔核巨人"] = true,
    ["暗炉卫士"] = true,
    ["暗炉织焰者"] = true,
    ["暗炉圣职者"] = true,
    ["法师领主索瑞森"] = true,

    -- 安琪拉废墟
    ["莫阿姆"] = true,
    
	-- 斯坦索姆
    ["安娜丝塔丽男爵夫人"] = true,
    ["埃提耶什"] = true,

	-- 其他
    ["黑衣守卫斥候"] = true,
    ["哀嚎的女妖"] = true,
    ["尖叫的女妖"] = true,
    ["无眼观察者"] = true,
    ["黑暗法师"] = true,
    ["幽灵训练师"] = true,
    ["受难的上层精灵"] = true,
    ["死亡歌手"] = true,
    ["恐怖编织者"] = true,
    ["哀嚎的死者"] = true,
    ["亡鬼幻象"] = true,
    ["恐惧骸骨"] = true,
    ["骷髅刽子手"] = true,
    ["骷髅剥皮者"] = true,
    ["骷髅守护者"] = true,
    ["骷髅巫师"] = true,
    ["骷髅军官"] = true,
    ["骷髅侍僧"] = true,
    ["游荡的骷髅"] = true,
    ["骷髅铁匠"] = true,
    ["鬼魅随从"] = true,
    ["艾德雷斯妖灵"] = true,
    ["天灾勇士"] = true,
    ["不安宁的阴影"] = true,
    ["不死的看守者"] = true,
    ["哀嚎的鬼怪"] = true,
    ["被诅咒的灵魂"] = true,
    ["不死的居民"] = true,
    ["幽灵工人"] = true,
}

-- 检验单位能否流血
---@param unit? string 单位名称；缺省为`target`
---@return boolean can 能流血返回真，否则返回假
function Library:CanBleed(unit)
	unit = unit or "target"
    
	local name = UnitName(unit)
	if not name then
		return false
    end

	local type = UnitCreatureType(unit) or "其它"
	if string.find("元素生物,机械", type) then
	    -- 元素生物或机械，位于白名单
        if WHITELIST[name] then
            return true
        end

        -- 元素生物或机械，默认不流血
        return false
    else
        -- 非元素生物或机械，位于黑名单
        if BLACKLIST[name] then
			return false
		end

        -- 非元素生物或机械，默认可流血
        return true
	end
end

--------------------------------

-- 库激活
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

-- 外部库加载
---@param self table 库自身对象
---@param major string 外部库主版本
---@param instance table 外部库实例
local function external(self, major, instance)

end

-- 最终注册库
AceLibrary:Register(Library, MAJOR_VERSION, MINOR_VERSION, activate, nil, external)
---@diagnostic disable-next-line
Library = nil