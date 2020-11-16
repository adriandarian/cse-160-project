/*
 * ~TCP Module~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/socket.h"
#include "../../includes/tcp.h"
#include "../../includes/math.h"

module TCPP{
    provides interface TCP;

    // Modules
    uses interface Timer<TMilli> as ServerTimer;
    uses interface Timer<TMilli> as ConnectionTimer;
    uses interface Timer<TMilli> as ClientTimer;
    uses interface Timer<TMilli> as CloseTimer;
    uses interface Transport;

    // Data Structures
    uses interface List<uint8_t> as AcceptedSockets;
}

implementation{
    socket_t fd;
    uint16_t data;
    uint16_t tempData;
    uint16_t time = 1;
    uint16_t bytesWritten = 1;


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
            call AcceptedSockets.pushback(fd);
            
            if (call Transport.listen(fd) == SUCCESS && !(call ServerTimer.isRunning())) {
                call ServerTimer.startPeriodic(ATTEMPT_CONNECTION_TIME);
            }

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

        call Transport.connect(fd, &server_address);
        tempData = transfer;
        call ConnectionTimer.startPeriodic(1000);
        printf("Establishing Connection");
    }

    command void TCP.closeClient(uint16_t clientAddress, uint16_t destination, uint8_t sourcePort, uint8_t destinationPort) {
        socket_t tempFd = call Transport.getFd(clientAddress, destination, sourcePort, destinationPort);

        if (tempFd > 0 && tempFd <= MAX_NUM_OF_SOCKETS) {
            call Transport.close(tempFd);
            call CloseTimer.startOneShot(120000);
            return;
        }

        dbg(TRANSPORT_CHANNEL, "Failed to close client socket\n");
    }

    /*
     * #######################################
     *              Events
     * #######################################
     */

    event void ServerTimer.fired() {
        socket_t newFd = call Transport.accept(fd);
        uint16_t i;
        uint16_t buffer[SOCKET_BUFFER_SIZE];

        if (newFd != NULL) {
            call AcceptedSockets.pushback(newFd);
        }

        for (i = 0; i < SOCKET_BUFFER_SIZE; i++) {
            buffer[i] = 0;
        }

        for (i = 0; i < call AcceptedSockets.size(); i++) {
            // read data and print
            // dbg(TRANSPORT_CHANNEL, "Accepted Socket(%d): %d\n", call AcceptedSockets.size(), call AcceptedSockets.get(i));
            call Transport.read(call AcceptedSockets.get(i), buffer, SOCKET_BUFFER_SIZE);
        }

        // call ServerTimer.stop();
    }

    event void ConnectionTimer.fired() {
        if (call Transport.hasConnected() == SUCCESS) {
            printf("in %d seconds\n", time);
            time = 1;
            dbg(TRANSPORT_CHANNEL, "Node %hu's socket %hhu has established a connection to the server\n", TOS_NODE_ID, fd);
            call Transport.printSockets();
            data = tempData;
            dbg(TRANSPORT_CHANNEL, "Begin write: (data = %hu)\n", data);
            call ClientTimer.startPeriodic(CLIENT_WRITE_TIMER);
            call ConnectionTimer.stop();
            return;
        }

        printf(".");
        time = time + 1;
    }

    event void ClientTimer.fired() {   
        uint8_t buffer[SOCKET_BUFFER_SIZE];
        uint16_t currentByte = bytesWritten;
        uint16_t bytesToTransfer;
        uint16_t bytesTransferred;
        uint16_t i = 0;

        if (currentByte > data) {
            call ClientTimer.stop();
            return;
        }

        for (i = 0; i < SOCKET_BUFFER_SIZE; i++) {
            buffer[i] = 0;
        }
        
        for (i = 0; currentByte <= data && i < SOCKET_BUFFER_SIZE; i++) {
            buffer[i] = currentByte;
            currentByte++;
        }

        // subtract the amount of data you were able to write(fd, buffer, buffer len)
        bytesTransferred = call Transport.write(fd, buffer, i);
        bytesWritten += bytesTransferred;

        return;
    }

    event void CloseTimer.fired() {
        call Transport.printSockets();
        return;
    }

    /*
     * #######################################
     *              Methods
     * #######################################
     */
}