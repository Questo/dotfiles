-- GitHub theme that follows the terminal's light/dark mode (Ghostty reports
-- system theme changes, and Neovim updates 'background' to match).
local function github_scheme(bg)
  return (bg or vim.o.background) == "light" and "github_light_default" or "github_dark"
end

-- Zellij answers Neovim's OSC 11 background query itself (with a fixed dark
-- color) and doesn't forward Ghostty's theme-change reports, so inside Zellij
-- read the GNOME color scheme directly and follow it with `gsettings monitor`.
local function gnome_background(scheme)
  return scheme:find("prefer%-dark") and "dark" or "light"
end

local function follow_gnome_theme()
  local out = vim.fn.system({ "gsettings", "get", "org.gnome.desktop.interface", "color-scheme" })
  if vim.v.shell_error ~= 0 then
    return
  end
  vim.o.background = gnome_background(out)
  vim.fn.jobstart({ "gsettings", "monitor", "org.gnome.desktop.interface", "color-scheme" }, {
    on_stdout = function(_, lines)
      for _, line in ipairs(lines) do
        if line ~= "" then
          local bg = gnome_background(line)
          vim.schedule(function()
            if vim.o.background ~= bg then
              vim.o.background = bg
            end
          end)
        end
      end
    end,
  })
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
        if vim.env.ZELLIJ then
          follow_gnome_theme()
        end
        vim.cmd.colorscheme(github_scheme())
      end,
    },
  },
}
