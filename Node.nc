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
      // dbg(GENERAL_CHANNEL, "Booted\n");
      // Initialize Neighbor Discovery as each node awakes
      call NeighborDiscovery.start();

      // Initializes Link State but has a delay to wait for the initial Neighbor Discovery to finish
      call LinkState.start();
   }

   event void AMControl.startDone(error_t err) {
      if (err == SUCCESS) {
         // dbg(GENERAL_CHANNEL, "Radio On\n");
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
      if (len == sizeof(pack)) {
         pack* message = (pack*) payload;

         // Output the full package being passed through
         // logPack(message);

         if (message->protocol == PROTOCOL_NEIGHBOR_PING || message->protocol == PROTOCOL_NEIGHBOR_PING_REPLY) {
            // Handle Pings in Neighbor Discovery Module
            call NeighborDiscovery.pingHandle(message);
         } else if (message->protocol == PROTOCOL_PING || message->protocol == PROTOCOL_PING_REPLY) {
            // Handle Pings in Flooding Module
            if (message->dest == TOS_NODE_ID) {
               dbg(GENERAL_CHANNEL, "This is the Destination from: %d to %d with %d\n", message->src, message->dest, message->seq);
               logPack(message);
            } else {
               if (call LinkState.checkIfInRoutingTable(message->dest)) {
                  // Execute Flooding
                  makePack(&sendPackage, message->src, message->dest, message->TTL - 1, message->protocol, message->seq, message->payload, PACKET_MAX_PAYLOAD_SIZE);
                  call Sender.send(sendPackage, call LinkState.getFromRoutingTable(message->dest));
               } else {
                  call Flooding.pingHandle(message);
               }
            }
         } else if (message->protocol == PROTOCOL_LINKED_STATE) {
            call Flooding.LSAHandle(message);
            call LinkState.LSHandler(message);
         } else if (message->protocol == PROTOCOL_TCP) {
            call Transport.receive(message);
         }
         
         return msg;
      }

      dbg(GENERAL_CHANNEL, "Unknown Packet Type %u\n", len);
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

   event void CommandHandler.setAppServer() {}

   event void CommandHandler.setAppClient() {}
}
