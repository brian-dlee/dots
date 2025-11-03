return {
  -- theme
  {
    "eldritch-theme/eldritch.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("eldritch").setup({
        ---@param colors ColorScheme
        on_colors = function(colors)
          colors.bg = "#000000"
        end,
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "eldritch",
    },
  },

  -- snacks explorer config (over neo-tree)
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      -- merge your overrides into existing picker/explorer options
      opts.picker = opts.picker or {}
      opts.picker.sources = opts.picker.sources or {}
      opts.picker.sources.explorer = vim.tbl_deep_extend("force", opts.picker.sources.explorer or {}, {
        hidden = true, -- show dotfiles
        ignored = false, -- hide gitignored files
        git_status = true,
        diagnostics = true,
        follow_file = true,
        exclude = { "**/.git/**" },
      })
    end,
  },

  -- trouble
  {
    "folke/trouble.nvim",
    -- opts will be merged with the parent spec
    opts = { use_diagnostic_signs = true },
  },

  -- symbols-outline
  {
    "simrat39/symbols-outline.nvim",
    cmd = "SymbolsOutline",
    keys = { { "<leader>cs", "<cmd>SymbolsOutline<cr>", desc = "Symbols Outline" } },
    config = true,
  },

  -- telescope
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>fp",
        function()
          local plugin = require("telescope.builtin")
          local lazy_core_config = require("lazy.core.config")
          plugin.find_files({ cwd = lazy_core_config.options.root })
        end,
        desc = "Find Plugin File",
      },
    },
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    },
  },
  {
    "telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      config = function()
        require("telescope").load_extension("fzf")
      end,
    },
  },

  -- neovim-dap - debugger
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "leoluz/nvim-dap-go",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
      "mason-org/mason.nvim",
    },
  },

  -- treesitter
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

  -- mason
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "basedpyright",
        "biome",
        "deno",
        "dockerfile-language-server",
        "eslint-lsp",
        "eslint_d",
        "gofumpt",
        "goimports",
        "golangci-lint",
        "gopls",
        "lua-language-server",
        "prettier",
        "prisma-language-server",
        "ruff",
        "shellcheck",
        "shfmt",
        "stylua",
        "sqlfmt",
        "taplo",
        "templ",
        "terraform-ls",
        "typescript-language-server",
        "yamlfmt",
      })
    end,
  },
}
