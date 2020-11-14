/*
 * ~Transport Module~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/socket.h"
#include "../../includes/tcp.h"

module TransportP
{
    provides interface Transport;

    // Modules
    uses interface Random;
    uses interface LinkState;
    uses interface SimpleSend as TransportSender;
    uses interface Timer<TMilli> as HandshakeTimer;

    // Data Structures
    uses interface Hashmap<socket_store_t> as Sockets;
}

implementation
{
    pack dataPackage;
    TCPPack dataTCP;
    pack handshakePackage;
    TCPPack handshakeTCP;
    error_t clientConnected = FAIL;

    /*
     * #######################################
     *              Prototypes
     * #######################################
     */

    uint16_t getSendBufferOccupied(uint8_t fd);
    uint16_t getReceiveBufferOccupied(uint8_t fd);
    uint16_t getSendBufferAvailable(uint8_t fd);
    uint16_t getReceiveBufferAvailable(uint8_t fd);
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
            printf("Socket[%hu]: {\n\tflag: %hhu\n\tstate: %d\n\tsrc: %hhu\n\tdest: {\n\t\taddr: %hu\n\t\tport: %hhu\n\t}\n}\n", fd, socket.flag, socket.state, socket.src, socket.dest.addr, socket.dest.port);
        }
    }

    command void Transport.printSockets() {
        uint16_t i;

        for (i = 1; i <= call Sockets.size(); i++) {
            call Transport.printSocket(i);
        }
    }

    command socket_t Transport.getFd(uint16_t clientAddress, uint16_t destination, uint8_t sourcePort, uint8_t destinationPort) {
        uint16_t i;
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

            if (socket.state != ESTABLISHED) {
                return FAIL;
            } else {
                if (getSendBufferAvailable(fd) == SOCKET_BUFFER_SIZE - 1 || getSendBufferOccupied(fd) == 0) {
                    return SUCCESS;
                }
            }
        }

        return FAIL;
    }

    command socket_t Transport.socket() {
        socket_t fd = NULL;
        socket_store_t socket;
        uint16_t SocketsSize = call Sockets.size();
        uint16_t i;
        uint8_t pos;

        if (SocketsSize < MAX_NUM_OF_SOCKETS) {
            fd = SocketsSize + 1;

            socket.flag = DATA;
            socket.state = CLOSED;
            socket.src = 0;
            socket.dest.addr = ROOT_SOCKET_ADDR;
            socket.dest.port = ROOT_SOCKET_PORT;

            for (i = 0; i < SOCKET_BUFFER_SIZE; i++) {
                socket.sendBuff[i] = 0;
                socket.rcvdBuff[i] = 0;
            }

            pos = call Random.rand16() % 128;
            socket.lastWritten = pos;
            socket.lastAck = pos;
            socket.lastSent = pos;

            pos = call Random.rand16() % 128;
            socket.lastRead = pos;
            socket.lastRcvd = pos;
            socket.nextExpected = pos;

            socket.RTT = 800;
            socket.effectiveWindow = 0;

            call Sockets.insert(fd, socket);
        }

        return fd;
    }

    command error_t Transport.bind(socket_t fd, socket_addr_t* addr) {
        socket_store_t socket;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);
            socket.src = addr->port;

            call Sockets.insert(fd, socket);

            return SUCCESS;
        }

        dbg(TRANSPORT_CHANNEL, "This should never happen\n");

        return FAIL;
    }

    command socket_t Transport.accept(socket_t fd) {
        socket_store_t socket;

        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS - 1) {
            socket = call Sockets.get(fd);

            if (socket.state == LISTEN) {
                // make a copy in next socket
                call Sockets.insert(fd + 1, socket);
                return fd;
            }
        }

        return NULL;
    }

    command uint16_t Transport.write(socket_t fd, uint8_t* buff, uint16_t bufflen) {
        socket_store_t socket;
        uint16_t bytesWritten = 0;
        uint16_t i;
        uint16_t temp;

        // check if socket is valid:
        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS) {
            if (call Sockets.contains(fd)) {
                socket = call Sockets.get(fd);
                temp = socket.lastWritten;
                dbg(TRANSPORT_CHANNEL, "last Written = %hhu\n", socket.lastWritten);
                // if socket is valid, it has to be on an established connection:
                if (socket.state != ESTABLISHED) {
                    // couldnt read any bytes
                    return 0;
                } else if (socket.state == ESTABLISHED) {
                    while (socket.lastWritten < bufflen && getSendBufferAvailable(fd) > 0) {
                        memcpy(&socket.sendBuff[socket.lastWritten], buff + bytesWritten, 1);
                        socket.lastWritten++;
                        bytesWritten++;
                    }
                    dbg(TRANSPORT_CHANNEL, "lastWritten = %hhu, buffer size = %hhu, occupied = %hu\n", socket.lastWritten, SOCKET_BUFFER_SIZE, getSendBufferOccupied(fd));
                    if (socket.lastWritten >= SOCKET_BUFFER_SIZE && getSendBufferAvailable(fd) > 0) {
                        socket.lastWritten = 0;
                    }
                    dbg(TRANSPORT_CHANNEL, "lastWritten = %hhu\n", socket.lastWritten);
                    printf("sendBuff(%hhu)[", temp);
                    for (i = 0; i < SOCKET_BUFFER_SIZE; i++) {
                        printf("%hhu", socket.sendBuff[i]);
                        if (i != SOCKET_BUFFER_SIZE - 1) {
                            printf(", ");
                        }
                    }
                    printf("]\n");

                    call Sockets.insert(fd, socket);

                    // send pack
                    makeTCPPacket(&dataTCP, socket.dest.port, socket.src, 0, 0, DATA, 1, 0, 0); // FIX SEQ AND ACK NUMS
                    makePack(&dataPackage, TOS_NODE_ID, socket.dest.addr, MAX_TTL, PROTOCOL_TCP, 0, &dataTCP, max_payload_size);
                    call TransportSender.send(dataPackage, call LinkState.getFromRoutingTable(socket.dest.addr));

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
        TCPPack *TCPPackage = package->payload;
        uint8_t sourcePort = TCPPackage->source_port;
        uint8_t destinationPort = TCPPackage->destination_port;
        uint32_t sequenceNumber = TCPPackage->sequence_number;
        uint32_t acknowledgementNumber = TCPPackage->acknowledgement_number;
        uint8_t flag = TCPPackage->flag;
        uint16_t advertisementWindow = TCPPackage->advertisement_window;
        uint32_t checksum = TCPPackage->checksum;
        uint16_t payload = TCPPackage->payload;
        uint16_t i;
        socket_store_t socket;
        uint32_t ackNum = sequenceNumber + 1;
        uint32_t seqNum = call Random.rand16() % 1000;
        uint16_t curByte;
        uint8_t recieverBuffer;
        
        switch (flag) {
            case (DATA):
                curByte = 0;

                for (i = 1; i <= call Sockets.size(); i++) {
                    socket = call Sockets.get(i);

                    if (socket.state == ESTABLISHED) {
                    if ((socket.nextExpected % SOCKET_BUFFER_SIZE) > (socket.lastRead % SOCKET_BUFFER_SIZE)) {
                            recieverBuffer = (socket.nextExpected % SOCKET_BUFFER_SIZE) - (socket.lastRead % SOCKET_BUFFER_SIZE);
                        } else {
                            recieverBuffer = SOCKET_BUFFER_SIZE - (socket.lastRead % SOCKET_BUFFER_SIZE) + (socket.nextExpected % SOCKET_BUFFER_SIZE);
                        }

                        while (curByte < max_payload_size && 0 < recieverBuffer) {
                            socket.lastRead++;
                            memcpy(&socket.rcvdBuff[socket.lastRead % SOCKET_BUFFER_SIZE], TCPPackage + curByte,1);
                            curByte++;
                            
                        }                    
                    }

                    break;
                }
            case (SYN):
                for (i = 1; i <= call Sockets.size(); i++) {
                    socket = call Sockets.get(i);

                    if (socket.state == LISTEN) {
                        socket.flag = SYN_ACK;
                        socket.state = SYN_RCVD;

                        call Sockets.insert(i, socket);

                        break;
                    }
                }

                makeTCPPacket(&handshakeTCP, destinationPort, sourcePort, seqNum, ackNum, SYN_ACK, advertisementWindow, 0, 0);
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

                makeTCPPacket(&handshakeTCP, destinationPort, sourcePort, seqNum + 1, ackNum + 1, ACK, advertisementWindow, 0, 0);
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
                    }

                    if (socket.state == ESTABLISHED) {
                        socket.lastAck = socket.lastSent;
                    }
                }

                return SUCCESS;
        }

        return FAIL;
    }

    command uint16_t Transport.read(socket_t fd, uint8_t* buff, uint16_t bufflen) {
        socket_store_t socket;
        uint16_t curByte = 0;
        uint8_t recieverBuffer;

        // check if socket is valid:
        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS) {
            if (call Sockets.contains(fd)) {
                socket = call Sockets.get(fd);

                // if socket is valid, it has to be on an established connection:
                if (socket.state != ESTABLISHED) {
                    // couldnt read any bytes
                    return 0;
                } else if (socket.state == ESTABLISHED) {
                    if ((socket.nextExpected % SOCKET_BUFFER_SIZE) > (socket.lastRead % SOCKET_BUFFER_SIZE)) {
                        recieverBuffer = (socket.nextExpected % SOCKET_BUFFER_SIZE) - (socket.lastRead % SOCKET_BUFFER_SIZE);
                    } else {
                        recieverBuffer = SOCKET_BUFFER_SIZE - (socket.lastRead % SOCKET_BUFFER_SIZE) + (socket.nextExpected % SOCKET_BUFFER_SIZE);
                    }

                    while (curByte < bufflen && 0 < recieverBuffer) {
                        socket.lastRead++;
                        memcpy(buff, socket.rcvdBuff[socket.lastRead % SOCKET_BUFFER_SIZE], 1);
                        curByte++;
                        buff++;
                    }
                    
                    // return bytes
                    return curByte;
                }
            }
        }

        return 0;
    }

    command error_t Transport.connect(socket_t fd, socket_addr_t* addr) {
        socket_store_t socket;
        uint32_t sequenceNum = call Random.rand16() % 1000;
        uint32_t ackNum = 0;
        uint8_t flag = SYN;
        uint16_t advertisement_window = 1; // for stop and wait
        uint32_t checksum;
        uint16_t payload = 0;

        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);

            if (socket.state == CLOSED) {
                socket.dest = *addr;
                socket.flag = SYN;
                socket.state = SYN_SENT;

                call Sockets.insert(fd, socket);

                makeTCPPacket(&handshakeTCP, socket.dest.port, addr->port, sequenceNum, ackNum, flag, advertisement_window, checksum, payload);
                makePack(&handshakePackage, TOS_NODE_ID, addr->addr, MAX_TTL, PROTOCOL_TCP, 0, &handshakeTCP, PACKET_MAX_PAYLOAD_SIZE);

                if (call TransportSender.send(handshakePackage, call LinkState.getFromRoutingTable(addr->addr)) == SUCCESS) {
                    call HandshakeTimer.startPeriodic(20000);
                }
            }
        }

        return FAIL;
    }

    command error_t Transport.close(socket_t fd) {
        socket_store_t socket;

        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS) {
            if (call Sockets.contains(fd)) {
                socket = call Sockets.get(fd);

                socket.state = CLOSED;

                call Sockets.insert(fd, socket);

                return SUCCESS;
            }
        }

        return FAIL;
    }

    command error_t Transport.release(socket_t fd) {
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

    /*
     * #######################################
     *              Methods
     * #######################################
     */

    uint16_t getSendBufferOccupied(uint8_t fd) {
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
    }

    uint16_t getReceiveBufferOccupied(uint8_t fd) {
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
    }

    uint16_t getSendBufferAvailable(uint8_t fd) {
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
    }

    uint16_t getReceiveBufferAvailable(uint8_t fd) {
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
    }

    error_t checkForEstablishedSocket() {
        uint16_t i;
        socket_store_t socket;

        for (i = 1; i <= call Sockets.size(); i++) {
            socket = call Sockets.get(i);

            if (socket.state == ESTABLISHED) {
                clientConnected = SUCCESS;
                return SUCCESS;
            }
        }

        return FAIL;
    }
}