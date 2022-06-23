#!awk

BEGIN {print "ok so far"}

(
    print "oops, this should be in curly braces"
)

END {print "sad trombone"}
