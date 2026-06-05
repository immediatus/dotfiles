return {
  "ojroques/nvim-osc52",
  event = "VeryLazy",
  config = function()
    local osc52 = require "osc52"
    osc52.setup {
      max_length = 0, -- No limit on selection length
      silent = true, -- Disable message on copy
      trim = false, -- Don't trim surrounding whitespace
    }

    -- Function to use as clipboard provider
    local function copy(lines, _) osc52.copy(table.concat(lines, "\n")) end

    local function paste() return { vim.fn.split(vim.fn.getreg "", "\n"), vim.fn.getregtype "" } end

    -- Set OSC 52 as the clipboard provider for AstroNvim
    vim.g.clipboard = {
      name = "osc52",
      copy = { ["+"] = copy, ["*"] = copy },
      paste = { ["+"] = paste, ["*"] = paste },
    }
  end,
}
