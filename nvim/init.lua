-- Configure Node.js before loading plugins
require("config.nodejs").setup({ silent = true })

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0
-- Prepend pipx bin to PATH dentro de Neovim
vim.env.PATH = os.getenv("HOME") .. "/.local/bin:" .. vim.env.PATH
