require("full-border"):setup({
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
})

require("bunny"):setup({
  hops = {
    { key = "~",          path = "~",                            desc = "Home"         },
    { key = "C",          path = "~/.config",                    desc = "Config files" },
    { key = "s",          path = "~/Sync",                       desc = "Sync"         },
    { key = "m",          path = "~/Music",                      desc = "Music"        },
    { key = "d",          path = "~/Downloads",                  desc = "Downloads"    },
    { key = "D",          path = "~/Documents",                  desc = "Documents"    },
    { key = "b",          path = "~/code/immediatus.github.io",  desc = "Blog"         },
    { key = "c",          path = "~/code",                       desc = "Code"         },
  },
  desc_strategy = "path",
  ephemeral = true,
  tabs = true,
  notify = false,
  fuzzy_cmd = "fzf",
})

require("custom-shell"):setup({
    history_path = "default",
    save_history = true,
})

if os.getenv("NVIM") then
	require("toggle-pane"):entry("min-preview")
end

function Linemode:mc_style()
    local time = math.floor(self._file.cha.btime or self._file.cha.mtime or 0)
    local time_str = os.date("%b %d %H:%M", time) -- Shorter format: "Mar 22 14:30"
    local size = self._file:size()
    local size_str = size and ya.readable_size(size) or ""
    local padded_size = string.format("%6s", size_str)
    return ui.Line(string.format("%s │ %s", time_str, padded_size))
end

require("githead"):setup()
