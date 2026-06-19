return {
  "supermaven-inc/supermaven-nvim",
  event = "InsertEnter",
  opts = {
    keymaps = {
      accept_suggestion = "<Tab>",
      clear_suggestion = "<C-]>",
      accept_word = "<C-j>",
    },
    ignore_filetypes = {
    },
    color = {
      suggestion_color = "#ffffff",
      cterm = 244,
    },
    disable_inline_completion = false,
    disable_keymaps = false,
  },
}
