local database = require("sandr.database")
local utils = require("sandr.utils")

---@type SandrState
local state = {
    last_search_term = "",
    last_search_terms = {},
    search_term_completion_index = 1,
    last_replace_term = "",
    last_replace_terms = {},
    replace_term_completion_index = 1,
    matches = {},
    current_match = nil,
}
local M = {}

---@param config SandrConfigUpdate
function M.update_config(config)
    Congig = vim.tbl_deep_extend("force", Config or {}, config)
end

---@param matches SandrRange[]
function M.set_matches(matches)
    state.matches = matches
end

function M.get_matches()
    return state.matches
end

---@param match SandrRange
function M.set_current_match(match)
    state.current_match = match
end

function M.get_current_match()
    return state.current_match
end

function M.set_search_term_completion_index(index)
    state.search_term_completion_index = index
end

function M.get_search_term_completion_index()
    return state.search_term_completion_index
end

function M.set_replace_term_completion_index(index)
    state.replace_term_completion_index = index
end

function M.get_replace_term_completion_index()
    return state.replace_term_completion_index
end

function M.get_last_search_term()
    return state.last_search_term
end

function M.set_last_search_term(search_term)
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

function M.get_last_replace_term()
    return state.last_replace_term
end

function M.set_last_replace_term(replace_term)
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

function M.get_last_search_terms()
    return state.last_search_terms
end

function M.get_last_replace_terms()
    return state.last_replace_terms
end

function M.read_from_db()
    state.last_search_terms = database.load_search_terms()
    state.last_replace_terms = database.load_replace_terms()
end

return M
