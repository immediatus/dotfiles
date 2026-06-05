return {
  {
    "nickjvandyke/opencode.nvim",
    event = "User AstroFile",
    dependencies = { 
      "nvim-lua/plenary.nvim",
      "folke/snacks.nvim", -- Required for the improved terminal and pickers
    },
    init = function()

      vim.o.autoread = true
      vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "CursorHoldI", "FocusGained" }, {
        command = "if mode() != 'c' | checktime | endif",
        pattern = { "*" },
      })

      vim.g.opencode_opts = {
        server = {
          start = function()
            require("snacks.terminal").open("opencode serve --port 42069", {
              win = { position = "right", width = 0.4 },
              on_win = function(win) 
                require("opencode.terminal").setup(win.win) 
              end,
            })
          end,
          port = 42069,
        },
      }
      vim.o.autoread = true
    end,
  },

  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>a"] = { desc = "   AI (OpenCode)" },
          ["<Leader>aa"] = { function() require("opencode").ask("@this: ", { submit = true }) end, desc = "Ask OpenCode" },
          ["<Leader>as"] = { function() require("opencode").select() end, desc = "Select Action" },
          ["<Leader>at"] = { function() require("opencode").toggle() end, desc = "Toggle UI" },
        },
        x = {
          ["<Leader>a"] = { desc = "   AI (OpenCode)" },
          ["<Leader>aa"] = { function() require("opencode").ask("@this: ", { submit = true }) end, desc = "Ask about selection" },
        },
      },
    },
  },
}
