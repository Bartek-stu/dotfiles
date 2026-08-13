return {
{
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    -- Not lazy-loaded: netrw is disabled below, so nvim-tree is the only thing
    -- left that can render a directory buffer (`nvim .`, `:e some/dir`). That
    -- hijack has to be registered at startup, before the buffer is entered.
    lazy = false,
    init = function()
        -- Required by nvim-tree, and has to happen before netrw's plugin would load.
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1
    end,
    opts = {
        view = {
            width = 35,
            preserve_window_proportions = true,
        },
        renderer = {
            group_empty = true,
            highlight_git = true,
            indent_markers = { enable = true },
        },
        filters = {
            dotfiles = false,
            -- nvim-tree hides git-ignored files by default
            git_ignored = false,
        },
        -- Follow the buffer you're editing as you move around.
        update_focused_file = {
            enable = true,
            update_root = false,
        },
        actions = {
            open_file = {
                resize_window = false,
            },
        },
    },
    keys = {
        { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" },
        { "<leader>E", "<cmd>NvimTreeFindFile<CR>", desc = "Reveal current file in tree" },
    },
}
}
