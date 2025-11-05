local function js_and_ts_formatters(bufnr)
  local dirname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p:h")

  if vim.fs.root(dirname, { "deno.json", "deno.jsonc" }) then
    return { "deno_fmt" }
  end

  if vim.fs.root(dirname, { "biome.json" }) then
    return { "biome" }
  end

  if vim.fs.root(dirname, { "package.json" }) then
    return { "eslint_d", "prettier" }
  end

  return {}
end

return {
  {
    "stevearc/conform.nvim",
    opts = {
      default_format_opts = {
        lsp_format = "fallback",
      },

      formatters_by_ft = {
        javascript = js_and_ts_formatters,
        javascriptreact = js_and_ts_formatters,
        go = { "gofumpt" },
        lua = { "stylua" },
        python = { "ruff_format" },
        typescript = js_and_ts_formatters,
        typescriptreact = js_and_ts_formatters,
        ["_"] = { "trim_whitespace" },
      },
    },
  },
}
