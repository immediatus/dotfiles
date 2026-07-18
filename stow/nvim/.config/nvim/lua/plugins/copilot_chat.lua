return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    keys = {
      {
        "<leader>aq",
        function()
          vim.ui.input({ prompt = "Quick Chat: " }, function(input)
            if input ~= "" then require("CopilotChat").ask(input) end
          end)
        end,
        desc = "Quick Chat (CopilotChat)",
        mode = { "n", "v" },
      },
      {
        "<leader>ap",
        function()
          local chat = require "CopilotChat"
          chat.toggle()
        end,
        desc = "Toggle Copilot Chat Window",
      },
      {
        "<leader>as",
        function() require("CopilotChat").select_prompt() end,
        desc = "Open Prompt Selection Menu",
      },
      {
        "<leader>ax",
        function() return require("CopilotChat").reset() end,
        desc = "Clear (CopilotChat)",
        mode = { "n", "v" },
      },
    },
    config = function(_, _)
      -- Auto-command to customize chat buffer behavior
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "copilot-*",
        callback = function()
          vim.opt_local.relativenumber = false
          vim.opt_local.number = false
          vim.opt_local.conceallevel = 0
        end,
      })
      require("CopilotChat").setup {
        how_folds = false,
        show_help = false,
        auto_insert_mode = false,
        sticky = "#buffer",
        answer_header = "  Copilot ",
        question_header = "  User ",
        temperature = 0.1,
        window = {
          layout = "vertical",
          width = 0.3,
        },

        prompts = {},

        model = "qwen3.5-122b-local",
        provider = "lemonade_local",
        providers = {
          copilot = { enabled = false },
          github_models = { enabled = false },
          lemonade_local = {
            get_url = function() return "http://127.0.0.1:13305/v1/chat/completions" end,
            get_headers = function() return { ["Content-Type"] = "application/json" } end,
            get_models = function()
              return {
                { id = "qwen3.5-122b-local", name = "Qwen3.5 122B (Local)" }
              }
            end,
          },
        },
      }
    end,
  },
}
