-- Debug/check Slidevim's current deck indexing behavior.
--
-- Usage:
--   SLIDEVIM_DECK_DIR=/path/to/slides nvim -n --headless -u NONE \
--     -c 'luafile slidevim/debug_index.lua' -c 'qa'
--
-- If SLIDEVIM_DECK_DIR is omitted, this script uses Robin's language-design-m2
-- deck when it exists. For that deck, the expected snapshot below is checked so
-- parser/index changes cannot silently alter global slide numbering or cursor
-- target lines.

local script = debug.getinfo(1, 'S').source:sub(2)
local plugin_dir = vim.fn.fnamemodify(script, ':h')
package.path = plugin_dir .. '/lua/?.lua;' .. package.path

local slidevim = require 'slidevim'
slidevim.config.auto_start = false

local default_deck_dir = '/home/robin/teach/coding/language-design-m2/slides'
local sample_deck_dir = vim.fn.fnamemodify(plugin_dir .. '/fixtures/sample-deck', ':p'):gsub('/$', '')
local deck_dir = os.getenv 'SLIDEVIM_DECK_DIR'
if not deck_dir or deck_dir == '' then
  deck_dir = default_deck_dir
end

deck_dir = vim.fn.fnamemodify(deck_dir, ':p'):gsub('/$', '')
slidevim.config.slides_dir_pattern = deck_dir:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')

local function fail(message)
  print('Slidevim debug index check failed: ' .. message)
  vim.cmd 'cquit 1'
end

if vim.fn.isdirectory(deck_dir) == 0 then
  fail('deck directory does not exist: ' .. deck_dir)
end

local debug_api = slidevim._debug
if not debug_api then
  fail('slidevim._debug is not available')
end

local main_file = deck_dir .. '/slides.md'
if vim.fn.filereadable(main_file) == 0 then
  fail('missing slides.md in deck directory: ' .. deck_dir)
end

local function normalize_src(path)
  local normalized = path:gsub('^%./', '')
  return normalized
end

local files = { 'slides.md' }
for _, directive in ipairs(debug_api.extract_src_directives(vim.fn.readfile(main_file))) do
  table.insert(files, normalize_src(directive.path))
end

local deck_index = debug_api.build_deck_index(deck_dir)

local function detect_file(relative_path)
  local path = vim.fn.fnamemodify(deck_dir .. '/' .. relative_path, ':p')
  if vim.fn.filereadable(path) == 0 then
    fail('missing imported file: ' .. relative_path)
  end

  vim.cmd('silent keepalt edit ' .. vim.fn.fnameescape(path))
  return debug_api.detect_slides(), path
end

