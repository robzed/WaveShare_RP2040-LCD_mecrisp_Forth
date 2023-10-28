

create animated_jsw
hex
3c00 h, 3c00 h, 7e00 h, 3400 h, 3e00 h, 3c00 h, 1800 h, 3c00 h, 7e00 h, 7e00 h, f700 h, fb00 h, 3c00 h, 7600 h, 6e00 h, 7700 h, 
0f00 h, 0f00 h, 1f80 h, 0d00 h, 0f80 h, 0f00 h, 0600 h, 0f00 h, 1b80 h, 1b80 h, 1b80 h, 1d80 h, 0f00 h, 0600 h, 0600 h, 0700 h, 
03c0 h, 03c0 h, 07e0 h, 0340 h, 03e0 h, 03c0 h, 0180 h, 03c0 h, 07e0 h, 07e0 h, 0f70 h, 0fb0 h, 03c0 h, 0760 h, 06e0 h, 0770 h, 
00f0 h, 00f0 h, 01f8 h, 00d0 h, 00f8 h, 00f0 h, 0060 h, 00f0 h, 01f8 h, 03fc h, 07fe h, 06f6 h, 00f8 h, 01da h, 030e h, 038c h, 
0f00 h, 0f00 h, 1f80 h, 0b00 h, 1f00 h, 0f00 h, 0600 h, 0f00 h, 1f80 h, 3fc0 h, 7fe0 h, 6f60 h, 1f00 h, 5b80 h, 70c0 h, 31c0 h, 
03c0 h, 03c0 h, 07e0 h, 02c0 h, 07c0 h, 03c0 h, 0180 h, 03c0 h, 07e0 h, 07e0 h, 0ef0 h, 0df0 h, 03c0 h, 06e0 h, 0760 h, 0ee0 h, 
00f0 h, 00f0 h, 01f8 h, 00b0 h, 01f0 h, 00f0 h, 0060 h, 00f0 h, 01d8 h, 01d8 h, 01d8 h, 01b8 h, 00f0 h, 0060 h, 0060 h, 00e0 h, 
003c h, 003c h, 007e h, 002c h, 007c h, 003c h, 0018 h, 003c h, 007e h, 007e h, 00ef h, 00df h, 003c h, 006e h, 0076 h, 00ee h, 
decimal

RED GREEN + constant YELLOW
RED BLUE + constant MAGENTA
GREEN BLUE + constant CYAN

: draw16lines ( char-addr x y height -- )
  
  \ clip x and y
  -rot xyclip rot

  \ check to see if height draw is outside FB
  height-clip ( x y h -- x y h-clip )

  \ convert x and y to address
  -rot fb_addr swap

  0 do ( char-addr fbaddr height=count -- char-addr fbaddr )
    2dup 
    swap h@ dup hex. cr _drawcharw 
    swap 2+ swap  \ next pixel row
    lcd_width pixsize *  +   \ next framebuffer line
  loop 2drop
;


: draw16 ( imageaddr x y  -- ) 
  _textw 16 !
  _texth 16 !

  16 draw16lines

  _textw 8 !
  _texth 8 !
;

\ lcd.init 0 lcd.fill animated_jsw 0 + 20 20 draw16 lcd.display

: dim ( n -- m )
  $1084 not and
;

create jsw_colours
cyan dim h, yellow dim h, green dim h, blue h, cyan h, magenta h, green h, 128 128 128 rgb16 h,

: multidraw16 ( offset -- )
  BLACK lcd.fill
  8 0 DO
    I 2* jsw_colours + h@ fgcolour !
    dup I + 7 and 32 * animated_jsw + 
    I 16 * 0 draw16
  LOOP

  lcd.display
;

: draw16_test
  begin
    8 0 do 
      I multidraw16
      200 ms
    loop
  key? until
;

: forth2020
  BLACK lcd.fill   
  S" Hello !!!" 0 center RED GREEN + lcd.text
  S" Rob says 'hi'" 10 center GREEN lcd.text
  S"     ... to everyone" 20 center GREEN lcd.text
  S" RP2040 Zeptoforth" 30 center RED BLUE + lcd.text
  S" on Pico-LCD-0.96" 40 center GREEN BLUE + lcd.text
  S" Forth2020" 60 center RED lcd.text
  lcd.display
;


\ to do: 
\ =======
\ Make this work: lcd.fill_rect(m,n,10,10,WHITE)
\ Add game graphics
\ Add time of day 8:00am printing
\ Add full colour picture 
\ add masks to back of fonts?
\ How much free flash/RAM?
\ Partial display update? Only lines that have been changed?
\ Add some images to the Repo
\ Consider time display?
\ Power down after displaying for x seconds? 
\ measure current used during sleep (do I need to power down the LCD display?)
\ Consider speed up SPI
\ PWM for backlight
\ : lcd.setfont ( w h charset -- ) ;
\ : lcd.pixel ( x y c -- )  ;

