/*
 * ~Transport Module~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/socket.h"
#include "../../includes/tcp.h"

module TransportP {
    provides interface Transport;

    // Modules
    uses interface Random;
    uses interface LinkState;
    uses interface SimpleSend as TransportSender;
    uses interface Timer<TMilli> as HandshakeTimer;
    uses interface Timer<TMilli> as StopAndWaitTimer;

    // Data Structures
    uses interface Hashmap<socket_store_t> as Sockets;
}

implementation {
    pack dataPackage;
    TCPPack dataTCP;
    pack handshakePackage;
    TCPPack handshakeTCP;
    error_t clientConnected = FAIL;
    socket_t globalFD;
    uint8_t globalServerSourcePort;

    /*
     * #######################################
     *              Prototypes
     * #######################################
     */

    void initSocket(uint8_t fd, uint8_t state);
    uint8_t calcReceiverBuffer(uint8_t fd);
    uint8_t calcSenderBuffer(uint8_t fd);
    uint8_t calcAdvertisementWindow(uint8_t fd);
    uint8_t calcEffectiveWindow(uint8_t fd);
    uint8_t getSendBufferOccupied(uint8_t fd);
    uint8_t getReceiveBufferOccupied(uint8_t fd);
    uint8_t getSendBufferAvailable(uint8_t fd);
    uint8_t getReceiveBufferAvailable(uint8_t fd);
    error_t checkForEstablishedSocket();

    /*
     * #######################################
     *              Commands
     * #######################################
     */

    command error_t Transport.hasConnected() {
        error_t temp = clientConnected;
        clientConnected = FAIL;
        return temp;
    }

    command void Transport.printSocket(socket_t fd) {
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);
            printf("Socket[%hhu]: {\n\tflag: %hhu\n\tstate: %hhu\n\tsrc: %hhu\n\tusername: %s\n\tdest: {\n\t\taddr: %hu\n\t\tport: %hhu\n\t}\n}\n", fd, socket.flag, socket.state, socket.src, socket.username, socket.dest.addr, socket.dest.port);
        }
    }

    command void Transport.printSockets() {
        uint8_t i;
        dbg(TRANSPORT_CHANNEL, "\n");
        for (i = 1; i <= call Sockets.size(); i++) {
            call Transport.printSocket(i);
        }
    }

    command socket_t Transport.getFd(uint16_t clientAddress, uint16_t destination, uint8_t sourcePort, uint8_t destinationPort) {
        uint8_t i;
        socket_store_t socket;

        for (i = 1; i <= call Sockets.size(); i++) {
            socket = call Sockets.get(i);

            if (TOS_NODE_ID == clientAddress && socket.src == sourcePort && socket.dest.addr == destination && socket.dest.port == destinationPort) {
                return i;
            }
        }

        return 0;
    }

    command error_t Transport.validateSocketBuffer(socket_t fd) {
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);

            if (socket.state == ESTABLISHED && (getSendBufferAvailable(fd) == SOCKET_BUFFER_SIZE - 1 || getSendBufferOccupied(fd) == 0)) {
                return SUCCESS;
            }
        }

        return FAIL;
    }

    command char* Transport.getUsername(socket_t fd) {
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);

            return socket.username;
        }
    }

    command uint16_t Transport.getDestinationFromSocketId(socket_t fd) {
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);

            return socket.dest.addr;
        }
    }

    command uint16_t Transport.getDestinationFromSocketUsername(char *username) {
        socket_store_t socket;
        char name[128];
        uint8_t i;
        uint8_t j;
        bool foundUsername = FALSE;

        for (i = 1; i <= MAX_NUM_OF_SOCKETS; i++) {
            socket = call Sockets.get(i);

            for (j = 0; j < sizeof(username); j++) {
                if (*(name + j) != *(username + j)) {
                    foundUsername = FALSE;
                    break;
                } else {
                    foundUsername = TRUE;
                }
            }

            if (foundUsername == TRUE) {
                return socket.dest.addr;
            }
        }

        return 99;
    }

    command socket_t Transport.socket() {
        socket_t fd = 0;
        uint8_t SocketsSize = call Sockets.size();

        if (SocketsSize < MAX_NUM_OF_SOCKETS) {
            fd = SocketsSize + 1;

            initSocket(fd, CLOSED);
        }

        return fd;
    }

    command error_t Transport.bind(socket_t fd, socket_addr_t* addr) {
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);
            socket.src = addr->port;
            globalServerSourcePort = addr->port;

            call Sockets.insert(fd, socket);

            return SUCCESS;
        }

        dbg(TRANSPORT_CHANNEL, "This should never happen\n");

        return FAIL;
    }

    command socket_t Transport.accept(socket_t fd) {
        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS) {
            fd = fd + 1;
            initSocket(fd, LISTEN);

            return fd;
        }

        return NULL;
    }

    command uint8_t Transport.write(socket_t fd, uint8_t* buff, uint8_t bufflen) {
        socket_store_t socket;
        uint8_t bytesWritten = 0;
        uint8_t i;
        uint8_t* payload = (uint8_t*)dataTCP.payload;
        uint8_t sequenceNumber;

        // check if socket is valid:
        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS) {
            if (call Sockets.contains(fd)) {
                socket = call Sockets.get(fd);

                // if socket is valid, it has to be on an established connection:
                if (socket.state != ESTABLISHED) {
                    // couldnt read any bytes
                    return 0;
                } else if (socket.state == ESTABLISHED) {
                    printf("sendBuff(%hhu)[", socket.lastWritten);
                    for (i = 0; socket.lastWritten < SOCKET_BUFFER_SIZE && getSendBufferAvailable(fd) > 0 && bytesWritten <= bufflen; i++) {
                        memcpy(&socket.sendBuff[socket.lastWritten], buff + bytesWritten, 1);
                        socket.lastWritten++;
                        bytesWritten++;
                    }

                    if (socket.lastWritten >= SOCKET_BUFFER_SIZE && getSendBufferAvailable(fd) > 0) {
                        socket.lastWritten = 0;
                    }

                    for (i = 0; i < SOCKET_BUFFER_SIZE; i++) {
                        printf("%hhu", socket.sendBuff[i]);
                        if (i != SOCKET_BUFFER_SIZE - 1) {
                            printf(", ");
                        }
                    }
                    printf("]\n");

                    sequenceNumber = socket.lastSent + 1;

                    for (i = 0; i < SOCKET_BUFFER_SIZE; i++) {
                        memcpy(payload + i, &socket.sendBuff[socket.lastSent++ % SOCKET_BUFFER_SIZE], 1);
                    }

                    call Sockets.insert(fd, socket);

                    // send pack
                    makeTCPPacket(&dataTCP, socket.dest.port, socket.src, sequenceNumber, socket.nextExpected, DATA, socket.effectiveWindow, 0, payload); // FIX SEQ AND ACK NUMS
                    
                    makePack(&dataPackage, TOS_NODE_ID, socket.dest.addr, MAX_TTL, PROTOCOL_TCP, 0, &dataTCP, sizeof(dataTCP));
                    
                    call TransportSender.send(dataPackage, call LinkState.getFromRoutingTable(socket.dest.addr));
                    

                    call StopAndWaitTimer.startOneShot(ATTEMPT_CONNECTION_TIME);

                    // return bytes
                    return bytesWritten;
                }
            }

            return 0;
        }

        return 0;
    }

    command error_t Transport.receive(pack* package) {
        uint16_t packageDestination = package->dest;
        uint16_t packageSource = package->src;
        uint16_t packageSequence = package->seq;
        uint8_t TTL = package->TTL;
        uint8_t protocol = package->protocol;
        TCPPack *TCPPackage =  package->payload;
        uint8_t sourcePort = TCPPackage->source_port;
        uint8_t destinationPort = TCPPackage->destination_port;
        uint8_t sequenceNumber = TCPPackage->sequence_number;
        uint8_t acknowledgementNumber = TCPPackage->acknowledgement_number;
        uint8_t flag = TCPPackage->flag;
        uint8_t advertisementWindow = TCPPackage->advertisement_window;
        uint8_t checksum = TCPPackage->checksum;
        uint8_t *payload = TCPPackage->payload;
        uint8_t i;
        socket_store_t socket;
        uint8_t ackNum = sequenceNumber + 1;
        uint8_t seqNum = call Random.rand16() % 1000;
        uint8_t curByte = 0;
        uint8_t recieverBuffer;
        dbg(APP_CHANNEL, "Flag # %hhu\n", flag);
        switch (flag) {
            case (DATA):
                for (i = 1; i <= call Sockets.size(); i++) {
                    socket = call Sockets.get(i);

                    if (socket.state == ESTABLISHED) {
                        printf("rcvdBuff(%hhu)[", socket.lastRead);
                        for (i = 0; socket.lastRead < SOCKET_BUFFER_SIZE && getReceiveBufferAvailable(i) > 0 && curByte <= SOCKET_BUFFER_SIZE; i++) {
                            memcpy(&socket.rcvdBuff[socket.lastRead], payload + curByte, 1);
                            socket.lastRead++;
                            curByte++;
                        }      

                        if (socket.lastRead >= SOCKET_BUFFER_SIZE && getReceiveBufferAvailable(i) > 0) {
                            socket.lastRead = 0;
                        }      

                        for (i = 0; i < SOCKET_BUFFER_SIZE; i++) {
                            printf("%hhu", socket.rcvdBuff[i]);
                            if (i != SOCKET_BUFFER_SIZE - 1) {
                                printf(", ");
                            }
                        }
                        printf("]\n");

                        call Sockets.insert(i, socket);     
                        dbg(TRANSPORT_CHANNEL, "Data packet recieved: sending ACK...\n");
                        //stop and wait:
                        ackNum = seqNum + 1;
                        makeTCPPacket(&handshakeTCP, destinationPort, sourcePort, seqNum, ackNum, ACK, advertisementWindow, 0, &payload);

                        makePack(&handshakePackage, TOS_NODE_ID, packageSource, MAX_TTL, PROTOCOL_TCP, 0, &handshakeTCP, PACKET_MAX_PAYLOAD_SIZE);

                        call TransportSender.send(handshakePackage, call LinkState.getFromRoutingTable(packageSource));
                    }

                    break;
                }
            case (SYN):
                for (i = 1; i <= call Sockets.size(); i++) {
                    socket = call Sockets.get(i);

                    if (socket.state == LISTEN) {
                        socket.flag = SYN_ACK;
                        socket.state = SYN_RCVD;
                        socket.dest.addr = packageSource;
                        socket.dest.port = sourcePort;
                        memcpy(socket.username, payload, sizeof(payload));

                        call Sockets.insert(i, socket);

                        break;
                    }
                }

                makeTCPPacket(&handshakeTCP, destinationPort, sourcePort, seqNum, ackNum, SYN_ACK, advertisementWindow, 9, payload);

                makePack(&handshakePackage, TOS_NODE_ID, packageSource, MAX_TTL, PROTOCOL_TCP, 0, &handshakeTCP, PACKET_MAX_PAYLOAD_SIZE);

                call TransportSender.send(handshakePackage, call LinkState.getFromRoutingTable(packageSource));

                return SUCCESS;
            case (SYN_ACK):
                for (i = 1; i <= call Sockets.size(); i++) {
                    socket = call Sockets.get(i);

                    if (socket.state == SYN_SENT) {
                        socket.flag = ACK;
                        socket.state = ESTABLISHED;

                        call Sockets.insert(i, socket);

                        break;
                    }
                }

                makeTCPPacket(&handshakeTCP, destinationPort, sourcePort, seqNum + 1, ackNum + 1, ACK, advertisementWindow, 9, payload);

                makePack(&handshakePackage, TOS_NODE_ID, packageSource, MAX_TTL, PROTOCOL_TCP, 0, &handshakeTCP, PACKET_MAX_PAYLOAD_SIZE);

                call TransportSender.send(handshakePackage, call LinkState.getFromRoutingTable(packageSource));

                return SUCCESS;
            case (ACK):
                for (i = 1; i <= call Sockets.size(); i++) {
                    socket = call Sockets.get(i);

                    if (socket.state == SYN_RCVD) {
                        socket.flag = ACK;
                        socket.state = ESTABLISHED;

                        call Sockets.insert(i, socket);

                        break;
                    } else if (socket.state == ESTABLISHED) {
                        // dbg(TRANSPORT_CHANNEL, "ACK recieved, stopping timer, incremeting sequence num...\n");
                        seqNum++;
                        call StopAndWaitTimer.stop();
                    }
                }

                return SUCCESS;
            case (FIN):
                dbg(APP_CHANNEL, "are these equal %hu == %hu\n", sourcePort, TOS_NODE_ID);
                for (i = 1; i <= call Sockets.size(); i++) {
                    socket = call Sockets.get(i);

                    if (socket.state == ESTABLISHED) {
                        socket.state = LISTEN;
                        socket.flag = FIN_ACK;
                        memcpy(socket.username, "0", sizeof("0"));
                        call Sockets.insert(i, socket);                    
                        
                        makeTCPPacket(&handshakeTCP, destinationPort, sourcePort, seqNum, ackNum, FIN_ACK, advertisementWindow, 0, &payload);

                        makePack(&handshakePackage, TOS_NODE_ID, packageSource, MAX_TTL, PROTOCOL_TCP, 0, &handshakeTCP, PACKET_MAX_PAYLOAD_SIZE);

                        call TransportSender.send(handshakePackage, call LinkState.getFromRoutingTable(packageSource));
                        break;
                    }
                }

                return SUCCESS;
            case (FIN_ACK):
                for (i = 1; i <= call Sockets.size(); i++) {
                    socket = call Sockets.get(i);

                    if (socket.state == LISTEN && socket.flag == FIN_ACK) {
                        socket.state = CLOSED;
                        socket.flag = FIN;
                        memcpy(socket.username, "0", sizeof("0"));
                        call Sockets.insert(i, socket);
                        break;
                    }
                }

                return SUCCESS;
        }

        return FAIL;
    }

    command uint8_t Transport.read(socket_t fd, uint8_t* buff, uint8_t bufflen) {
        socket_store_t socket;
        uint8_t bytesRead = 0;
        uint8_t i;
        bool hasData = FALSE;
        
        // check if socket is valid:
        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS) {
            if (call Sockets.contains(fd)) {
                socket = call Sockets.get(fd);
                // dbg(TRANSPORT_CHANNEL, "socket state: %hu\n", socket.state);
                // if socket is valid, it has to be on an established connection:
                if (socket.state != ESTABLISHED) {
                    // couldnt read any bytes
                    return 0;
                } else if (socket.state == ESTABLISHED) {
           
                    for (i = 0; i < SOCKET_BUFFER_SIZE; i++) {
                        if (socket.rcvdBuff[i] != 0) {

                        }  
                    }
                    
                    // return bytes
                    return bytesRead;
                }
            }
        }

        return 0;
    }

    command error_t Transport.connect(socket_t fd, socket_addr_t* addr) {
        socket_store_t socket;
        uint8_t sequenceNum = call Random.rand16() % 1000;
        uint8_t ackNum = 0;
        uint8_t flag = SYN;
        uint8_t advertisement_window = 1; // for stop and wait
        uint8_t checksum = 0;
        uint8_t buffer[SOCKET_BUFFER_SIZE];

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);

            if (socket.state == CLOSED) {
                socket.dest = *addr;
                socket.flag = SYN;
                socket.state = SYN_SENT;

                call Sockets.insert(fd, socket);
                
                makeTCPPacket(&handshakeTCP, socket.src, addr->port, sequenceNum, ackNum, flag, advertisement_window, checksum, buffer);

                makePack(&handshakePackage, TOS_NODE_ID, addr->addr, MAX_TTL, PROTOCOL_TCP, 0, &handshakeTCP, PACKET_MAX_PAYLOAD_SIZE);

                if (call TransportSender.send(handshakePackage, call LinkState.getFromRoutingTable(addr->addr)) == SUCCESS) {
                    call HandshakeTimer.startPeriodic(20000);
                    globalFD = fd;
                }
            }
        }

        return FAIL;
    }

    command error_t Transport.appConnect(socket_t fd, socket_addr_t* addr, uint8_t *username) {
        socket_store_t socket;
        uint8_t sequenceNum = call Random.rand16() % 1000;
        uint8_t ackNum = 0;
        uint8_t flag = SYN;
        uint8_t advertisement_window = 1; // for stop and wait
        uint8_t checksum = 0;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);

            if (socket.state == CLOSED) {
                socket.dest = *addr;
                socket.flag = SYN;
                socket.state = SYN_SENT;
                memcpy(socket.username, username, sizeof(username));

                call Sockets.insert(fd, socket);
                
                makeTCPPacket(&handshakeTCP, socket.src, addr->port, sequenceNum, ackNum, flag, advertisement_window, checksum, username);

                makePack(&handshakePackage, TOS_NODE_ID, addr->addr, MAX_TTL, PROTOCOL_TCP, 0, &handshakeTCP, PACKET_MAX_PAYLOAD_SIZE);

                if (call TransportSender.send(handshakePackage, call LinkState.getFromRoutingTable(addr->addr)) == SUCCESS) {
                    call HandshakeTimer.startPeriodic(20000);
                    globalFD = fd;
                }
            }
        }

        return FAIL;
    }

    command error_t Transport.close(socket_t fd) {
        socket_store_t socket;
        uint8_t buffer[MAX_PAYLOAD_SIZE];

        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS) {
            if (call Sockets.contains(fd)) {
                socket = call Sockets.get(fd);
                memcpy(socket.username, "0", sizeof("0"));
                call Sockets.insert(fd, socket);
                socket = call Sockets.get(fd);
                
                switch (socket.state) {
                    case ESTABLISHED:
                    case SYN_RCVD:
                        initSocket(fd, CLOSED);
                        makeTCPPacket(&handshakeTCP, TOS_NODE_ID, socket.dest.addr, 0, 0, FIN, 0, 0, buffer);
                        makePack(&handshakePackage, TOS_NODE_ID, socket.dest.addr, MAX_TTL, PROTOCOL_TCP, 0, &handshakeTCP, PACKET_MAX_PAYLOAD_SIZE);
                        call TransportSender.send(dataPackage, call LinkState.getFromRoutingTable(socket.dest.addr));
                    default:
                        initSocket(fd, CLOSED);
                }

                return SUCCESS;
            }
        }

        return FAIL;
    }

    command error_t Transport.release(socket_t fd) {
        socket_store_t socket;

        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS) {
            if (call Sockets.contains(fd)) {
                socket = call Sockets.get(fd);
                initSocket(fd, CLOSED);

                return SUCCESS;
            }
        }

        return FAIL;
    }

    command error_t Transport.listen(socket_t fd) {
        socket_store_t socket;

        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS) {
            if (call Sockets.contains(fd)) {
                socket = call Sockets.get(fd);

                socket.state = LISTEN;

                call Sockets.insert(fd, socket);

                return SUCCESS;
            }
        }

        return FAIL;
    }

    /*
     * #######################################
     *              Events
     * #######################################
     */

    event void HandshakeTimer.fired() {
        if (checkForEstablishedSocket() == SUCCESS) {
            call HandshakeTimer.stop();
        }
    }

    event void StopAndWaitTimer.fired() {
        // retransmit
        call TransportSender.send(dataPackage, call LinkState.getFromRoutingTable(dataPackage.dest));
        call StopAndWaitTimer.startOneShot(ATTEMPT_CONNECTION_TIME);
    }

    /*
     * #######################################
     *              Methods
     * #######################################
     */

    void initSocket(uint8_t fd, uint8_t state) {
        socket_store_t socket = call Sockets.get(fd);
        uint8_t i;
        uint8_t pos;

        socket.flag = DATA;
        socket.state = state;
        socket.src = globalServerSourcePort;
        socket.dest.addr = ROOT_SOCKET_ADDR;
        socket.dest.port = ROOT_SOCKET_PORT;
        memcpy(socket.username, "0", sizeof("0"));

        for (i = 0; i < SOCKET_BUFFER_SIZE; i++) {
            socket.sendBuff[i] = 0;
            socket.rcvdBuff[i] = 0;
        }

        pos = call Random.rand16() % 128 * 0;
        socket.lastWritten = pos;
        socket.lastAck = pos;
        socket.lastSent = pos;

        pos = call Random.rand16() % 128 * 0;
        socket.lastRead = pos;
        socket.lastRcvd = pos;
        socket.nextExpected = pos;

        socket.RTT = 800;
        socket.effectiveWindow = 0;

        call Sockets.insert(fd, socket);
    }

    uint8_t calcReceiverBuffer(uint8_t fd) {
        uint8_t lastRead;
        uint8_t nextExpected;
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);

            lastRead = socket.lastRead % SOCKET_BUFFER_SIZE;
            nextExpected = socket.nextExpected % SOCKET_BUFFER_SIZE;

            if (lastRead < nextExpected) {
                return nextExpected - lastRead - 1;    
            } else {
                return SOCKET_BUFFER_SIZE - lastRead + nextExpected - 1;
            }
        }
    }

    uint8_t calcSenderBuffer(uint8_t fd) {
        uint8_t lastAck;
        uint8_t lastSent;
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);

            lastAck = socket.lastAck % SOCKET_BUFFER_SIZE;
            lastSent = socket.lastSent % SOCKET_BUFFER_SIZE;

            if (lastAck <= lastSent) {
                return lastSent - lastAck;
            } else {
                return SOCKET_BUFFER_SIZE - lastAck + lastSent;
            }
        }
    }

    uint8_t calcAdvertisementWindow(uint8_t fd) {
        return SOCKET_BUFFER_SIZE - calcReceiverBuffer(fd);
    }

    uint8_t calcEffectiveWindow(uint8_t fd) {
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);
            
            return socket.effectiveWindow - calcSenderBuffer(fd);
        }
    }

    uint8_t getSendBufferOccupied(uint8_t fd) {
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);

            if (socket.lastSent == socket.lastWritten) {
                return 0;
            } else if (socket.lastSent > socket.lastWritten) {
                return socket.lastWritten + (SOCKET_BUFFER_SIZE - socket.lastSent);
            } else {
                return socket.lastWritten - socket.lastSent;
            }
        }

        return -1;
    }

    uint8_t getReceiveBufferOccupied(uint8_t fd) {
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);

            if (socket.lastRead == socket.lastRcvd) {
                return 0;
            } else if(socket.lastRead > socket.lastRcvd) {
                return socket.lastRcvd + (SOCKET_BUFFER_SIZE - socket.lastRead);
            } else {
                return socket.lastRcvd - socket.lastRead;
            }
        }

        return -1;
    }

    uint8_t getSendBufferAvailable(uint8_t fd) {
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);

            if (socket.lastAck == socket.lastWritten) {
                return SOCKET_BUFFER_SIZE - 1;
            } else if(socket.lastAck > socket.lastWritten) {
                return socket.lastAck - socket.lastWritten - 1;
            } else {
                return socket.lastAck + (SOCKET_BUFFER_SIZE - socket.lastWritten) - 1;
            }
        }

        return -1;
    }

    uint8_t getReceiveBufferAvailable(uint8_t fd) {
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);

            if (socket.lastRead == socket.lastRcvd) {
                return SOCKET_BUFFER_SIZE - 1;
            } else if (socket.lastRead > socket.lastRcvd) {
                return socket.lastRead - socket.lastRcvd - 1;
            } else {
                return socket.lastRead + (SOCKET_BUFFER_SIZE - socket.lastRcvd) - 1;
            }
        }

        return -1;
    }

    error_t checkForEstablishedSocket() {
        socket_store_t socket;

        if (call Sockets.contains(globalFD)) {
            socket = call Sockets.get(globalFD);

            if (socket.state == ESTABLISHED) {
                clientConnected = SUCCESS;
                return SUCCESS;
            }
        }

        return FAIL;
    }
}