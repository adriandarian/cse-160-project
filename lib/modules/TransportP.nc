/*
 * ~Transport Module~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
#include "../../includes/channels.h"
#include "../../includes/packet.h"
#include "../../includes/socket.h"

module TransportP{
    provides interface Transport;

    // Data Structure
    uses interface Hashmap<socket_store_t> as Sockets;
}

implementation{
    /*
     * #######################################
     *              Commands
     * #######################################
     */

    command socket_t Transport.socket() {
        socket_t fd = NULL;
        uint16_t i;
        socket_store_t socket;
        uint16_t SocketsSize = call Sockets.size();
        dbg(TRANSPORT_CHANNEL, "Sockets size %d\n", call Sockets.size());

        if (SocketsSize < MAX_NUM_OF_SOCKETS) {
            dbg(TRANSPORT_CHANNEL, "Allocating a new socket\n");
            fd = SocketsSize;
            socket.state = CLOSED;
            call Sockets.insert(fd, socket);
        }

        return fd;
    }

    command error_t Transport.bind(socket_t fd, socket_addr_t *addr) {
        uint16_t i;
        socket_store_t socket;
        dbg(TRANSPORT_CHANNEL, "Binding Server to socket\n");
        
        if (call Sockets.contains(fd)) {
            dbg(TRANSPORT_CHANNEL, "Socket exists\n");
            socket = call Sockets.get(fd);
            dbg(TRANSPORT_CHANNEL, "Received a socket from allocation\n");

            socket.dest = *addr;
            dbg(TRANSPORT_CHANNEL, "assigned new socket_addr_t\n");
            call Sockets.remove(fd);
            dbg(TRANSPORT_CHANNEL, "removed a socket from the allocation\n");
            call Sockets.insert(fd, socket);
            dbg(TRANSPORT_CHANNEL, "insert updated socket\n");
            
            return SUCCESS;
        }

        dbg(TRANSPORT_CHANNEL, "This should never happen\n");

        return FAIL;
    }

    command socket_t Transport.accept(socket_t fd) {
        // uint16_t i;
        // socket_store_t socket;
        // dbg(TRANSPORT_CHANNEL, "I am going to try to accept the socket at %hhu\n", fd);

        // if (fd >= 0 && fd < MAX_NUM_OF_SOCKETS) {
        //     dbg(TRANSPORT_CHANNEL, "fd in range\n");
        //     socket = call Sockets.get(fd);

        //     if (socket.state == LISTEN) {


        //         return fd;
        //     }
        // }

        // return NULL;
    }

    command uint16_t Transport.write(socket_t fd, uint8_t *buff, uint16_t bufflen) {

    }

    command error_t Transport.receive(pack* package) {

    }

    command uint16_t Transport.read(socket_t fd, uint8_t *buff, uint16_t bufflen) {

    }

    command error_t Transport.connect(socket_t fd, socket_addr_t * addr) {

    }

    command error_t Transport.close(socket_t fd) {

    }

    command error_t Transport.release(socket_t fd) {

    }

    command error_t Transport.listen(socket_t fd) {

    }
}