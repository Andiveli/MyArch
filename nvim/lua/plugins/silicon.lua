return {
    "michaelrommel/nvim-silicon",
    to_clipboard = true,
    cmd = "Silicon",
    config = function()
        require("silicon").setup({
            font = "JetBrainsMono Nerd Font=26", -- Correcto
            background = "#282a36",
            theme = "Dracula",
            output = function()
                local basePath = "/home/samael/Pictures/nvim_silicon/"
                local bufferName = vim.fn.fnamemodify(vim.fn.bufname(vim.fn.bufnr()), ":t:r")
                local timestamp = os.date("%Y%m%d_%H%M%S")
                return basePath .. bufferName .. "_" .. timestamp .. ".png"
            end,
            pad_vert = 80,
            pad_horiz = 50,
            -- watermark = {
            --     text = " @eSeylaA69",
            -- },
            window_title = function()
                return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), ":t")
            end,
        })
    end,
    lazy = true,
    keys = {
        mode = { "v" },
        { "<leader>S", group = "Silicon" },
        {
            "<leader>Sc",
            function()
                require("nvim-silicon").clip()
            end,
            desc = "Copy code screenshot to clipboard",
        },
        {
            "<leader>Sf",
            function()
                require("nvim-silicon").file()
            end,
            desc = "Save code screenshot as file",
        },
        {
            "<leader>Ss",
            function()
                require("nvim-silicon").shoot()
            end,
            desc = "Create code screenshot",
        },
    },
}
