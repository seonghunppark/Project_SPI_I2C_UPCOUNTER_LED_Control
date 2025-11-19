/*
 * main.c
 *
 *  Created on: 2025. 11. 17.
 *      Author: kccistc
 */


/*
 * I2C-LED Control System (간결 버전)
 *
 * 동작 방식:
 * - WRITE 모드: Master Switch → Slave LED
 * - READ 모드: Slave Switch → Master LED
 * - 모드 전환: BTN (axi_gpio_1의 버튼 0번)
 */

#include "xil_printf.h"
#include "xparameters.h"
#include "sleep.h"

//// 상준 선배님 ///////
#define I2C_CTR (*(volatile uint32_t *)(I2C_BASE + I2C_CTRL_REG))
#define I2C_TXR (*(volatile uint32_t *)(I2C_BASE + I2C_TX_REG))
#define I2C_RXR (*(volatile uint32_t *)(I2C_BASE + I2C_RX_REG))
#define I2C_SR (*(volatile uint32_t *)(I2C_BASE + I2C_STATUS_REG))
#define LED_GPIO (*(volatile uint32_t *)(LED_GPIO_BASE))
#define SWITCH_IDR (*(volatile uint32_t *)(SWITCH_GPIO_BASE))

// ===== 하드웨어 주소 =====
#define I2C_BASE         XPAR_LED_LAST_0_S00_AXI_BASEADDR
#define LED_GPIO_BASE    0x40000000
#define BTN_GPIO_BASE    0x40010000
#define SWITCH_GPIO_BASE 0x40020000

// ===== I2C 레지스터 오프셋 =====
#define I2C_CTRL_REG     0x00
#define I2C_TX_REG       0x04
#define I2C_RX_REG       0x08
#define I2C_STATUS_REG   0x0C

// ===== GPIO 레지스터 오프셋 =====
#define GPIO_DATA        0x00
#define GPIO_TRI         0x04

// ===== I2C 제어 비트 =====
#define I2C_EN           (1 << 2)
#define I2C_START        (1 << 1)
#define I2C_STOP         (1 << 0)

// ===== I2C 슬레이브 주소 =====
#define SLAVE_ADDR_WRITE 0xA8
#define SLAVE_ADDR_READ  0xA9

// ===== 타임아웃 설정 =====
#define I2C_TIMEOUT      1000000

// ===== 시스템 모드 =====
typedef enum {
    MODE_WRITE = 0,
    MODE_READ = 1
} mode_t;

// ===== 시스템 컨텍스트 =====
typedef struct {
    volatile unsigned int *i2c_base;
    volatile unsigned int *led_gpio;
    volatile unsigned int *btn_gpio;
    volatile unsigned int *switch_gpio;
    mode_t mode;
} sys_t;

// ===== 레지스터 읽기/쓰기 =====
static inline void write_reg(volatile unsigned int *base, unsigned int offset, unsigned int value) {
    *(base + (offset / 4)) = value;
}

static inline unsigned int read_reg(volatile unsigned int *base, unsigned int offset) {
    return *(base + (offset / 4));
}

// ===== I2C 함수들 =====

// I2C 초기화
void i2c_init(sys_t *sys) {
    write_reg(sys->i2c_base, I2C_CTRL_REG, I2C_EN);
    usleep(1000);
}

// tx_done 대기
int wait_tx_done(sys_t *sys) {
    unsigned int timeout = I2C_TIMEOUT;
    while (timeout--) {
        if (read_reg(sys->i2c_base, I2C_STATUS_REG) & (1 << 2)) {
            return 0;  // 성공
        }
    }
    return -1;  // 타임아웃
}

// rx_done 대기
int wait_rx_done(sys_t *sys) {
    unsigned int timeout = I2C_TIMEOUT;
    while (timeout--) {
        if (read_reg(sys->i2c_base, I2C_STATUS_REG) & (1 << 0)) {
            return 0;  // 성공
        }
    }
    return -1;  // 타임아웃
}

// I2C 바이트 쓰기
int i2c_write(sys_t *sys, unsigned char data, int start) {
    // TX 레지스터에 데이터 쓰기
    write_reg(sys->i2c_base, I2C_TX_REG, data);

    // START 펄스 생성 (필요 시)
    if (start) {
        write_reg(sys->i2c_base, I2C_CTRL_REG, I2C_EN | I2C_START);
        usleep(1);
        write_reg(sys->i2c_base, I2C_CTRL_REG, I2C_EN);
    }

    // 전송 완료 대기
    return wait_tx_done(sys);
}

// I2C 바이트 읽기
unsigned char i2c_read(sys_t *sys) {
    if (wait_rx_done(sys) != 0) {
        return 0xFF;  // 에러
    }
    return (unsigned char)(read_reg(sys->i2c_base, I2C_RX_REG) & 0xFF);
}

// I2C STOP 조건
void i2c_stop(sys_t *sys) {
    write_reg(sys->i2c_base, I2C_CTRL_REG, I2C_EN | I2C_STOP);
    usleep(10);
    write_reg(sys->i2c_base, I2C_CTRL_REG, I2C_EN);
}

// ===== GPIO 함수들 =====

// GPIO 초기화
void gpio_init(sys_t *sys) {
    // LED: 출력
    *(sys->led_gpio + (GPIO_TRI / 4)) = 0x00000000;
    *(sys->led_gpio + (GPIO_DATA / 4)) = 0x00000000;

    // BTN: 입력
    *(sys->btn_gpio + (GPIO_TRI / 4)) = 0xFFFFFFFF;

    // SWITCH: 입력
    *(sys->switch_gpio + (GPIO_TRI / 4)) = 0xFFFFFFFF;
}

