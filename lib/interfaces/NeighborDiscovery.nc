/*
 * ~NEIGHBOR DISCOVERY INTERFACE~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

interface NeighborDiscovery{
    command error_t start();
    command error_t print();
    command error_t getNeighbors();
}