local find_deno_root_dir = function(fname)
  return require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")(fname)
end

local find_typescript_root_dir = function(fname)
  return require("lspconfig.util").root_pattern("tsconfig.json")(fname)
end

local resolve_deno_root_dir = function(fname)
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

local resolve_typescript_root_dir = function(fname)
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
          root_dir = resolve_typescript_root_dir,
          single_file_support = false,
        },
      },
    },
  },
}
