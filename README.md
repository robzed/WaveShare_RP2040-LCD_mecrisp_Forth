# WaveShare_RP2040-LCD_mecrisp_Forth

Can be modified for other displays, but was based on this device:
  https://www.waveshare.com/wiki/RP2040-LCD-0.96

## lcd v1 for mecrisp - Getting Started

1. Program as per mecrisp-stellaris README for the Pico. (BOOTSEL while plugging USB, copy with tools ut2).

2. Upload the code in `lcd_v1_mecrisp.fth` via a serial terminal to UART1 (GP0 GP1).


### Examples

* `test_fill`
* `line_test`   (requires `lcd.init` if you haven't used test_fill)
* `test_text`   (required `lcd.init` if you haven't used test_fill)
* `center_test` (required `lcd.init` if you haven't used test_fill)

### Notes for v1 mecrisp

 * Time to update display is currently about 83ms - and is limited by Software SPI. Would h/w SPI be faster?


## lcd v2 for Zeptoforth - Getting Started

This was tested with zeptoforth_full_usb-1.0.2.uf2 using communications over the USB port to the RP2040-LCD-0.96 board.


1. Program as per Zeptoforth instructions - drag the UF2 file over to the USB mounted RP2040 to program (after pressing reset while holding boot).

2. Upload the code in `lcd_v2_zepto.fth` via a serial terminal to USB.

### Examples

* `test_fill`
* `line_test`   (requires `lcd.init` if you haven't used test_fill)
* `test_text`   (required `lcd.init` if you haven't used test_fill)
* `center_test` (required `lcd.init` if you haven't used test_fill)


### Notes for v2 Zeptoforth

 * Time to update display is currently about ??m. This is a h/w SPI implementation. 


