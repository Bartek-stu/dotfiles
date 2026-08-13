return {
    {
        'nvim-treesitter/nvim-treesitter',
        branch = 'main', -- new default branch; master is frozen for backward compat only
        lazy = false,
        build = ':TSUpdate',
        config = function()
            -- parsers to install (see :h nvim-treesitter or SUPPORTED_LANGUAGES.md).
            -- Kept in cfg/parsers.lua so bootstrap.sh can install the same list
            -- synchronously in headless nvim.
            -- install missing parsers asynchronously (no-op if already present).
            -- nvim-treesitter main uses the tree-sitter CLI for builds; skip
            -- auto-install if bootstrap has not installed it yet.
            if vim.fn.executable('tree-sitter') == 1 then
                require('nvim-treesitter').install(require('cfg.parsers'))
            end

            -- On the main branch, highlighting and indentation are NOT enabled by
            -- setup(). Neovim provides them per-buffer; turn them on for any
            -- filetype that has an installed parser.
            vim.api.nvim_create_autocmd('FileType', {
                callback = function(args)
                    local buf = args.buf
                    local ft = vim.bo[buf].filetype
                    local lang = vim.treesitter.language.get_lang(ft)
                    -- start() errors if the parser isn't installed, so guard it
                    if lang and pcall(vim.treesitter.start, buf, lang) then
                        -- treesitter-based indentation (experimental upstream)
                        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                    end
                end,
            })
        end,
    },
    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        branch = 'main', -- must match nvim-treesitter's branch
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            require('nvim-treesitter-textobjects').setup {
                select = {
                    -- jump forward to the next textobject when the cursor
                    -- isn't already inside one (like targets.vim)
                    lookahead = true,
                },
            }

            -- On the main branch keymaps are defined by the user, not setup()
            local select = require('nvim-treesitter-textobjects.select')
            vim.keymap.set({ 'x', 'o' }, 'af', function()
                select.select_textobject('@function.outer', 'textobjects')
            end, { desc = 'Select outer function' })
            vim.keymap.set({ 'x', 'o' }, 'if', function()
                select.select_textobject('@function.inner', 'textobjects')
            end, { desc = 'Select inner function' })
        end,
    },
}
