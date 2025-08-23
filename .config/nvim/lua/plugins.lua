require('helpers/globals')

return {
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    cmd = 'Neotree',
    config = function() require('extensions.neotree') end,
    dependencies = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim' },
    lazy = true,
  },
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    config = function() require('extensions.telescope') end,
    dependencies = {
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        enabled = vim.fn.executable('make') == 1,
        build = 'make',
      },
      { 'nvim-telescope/telescope-project.nvim' },
    },
    lazy = false,
  },
  {
    'nvim-lualine/lualine.nvim',
    config = function() require('extensions.lualine') end,
  },
  {
    'lewis6991/gitsigns.nvim',
    config = function() require('extensions.gitsigns') end,
  },
  {
    'dstein64/vim-startuptime',
    cmd = 'StartupTime',
    init = function() vim.g.startuptime_tries = 50 end,
  },
  {
    'echasnovski/mini.surround',
    opts = { mappings = { add = 'gsa', delete = 'gsd', replace = 'gsr', update_n_lines = 'gsn' } },
  },
  { 'akinsho/toggleterm.nvim', cmd = { 'TermExec', 'ToggleTerm' }, opts = {} },
  { 'junegunn/vim-easy-align', cmd = 'EasyAlign', lazy = true },
  { 'numToStr/Comment.nvim', opts = {} },
  {
    'obreitwi/vim-sort-folds',
    build = 'pip3 install pynvim',
    cmd = 'SortFolds',
    enabled = vim.fn.executable('pip3') == 1,
    lazy = true,
  },
  { 'sQVe/sort.nvim', cmd = 'Sort' },
  { 'kylechui/nvim-surround', opts = {} },
  {
    'folke/tokyonight.nvim',
    config = function() vim.cmd([[colorscheme tokyonight]]) end,
    lazy = false,
    priority = 1000,
  },
  {
    'vladdoster/remember.nvim',
    config = function() require('remember') end,
    lazy = false,
    priority = 2000,
  },
}

--  vim: set expandtab filetype=lua shiftwidth=4 tabstop=4 :
