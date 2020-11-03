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
     *              Modules
     * #######################################
     */

    components RandomC as Random;
    TransportP.Random -> Random;

    components new SimpleSendC(AM_PACK) as TransportSenderC;
    TransportP.TransportSender->TransportSenderC;

    components new TimerMilliC() as HandshakeTimerC;
    TransportP.HandshakeTimer->HandshakeTimerC;

    /*
     * #######################################
     *              Data Structures
     * #######################################
     */

    components new HashmapC(socket_store_t, MAX_NUM_OF_SOCKETS) as SocketsC;
    TransportP.Sockets->SocketsC;
}