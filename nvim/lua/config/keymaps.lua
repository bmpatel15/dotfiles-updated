-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

vim.keymap.set({ "n", "v", "i" }, "<M-q>", "<cmd>q!<cr>", { desc = "[P]Quit All" })
vim.keymap.set({ "i", "v", "c" }, "jk", "<Esc>", { desc = "Exit to normal mode" })

-- ############################################################################
--                         Task Management Section
-- ############################################################################

-- List incomplete tasks with Telescope
vim.keymap.set("n", "<leader>tt", function()
  require("telescope.builtin").grep_string(require("telescope.themes").get_ivy({
    prompt_title = "Incomplete Tasks",
    search = "^\\s*- \\[ \\]",
    search_dirs = { vim.fn.getcwd() },
    use_regex = true,
    initial_mode = "insert", -- Changed to insert mode
    layout_config = {
      preview_width = 0.5,
    },
    additional_args = function()
      return { "--no-ignore" }
    end,
  }))
end, { desc = "[P]Search for incomplete tasks" })

-- List completed tasks with Telescope
vim.keymap.set("n", "<leader>tc", function()
  require("telescope.builtin").grep_string(require("telescope.themes").get_ivy({
    prompt_title = "Completed Tasks",
    search = "^\\s*- \\[x\\] `done:",
    search_dirs = { vim.fn.getcwd() },
    use_regex = true,
    initial_mode = "insert", -- Changed to insert mode
    layout_config = {
      preview_width = 0.5,
    },
    additional_args = function()
      return { "--no-ignore" }
    end,
  }))
end, { desc = "[P]Search for completed tasks" })

-- Create task or checkbox
-- Converts bullets to tasks or inserts new task bullet
vim.keymap.set({ "n", "i" }, "<M-l>", function()
  -- Get the current line/row/column
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row, _ = cursor_pos[1], cursor_pos[2]
  local line = vim.api.nvim_get_current_line()
  -- 1) If line is empty => replace it with "- [ ] " and set cursor after the brackets
  if line:match("^%s*$") then
    local final_line = "- [ ] "
    vim.api.nvim_set_current_line(final_line)
    -- "- [ ] " is 6 characters, so cursor col = 6 places you *after* that space
    vim.api.nvim_win_set_cursor(0, { row, 6 })
    return
  end
  -- 2) Check if line already has a bullet with possible indentation: e.g. "  - Something"
  --    We'll capture "  -" (including trailing spaces) as `bullet` plus the rest as `text`.
  local bullet, text = line:match("^([%s]*[-*]%s+)(.*)$")
  if bullet then
    -- Convert bullet => bullet .. "[ ] " .. text
    local final_line = bullet .. "[ ] " .. text
    vim.api.nvim_set_current_line(final_line)
    -- Place the cursor right after "[ ] "
    local bullet_len = #bullet
    vim.api.nvim_win_set_cursor(0, { row, bullet_len + 4 })
    return
  end
  -- 3) If there's text, but no bullet => prepend "- [ ] "
  --    and place cursor after the brackets
  local final_line = "- [ ] " .. line
  vim.api.nvim_set_current_line(final_line)
  -- "- [ ] " is 6 characters
  vim.api.nvim_win_set_cursor(0, { row, 6 })
