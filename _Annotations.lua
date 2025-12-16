---@meta _

---@alias OM_Scopes string 范围
---| "raid" 团队
---| "team" 小队；小队（团队）或队伍(组队)
---| "party" 队伍；仅组队的
---| "roster" 名单
---| "player" 玩家；自己
---| "target" 目标；仅可协助的，包含目标和目标的目标

---@alias OM_Sorts string 排序
---| "asc" 升序；按权重升序
---| "desc" 降序；按权重降序
---| "disturb" 打乱；随机排序

---@alias OM_Chooses string 选取
---| "first" 第一个
---| "last" 最后一个
---| "random" 随机一个
---| "traverse" 遍历每个；直到满足条件或遍历完

---@alias OM_Logicals string 逻辑
---| "and" 且
---| "or" 或

---@alias OM_Comparisons string 比对
---| "=" 等于
---| "!=" 不等于
---| "<" 小于
---| "<=" 小于等于
---| ">" 大于
---| ">=" 大于等于
---| "?" 包含
---| "!?" 不包含
---| "%" 匹配
---| "!%" 不匹配

---@alias OM_Types string 类型
---| "nil" 空
---| "boolean" 布尔
---| "number" 数字
---| "string" 字符串

---@class OM_Option 选项
---@field type OM_Types 类型
---@field name? string 名称；缺省为选项键名
---@field require? boolean 必需；缺省为`false`
---@field default? nil|boolean|number|string 默认；缺省为`nil`
---@field filter? string 筛选；缺省为`nil`；选项值为该值时将重置为当前筛选单位，仅检测和动作选项时有效
---@field remark? string 备注

---@class OM_Weight 权重
---@field name? string 名称；缺省为权重键名
---@field options? table<string,OM_Option> 选项；定义权重接受的选项
---@field handle fun(config:table,unit:string,options:table):number|string|{object:table,method:function|string} 处理
---@field remark? string 备注
---@field order? number 顺序；缺省为0

---@class OM_Detect 检测
---@field name? string 名称；缺省为检测键名
---@field options? table<string,OM_Option> 选项；定义检测接受的选项
---@field result OM_Result 结果；定义检测返回的结果
---@field handle fun(config:table,filter:string|nil,options:table):any|string|{object:table,method:function|string} 处理
---@field remark? string 备注
---@field order? number 顺序；缺省为0

---@class OM_Action 动作
---@field name? string 名称；缺省为动作键名
---@field options? table<string,OM_Option> 选项；定义动作接受的选项
---@field handle fun(config:table,filter:string|nil,options:table):any|string|{object:table,method:function|string} 处理
---@field remark? string 备注
---@field order? number 顺序；缺省为0

---@class OM_Result 结果定义
---@field type OM_Types 类型
---@field remark? string 备注

---@class OM_Value 值；优先`detect`否则为`value`
---@field detect? string 检测；已注册检测全名（空间键名.检测键名）
---@field options? table<string,nil|boolean|number|string> 选项；深度拷贝传递给检测选项
---@field value? nil|boolean|number|string 值；缺省为`nil`
---@field remark? string 备注

---@class OM_Filter 筛选
---@field scopes? OM_Scopes[] 范围；欲要筛选的范围
---@field weight? string 权重；已注册权重全名（空间键名.权重键名），缺省为筛选索引
---@field options? table<string,any> 选项；深度拷贝传递给权重选项
---@field sort? OM_Sorts 排序；缺省为`desc`
---@field choose? OM_Chooses 选取；缺省为`first`
---@field limit? number 限数；缺省不限；限定遍历数量，当`choose`值为`traverse`时生效
---@field remark? string 备注

---@class OM_Condition 条件
---@field grouping? boolean 编组；缺省为`false`；是否与前一个条件编组，相当于用括号括起来
---@field logical? OM_Logicals 逻辑；缺省为`and`；与前一个条件或编组（编组后第一个条件）的逻辑
---@field left OM_Value 左值
---@field comparison? OM_Comparisons 比对符；缺省为`=`
---@field right OM_Value 右值
---@field remark? string 备注

---@class OM_Operation 操作
---@field action string 动作；已注册动作全名（空间键名.动作键名）
---@field options? table<string,nil|boolean|number|string> 选项；深度拷贝传递给动作选项
---@field disable? boolean 禁用；缺省为`false`
---@field remark? string 备注

---@class OM_Rule 规则
---@field name? string 名称；缺省为规则索引
---@field disable? boolean 禁用；缺省为`false`
---@field filter? OM_Filter 筛选
---@field conditions? OM_Condition[] 条件
---@field operations OM_Operation[] 操作
---@field continue? boolean 继续；缺省为`false`；是否在条件成立后，继续执行下一个规则
---@field remark? string 备注

