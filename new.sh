#!sh
./hugo new $1 &&  emacsclient -nw -a "" -t content/$1
