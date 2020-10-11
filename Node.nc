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
#include "includes/CommandMsg.h"
#include "includes/sendInfo.h"
#include "includes/channels.h"

module Node{
   uses interface Boot;
   uses interface SplitControl as AMControl;
   uses interface Receive;
   
   uses interface List<uint16_t> as List;

   uses interface SimpleSend as Sender;
   uses interface CommandHandler;
   uses interface NeighborDiscovery;
   uses interface Flooding;
   uses interface LinkState;
}

implementation{
   pack sendPackage;

   event void Boot.booted() {
      call AMControl.start();
      dbg(GENERAL_CHANNEL, "Booted\n");
      
   }

   event void AMControl.startDone(error_t err) {
      if (err == SUCCESS) {
         dbg(GENERAL_CHANNEL, "Radio On\n");
         
         // Initialize Neighbor Discovery as each node awakes
         call NeighborDiscovery.start();
         call LinkState.start();
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
            call Flooding.pingHandle(message);
         } else if (message->protocol == PROTOCOL_LINKED_STATE) {
            // Handle Pings in Link State Module
            call LinkState.LSHandler(message);
         }
         
         return msg;
      }

      dbg(GENERAL_CHANNEL, "Unknown Packet Type %u\n", len);
      return msg;
   }

   event void CommandHandler.ping(uint16_t destination, uint8_t *payload) {
      dbg(GENERAL_CHANNEL, "Ping sent to node %u from node %u\n", destination, TOS_NODE_ID);

      // Execute Flooding
      makePack(&sendPackage, TOS_NODE_ID, destination, 0, PROTOCOL_PING, 0, payload, PACKET_MAX_PAYLOAD_SIZE);
      call Flooding.send(sendPackage, destination);
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

   event void CommandHandler.setTestServer() {}

   event void CommandHandler.setTestClient() {}

   event void CommandHandler.setAppServer() {}

   event void CommandHandler.setAppClient() {}
}
