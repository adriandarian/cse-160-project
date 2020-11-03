/*
 * ~TCP Interface~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

interface TCP{
    command void testServer(uint16_t address, uint8_t port);
    command void testClient(uint16_t destination, uint8_t sourcePort, uint8_t destinationPort, uint16_t transfer);
    command void closeClient(uint16_t clientAddress, uint16_t destination, uint8_t sourcePort, uint8_t destinationPort);
}