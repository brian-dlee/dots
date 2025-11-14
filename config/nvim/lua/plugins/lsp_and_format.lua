local function find_deno_root_dir(fname)
  return require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")(fname)
end

local function find_typescript_root_dir(fname)
  return require("lspconfig.util").root_pattern(
    "package-lock.json",
    "yarn.lock",
    "pnpm-lock.yaml",
    "bun.lockb",
    "bun.lock"
  )(fname)
end

local function resolve_deno_root_dir(bufnr, on_dir)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local deno_root_dir = find_deno_root_dir(fname)
  local typescript_root_dir = find_typescript_root_dir(fname)

  if not deno_root_dir or string.len(deno_root_dir) == 0 then
    return nil
  end

  if typescript_root_dir and string.len(typescript_root_dir) > string.len(deno_root_dir) then
    return nil
  end

  on_dir(deno_root_dir)
end

local function resolve_typescript_root_dir(bufnr, on_dir)
  local fname = vim.api.nvim_buf_get_name(bufnr)
  local deno_root_dir = find_deno_root_dir(fname)
  local typescript_root_dir = find_typescript_root_dir(fname)

  if not typescript_root_dir or string.len(typescript_root_dir) == 0 then
    return
  end

  if deno_root_dir and string.len(deno_root_dir) > string.len(typescript_root_dir) then
    return nil
  end

  on_dir(typescript_root_dir)
end

local function js_and_ts_formatters(bufnr)
  local dirname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p:h")

  if vim.fs.root(dirname, { "deno.json", "deno.jsonc" }) then
    return { "deno_fmt" }
  end

  if vim.fs.root(dirname, { "biome.json" }) then
    return { "biome" }
  end

  if vim.fs.root(dirname, { "package.json" }) then
    return { "prettier" }
  end

  return {}
end

return {
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "bash",
        "html",
        "javascript",
        "json",
        "just",
        "lua",
        "markdown",
        "markdown_inline",
        "prisma",
        "python",
        "query",
        "regex",
        "sql",
        "templ",
        "terraform",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      })
    end,
  },

  -- TypeScript Tools (more performant than ts_ls)
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("typescript-tools").setup({
        root_dir = resolve_typescript_root_dir,
        single_file_support = true,
      })
    end,
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {},
        biome = {},
        denols = {
          root_dir = resolve_deno_root_dir,
          single_file_support = false,
        },
        docker_compose_language_service = {},
        dockerls = {},
        eslint = {},
        golangci_lint_ls = {},
        gopls = {},
        lua_ls = {},
        prismals = {},
        ruff_lsp = {},
        rust_analyzer = {},
        taplo = {},
        templ = {},
        terraformls = {},
        yamlls = {},
      },
    },
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      default_format_opts = {
        lsp_format = "first",
      },
      formatters_by_ft = {
        javascript = js_and_ts_formatters,
        javascriptreact = js_and_ts_formatters,
        typescript = js_and_ts_formatters,
        typescriptreact = js_and_ts_formatters,
        json = { "jq" },
        jsonc = { "jq" },
        go = { "gofumpt" },
        lua = { "stylua" },
        markdown = { "mdformat" },
        prisma = { "prisma_format" },
        python = { "ruff_format" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        sql = { "sqlfmt" },
        toml = { "taplo" },
        yaml = { "yamlfmt" },
        ["_"] = { "trim_whitespace" },
      },
      formatters = {
        prisma_format = {
          command = "prisma",
          args = { "format", "--schema", "$FILENAME" },
          stdin = false,
        },
        eslint = {
          command = "eslint",
          args = { "--stdin", "--stdin-filename", "$FILENAME" },
          stdin = true,
        },
      },
    },
  },
}
