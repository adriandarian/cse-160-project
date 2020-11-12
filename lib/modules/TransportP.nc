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
    pack handshakePackage;
    TCPPack handshakeTCP;
    error_t clientConnected = FAIL;

    /*
     * #######################################
     *              Prototypes
     * #######################################
     */

    error_t checkForEstablishedSocket();

    /*
     * #######################################
     *              Commands
     * #######################################
     */

    command error_t Transport.hasConnected()
    {
        error_t temp = clientConnected;
        clientConnected = FAIL;
        return temp;
    }

    command void Transport.printSocket(socket_t fd)
    {
        socket_store_t socket;

        if (call Sockets.contains(fd))
        {
            socket = call Sockets.get(fd);
            printf("Socket[%hu]: {\n\tflag: %hhu\n\tstate: %d\n\tsrc: %hhu\n\tdest: {\n\t\taddr: %hu\n\t\tport: %hhu\n\t}\n}\n", fd, socket.flag, socket.state, socket.src, socket.dest.addr, socket.dest.port);
        }
    }

    command void Transport.printSockets()
    {
        uint16_t i;

        for (i = 1; i <= call Sockets.size(); i++)
        {
            call Transport.printSocket(i);
        }
    }

    command socket_t Transport.getFd(uint16_t clientAddress, uint16_t destination, uint8_t sourcePort, uint8_t destinationPort)
    {
        uint16_t i;
        socket_store_t socket;

        for (i = 1; i <= call Sockets.size(); i++)
        {
            socket = call Sockets.get(i);

            if (TOS_NODE_ID == clientAddress && socket.src == sourcePort && socket.dest.addr == destination && socket.dest.port == destinationPort)
            {
                return i;
            }
        }

        return 0;
    }

    command socket_t Transport.socket()
    {
        socket_t fd = NULL;
        socket_store_t socket;
        uint16_t SocketsSize = call Sockets.size();

        if (SocketsSize < MAX_NUM_OF_SOCKETS)
        {
            fd = SocketsSize + 1;

            socket.flag = DATA;
            socket.state = CLOSED;
            socket.src = TOS_NODE_ID;

            call Sockets.insert(fd, socket);
        }

        return fd;
    }

    command error_t Transport.bind(socket_t fd, socket_addr_t * addr)
    {
        socket_store_t socket;

        if (call Sockets.contains(fd))
        {
            socket = call Sockets.get(fd);
            socket.src = addr->port;

            call Sockets.insert(fd, socket);

            return SUCCESS;
        }

        dbg(TRANSPORT_CHANNEL, "This should never happen\n");

        return FAIL;
    }

    command socket_t Transport.accept(socket_t fd)
    {
        socket_store_t socket;

        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS - 1)
        {
            socket = call Sockets.get(fd);

            if (socket.state == LISTEN)
            {
                // make a copy in next socket
                call Sockets.insert(fd + 1, socket);
                return fd;
            }
        }

        return NULL;
    }

    command uint16_t Transport.write(socket_t fd, uint8_t * buff, uint16_t bufflen)
    {
        socket_store_t socket;
        uint16_t curByte = 0;
        uint8_t senderBuffer;
        //check if socket is valid:
        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS)
        {
            if (call Sockets.contains(fd))
            {
                socket = call Sockets.get(fd);
                //if socket is valid, it has to be on an established connection:
                if (socket.state != ESTABLISHED)
                {
                    // couldnt read any bytes
                    return 0;
                }
                else if (socket.state == ESTABLISHED)
                {

                    senderBuffer = abs((SOCKET_BUFFER_SIZE - socket.lastWritten % SOCKET_BUFFER_SIZE) + (socket.lastAck % SOCKET_BUFFER_SIZE));


                        while (bufflen > curByte && 0 < senderBuffer)
                    {
                        //write bytes??
                        memcpy(&socket.sendBuff[socket.lastWritten % SOCKET_BUFFER_SIZE], buff + curByte, 1);

                        curByte++;
                    }
                    //return bytes
                    return curByte;
                }
            }
        }
    }

    command error_t Transport.receive(pack * package)
    {
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

        switch (flag)
        {
        case (SYN):
            for (i = 1; i <= call Sockets.size(); i++)
            {
                socket = call Sockets.get(i);

                if (socket.state == LISTEN)
                {
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
            for (i = 1; i <= call Sockets.size(); i++)
            {
                socket = call Sockets.get(i);

                if (socket.state == SYN_SENT)
                {
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
            for (i = 1; i <= call Sockets.size(); i++)
            {
                socket = call Sockets.get(i);

                if (socket.state == SYN_RCVD)
                {
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

    command uint16_t Transport.read(socket_t fd, uint8_t * buff, uint16_t bufflen)
    {
    }

    command error_t Transport.connect(socket_t fd, socket_addr_t * addr)
    {
        socket_store_t socket;
        uint32_t sequenceNum = call Random.rand16() % 1000;
        uint32_t ackNum = 0;
        uint8_t flag = SYN;
        uint16_t advertisement_window = 1; // for stop and wait
        uint32_t checksum;
        uint16_t payload = 0;

        if (call Sockets.contains(fd))
        {
            socket = call Sockets.get(fd);

            if (socket.state == CLOSED)
            {
                socket.dest = *addr;
                socket.flag = SYN;
                socket.state = SYN_SENT;

                call Sockets.insert(fd, socket);

                makeTCPPacket(&handshakeTCP, socket.dest.port, addr->port, sequenceNum, ackNum, flag, advertisement_window, checksum, payload);
                makePack(&handshakePackage, TOS_NODE_ID, addr->addr, MAX_TTL, PROTOCOL_TCP, 0, &handshakeTCP, PACKET_MAX_PAYLOAD_SIZE);

                if (call TransportSender.send(handshakePackage, call LinkState.getFromRoutingTable(addr->addr)) == SUCCESS)
                {
                    call HandshakeTimer.startPeriodic(20000);
                }
            }
        }

        return FAIL;
    }

    command error_t Transport.close(socket_t fd)
    {
        socket_store_t socket;

        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS)
        {
            if (call Sockets.contains(fd))
            {
                socket = call Sockets.get(fd);

                socket.state = CLOSED;

                call Sockets.insert(fd, socket);

                return SUCCESS;
            }
        }

        return FAIL;
    }

    command error_t Transport.release(socket_t fd)
    {
    }

    command error_t Transport.listen(socket_t fd)
    {
        socket_store_t socket;

        if (fd > 0 && fd < MAX_NUM_OF_SOCKETS)
        {
            if (call Sockets.contains(fd))
            {
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

    event void HandshakeTimer.fired()
    {
        if (checkForEstablishedSocket() == SUCCESS)
        {
            call HandshakeTimer.stop();
        }
    }

    /*
     * #######################################
     *              Methods
     * #######################################
     */

    error_t checkForEstablishedSocket()
    {
        uint16_t i;
        socket_store_t socket;

        for (i = 1; i <= call Sockets.size(); i++)
        {
            socket = call Sockets.get(i);

            if (socket.state == ESTABLISHED)
            {
                clientConnected = SUCCESS;
                return SUCCESS;
            }
        }

        return FAIL;
    }
}