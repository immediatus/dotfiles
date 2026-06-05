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

        model = "q3",
        provider = "llama_local",
        providers = {
          copilot = { enabled = false },
          github_models = { enabled = false },
          llama_local = {
            get_url = function(_) return "127.0.0.1:8080/completion" end,
            get_headers = function() return { ["Content-Type"] = "application/json" } end,
            get_models = function() return { { id = "q3", name = "Qwen3" } } end,
            prepare_input = function(messages, _)
              local prompt = ""
              for _, msg in ipairs(messages) do
                local role = msg.role == "user" and "User: " or "Assistant: "
                prompt = prompt .. role .. msg.content .. "\n"
              end
              prompt = prompt .. "Assistant: "
              return {
                prompt = prompt,
                temperature = 0.7,
                n_predict = 4096,
                repeat_penalty = 1.1,
                stop = { "User:", "Assistant:" },
                stream = false,
              }
            end,

            prepare_output = function(data)
              local text = ""
              if type(data) == "table" and data.content then
                text = data.content
              elseif type(data) == "string" then
                local ok, decoded = pcall(vim.json.decode, data)
                if ok and decoded.content then text = decoded.content end
              end
              text = text:gsub("^%s*(.-)%s*$", "%1")
              return { content = text }
            end,
          },
        },
      }
    end,
  },
}
