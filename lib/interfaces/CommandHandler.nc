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
   event void setAppServer();
   event void setAppClient();
}
