<!-- Command to check the server performance and random hits -->

ab -n 1000 -c 100 https://login.test-prio.com/
 1225  clear
 1226  ab -n 1000 -c 100 https://login.prioticket.com
 1227  ab -n 1000 -c 100 https://login.test-prio.com
 1228  clear
 1229  ab -n 1000 -c 100 https://login.prioticket.com/
 1230  ab -n 1000 -c 100 https://marketplace.prioticket.com/