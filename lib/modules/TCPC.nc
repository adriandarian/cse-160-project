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

    components new TimerMilliC() as ConnectionTimerC;
    TCPP.ConnectionTimer->ConnectionTimerC;

    components new TimerMilliC() as ClientTimerC;
    TCPP.ClientTimer->ClientTimerC;

    components new TimerMilliC() as CloseTimerC;
    TCPP.CloseTimer->CloseTimerC;

    // Transport
    components TransportC;
    TCPP.Transport->TransportC;

    /*
     * #######################################
     *              Data Structures
     * #######################################
     */

    components new ListC(uint8_t, 10) as AcceptedSocketsC;
    TCPP.AcceptedSockets->AcceptedSocketsC;
}