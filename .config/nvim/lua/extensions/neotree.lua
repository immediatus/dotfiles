require('neo-tree').setup({
  close_if_last_window = true,
  name = { trailing_slash = true, use_git_status_colors = true, highlight = 'NeoTreeFileName' },
  window = { width = 25, mappings = { ['l'] = 'open', ['h'] = 'close_node' } },
  filesystem = { follow_current_file = { enabled = true } },
})