end, { desc = "Convert bullet to a task or insert new task bullet" })
-- Toggle task and move to completed section
vim.keymap.set("n", "<M-x>", function()
  -- Customizable variables
  local label_done = "done:"
  local timestamp = os.date("%y%m%d-%H%M")
  local tasks_heading = "## Completed tasks"

  -- Save the view to preserve folds
  vim.cmd("mkview")
  local api = vim.api

  -- Retrieve buffer & lines
  local buf = api.nvim_get_current_buf()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local start_line = cursor_pos[1] - 1
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local total_lines = #lines

  -- If cursor is beyond last line, do nothing
  if start_line >= total_lines then
    vim.cmd("loadview")
    return
  end

  -- Move upwards to find the bullet line
  while start_line > 0 do
    local line_text = lines[start_line + 1]
    if line_text == "" or line_text:match("^%s*%-") then
      break
    end
    start_line = start_line - 1
  end

  if lines[start_line + 1] == "" and start_line < (total_lines - 1) then
    start_line = start_line + 1
  end

  -- Validate that it's a task bullet
  local bullet_line = lines[start_line + 1]
  if not bullet_line:match("^%s*%- %[[x ]%]") then
    print("Not a task bullet: no action taken.")
    vim.cmd("loadview")
    return
  end

  -- Identify chunk boundaries
  local chunk_start = start_line
  local chunk_end = start_line
  while chunk_end + 1 < total_lines do
    local next_line = lines[chunk_end + 2]
    if next_line == "" or next_line:match("^%s*%-") then
      break
    end
    chunk_end = chunk_end + 1
  end

  -- Collect the chunk lines
  local chunk = {}
  for i = chunk_start, chunk_end do
    table.insert(chunk, lines[i + 1])
  end

  -- Check if chunk has done or untoggled labels
  local has_done_index = nil
  local has_untoggled_index = nil
  for i, line in ipairs(chunk) do
    chunk[i] = line:gsub("%[done:([^%]]+)%]", "`" .. label_done .. "%1`")
    chunk[i] = chunk[i]:gsub("%[untoggled%]", "`untoggled`")
    if chunk[i]:match("`" .. label_done .. ".-`") then
      has_done_index = i
      break
    end
  end
  if not has_done_index then
    for i, line in ipairs(chunk) do
      if line:match("`untoggled`") then
        has_untoggled_index = i
        break
      end
    end
  end

  -- Helper functions
  local function bulletToX(line)
    return line:gsub("^(%s*%- )%[%s*%]", "%1[x]")
  end

  local function bulletToBlank(line)
    return line:gsub("^(%s*%- )%[x%]", "%1[ ]")
  end

  local function insertLabelAfterBracket(line, label)
    local prefix = line:match("^(%s*%- %[[x ]%])")
    if not prefix then
      return line
    end
    local rest = line:sub(#prefix + 1)
    return prefix .. " " .. label .. rest
  end

  local function removeLabel(line)
    return line:gsub("^(%s*%- %[[x ]%])%s+`.-`", "%1")
  end

  local function updateBufferWithChunk(new_chunk)
    for idx = chunk_start, chunk_end do
      lines[idx + 1] = new_chunk[idx - chunk_start + 1]
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  end

  -- Main toggle logic
  if has_done_index then
    chunk[has_done_index] = removeLabel(chunk[has_done_index]):gsub("`" .. label_done .. ".-`", "`untoggled`")
    chunk[1] = bulletToBlank(chunk[1])
    chunk[1] = removeLabel(chunk[1])
    chunk[1] = insertLabelAfterBracket(chunk[1], "`untoggled`")
    updateBufferWithChunk(chunk)
    vim.notify("Untoggled", vim.log.levels.INFO)
  elseif has_untoggled_index then
    chunk[has_untoggled_index] =
        removeLabel(chunk[has_untoggled_index]):gsub("`untoggled`", "`" .. label_done .. " " .. timestamp .. "`")
    chunk[1] = bulletToX(chunk[1])
    chunk[1] = removeLabel(chunk[1])
    chunk[1] = insertLabelAfterBracket(chunk[1], "`" .. label_done .. " " .. timestamp .. "`")
    updateBufferWithChunk(chunk)
    vim.notify("Completed", vim.log.levels.INFO)
  else
    -- Save original window view before modifications
    local win = api.nvim_get_current_win()
    local view = api.nvim_win_call(win, function()
      return vim.fn.winsaveview()
    end)

    chunk[1] = bulletToX(chunk[1])
    chunk[1] = insertLabelAfterBracket(chunk[1], "`" .. label_done .. " " .. timestamp .. "`")

    -- Remove chunk from original lines
    for i = chunk_end, chunk_start, -1 do
      table.remove(lines, i + 1)
    end

    -- Find or create the Completed tasks heading
    local heading_index = nil
    for i, line in ipairs(lines) do
      -- More robust pattern matching - trim whitespace
      if line:match("^%s*" .. tasks_heading:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1") .. "%s*$") then
        heading_index = i
        break
      end
    end

    if heading_index then
      -- Insert tasks right after the heading
      for j = #chunk, 1, -1 do
        table.insert(lines, heading_index + 1, chunk[j])
      end
    else
      -- Create new heading at end of file
      -- Remove trailing blank lines first
      while #lines > 0 and lines[#lines] == "" do
        table.remove(lines)
      end

      -- Add blank line, heading, and tasks
      table.insert(lines, "")
      table.insert(lines, tasks_heading)
      for _, cLine in ipairs(chunk) do
        table.insert(lines, cLine)
      end
    end

    -- Update buffer content
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.notify("Completed", vim.log.levels.INFO)

    -- Restore window view to preserve scroll position
    api.nvim_win_call(win, function()
      vim.fn.winrestview(view)
    end)
  end

  -- Write changes and restore view to preserve folds
  vim.cmd("silent update")
  vim.cmd("loadview")
end, { desc = "[P]Toggle task and move it to 'done'" })

-- ============================================================================
-- NOTES MANAGEMENT - PARA METHOD (using <leader>z)
-- ============================================================================

local notes_dir = vim.fn.expand("~/notes/")
local templates_dir = notes_dir .. "_Meta/"

-- ============================================================================
-- HELPER FUNCTION: Load and process templates
-- ============================================================================

local function load_template(template_name, replacements)
  local template_path = templates_dir .. template_name

  -- Check if template exists
  if vim.fn.filereadable(template_path) == 0 then
    vim.notify("Template not found: " .. template_path, vim.log.levels.ERROR)
    return nil
  end

  -- Read template file
  local file = io.open(template_path, "r")
  if not file then
    vim.notify("Could not read template: " .. template_path, vim.log.levels.ERROR)
    return nil
  end

  local content = file:read("*all")
  file:close()

  -- Replace placeholders
  if replacements then
    for key, value in pairs(replacements) do
      content = content:gsub("{{" .. key .. "}}", value)
    end
  end

  -- Split into lines for buffer insertion
  local lines = {}
  for line in content:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  -- Handle empty last line
  if content:sub(-1) == "\n" then
    table.insert(lines, "")
  end

  return lines
end

-- ============================================================================
-- 1. DAILY NOTE CREATION & TEMPLATES
-- ============================================================================

-- Open or create today's daily note
vim.keymap.set("n", "<leader>zd", function()
  local year = os.date("%Y")
  local month = os.date("%m-%B")
  local note_name = os.date("%Y-%m-%d-%A") .. ".md"
  local note_dir = notes_dir .. "daily/" .. year .. "/" .. month .. "/"
  local note_path = note_dir .. note_name

  -- Create directory if it doesn't exist
  vim.fn.mkdir(note_dir, "p")

  -- Open the file
  vim.cmd("edit " .. note_path)

  -- If file is empty, insert template
  if vim.fn.line('$') == 1 and vim.fn.getline(1) == '' then
    -- Calculate yesterday and tomorrow
    local yesterday = os.time() - (24 * 60 * 60)
    local tomorrow = os.time() + (24 * 60 * 60)

    local replacements = {
      date = os.date("%Y-%m-%d"),
      day = os.date("%A"),
      yesterday = os.date("%Y-%m-%d-%A", yesterday),
      tomorrow = os.date("%Y-%m-%d-%A", tomorrow),
      timestamp = os.date("%Y-%m-%d %H:%M"),
    }

    local template = load_template("daily-note.md", replacements)
    if template then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
    end
  end
end, { desc = "[Z]ettel: Open today's [D]aily note" })

-- Open yesterday's daily note
vim.keymap.set("n", "<leader>zy", function()
  local yesterday = os.time() - (24 * 60 * 60)
  local year = os.date("%Y", yesterday)
  local month = os.date("%m-%B", yesterday)
  local note_name = os.date("%Y-%m-%d-%A", yesterday) .. ".md"
  local note_path = notes_dir .. "daily/" .. year .. "/" .. month .. "/" .. note_name

  if vim.fn.filereadable(note_path) == 1 then
    vim.cmd("edit " .. note_path)
  else
    vim.notify("Yesterday's note doesn't exist", vim.log.levels.WARN)
  end
end, { desc = "[Z]ettel: Open [Y]esterday's note" })

-- Open tomorrow's daily note (for planning)
vim.keymap.set("n", "<leader>zm", function()
  local tomorrow = os.time() + (24 * 60 * 60)
  local year = os.date("%Y", tomorrow)
  local month = os.date("%m-%B", tomorrow)
  local note_name = os.date("%Y-%m-%d-%A", tomorrow) .. ".md"
  local note_dir = notes_dir .. "daily/" .. year .. "/" .. month .. "/"
  local note_path = note_dir .. note_name

  vim.fn.mkdir(note_dir, "p")
  vim.cmd("edit " .. note_path)

  if vim.fn.line('$') == 1 and vim.fn.getline(1) == '' then
    local day_after = os.time() + (2 * 24 * 60 * 60)

    local replacements = {
      date = os.date("%Y-%m-%d", tomorrow),
      day = os.date("%A", tomorrow),
      yesterday = os.date("%Y-%m-%d-%A"), -- today
      tomorrow = os.date("%Y-%m-%d-%A", day_after),
      timestamp = os.date("%Y-%m-%d %H:%M"),
    }

    local template = load_template("daily-note.md", replacements)
    if template then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
    end
  end
end, { desc = "[Z]ettel: To[m]orrow's note (planning)" })

-- Create physical notes transcript
vim.keymap.set("n", "<leader>zp", function()
  local date = os.date("%Y-%m-%d")
  local transcript_dir = notes_dir .. "Inbox/physical-transcripts/"
  local transcript_name = "physical-" .. date .. ".md"
  local transcript_path = transcript_dir .. transcript_name

  vim.fn.mkdir(transcript_dir, "p")
  vim.cmd("edit " .. transcript_path)

  if vim.fn.line('$') == 1 and vim.fn.getline(1) == '' then
    local replacements = {
      date = date,
    }

    local template = load_template("transcript.md", replacements)
    if template then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
      -- Jump to the heading line (adjust as needed)
      vim.api.nvim_win_set_cursor(0, { 6, 3 })
    end
  end
end, { desc = "[Z]ettel: [P]hysical transcript" })

-- Create new project note
vim.keymap.set("n", "<leader>zP", function()
  vim.ui.input({ prompt = "Project name: " }, function(project_name)
    if not project_name or project_name == "" then return end

    -- Create filename from project name
    local filename = project_name:lower():gsub("%s+", "-"):gsub("[^%w-]", "") .. ".md"
    local project_path = notes_dir .. "Projects/" .. filename

    vim.cmd("edit " .. project_path)

    if vim.fn.line('$') == 1 and vim.fn.getline(1) == '' then
      local replacements = {
        project_name = project_name,
        date = os.date("%Y-%m-%d"),
        timestamp = os.date("%Y-%m-%d %H:%M"),
      }

      local template = load_template("project.md", replacements)
      if template then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
      end
    end
  end)
end, { desc = "[Z]ettel: New [P]roject" })

-- Create new area note
vim.keymap.set("n", "<leader>zA", function()
  vim.ui.input({ prompt = "Area name: " }, function(area_name)
    if not area_name or area_name == "" then return end

    local filename = area_name:lower():gsub("%s+", "-"):gsub("[^%w-]", "") .. ".md"
    local area_path = notes_dir .. "Areas/" .. filename

    vim.cmd("edit " .. area_path)

    if vim.fn.line('$') == 1 and vim.fn.getline(1) == '' then
      local replacements = {
        area_name = area_name,
        date = os.date("%Y-%m-%d"),
        timestamp = os.date("%Y-%m-%d %H:%M"),
      }

      local template = load_template("area.md", replacements)
      if template then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
      end
    end
  end)
end, { desc = "[Z]ettel: New [A]rea" })

-- Create new resource note
vim.keymap.set("n", "<leader>zR", function()
  vim.ui.input({ prompt = "Resource name: " }, function(resource_name)
    if not resource_name or resource_name == "" then return end

    local filename = resource_name:lower():gsub("%s+", "-"):gsub("[^%w-]", "") .. ".md"
    local resource_path = notes_dir .. "Resources/" .. filename

    vim.cmd("edit " .. resource_path)

    if vim.fn.line('$') == 1 and vim.fn.getline(1) == '' then
      local replacements = {
        resource_name = resource_name,
        date = os.date("%Y-%m-%d"),
        timestamp = os.date("%Y-%m-%d %H:%M"),
      }

      local template = load_template("resource.md", replacements)
      if template then
        vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
      end
    end
  end)
end, { desc = "[Z]ettel: New [R]esource" })

-- ============================================================================
-- 2. SEARCHING THROUGH LINKED NOTES
-- ============================================================================

-- Find BACKLINKS (what links TO current note)
vim.keymap.set("n", "<leader>zb", function()
  local filename = vim.fn.expand("%:t:r")
  if filename == "" then
    vim.notify("Not in a named file", vim.log.levels.WARN)
    return
  end

  require("telescope.builtin").live_grep({
    prompt_title = "← Backlinks to: " .. filename,
    default_text = "\\[\\[" .. filename,
    cwd = notes_dir,
  })
end, { desc = "[Z]ettel: [B]acklinks (what links here)" })

-- Find FORWARD LINKS (what THIS note links to)
vim.keymap.set("n", "<leader>zf", function()
  require("telescope.builtin").current_buffer_fuzzy_find({
    prompt_title = "→ Links in current note",
    default_text = "\\[\\[",
  })
end, { desc = "[Z]ettel: [F]orward links (in this note)" })

-- Search ALL notes by content (live grep)
vim.keymap.set("n", "<leader>zs", function()
  require("telescope.builtin").live_grep({
    prompt_title = "Search Notes Content",
    cwd = notes_dir,
  })
end, { desc = "[Z]ettel: [S]earch content" })

-- Open note by filename (fuzzy find)
vim.keymap.set("n", "<leader>zo", function()
  require("telescope.builtin").find_files({
    prompt_title = "Open Note",
    cwd = notes_dir,
    hidden = false,
    find_command = { "rg", "--files", "--glob", "*.md" },
  })
end, { desc = "[Z]ettel: [O]pen note by name" })

-- Search by TAG
vim.keymap.set("n", "<leader>zt", function()
  require("telescope.builtin").live_grep({
    prompt_title = "Find by Tag",
    default_text = "#",
    cwd = notes_dir,
  })
end, { desc = "[Z]ettel: Search [T]ags" })

-- Recent notes (modified recently)
vim.keymap.set("n", "<leader>zr", function()
  require("telescope.builtin").find_files({
    prompt_title = "Recent Notes",
    cwd = notes_dir,
    find_command = {
      "fd",
      "--type", "f",
      "--extension", "md",
      "--exec-batch", "ls", "-t"
    },
  })
end, { desc = "[Z]ettel: Recent files" })

-- Search in specific PARA sections
vim.keymap.set("n", "<leader>z1", function()
  require("telescope.builtin").find_files({
    prompt_title = "Projects",
    cwd = notes_dir .. "Projects/",
  })
end, { desc = "[Z]ettel: Browse [1] Projects" })

vim.keymap.set("n", "<leader>z2", function()
  require("telescope.builtin").find_files({
    prompt_title = "Areas",
    cwd = notes_dir .. "Areas/",
  })
end, { desc = "[Z]ettel: Browse [2] Areas" })

vim.keymap.set("n", "<leader>z3", function()
  require("telescope.builtin").find_files({
    prompt_title = "Resources",
    cwd = notes_dir .. "Resources/",
  })
end, { desc = "[Z]ettel: Browse [3] Resources" })

vim.keymap.set("n", "<leader>z0", function()
  require("telescope.builtin").find_files({
    prompt_title = "Inbox",
    cwd = notes_dir .. "Inbox/",
  })
end, { desc = "[Z]ettel: Browse [0] Inbox" })

-- Search within Vachanamrut/Spiritual notes specifically
vim.keymap.set("n", "<leader>zv", function()
  require("telescope.builtin").live_grep({
    prompt_title = "Search Vachanamrut Notes",
    cwd = notes_dir .. "Resources/Vachanamrut/",
  })
end, { desc = "[Z]ettel: Search [V]achanamrut" })

-- ============================================================================
-- 3. MARKSMAN LSP - HEADING NAVIGATION
-- ============================================================================

-- Jump to heading in current file (Telescope symbols)
vim.keymap.set("n", "<leader>zh", function()
  require("telescope.builtin").lsp_document_symbols({
    prompt_title = "Jump to Heading",
    symbols = { "heading" },
  })
end, { desc = "[Z]ettel: Jump to [H]eading" })

-- Jump to heading across ALL notes (workspace symbols)
vim.keymap.set("n", "<leader>zH", function()
  require("telescope.builtin").lsp_dynamic_workspace_symbols({
    prompt_title = "Find Heading in All Notes",
    symbols = { "heading" },
  })
end, { desc = "[Z]ettel: Find heading in all notes" })

-- Marksman: Go to definition (follow link)
vim.keymap.set("n", "<leader>zl", function()
  vim.lsp.buf.definition()
end, { desc = "[Z]ettel: Follow [L]ink (gd also works)" })

-- Marksman: Find references (where is this note referenced)
vim.keymap.set("n", "<leader>zR", function()
  require("telescope.builtin").lsp_references({
    prompt_title = "References to Current Note",
  })
end, { desc = "[Z]ettel: Find [R]eferences (Marksman)" })

-- Marksman: Rename note (updates all links)
vim.keymap.set("n", "<leader>zN", function()
  vim.lsp.buf.rename()
end, { desc = "[Z]ettel: Re[N]ame note (updates links)" })

-- ============================================================================
-- 4. MARKSMAN LSP MANAGEMENT
-- ============================================================================

-- Restart Marksman LSP
vim.keymap.set("n", "<leader>zL", function()
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "marksman" })

  if #clients == 0 then
    vim.notify("No Marksman LSP client found", vim.log.levels.WARN)
    return
  end

  for _, client in ipairs(clients) do
    vim.lsp.stop_client(client.id)
  end

  vim.notify("Marksman LSP stopped. Will restart on next markdown file.", vim.log.levels.INFO)

  vim.schedule(function()
    vim.cmd("edit!")
  end)
end, { desc = "[Z]ettel: Restart Marksman [L]SP" })

