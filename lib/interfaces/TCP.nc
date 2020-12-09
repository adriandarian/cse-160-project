/*
 * ~TCP Interface~
 * Busher Bridi, Adrian Darian 
 * UC MERCED, Prof. Cerpa CSE 160, 2020
 */

#include "../../includes/socket.h"

interface TCP{
    command void testServer(uint16_t address, uint8_t port);
    command void testClient(uint16_t destination, uint8_t sourcePort, uint8_t destinationPort, uint16_t transfer);
    command void closeClient(uint16_t clientAddress, uint16_t destination, uint8_t sourcePort, uint8_t destinationPort);
    command void setAppServer(uint16_t address, uint8_t port);
    command void setAppClient(uint16_t clientAddress, uint16_t serverAddress, uint8_t clientPort, uint8_t serverPort, uint8_t *username);
    command void broadcastMessage(uint16_t address, uint8_t *message);
    command void unicastMessage(uint16_t address, uint8_t *username, uint8_t *message);
    command void printUsers();
    command error_t receive(pack* p);
}