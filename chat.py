from TestSim import TestSim

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
    serverNode = 1
    serverPort = 80
    s.appServer(serverNode, serverPort) 
    catalog[serverNode] = (serverPort, "server")
    s.runTime(60)

    openNode = 2
    f = open("commands.txt", "r")
    for x in f:
        messages = x.split("\\r\\n")
        for m in messages[:len(messages) - 1]:
            message = m.split(" ")
            if message[0] == "hello":
                nodeId = openNode if openNode != 2 else catalog.keys()[-1] + 1
                if nodeId > s.numMote:
                    print("There are no more open nodes to establish a conection with\n")
                    break
                s.appClient(nodeId, message[1], message[2])
                catalog[nodeId] = (message[1], message[2])
            elif message[0] == "msg":
                s.broadcastingMessage(" ".join(message[1:]))
            elif message[0] == "whisper":
                s.uincastMessage([c for c in catalog.keys() if catalog[c][0] == message[1]][0], " ".join(message[2:]))
            elif message[0] == "listusr":
                s.printUsers()
            elif message[0] == "close":
                s.clientClose(message[1], serverNode, message[2], serverPort)
                del catalog[message[1]]
                openNode = message[1]
            elif message[0] == "stop":
                print("Closing Server!!!")
                return
            else:
                print("Bad argument")
                break
            s.runTime(1)
            s.runTime(1000)


if __name__ == '__main__':
    main()