-- Show Marksman LSP info
vim.keymap.set("n", "<leader>zI", function()
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "marksman" })

  if #clients == 0 then
    vim.notify("Marksman LSP is not running", vim.log.levels.WARN)
  else
    local info = {}
    for _, client in ipairs(clients) do
      table.insert(info, string.format(
        "Marksman LSP (ID: %d)\nRoot: %s\nStatus: Running",
        client.id,
        client.config.root_dir or "unknown"
      ))
    end
    vim.notify(table.concat(info, "\n\n"), vim.log.levels.INFO)
  end
end, { desc = "[Z]ettel: Marksman LSP [I]nfo" })

-- ============================================================================
-- ADDITIONAL HELPFUL KEYMAPS
-- ============================================================================

-- Create new note from visual selection
vim.keymap.set("v", "<leader>zn", function()
  vim.cmd('noau normal! "vy"')
  local text = vim.fn.getreg('v')

  local filename = text:lower():gsub("%s+", "-"):gsub("[^%w-]", "")
  local note_path = notes_dir .. "Resources/" .. filename .. ".md"

  vim.cmd("edit " .. note_path)

  if vim.fn.line('$') == 1 and vim.fn.getline(1) == '' then
    local replacements = {
      resource_name = text,
      date = os.date("%Y-%m-%d"),
      timestamp = os.date("%Y-%m-%d %H:%M"),
    }

    local template = load_template("resource.md", replacements)
    if template then
      vim.api.nvim_buf_set_lines(0, 0, -1, false, template)
    end
  end

  vim.cmd("wincmd p")
  vim.api.nvim_feedkeys("c[[" .. filename .. "]]", "n", false)
end, { desc = "[Z]ettel: [N]ew note from selection" })

