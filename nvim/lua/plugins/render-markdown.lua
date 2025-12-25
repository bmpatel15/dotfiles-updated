return {
  "MeanderingProgrammer/render-markdown.nvim",
  enabled = true,
  ft = "markdown",   -- Only load for markdown files
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons"
  },
  config = function()
    -- ============================================
    -- BUFFER-LOCAL SETTINGS
    -- ============================================
    vim.opt_local.textwidth = 80
    vim.opt_local.spell = true
    vim.opt_local.linebreak = true

    -- ============================================
    -- HIGHLIGHT COLORS
    -- ============================================
    local color1_bg = "#ff757f"
    local color2_bg = "#4fd6be"
    local color3_bg = "#7dcfff"
    local color4_bg = "#ff9e64"
    local color5_bg = "#7aa2f7"
    local color6_bg = "#c0caf5"
    local color_fg = "#1F2335"

    local function set_markdown_highlights()
      -- Heading backgrounds for render-markdown
      vim.cmd(string.format([[highlight Headline1Bg guifg=%s guibg=%s gui=bold]], color_fg, color1_bg))
      vim.cmd(string.format([[highlight Headline2Bg guifg=%s guibg=%s gui=bold]], color_fg, color2_bg))
      vim.cmd(string.format([[highlight Headline3Bg guifg=%s guibg=%s gui=bold]], color_fg, color3_bg))
      vim.cmd(string.format([[highlight Headline4Bg guifg=%s guibg=%s gui=bold]], color_fg, color4_bg))
      vim.cmd(string.format([[highlight Headline5Bg guifg=%s guibg=%s gui=bold]], color_fg, color5_bg))
      vim.cmd(string.format([[highlight Headline6Bg guifg=%s guibg=%s gui=bold]], color_fg, color6_bg))

      -- Heading foregrounds (for icons)
      vim.cmd(string.format([[highlight Headline1Fg guifg=%s gui=bold]], "#ffffff"))
      vim.cmd(string.format([[highlight Headline2Fg guifg=%s gui=bold]], "#ffffff"))
      vim.cmd(string.format([[highlight Headline3Fg guifg=%s gui=bold]], "#ffffff"))
      vim.cmd(string.format([[highlight Headline4Fg guifg=%s gui=bold]], "#ffffff"))
      vim.cmd(string.format([[highlight Headline5Fg guifg=%s gui=bold]], "#ffffff"))
      vim.cmd(string.format([[highlight Headline6Fg guifg=%s gui=bold]], "#ffffff"))

      -- Treesitter heading highlights (backup for when render-markdown is toggled off)
      vim.cmd(string.format([[highlight @markup.heading.1.markdown cterm=bold gui=bold guifg=%s guibg=%s]], color_fg,
        color1_bg))
      vim.cmd(string.format([[highlight @markup.heading.2.markdown cterm=bold gui=bold guifg=%s guibg=%s]], color_fg,
        color2_bg))
      vim.cmd(string.format([[highlight @markup.heading.3.markdown cterm=bold gui=bold guifg=%s guibg=%s]], color_fg,
        color3_bg))
      vim.cmd(string.format([[highlight @markup.heading.4.markdown cterm=bold gui=bold guifg=%s guibg=%s]], color_fg,
        color4_bg))
      vim.cmd(string.format([[highlight @markup.heading.5.markdown cterm=bold gui=bold guifg=%s guibg=%s]], color_fg,
        color5_bg))
      vim.cmd(string.format([[highlight @markup.heading.6.markdown cterm=bold gui=bold guifg=%s guibg=%s]], color_fg,
        color6_bg))
    end

    -- Apply highlights immediately
    set_markdown_highlights()

    -- Reapply on colorscheme change
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "*",
      callback = set_markdown_highlights,
    })

    -- ============================================
    -- TOGGLE FUNCTIONS
    -- ============================================

    -- Toggle Line Numbers (Visual Selection)
    function ToggleNumberVisualSelection()
      local start_line = vim.fn.line("'<")
      local end_line = vim.fn.line("'>")
      local lines = vim.fn.getline(start_line, end_line)
      local has_numbers = false

      for i = 1, #lines do
        if lines[i]:match("^%s*%d+%.%s") then
          has_numbers = true
          break
        end
      end

      if has_numbers then
        for i = 1, #lines do
          lines[i] = lines[i]:gsub("^%s*%d+%.%s*", "")
        end
        print("✓ Numbers removed")
      else
        for i = 1, #lines do
          lines[i] = i .. ". " .. lines[i]
        end
        print("✓ Numbers added")
      end
      vim.fn.setline(start_line, lines)
    end

    -- Toggle Line Numbers for Current Line
    function ToggleNumberCurrentLine()
      local line_num = vim.fn.line(".")
      local line = vim.fn.getline(line_num)

      if line:match("^%s*%d+%.%s") then
        line = line:gsub("^%s*%d+%.%s*", "")
        print("✓ Number removed")
      else
        line = "1. " .. line
        print("✓ Number added")
      end
      vim.fn.setline(line_num, line)
    end

    -- Toggle Bullet Points (Visual Selection)
    function ToggleBulletVisualSelection()
      local start_line = vim.fn.line("'<")
      local end_line = vim.fn.line("'>")
      local lines = vim.fn.getline(start_line, end_line)
      local has_bullets = false

      for i = 1, #lines do
        if lines[i]:match("^%s*[%-%*%+]%s") then
          has_bullets = true
          break
        end
      end

      if has_bullets then
        for i = 1, #lines do
          lines[i] = lines[i]:gsub("^(%s*)[%-%*%+]%s*", "%1")
        end
        print("✓ Bullets removed")
      else
        for i = 1, #lines do
          if not lines[i]:match("^%s*[%-%*%+]%s") and not lines[i]:match("^%s*%d+%.%s") then
            lines[i] = "- " .. lines[i]
          end
        end
        print("✓ Bullets added")
      end
      vim.fn.setline(start_line, lines)
    end

    -- Toggle Bullet Points for Current Line
    function ToggleBulletCurrentLine()
      local line_num = vim.fn.line(".")
      local line = vim.fn.getline(line_num)

      if line:match("^%s*[%-%*%+]%s") then
        line = line:gsub("^(%s*)[%-%*%+]%s*", "%1")
        print("✓ Bullet removed")
      else
        if not line:match("^%s*%d+%.%s") then
          line = "- " .. line
          print("✓ Bullet added")
        end
      end
      vim.fn.setline(line_num, line)
    end

    -- Toggle Checkboxes (Visual Selection)
    function ToggleCheckboxVisualSelection()
      local start_line = vim.fn.line("'<")
      local end_line = vim.fn.line("'>")
      local lines = vim.fn.getline(start_line, end_line)
      local has_checkboxes = false

      for i = 1, #lines do
        if lines[i]:match("^%s*%-%s*%[.%]%s") then
          has_checkboxes = true
          break
        end
      end

      if has_checkboxes then
        for i = 1, #lines do
          lines[i] = lines[i]:gsub("^(%s*%-)%s*%[.%]%s*", "%1 ")
        end
        print("✓ Checkboxes removed")
      else
        for i = 1, #lines do
          if lines[i]:match("^%s*%-%s") then
            lines[i] = lines[i]:gsub("^(%s*%-)%s*", "%1 [ ] ")
          elseif not lines[i]:match("^%s*$") then
            lines[i] = "- [ ] " .. lines[i]
          end
        end
        print("✓ Checkboxes added")
      end
      vim.fn.setline(start_line, lines)
    end

    -- Toggle Checkboxes for Current Line
    function ToggleCheckboxCurrentLine()
      local line_num = vim.fn.line(".")
      local line = vim.fn.getline(line_num)

      if line:match("^%s*%-%s*%[.%]%s") then
        line = line:gsub("^(%s*%-)%s*%[.%]%s*", "%1 ")
        print("✓ Checkbox removed")
      else
        if line:match("^%s*%-%s") then
          line = line:gsub("^(%s*%-)%s*", "%1 [ ] ")
        elseif not line:match("^%s*$") then
          line = "- [ ] " .. line
        end
        print("✓ Checkbox added")
      end
      vim.fn.setline(line_num, line)
    end

    -- Toggle Task State (Visual Selection)
    function ToggleTaskStateVisualSelection()
      local start_line = vim.fn.line("'<")
      local end_line = vim.fn.line("'>")
      local lines = vim.fn.getline(start_line, end_line)
      local changed = 0

      for i = 1, #lines do
        if lines[i]:match("^%s*%-%s*%[ %]") then
          lines[i] = lines[i]:gsub("(%[) (])", "%1x%2")
          changed = changed + 1
        elseif lines[i]:match("^%s*%-%s*%[x%]") or lines[i]:match("^%s*%-%s*%[X%]") then
          lines[i] = lines[i]:gsub("(%[)[xX](])", "%1 %2")
          changed = changed + 1
        end
      end

      if changed > 0 then
        vim.fn.setline(start_line, lines)
        print("✓ " .. changed .. " tasks toggled")
      else
        print("○ No checkboxes found to toggle")
      end
    end

    -- Toggle Task State for Current Line
    function ToggleTaskStateCurrentLine()
      local line_num = vim.fn.line(".")
      local line = vim.fn.getline(line_num)

      if line:match("^%s*%-%s*%[ %]") then
        line = line:gsub("(%[) (])", "%1x%2")
        print("✓ Task completed")
      elseif line:match("^%s*%-%s*%[x%]") or line:match("^%s*%-%s*%[X%]") then
        line = line:gsub("(%[)[xX](])", "%1 %2")
        print("○ Task reopened")
      else
        print("○ No checkbox found to toggle")
      end
      vim.fn.setline(line_num, line)
    end

    -- Smart List Toggle (Visual Selection)
    function SmartListToggleVisualSelection()
      local start_line = vim.fn.line("'<")
      local end_line = vim.fn.line("'>")
      local lines = vim.fn.getline(start_line, end_line)
      local has_numbers, has_checkboxes, has_bullets = false, false, false

      for i = 1, #lines do
        if lines[i]:match("^%s*%d+%.%s") then
          has_numbers = true
        elseif lines[i]:match("^%s*%-%s*%[.%]%s") then
          has_checkboxes = true
        elseif lines[i]:match("^%s*[%-%*%+]%s") then
          has_bullets = true
        end
      end

      if has_numbers then
        for i = 1, #lines do
          lines[i] = lines[i]:gsub("^%s*%d+%.%s*", "")
        end
        print("✓ All formatting removed")
      elseif has_checkboxes then
        for i = 1, #lines do
          lines[i] = lines[i]:gsub("^(%s*)%-%s*%[.%]%s*", "%1")
          if not lines[i]:match("^%s*$") then
            lines[i] = i .. ". " .. lines[i]
          end
        end
        print("✓ Converted to numbered list")
      elseif has_bullets then
        for i = 1, #lines do
          lines[i] = lines[i]:gsub("^(%s*)[%-%*%+]%s*", "%1- [ ] ")
        end
        print("✓ Converted to checkboxes")
      else
        for i = 1, #lines do
          if not lines[i]:match("^%s*$") then
            lines[i] = "- " .. lines[i]
          end
        end
        print("✓ Added bullets")
      end
      vim.fn.setline(start_line, lines)
    end

    -- Smart List Toggle for Current Line
    function SmartListToggleCurrentLine()
      local line_num = vim.fn.line(".")
      local line = vim.fn.getline(line_num)

      if line:match("^%s*%d+%.%s") then
        line = line:gsub("^%s*%d+%.%s*", "")
        print("✓ All formatting removed")
      elseif line:match("^%s*%-%s*%[.%]%s") then
        line = line:gsub("^(%s*)%-%s*%[.%]%s*", "%1")
        if not line:match("^%s*$") then
          line = "1. " .. line
        end
        print("✓ Converted to numbered list")
      elseif line:match("^%s*[%-%*%+]%s") then
        line = line:gsub("^(%s*)[%-%*%+]%s*", "%1- [ ] ")
        print("✓ Converted to checkbox")
      else
        if not line:match("^%s*$") then
          line = "- " .. line
          print("✓ Added bullet")
        end
      end
      vim.fn.setline(line_num, line)
    end

    -- Toggle Heading Function
    local function toggle_heading(level)
      local line = vim.api.nvim_get_current_line()
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local content = line:gsub("^#+%s*", "")
      local current_level = line:match("^(#+)")

      if current_level and #current_level == level then
        vim.api.nvim_set_current_line(content)
        vim.api.nvim_win_set_cursor(0, { cursor_pos[1], math.max(0, cursor_pos[2] - level - 1) })
      else
        local new_line = string.rep("#", level) .. " " .. content
        vim.api.nvim_set_current_line(new_line)
        vim.api.nvim_win_set_cursor(0, { cursor_pos[1], cursor_pos[2] + level + 1 })
      end
    end

    -- ============================================
    -- COMMANDS
    -- ============================================
    vim.api.nvim_create_user_command("ToggleNumberVisual", ToggleNumberVisualSelection, {})
    vim.api.nvim_create_user_command("ToggleBulletVisual", ToggleBulletVisualSelection, {})
    vim.api.nvim_create_user_command("ToggleCheckboxVisual", ToggleCheckboxVisualSelection, {})
    vim.api.nvim_create_user_command("ToggleTaskStateVisual", ToggleTaskStateVisualSelection, {})
    vim.api.nvim_create_user_command("SmartListToggleVisual", SmartListToggleVisualSelection, {})

    -- ============================================
    -- KEYMAPS
    -- ============================================
    local opts = { buffer = true, silent = true }

    -- Visual mode keymaps
    vim.keymap.set("v", "tn", ":<C-u>ToggleNumberVisual<CR>", vim.tbl_extend("force", opts, { desc = "Toggle numbers" }))
    vim.keymap.set("v", "tb", ":<C-u>ToggleBulletVisual<CR>", vim.tbl_extend("force", opts, { desc = "Toggle bullets" }))
    vim.keymap.set("v", "tc", ":<C-u>ToggleCheckboxVisual<CR>",
      vim.tbl_extend("force", opts, { desc = "Toggle checkboxes" }))
    vim.keymap.set("v", "tt", ":<C-u>ToggleTaskStateVisual<CR>",
      vim.tbl_extend("force", opts, { desc = "Toggle task state" }))
    vim.keymap.set("v", "tl", ":<C-u>SmartListToggleVisual<CR>",
      vim.tbl_extend("force", opts, { desc = "Smart list toggle" }))

    -- Normal mode keymaps
    vim.keymap.set("n", "tn", ToggleNumberCurrentLine, vim.tbl_extend("force", opts, { desc = "Toggle numbers" }))
    vim.keymap.set("n", "tb", ToggleBulletCurrentLine, vim.tbl_extend("force", opts, { desc = "Toggle bullets" }))
    vim.keymap.set("n", "tc", ToggleCheckboxCurrentLine, vim.tbl_extend("force", opts, { desc = "Toggle checkboxes" }))
    vim.keymap.set("n", "tt", ToggleTaskStateCurrentLine, vim.tbl_extend("force", opts, { desc = "Toggle task state" }))
    vim.keymap.set("n", "tl", SmartListToggleCurrentLine, vim.tbl_extend("force", opts, { desc = "Smart list toggle" }))

    -- Task management keymaps
    local function safe_markdown_cmd(cmd, success_msg)
      return function()
        vim.cmd("normal! t'")
        local ok, err = pcall(vim.cmd, cmd)
        if ok then
          print("✓ " .. success_msg)
        else
          print("✗ Failed: " .. err)
          vim.cmd("undo")
        end
      end
    end

    vim.keymap.set("n", "<leader>tc", safe_markdown_cmd("g/- \\[ \\]/s/\\[ \\]/[x]/", "Marked all tasks as done"),
      vim.tbl_extend("force", opts, { desc = "Mark all tasks done" }))
    vim.keymap.set("n", "<leader>tu", safe_markdown_cmd("g/- \\[x\\]/s/\\[x\\]/[ ]/", "Marked all tasks as undone"),
      vim.tbl_extend("force", opts, { desc = "Mark all tasks undone" }))

    -- Heading keymaps
    vim.keymap.set("n", "<leader>h1", function() toggle_heading(1) end,
      vim.tbl_extend("force", opts, { desc = "Toggle H1" }))
    vim.keymap.set("n", "<leader>h2", function() toggle_heading(2) end,
      vim.tbl_extend("force", opts, { desc = "Toggle H2" }))
    vim.keymap.set("n", "<leader>h3", function() toggle_heading(3) end,
      vim.tbl_extend("force", opts, { desc = "Toggle H3" }))
    vim.keymap.set("n", "<leader>h4", function() toggle_heading(4) end,
      vim.tbl_extend("force", opts, { desc = "Toggle H4" }))
    vim.keymap.set("n", "<leader>h5", function() toggle_heading(5) end,
      vim.tbl_extend("force", opts, { desc = "Toggle H5" }))
    vim.keymap.set("n", "<leader>h6", function() toggle_heading(6) end,
      vim.tbl_extend("force", opts, { desc = "Toggle H6" }))

    -- ============================================
    -- RENDER-MARKDOWN SETUP
    -- ============================================
    require("render-markdown").setup({
      heading = {
        sign = false,
        icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
        backgrounds = {
          "Headline1Bg", "Headline2Bg", "Headline3Bg",
          "Headline4Bg", "Headline5Bg", "Headline6Bg",
        },
        foregrounds = {
          "Headline1Fg", "Headline2Fg", "Headline3Fg",
          "Headline4Fg", "Headline5Fg", "Headline6Fg",
        },
      },
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
      },
      bullet = {
        enabled = true,
      },
      checkbox = {
        enabled = true,
        position = "inline",
        unchecked = {
          icon = "   󰄱 ",
          highlight = "RenderMarkdownUnchecked",
          scope_highlight = nil,
        },
        checked = {
          icon = "   󰱒 ",
          highlight = "RenderMarkdownChecked",
          scope_highlight = nil,
        },
      },
    })
  end,
}
