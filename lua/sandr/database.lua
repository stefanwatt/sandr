local Path = require("plenary.path")
local M = {}

local data_path = vim.fn.stdpath("data")
local json_file_path = Path:new(data_path, "sandr.json"):absolute()

local function read_config()
    local file = Path:new(json_file_path)
    if not file:exists() then
        return { search_terms = {}, replace_terms = {} }
    end

    local content = file:read()
    return vim.fn.json_decode(content)
        or { search_terms = {}, replace_terms = {} }
end

local function write_config(data)
    local json_str = vim.fn.json_encode(data)
    Path:new(json_file_path):write(json_str, "w")
end

M.save_search_terms = function(search_terms)
    local data = read_config()
    data.search_terms = search_terms
    write_config(data)
end

M.save_replace_terms = function(replace_terms)
    local data = read_config()
    data.replace_terms = replace_terms
    write_config(data)
end

M.load_search_terms = function()
    local data = read_config()
    return data.search_terms or {}
end

M.load_replace_terms = function()
    local data = read_config()
    return data.replace_terms or {}
end

return M
