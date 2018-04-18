# NANO Node & NANO Node Monitor Dockerized stack

### **Description**

This will build and deploy the following containers on your Docker host:

* **nano-node** -- This is the official NANO node created from the official Docker Image (RPC is enabled but not publicly accessible)
* **nano-monitor** -- This is the popular NANO Node Monitor PHP application built with a custom image containing: PHP7.2, Nginx, Composer & Supervisor.

#### **Directory Structure**
```
+-- RaiBlocks <mounted from the NANO node container>
+-- resources
|   +-- default
|   +-- nginx.conf
|   +-- supervisord.conf
|   +-- www.conf
+-- Dockerfile
+-- docker-compose.yml
+-- readme.md <this file>
+-- monitor <NANO node monitor repository root and mounted inside nano-monitor container>
```

### **Setup instructions using Docker natively (Windows 10/Linux/Mac)**

**Prerequisites:** 

* Depending on your OS, the appropriate version of Docker Community Edition has to be installed on your machine.  ([Download Docker Community Edition](https://www.docker.com/community-edition#/download))
* Latest version of Docker-compose should be installed as well. ([Install Docker Compose](https://docs.docker.com/compose/install/))

**Installation steps:** 

1. Clone this repository inside an empty directory in which your OS user has full write access:

```
$ git clone https://github.com/lephleg/nano-node-monitor-docker.git .
```

2. Clone the original NANO Node Monitor source code repository in a new **monitor** folder with the command:

```
$ git clone https://github.com/NanoTools/nanoNodeMonitor.git src
```

3. You should now have the directory structure described above. Copy and edit the monitor config file:

```
$ cp src/modules/config.sample.php src/modules/config.php 
$ nano src/modules/config.php
```

4. Create an external docker network to for your node to communicate with your monitor:

```
$ docker network create nano_node_network
```

5. Build and run your containers:

```
$ docker-compose up -d
```

7. That's it! Navigate to port 80 on your host to access the NANO Node Monitor dashboard.

### **Credits**

* **[Nanocurrency](https://github.com/nanocurrency/raiblocks)**
* **[NANO Node Monitor](https://github.com/NanoTools/nanoNodeMonitor)**