#!/bin/bash
#intall nvm 
sudo curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.8/install.sh | bash

#activate nvm (node version manager)
. ~/.nvm/nvm.sh

#install latest version of node with long term support  
nvm install --lts

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

node --version 
npm --version 