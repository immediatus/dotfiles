if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize Treesitter

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "lua",
      "vim",
      "python",
      "javascript",
      "typescript",
      "rust",
      "go",
      "c",
      "cpp",
      "ruby",
      "php",
      "html",
      "css",
      "sql",
      "json",
      "yaml",
      "toml",
    },
  },
}
