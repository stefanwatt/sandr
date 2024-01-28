---@class Sandr.Input
---@field value? string
---@field mounted boolean
---@field nui_input? NuiInput
---@field source_win_id? number
---@field prompt string
---@field focused boolean

---@class Sandr.Keymap
---@field lhs string
---@field rhs function
---@field modes? string[]|string
---@field opts? any
---
---@class Sandr.Args
---@field visual boolean
---
---@class Sandr.BaseConfig
---@field toggle string
---@field toggle_ignore_case string

---@class Sandr.ExtendedConfig : Sandr.BaseConfig
---@field jump string
---@field range string
---@field flags string

---@class Sandr.UserConfig
---@field base Sandr.BaseConfig
---@field jump string

---@class Sandr.ConfigUpdate
---@field toggle? string
---@field toggle_ignore_case? string
---@field jump? string
---@field range? string
---@field flags? string

---@class Sandr.StateConfig
---@field extended Sandr.ExtendedConfig
---
--- @class Sandr.State
--- @field last_search_term string
--- @field last_search_terms string[]
--- @field search_term_completion_index number
--- @field last_replace_term string
--- @field last_replace_terms string[]
--- @field replace_term_completion_index number
--- @field config? Sandr.ExtendedConfig
--- @field matches? Sandr.Range[]
--- @field current_match? Sandr.Range
---
---@class Sandr.Position
---@field row number
---@field col number

---@class Sandr.Range
---@field start Sandr.Position
---@field finish Sandr.Position
