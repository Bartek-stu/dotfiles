return {
    {
        'saghen/blink.cmp',
        -- Release tags ship the prebuilt Rust fuzzy matcher, so there is no
        -- cargo build step. Tracking '1.*' keeps that guarantee.
        version = '1.*',
        event = { 'InsertEnter', 'CmdlineEnter' },
        opts = {
            -- 'default' keeps insert-mode keys out of the way:
            --   <C-space> open menu   <C-n>/<C-p> cycle   <C-y> accept
            --   <C-e> cancel          <C-k> signature help
            -- Swap for 'super-tab' or 'enter' if you want Tab/CR to accept.
            keymap = { preset = 'default' },

            appearance = { nerd_font_variant = 'mono' },

            completion = {
                documentation = { auto_show = true, auto_show_delay_ms = 200 },
                ghost_text = { enabled = true },
            },

            signature = { enabled = true },

            sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },

            fuzzy = { implementation = 'prefer_rust_with_warning' },
        },
    },
}
