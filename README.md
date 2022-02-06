# telescope-kubernetes
Telescope add on to allow editing of Objects in Kubernetes

This is currently a work in progress -- don't use it yet.

# Requirements
* Kubectl must be installed, it is used to fetch objects, apply, etc
* jq must be installed

# Installation
1. Install [https://github.com/nvim-telescope/telescope.nvim](Telescope) first.
2. Using the Plugin manager of your choice, install telescope-kubernetes:

    Plug 'MattFlower/telescope-kubernetes'
    use 'MattFlower/telescope-kubernetes'
    etc.

3. Add the following to your init.lua
    require('telescope').load_extension('k8s')
    
# Usage
Run the following:

    :Telescope k8s

# Things to do:

- [X] Get the basics working on my own machine
  - [X] Arbitrary list of Kubernetes objects are returned in a telescope list
  - [X] On selection of an object, pop open a new tab with the source inside
- [ ] Make the execution more configurable
  - [ ] Location of kubectl needs to be configurable
- [ ] Check to make sure that jq and kubectl are installed and make reasonable error messages
- [ ] Commands to apply changes to the buffers back to kubernetes.  (Effectively kubectl apply -f %)

