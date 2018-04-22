# NANO Node Docker stack

### **Description**

This will build and deploy the following containers on your Docker host:

* **nano-node** -- This is the official NANO node created from the official [NANO Docker Image](https://hub.docker.com/r/nanocurrency/nano/) (RPC is enabled but not publicly exposed).
* **nano-node-monitor** -- This is the popular NANO Node Monitor PHP application based on [NanoTools's Docker image](https://hub.docker.com/r/nanotools/nanonodemonitor/).
* **nano-node-watchdog** -- This is custom lightweight watcher container checking on node's health status every hour (checking code adapted from [dbachm123's nanoNodeScripts](https://github.com/dbachm123/nanoNodeScripts).

#### **Directory Structure**

This will be your directory structure _after_ you've spinned up the containers:

```
+-- docker-compose.yml
+-- nano-node <mounted config file, database files and logs>
+-- nano-node-monitor <mounted config file>
+-- nano-node-watchdog
|   +-- Dockerfile
|   +-- nano-node-watchdog.py
|   +-- log <mounted watchdog logfile directory>
+-- readme.md <this file>
```

### **Setup instructions using Docker "natively" (Windows 10/Linux/Mac)**

**Prerequisites:** 

* Depending on your OS, the appropriate version of Docker Community Edition has to be installed on your machine.  ([Download Docker Community Edition](https://www.docker.com/community-edition#/download))
* Latest version of Docker-compose should be installed as well. ([Install Docker Compose](https://docs.docker.com/compose/install/))
* Of course [Git](https://git-scm.com/) and a text editor.

**Installation steps:** 

1. Clone this repository inside an empty directory in which your OS user has full write access:

```
$ git clone https://github.com/lephleg/nano-node-monitor-docker-stack.git .
```

2. Pull the Docker images and run the containers:

```
$ docker-compose up -d
```

3. If all went well, you should now have the directory structure described in the section above and your containers runnning. Open the the NANO Node Monitor config file found in `nano-node-monitor/config.php`. Minimum configuration setup requires the following options set:

```
// the NANO node Docker container hostname
$nanoNodeRPCIP   = 'nano-node';

// your NANO node account
$nanoNodeAccount = 'xrb_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'; 
```

5. That's it! Navigate to port 80 on your host to access the NANO Node Monitor dashboard.

### **NANO Node Watchdog**

This version of the stack also includes a node watcher in a separate container. 

The **nano-node-watchdog** container will perform a basic node health-check every hour (starting from the time it was first initialized). The check results are based:

* on node's RPC responsiveness 
* on node's last voting activity 

If the node found to be stuck, an automatic restart will be triggered for the **nano-node** container, along with another health check after a minute to ensure its uptime.

_**TODO**_: Send an email notification to the onwer if the node keeps crashing.

### **Credits**

* **[Nanocurrency](https://github.com/nanocurrency/raiblocks)**
* **[NANO Node Monitor](https://github.com/NanoTools/nanoNodeMonitor)**
* **[nanoNodeScripts](https://github.com/dbachm123/nanoNodeScripts)**