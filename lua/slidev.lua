-- Slidev integration for Neovim
-- Auto-save and cursor-synced preview

-- Auto-save configuration
vim.opt.updatetime = 200

-- Auto-save on cursor hold for slide files
vim.api.nvim_create_autocmd({"CursorHold", "CursorHoldI"}, {
  pattern = "*/slides/**/*.md",
  command = "silent! update",
  desc = "Auto-save slide files after 200ms of inactivity"
})

-- Cursor position sync with browser
local last_sync_time = 0
local sync_cooldown = 500 -- milliseconds

local function sync_slide_preview()
  local current_time = vim.loop.now()

  -- Rate limiting: only sync once per cooldown period
  if current_time - last_sync_time < sync_cooldown then
    return
  end

  last_sync_time = current_time

  -- Get current file and cursor position
  local file_path = vim.fn.expand("%:p")
  local line_num = vim.fn.line(".")

  -- Call the sync script
  vim.fn.jobstart({
    vim.fn.expand("~/bin/slidev-sync"),
    file_path,
    tostring(line_num)
  }, {
    detach = true,
    on_stderr = function(_, data)
      if data and #data > 0 and data[1] ~= "" then
        vim.notify("Slidev sync error: " .. table.concat(data, "\n"), vim.log.levels.WARN)
      end
    end
  })
end

-- Sync on cursor movement for slide files
vim.api.nvim_create_autocmd("CursorMoved", {
  pattern = "*/slides/**/*.md",
  callback = sync_slide_preview,
  desc = "Sync browser preview with cursor position"
})

-- Also sync when entering a slide buffer
vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*/slides/**/*.md",
  callback = sync_slide_preview,
  desc = "Sync browser preview when entering slide buffer"
})
