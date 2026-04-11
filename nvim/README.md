# Neovim Configuration

LazyVim-based configuration for Python/TypeScript development.

## Current Setup

### LazyVim Extras Enabled

| Category  | Extras                                              |
| --------- | --------------------------------------------------- |
| AI        | claudecode, copilot                                 |
| Languages | python, typescript, terraform, json, toml, markdown |
| Testing   | test.core (neotest)                                 |
| UI        | mini-animate                                        |
| Coding    | yanky, inc-rename                                   |
| Util      | dot                                                 |

### Custom Plugins

| Plugin                    | Description                                          |
| ------------------------- | ---------------------------------------------------- |
| `theme.lua`               | Solarized-osaka colorscheme                          |
| `tmux-navigator.lua`      | Seamless tmux/nvim navigation (C-h/j/k/l)            |
| `scrollbar.lua`           | nvim-scrollbar with gitsigns and hlslens integration |
| `python-lsp.lua`          | basedpyright + ruff LSP configuration                |
| `neotest-python.lua`      | `<leader>td` to run tests in directory               |

### Custom Keymaps

| Key              | Description                      |
| ---------------- | -------------------------------- |
| `<D-c>` (visual) | Copy to system clipboard         |
| `<leader>td`     | Run tests in active directory    |
| `<C-h/j/k/l>`    | Navigate between tmux/nvim panes |

### LSP Servers (via LazyVim extras)

- **Python**: basedpyright (types) + ruff (linting/formatting)
- **TypeScript**: vtsls
- **Terraform**: terraform-ls
- **Lua**: lua_ls
- **JSON**: jsonls
- **Markdown**: marksman

### Python Venv Detection

For basedpyright to find your venv, add a `pyrightconfig.json` to your project root:

```json
{
  "venvPath": ".",
  "venv": ".venv",
  "pythonVersion": "3.12"
}
```

## Key Bindings

### Testing

| Key          | Description            |
| ------------ | ---------------------- |
| `<leader>tr` | Run nearest test       |
| `<leader>tt` | Run tests in file      |
| `<leader>tT` | Run all tests          |
| `<leader>td` | Run tests in directory |
| `<leader>tl` | Run last test          |
| `<leader>to` | Toggle test output     |
| `<leader>ts` | Toggle test summary    |

### LSP

| Key          | Description         |
| ------------ | ------------------- |
| `<leader>ca` | Code actions        |
| `<leader>co` | Organize imports    |
| `<leader>cr` | Rename symbol       |
| `gd`         | Go to definition    |
| `gr`         | Find references     |
| `K`          | Hover documentation |

## Todos

### High Priority

- [x] Add `vim.g.lazyvim_python_ruff = "ruff"` to `lua/config/options.lua` to enable ruff LSP
- [x] Create `lua/plugins/python-lsp.lua` with pyright + ruff configuration + venv detection
- [x] Create `lua/plugins/neotest-python.lua` with `<leader>td` directory test keybinding
- [x] Delete `lua/plugins/run-tests-in-folder.lua` (functionality moves to neotest-python.lua)
- [ ] Add mypy integration via nvim-lint for stricter type checking
- [ ] Add code actions for markdownlint warnings

### Future Enhancements

- [ ] Configure DAP (debug adapter) for Python debugging
- [ ] Add language support for Go when needed
- [ ] Consider basedpyright for stricter pyright variant

## Test Environment

Tests use `pytest-dotenv` to load environment variables. Configure in `pyproject.toml`:

```toml
[tool.pytest.ini_options]
env_files = [".local/env/test.env"]
env_override_existing_values = 1
```

The `.local/` directory should be gitignored for local-only configuration.

## Adding New Languages

1. Check for LazyVim extra: `:LazyExtras` and search
2. Enable via `lazyvim.json` extras array if available
3. Create `lua/plugins/lang-{name}.lua` for customization
4. Add tools to mason ensure_installed if needed

## Verification After Changes

1. `:Lazy sync` to install/update plugins
2. `:LspInfo` should show both `pyright` and `ruff`
3. Position cursor on a warning, `<leader>ca` should show fixes
4. `<leader>co` should organize imports
5. `<leader>tr` should run test with env vars loaded
