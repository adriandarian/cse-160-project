# Project 3 Mid Review Design Doc
- [ ] Make TCP struct
- [ ] 3-Way Handshake
- [ ] Stop and Wait
- [ ] Implement sockets...
- [ ] Set up Test Server and Test Client 
### MAKE TCP STRUCT
***TCP PACKET***
**PROPERTIES**
- Source Port [INT, 16]
- Destination Port [INT, 16]
- Sequence Number [INT,32]
- Acknowledgment Number [INT,32]
- HdrLen [INT] [maybenot]
- Flags [tcpFlag]
- Advertised Window [INT, 16]
- Checksum [INT, 16]
- Data [INT{}]

***TCP FLAG***
- DATA
- ACK
- SYN
- SYNACK
- FIN
- FINACK

###IMPLEMENT 3-WAY HANDSHAKE###
***CLIENT*** Sends SYN 
***SERVER*** Sends SYNACK
***CLIENT*** Sends ACK
*PseudoCode*
```python
  avaliablePorts # List of ports that are not currently used
  timeout # How long to wait till trying handshake step again
  currentConnections # Destinations we already have a TCP connection with
  Client(destination,DestPort, data):
    if((destination, DestPort) not in currentConnections)):
      SrcPort = avaliableSocket.pop()
      # Begin 3-Way Handshake
      SequenceNum = Random(0,1000)
      CheckSum = computeCheckSum(data)
      bool isSynAckRecieved = False
      while(isSynAckRecieved == False):
        tcpPacket = createTCPPacket(SrcPort, DestPort, SequenceNum, 0, SYN, 0, CheckSum, 0)
        sendPacket(tcpPacket)
        startTimer(timeout)
        if(SynAckRecieved):
          isSynAckRecieved = True
          break
        pause
        if(Timer.finish):
          continue
        AckNum = RecievedSynAck.SeqNum + 1
        SequenceNum += 1
        createTCPPacket(SrcPort, DestPort, SequenceNum, AckNum, SYN, 0, CheckSum, 0)
        print("Connection Established")
    while(isAck    
    tcpPacket = CreateTCPPacket(SrcPort, DestPort, SequenceNum, AckNum, DATA, 0, CheckSum, 0)
    sendPacket(tcpPacket)
    
```

