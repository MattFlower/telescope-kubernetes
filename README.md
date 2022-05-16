# telescope-kubernetes
Telescope add-on to allow editing of Objects in Kubernetes.  This is something you probably shouldn't really be doing that often, but it can be helpful when prototyping.

# Requirements
* Kubectl must be installed, it is used to fetch objects, apply, etc
* yq must be installed (apt install yq, brew install yq, or similar depending on your OS)


# Installation
1. Install [https://github.com/nvim-telescope/telescope.nvim](Telescope) first.
2. Using the Plugin manager of your choice, install telescope-kubernetes:

    Vim-Plug
    ```
    Plug 'MattFlower/telescope-kubernetes'
    ```

    Packer
    ```
    use 'MattFlower/telescope-kubernetes'
    ```
3. Add the following to your init.lua:
    ```lua
    require("telescope").load_extension("k8s") 
    ```
    
# Usage
Run the following:
```
:Telescope k8s
```

Select a kubernetes object to open a new tab with source for that object.  If desired, modify the buffer and run ```:KubeApply``` to apply the changes to kubernetes.
```
```


# Configuration when things go wrong

The following set custom values for configuration fields.  The listed values are the defaults.
```lua
require("telescope").setup {
  extensions = {
    k8s = {
      kubectl_location = "/opt/homebrew/bin/kubectl",
      yq_location = "/opt/homebrew/bin/yq",
      object_types = { "pod", "secret", "deployment", "service", "daemonset", "replicaset", "statefulset", "persistentvolume", "persistentvolumeclaim" },
      fields_to_filter = { 
        ".metadata.annotations",
        ".metadata.creationTimestamp",
        ".metadata.resourceVersion",
        ".metadata.selfLink",
        ".metadata.uid",
      }
    }
  }
}
```

| Field Name       | What it Does |
| ---------------- | ------------ |
| kubectl_location | kubectl provides all the data that is used for this plugin.  When the extension starts up it looks for kubectl in /usr/bin/kubectl, /usr/local/bin/kubectl, and /opt/homebrew/bin/kubectl.  If it can't find it in one of those locations, or if you want to specify a different one, specify the absolute path to the kubectl executable. |
| object_types     | The type of objects we will list from kubernetes.  We won't load any other types |
| fields_to_filter | These fields will not appear in the source of any object you select. |


# Things to do:

- [X] Get the basics working on my own machine
  - [X] Arbitrary list of Kubernetes objects are returned in a telescope list
  - [X] On selection of an object, pop open a new tab with the source inside
- [X] Make the execution more configurable
  - [X] Location of kubectl needs to be configurable
- [X] Check to make sure that yq and kubectl are installed and make reasonable error messages
- [X] Commands to apply changes to the buffers back to kubernetes.  (Effectively kubectl apply -f %)

