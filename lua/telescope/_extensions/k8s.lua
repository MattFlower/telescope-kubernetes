local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local conf = require('telescope.config').values
local entry_display = require('telescope.pickers.entry_display')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local telescope = require('telescope')

local fetch_all_objects_command = {
  "/opt/homebrew/bin/kubectl",
  "get",
  "pod,secret,deployment,service,daemonset,replicaset,statefulset,persistentvolume,persistentvolumeclaim",
  "--no-headers",
  "--all_namespaces",
  "-o",
  "custom-columns=TYPE:.kind,NAME:.metadata.name,NAMESPACE:.metadata.namespace",
  "--sort-by=.metadata.name"}

local entry_maker = function(opts)
  opts = opts or {}

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 10 },
      { width = 20 },
      { remaining = true },
    },
  }

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

    local type, name, namespace = string.match(entry, "([^ ]+)[ ]+([^ ]+)[ ]+([^ ]+)")

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



local kubernetes_objects = function(opts)
  opts = opts or {}
  opts.entry_maker = entry_maker()
  local kubectl_objects = vim.F.if_nil(opts.kubectl_command, fetch_all_objects_command)
  opts.get_command = function(entry, status)
    status = status or {}
    return { '/opt/homebrew/bin/kubectl', 'get', entry.type, '--show-managed-fields=false', '-n', entry.namespace, entry.name, '-o', 'yaml'}
  end

  pickers.new(opts, {
    prompt_title = "Kubernetes",
    finder = finders.new_oneshot_job(kubectl_objects, opts),
    sorter = conf.generic_sorter(opts),
    previewer = previewers.new_termopen_previewer(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local entry = selection.value
        local temp_file_name = entry.name .. '.yml'
        local command = ":tabnew " .. temp_file_name .. " | r !/opt/homebrew/bin/kubectl get " .. entry.type .. " --show-managed-fields=false -n " .. entry.namespace .. " " .. entry.name .. " -o yaml | yq e 'del(.metadata.annotations) | del(.metadata.creationTimestamp) | del(.metadata.resourceVersion) | del(.metadata.selfLink) | del(.metadata.uid)' - "
        vim.cmd(command)
      end)
      return true
    end,
  }):find()
end


return telescope.register_extension({
  exports = {
    k8s = kubernetes_objects
  }
})

