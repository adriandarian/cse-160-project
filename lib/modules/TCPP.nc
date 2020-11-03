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
        socket_addr_t socket_address;
        fd = call Transport.socket();

        // Only source info
        socket_address.addr = TOS_NODE_ID; // NODE_ID
        socket_address.port = port; 

        if (call Transport.bind(fd, &socket_address) == SUCCESS) { 
            call ServerTimer.startOneShot(ATTEMPT_CONNECTION_TIME);
            return;
        }

        dbg(TRANSPORT_CHANNEL, "This should never happen\n");
    }

    command void TCP.testClient(uint16_t destination, uint8_t sourcePort, uint8_t destinationPort, uint16_t transfer) {
        socket_addr_t socket_address;
        socket_addr_t server_address;
        fd = call Transport.socket();

        // Only source info.
        socket_address.addr = TOS_NODE_ID;
        socket_address.port = sourcePort;

        call Transport.bind(fd, &socket_address);

        // Only dest info.
        server_address.addr = destination;
        server_address.port = destinationPort;

        if (call Transport.connect(fd, &server_address) == SUCCESS) {
            call ClientTimer.startOneShot(CLIENT_WRITE_TIMER);
            data = transfer;
            return;
        }

        dbg(TRANSPORT_CHANNEL, "This should never happen\n");
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
        socket_t newFd = call Transport.accept(fd);
        uint16_t i;

        if (newFd != NULL) {
            call AcceptedSockets.pushback(newFd);
        }

        for (i = 0; i < call AcceptedSockets.size(); i++) {
            // read data and print
        }
    }

    event void ClientTimer.fired() {
        dbg(TRANSPORT_CHANNEL, "Client has connected to Server\n");
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