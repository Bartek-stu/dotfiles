return {
    {
   'nvim-telescope/telescope.nvim', version = '*',
    dependencies = {
            'nvim-lua/plenary.nvim',
            -- optional but recommended
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>pf', builtin.find_files, { desc = 'Find files' })
      vim.keymap.set('n', '<C-p>', builtin.git_files, { desc = 'Find git files' })
      vim.keymap.set('n', '<leader>gS', "<cmd>Telescope lsp_document_symbols<CR>", {
            desc = "Document symbols",
       })
    end,
    }
}
