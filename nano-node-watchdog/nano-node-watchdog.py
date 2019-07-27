#!/usr/bin/python3

# adapted from https://github.com/dbachm123/nanoNodeScripts

import requests
import docker
import time
import glob
import os
import re
from datetime import datetime

# -----------------------------------------------------------------------
# some global constants - adapt these to your local node setup
# -----------------------------------------------------------------------
node_ip = 'nano-node'  # node's local IP
node_port = '7076'  # RPC port
log_file = "/opt/nanoNodeWatchdog/log/watchdog.log"  # log file for this script
node_log_dir = "/root/Nano/log"  # the log directory of the Nano node
# -----------------------------------------------------------------------

# test whether RPC is responsive
def testRPC(ip, port, logFile):
    # test RPC
    try:
        data = '{"action": "version"}'
        response = requests.post('http://{}:{}'.format(ip,port), data=data, timeout=5)
        return response.status_code == requests.codes.ok
    except Exception as e:
        log("RPC not available", logFile)
        return False

# test when the latest vote occured
def testVoting(ip, port, latestNodeLog, logFile):
    # maximum allowed time in seconds since last vote
    maxSecondsSinceLastVote = 5 * 60; # 5 minutes

    # check for the timestamp of the following message in the log
    msgInLog = "was confirmed to peers";

    # read file line by line; start at the back
    with open(latestNodeLog) as fp:
        cnt = 0
        for line in reversed(list(fp)):
            if msgInLog in line:
                # found a line --> extract time stamp
                # line is something like:
                # [[2018-04-13 08:37:48.001414]: Block D84B7B...  was confirmed to peers

                match = re.search(r'\[(.*?)\]', line)
                if match:
                    timestamp = match.group(1)
                    if timestamp:
                        # convert timestamp to datetime object
                        dateFormat = '%Y-%m-%d %H:%M:%S.%f'
                        voteTime = datetime.strptime(timestamp, dateFormat)

                        # check when the last vote was
                        now = datetime.now()
                        lastVoteSecondsAgo = (now - voteTime).total_seconds()
                        if (lastVoteSecondsAgo > maxSecondsSinceLastVote):
                            log("Last vote was {} seconds ago".format(lastVoteSecondsAgo), logFile);
                            return False;
                break
    return True

# log a message to logFile
def log(message, logFile):
    now = datetime.now()
    print("{} ::: {}".format(now, message), file=open(logFile, "a"))

# check whether the node is alive
def nodeAlive(ip, port, latestNodeLog, logFile):
    # run all tests
    ret = True;
    ret = ret & testRPC(ip, port, logFile);
    ret = ret & testVoting(ip, port, latestNodeLog, logFile);
    return ret

# find latest file in directory
def findLatestFileInDir(dir, logFile):
    log('Log directory: ' + dir, logFile);
    list_of_files = glob.glob(dir+'/*.log')
    log('Log files found: ' + ' '.join(list_of_files), logFile);
    latest_file = max(list_of_files, key=os.path.getctime)
    log('Latest logfile: ' + logFile, logFile);
    return latest_file

# check whether node is alive and restart if it is not
def checkOnNode():

    # find latest log file in the node's log dir
    latest_node_log = findLatestFileInDir(node_log_dir, log_file)

    if not nodeAlive(node_ip, node_port, latest_node_log, log_file):
        log("Node appears to be stuck!", log_file)
        restartNodeContainer(log_file)
    else:
        log("Node is alive, no need for action. Sleeping for another hour...", log_file)

# restart node container, check on it again in a minute
def restartNodeContainer(logFile):
    # log and restart
    log("Restarting node container...", logFile)

    # restart node container
    client = docker.from_env()
    node = client.containers.get('nano-node')
    node.restart()

    log("Node container restarted successfully. Will check on it again in a minute...", logFile)
    time.sleep(60)
    checkOnNode()

# main
def main():

    log("NANO Node Watchdog initialized. Will check on NANO node status in a minute...", log_file)

    # sleep for a minute until node has been fully initialized too
    time.sleep(60)

    # trigger watcher every hour starting now
    delta_min = datetime.now().minute
    while 1:
        now_min = datetime.now().minute

        if delta_min == now_min:
            log("Checking on node...", log_file)
            checkOnNode()

        # sleep for a minute
        time.sleep(60)

if __name__ == "__main__":
    main()
