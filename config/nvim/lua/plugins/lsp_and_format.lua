local function find_biome_root_dir(fname)
  return require("lspconfig.util").root_pattern("biome.json", "biome.jsonc")(fname)
end

local function find_deno_root_dir(fname)
  return require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")(fname)
end

local function find_typescript_root_dir(fname)
  return require("lspconfig.util").root_pattern("jsconfig.json", "tsconfig.json")(fname)
end

local function find_eslint_root_dir(fname)
  return require("lspconfig.util").root_pattern(
    "eslint.config.js",
    "eslint.config.mjs",
    "eslint.config.cjs",
    ".eslintrc.js",
    ".eslintrc.cjs",
    ".eslintrc.mjs",
    ".eslintrc.json",
    ".eslintrc.yml",
    ".eslintrc.yaml",
    ".eslintrc"
  )(fname)
end

local function find_prettier_root_dir(fname)
  return require("lspconfig.util").root_pattern(
    "prettier.config.js",
    "prettier.config.cjs",
    "prettier.config.mjs",
    ".prettierrc",
    ".prettierrc.js",
    ".prettierrc.cjs",
    ".prettierrc.mjs",
    ".prettierrc.json",
    ".prettierrc.yml",
    ".prettierrc.yaml"
  )(fname)
end

local function resolve_jsts_file_tools(fname)
  local deno_root_dir = find_deno_root_dir(fname)
  local deno_root_dir_length = 0
  if deno_root_dir and deno_root_dir ~= "" then
    deno_root_dir_length = string.len(deno_root_dir)
  end

  local biome_root_dir = find_biome_root_dir(fname)
  local biome_root_dir_length = 0
  if biome_root_dir and biome_root_dir ~= "" then
    biome_root_dir_length = string.len(biome_root_dir)
  end

  local typescript_root_dir = find_typescript_root_dir(fname)
  local typescript_root_dir_length = 0
  if typescript_root_dir and typescript_root_dir ~= "" then
    typescript_root_dir_length = string.len(typescript_root_dir)
  end

  local eslint_root_dir = find_eslint_root_dir(fname)
  local eslint_root_dir_length = 0
  if eslint_root_dir and eslint_root_dir ~= "" then
    eslint_root_dir_length = string.len(eslint_root_dir)
  end

  local prettier_root_dir = find_prettier_root_dir(fname)
  local prettier_root_dir_length = 0
  if prettier_root_dir and prettier_root_dir ~= "" then
    prettier_root_dir_length = string.len(prettier_root_dir)
  end

  vim.notify(string.format("ESLINT ROOT DIR: (len: %d) %s", eslint_root_dir_length, eslint_root_dir))
  vim.notify(string.format("BIOME ROOT DIR: (len: %d) %s", biome_root_dir_length, biome_root_dir))

  local tools = {}

  if deno_root_dir_length > 0 and deno_root_dir_length > typescript_root_dir_length then
    return { deno = deno_root_dir }
  end

  tools["tsc"] = typescript_root_dir

  if biome_root_dir_length > 0 and biome_root_dir_length > eslint_root_dir_length then
    vim.notify("SELECTED biome")
    tools["biome"] = biome_root_dir
  elseif eslint_root_dir_length > 0 then
    vim.notify("SELECTED eslint")

    tools["eslint"] = eslint_root_dir

    if prettier_root_dir_length > 0 then
      vim.notify("ADDED prettier")

      tools["prettier"] = prettier_root_dir
    end
  else
    tools["biome"] = biome_root_dir
  end

  return tools
end

local function get_or_resolve_jsts_buffer_tools(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if vim.b[bufnr].project_tools then
    return vim.b[bufnr].project_tools
  end

  local fname = vim.api.nvim_buf_get_name(bufnr)
  if not fname or fname == "" then
    return {}
  end

  local tools = resolve_jsts_file_tools(fname)

  vim.b[bufnr].project_tools = tools

  return tools
end

local function tool_root_dir(tool)
  local get_root_dir = function(bufnr, on_dir)
    local tools = get_or_resolve_jsts_buffer_tools(bufnr)

    if tools[tool] == nil then
      return nil
    end

    on_dir(tools[tool])
  end

  return get_root_dir
end

local function jsts_formatters(bufnr)
  local tools = get_or_resolve_jsts_buffer_tools(bufnr)

  if tools["deno"] ~= nil then
    return { "deno_fmt" }
  end

  if tools["biome"] ~= nil then
    return { "biome-check" }
  end

  if tools["prettier"] ~= nil then
    return { "prettier" }
  end

  return {}
end

return {
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "docker_compose_language_service",
        "docker_language_server",
        "eslint",
        "lua_ls",
        "prismals",
        "terraformls",
        "yamlls",
      },
    },
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
  },
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
      local settings = {}

      local tsserver_max_memory_env = os.getenv("NEOVIM_LSP_TSSERVER_MAX_MEMORY")

      if tsserver_max_memory_env ~= nil and tsserver_max_memory_env ~= "" then
        vim.lsp.log.info(
          string.format("Detected NEOVIM_LSP_TSSERVER_MAX_MEMORY=%s", vim.inspect(tsserver_max_memory_env))
        )

        local tsserver_max_memory = tonumber(tsserver_max_memory_env)

        settings.tsserver_max_memory = tsserver_max_memory

        vim.lsp.log.info(string.format("Updating tsserver_max_memory=%d", vim.inspect(tsserver_max_memory)))
      end

      require("typescript-tools").setup({
        root_dir = tool_root_dir("tsc"),
        settings = settings,
        single_file_support = true,
      })
    end,
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    init = function()
      local debug = os.getenv("NEOVIM_LSP_DEBUG")

      if debug == "1" then
        vim.lsp.set_log_level("DEBUG")

        vim.lsp.log.debug("Log level is DEBUG [NEOVIM_LSP_DEBUG]")
      else
        vim.lsp.set_log_level("WARN")

        vim.lsp.log.warn("Log level is warning [NEOVIM_LSP_DEBUG]")
      end
    end,
    opts = function(_, opts)
      opts.servers = vim.tbl_deep_extend("force", opts.servers or {}, {
        basedpyright = {},
        biome = {
          root_dir = tool_root_dir("biome"),
          single_file_support = true,
        },
        denols = {
          root_dir = tool_root_dir("deno"),
          single_file_support = false,
        },
        docker_compose_language_service = {},
        dockerls = {},
        eslint = {
          root_dir = tool_root_dir("eslint"),
          single_file_support = true,
        },
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
      })
    end,
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      default_format_opts = {
        lsp_format = "first",
      },
      formatters_by_ft = {
        bash = { "shfmt" },
        fish = {},
        go = { "gofumpt" },
        javascript = jsts_formatters,
        javascriptreact = jsts_formatters,
        json = { "jq" },
        jsonc = { "jq" },
        lua = { "stylua" },
        markdown = { "mdformat" },
        prisma = { "prisma_format" },
        python = { "ruff_format" },
        rust = { "rustfmt" },
        sh = { "shfmt" },
        sql = { "sqlfmt" },
        toml = { "taplo" },
        typescript = jsts_formatters,
        typescriptreact = jsts_formatters,
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
