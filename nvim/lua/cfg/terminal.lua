local HEIGHT = 15

-- Ordered list of terminal buffers: [1] is the bottom horizontal split,
-- the rest are vertical splits to its right.
local terminals = {}

local function prune()
    local kept = {}
    for _, buf in ipairs(terminals) do
        if vim.api.nvim_buf_is_valid(buf) then
            kept[#kept + 1] = buf
        end
    end
    terminals = kept
end

local function win_for_buf(buf)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_buf(win) == buf then
            return win
        end
    end
end

local function visible_wins()
    local wins = {}
    for _, buf in ipairs(terminals) do
        local win = win_for_buf(buf)
        if win then
            wins[#wins + 1] = win
        end
    end
    return wins
end

local function spawn()
    vim.cmd("terminal")
    terminals[#terminals + 1] = vim.api.nvim_get_current_buf()
    vim.cmd("startinsert")
end

-- Re-show every remembered terminal, rebuilding the bottom row.
local function restore()
    for i, buf in ipairs(terminals) do
        if i == 1 then
            vim.cmd("botright split")
            vim.api.nvim_win_set_buf(0, buf)
            vim.cmd("resize " .. HEIGHT)
        else
            vim.cmd("rightbelow vsplit")
            vim.api.nvim_win_set_buf(0, buf)
        end
    end
end

local function new_terminal()
    prune()

    if #terminals == 0 then
        vim.cmd("botright split")
        vim.cmd("resize " .. HEIGHT)
        spawn()
        return
    end

    local wins = visible_wins()
    if #wins == 0 then
        restore()
    else
        vim.api.nvim_set_current_win(wins[#wins])
    end

    vim.cmd("rightbelow vsplit")
    spawn()
end

local function toggle_terminals()
    prune()

    local wins = visible_wins()
    if #wins > 0 then
        for _, win in ipairs(wins) do
            pcall(vim.api.nvim_win_close, win, false)
        end
    elseif #terminals > 0 then
        restore()
        vim.cmd("startinsert")
    else
        new_terminal()
    end
end

vim.keymap.set("n", "<leader>tt", new_terminal, { desc = "New terminal (bottom, then split right)" })
vim.keymap.set("n", "<leader>tg", toggle_terminals, { desc = "Toggle all terminals" })

vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])
