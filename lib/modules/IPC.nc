/*
 * ~IP Config~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */
configuration IPC{
    provides interface IP;
}

implementation{
    components IPP;
    IP = IPP;
}