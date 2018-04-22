# NANO Node & NANO Node Monitor Dockerized stack

### **Description**

This will build and deploy the following containers on your Docker host:

* **nano-node** -- This is the official NANO node created from the official Docker Image (RPC is enabled but not publicly accessible)
* **nano-node-monitor** -- This is the popular NANO Node Monitor PHP application based on [Nano Tools Docker image](https://hub.docker.com/r/nanotools/nanonodemonitor/).

#### **Directory Structure**

This will be your directory structure _after_ you've spinned up the containers:

```
+-- docker-compose.yml
+-- nano-node-monitor <mounted config file>
+-- nano-node <mounted config file, database files and logs>
+-- readme.md <this file>
```

### **Setup instructions using Docker natively (Windows 10/Linux/Mac)**

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

### **Credits**

* **[Nanocurrency](https://github.com/nanocurrency/raiblocks)**
* **[NANO Node Monitor](https://github.com/NanoTools/nanoNodeMonitor)**