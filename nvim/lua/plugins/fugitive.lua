return {
{
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Gedit", "GBrowse", "Gclog", "Ggrep" },
    keys = {
        { "<leader>gs", vim.cmd.Git, desc = "Git status" },
        { "<leader>gb", function() vim.cmd.Git("blame") end, desc = "Git blame" },
        { "<leader>gd", vim.cmd.Gvdiffsplit, desc = "Git diff (vertical split)" },
        { "<leader>gl", vim.cmd.Gclog, desc = "Git log (quickfix)" },
        { "<leader>gp", function() vim.cmd.Git("push origin HEAD") end, desc = "Git push" },
        { "<leader>gP", function() vim.cmd.Git("push --force origin HEAD") end, desc = "Git force push" },
    },
}
}
