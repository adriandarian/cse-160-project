/*
 * ~Transport Config~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
#include "../../includes/socket.h"

configuration TransportC{
    provides interface Transport;
}

implementation{
    components TransportP;
    Transport = TransportP;

    /*
     * #######################################
     *              Data Structures
     * #######################################
     */

    components new HashmapC(socket_store_t, MAX_NUM_OF_SOCKETS) as SocketsC;
    TransportP.Sockets->SocketsC;
}