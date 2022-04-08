#!/bin/bash
/Applications/tic80.app/Contents/MacOS/tic80 --skip --fs . --cmd \
"load dyke.lua & \
export html release/dyker_html & \
export win release/dyker_win & \
export linux release/dyker_linux & \
export mac release/dyker_mac & \
save release/dyker.png & \
exit"