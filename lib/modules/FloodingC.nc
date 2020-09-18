/*
 * ~Flooding CONFIG~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
 
configuration FloodingC {
    provides interface Flooding;
}

implementation{
    components FloodingP;
    Flooding = FloodingP;

    components new AMReceiverC(AM_PACK);
    FloodingP.Receiver->AMReceiverC;

    components new SimpleSendC(AM_PACK);
    FloodingP.Sender->SimpleSendC;
}