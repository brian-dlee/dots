vim.filetype.add({
  pattern = {
    ["(docker-)?compose%.ya?ml"] = "yaml.docker-compose",
    ["%.envrc%..+"] = "sh",
  },
})

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = {
    "**/docker-compose.yml",
    "**/docker-compose.yaml",
    "**/compose.yml",
    "**/compose.yaml",
  },
  callback = function(opts)
    vim.bo[opts.buf].filetype = "yaml.docker-compose"
  end,
})
