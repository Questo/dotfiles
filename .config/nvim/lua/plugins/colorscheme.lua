-- GitHub theme that follows the terminal's light/dark mode (Ghostty reports
-- system theme changes, and Neovim updates 'background' to match).
local function github_scheme(bg)
  return (bg or vim.o.background) == "light" and "github_light_default" or "github_dark"
end

return {
  {
    "projekt0n/github-nvim-theme",
    name = "github-theme",
    lazy = false,
    priority = 1000,
    opts = {
      options = {
        transparent = true, -- let Ghostty's background-opacity show through
      },
    },
    config = function(_, opts)
      require("github-theme").setup(opts)
      vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "background",
        callback = function()
          -- Use the requested value: Neovim reloads the current scheme on a
          -- 'background' change, and the theme resets 'background' itself.
          local scheme = github_scheme(vim.v.option_new)
          if vim.g.colors_name ~= scheme then
            vim.cmd.colorscheme(scheme)
          end
        end,
      })
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = function()
        vim.cmd.colorscheme(github_scheme())
      end,
    },
  },
}
