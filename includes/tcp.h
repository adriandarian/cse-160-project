#ifndef TCP_H
#define TCP_H

enum{
    max_payload_size = 4,
    ATTEMPT_CONNECTION_TIME = 20000,
    CLIENT_WRITE_TIMER = 20000,
};

typedef nx_struct TCPPack{
    nx_uint8_t source_port;
    nx_uint8_t destination_port;
    nx_uint32_t sequence_number;
    nx_uint32_t acknowledgement_number;
    nx_uint8_t flag;
    nx_uint16_t advertisement_window;
    nx_uint32_t checksum;
    nx_uint16_t payload;
}TCPPack;

enum{
    DATA = 0,
    ACK = 1,
    SYN = 2,
    SYNACK = 3,
    FIN = 4,
    FINACK = 5,
};

void makeTCPPacket(TCPPack* TCP, nx_uint16_t source_port, nx_uint16_t destination_port, nx_uint32_t sequence_number, nx_uint32_t acknowledgement_number, nx_uint16_t flag, nx_uint16_t advertisement_window, nx_uint32_t checksum, nx_uint16_t payload) {
    TCP->source_port = source_port;
    TCP->destination_port = destination_port;
    TCP->sequence_number = sequence_number;
    TCP->acknowledgement_number = acknowledgement_number;
    TCP->flag = flag;
    TCP->advertisement_window = advertisement_window;
    TCP->checksum = checksum;
    TCP->payload = payload;
}

#endif