# Project_SPI_I2C_UPCOUNTER_LED_Control
미니프로젝트 : SPI 및 I2C 프로토콜 기반 Upcounter, LED 제어로직 설계 및 검증


❗발표영상은 PPT 마지막 슬라이드에 있습니다.

## 🔹프로젝트 개요


- **RISC-V 아키텍처**를 기반으로 SoC 시스템 내에서 **SPI 및 I2C 표준 통신 프로토콜**을 직접 설계하고 통합하는 메커니즘을 이해하기 위해 프로젝트를 수행하였습니다.
- **SystemVerilog**를 활용하여 Custom IP를 설계하고, **UVM(Universal Verification Methodology)** 기반의 검증 환경을 구축하여 하드웨어 설계의 신뢰성을 확보하는 프로세스를 경험하였습니다

## 🔹 프로젝트 목표


**What?** 🎯

- **SPI/I2C Custom IP 설계**: Motorola SPI 및 Philips I2C 규격을 준수하는 통신 인터페이스를 SystemVerilog로 구현
- **Upcounter 및 주변기기 제어**: SPI 통신을 통해 13비트 Upcounter(최대 10,000) 데이터를 전송하고, I2C를 통해 슬레이브 보드의 LED 및 스위치를 실시간 제어
- **UVM 기반 검증 환경 구축**: 랜덤 시나리오 테스트와 Scoreboard 비교를 통해 설계된 IP의 통신 정합성 검증
- **시스템 통합 및 디버깅**: RISC-V 기반의 Top Module 통합과 Analyzer를 이용한 실시간 하드웨어 디버깅

## 🔹 설계 및 구현 환경

--

**설계 (Design)**

- **SPI Master/Slave**: Full Duplex 기반의 2바이트 데이터 Latching 및 전송 로직 설계
- **I2C Controller**: Open-Drain 방식을 고려한 Start/Stop Condition 및 FSM(Finite State Machine) 설계
- **Peripheral Control**: C 언어를 활용한 RISC-V 기반 주변장치 제어 펌웨어 개발

**검증(Verification)**

- UVM 환경(Synopsys VCS)에서 - Random Test Pattern 생성 및 ScoreBoard 검증

**구현 환경 (Tool Environment)**

- **Language**: SystemVerilog, C
- **Design Tool**: Vivado, Vitis, VCS (UVM Verification)
- **Equipment**: Basys3 FPGA Board

## 🔹Block Diagram

---

### 🔸I2C Block Diagram

![image.png](attachment:223c44e5-b2bf-47b8-9e59-8d31da9acabb:image.png)

### 🔸SPI Block Diagram

![image.png](attachment:a3d62d3b-dfce-4f12-a59c-285b31ab0af9:image.png)

### 🔸UVM Hierachy Structure

![image.png](attachment:105bf505-f87b-4805-a9f5-251dc38dcded:image.png)

## 🔹프로젝트 성과

---

- **SPI와 I2C 통신 Protocol을 이용해서 설계 및 검증**
- **I2C 기반으로 하여 Peripheral을 이용하여 원하는 LED 제어를 C언어 프로그래밍 바탕으로 동작**
- **SPI 기반으로 하여 Peripheral을 이용하여 UPCOUNTER 10,000을 C언어 프로그래밍 바탕으로 동작**

## 🔹Trouble Shooting 및 배운 점

---

### **1. Address Data Latching Failure 및 타이밍 최적화**

- **문제상황**: 마스터에서 올바른 주소를 전송했음에도 슬레이브에서 엉뚱한 주소를 인식하는 문제 발생
- **문제원인**: IDLE 상태에서 START로 전환될 때 주소 데이터가 충분히 유지되지 않아 Latching 타이밍이 어긋남을 분석함
- **해결방안**: 주소 데이터 유지 시간을 **$10\mu s$ 이상**으로 확장하도록 로직을 수정하여 안정적 Latching 보장
- **성과**: 주소 인식 오류를 제거하여 마스터-슬레이브 간 통신 신뢰성을 확보함

### **2. 수신 데이터(RX Data) Latching Failure로 인한 LED Blinking**

- **문제상황** : 슬레이브 스위치 데이터를 마스터가 수신할 때, 값이 미세하게 변하여 LED가 비정상적으로 깜빡이는 현상 발생
- **문제원인** : 수신단(SDA)에서 들어오는 데이터가 안정화되기 전 샘플링되어 발생하는 논리적 불안정임을 정의함
- **해결방안** : 입력단에 **2번의 Latching(Double Latching)** 구조를 도입하여 신호를 안정화시킨 후 데이터로 사용하도록 수정
- **성과**: 데이터 노이즈를 제거하여 실시간 스위치 상태 확인 기능의 정확도를 높임

### **3. Write the Read FSM Synchronization Failure**

- **문제상황 :** Write data를 하다가 Repeated Start(read)시에 Master-Slave State Timing 문제
- **문제원인** : SDA Signal Delay로 인한  Master와 Slave의 FSM Synchronization 불일치
- **문제 해결** : HOLD State에 Start로 SCL, SDA Start condition 로직 수정

### 4. 하드웨어 디버깅 및 FSM 동기화 최적화 (Debugging & Method)

- **독립된 시스템 간의 신호 가시성(Visibility) 확보**: 물리적으로 분리된 두 개의 Basys3 보드 간 통신 시, 내부 FSM 상태를 직접 확인하기 어렵다는 한계를 극복하기 위해 주요 상태 신호를 외부 **Test Port**로 인출하였습니다. 이를 통해 블랙박스 상태였던 보드 간 통신 과정을 가시화하였습니다.
- **로직 분석기(Logic Analyzer)를 활용한 실시간 파형 분석**: 프로토콜 오류가 의심되는 SCL, SDA 신호 라인에 분석기를 연결하여 내부 로직상의 데이터 전송 시점과 실제 버스 상의 물리적 파형을 실시간으로 비교 분석하였습니다. 이 과정에서 Master와 Slave 간의 미세한 타이밍 불일치(Timing Mismatch)를 포착하여 디버깅 효율을 극대화했습니다.
- **FSM 동기화 로직의 중요성 체득**: 서로 다른 클럭 도메인을 가진 보드 사이에서 안정적인 데이터 전송을 위해서는 FSM의 전이 조건이 물리적 신호의 안정화 시간과 유기적으로 맞물려야 함을 이해하게 되었습니다.
