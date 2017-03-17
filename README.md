# Chocophile
### ***A small utility to quickly export and re-install or move a Chocolatey environment.***

## What does it do?
Basically, this will allow you to export a .Chocofile that lists your currently installed Chocolatey packages. You can then take that file to any other machine which has also Chocophile installed and then automagically install all the packages listed in the .Chocofile.

Chocophile is (hopefully) to Chocolatey what Brewfiles are to Homebrew.

## Why?
1. Uniformity

    You and your team can all have the same Chocolatey environment. It's just as easy to get back to work after doing a re-install of Chocolatey or even Windows.

3. Seperability
    
    You can have multiple .Chocofiles to seperate your environments. One for work, one for home? One for dev tools, one for deployment tools? Or seperate your development packages from your media packages, or your utility packages from your... you get the idea.

4. Revertablity

    Only need to install some packages temporarily? Not an issue; you can cleanly uninstall a particular environment, whilst leaving all other packages untouched.

## Usage
```sh
# All Chocophile commands are one-liners
# Most commands have a shortened alternative (usually one letter)

# export
chocophile e
# confirm all prompts & export to dev.Chocofile
chocophile export -y -chocofileName dev

# install
chocophile i
chocophile install -chocofileName dev

# uninstall
chocophile uninstall
chocophile u -chocofileName dev

# add
chocophile a sumatrapdf
chocophile a git,git-lfs
chocophile add googlechrome,firefox,flashplayerplugin -chocofileName browsers

# remove
chocophile r googlechrome -chocofileName browsers
```