// 버튼 읽기
unsigned int read_btn(sys_t *sys) {
    return *(sys->btn_gpio + (GPIO_DATA / 4));
}

// 스위치 읽기
unsigned int read_switch(sys_t *sys) {
    return *(sys->switch_gpio + (GPIO_DATA / 4));
}

// LED 쓰기
void write_led(sys_t *sys, unsigned int value) {
    *(sys->led_gpio + (GPIO_DATA / 4)) = value;
}

// ===== WRITE 모드 =====
int do_write(sys_t *sys) {
    unsigned char sw_val = read_switch(sys) & 0xFF;

    xil_printf("WRITE: SW=0x%02X -> Slave\r\n", sw_val);

    // 주소 전송 (START 포함)
    if (i2c_write(sys, SLAVE_ADDR_WRITE, 1) != 0) {
        xil_printf("  ERR: Addr timeout\r\n");
        i2c_stop(sys);
        return -1;
    }

    // 데이터 전송
    if (i2c_write(sys, sw_val, 0) != 0) {
        xil_printf("  ERR: Data timeout\r\n");
        i2c_stop(sys);
        return -1;
    }

    // STOP
    i2c_stop(sys);
    xil_printf("  OK\r\n");
    return 0;
}

// ===== READ 모드 =====
int do_read(sys_t *sys) {
    unsigned char rx_val;

    xil_printf("READ: Slave -> Master\r\n");

    // 주소 전송 (START 포함)
    if (i2c_write(sys, SLAVE_ADDR_READ, 1) != 0) {
        xil_printf("  ERR: Addr timeout\r\n");
        i2c_stop(sys);
        return -1;
    }

    // 데이터 수신
    rx_val = i2c_read(sys);

    // STOP
    i2c_stop(sys);

    // Master LED 업데이트
    write_led(sys, rx_val);
    xil_printf("  RX=0x%02X, LED updated\r\n", rx_val);
    return 0;
}

// ===== 버튼 디바운싱 =====
unsigned int debounce(sys_t *sys, unsigned int prev) {
    unsigned int curr = read_btn(sys);
    if (curr != prev) {
        usleep(20000);  // 20ms
        curr = read_btn(sys);
    }
    return curr;
}

// ===== 버튼 이벤트 처리 =====
void check_button(sys_t *sys) {
    static unsigned int prev_btn = 0;
    unsigned int curr_btn = debounce(sys, prev_btn);

    // 상승 엣지 감지 (버튼 0번)
    if ((curr_btn & 0x01) && !(prev_btn & 0x01)) {
        // 모드 전환
        sys->mode = (sys->mode == MODE_WRITE) ? MODE_READ : MODE_WRITE;
        xil_printf("\n*** MODE: %s ***\n\n", sys->mode == MODE_WRITE ? "WRITE" : "READ");
    }

    prev_btn = curr_btn;
}

// ===== 시스템 초기화 =====
void sys_init(sys_t *sys) {
    sys->i2c_base = (volatile unsigned int *)I2C_BASE;
    sys->led_gpio = (volatile unsigned int *)LED_GPIO_BASE;
    sys->btn_gpio = (volatile unsigned int *)BTN_GPIO_BASE;
    sys->switch_gpio = (volatile unsigned int *)SWITCH_GPIO_BASE;
    sys->mode = MODE_WRITE;

    xil_printf("\n========================================\n");
    xil_printf("I2C-LED Control v2.2\n");
    xil_printf("========================================\n");
    xil_printf("Master Switch[7:0] -> Slave LED[7:0]\n");
    xil_printf("Slave Switch[7:0]  -> Master LED[7:0]\n");
    xil_printf("BTN[0] = Mode Toggle\n");
    xil_printf("========================================\n\n");

    gpio_init(sys);
    i2c_init(sys);

    xil_printf("Init OK. Mode: WRITE\n\n");
}

//// ===== 메인 =====
//int main() {
////    sys_t sys;
////
////    sys_init(&sys);
//
//    while (1) {
////        // 버튼 체크
////        check_button(&sys);
////
////        // 현재 모드 실행
////        if (sys.mode == MODE_WRITE) {
////            do_write(&sys);
////        } else {
////            do_read(&sys);
////        }
//
//        sleep(1000);
//    }
//
//    return 0;
//}


int main ()
{

   ////////// write C Code /////////////////

   I2C_TXR = 0b10101000; //주소 보내기 -> 예상 : slave led[7:0]
   sleep(1); // 10s 대기
   I2C_CTR = 0b00000110;

   usleep(12); // 10us이상

   while(1){
   I2C_CTR = 0b00000100; // write
   I2C_TXR = SWITCH_IDR; // write data
   }
	//////// write C Code /////////////////



////	//////////// Read C Code ///////////////
	LED_GPIO = 0x00;
	I2C_TXR = 0b10101001;
	// Address + read
	sleep(1);
	I2C_CTR = 0b00000110; // en + start
	usleep(1);
	I2C_CTR = 0b00000111;
//  switch에 따른 LED_GPIO


	while (1)
	   {
	      if(I2C_SR & 0x01)
	            LED_GPIO = I2C_RXR;
	       else

	   LED_GPIO = I2C_RXR;
	   usleep(10000);
   }

   return 0;
}


