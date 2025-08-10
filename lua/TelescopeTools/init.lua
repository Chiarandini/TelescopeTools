local M = {}

local function check_dependencies()
  local pdftoppm_available = vim.fn.executable('pdftoppm') == 1
  local pdfinfo_available = vim.fn.executable('pdfinfo') == 1

  return {
    pdftoppm = pdftoppm_available,
    pdfinfo = pdfinfo_available,
    all_available = pdftoppm_available and pdfinfo_available
  }
end

local function get_pdf_info(pdf_path)
  local info_cmd = string.format('pdfinfo "%s"', pdf_path)
  local pdfinfo = vim.fn.system(info_cmd)

  if vim.v.shell_error == 0 then
    local info_lines = {"", "PDF Information:", string.rep("=", 50)}
    for line in pdfinfo:gmatch("[^\r\n]+") do
      table.insert(info_lines, line)
    end
    return info_lines
  end

  return {"Could not retrieve PDF information"}
end

-- Convert PDF first page to PNG
local function convert_pdf_to_image(pdf_path, temp_dir)
  local temp_image = temp_dir .. '/preview.png'

  -- macOS-optimized pdftoppm command
  local cmd = string.format(
    'pdftoppm -f 1 -l 1 -png -scale-to-x 800 -scale-to-y -1 "%s" "%s/preview"',
    pdf_path,
    temp_dir
  )

  return cmd, temp_image
end

-- Handle successful PDF conversion
local function handle_pdf_conversion_success(bufnr, entry, temp_image, pdf_path)
  local lines = {
    "📄 PDF Preview Generated",
    "File: " .. entry.value,
    "Path: " .. pdf_path,
    "",
    "Preview image: " .. temp_image,
    "",
    "💡 For better preview experience:",
    "• Install 'image.nvim' for inline images",
    "• Or use 'hologram.nvim' for terminal images"
  }

  -- Add PDF information if available
  local pdf_info = get_pdf_info(pdf_path)
  vim.list_extend(lines, pdf_info)

  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end
  end)
end

-- Handle failed PDF conversion
local function handle_pdf_conversion_failure(bufnr, entry)
  local deps = check_dependencies()
  local lines = {
    "❌ Failed to preview PDF",
    "File: " .. entry.value,
    ""
  }

  if not deps.all_available then
    vim.list_extend(lines, {
      "Missing dependencies:",
      "• pdftoppm: " .. (deps.pdftoppm and "✅ Available" or "❌ Missing"),
      "• pdfinfo: " .. (deps.pdfinfo and "✅ Available" or "❌ Missing"),
      "",
      "Install with: brew install poppler"
    })
  else
    table.insert(lines, "PDF conversion failed for unknown reason")
  end

  vim.schedule(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    end
  end)
end

-- Handle non-PDF file preview
local function handle_non_pdf_preview(bufnr, entry)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
    "📄 Not a PDF file",
    "File: " .. entry.value,
    "Type: " .. (entry.value:match("%.([^%.]+)$") or "unknown")
  })
end

-- Create the PDF previewer
local function create_pdf_previewer()
  local previewers = require('telescope.previewers')

  return previewers.new_buffer_previewer({
    title = "PDF Preview",
    get_buffer_by_name = function(_, entry)
      return entry.value
    end,

    define_preview = function(self, entry, status)
      local pdf_path = entry.cwd .. '/' .. entry.value

      -- Check if it's a PDF file
      if not pdf_path:match('%.pdf$') then
        handle_non_pdf_preview(self.state.bufnr, entry)
        return
      end

      -- Check dependencies
      local deps = check_dependencies()
      if not deps.all_available then
        handle_pdf_conversion_failure(self.state.bufnr, entry)
        return
      end

      -- Create temporary directory
      local temp_dir = vim.fn.tempname()
      vim.fn.mkdir(temp_dir, 'p')

      -- Convert PDF to image
      local cmd, temp_image = convert_pdf_to_image(pdf_path, temp_dir)

      vim.fn.jobstart(cmd, {
        on_exit = function(_, exit_code)
          if exit_code == 0 and vim.fn.filereadable(temp_image) == 1 then
            handle_pdf_conversion_success(self.state.bufnr, entry, temp_image, pdf_path)
          else
            handle_pdf_conversion_failure(self.state.bufnr, entry)
          end

          -- Cleanup
          vim.fn.delete(temp_dir, 'rf')
        end
      })
    end
  })
end

-- Get macOS open command
local function get_macos_open_command()
  return 'open'  -- macOS default
end

-- Handle file opening with default application
local function create_file_opener()
  local actions = require('telescope.actions')

  return function(prompt_bufnr)
    local entry = require('telescope.actions.state').get_selected_entry()
    actions.close(prompt_bufnr)

    local file_path = entry.cwd .. '/' .. entry.value
    local open_cmd = get_macos_open_command()

    vim.fn.jobstart({ open_cmd, file_path }, {
      detach = true,
    })
  end
end

-- Setup telescope key mappings
local function setup_telescope_mappings(map, file_opener)
  map('i', '<CR>', file_opener)
  map('n', '<CR>', file_opener)
  return true
end

-- Main telescope function
function M.telescope_open_execute(path)
  local builtin = require('telescope.builtin')
  local pdf_previewer = create_pdf_previewer()
  local file_opener = create_file_opener()

  builtin.find_files({
    prompt_title = '📚 Open Book',
    cwd = path,
    previewer = pdf_previewer,

    attach_mappings = function(prompt_bufnr, map)
      return setup_telescope_mappings(map, file_opener)
    end,
  })
end

-- Utility function to check system readiness
function M.check_system_readiness()
  local deps = check_dependencies()

  print("📋 PDF Preview System Check:")
  print("pdftoppm: " .. (deps.pdftoppm and "✅" or "❌"))
  print("pdfinfo:  " .. (deps.pdfinfo and "✅" or "❌"))

  if not deps.all_available then
    print("\n💡 Install missing dependencies with:")
    print("brew install poppler")
  else
    print("\n🎉 All dependencies available!")
  end

  return deps.all_available
end

return M
