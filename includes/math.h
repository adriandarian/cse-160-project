#ifndef MATH_H
#define MATH_H

uint16_t max(uint16_t a, uint16_t b) {
    if (a >= b) {
        return a;
    } else {
        return b;
    }
}

uint16_t min(uint16_t a, uint16_t b) {
    if (a <= b) {
        return a;
    } else {
        return b;
    }
}

#endif
