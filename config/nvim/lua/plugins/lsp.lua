local function find_deno_root_dir(fname)
  return require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")(fname)
end

local function find_typescript_root_dir(fname)
  return require("lspconfig.util").root_pattern("tsconfig.json")(fname)
end

local function resolve_deno_root_dir(fname)
  local deno_root_dir = find_deno_root_dir(fname)
  local typescript_root_dir = find_typescript_root_dir(fname)

  if not deno_root_dir then
    return nil
  end

  if typescript_root_dir and #typescript_root_dir > #deno_root_dir then
    return nil
  end

  return deno_root_dir
end

local function resolve_typescript_root_dir(fname)
  local deno_root_dir = find_deno_root_dir(fname)
  local typescript_root_dir = find_typescript_root_dir(fname)

  if not typescript_root_dir then
    return nil
  end

  if deno_root_dir and #deno_root_dir > #typescript_root_dir then
    return nil
  end

  return typescript_root_dir
end

local function env_to_number(value, default)
  if not value or value == "" then
    return default
  end

  return tonumber(value)
end

local ts_ls_max_memory = env_to_number(os.getenv("NEOVIM_LSP_TS_LS_MAX_TS_SERVER_MEMORY"), 4 * 1024)

return {
  "mason-org/mason.nvim",
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    opts = {},
  },

  -- comment out until they upgrade to use the new lspconfig
  --
  -- -- typescript-tools - a much more performant lsp for typescript
  -- {
  --   "pmizio/typescript-tools.nvim",
  --   dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
  --   config = function()
  --     require("typescript-tools").setup({
  --       on_attach = function(client, _)
  --         -- disabling formatting since it conflicts with other formatters like
  --         -- eslint/prettier/biome
  --         client.server_capabilities.documentFormattingProvider = false
  --         client.server_capabilities.documentRangeFormattingProvider = false
  --       end,
  --     })
  --   end,
  -- },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        denols = {
          root_dir = resolve_deno_root_dir,
          single_file_support = false,
        },
        ts_ls = {
          init_options = { hostInfo = "neovim", maxTsServerMemory = ts_ls_max_memory },
          root_dir = resolve_typescript_root_dir,
          single_file_support = false,
        },
      },
    },
  },
}
