# Verilog Based UART Communication Core 
Design of a modular UART core in Verilog with transmitter and receiver blocks each with synchronous FIFO buffering. Integrated
- 16x oversampling
- Parity checking (Even or Odd)
- Multi stop bit (1 or 2)
- NS16550A style error/status flag
  
## The Flow
The design was realized by building the components part by part using ASMD charts. The control logic and datapath logic are kept clean and seperated.


### **Baud Tick Generator**
---
The main functionality expected is the 16x oversampling.
The baud rate is parameterized to keep future scaling in mind.It works at 9600 Baud on a 50 MHz clock. Divisior value would be 
$$
 Divisor = \frac{Clock}{16 \times Baud\space Rate}
$$
A 16 bit counter counts to the divisor value and sets it high on overflow. This generates the 16x overesampled baud tick.

### **UART Receiver**
---
The basic architecture of the uart reciver module.

![alt text](Images\ReceiverArc.png)


Just as in **NS16550A** there will be a Line status register.
The bits of LSR that will be used for the current model is

- LSR[0] : Data Available flag
- LSR[1] : Overflow Error (For the FIFO)
- LSR[2] : Inccorrect Parity 
- LSR[3] : No Framing error (No valid stop bit)
  
Since Uart is an ashynchronous protocol to prevent metastability the rx line will be synchronized by passing through two DFF.

The ASMD chart for the UART receiver module.

![alt text](Images\ReceiverASMD.png)

All the bits are centre sampled. To prevent start bit glitching an additional three samples are taken before the mid point.

### **UART Transmitter**
---
In the transmit module the tx line should be held high while in idle state and changes once data starts transmitting. A transmit done pulse was also needed.
In UART to transmit data we would need
- One Start Bit
- Data Bits (8)
- Parity Bit 
- Stop Bits (2) 
  
The same baud tick generator as the receiver was used for the sake of resusability whereas in truth 16x oversampling is not necessary for transmitting.

The ASMD chart for UART transmitter module

![alt text](Images\TransmitterASMD.png)

### **Synchronous FIFO**
---

A 16 bit FIFO for the receiver and a 8 bit FIFO for the transmitter was made.In the receiver both the data and LSR is stored.The fifo full signal is passed as input into the receiver module while the fifo empty is passed as a signal into the transmitter module.

### **UART Core**
---
The file named `uart.v` contains all the fifos, receiver and transmitter all connected into one single module behaving as the uart core.



## Code
All the code is provided in the folder.The testbenches used are also included. Icarus Verilog and gtkwave were used for verifying the modules.

**Work in progress** : `comm_layer.v` and `ram.v` are still under development to create a communication layer on top of the uart for basic memory logging