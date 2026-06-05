return {
  "Saghen/blink.cmp",
  opts = function(_, opts)
    opts.keymap = opts.keymap or {}

    local old_tab = opts.keymap["<Tab>"] or { "snippet_forward", "select_next", "fallback" }

    opts.keymap["<Tab>"] = {
--      function()
--        if vim.g.ai_accept and vim.g.ai_accept() then return true end
--      end,
      function()
        local suggestion = require("supermaven-nvim.completion_preview")
        if suggestion and suggestion.has_suggestion() then
          -- schedule() moves the text change out of the locked keypress event
          vim.schedule(function()
            suggestion.on_accept_suggestion()
          end)
          return true -- Tells blink we handled the keypress
        end
      end,
      unpack(old_tab)
    }

    return opts
  end,
}
