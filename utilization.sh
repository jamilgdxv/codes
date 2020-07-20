#!/usr/bin/expect

set timeout 120

set user [lindex $argv 1]

set password [lindex $argv 2]

set host [lindex $argv 0]

spawn ssh $host -l $user

expect "password: "

send "$password\r"

expect "#"


send "show interface utilization | include Channel|<--|75%|76%|77%|78%|79%|80%|81%|82%|83%|84%|85%|86%|87%|88%|89%|90%|91%|92%|93%|94%|95%|96%|97%|98%|99%|100%"

send "\r"

expect "#"

send "quit"

send "\r"

expect eof