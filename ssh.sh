#!/usr/bin/expect

set ip1 192.168.10.
set ip2 192

if { $argc > 0 } {
    set ip2 [lindex $argv 0]
}
set ip3 $ip1$ip2

set passwd rgbd123gp
set timeout 3
#spawn ssh root@192.168.10.192
spawn ssh root@$ip3

expect "*password:"
send "$passwd\r"

interact

