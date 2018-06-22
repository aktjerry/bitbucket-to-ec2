#!/bin/bash
# stop any old running servers 
 killall -s KILL node -q || true 

# remove older app files
cd /home/ubuntu/
rm -rf  helloworld/