return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    -- Remove markdownlint from markdown linters
    opts.linters_by_ft = opts.linters_by_ft or {}
    opts.linters_by_ft.markdown = {}

    return opts
  end,
}
