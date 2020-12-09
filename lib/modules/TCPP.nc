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
    uses interface Timer<TMilli> as AppServerTimer;
    uses interface Timer<TMilli> as AppConnectionTimer;
    uses interface Timer<TMilli> as AppClientTimer;
    uses interface Transport;
    uses interface LinkState;
    uses interface SimpleSend as NameSender;

    // Data Structures
    uses interface Hashmap<uint8_t*> as AcceptedSockets;
}

implementation{
    socket_t fd;
    uint16_t data;
    uint16_t tempData;
    uint16_t time = 1;
    uint16_t bytesWritten = 1;
    uint8_t *user;
    pack package;
    uint16_t serverDestination;


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

        if (fd != 0) {
            // Only source info
            socket_address.addr = TOS_NODE_ID; // NODE_ID
            socket_address.port = port; 

            if (call Transport.bind(fd, &socket_address) == SUCCESS) { 
                call AcceptedSockets.insert(fd, "0");
                
                if (call Transport.listen(fd) == SUCCESS && !call ServerTimer.isRunning()) {
                    call ServerTimer.startPeriodic(ATTEMPT_CONNECTION_TIME);
                }

                return;
            }
        }

        dbg(TRANSPORT_CHANNEL, "This should never happen\n");
    }

    command void TCP.testClient(uint16_t destination, uint8_t sourcePort, uint8_t destinationPort, uint16_t transfer) {
        socket_addr_t socket_address;
        socket_addr_t server_address;
        fd = call Transport.socket();

        if (fd != 0) {
            // Only source info.
            socket_address.addr = TOS_NODE_ID;
            socket_address.port = sourcePort;

            if (call Transport.bind(fd, &socket_address) == FAIL) {
                dbg(TRANSPORT_CHANNEL, "Failed to bind sockets. Exiting!");
                return;
            }

            // Only dest info.
            server_address.addr = destination;
            server_address.port = destinationPort;

            call Transport.connect(fd, &server_address);
            tempData = transfer;

            if (!call ConnectionTimer.isRunning()) {
                call ConnectionTimer.startPeriodic(1000);
            }

            printf("Establishing Connection");
            return;
        }

        dbg(TRANSPORT_CHANNEL, "This should never happen\n");
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

    command void TCP.setAppServer(uint16_t address, uint8_t port) {
        socket_addr_t socket_address;
        fd = call Transport.socket();

        if (fd != 0) {
            // Only source info
            socket_address.addr = TOS_NODE_ID; // NODE_ID
            socket_address.port = port; 

            if (call Transport.bind(fd, &socket_address) == SUCCESS) { 
                call AcceptedSockets.insert(fd, "0");
                
                if (call Transport.listen(fd) == SUCCESS && !call ServerTimer.isRunning()) {
                    call AppServerTimer.startPeriodic(ATTEMPT_CONNECTION_TIME);
                }

                return;
            }
        }

        dbg(TRANSPORT_CHANNEL, "This should never happen\n");
    }

    command void TCP.setAppClient(uint16_t clientAddress, uint16_t serverAddress, uint8_t clientPort, uint8_t serverPort, uint8_t *username) {
        socket_addr_t socket_address;
        socket_addr_t server_address;
        fd = call Transport.socket();

        if (fd != 0) {
            // Only source info.
            socket_address.addr = TOS_NODE_ID;
            socket_address.port = clientPort;

            if (call Transport.bind(fd, &socket_address) == FAIL) {
                dbg(TRANSPORT_CHANNEL, "Failed to bind sockets. Exiting!");
                return;
            }

            // Only dest info.
            server_address.addr = serverAddress;
            server_address.port = serverPort;

            call Transport.appConnect(fd, &server_address, username);
            user = username;
            serverDestination = serverAddress;

            if (!call AppConnectionTimer.isRunning()) {
                call AppConnectionTimer.startPeriodic(1000);
            }

            printf("Establishing Connection");
            return;
        }

        dbg(TRANSPORT_CHANNEL, "This should never happen\n");
    }

    command void TCP.broadcastMessage(uint16_t address, uint8_t *message) {
        // get a sub list of all sockets with flag 3 and state 2 on server
        // send message to each node with the defined port and address
        uint8_t i;
        uint8_t *username;

        for (i = 0; i < call AcceptedSockets.size(); i++) {
            username = call AcceptedSockets.get(i);

            if (username != (uint8_t*)"0") {
                // broadcast
                // makePack(&package, TOS_NODE_ID, serverDestination, MAX_TTL, PROTOCOL_APP, 0, message, PACKET_MAX_PAYLOAD_SIZE);
                // dbg(APP_CHANNEL, "post make pack %s\n", package.payload);
                // call NameSender.send(package, call LinkState.getFromRoutingTable(serverDestination));
            }
        }
    }

    command void TCP.unicastMessage(uint16_t address, uint8_t *username, uint8_t *message) {
        // check if the user has an established socket to the server
        //      this is by flag = 3 state = 2 and username = username
        // send message to the given user
        uint8_t i;
        uint8_t *name;

        for (i = 0; i < call AcceptedSockets.size(); i++) {
            name = call AcceptedSockets.get(i);

            if (name == username) {
                // broadcast
                // makePack(&package, TOS_NODE_ID, serverDestination, MAX_TTL, PROTOCOL_APP, 0, message, PACKET_MAX_PAYLOAD_SIZE);
                // dbg(APP_CHANNEL, "post make pack %s\n", package.payload);
                // call NameSender.send(package, call LinkState.getFromRoutingTable(serverDestination));
                break;
            }
        }
    }

    command void TCP.printUsers() {
        uint8_t i;
        uint8_t *username;

        printf("Reply: listUsrRply ");
        for (i = 0; i < call AcceptedSockets.size(); i++) {
            username = call AcceptedSockets.get(i);

            if (username != (uint8_t*)"0") {
                printf("%s, ", username);
            }
        }
        printf("\\r\\n\n");
    }

    command error_t TCP.receive(pack* p) {
        uint8_t i;
        uint8_t* name;
        
        for (i = 0; i < call AcceptedSockets.size(); i++) {
            name = call AcceptedSockets.get(i);

            if (name == (uint8_t*)"0") {
                call AcceptedSockets.remove(i);
                call AcceptedSockets.insert(i, (uint8_t*)p->payload);
                dbg(APP_CHANNEL, "Updated Socket[%hhu] with %s\n", i, call AcceptedSockets.get(i));
                break;
            }
        }
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
            call AcceptedSockets.insert(newFd, "0");
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
        return;
    }

    event void AppServerTimer.fired() {
        socket_t newFd = 0;

        if (fd < MAX_NUM_OF_SOCKETS) {
            newFd = call Transport.accept(fd);

            if (newFd != NULL) {
                call AcceptedSockets.insert(newFd, "0");
                fd = newFd;
            }   
        } 
    }

    event void AppConnectionTimer.fired() {
        if (call Transport.hasConnected() == SUCCESS) {
            printf("in %d seconds\n", time);
            time = 1;
            dbg(TRANSPORT_CHANNEL, "Node %hu's socket %hhu has established a connection to the server\n", TOS_NODE_ID, fd);
            call AppClientTimer.startOneShot(CLIENT_WRITE_TIMER);
            call AppConnectionTimer.stop();

            return;
        }

        printf(".");
        time = time + 1;
    }

    event void AppClientTimer.fired() {
        call AcceptedSockets.insert(fd, user);
        makePack(&package, TOS_NODE_ID, serverDestination, MAX_TTL, PROTOCOL_APP, 0, user, PACKET_MAX_PAYLOAD_SIZE);
        dbg(APP_CHANNEL, "post make pack %s\n", package.payload);
        call NameSender.send(package, call LinkState.getFromRoutingTable(serverDestination));
    }

    /*
     * #######################################
     *              Methods
     * #######################################
     */
}