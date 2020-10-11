/*
 * ~Flooding Interface~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

interface Flooding{
    command error_t send(pack package, uint16_t destination);
    command void pingHandle(pack* message);
    command void LSAHandle(pack* message);
}
