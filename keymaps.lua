-- ~/.config/nvim/lua/config/keymaps.lua
-- Copy selected text to clipboard
vim.keymap.set("v", "<C-S-c>", '"+y', { desc = "Copy to system clipboard" })
-- Paste clipboard in normal mode
vim.keymap.set("n", "<C-S-v>", '"+p', { desc = "Paste from system clipboard" })
-- Paste clipboard in insert mode
vim.keymap.set("i", "<C-S-v>", "<C-r>+", { desc = "Paste from clipboard (insert)" })
