from TestSim import TestSim

def firstMissingNumber(arr):
    for x in range(0, len(arr)):
        if arr[x] == None:
            return x + 1
    return len(arr) + 1

def main():
    catalog = {}

    # Get simulation ready to run.
    s = TestSim()

    # Before we do anything, lets simulate the network off.
    s.runTime(1)

    # Load the the layout of the network.
    s.loadTopo("short_line.topo")

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt")

    # Turn on all of the sensors.
    s.bootAll()

    # Add the main channels. These channels are declared in includes/channels.h
    # s.addChannel(s.COMMAND_CHANNEL)
    # s.addChannel(s.GENERAL_CHANNEL)
    # s.addChannel(s.TRANSPORT_CHANNEL)
    # s.addChannel(s.APP_CHANNEL)
    # s.addChannel(s.LOG_CHANNEL)

    # After sending a ping, simulate a little to prevent collision.
    s.runTime(300)
    serverNode = 0
    serverPort = 255
    record = [None] * s.numMote

    f = open("commands.txt", "r")
    for x in f:
        messages = x.split("\\r\\n")
        for m in messages[:len(messages) - 1]:
            message = m.split(" ")
            if message[0] == "server":
                serverNode = int(message[1])
                serverPort = int(message[2])
                s.appServer(serverNode, serverPort) 
                catalog[serverNode] = (serverPort, "server")
                record[serverNode - 1] = serverNode
                s.runTime(60)
                break
            if serverNode > 0 and serverPort < 255:
                if message[0] == "hello":
                    nodeId = firstMissingNumber(record)
                    if nodeId > s.numMote:
                        print("There are no more open nodes to establish a conection with")
                        break
                    s.appClient(nodeId, message[1], message[2])
                    catalog[nodeId] = (message[1], message[2])
                    record[nodeId - 1] = nodeId
                elif message[0] == "msg":
                    s.broadcastingMessage(" ".join(message[1:]))
                elif message[0] == "whisper":
                    s.uincastMessage([c for c in catalog.keys() if catalog[c][0] == message[1]][0], " ".join(message[2:]))
                elif message[0] == "listusr":
                    s.printUsers()
                elif message[0] == "close":
                    s.clientClose(message[1], serverNode, message[2], serverPort)
                    del catalog[int(message[1])]
                    for idx, val in enumerate(record):
                        if val == int(message[1]):
                            record[idx] = None
                elif message[0] == "stop":
                    print("Closing Server!!!")
                    return
                else:
                    print("Bad argument")
                    break
                s.runTime(1)
                s.runTime(500)


if __name__ == '__main__':
    main()
