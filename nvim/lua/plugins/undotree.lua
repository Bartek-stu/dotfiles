return {
{
    "mbbill/undotree",
    cmd = { "UndotreeToggle", "UndotreeShow", "UndotreeFocus" },
    keys = {
        { "<leader>u", vim.cmd.UndotreeToggle, desc = "Toggle undotree" },
    },
    init = function()
        vim.g.undotree_SetFocusWhenToggle = 1
    end,
}
}
