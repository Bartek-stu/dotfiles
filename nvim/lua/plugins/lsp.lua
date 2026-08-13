-- Neovim 0.12 already ships the entire LSP client: vim.lsp.config/enable, the
-- default keymaps (grn, gra, grr, gri, gO, K, i_<C-s>), diagnostics and
-- vim.lsp.completion. That is why lsp-zero is obsolete -- it was a wrapper
-- around plumbing that now lives in core.
--
-- The one thing core does NOT ship is the per-server data: which binary to
-- spawn, which filetypes it owns, which files mark a project root. That is all
-- nvim-lspconfig still is -- a bag of lsp/<name>.lua files dropped onto the
-- runtimepath for vim.lsp.enable() to read. No setup() calls, no framework.

return {
    {
        'neovim/nvim-lspconfig',
        -- blink.cmp has to be loaded before the config below runs so we can
        -- hand its extra completion capabilities to every server.
        dependencies = { 'saghen/blink.cmp' },
        event = { 'BufReadPre', 'BufNewFile' },
        config = function()
            -- Two tool directories that hold language servers but are missing
            -- from the login shell's PATH:
            --   ~/.dotnet/tools -- /etc/paths.d/dotnet-cli-tools lists it as a
            --     literal "~/.dotnet/tools" and path_helper never expands "~".
            --   ~/.local/bin    -- where `uv tool install` puts binaries.
            for _, dir in ipairs({ '~/.dotnet/tools', '~/.local/bin' }) do
                local p = vim.fs.normalize(dir)
                if not vim.env.PATH:find(p, 1, true) then
                    vim.env.PATH = p .. ':' .. vim.env.PATH
                end
            end

            -- Three config layers merge per server, lowest precedence first:
            --   1. vim.lsp.config('*')      -- this block
            --   2. lsp/<name>.lua on the rtp -- nvim-lspconfig's data
            --   3. vim.lsp.config('<name>')  -- the overrides below
            -- So '*' is the right home for things every server should inherit,
            -- and a server's own capabilities table still deep-merges on top.
            vim.lsp.config('*', {
                capabilities = require('blink.cmp').get_lsp_capabilities(),
            })

            -- rust -- rust-analyzer (installed via rustup)
            vim.lsp.config('rust_analyzer', {
                settings = {
                    ['rust-analyzer'] = {
                        check = { command = 'clippy' },
                        cargo = { buildScripts = { enable = true } },
                        procMacro = { enable = true },
                        inlayHints = {
                            closureReturnTypeHints = { enable = 'with_block' },
                        },
                    },
                },
            })

            -- go -- gopls
            vim.lsp.config('gopls', {
                settings = {
                    gopls = {
                        gofumpt = true,
                        staticcheck = true,
                        analyses = {
                            nilness = true,
                            unusedparams = true,
                            unusedwrite = true,
                            useany = true,
                        },
                        hints = {
                            assignVariableTypes = true,
                            compositeLiteralFields = true,
                            constantValues = true,
                            functionTypeParameters = true,
                            parameterNames = true,
                            rangeVariableTypes = true,
                        },
                        env = { CGO_ENABLED = "1" },
                    },
                },
            })

            -- c / c++ -- clangd. Needs a compile_commands.json (or
            -- compile_flags.txt) at the project root to know your flags;
            -- CMake emits one with -DCMAKE_EXPORT_COMPILE_COMMANDS=ON.
            vim.lsp.config('clangd', {
                cmd = {
                    'clangd',
                    '--background-index',
                    '--clang-tidy',
                    '--header-insertion=iwyu',
                    '--completion-style=detailed',
                    -- Homebrew's clangd rejects the bare flag; it wants a value.
                    '--function-arg-placeholders=1',
                },
            })

            -- swift -- sourcekit-lsp from the Xcode toolchain. Upstream also
            -- claims c/cpp/objc, which would put sourcekit-lsp and clangd on
            -- the same buffer; leave C and C++ to clangd.
            vim.lsp.config('sourcekit', {
                filetypes = { 'swift', 'objc', 'objcpp' },
            })

            -- typescript / javascript -- the native (Go) TypeScript server.
            -- TypeScript 7 ships it inside the `tsc` binary as `tsc --lsp`;
            -- the standalone preview package installs it as `tsgo`. We reuse
            -- nvim-lspconfig's tsgo entry for its monorepo- and Deno-aware
            -- root detection and only swap in the command.
            --
            -- Only a *local* tsgo is preferred -- deliberately not a local
            -- `tsc`, because a project pinned to TypeScript 5.x has a tsc that
            -- does not understand --lsp and would fail to start.
            vim.lsp.config('tsgo', {
                cmd = function(dispatchers, config)
                    local bin = 'tsc'
                    local root = (config or {}).root_dir
                    if root then
                        local local_tsgo = vim.fs.joinpath(root, 'node_modules/.bin/tsgo')
                        if vim.fn.executable(local_tsgo) == 1 then
                            bin = local_tsgo
                        end
                    end
                    return vim.lsp.rpc.start({ bin, '--lsp', '--stdio' }, dispatchers)
                end,
            })

            -- python -- two servers share the buffer by design: basedpyright
            -- does types/completion/hover, ruff does lint and formatting.
            -- Turn off ruff's hover so it does not compete with basedpyright.
            vim.lsp.config('basedpyright', {
                settings = {
                    basedpyright = {
                        analysis = {
                            -- 'workspace' type-checks the whole project rather
                            -- than just open files. Drop back to
                            -- 'openFilesOnly' if it gets heavy on a monorepo.
                            diagnosticMode = 'workspace',
                            -- ruff already reports these (F401/F841) and says
                            -- it better; without this both servers flag the
                            -- same unused import on the same line.
                            diagnosticSeverityOverrides = {
                                reportUnusedImport = 'none',
                                reportUnusedVariable = 'none',
                            },
                            inlayHints = {
                                variableTypes = true,
                                callArgumentNames = true,
                                functionReturnTypes = true,
                                genericTypes = false,
                            },
                        },
                    },
                },
            })
            vim.lsp.config('ruff', {
                on_attach = function(client)
                    client.server_capabilities.hoverProvider = false
                end,
            })

            -- kotlin -- kotlin-language-server is built for Java 21+, but the
            -- default `java` on this machine is 17, which refuses to load its
            -- class files. Hand the server a new enough JDK without disturbing
            -- JAVA_HOME for anything else.
            -- Pin 21 rather than "newest available": the Kotlin compiler
            -- bundled in kotlin-language-server 1.3.13 cannot read the JRT
            -- filesystem of the current unversioned brew openjdk.
            local jdk = vim.iter({
                '/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home',
                '/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home',
            }):find(function(p)
                return vim.uv.fs_stat(p) ~= nil
            end)
            if jdk then
                vim.lsp.config('kotlin_language_server', {
                    cmd_env = { JAVA_HOME = jdk },
                })
            end

            -- c# -- `dotnet tool install` bakes the installing SDK's root into
            -- the roslyn-language-server apphost, and Homebrew's dotnet
            -- recorded a path that holds no runtime. The shim therefore dies
            -- with "You must install .NET to run this application" and ignores
            -- DOTNET_ROOT, so there is no env fix. Skip the shim and hand the
            -- managed dll to `dotnet exec`, which resolves the runtime itself.
            local roslyn_dll = vim.fn.glob(
                vim.fs.normalize('~/.dotnet/tools/.store/roslyn-language-server')
                    .. '/*/*/*/tools/*/*/Microsoft.CodeAnalysis.LanguageServer.dll',
                true,
                true
            )
            if #roslyn_dll > 0 then
                table.sort(roslyn_dll)
                vim.lsp.config('roslyn_ls', {
                    cmd = { 'dotnet', 'exec', roslyn_dll[#roslyn_dll], '--stdio' },
                })
            end

            vim.lsp.enable({
                'basedpyright',           -- python (types)
                'clangd',                 -- c, c++
                'gopls',                  -- go
                'kotlin_language_server', -- kotlin
                'roslyn_ls',              -- c#
                'ruff',                   -- python (lint, format)
                'rust_analyzer',          -- rust
                'sourcekit',              -- swift
                'tsgo',                   -- typescript, javascript
            })

            vim.diagnostic.config({
                severity_sort = true,
                underline = true,
                virtual_text = { spacing = 2, prefix = '>' },
                float = { border = 'rounded', source = true },
            })

            -- nvim-lspconfig's :LspRestart still routes through its legacy
            -- lspconfig.configs registry, which vim.lsp.enable() never
            -- populates -- it stops servers and never brings them back. So
            -- restart natively: stop every client on the buffer, then
            -- re-enable once they are actually down. client:stop() is async,
            -- so re-enabling immediately would only re-attach the dying one.
            local function restart_clients(bufnr)
                local clients = vim.lsp.get_clients({ bufnr = bufnr })
                if #clients == 0 then
                    return
                end

                local names = vim.tbl_map(function(c)
                    return c.name
                end, clients)
                for _, name in ipairs(names) do
                    vim.lsp.enable(name, false)
                end

                local timer = assert(vim.uv.new_timer())
                local tries = 0
                timer:start(50, 50, vim.schedule_wrap(function()
                    tries = tries + 1
                    local down = vim.iter(clients):all(function(c)
                        return c:is_stopped()
                    end)
                    -- 5s cap so a server that refuses to die cannot leak the timer
                    if not down and tries < 100 then
                        return
                    end
                    timer:close()
                    vim.lsp.enable(names)
                    -- vim.lsp.enable() only re-attaches pre-existing buffers
                    -- via doautoall, and only once vim_did_enter is set -- and
                    -- that fires FileType for every buffer, not just this one.
                    -- Re-trigger its own autocmd directly for this buffer.
                    vim.api.nvim_exec_autocmds('FileType', {
                        group = 'nvim.lsp.enable',
                        buffer = bufnr,
                    })
                    vim.notify(
                        (down and 'LSP restarted: ' or 'LSP restart timed out: ') .. table.concat(names, ', '),
                        down and vim.log.levels.INFO or vim.log.levels.WARN
                    )
                end))
            end

            -- Format on save. clear = false because the autocmds inside are
            -- buffer-scoped and cleared per buffer below -- clearing the whole
            -- group on each attach would tear down other buffers' hooks.
            local fmt_group = vim.api.nvim_create_augroup('cfg.lsp.format', { clear = false })

            -- Escape hatch: :FormatOnSave off  (or set vim.b.disable_autoformat
            -- for one buffer). Useful when editing a repo whose style you must
            -- not reflow.
            vim.api.nvim_create_user_command('FormatOnSave', function(a)
                if a.args == 'on' then
                    vim.g.disable_autoformat = false
                elseif a.args == 'off' then
                    vim.g.disable_autoformat = true
                else
                    vim.g.disable_autoformat = not vim.g.disable_autoformat
                end
                vim.notify('format on save: ' .. (vim.g.disable_autoformat and 'off' or 'on'))
            end, {
                nargs = '?',
                complete = function()
                    return { 'on', 'off' }
                end,
                desc = 'Toggle LSP format on save',
            })

            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('cfg.lsp.attach', {}),
                callback = function(args)
                    local buf = args.buf
                    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

                    local function map(mode, keys, fn, desc)
                        vim.keymap.set(mode, keys, fn, { buffer = buf, desc = 'LSP: ' .. desc })
                    end

                    -- Core 0.12 already maps these buffer-locally on attach:
                    --   grn rename          gra code action (normal + visual)
                    --   grr references      gri implementation
                    --   grt type definition gO  document symbols
                    --   grx run code lens   K   hover
                    --   i_<C-s> signature help
                    -- Everything below is either a gap core leaves open or the
                    -- same verb bound to a key you'd rather reach for.
                    map('n', 'gd', vim.lsp.buf.definition, 'Goto definition')
                    map('n', 'gD', vim.lsp.buf.declaration, 'Goto declaration')
                    map('n', 'gy', vim.lsp.buf.type_definition, 'Goto type definition')

                    map('n', '<leader>vd', vim.diagnostic.open_float, 'Line diagnostics')
                    map('n', '<leader>vws', vim.lsp.buf.workspace_symbol, 'Workspace symbol')
                    map('n', '<leader>vca', vim.lsp.buf.code_action, 'Code action')
                    map('n', '<leader>vrr', vim.lsp.buf.references, 'References')
                    map('n', '<leader>vrn', vim.lsp.buf.rename, 'Rename')

                    map('n', '<leader>lf', function()
                        vim.lsp.buf.format({ async = true })
                    end, 'Format buffer')
                    map('n', '<leader>lr', function()
                        restart_clients(buf)
                    end, 'Restart servers for this buffer')

                    if client:supports_method('textDocument/formatting') then
                        -- LspAttach fires once per client, and python attaches
                        -- two. Clear this buffer's hook first so the file is
                        -- not formatted twice per write.
                        vim.api.nvim_clear_autocmds({ group = fmt_group, buffer = buf })
                        vim.api.nvim_create_autocmd('BufWritePre', {
                            group = fmt_group,
                            buffer = buf,
                            desc = 'LSP format on save',
                            callback = function()
                                if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then
                                    return
                                end
                                -- Synchronous on purpose: async = true would
                                -- race the write and land after the file is
                                -- already on disk. Default timeout is 1s, which
                                -- rust-analyzer and clangd can exceed.
                                vim.lsp.buf.format({
                                    bufnr = buf,
                                    async = false,
                                    timeout_ms = 3000,
                                })
                            end,
                        })
                    end

                    if client:supports_method('textDocument/inlayHint') then
                        vim.lsp.inlay_hint.enable(true, { bufnr = buf })
                        map('n', '<leader>lh', function()
                            local on = vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
                            vim.lsp.inlay_hint.enable(not on, { bufnr = buf })
                        end, 'Toggle inlay hints')
                    end

                    -- Core binds i_<C-s> to this already. <C-h> is kept because
                    -- it is easier to reach, but note that terminals which do
                    -- not use the kitty keyboard protocol send <C-h> and <BS>
                    -- as the same byte (0x08) -- in those, this eats backspace.
                    map('i', '<C-h>', vim.lsp.buf.signature_help, 'Signature help')
                end,
            })
        end,
    },
}
