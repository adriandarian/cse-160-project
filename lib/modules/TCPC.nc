/*
 * ~TCP Config~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
configuration TCPC{
    provides interface TCP;
}

implementation{
    components TCPP;
    TCP = TCPP;

    /*
     * #######################################
     *              Modules
     * #######################################
     */

    components new TimerMilliC() as ServerTimerC;
    TCPP.ServerTimer->ServerTimerC;

    components new TimerMilliC() as ClientTimerC;
    TCPP.ClientTimer->ClientTimerC;

    // Transport
    components TransportC;
    TCPP.Transport->TransportC;

    /*
     * #######################################
     *              Data Structures
     * #######################################
     */

    components new ListC(uint8_t, 64) as AcceptedSocketsC;
    TCPP.AcceptedSockets->AcceptedSocketsC;
}