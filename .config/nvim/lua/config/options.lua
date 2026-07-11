-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- Autoguardado seguro sin plugins
-- Evitar problemas con swap y backups
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
-- Configuración de tabs
vim.opt.expandtab = true -- usar espacios en lugar de tab
vim.opt.shiftwidth = 4 -- número de espacios para >> y <<
vim.opt.tabstop = 4 -- número de espacios que ocupa un tab
vim.opt.softtabstop = 4 -- espacios que se insertan al presionar Tab
vim.opt.smartindent = true -- indentación automática inteligente

vim.api.nvim_create_autocmd({ "InsertLeave", "FocusLost" }, {
    pattern = "*",
    callback = function()
        -- solo guarda si el buffer existe, es modificable y tiene nombre
        if vim.bo.modifiable and vim.bo.filetype ~= "" and vim.bo.filetype ~= "alpha" then
            vim.cmd("silent! update")
        end
    end,
})
