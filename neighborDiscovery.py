from TestSim import TestSim

def main():
    # Get simulation ready to run.
    s = TestSim()

    # Before we do anything, lets simulate the network off.
    s.runTime(1)

    # Load the the layout of the network.
    s.loadTopo("long_line.topo")

    # Add a noise model to all of the motes.
    s.loadNoise("no_noise.txt")

    # Turn on all of the sensors.
    s.bootAll()

    # Add the main channels. These channels are declared in includes/channels.h
    s.addChannel(s.COMMAND_CHANNEL)
    s.addChannel(s.GENERAL_CHANNEL)
    s.addChannel(s.ROUTING_CHANNEL)
    s.addChannel(s.LOG_CHANNEL)

    # After sending a ping, simulate a little to prevent collision.
    
    s.runTime(100)

    # Print all neighbors in Topology
    for i in range(s.numMote + 1):
        s.runTime(20)
        s.neighborDMP(i)

if __name__ == '__main__':
    main()
