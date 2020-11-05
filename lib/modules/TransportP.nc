/*
 * ~Transport Module~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/socket.h"
#include "../../includes/tcp.h"

module TransportP{
    provides interface Transport;

    // Modules
    uses interface Random;
    uses interface LinkState;
    uses interface SimpleSend as TransportSender;
    uses interface Timer<TMilli> as HandshakeTimer;

    // Data Structures
    uses interface Hashmap<socket_store_t> as Sockets;
}

implementation{
    pack handshakePackage;
    TCPPack handshakeTCP;

    /*
     * #######################################
     *              Prototypes
     * #######################################
     */

    void printSockets();

    /*
     * #######################################
     *              Commands
     * #######################################
     */

    command socket_t Transport.socket() {
        socket_t fd = NULL;
        socket_store_t socket;
        uint16_t SocketsSize = call Sockets.size();

        if (SocketsSize < MAX_NUM_OF_SOCKETS) {
            fd = SocketsSize + 1;

            socket.flag = DATA;
            socket.state = CLOSED;
            socket.src = TOS_NODE_ID;

            call Sockets.insert(fd, socket);
        }

        return fd;
    }

    command error_t Transport.bind(socket_t fd, socket_addr_t *addr) {
        socket_store_t socket;
        
        if (call Sockets.contains(fd)) {
            socket = call Sockets.get(fd);
            socket.dest = *addr;

            call Sockets.insert(fd, socket);

            return SUCCESS;
        }

        dbg(TRANSPORT_CHANNEL, "This should never happen\n");

        return FAIL;
    }

    command socket_t Transport.accept(socket_t fd) {
        socket_store_t socket;

        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS) {
            socket = call Sockets.get(fd);

            if (socket.state == LISTEN) {
                // make a copy in next socket
                return fd;
            }
        }

        return NULL;
    }

    command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen) {

    }

    command error_t Transport.receive(pack* package) {
        uint16_t packageDestination = package->dest;
        uint16_t packageSource = package->src;
        uint16_t packageSequence = package->seq;
        uint8_t TTL = package->TTL;
        uint8_t protocol = package->protocol;
        TCPPack* TCPPackage = package->payload;
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

        switch(flag) {
            case(SYN):
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
            case(SYN_ACK):
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
            case(ACK):
                for (i = 1; i <= call Sockets.size(); i++) {
                    socket = call Sockets.get(i);

                    if (socket.state == SYN_RCVD) {                        
                        socket.flag = ACK;
                        socket.state = ESTABLISHED;
                        
                        call Sockets.insert(i, socket);

                        break;
                    }   
                }

                return SUCCESS;
        }

        return FAIL;
    }

    command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen) {

    }

    command error_t Transport.connect(socket_t fd, socket_addr_t *addr) {
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
                socket.flag = SYN;
                socket.state = SYN_SENT;

                call Sockets.insert(fd, socket);

                makeTCPPacket(&handshakeTCP, socket.dest.port, addr->port, sequenceNum, ackNum, flag, advertisement_window, checksum, payload);
                makePack(&handshakePackage, TOS_NODE_ID, addr->addr, MAX_TTL, PROTOCOL_TCP, 0, &handshakeTCP, PACKET_MAX_PAYLOAD_SIZE);

                if (call TransportSender.send(handshakePackage, call LinkState.getFromRoutingTable(addr->addr)) == SUCCESS) {
                    dbg(TRANSPORT_CHANNEL, "Successful sending of TCP Packet\n");
                    call HandshakeTimer.startOneShot(20000);
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
        uint16_t i;
        socket_store_t socket;

        for (i = 1; i <= call Sockets.size(); i++) {
            socket = call Sockets.get(i);

            if (socket.state == ESTABLISHED) {
                dbg(TRANSPORT_CHANNEL, "Node %hu's socket %hhu has established a connection to the server\n", TOS_NODE_ID, i);
                printSockets();
            }
        }
    }

    /*
     * #######################################
     *              Methods
     * #######################################
     */

    void printSockets() {
        uint16_t i;
        socket_store_t socket;

        for (i = 1; i <= call Sockets.size(); i++) {
            socket = call Sockets.get(i);
            printf("Socket: {\n\tflag: %hhu\n\tstate: %d\n\tsrc: %hhu\n\taddr: %hu\n\tport: %hhu\n}\n", socket.flag, socket.state, socket.src, socket.dest.addr, socket.dest.port);
        }
    }
}