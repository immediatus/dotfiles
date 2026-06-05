return {
  {
    "zbirenbaum/copilot.lua",
    opts = function(_, opts)
      -- 1. Enable Markdown explicitly
      opts.filetypes = {
        markdown = true,
        yaml = true,
        help = false,
        gitcommit = false,
        ["."] = false,
      }

      opts.suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = {
          accept = false, -- Handled by AstroNvim ai_accept bridge
        },
      }

      -- 3. Existing AstroNvim bridge
      vim.g.ai_accept = function()
        if require("copilot.suggestion").is_visible() then
          require("copilot.suggestion").accept()
          return true
        end
      end
    end,
  },
}
