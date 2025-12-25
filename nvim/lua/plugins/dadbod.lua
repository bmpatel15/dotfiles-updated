-- vim-dadbod Complete Setup with UI and Completion
-- Place this file in: ~/.config/nvim/lua/plugins/dadbod.lua

return {
  {
    "tpope/vim-dadbod",
    lazy = true,
  },
  {
    "kristijanhusak/vim-dadbod-completion",
    dependencies = { "tpope/vim-dadbod" },
    ft = { "sql", "mysql", "plsql" },
    init = function()
      -- Enable completion in SQL files
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sql", "mysql", "plsql" },
        callback = function()
          local cmp = require("cmp")

          -- Add dadbod-completion source
          cmp.setup.buffer({
            sources = {
              { name = "vim-dadbod-completion" },
              { name = "buffer" },
              { name = "path" },
            },
          })
        end,
      })
    end,
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod" },
      { "kristijanhusak/vim-dadbod-completion" },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      -- UI Configuration
      vim.g.db_ui_use_nerd_fonts = 1           -- Use nerd font icons
      vim.g.db_ui_show_database_icon = 1       -- Show database icons
      vim.g.db_ui_force_echo_notifications = 1 -- Force notifications
      vim.g.db_ui_win_position = "left"        -- Open on left side
      vim.g.db_ui_winwidth = 40                -- Width of the sidebar

      -- Execution settings
      vim.g.db_ui_execute_on_save = 0 -- Don't auto-execute on save (manual control)
      vim.g.db_ui_use_nvim_notify = 1 -- Use nvim-notify if available

      -- Save location for connections and queries
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"

      -- Table helpers - show these in the UI
      vim.g.db_ui_show_help = 1
      vim.g.db_ui_auto_execute_table_helpers = 0 -- Don't auto-execute helpers

      -- Icons (customize if you want)
      vim.g.db_ui_icons = {
        expanded = {
          db = "▾ ",
          buffers = "▾ ",
          saved_queries = "▾ ",
          schemas = "▾ ",
          schema = "▾ פּ",
          tables = "▾ 藺",
          table = "▾ ",
        },
        collapsed = {
          db = "▸ ",
          buffers = "▸ ",
          saved_queries = "▸ ",
          schemas = "▸ ",
          schema = "▸ פּ",
          tables = "▸ 藺",
          table = "▸ ",
        },
        saved_query = "",
        new_query = "璘",
        tables = "離",
        buffers = "﬘",
        add_connection = "",
        connection_ok = "✓",
        connection_error = "✕",
      }
    end,
    keys = {
      -- Main toggles
      { "<leader>po", "<cmd>DBUIToggle<CR>",        desc = "Toggle DB UI" },
      { "<leader>pf", "<cmd>DBUIFindBuffer<CR>",    desc = "Find DB Buffer" },
      { "<leader>pa", "<cmd>DBUIAddConnection<CR>", desc = "Add DB Connection" },

      -- Quick actions (in DBUI buffer)
      { "<leader>pr", "<cmd>DBUIRename<CR>",        desc = "Rename Query",     ft = "sql" },
      { "<leader>pl", "<cmd>DBUILastQueryInfo<CR>", desc = "Last Query Info" },
    },
  },
  {
    -- Optional: Better SQL syntax highlighting
    "nanotee/sqls.nvim",
    ft = { "sql", "mysql", "plsql" },
    optional = true,
  },
}
