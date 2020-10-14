# Design Document

## Modules

* NeighborDiscovery->provides neighbortable
* neighborTable
* Flooding
* IPForwarding
* LinkState -> RoutingTable

## Data Structure

> values do not allow other Data Structures to be inserted as a value type

* List
  * basically a Link List
* Hashmap
  * Key value pairing

## Topology

       example.topo

             1
           /  \
          3 __ 2
         / \  \ \
        6__ 4 __ 5
            |    |
       9 __ 8 __ 7

LSA | source | seq num | num entries | [Node | Cost] |
FH  | flood source | sequence number | Time to live  | package(source, ttl, seq, ... payload=LSA)
LLH | source address | destination address | LL Type |

A ------------------------- B -------------------------------- C

| A | 27 | 1 | [B | 1] |          | A | 27 | 1 | [B | 1] |
| A     | 52     | 15  |          | A     | 52     | 14  |
| A    | B     | Flood |          | B    | C     | Flood |
