-- Slidevim - Neovim plugin for bidirectional sync with sli.dev
local M = {}

-- Configuration
M.config = {
  nvim_port = 8766,
  host = '127.0.0.1',
  debounce_ms = 400,
  slides_dir_pattern = '/slides/',
  plugin_dir = vim.fn.stdpath 'config' .. '/slidevim',
}

-- State
local server_job = nil
local tcp_client = nil
local slide_cache = nil
local debounce_timer = nil
local last_sent_slide = nil

-- Check if current buffer is in slides directory
local function is_slides_buffer()
  local path = vim.fn.expand '%:p'
  return path:find(M.config.slides_dir_pattern) ~= nil
end

-- Parse markdown lines and return slide positions
-- Returns array of {slide = N, line = L} (slide numbers start at 1, not offset)
-- skip_src_directives: if true, don't count --- src: ... --- blocks as slides
local function parse_slides_from_lines(lines, skip_src_directives)
  local slides = {}
  local in_code_fence = false
  local i = 1
  local n = #lines

  local function is_separator(line)
    return line:match '^%s*%-%-%-%s*$' ~= nil
  end

  local function is_code_fence(line)
    return line:match '^%s*```' ~= nil
  end

  local function has_frontmatter_directive(line)
    -- Match YAML key:value or YAML comments (#...)
    return line:match '^%s*[%w_%-]+%s*:' ~= nil or line:match '^%s*#' ~= nil
  end

  local function is_src_directive(line)
    return line:match '^%s*src%s*:%s*.+%s*$' ~= nil
  end

  -- Skip global frontmatter
  if i <= n and is_separator(lines[i]) then
    i = i + 1
    while i <= n and not is_separator(lines[i]) do
      i = i + 1
    end
    if i <= n then
      i = i + 1
    end
  end

  local slide_start = i
  table.insert(slides, { slide = 1, line = slide_start })

  while i <= n do
    local line = lines[i]

    if is_code_fence(line) then
      in_code_fence = not in_code_fence
    elseif not in_code_fence and is_separator(line) then
      -- Check if following lines contain frontmatter directives
      local has_frontmatter = false
      local is_src_block = false
      local j = i + 1

      -- Scan next few lines (skip blank lines) to detect frontmatter
      while j <= n and j <= i + 30 do
        local next_line = lines[j]

        -- Skip blank lines
        if next_line:match '^%s*$' then
          j = j + 1
        -- Found frontmatter directive
        elseif has_frontmatter_directive(next_line) then
          has_frontmatter = true
          if is_src_directive(next_line) then
            is_src_block = true
          end
          j = j + 1
        -- Found closing separator
        elseif is_separator(next_line) then
          if has_frontmatter then
            i = j -- Skip to closing separator
          end
          break
        -- Found content (not frontmatter)
        else
          break
        end
      end

      -- Only add as slide if not a src: directive block (or if we're not skipping them)
      if not (skip_src_directives and is_src_block) then
        -- Create slide after this separator (which may be the closing --- if frontmatter)
        table.insert(slides, { slide = #slides + 1, line = i + 1 })
      end
    end

    i = i + 1
  end

  return slides
end

-- Extract src: directives from lines
-- Returns array of {line = L, path = "relative/path.md"}
local function extract_src_directives(lines)
  local directives = {}
  for i, line in ipairs(lines) do
    local src_path = line:match '^%s*src%s*:%s*(.+)%s*$'
    if src_path then
      table.insert(directives, { line = i, path = src_path })
    end
  end
  return directives
end

-- Count slides in an external file
local function count_slides_in_file(filepath)
  local f = io.open(filepath, 'r')
  if not f then
    return 0
  end

  local content = f:read '*all'
  f:close()

  local lines = vim.split(content, '\n')
  local slides = parse_slides_from_lines(lines)
  return #slides
end

-- Detect slides in current buffer with global numbering
-- Returns array of {slide = N, line = L} where N is global slide number
local function detect_slides()
  local current_file = vim.fn.expand '%:p'
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  -- Check if we're in a slides directory
  if not is_slides_buffer() then
    return parse_slides_from_lines(lines)
  end

  -- Check if current file is slides.md or a pages/*.md file
  local is_main = current_file:match '/slides%.md$' ~= nil

  if is_main then
    -- Main slides.md: parse with src: directives skipped
    local slides = {}
    local directives = extract_src_directives(lines)
    local directive_idx = 1
    local slide_offset = 0

    -- Parse slides in main file, skipping src: directive blocks
    local main_slides = parse_slides_from_lines(lines, true)

    for _, slide_info in ipairs(main_slides) do
      -- Check if we passed a src: directive
      while directive_idx <= #directives and directives[directive_idx].line < slide_info.line do
        local directive = directives[directive_idx]
        local src_path = vim.fn.fnamemodify(current_dir .. '/' .. directive.path, ':p')
        local external_count = count_slides_in_file(src_path)
        slide_offset = slide_offset + external_count
        directive_idx = directive_idx + 1
      end

      table.insert(slides, { slide = slide_info.slide + slide_offset, line = slide_info.line })
    end

    return slides
  else
    -- pages/*.md: calculate offset from main slides.md
    local slides_dir = vim.fn.fnamemodify(current_file, ':h:h') -- Go up from pages/ to slides/
    local main_file = slides_dir .. '/slides.md'
    local offset = 0

    -- Read main slides.md
    local f = io.open(main_file, 'r')
    if f then
      local main_content = f:read '*all'
      f:close()

      local main_lines = vim.split(main_content, '\n')
      local main_slides = parse_slides_from_lines(main_lines, true) -- Skip src: blocks
      local directives = extract_src_directives(main_lines)

      -- Find where current file is included
      for _, directive in ipairs(directives) do
        -- Resolve relative path from slides.md location
        local src_path = vim.fn.fnamemodify(slides_dir .. '/' .. directive.path, ':p')

        if src_path == current_file then
          -- Count slides before this directive
          for _, slide_info in ipairs(main_slides) do
            if slide_info.line < directive.line then
              offset = offset + 1
            end
          end

          -- Count slides from previous src: directives
          for _, prev_directive in ipairs(directives) do
            if prev_directive.line < directive.line then
              local prev_path = vim.fn.fnamemodify(slides_dir .. '/' .. prev_directive.path, ':p')
              local prev_count = count_slides_in_file(prev_path)
              offset = offset + prev_count
            end
          end

          break
        end
      end
    end

    -- Apply offset to current file's slides
    local slides = parse_slides_from_lines(lines)
    for _, slide_info in ipairs(slides) do
      slide_info.slide = slide_info.slide + offset
    end

    return slides
  end
end

-- Get current slide number from cursor position
local function get_current_slide()
  if not slide_cache then
    slide_cache = detect_slides()
  end

  local cursor_line = vim.fn.line '.'
  local current_slide = 1

  for i = #slide_cache, 1, -1 do
    if cursor_line >= slide_cache[i].line then
      current_slide = slide_cache[i].slide
      break
    end
  end

  return current_slide
end

-- Jump cursor to start of slide
local function goto_slide(slide_num)
  if not slide_cache then
    slide_cache = detect_slides()
  end

  for _, entry in ipairs(slide_cache) do
    if entry.slide == slide_num then
      vim.api.nvim_win_set_cursor(0, { entry.line, 0 })
      vim.cmd 'normal! zz' -- Center screen
      return true
    end
  end

  return false
end

-- Send message to Python server via TCP
local function send_message(msg)
  if not tcp_client or tcp_client:is_closing() then
    return
  end

  local json = vim.fn.json_encode(msg)
  tcp_client:write(json .. '\n')
end

-- Send current slide to Chrome
local function send_current_slide()
  if not is_slides_buffer() then
    return
  end

  local slide = get_current_slide()
  if slide ~= last_sent_slide then
    last_sent_slide = slide
    send_message { type = 'goto', slide = slide }
    vim.notify('Slidevim: → slide ' .. slide, vim.log.levels.INFO)
  end
end

-- Debounced slide update on cursor move
local function schedule_slide_update()
  if debounce_timer then
    debounce_timer:stop()
  end

  debounce_timer = vim.loop.new_timer()
  debounce_timer:start(M.config.debounce_ms, 0, vim.schedule_wrap(send_current_slide))
end

-- Connect to Python server as TCP client
local function connect_tcp()
  local uv = vim.loop
  tcp_client = uv.new_tcp()

  tcp_client:connect(M.config.host, M.config.nvim_port, function(err)
    if err then
      vim.schedule(function()
        vim.notify('Slidevim: Failed to connect to server: ' .. err, vim.log.levels.ERROR)
      end)
      return
    end

    vim.schedule(function()
      vim.notify('Slidevim: Connected to server', vim.log.levels.INFO)
    end)

    -- Start reading messages from server
    tcp_client:read_start(function(read_err, chunk)
      if read_err then
        vim.schedule(function()
          vim.notify('Slidevim: Read error: ' .. read_err, vim.log.levels.ERROR)
        end)
        return
      end

      if not chunk then
        -- Connection closed
        tcp_client:close()
        tcp_client = nil
        return
      end

      -- Handle incoming message (Chrome → Neovim)
      vim.schedule(function()
        local ok, msg = pcall(vim.fn.json_decode, chunk)
        if ok and msg.type == 'navigate' and msg.slide then
          -- Ignore if this is the slide we just sent (echo suppression)
          if msg.slide ~= last_sent_slide then
            local success = goto_slide(msg.slide)
            if success then
              last_sent_slide = msg.slide
              vim.notify('Slidevim: ← slide ' .. msg.slide, vim.log.levels.INFO)
            end
          end
        end
      end)
    end)
  end)
end

-- Start Python WebSocket server with uv
function M.start()
  if server_job then
    vim.notify('Slidevim: Already running', vim.log.levels.WARN)
    return
  end

  -- Check if uv is available
  if vim.fn.executable 'uv' == 0 then
    vim.notify('Slidevim: uv not found, please install it: https://docs.astral.sh/uv/', vim.log.levels.ERROR)
    return
  end

  local server_py = M.config.plugin_dir .. '/python/server.py'

  -- Start the Python server with uv run (handles deps automatically)
  server_job = vim.fn.jobstart({ 'uv', 'run', server_py }, {
    on_stdout = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= '' then
            print(line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line ~= '' then
            vim.notify(line, vim.log.levels.WARN)
          end
        end
      end
    end,
    on_exit = function(_, code)
      server_job = nil
      if tcp_client then
        tcp_client:close()
        tcp_client = nil
      end
      if code ~= 0 then
        vim.notify('Slidevim: Server exited with code ' .. code, vim.log.levels.ERROR)
      end
    end,
  })

  -- Give server a moment to start, then connect
  vim.defer_fn(function()
    connect_tcp()
  end, 500)

  -- Set up autocommands
  local group = vim.api.nvim_create_augroup('Slidevim', { clear = true })

  vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
    group = group,
    pattern = '*.md',
    callback = schedule_slide_update,
  })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI', 'BufEnter' }, {
    group = group,
    pattern = '*.md',
    callback = function()
      slide_cache = nil -- Invalidate cache
    end,
  })
end

-- Stop server
function M.stop()
  if server_job then
    vim.fn.jobstop(server_job)
    server_job = nil
  end

  if tcp_client then
    tcp_client:close()
    tcp_client = nil
  end

  if debounce_timer then
    debounce_timer:stop()
    debounce_timer = nil
  end

  vim.api.nvim_del_augroup_by_name 'Slidevim'
  vim.notify('Slidevim: Stopped', vim.log.levels.INFO)
end

-- Commands
vim.api.nvim_create_user_command('SlidevStart', M.start, {})
vim.api.nvim_create_user_command('SlidevStop', M.stop, {})
vim.api.nvim_create_user_command('SlidevGoto', function(opts)
  local slide_num = tonumber(opts.args)
  if slide_num then
    goto_slide(slide_num)
  end
end, { nargs = 1 })

-- Auto-start when opening markdown files in slides directory
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = '*.md',
  callback = function()
    if is_slides_buffer() and not server_job then
      M.start()
    end
  end,
})

return M
