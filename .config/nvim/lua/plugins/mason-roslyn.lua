return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts = opts or {}

      -- Ensure the registries table exists
      opts.registries = opts.registries or {
        "github:mason-org/mason-registry",
      }

      -- Add Crashdummyy registry if not present
      local has_roslyn_registry = false
      for _, reg in ipairs(opts.registries) do
        if reg == "github:Crashdummyy/mason-registry" then
          has_roslyn_registry = true
          break
        end
      end

      if not has_roslyn_registry then
        table.insert(opts.registries, "github:Crashdummyy/mason-registry")
      end

      return opts
    end,
  },
}
