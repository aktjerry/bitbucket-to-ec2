#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

cd /home/ubuntu/helloworld/

#install forever script 
npm install forever -g

# install node dependencies 
npm install 

# build app 

npm run build

#start server.js 
#forever -l -s start server.js 

node server.js & 