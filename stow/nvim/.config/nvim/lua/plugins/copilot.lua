return {
  {
    "github/copilot.vim",
    cmd = "Copilot",
    event = "User AstroFile",
    config = function()
      -- Disable default tab mapping to avoid conflicts with autocomplete engines
      vim.g.copilot_no_tab_map = true

      -- Configure filetypes
      vim.g.copilot_filetypes = {
        markdown = true,
        yaml = true,
        help = false,
        gitcommit = false,
        ["."] = false,
      }

      -- AstroNvim bridge to accept suggestion
      vim.g.ai_accept = function()
        local suggestion = vim.fn["copilot#GetDisplayedSuggestion"]()
        if (type(suggestion) == "table" and suggestion.text and suggestion.text ~= "")
           or (type(suggestion) == "string" and suggestion ~= "") then
          -- Feed keys to accept suggestion
          local accept = vim.fn["copilot#Accept"]("")
          vim.api.nvim_feedkeys(accept, "i", true)
          return true
        end
      end
    end,
  },
}
