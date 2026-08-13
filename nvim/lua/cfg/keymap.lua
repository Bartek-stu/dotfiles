vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("x", "<leader>p", "\"_dP")

vim.keymap.set("n", "<leader>y", "\"+y")
vim.keymap.set("v", "<leader>y", "\"+y")
vim.keymap.set("n", "<leader>Y", "\"+Y")

vim.keymap.set("n", "<leader>d", "\"_d")
vim.keymap.set("v", "<leader>d", "\"_d")

vim.keymap.set("n", "Q", "<nop>")
-- Run tmux-sessionizer in its own tmux window so it never blocks nvim or forces
-- a redraw. That needs a running tmux server - `tmux neww` has nothing to hang
-- a window off otherwise -- so report that instead of failing obscurely.
vim.keymap.set("n", "<C-f>", function()
    if not vim.env.TMUX then
        vim.notify("tmux-sessionizer needs nvim to be running inside tmux", vim.log.levels.WARN)
        return
    end
    vim.system({ "tmux", "neww", "tmux-sessionizer" }, { text = true }, function(out)
        if out.code ~= 0 then
            vim.schedule(function()
                local msg = (out.stderr ~= "" and out.stderr) or ("exit " .. out.code)
                vim.notify("tmux-sessionizer: " .. msg, vim.log.levels.ERROR)
            end)
        end
    end)
end, { desc = "tmux sessionizer" })
local function tmux_sessionizer_session(index)
    return function()
        if not vim.env.TMUX then
            vim.notify("tmux-sessionizer needs nvim to be running inside tmux", vim.log.levels.WARN)
            return
        end
        -- `tmux-sessionizer -s` already creates/selects its target tmux window.
        -- Wrapping it in `tmux neww` creates a temporary window that exits once
        -- sessionizer finishes, so it looks like the terminal closes immediately.
        vim.system({ "tmux-sessionizer", "-s", tostring(index) }, { text = true }, function(out)
            if out.code ~= 0 then
                vim.schedule(function()
                    local msg = (out.stderr ~= "" and out.stderr) or ("exit " .. out.code)
                    vim.notify("tmux-sessionizer -s " .. index .. ": " .. msg, vim.log.levels.ERROR)
                end)
            end
        end)
    end
end

vim.keymap.set("n", "<M-h>", tmux_sessionizer_session(0), { desc = "tmux session command 0" })
vim.keymap.set("n", "<M-t>", tmux_sessionizer_session(1), { desc = "tmux session command 1" })
vim.keymap.set("n", "<M-n>", tmux_sessionizer_session(2), { desc = "tmux session command 2" })
vim.keymap.set("n", "<M-s>", tmux_sessionizer_session(3), { desc = "tmux session command 3" })

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

local closer_of = { ["("] = ")", ["["] = "]", ["{"] = "}" }
local opener_of = { [")"] = "(", ["]"] = "[", ["}"] = "{" }
vim.keymap.set("i", "<Tab>", function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    -- Scan the whole line so closers already sitting after the cursor count
    -- as matched, then close the last opener still unmatched before the cursor.
    local stack = {}
    for pos = 1, #line do
        local c = line:sub(pos, pos)
        if closer_of[c] then
            table.insert(stack, { char = c, pos = pos })
        elseif opener_of[c] and #stack > 0 and stack[#stack].char == opener_of[c] then
            table.remove(stack)
        end
    end
    for i = #stack, 1, -1 do
        if stack[i].pos <= col then
            return closer_of[stack[i].char]
        end
    end
    return "<Tab>"
end, { expr = true, desc = "Close nearest open bracket, else tab" })

