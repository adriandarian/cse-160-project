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
    # s.addChannel(s.FLOODING_CHANNEL)
    s.addChannel(s.LOG_CHANNEL)

    # After sending a ping, simulate a little to prevent collision.
    s.runTime(100)
    s.ping(1, 3, "1->3")
    s.runTime(10)
    s.ping(2, 1, "2->1")
    s.runTime(10)
    s.ping(2, 3, "2->3")
    s.runTime(10)
    s.ping(3, 1, "3->1")
    s.runTime(10)
    s.ping(3, 2, "3->2")
    s.runTime(20)
    s.ping(1, 5, "1->5")
    s.runTime(20)
    s.ping(1, 5, "1->5")
    s.runTime(20) 

if __name__ == '__main__':
    main()
