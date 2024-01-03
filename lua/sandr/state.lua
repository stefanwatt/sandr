local database = require("sandr.database")
--- @class SearchAndReplaceState
--- @field last_search_term string
--- @field last_search_terms string[]
--- @field last_replace_term string
--- @field last_replace_terms string[]
local state = {
    last_search_term = "",
    last_search_terms = {},
    last_replace_term = "",
    last_replace_terms = {},
}
local M = {}

M.get_last_search_term = function()
    return state.last_search_term
end

M.set_last_search_term = function(search_term)
    state.last_search_term = search_term
    if #state.last_search_terms < 11 then
        table.insert(state.last_search_terms, 1, search_term)
    else
        table.remove(state.last_search_terms, #state.last_search_terms)
        table.insert(state.last_search_terms, 1, search_term)
    end
    database.save_search_terms(state.last_search_terms)
end

M.get_last_replace_term = function()
    return state.last_replace_term
end

M.set_last_replace_term = function(replace_term)
    state.last_replace_term = replace_term
    if #state.last_replace_terms < 11 then
        table.insert(state.last_replace_terms, 1, replace_term)
    else
        table.remove(state.last_replace_terms, #state.last_replace_terms)
        table.insert(state.last_replace_terms, 1, replace_term)
    end
    database.save_replace_terms(state.last_replace_terms)
end

M.get_last_search_terms = function()
    return state.last_search_terms
end

M.get_last_replace_terms = function()
    return state.last_replace_terms
end

M.read_from_db = function()
    state.last_search_terms = database.load_search_terms()
    state.last_replace_terms = database.load_replace_terms()
end

return M