---@class OM_Strategy 策略
---@field name? string 名称；缺省为策略索引
---@field rules OM_Rule[] 规则
---@field expand? boolean 展开；缺省为`false`；是否展开规则
---@field remark? string 备注
---@field readme? string 自述

----------------------------------------------------------------------

---@alias ReportKinds string 通报类型；公共支持插值：PlayerName、PlayerHealth、PlayerMana、TargetName
---| `CastInstant` 施法瞬发；支持插值：SpellName
---| `CastFailure` 施法失败；支持插值：SpellName
---| `CastCastingStart` 施法读条开始；支持插值：SpellName
---| `CastCastingChange` 施法读条改变；支持插值：SpellName
---| `CastCastingFinish` 施法读条完成；支持插值：SpellName
---| `CastChannelingStart` 施法引导开始；支持插值：SpellName
---| `CastChannelingChange` 施法引导改变；支持插值：SpellName
---| `CastChannelingFinish` 施法引导完成；支持插值：SpellName
---| `AuraCancel` 光环取消；支持插值：BuffName
---| `BuffGain` 增益获得；支持插值：BuffName
---| `BuffLost` 增益失去；支持插值：BuffName
---| `DebuffGain` 减益获得；支持插值：DebuffName
---| `DebuffLost` 减益失去；支持插值：DebuffName
---| `SpellHit` 法术已命中；支持插值：SpellName、VictimName
---| `SpellMiss` 法术未命中；支持插值：SpellName、VictimName
---| `SpellLeech` 法术吸收；支持插值：SpellName、VictimName
---| `SpellDispel` 法术驱散；支持插值：SpellName、VictimName

---@alias ReportModes string 通报方式
---| `SAY` 说
---| `YELL` 大喊
---| `PARTY` 小队
---| `RAID` 团队
---| `PRINT` 打印
---| `PROMPT` 提示

---@class OM_StrategyProfile 策略资料，会固化数据
---@field list OM_Strategy[] 列表
---@field selected any 选中

---@class OM_WeightProfile 权重资料，会固化数据
---@field expands table<string,boolean> 展开
---@field selected any 选中

---@class OM_DetectProfile 检测资料，会固化数据
---@field expands table<string,boolean> 展开
---@field selected any 选中

---@class OM_ActionProfile 动作资料，会固化数据
---@field expands table<string,boolean> 展开
---@field selected any 选中

---@class OM_RosterProfile 名单资料，会固化数据
---@field list string[] 列表
---@field show boolean 显示

---@class OM_Report 通报
---@field disable? boolean 禁用；缺省为`false`
---@field mode? string|ReportModes 方式；缺省为`SAY`
---@field message string 消息
---@field remark? string 备注
---@field order? number 顺序；缺省为为0

---@class OM_ReportKind 通报种类
---@field name string 名称
---@field reports table<string,OM_Report> 通报
---@field remark? string 备注
---@field expand? boolean 展开；缺省为`false`
---@field order? number 顺序；缺省为为0

---@class OM_ReportProfile 通报资料，会固化数据
---@field list table<ReportKinds,OM_ReportKind> 列表
---@field selected any 选中

---@class OM_Profile 资料
---@field strategy OM_StrategyProfile 策略资料
---@field weight OM_WeightProfile 权重资料，会固化数据
---@field detect OM_DetectProfile 检测资料，会固化数据
---@field action OM_ActionProfile 动作资料，会固化数据
---@field roster OM_RosterProfile 名单资料，会固化数据
---@field report OM_ReportProfile 通报资料，会固化数据
---@field debug {enable:boolean,level:number} 调试

---@class OM_WeightSpace 权重空间，由插件等动态注册
---@field name string 名称；缺省为空间键名
---@field weights table<string,OM_Weight> 权重
---@field remark? string 备注；缺省为空字符串
---@field order? number 顺序；缺省为为0

---@class OM_DetectSpace 检测空间，由插件等动态注册
---@field name string 名称；缺省为空间键名
---@field detects table<string,OM_Detect> 检测
---@field remark? string 备注；缺省为空字符串
---@field order? number 顺序；缺省为为0

---@class OM_ActionSpace 动作空间，由插件等动态注册
---@field name string 名称；缺省为空间键名
---@field actions table<string,OM_Action> 动作
---@field remark? string 备注；缺省为空字符串
---@field order? number 顺序；缺省为为0


------------------------------------------------------------------------
