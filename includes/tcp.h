#ifndef TCP_H
#define TCP_H

enum{
    MAX_PAYLOAD_SIZE = 128,
    ATTEMPT_CONNECTION_TIME = 20000,
    CLIENT_WRITE_TIMER = 20000,
};

enum tcp_flag{
    DATA,
    SYN,
    SYN_ACK,
    ACK,
    FIN,
    FIN_ACK,
};

typedef struct TCPPack{
    uint8_t source_port;
    uint8_t destination_port;
    uint32_t sequence_number;
    uint32_t acknowledgement_number;
    enum tcp_flag flag;
    uint16_t advertisement_window;
    uint32_t checksum;
    uint8_t payload[MAX_PAYLOAD_SIZE];
}TCPPack;

void makeTCPPacket(TCPPack* TCP, uint16_t source_port, uint16_t destination_port, uint32_t sequence_number, uint32_t acknowledgement_number, uint16_t flag, uint16_t advertisement_window, uint32_t checksum, uint8_t* payload) {
    TCP->source_port = source_port;
    TCP->destination_port = destination_port;
    TCP->sequence_number = sequence_number;
    TCP->acknowledgement_number = acknowledgement_number;
    TCP->flag = flag;
    TCP->advertisement_window = advertisement_window;
    TCP->checksum = checksum;
    // TCP->payload = payload;
    memcpy(TCP->payload, payload, MAX_PAYLOAD_SIZE);
}

#endif