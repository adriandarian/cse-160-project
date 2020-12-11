interface CommandHandler{
   // Events
   event void ping(uint16_t destination, uint8_t *payload);
   event void printNeighbors(uint16_t node);
   event void printRouteTable();
   event void printLinkState();
   event void printDistanceVector();
   event void setTestServer(uint16_t address, uint8_t port);
   event void setTestClient(uint16_t clientAddress, uint16_t destination, uint8_t sourcePort, uint8_t destinationPort, uint16_t transfer);
   event void closeClient(uint16_t clientAddress, uint16_t destination, uint8_t sourcePort, uint8_t destinationPort);
   event void setAppServer(uint16_t address, uint8_t port);
   event void setAppClient(uint16_t clientAddress, uint16_t serverAddress, uint8_t clientPort, uint8_t serverPort, uint8_t *username);
   event void broadcastMessage(uint16_t address, uint8_t *message);
   event void unicastMessage(uint16_t address, uint16_t clientAddress, uint8_t *message);
   event void printUsers(uint16_t address);
}
