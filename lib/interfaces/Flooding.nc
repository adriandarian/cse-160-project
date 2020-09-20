/*
 * ~Flooding INTERFACE~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

interface Flooding{
    command error_t start();
    command void forwardHandle(pack *package);
    command void pingHandle(uint16_t destination, uint8_t *payload);
}
