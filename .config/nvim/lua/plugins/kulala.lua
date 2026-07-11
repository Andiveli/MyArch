return {
    "mistweaverco/kulala.nvim",
    keys = {
        {
            "<leader>ks",
            function()
                require("kulala").run()
            end,
            desc = "Send request",
        },
        {
            "<leader>ka",
            function()
                require("kulala").run_all()
            end,
            desc = "Send all requests",
        },
        {
            "<leader>kb",
            function()
                require("kulala").run_all()
            end,
            desc = "Open scratchpad",
        },
    },
    ft = { "http", "rest" },
    opts = {
        contenttypes = {
            ["application/json"] = {
                ft = "json",
                formatter = vim.fn.executable("jq") == 1 and { "jq", "." },
                pathresolver = function(...)
                    return require("kulala.parser.jsonpath").parse(...)
                end,
            },
            ["application/graphql"] = {
                ft = "graphql",
                formatter = vim.fn.executable("prettier") == 1
                    and { "prettier", "--stdin-filepath", "graphql", "--parser", "graphql" },
                pathresolver = nil,
            },
            ["application/xml"] = {
                ft = "xml",
                formatter = vim.fn.executable("xmllint") == 1 and { "xmllint", "--format", "-" },
                pathresolver = vim.fn.executable("xmllint") == 1 and { "xmllint", "--xpath", "{{path}}", "-" },
            },
            ["text/html"] = {
                ft = "html",
                formatter = vim.fn.executable("xmllint") == 1 and { "xmllint", "--format", "--html", "-" },
                pathresolver = nil,
            },
        },
        global_keymaps = false,
        global_keymaps_prefix = "<leader>R",
        kulala_keymaps_prefix = "",
        request_timeout = 5000,
        ui = {
            split_direction = "vertical",
            -- display_mode = "float",
            autocomplete = true,
            lua_syntax_hl = true,
            float = {
                width = 0.9,
                height = 0.8,
                border = "rounded",
            },
        },
        show_icons = "signcolumn",
    },
}
