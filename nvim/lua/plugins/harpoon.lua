return {
{
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")

        -- REQUIRED
        harpoon:setup()
        -- REQUIRED
    end,
    keys = {
        { "<leader>a", function() require("harpoon"):list():add() end, desc = "Harpoon add file" },
        { "<C-e>", function() local h = require("harpoon") h.ui:toggle_quick_menu(h:list()) end, desc = "Harpoon quick menu" },

        { "<C-h>", function() require("harpoon"):list():select(1) end, desc = "Harpoon file 1" },
        { "<C-t>", function() require("harpoon"):list():select(2) end, desc = "Harpoon file 2" },
        { "<C-n>", function() require("harpoon"):list():select(3) end, desc = "Harpoon file 3" },
        { "<C-s>", function() require("harpoon"):list():select(4) end, desc = "Harpoon file 4" },

        -- Toggle previous & next buffers stored within Harpoon list
        { "<C-S-P>", function() require("harpoon"):list():prev() end, desc = "Harpoon prev" },
        { "<C-S-N>", function() require("harpoon"):list():next() end, desc = "Harpoon next" },
    },
}
}
