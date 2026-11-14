return {
  -- Prefer development-shell tools; keep Mason as a fallback at home.
  { 'mason-org/mason.nvim', opts = { PATH = 'append' } },
}
