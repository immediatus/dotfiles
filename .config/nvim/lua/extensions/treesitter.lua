require('nvim-treesitter.configs').setup({
  ensure_installed = { 'go', 'lua', 'python' },
  sync_install = false,
  highlight = { enable = true, disable = {} },
  indent = { enable = true, disable = {} },
})
