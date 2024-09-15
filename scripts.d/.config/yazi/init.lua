require("full-border"):setup {
	-- Available values: ui.Border.PLAIN, ui.Border.ROUNDED
	type = ui.Border.ROUNDED,
}

require("git"):setup()
THEME.git_modified = ui.Style():fg("blue")
THEME.git_deleted = ui.Style():fg("red"):bold()
THEME.git_modified_sign = "M"
THEME.git_deleted_sign = "D"
