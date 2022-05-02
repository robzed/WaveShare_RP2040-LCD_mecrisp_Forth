# WaveShare_RP2040-LCD_mecrisp_Forth

Can be modified for other displays, but was based on this device:
  https://www.waveshare.com/wiki/RP2040-LCD-0.96

## Getting Started

1. Program as per mecrisp-stellaris README for the Pico. (BOOTSEL while plugging USB, copy with tools ut2).

2. Upload the code in lcd.fth via a serial terminal to UART1 (GP0 GP1).

3. Type `save` or `1 save#`

4. Type `test_fill` or `line_test`





## Notes

 * Time to update display is currently about 83ms - and is limited by Software SPI. Would h/w SPI be faster?


