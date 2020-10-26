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

### Example Dijkstra's Algo Working From our Code

0:2:55.781252552 DEBUG (19): Src: 19 with size 19 [
0:2:55.781252552 DEBUG (19): S: 6 (N: 7, C: 1)
0:2:55.781252552 DEBUG (19): S: 6 (N: 5, C: 1)
0:2:55.781252552 DEBUG (19): S: 1 (N: 2, C: 1)
0:2:55.781252552 DEBUG (19): S: 3 (N: 4, C: 1)
0:2:55.781252552 DEBUG (19): S: 3 (N: 2, C: 1)
0:2:55.781252552 DEBUG (19): S: 18 (N: 19, C: 1)
0:2:55.781252552 DEBUG (19): S: 18 (N: 17, C: 1)
0:2:55.781252552 DEBUG (19): S: 13 (N: 14, C: 1)
0:2:55.781252552 DEBUG (19): S: 13 (N: 12, C: 1)
0:2:55.781252552 DEBUG (19): S: 15 (N: 16, C: 1)
0:2:55.781252552 DEBUG (19): S: 15 (N: 14, C: 1)
0:2:55.781252552 DEBUG (19): S: 12 (N: 11, C: 1)
0:2:55.781252552 DEBUG (19): S: 12 (N: 13, C: 1)
0:2:55.781252552 DEBUG (19): S: 10 (N: 11, C: 1)
0:2:55.781252552 DEBUG (19): S: 10 (N: 9, C: 1)
0:2:55.781252552 DEBUG (19): S: 8 (N: 9, C: 1)
0:2:55.781252552 DEBUG (19): S: 8 (N: 7, C: 1)
0:2:55.781252552 DEBUG (19): S: 7 (N: 8, C: 1)
0:2:55.781252552 DEBUG (19): S: 7 (N: 6, C: 1)
0:2:55.781252552 DEBUG (19): S: 5 (N: 4, C: 1)
0:2:55.781252552 DEBUG (19): S: 5 (N: 6, C: 1)
0:2:55.781252552 DEBUG (19): S: 2 (N: 1, C: 1)
0:2:55.781252552 DEBUG (19): S: 2 (N: 3, C: 1)
0:2:55.781252552 DEBUG (19): S: 17 (N: 18, C: 1)
0:2:55.781252552 DEBUG (19): S: 17 (N: 16, C: 1)
0:2:55.781252552 DEBUG (19): S: 19 (N: 18, C: 1)
0:2:55.781252552 DEBUG (19): S: 16 (N: 15, C: 1)
0:2:55.781252552 DEBUG (19): S: 16 (N: 17, C: 1)
0:2:55.781252552 DEBUG (19): S: 14 (N: 15, C: 1)
0:2:55.781252552 DEBUG (19): S: 14 (N: 13, C: 1)
0:2:55.781252552 DEBUG (19): S: 9 (N: 10, C: 1)
0:2:55.781252552 DEBUG (19): S: 9 (N: 8, C: 1)
0:2:55.781252552 DEBUG (19): S: 11 (N: 10, C: 1)
0:2:55.781252552 DEBUG (19): S: 11 (N: 12, C: 1)
0:2:55.781252552 DEBUG (19): S: 4 (N: 5, C: 1)
0:2:55.781252552 DEBUG (19): S: 4 (N: 3, C: 1)
0:2:55.781252552 DEBUG (19): ]
0:2:55.781252552 DEBUG (19): Generated Adjacency Matrix
[ ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ]
[ ,  , 1,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ]
[ , 1,  , 1,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ]
[ ,  , 1,  , 1,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ]
[ ,  ,  , 1,  , 1,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ]
[ ,  ,  ,  , 1,  , 1,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ]
[ ,  ,  ,  ,  , 1,  , 1,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ]
[ ,  ,  ,  ,  ,  , 1,  , 1,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ]
[ ,  ,  ,  ,  ,  ,  , 1,  , 1,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ]
[ ,  ,  ,  ,  ,  ,  ,  , 1,  , 1,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ]
[ ,  ,  ,  ,  ,  ,  ,  ,  , 1,  , 1,  ,  ,  ,  ,  ,  ,  ,  ,  ]
[ ,  ,  ,  ,  ,  ,  ,  ,  ,  , 1,  , 1,  ,  ,  ,  ,  ,  ,  ,  ]
[ ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  , 1,  , 1,  ,  ,  ,  ,  ,  ,  ]
[ ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  , 1,  , 1,  ,  ,  ,  ,  ,  ]
[ ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  , 1,  , 1,  ,  ,  ,  ,  ]
[ ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  , 1,  , 1,  ,  ,  ,  ]
[ ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  , 1,  , 1,  ,  ,  ]
[ ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  , 1,  , 1,  ,  ]
[ ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  , 1,  , 1,  ]
[ ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  , 1,  ,  ]
[ ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ,  ]
0:2:55.781252552 DEBUG (19): Initial Cost Matrix
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111,   1  , 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111,   1  , 11111, 11111]
[11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111, 11111]
Distance of node 1 = 18
Path = 1<-2<-3<-4<-5<-6<-7<-8<-9<-10<-11<-12<-13<-14<-15<-16<-17<-18<-19
Distance of node 2 = 17
Path = 2<-3<-4<-5<-6<-7<-8<-9<-10<-11<-12<-13<-14<-15<-16<-17<-18<-19
Distance of node 3 = 16
Path = 3<-4<-5<-6<-7<-8<-9<-10<-11<-12<-13<-14<-15<-16<-17<-18<-19
Distance of node 4 = 15
Path = 4<-5<-6<-7<-8<-9<-10<-11<-12<-13<-14<-15<-16<-17<-18<-19
Distance of node 5 = 14
Path = 5<-6<-7<-8<-9<-10<-11<-12<-13<-14<-15<-16<-17<-18<-19
Distance of node 6 = 13
Path = 6<-7<-8<-9<-10<-11<-12<-13<-14<-15<-16<-17<-18<-19
Distance of node 7 = 12
Path = 7<-8<-9<-10<-11<-12<-13<-14<-15<-16<-17<-18<-19
Distance of node 8 = 11
Path = 8<-9<-10<-11<-12<-13<-14<-15<-16<-17<-18<-19
Distance of node 9 = 10
Path = 9<-10<-11<-12<-13<-14<-15<-16<-17<-18<-19
Distance of node 10 = 9
Path = 10<-11<-12<-13<-14<-15<-16<-17<-18<-19
Distance of node 11 = 8
Path = 11<-12<-13<-14<-15<-16<-17<-18<-19
Distance of node 12 = 7
Path = 12<-13<-14<-15<-16<-17<-18<-19
Distance of node 13 = 6
Path = 13<-14<-15<-16<-17<-18<-19
Distance of node 14 = 5
Path = 14<-15<-16<-17<-18<-19
Distance of node 15 = 4
Path = 15<-16<-17<-18<-19
Distance of node 16 = 3
Path = 16<-17<-18<-19
Distance of node 17 = 2
Path = 17<-18<-19
Distance of node 18 = 1
Path = 18<-19
Distance of node 19 = 0
Path = 19<-19