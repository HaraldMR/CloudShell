-- Helpers shared by the other config files

HOME = os.getenv("HOME")

function file_exists(path)
	local file = io.open(path, "r")
	if file then
		file:close()
		return true
	end
	return false
end

function dofile_if_exists(path)
	if file_exists(path) then
		dofile(path)
	end
end

-- Workspace `i` within the current group of `workspaceGroupSize` workspaces
-- (Super+1 on workspace 12 goes to 11, not 1)
function workspace_in_group(i)
	local current = hl.get_active_workspace().id
	return math.floor((current - 1) / workspaceGroupSize) * workspaceGroupSize + i
end
