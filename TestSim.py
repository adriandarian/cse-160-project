# ANDES Lab - University of California, Merced
# Author: UCM ANDES Lab
# $Author: abeltran2 $
# $LastChangedDate: 2014-08-31 16:06:26 -0700 (Sun, 31 Aug 2014) $
#! /usr/bin/python
import sys
from TOSSIM import *
from CommandMsg import *

class TestSim:
    moteids = []
    # COMMAND TYPES
    CMD_PING = 0
    CMD_NEIGHBOR_DUMP = 1
    CMD_ROUTE_DUMP = 3
    CMD_TEST_CLIENT = 4
    CMD_TEST_SERVER = 5
    CMD_CLIENT_CLOSE = 6
    CMD_APP_SERVER = 10
    CMD_APP_CLIENT = 11
    CMD_APP_BROADCAST_MESSAGE = 12
    CMD_APP_UNICAST_MESSAGE = 13
    CMD_APP_PRINT_USERS = 14

    # CHANNELS - see includes/channels.h
    COMMAND_CHANNEL = "command"
    GENERAL_CHANNEL = "general"
    LOG_CHANNEL = "log"

    # Project 1
    NEIGHBOR_CHANNEL = "neighbor"
    FLOODING_CHANNEL = "flooding"

    # Project 2
    ROUTING_CHANNEL = "routing"

    # Project 3
    TRANSPORT_CHANNEL = "transport"

    # Project 4
    APP_CHANNEL = "app"

    # Personal Debuggin Channels for some of the additional models implemented.
    HASHMAP_CHANNEL = "hashmap"

    # Initialize Vars
    numMote = 0
    serverAddress = 0
    serverPort = 0

    def __init__(self):
        self.t = Tossim([])
        self.r = self.t.radio()

        # Create a Command Packet
        self.msg = CommandMsg()
        self.pkt = self.t.newPacket()
        self.pkt.setType(self.msg.get_amType())

    # Load a topo file and use it.
    def loadTopo(self, topoFile):
        print('Creating Topo!')
        # Read topology file.
        topoFile = 'topo/' + topoFile
        f = open(topoFile, "r")
        self.numMote = int(f.readline())
        print('Number of Motes {0}'.format(self.numMote))
        for line in f:
            s = line.split()
            if s:
                print("S: {0}, N: {1}, Noise: {2}".format(s[0], s[1], s[2]))
                self.r.add(int(s[0]), int(s[1]), float(s[2]))
                if not int(s[0]) in self.moteids:
                    self.moteids = self.moteids + [int(s[0])]
                if not int(s[1]) in self.moteids:
                    self.moteids = self.moteids + [int(s[1])]

    # Load a noise file and apply it.
    def loadNoise(self, noiseFile):
        if self.numMote == 0:
            print("Create a topo first")
            return

        # Get and Create a Noise Model
        noiseFile = 'noise/' + noiseFile
        noise = open(noiseFile, "r")
        for line in noise:
            str1 = line.strip()
            if str1:
                val = int(str1)
            for i in self.moteids:
                self.t.getNode(i).addNoiseTraceReading(val)

        for i in self.moteids:
            print("Creating noise model for {0}".format(i))
            self.t.getNode(i).createNoiseModel()

    def bootNode(self, nodeID):
        if self.numMote == 0:
            print("Create a topo first")
            return
        self.t.getNode(nodeID).bootAtTime(1333 * nodeID)

    def bootAll(self):
        i = 0
        for i in self.moteids:
            self.bootNode(i)

    def moteOff(self, nodeID):
        self.t.getNode(nodeID).turnOff()

    def moteOn(self, nodeID):
        self.t.getNode(nodeID).turnOn()

    def run(self, ticks):
        for i in range(ticks):
            self.t.runNextEvent()

    # Rough run time. tickPerSecond does not work.
    def runTime(self, amount):
        self.run(amount * 1000)

    # Generic Command
    def sendCMD(self, ID, dest, payloadStr):
        self.msg.set_dest(dest)
        self.msg.set_id(ID)
        self.msg.setString_payload(payloadStr)

        self.pkt.setData(self.msg.data)
        self.pkt.setDestination(dest)
        self.pkt.deliver(dest, self.t.time() + 5)

    def ping(self, source, destination, message):
        self.sendCMD(self.CMD_PING, source, "{0}{1}".format(chr(destination), message))

    def neighborDMP(self, destination):
        self.sendCMD(self.CMD_NEIGHBOR_DUMP, destination, "neighbor command")

    def routeDMP(self, destination):
        self.sendCMD(self.CMD_ROUTE_DUMP, destination, "routing command")

    def addChannel(self, channelName, out=sys.stdout):
        print('Adding Channel {0}'.format(channelName))
        self.t.addChannel(channelName, out)

    def testServer(self, address, port):
        self.sendCMD(self.CMD_TEST_SERVER, address, "{0}".format(chr(port)))
    
    def testClient(self, clientAddress, destination, sourcePort, destinationPort, transfer):
        self.sendCMD(self.CMD_TEST_CLIENT, clientAddress, "{0}{1}{2}{3}{4}".format(chr(destination), chr(sourcePort), chr(destinationPort), chr(transfer >> 8), chr(transfer & 0xFF)))

    def clientClose(self, clientAddress, destination, sourcePort, destinationPort):
        self.sendCMD(self.CMD_CLIENT_CLOSE, int(clientAddress), "{0}{1}{2}".format(chr(destination), chr(int(sourcePort)), chr(int(destinationPort))))

    def appServer(self, address, port):
        self.serverAddress = address
        self.serverPort = port
        self.sendCMD(self.CMD_APP_SERVER, address, "{0}".format(chr(port)))

    def appClient(self, clientAddress, username, clientPort):
        self.sendCMD(self.CMD_APP_CLIENT, clientAddress, "{0}{1}{2}{3}".format(chr(self.serverAddress), chr(int(clientPort)), chr(self.serverPort), username))

    def broadcastingMessage(self, message):
        self.sendCMD(self.CMD_APP_BROADCAST_MESSAGE, self.serverAddress, "{0}".format(message))

    def uincastMessage(self, clientAddress, message):
        self.sendCMD(self.CMD_APP_UNICAST_MESSAGE, self.serverAddress, "{0}{1}".format(chr(clientAddress), message))

    def printUsers(self):
        self.sendCMD(self.CMD_APP_PRINT_USERS, self.serverAddress, "listusr\r\n")