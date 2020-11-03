from TestSim import TestSim

def main():
    # Get simulation ready to run.
    s = TestSim()

    # Before we do anything, lets simulate the network off.
    s.runTime(1)

    # Load the the layout of the network.
    s.loadTopo("simple.topo")

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt")

    # Turn on all of the sensors.
    s.bootAll()

    # Add the main channels. These channels are declared in includes/channels.h
    s.addChannel(s.COMMAND_CHANNEL)
    s.addChannel(s.GENERAL_CHANNEL)
    s.addChannel(s.NEIGHBOR_CHANNEL)
    s.addChannel(s.ROUTING_CHANNEL)
    s.addChannel(s.TRANSPORT_CHANNEL)
    s.addChannel(s.LOG_CHANNEL)

    # After sending a ping, simulate a little to prevent collision.
    s.runTime(100)
    for i in range(s.numMote + 1):
        s.runTime(20)
        s.routeDMP(i)

    s.runTime(300)
    s.testServer(1, 80) # @params address, port 
    s.runTime(60)
    # print("about to start a new client")
    # s.testClient(4, 3000, 80, 1000) # @params destination, srcPort, destPort, transfer 
    # s.runTime(1)
    # s.runTime(1000)

    # s.clientClose(4, 1, 3000, 80) # @params clientAddress, destination, srcPort, destPort
    # s.runTime(1)
    # s.runTime(1000)



if __name__ == '__main__':
    main()
