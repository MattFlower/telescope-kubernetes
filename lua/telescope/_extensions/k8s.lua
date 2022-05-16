local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local conf = require('telescope.config').values
local entry_display = require('telescope.pickers.entry_display')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local telescope = require('telescope')

local kubectl_location = ""
local object_types = {}
local fields_to_filter = {}


-- Construct command to fetch all kubernetes objects 
-- of the types listed in object_types out of kubernetes 
-- using kubectl.
local function get_fetch_all_objects_command()
  return {
    kubectl_location,
    "get",
    table.concat(object_types,","),
    "--no-headers",
    "--all-namespaces",
    "-o",
    "custom-columns=TYPE:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace",
    "--sort-by=.metadata.name",
  }
end

-- Construct the command to fetch a single object out 
-- of kubernetes.  This is used for the preview
local function get_fetch_object_command(entry)
  return {
    kubectl_location,
    "get",
    entry.type,
    "--show-managed-fields=false",
    "-n",
    entry.namespace,
    entry.name,
    "-o",
    "yaml"
  }
end

-- Make a single "line" of data for telescope
local entry_maker = function(opts)
  opts = opts or {}

  -- Define the layout of the "columns" in telescope
  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 10 },
      { width = 20 },
      { remaining = true },
    },
  }

  -- Define the fields in order that they'll display in telescope
  local make_display = function(entry)
    return displayer {
      entry.type,
      entry.namespace,
      entry.name,
    }
  end

  return function(entry)
    if entry == "" then
      return nil
    end

    -- We have to parse the fields from the output of kubectl
    local type, name, namespace = string.match(entry, "([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)")

    -- This table represents an "entry", with everything to display it and to 
    -- use it if it is selected.
    return {
      value = { name = name, namespace = namespace, type = type },
      ordinal = name,
      display = make_display,
      name = name,
      namespace = namespace,
      type = type,
    }
  end
end

local function file_exists(name)
  local f = io.open(name, "r")
  if f ~= nil then io.close(f) return true else return false end
end

local function which(command)
  local result = vim.cmd("!which " .. command)
  if result ~= nil then return false else return result end
end

-- Given a list of filenames, return the first one that actually exists in the filesystem
local function first_existing_file(files)
  for key, value in ipairs(files) do
    if file_exists(value) then
      return value
    end
  end
end


local kubernetes_objects = function(opts)
  opts = opts or {}

  -- Provide the method that will turn kubectl results into "entry" objects.
  opts.entry_maker = entry_maker()

  -- If a single object is selected, fetch the full details of it.
  opts.get_command = function(entry, status)
    status = status or {}
    return get_fetch_object_command(entry)
  end

  pickers.new(opts, {
    prompt_title = "Kubernetes Objects",

    -- Job to fetch all objects from kuberentes
    finder = finders.new_oneshot_job(get_fetch_all_objects_command(), opts),
    sorter = conf.generic_sorter(opts),
    -- If we want to open the object we run a terminal command.  We use this previewer because it runs a terminal command
    previewer = previewers.new_termopen_previewer(opts),
    -- This represents what happens if we select an object
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local entry = selection.value
        local temp_file_name = entry.name .. '.yml'
        -- Create a new tab and fetch the object into that tab
        if vim.fn.bufexists(temp_file_name) == 1 then
          vim.cmd(":bunload " .. temp_file_name)  
        end
        local command = ":tabnew " .. temp_file_name .. " | 0r !" .. kubectl_location .. " get " .. entry.type .. " --show-managed-fields=false -n " .. entry.namespace .. " " .. entry.name .. " -o yaml | yq e 'del(.metadata.annotations) | del(.metadata.creationTimestamp) | del(.metadata.resourceVersion) | del(.metadata.selfLink) | del(.metadata.uid)' - "
        vim.cmd(command)
        vim.cmd(":setlocal buftype=nofile")
      end)
      return true
    end,
  }):find()
end

vim.api.nvim_create_user_command("KubeApply", function ()
  local command = ":write !" .. kubectl_location .. " apply -f - "
  vim.cmd(command)
end, {})

return telescope.register_extension({
  setup = function(ext_config) 
    kubectl_location = ext_config.kubectl_location or which("kubectl") or first_existing_file({"/usr/bin/kubectl", "/usr/local/bin/kubectl", "/opt/homebrew/bin/kubectl"})
    assert(file_exists(kubectl_location), "kubectl_location points to a location that doesn't exist (" .. kubectl_location .. ").")

    object_types = ext_config.object_types or {'pod','secret','deployment','service','daemonset','replicaset','statefulset','persistentvolume','persistentvolumeclaim'}
    fields_to_filter = ext_config.fields_to_filter or {'.metadata.annotations', '.metadata.creationTimestamp', '.metadata.resourceVersion', '.metadata.selfLink', '.metadata.uid'}
  end,
  exports = {
    k8s = kubernetes_objects
  }
})

