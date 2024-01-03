local database = require("sandr.database")
local utils = require("sandr.utils")
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
    if
        not search_term
        or search_term == ""
        or utils.find(state.last_search_terms, function(term)
            return term == search_term
        end)
    then
        return
    end
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
    if
        not replace_term
        or replace_term == ""
        or utils.find(state.last_replace_terms, function(term)
            return term == replace_term
        end)
    then
        return
    end
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
