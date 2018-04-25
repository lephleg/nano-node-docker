# NANO Node Docker stack (with optional SSL support)

### **Description**

This will build and deploy the following containers on your Docker host:

* **nano-node** -- This is the official NANO node created from the official [NANO Docker Image](https://hub.docker.com/r/nanocurrency/nano/) (RPC is enabled but not publicly exposed).
* **nano-node-monitor** -- This is the popular NANO Node Monitor PHP application based on [NanoTools's Docker image](https://hub.docker.com/r/nanotools/nanonodemonitor/).
* **nano-node-watchdog** -- This is custom lightweight watcher container checking on node's health status every hour (checking code adapted from [dbachm123's nanoNodeScripts](https://github.com/dbachm123/nanoNodeScripts)).

#### **SSL Support with Let's Encrypt**

Optionally, if a domain name is available for the host, NANO Docker Stack can also serve NANO Node Monitor through an secure connection (HTTPS). If this feature is enabled (scroll below for Let's Encrypt setup instructions), the stack also includes the following containers:

* **nginx-proxy** -- This is an instance of the popular Nginx web server running in a reverse proxy setup, serving as a gateway for all incoming requests to your host.

* **nginx-proxy-letsencrypt** -- This is a lightweight companion container for the nginx-proxy. It allows the creation/renewal of Let's Encrypt certificates automatically.

#### **Directory Structure**

This will be your directory structure _after_ you've spinned up the containers:

```
+-- docker-compose.yml
+-- docker-compose.letsencrypt.yml
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

**Basic Installation steps (plain HTTP) for plain IP served hosts:** 

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

**That's it!** Navigate to port 80 on your host to access the NANO Node Monitor dashboard.

___

**SSL Installation steps (secure HTTPS) for domain/subdomain served hosts:** 

The following istallation steps will deploy NANO Docker stack for usage with encrypted connections.

1. Clone this repository inside an empty directory in which your OS user has full write access:

    ```
    $ git clone https://github.com/lephleg/nano-node-monitor-docker-stack.git .
    ```

2. Edit and fill the following lines of the `docker-compose.letsencrypt.yml` file with your domain/subdomain name and your email address (will be used by Let's Encrypt to warn you of impeding certificate expiration):

    ```
        environment:
        - VIRTUAL_HOST=mydomain.com
        - LETSENCRYPT_HOST=mydomain.com
        - LETSENCRYPT_EMAIL=myemailaddress@mail.com
    ```

    ```
        environment:
        - DEFAULT_HOST=mydomain.com
    ```

3. Pull the Docker images and run the containers using the Let's Encrypt enabled compose file (_Note: The first time this is launched it takes several minutes to complete, so please be patient_):

    ```
    $ docker-compose -f docker-compose.letsencrypt.yml up -d
    ```

4. Edit the configuration file as in basic installation (found in `nano-node-monitor/config.php`). Minimum configuration setup requires the following options set:

    ```
    // the NANO node Docker container hostname
    $nanoNodeRPCIP   = 'nano-node';

    // your NANO node account
    $nanoNodeAccount = 'xrb_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'; 
    ```

5. **Optional:** If you're using an third-party firewall like [UFW](https://help.ubuntu.com/community/UFW) and have already applied the iptables security fix [How to fix the Docker and UFW security flaw](https://www.techrepublic.com/article/how-to-fix-the-docker-and-ufw-security-flaw/) (_highly recommended_), you should also verify that the port 443 required by the SSL setup is accepting incoming connections. In case of UFW the required commands to enable the port and reload your firewall are the following:

    ```
    $ sudo ufw allow 443
    $ sudo ufw reload
    ```

**Done!** Navigate to **https://mydomain.com** to access your SSL encrypted NANO Node Monitor dashboard, as well as its API endpoint (https://mydomain.com/api.php). You can now serve your NANO node data with robust security!


#### **Additional Notes/Tools**: 

* The `VIRTUAL_HOST` (along with `LETSENCRYPT_HOST` and `DEFAULT_HOST`) must a reachable domain for Let's Encrypt to be able to validate the challenge and provide the certificate. Be sure to configure your DNS records properly before triggering the installation.
* Every hour (3600 seconds) the certificates are checked and every certificate that will expire in the next 30 days (90 days / 3) are renewed.
* To display informations about your existing certificates, use the following command:

    ```
    $ docker exec nginx-proxy-letsencrypt /app/cert_status
    ```

* To force the lnginx-proxy-letsencrypt container to renew all certificates that are currently in use use the following command:

    ```
    $ docker exec nginx-proxy-letsencrypt /app/force_renew
    ```

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
* **[jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy)**
* **[JrCs/docker-letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion)**