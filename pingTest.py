from TestSim import TestSim

def main():
    # Get simulation ready to run.
    s = TestSim()

    # Before we do anything, lets simulate the network off.
    s.runTime(1)

    # Load the the layout of the network.
    s.loadTopo("house.topo")

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt")

    # Turn on all of the sensors.
    s.bootAll()

    # Add the main channels. These channels are declared in includes/channels.h
    s.addChannel(s.COMMAND_CHANNEL)
    s.addChannel(s.GENERAL_CHANNEL)
    #s.addChannel(s.FLOODING_CHANNEL)
    # s.addChannel(s.NEIGHBOR_CHANNEL)
    s.addChannel(s.ROUTING_CHANNEL)
    s.addChannel(s.LOG_CHANNEL)

    # After sending a ping, simulate a little to prevent collision.
    s.runTime(20)

    s.ping(1, 5, "1->5")
    s.runTime(20)
    # s.ping(1, 5, "1->5")
    # s.runTime(20)
    # s.ping(1, 5, "1->5")
    # s.runTime(20)
    # s.ping(1, 5, "1->5")
    # s.runTime(20)

    # Print all neighbors in Topology
    # for i in range(s.numMote + 1):
    #     s.runTime(20)
    #     s.neighborDMP(i)
    
    # Check Routing table
    s.runTime(20)
    s.routeDMP(0)

    s.runTime(20)


if __name__ == '__main__':
    main()
