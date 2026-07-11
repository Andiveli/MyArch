return {
    {
        -- {
        --   "xiyaowong/transparent.nvim",
        --   config = function()
        --     require("transparent").setup({
        --       extra_groups = { -- table/string: additional groups that should be cleared
        --         "Normal",
        --         "NormalNC",
        --         "Comment",
        --         "Constant",
        --         "Special",
        --         "Identifier",
        --         "Statement",
        --         "PreProc",
        --         "Type",
        --         "Underlined",
        --         "Todo",
        --         "String",
        --         "Function",
        --         "Conditional",
        --         "Repeat",
        --         "Operator",
        --         "Structure",
        --         "LineNr",
        --         "NonText",
        --         "SignColumn",
        --         "CursorLineNr",
        --         "EndOfBuffer",
        --       },
        --       exclude_groups = {}, -- table: groups you don't want to clear
        --     })
        --   end,
        -- },
        {
            "catppuccin/nvim",
            name = "catppuccin",
            priority = 1000,
            opts = {
                flavour = "mocha",
                transparent_background = true,

                custom_highlights = function(colors)
                    return {
                        LineNr = { bg = "none" },
                        NormalFloat = { bg = "none" },
                        FloatBorder = { bg = "none" },
                        FloatTitle = { bg = "none" },
                        TelescopeNormal = { bg = "none" },
                        TelescopeBorder = { bg = "none" },
                        LspInfoBorder = { bg = "none" },
                    }
                end,

                integrations = {
                    lualine = true,
                    telescope = true,
                    cmp = true,
                    treesitter = true,
                },
            },
        },
        {
            "Gentleman-Programming/gentleman-kanagawa-blur",
            name = "gentleman-kanagawa-blur",
            priority = 1000,
        },
        {
            "Andiveli/samael-purple-night",
            name = "samael-purple-night",
            priority = 1000,
            lazy = false,
        },
        {
            "Alan-TheGentleman/oldworld.nvim",
            lazy = false,
            priority = 1000,
            opts = {},
        },
        {
            "rebelot/kanagawa.nvim",
            priority = 1000,
            lazy = true,
            config = function()
                require("kanagawa").setup({
                    compile = false, -- enable compiling the colorscheme
                    undercurl = true, -- enable undercurls
                    commentStyle = { italic = true },
                    functionStyle = {},
                    keywordStyle = { italic = true },
                    statementStyle = { bold = true },
                    typeStyle = {},
                    transparent = true, -- do not set background color
                    dimInactive = false, -- dim inactive window `:h hl-NormalNC`
                    terminalColors = true, -- define vim.g.terminal_color_{0,17}
                    colors = { -- add/modify theme and palette colors
                        palette = {},
                        theme = {
                            wave = {},
                            lotus = {},
                            dragon = {},
                            all = {
                                ui = {
                                    bg_gutter = "none", -- set bg color for normal background
                                    bg_sidebar = "none", -- set bg color for sidebar like nvim-tree
                                    bg_float = "none", -- set bg color for floating windows
                                },
                            },
                        },
                    },
                    overrides = function() -- add/modify highlights
                        return {
                            LineNr = { bg = "none" },
                            NormalFloat = { bg = "none" },
                            FloatBorder = { bg = "none" },
                            FloatTitle = { bg = "none" },
                            TelescopeNormal = { bg = "none" },
                            TelescopeBorder = { bg = "none" },
                            LspInfoBorder = { bg = "none" },
                        }
                    end,
                    theme = "wave", -- Load "wave" theme
                    background = { -- map the value of 'background' option to a theme
                        dark = "wave", -- try "dragon" !
                        light = "lotus",
                    },
                })
            end,
        },
        {
            "LazyVim/LazyVim",
            opts = {
                colorscheme = "samael-purple-night",
            },
        },
        {
            "folke/tokyonight.nvim",
            priority = 1000,
            opts = {
                transparent = true,
                styles = {
                    sidebars = "transparent",
                    floats = "transparent",
                },

                on_highlights = function(hl, c)
                    hl.LineNr = { bg = "none" }
                    hl.NormalFloat = { bg = "none" }
                    hl.FloatBorder = { bg = "none" }
                    hl.FloatTitle = { bg = "none" }
                    hl.TelescopeNormal = { bg = "none" }
                    hl.TelescopeBorder = { bg = "none" }
                    hl.LspInfoBorder = { bg = "none" }
                end,
            },
        },
    },
}
