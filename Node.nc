/*
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   2013/09/03
 *
 */
#include <Timer.h>
#include "includes/command.h"
#include "includes/packet.h"
#include "includes/linkstate.h"
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   // Modules
   uses interface Boot;
   uses interface SplitControl as AMControl;
   uses interface Receive;
   uses interface SimpleSend as Sender;
   uses interface CommandHandler;
   uses interface NeighborDiscovery;
   uses interface Flooding;
   uses interface LinkState;
   uses interface TCP;
   uses interface Transport;
}

implementation{
   pack sendPackage;
   uint16_t seqNum = 0;

   event void Boot.booted() {
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
      // Initialize Neighbor Discovery as each node awakes
      call NeighborDiscovery.start();

      // Initializes Link State but has a delay to wait for the initial Neighbor Discovery to finish
      call LinkState.start();
   }

   event void AMControl.startDone(error_t err) {
      if (err == SUCCESS) {
         dbg(GENERAL_CHANNEL, "Radio On\n");
      } else {
         // Retry until successful
         call AMControl.start();
      }
   }

   event void AMControl.stopDone(error_t err) {
      // DEBUG: any error messages
      dbg(GENERAL_CHANNEL, "An Error occurred: %d\n", err);
   }

   event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {      
      pack* message = (pack*) payload;

      if (len != sizeof(pack)) {
         dbg(GENERAL_CHANNEL, "Unknown Packet Type %u\n", len);
         logPack(message);

         return msg;
      }

      switch (message->protocol) {
         case PROTOCOL_NEIGHBOR_PING:
         case PROTOCOL_NEIGHBOR_PING_REPLY: {
            call NeighborDiscovery.pingHandle(message);
            break;
         }
         case PROTOCOL_PING:
         case PROTOCOL_PING_REPLY:
         case PROTOCOL_TCP: {
            if (message->dest == TOS_NODE_ID) {
               call Transport.receive(message);
            } else {
               if (call LinkState.checkIfInRoutingTable(message->dest)) {
                  makePack(&sendPackage, message->src, message->dest, message->TTL - 1, message->protocol, message->seq, message->payload, PACKET_MAX_PAYLOAD_SIZE);
                  call Sender.send(sendPackage, call LinkState.getFromRoutingTable(message->dest));
               } else {
                  call Flooding.pingHandle(message);
               }
            }
         }
         case PROTOCOL_APP: {
            dbg(APP_CHANNEL, "in global receiver %s\n", message->payload);
            if (message->dest == TOS_NODE_ID) {
               call TCP.receive(message);
            } else {
               if (call LinkState.checkIfInRoutingTable(message->dest)) {
                  makePack(&sendPackage, message->src, message->dest, message->TTL - 1, message->protocol, message->seq, message->payload, PACKET_MAX_PAYLOAD_SIZE);
                  call Sender.send(sendPackage, call LinkState.getFromRoutingTable(message->dest));
               }
            }
         }
         case PROTOCOL_LINKED_STATE: {
            call Flooding.LSAHandle(message);
            call LinkState.LSHandler(message);
         }
      }
         
      return msg;
   }

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload) {
      dbg(GENERAL_CHANNEL, "Ping sent to node %d from node %d\n", destination, TOS_NODE_ID);

      if (call LinkState.checkIfInRoutingTable(destination)) {
         // Execute Flooding
         makePack(&sendPackage, TOS_NODE_ID, destination, MAX_TTL, PROTOCOL_PING, seqNum, payload, PACKET_MAX_PAYLOAD_SIZE);
         seqNum = seqNum + 1;
         call Sender.send(sendPackage, call LinkState.getFromRoutingTable(destination));
      } else {
         // Execute Flooding
         makePack(&sendPackage, TOS_NODE_ID, destination, 0, PROTOCOL_PING, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
         call Flooding.send(&sendPackage, destination);
      }
   }

   event void CommandHandler.printNeighbors(uint16_t node) {
      dbg(GENERAL_CHANNEL, "Printing Neighbors of node %d\n", node);
      call NeighborDiscovery.print();
   }

   event void CommandHandler.printRouteTable() {
      dbg(ROUTING_CHANNEL, "Printing Routing Table\n");
      call LinkState.printRoutingTable();
   }

   event void CommandHandler.printLinkState() {}

   event void CommandHandler.printDistanceVector() {}

   event void CommandHandler.setTestServer(uint16_t address, uint8_t port) {
      dbg(TRANSPORT_CHANNEL, "Server: Node %hu listening on port %hhu...\n", address, port);
      call TCP.testServer(address, port);
   }

   event void CommandHandler.setTestClient(uint16_t clientAddress, uint16_t destination, uint8_t sourcePort, uint8_t destinationPort, uint16_t transfer) {
      dbg(TRANSPORT_CHANNEL, "Client: Connecting node %hu's port %hhu to node %hu's port %hhu...\n", clientAddress, sourcePort, destination, destinationPort);
      call TCP.testClient(destination, sourcePort, destinationPort, transfer);
   }

   event void CommandHandler.closeClient(uint16_t clientAddress, uint16_t destination, uint8_t sourcePort, uint8_t destinationPort) {
      dbg(TRANSPORT_CHANNEL, "Killing node %hu's connection from port %hhu to node %hu's %hhu\n", clientAddress, sourcePort, destination, destinationPort);
      call TCP.closeClient(clientAddress, destination, sourcePort, destinationPort);
   }

   event void CommandHandler.setAppServer(uint16_t address, uint8_t port) {
      dbg(APP_CHANNEL, "Server: Node %hu listening on port %hhu...\n", address, port);
      call TCP.setAppServer(address, port);
   }

   event void CommandHandler.setAppClient(uint16_t clientAddress, uint16_t serverAddress, uint8_t clientPort, uint8_t serverPort, uint8_t *username) {
      dbg(APP_CHANNEL, "Username: %s\n", username);
      call TCP.setAppClient(clientAddress, serverAddress, clientPort, serverPort, username);
   }

   event void CommandHandler.broadcastMessage(uint16_t address, uint8_t *message) {
      dbg(APP_CHANNEL, "Message: %s\n", message);
      call TCP.broadcastMessage(address, message);
   }

   event void CommandHandler.unicastMessage(uint16_t address, uint8_t *username, uint8_t *message) {
      dbg(APP_CHANNEL, "Username: %s, Message: %s\n", username, message);
      call TCP.unicastMessage(address, username, message);
   }

   event void CommandHandler.printUsers(uint16_t address) {
      dbg(APP_CHANNEL, "Printing all users on node: %hu\n", address);
      call TCP.printUsers();
   }
}