vim.keymap.set("i", "<C-t>", function()
  return os.date("%Y-%m-%d %H:%M")
end, { expr = true, desc = "Insert timestamp" })

-- Quick link to today's daily note
vim.keymap.set("i", "<C-d>", function()
  return "[[" .. os.date("%Y-%m-%d-%A") .. "]]"
end, { expr = true, desc = "Insert link to today" })

-- Navigate to next/previous heading
vim.keymap.set("n", "]]", function()
  vim.fn.search("^##\\+", "W")
end, { desc = "Next heading" })

vim.keymap.set("n", "[[", function()
  vim.fn.search("^##\\+", "bW")
end, { desc = "Previous heading" })

-- Quick access to notes directory in file explorer
vim.keymap.set("n", "<leader>ze", function()
  vim.cmd("edit " .. notes_dir)
end, { desc = "[Z]ettel: Open notes in [E]xplorer" })

-- ============================================================================
-- VACHANAMRUT INDEX NAVIGATION (Header-based)
-- ============================================================================

-- Navigate Vachanamrut TOC by headers and show linked notes
vim.keymap.set("n", "<leader>zii", function()
  local notes_dir = vim.fn.expand("~/notes/")
  local toc_file = notes_dir .. "Resources/Vachanamrut/vachanamrut-toc.md"

  -- Check if TOC exists
  if vim.fn.filereadable(toc_file) == 0 then
    vim.notify("Vachanamrut TOC not found at: " .. toc_file, vim.log.levels.ERROR)
    return
  end

  -- Read TOC file and extract all headers with their content
  local file = io.open(toc_file, "r")
  if not file then
    vim.notify("Could not open TOC file", vim.log.levels.ERROR)
    return
  end

  local content = file:read("*all")
  file:close()

  -- Parse headers and their wiki-links
  local topics = {}
  local current_h2 = nil
  local current_h3 = nil

  for line in content:gmatch("[^\r\n]+") do
    -- Match ## Header (H2)
    local h2 = line:match("^##%s+(.+)$")
    if h2 and not line:match("^###") then
      current_h2 = {
        heading = h2,
        level = 2,
        links = {},
        display = "## " .. h2
      }
      table.insert(topics, current_h2)
      current_h3 = nil
    end

    -- Match ### Header (H3)
    local h3 = line:match("^###%s+(.+)$")
    if h3 then
      current_h3 = {
        heading = h3,
        level = 3,
        links = {},
        display = "### " .. h3
      }
      table.insert(topics, current_h3)
    end

    -- Match wiki-links under current header
    local link = line:match("%[%[([^%]]+)%]%]")
    if link then
      -- Add to most specific header (H3 if exists, otherwise H2)
      if current_h3 then
        table.insert(current_h3.links, link)
      elseif current_h2 then
        table.insert(current_h2.links, link)
      end
    end
  end

  if #topics == 0 then
    vim.notify("No topics found in TOC", vim.log.levels.WARN)
    return
  end

  -- Create Telescope picker for headers
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Vachanamrut Topics",
    finder = finders.new_table({
      results = topics,
      entry_maker = function(entry)
        -- Show number of linked notes
        local link_count = #entry.links > 0 and " (" .. #entry.links .. " notes)" or ""
        return {
          value = entry,
          display = entry.display .. link_count,
          ordinal = entry.heading,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local topic = selection.value

        -- If header has links, show them in Telescope
        if #topic.links > 0 then
          local link_pickers = require("telescope.pickers")
          local link_finders = require("telescope.finders")

          link_pickers.new({}, {
            prompt_title = "Notes under: " .. topic.heading,
            finder = link_finders.new_table({
              results = topic.links,
              entry_maker = function(link)
                return {
                  value = link,
                  display = link,
                  ordinal = link,
                }
              end,
            }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(link_bufnr, link_map)
              actions.select_default:replace(function()
                local link_selection = action_state.get_selected_entry()
                actions.close(link_bufnr)

                -- Open the linked note
                local note_file = notes_dir .. "Resources/Vachanamrut/" .. link_selection.value .. ".md"
                vim.cmd("edit " .. note_file)
              end)
              return true
            end,
          }):find()
        else
          vim.notify("No notes linked under: " .. topic.heading, vim.log.levels.INFO)
        end
      end)

      -- Alt+e to edit the TOC file at this heading
      map("i", "<M-e>", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        -- Open TOC and search for the heading
        vim.cmd("edit " .. toc_file)
        vim.fn.search(vim.pesc(selection.value.heading))
      end)

      return true
    end,
  }):find()
end, { desc = "[Z]ettel: Vachanamrut [I]ndex navigation" })

-- ============================================================================
-- ADD CURRENT NOTE TO VACHANAMRUT INDEX (with bullet points)
-- ============================================================================

-- Helper function to add note to TOC with smart indentation
local function add_to_vachanamrut_toc(header_level)
  local notes_dir = vim.fn.expand("~/notes/")
  local toc_file = notes_dir .. "Resources/Vachanamrut/vachanamrut-toc.md"

  -- Get current file name without extension
  local current_file = vim.fn.expand("%:t:r")
  if current_file == "" then
    vim.notify("Not in a named file", vim.log.levels.WARN)
    return
  end

  -- Check if TOC exists
  if vim.fn.filereadable(toc_file) == 0 then
    vim.notify("Vachanamrut TOC not found", vim.log.levels.ERROR)
    return
  end

  -- Read TOC file
  local file = io.open(toc_file, "r")
  if not file then
    vim.notify("Could not read TOC file", vim.log.levels.ERROR)
    return
  end

  local content = file:read("*all")
  file:close()

  local lines = {}
  for line in content:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  -- Add empty line at end if not present
  if #lines > 0 and lines[#lines] ~= "" then
    table.insert(lines, "")
  end

  -- Parse headers based on requested level
  local headers = {}
  local pattern = header_level == 2 and "^##%s+(.+)$" or "^###%s+(.+)$"
  local display_prefix = header_level == 2 and "## " or "### "

  for i, line in ipairs(lines) do
    local heading = line:match(pattern)
    if heading and not (header_level == 2 and line:match("^###")) then
      table.insert(headers, {
        line_num = i,
        heading = heading,
        display = display_prefix .. heading,
      })
    end
  end

  if #headers == 0 then
    vim.notify("No headers found at level " .. header_level, vim.log.levels.WARN)
    return
  end

  -- Show Telescope picker
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Add [[" .. current_file .. "]] to topic",
    finder = finders.new_table({
      results = headers,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.display,
          ordinal = entry.heading,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local header = selection.value

        -- Smart indentation based on header level
        -- H2 (##): "- [[link]]"
        -- H3 (###): "  - [[link]]" (2 spaces indent)
        local indent = header_level == 2 and "" or "  "
        local link_line = indent .. "- [[" .. current_file .. "]]"

        -- Start right after the header
        local insert_pos = header.line_num + 1

        -- Skip existing blank line if present
        if insert_pos <= #lines and lines[insert_pos] == "" then
          insert_pos = insert_pos + 1
        end

        -- Find the right position among existing bullets
        -- Match the indentation pattern for the current level
        local bullet_pattern = header_level == 2 and "^%-" or "^%s+%-"
        while insert_pos <= #lines and lines[insert_pos]:match(bullet_pattern) do
          insert_pos = insert_pos + 1
        end

        -- Insert the link
        table.insert(lines, insert_pos, link_line)

        -- Write back to file
        local write_file = io.open(toc_file, "w")
        if not write_file then
          vim.notify("Could not write to TOC file", vim.log.levels.ERROR)
          return
        end

        write_file:write(table.concat(lines, "\n"))
        write_file:close()

        vim.notify("Added [[" .. current_file .. "]] to: " .. header.heading, vim.log.levels.INFO)
      end)

      return true
    end,
  }):find()
end

-- Add current note to H2 (main topic)
vim.keymap.set("n", "<leader>zih", function()
  add_to_vachanamrut_toc(2)
end, { desc = "[Z]ettel: Add to [I]ndex [H]eader (H2)" })

-- Add current note to H3 (subtopic)
vim.keymap.set("n", "<leader>zis", function()
  add_to_vachanamrut_toc(3)
end, { desc = "[Z]ettel: Add to [I]ndex [S]ubheader (H3)" })

-- Search ALL files in home directory (including hidden)
vim.keymap.set("n", "<leader>fh", function()
  require("telescope.builtin").find_files({
    cwd = vim.fn.expand("~"),
    hidden = true,
    prompt_title = "Find Files (Home Directory)"
  })
end, { desc = "Find files in home directory" })

-- Search by directory name from home
vim.keymap.set("n", "<leader>fd", function()
  require("telescope.builtin").file_browser({
    cwd = vim.fn.expand("~"),
    prompt_title = "Browse Home Directory"
  })
end, { desc = "Browse home directory" })
