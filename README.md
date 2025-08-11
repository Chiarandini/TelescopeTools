# 🔧 TelescopeTools

A Neovim plugin extension that adds PDF preview capabilities to Telescope's file finder. Perfect for browsing document libraries, academic papers, or any collection of PDF files.

## ✨ Features

- 🔍 **PDF Preview**: See PDF metadata and first-page preview directly in Telescope
- 📄 **Smart File Detection**: Automatically detects PDF files and shows appropriate previews
- 🚀 **Non-blocking**: Asynchronous PDF processing won't freeze your editor
- 🖥️ **macOS Optimized**: Designed specifically for macOS users
- 🛠️ **Dependency Checking**: Built-in system readiness verification
- 📁 **Flexible**: Works with any directory containing PDF files

## 🎯 Demo

```
┌─ 📚 Open Book ────────────────────────┐  ┌─ PDF Preview ─────────────────────────┐
│ > research-paper.pdf                   │  │ 📄 PDF Preview Generated              │
│   textbook-chapter-1.pdf              │  │ File: research-paper.pdf              │
│   notes.pdf                           │  │ Path: /Users/you/Documents/Books/...  │
│   presentation.pdf                    │  │                                       │
│                                       │  │ PDF Information:                      │
│                                       │  │ ================================================ │
│                                       │  │ Title:    Advanced Machine Learning   │
│                                       │  │ Author:   Dr. Smith                   │
│                                       │  │ Pages:    245                         │
│                                       │  │ Creator:  LaTeX                       │
└───────────────────────────────────────┘  └───────────────────────────────────────┘
```

## 📋 Requirements

### System Dependencies
- **Neovim** 0.7+
- **poppler-utils** (for PDF processing)
- **macOS** (optimized for, but adaptable to Linux)

### Neovim Plugins
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) (telescope dependency)

## 🚀 Installation

### 1. Install System Dependencies

```bash
# Install poppler-utils on macOS
brew install poppler

# Verify installation
which pdftoppm pdfinfo
```

<details>
<summary>Other Platforms</summary>

```bash
# Ubuntu/Debian
sudo apt install poppler-utils

# Arch Linux
sudo pacman -S poppler

# Fedora
sudo dnf install poppler-utils
```
</details>

### 2. Install the Module

#### Option A: Direct File
1. Create the directory: `mkdir -p ~/.config/nvim/lua/`
2. Save the main code as `~/.config/nvim/lua/telescope_tools.lua`

#### Option B: Plugin Manager
Add to your plugin configuration:

<details>
<summary>lazy.nvim</summary>

```lua
{
  "Chiarandini/TelescopeTools",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    -- Configuration here
  end,
}
```
</details>

<details>
<summary>packer.nvim</summary>

```lua
use {
  'Chiarandini/TelescopeTools',
  requires = {
    'nvim-telescope/telescope.nvim',
    'nvim-lua/plenary.nvim',
  },
  config = function()
    -- Configuration here
  end
}
```
</details>

### 3. Configure in init.lua

```lua
local telescope_tools = require('telescope_tools')

-- Check system readiness (optional)
telescope_tools.check_system_readiness()

-- Set up keymaps
vim.keymap.set('n', '<leader>fo', function()
  telescope_tools.telescope_open_execute(vim.fn.getcwd())
end, { desc = 'Open files with PDF preview' })

vim.keymap.set('n', '<leader>fb', function()
  telescope_tools.telescope_open_execute('~/Documents/Books')
end, { desc = 'Browse books with PDF preview' })

vim.keymap.set('n', '<leader>fp', function()
  telescope_tools.telescope_open_execute('~/Documents/Papers')
end, { desc = 'Browse research papers' })
```

## 🎮 Usage

### Basic Usage

```lua
-- Browse current directory
:lua require('telescope_tools').telescope_open_execute(vim.fn.getcwd())

-- Browse specific directory
:lua require('telescope_tools').telescope_open_execute('~/Documents')
```

### Key Bindings (in Telescope)

| Key | Mode | Action |
|-----|------|--------|
| `<CR>` | Insert/Normal | Open PDF with default application |
| `<Esc>` | Insert/Normal | Close Telescope |
| `<C-c>` | Insert/Normal | Close Telescope |

### System Check

Verify your system is properly configured:

```lua
:lua require('telescope_tools').check_system_readiness()
```

Expected output:
```
📋 PDF Preview System Check:
pdftoppm: ✅
pdfinfo:  ✅

🎉 All dependencies available!
```

## ⚙️ Configuration

### Custom Directory Shortcuts

```lua
local telescope_tools = require('telescope_tools')

-- Create custom commands
vim.api.nvim_create_user_command('BrowseBooks', function()
  telescope_tools.telescope_open_execute('~/Library/Books')
end, { desc = 'Browse book collection' })

vim.api.nvim_create_user_command('BrowsePapers', function()
  telescope_tools.telescope_open_execute('~/Documents/Research')
end, { desc = 'Browse research papers' })
```

### Which-key Integration

```lua
local wk = require("which-key")

wk.register({
  f = {
    name = "Files",
    o = { function() require('telescope_tools').telescope_open_execute(vim.fn.getcwd()) end, "Open with PDF preview" },
    b = { function() require('telescope_tools').telescope_open_execute('~/Documents/Books') end, "Browse books" },
    p = { function() require('telescope_tools').telescope_open_execute('~/Documents/Papers') end, "Browse papers" },
  }
}, { prefix = "<leader>" })
```

## 🔧 Advanced Features

### Enhanced Image Preview

For actual image preview (not just metadata), install additional plugins:

```lua
-- With lazy.nvim
{
  "3rd/image.nvim",
  config = function()
    require("image").setup({
      backend = "kitty", -- or "ueberzug"
    })
  end,
}
```

### Custom File Types

Extend to support other document types:

```lua
-- In your configuration
local function is_document(filename)
  local extensions = { 'pdf', 'epub', 'mobi', 'djvu' }
  local ext = filename:match("%.([^%.]+)$")
  return ext and vim.tbl_contains(extensions, ext:lower())
end
```

## 🐛 Troubleshooting

### Common Issues

#### "pdftoppm not found"
```bash
# Install poppler-utils
brew install poppler

# Add to PATH if needed
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

#### "Failed to preview PDF"
1. Check file permissions: `ls -la your-file.pdf`
2. Verify PDF is not corrupted: `pdfinfo your-file.pdf`
3. Check available disk space: `df -h`

#### Slow preview generation
- Large PDFs may take time to process
- Consider using `-scale-to-x 400` for faster previews
- Check system resources: `top` or `htop`

### Debug Mode

Enable verbose output:

```lua
vim.g.telescope_tools_debug = true
```


### Development Setup

```bash
git clone your-repo
cd TelescopeTools

# Test the module
nvim --headless -c "lua require('telescope_tools').check_system_readiness()" -c "qa"
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file.

## 🙏 Acknowledgments

- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - Amazing fuzzy finder
- [Poppler](https://poppler.freedesktop.org/) - PDF rendering utilities
- [Neovim](https://neovim.io/) - The extensible editor

---

**💡 Pro Tip**: Use with [zoxide](https://github.com/ajeetdsouza/zoxide) for quick directory jumping:
```lua
vim.keymap.set('n', '<leader>fz', function()
  local dir = vim.fn.system('zoxide query --interactive'):gsub('\n', '')
  if dir and dir ~= '' then
    require('telescope_tools').telescope_open_execute(dir)
  end
end, { desc = 'Browse PDFs with zoxide' })
```
