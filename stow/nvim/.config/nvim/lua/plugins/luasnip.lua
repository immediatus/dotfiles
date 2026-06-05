return {
  "L3MON4D3/LuaSnip",
  opts = { store_selection_keys = "<leader>ss" },
  config = function(plugin, opts)
    require("astronvim.plugins.configs.luasnip")(plugin, opts)
    local ls = require("luasnip")
    ls.add_snippets("all", {
      ls.s("kat", {
        ls.t("{% katex() %}"),
        ls.f(function(_, snip)
          local res = table.concat(snip.env.TM_SELECTED_TEXT or {}, "\n")
          return res:gsub("^\\\\?%(", ""):gsub("\\\\?%)$", "")
        end),
        ls.t("{% end %}"),
        ls.i(0)
      }),
    })
  end,
}