local rows = {}
local all_slides = {}
for _, relative_path in ipairs(files) do
  local slides, path = detect_file(relative_path)
  if #slides == 0 then
    fail('no slides detected in ' .. relative_path)
  end

  for _, slide in ipairs(slides) do
    table.insert(all_slides, {
      file = relative_path,
      path = path,
      slide = slide.slide,
      line = slide.line,
    })
  end

  table.insert(rows, {
    file = relative_path,
    path = path,
    first_slide = slides[1].slide,
    first_line = slides[1].line,
    count = #slides,
    last_slide = slides[#slides].slide,
    slides = slides,
  })
end

local function print_rows()
  print('Slidevim deck index: ' .. deck_dir)
  print(string.format('%-40s %8s %8s %8s %8s', 'file', 'first', 'line', 'count', 'last'))
  for _, row in ipairs(rows) do
    print(string.format('%-40s %8d %8d %8d %8d', row.file, row.first_slide, row.first_line, row.count, row.last_slide))
  end
end

local expected_language_design_m2 = {
  { file = 'slides.md', first_slide = 1, first_line = 13, count = 1, last_slide = 1 },
  { file = 'pages/00_intro-udemy.md', first_slide = 2, first_line = 6, count = 14, last_slide = 15 },
  { file = 'pages/01_calc.md', first_slide = 16, first_line = 4, count = 20, last_slide = 35 },
  { file = 'pages/02_toy-00-intro.md', first_slide = 36, first_line = 4, count = 9, last_slide = 44 },
  { file = 'pages/02_toy-module-01-lexer.md', first_slide = 45, first_line = 6, count = 4, last_slide = 48 },
  { file = 'pages/02_toy-module-02-parser.md', first_slide = 49, first_line = 6, count = 21, last_slide = 69 },
  { file = 'pages/02_toy-module-03-interpreter.md', first_slide = 70, first_line = 6, count = 12, last_slide = 81 },
  { file = 'pages/02_toy-module-04-variables.md', first_slide = 82, first_line = 6, count = 40, last_slide = 121 },
  { file = 'pages/02_toy-module-05-control-flow.md', first_slide = 122, first_line = 6, count = 30, last_slide = 151 },
  { file = 'pages/02_toy-module-06-functions.md', first_slide = 152, first_line = 6, count = 24, last_slide = 175 },
  { file = 'pages/02_toy-module-07-antlr.md', first_slide = 176, first_line = 6, count = 17, last_slide = 192 },
  { file = 'pages/02_toy-module-08-polishing.md', first_slide = 193, first_line = 6, count = 10, last_slide = 202 },
  { file = 'pages/03_conclusion.md', first_slide = 203, first_line = 6, count = 6, last_slide = 208 },
}

local expected_sample_deck = {
  {
    file = 'slides.md',
    first_slide = 1,
    first_line = 5,
    count = 2,
    last_slide = 5,
    slides = {
      { slide = 1, line = 5 },
      { slide = 5, line = 22 },
    },
  },
  {
    file = 'pages/intro.md',
    first_slide = 2,
    first_line = 4,
    count = 3,
    last_slide = 4,
    slides = {
      { slide = 2, line = 4 },
      { slide = 3, line = 10 },
      { slide = 4, line = 22 },
    },
  },
  {
    file = 'pages/deep-dive.md',
    first_slide = 6,
    first_line = 4,
    count = 3,
    last_slide = 8,
    slides = {
      { slide = 6, line = 4 },
      { slide = 7, line = 10 },
      { slide = 8, line = 18 },
    },
  },
  {
    file = 'pages/nested/appendix.md',
    first_slide = 9,
    first_line = 4,
    count = 2,
    last_slide = 10,
    slides = {
      { slide = 9, line = 4 },
      { slide = 10, line = 10 },
    },
  },
}

local expected = nil
if deck_dir == vim.fn.fnamemodify(default_deck_dir, ':p'):gsub('/$', '') then
  expected = expected_language_design_m2
elseif deck_dir == sample_deck_dir then
  expected = expected_sample_deck
end

local failures = {}

local function add_failure(message)
  table.insert(failures, message)
end

table.sort(all_slides, function(a, b)
  return a.slide < b.slide
end)

for i, slide in ipairs(all_slides) do
  if slide.slide ~= i then
    add_failure(string.format('global slide sequence mismatch at #%d: found slide=%d in %s:%d', i, slide.slide, slide.file, slide.line))
  end
end

if #deck_index.slides ~= #all_slides then
  add_failure(string.format('deck index expected %d total slides from detect_slides(), got %d', #all_slides, #deck_index.slides))
end

for i, slide in ipairs(all_slides) do
  local indexed = deck_index.slides[i]
  if not indexed then
    add_failure(string.format('deck index missing global slide entry #%d for %s:%d', slide.slide, slide.file, slide.line))
  elseif indexed.slide ~= slide.slide or indexed.file ~= slide.path or indexed.line ~= slide.line then
    add_failure(string.format('deck index slide #%d expected %s:%d, got %s:%d', slide.slide, slide.file, slide.line, indexed.file, indexed.line))
  end
end

for _, row in ipairs(rows) do
  local indexed_slides = deck_index.by_file[row.path] or {}
  if #indexed_slides ~= #row.slides then
    add_failure(string.format('deck index %s expected %d file slides from detect_slides(), got %d', row.file, #row.slides, #indexed_slides))
  end

  for i, slide in ipairs(row.slides) do
    local indexed = indexed_slides[i]
    if not indexed then
      add_failure(string.format('deck index missing %s slide entry #%d', row.file, i))
    elseif indexed.slide ~= slide.slide or indexed.line ~= slide.line then
      add_failure(string.format('deck index %s entry #%d expected slide=%d line=%d, got slide=%d line=%d', row.file, i, slide.slide, slide.line, indexed.slide, indexed.line))
    end
  end
end

if expected then
  if #rows ~= #expected then
    add_failure(string.format('expected %d indexed files, got %d', #expected, #rows))
  end

  for i, expected_row in ipairs(expected) do
    local row = rows[i]
    if not row then
      add_failure('missing row #' .. i .. ' for ' .. expected_row.file)
    else
      for _, field in ipairs { 'file', 'first_slide', 'first_line', 'count', 'last_slide' } do
        if row[field] ~= expected_row[field] then
          add_failure(string.format('%s.%s expected %s, got %s', expected_row.file, field, tostring(expected_row[field]), tostring(row[field])))
        end
      end

      if expected_row.slides then
        if #row.slides ~= #expected_row.slides then
          add_failure(string.format('%s.slides expected %d entries, got %d', expected_row.file, #expected_row.slides, #row.slides))
        end

        for slide_idx, expected_slide in ipairs(expected_row.slides) do
          local slide = row.slides[slide_idx]
          if not slide then
            add_failure(string.format('%s.slides[%d] missing expected slide=%d line=%d', expected_row.file, slide_idx, expected_slide.slide, expected_slide.line))
          else
            for _, field in ipairs { 'slide', 'line' } do
              if slide[field] ~= expected_slide[field] then
                add_failure(string.format('%s.slides[%d].%s expected %s, got %s', expected_row.file, slide_idx, field, tostring(expected_slide[field]), tostring(slide[field])))
              end
            end
          end
        end
      end
    end
  end
end

print_rows()

if #failures > 0 then
  fail('\n  - ' .. table.concat(failures, '\n  - '))
end

if expected then
  print('Slidevim debug index check passed.')
else
  print('No snapshot expectations for this deck; printed index only.')
end
