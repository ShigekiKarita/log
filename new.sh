#!sh
./hugo new posts/$1 &&  emacsclient -nw -a "" -t content/posts/$1
