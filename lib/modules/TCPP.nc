/*
 * ~TCP Module~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/socket.h"
#include "../../includes/tcp.h"

module TCPP{
    provides interface TCP;

    // Modules
    uses interface Timer<TMilli> as ServerTimer;
    uses interface Timer<TMilli> as ClientTimer;
    uses interface Transport;

    // Data Structures
    uses interface List<uint8_t> as AcceptedSockets;
}

implementation{
    socket_t fd;
    uint16_t data;

    /*
     * #######################################
     *              Prototypes
     * #######################################
     */



    /*
     * #######################################
     *              Commands
     * #######################################
     */

    command void TCP.testServer(uint16_t address, uint8_t port) {
        socket_addr_t *socket_address;
        fd = call Transport.socket();
        dbg(TRANSPORT_CHANNEL, "received a socket\n");

        // Only source info
        socket_address->addr = address; // NODE_ID
        socket_address->port = port; 

        dbg(TRANSPORT_CHANNEL, "socket address: %hu, %hhu\n", socket_address->addr, socket_address->port);

        if (call Transport.bind(fd, socket_address) == SUCCESS) { 
            // call ServerTimer.startOneShot(ATTEMPT_CONNECTION_TIME);
            dbg(TRANSPORT_CHANNEL, "timer fired\n");
            return;
        }

        dbg(TRANSPORT_CHANNEL, "This should never happen\n");
    }

    command void TCP.testClient(uint16_t destination, uint8_t sourcePort, uint8_t destinationPort, uint16_t transfer) {
        // socket_addr_t *socket_address;
        // socket_addr_t *server_address;
        // fd = call Transport.socket();
        // dbg(TRANSPORT_CHANNEL, "Opening a Client socket relationship\n");

        // // Only source info.
        // socket_address->addr = TOS_NODE_ID;
        // socket_address->port = sourcePort;
        // call Transport.bind(fd, socket_address);

        // // Only dest info.
        // server_address->addr = destination;
        // server_address->port = destinationPort;

        // if (call Transport.connect(fd, server_address)) {
        //     call ClientTimer.startOneShot(CLIENT_WRITE_TIMER);
        //     data = transfer;
        // }
    }

    command void TCP.closeClient(uint16_t clientAddress, uint16_t destination, uint8_t sourcePort, uint8_t destinationPort) {
        // find fd associated with [client address], [srcPort], [destPort], [dest]
        // call Transport.close(fd);
    }

    /*
     * #######################################
     *              Events
     * #######################################
     */

    event void ServerTimer.fired() {
        socket_t newFd;
        uint16_t i;
        dbg(TRANSPORT_CHANNEL, "Attempting to accept socket\n");
        newFd = call Transport.accept(fd);

        dbg(TRANSPORT_CHANNEL, "Got a newFd from %hhu\n", fd);

        if (newFd != NULL) {
            dbg(TRANSPORT_CHANNEL, "adding a new socket to the acceptable sockets\n");
            call AcceptedSockets.pushback(newFd);
        }

        for (i = 0; i < call AcceptedSockets.size(); i++) {
            // read data and print
        }
    }

    event void ClientTimer.fired() {
        // if all data in buffer has been written or the buffer empty
        //     create new data for the buffer
        //     // data is from 0 to [transfer]
        // subtract the amount of data you were able to write(fd, buffer, buffer len)
    }

    /*
     * #######################################
     *              Methods
     * #######################################
     */
}