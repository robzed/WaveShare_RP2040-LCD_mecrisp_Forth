\ --------------------------------------
\ LCD controller by Rob Probin 1 May 2022
\ (c) 2022-2023 Rob Probin
\ Released under the MIT licenses
\ --------------------------------------

\ We use Zeptoforth libraries rather than do the 
\ GPIO and bitbash the SPI port.

pin import
spi import
timer import

\ --------------------------------------
\ LCD I/O Pins
\ --------------------------------------

11 constant lcd_din 
10 constant lcd_clk
8  constant lcd_dc
12 constant lcd_rst
9  constant lcd_cs
25 constant lcd_bl

\ --------------------------------------
\ Helper words
\ --------------------------------------

: >> rshift ;
: << lshift ;

\ Write a set of bytes to the SPI port
: spi_write ( address n -- )
  0 do 
    dup C@ 1 >spi 1+ 
  loop drop
;

\ --------------------------------------
\ LCD Subsystem
\ --------------------------------------

160 constant lcd_width
80 constant lcd_height

: lcd.reset ( -- )
  high lcd_rst pin!
  200 ms
  low lcd_rst pin!
  200 ms
  high lcd_rst pin!
  200 ms
;

: lcd.write_cmd ( byte -- )
  low lcd_dc pin!
  low lcd_cs pin!
  1 >spi \ 1 spi> drop
  high lcd_cs pin!
; 

: lcd.write_data ( byte -- )
  high lcd_dc pin!
  low lcd_cs pin!
  1 >spi \ 1 spi> drop
  high lcd_cs pin!
; 

: lcd.backlight ( % -- )
  \ not implemented properly yet
  lcd_bl output-pin  \ could make this PWM

  IF 1 ELSE 0 THEN
  lcd_bl pin!
;

: lcd_CoreInit ( -- )
        lcd.reset
        100 lcd.backlight  
        
        $11 lcd.write_cmd
        120 ms
        $21 lcd.write_cmd 
        $21 lcd.write_cmd 

        $B1 lcd.write_cmd
        $05 lcd.write_data
        $3A lcd.write_data
        $3A lcd.write_data

        $B2 lcd.write_cmd
        $05 lcd.write_data
        $3A lcd.write_data
        $3A lcd.write_data

        $B3 lcd.write_cmd 
        $05 lcd.write_data
        $3A lcd.write_data
        $3A lcd.write_data
        $05 lcd.write_data
        $3A lcd.write_data
        $3A lcd.write_data

        $B4 lcd.write_cmd
        $03 lcd.write_data

        $C0 lcd.write_cmd
        $62 lcd.write_data
        $02 lcd.write_data
        $04 lcd.write_data

        $C1 lcd.write_cmd
        $C0 lcd.write_data

        $C2 lcd.write_cmd
        $0D lcd.write_data
        $00 lcd.write_data

        $C3 lcd.write_cmd
        $8D lcd.write_data
        $6A lcd.write_data   

        $C4 lcd.write_cmd
        $BD lcd.write_data 
        $EE lcd.write_data

        $C5 lcd.write_cmd
        $0E lcd.write_data

        $E0 lcd.write_cmd
        $10 lcd.write_data
        $0E lcd.write_data
        $02 lcd.write_data
        $03 lcd.write_data
        $0E lcd.write_data
        $07 lcd.write_data
        $02 lcd.write_data
        $07 lcd.write_data
        $0A lcd.write_data
        $12 lcd.write_data
        $27 lcd.write_data
        $37 lcd.write_data
        $00 lcd.write_data
        $0D lcd.write_data
        $0E lcd.write_data
        $10 lcd.write_data

        $E1 lcd.write_cmd
        $10 lcd.write_data
        $0E lcd.write_data
        $03 lcd.write_data
        $03 lcd.write_data
        $0F lcd.write_data
        $06 lcd.write_data
        $02 lcd.write_data
        $08 lcd.write_data
        $0A lcd.write_data
        $13 lcd.write_data
        $26 lcd.write_data
        $36 lcd.write_data
        $00 lcd.write_data
        $0D lcd.write_data
        $0E lcd.write_data
        $10 lcd.write_data

        $3A lcd.write_cmd 
        $05 lcd.write_data

        $36 lcd.write_cmd
        $A8 lcd.write_data

        $29 lcd.write_cmd 
;
        
: lcd.SetWindows ( Ystart Yend Xstart Xend ) \ example max: 0 79 0 159
        swap
        $2A lcd.write_cmd
        0 lcd.write_data              
        1+ lcd.write_data \ Xstart
        0 lcd.write_data              
        1+ lcd.write_data \ Xend

        swap
        $2B lcd.write_cmd
        0 lcd.write_data
        26 + lcd.write_data \ Ystart
        0 lcd.write_data
        26 + lcd.write_data \ Yend

        $2C lcd.write_cmd
; 

\ --------------------------------------
\ LCD Middleware
\ --------------------------------------

\ create space for images
2 constant pixsize
lcd_height lcd_width * pixsize * constant lcd_buf_size
lcd_buf_size buffer: lcd_buffer



: lcd.display ( -- )
  0 lcd_height 1- 0 lcd_width 1- lcd.SetWindows       
  1 lcd_dc pin! 
  0 lcd_cs pin!
 us-counter-lsb
  lcd_buffer lcd_buf_size spi_write
 us-counter-lsb swap - u. cr

  1 lcd_cs pin!
;

: lcd.init
    lcd_cs output-pin
    high lcd_cs pin!

    lcd_rst output-pin

    lcd_dc output-pin
    high lcd_dc pin!

    1 lcd_clk spi-pin \ SPI1 SCK
    1 lcd_din spi-pin \ SPI1 TX
    1 master-spi
    10000000 1 spi-baud!
    8 1 spi-data-size!
    \    1 ti-ss-spi

    \ true false 1 motorola-spi
    \ https://docs.arduino.cc/learn/communication/spi
    \ Mode      Clock Polarity (CPOL)   Clock Phase (CPHA)  Output Edge     Data Capture
    \ SPI_MODE0 0                       0                   Falling         Rising
    \ SPI_MODE1 0                       1                   Rising          Falling
    \ SPI_MODE2 1                       0                   Rising          Falling
    \ SPI_MODE3 1                       1                   Falling         Rising

   \ Zeptoforth: ( sph spo spi – )
   \ Set the protocol of an SPI peripheral to Motorola SPI, with SPO/CPOL set to spo and 
   \ SPH/CPHA set to sph. This must be done with the SPI peripheral disabled.
   false false 1 motorola-spi        
   \ The SPI settings for the LCD are: 10000000, MSBFIRST, SPI_MODE0

   1 enable-spi

    lcd_CoreInit
    0 lcd_height 1- 0 lcd_width 1- lcd.SetWindows       
;

\ built-in assumption about pixsize
: lcd.fill ( colour -- )
  lcd_buffer 
  lcd_buf_size 2/ 0 do 
    2dup h! 2 +
  loop 2drop
;

\ --------------------------------------
\ LCD Drawing functions
\ --------------------------------------

\ color is BGR
$00F8 constant RED
$E007 constant GREEN
$1F00 constant BLUE
$FFFF constant WHITE
$0000 constant BLACK

: test_fill
 lcd.init
 BLUE lcd.fill lcd.display
 1000 ms
 RED lcd.fill lcd.display
 1000 ms
 GREEN lcd.fill lcd.display
 1000 ms
 BLACK lcd.fill lcd.display
;

: rgb16 ( r_byte g_byte b_byte -- colour )
  \ we don't need these because first thing we do if a shift and bitwise AND
  \ dup 255 > if drop 255 then rot
  \ dup 255 > if drop 255 then rot
  \ dup 255 > if drop 255 then rot 
  
  \ do blue component
  3 >> $1F AND   ( b -- 5-bit-blue )
  8 << \ blue into position

  \ do green component
  swap
  2 >> $3F AND  \ ( g -- 6-bit-green )
  dup 3 >> $7 AND \ green high bits, into position
  swap $07 AND \ green low bits
  13 <<        \ green low bits into position
  +   \ merge green into single integer
  +   \ merge blue and green into single integer

  \ do red component
  swap
  3 >> $1F AND    ( g -- 5-bit-red )
  3 <<            \ red into position

  +  \ merge red into position
;

variable fgcolour

\ NOTE: No out of bounds checking - clipping should be done before this!
: fb_addr ( x y -- addr )
  lcd_width * + pixsize * lcd_buffer +
;

: xyclip ( x y -- clip-x clip-y )
  dup 0 < IF drop 0 THEN
  dup lcd_height > IF drop lcd_height 1- THEN
  swap

  dup 0 < IF drop 0 THEN
  dup lcd_width > IF drop lcd_width 1- THEN
  swap
; 

: width-clip ( x w -- x w-clip )
 2dup + lcd_width > IF 
    drop lcd_width over -
  THEN
;

: height-clip ( y h -- y h-clip )
  2dup + lcd_height > IF 
    drop lcd_height over - 
  THEN
;

: lcd.hline  ( x y w c -- )
  fgcolour !

  \ check to see if width draw is outside FB
  -rot xyclip rot

  \ check to see if width draw is outside FB
  rot swap width-clip ( x y w -- y x w-clip )

  -rot swap fb_addr
  
  \ finally do the draw!
  swap 0 do fgcolour @ over h! pixsize + loop drop
;

: lcd.vline ( x y h c -- )
  fgcolour !

  \ clip x and y
  -rot xyclip rot

  \ check to see if height draw is outside FB
  height-clip ( x y h -- x y h-clip )

  -rot fb_addr

  \ finally do the draw!
  swap 0 do fgcolour @ over h! lcd_width pixsize *  + loop drop
;

: line_test
  black lcd.fill
  10 10 140 BLUE lcd.hline
  10 70 140 BLUE lcd.hline
  10 10 60 BLUE  lcd.vline
  150 10 60 BLUE lcd.vline
    
  0 0 160 BLUE   lcd.hline
  0 79 160 BLUE  lcd.hline
  0 0 80 BLUE    lcd.vline
  159 0 80 BLUE  lcd.vline

  10 10 20 white lcd.hline
  10 20 30 red lcd.vline 
  100 20 40 green lcd.hline

  lcd.display
;

variable _texth
variable _textw

: init_texthw
  8 _texth ! 
  8 _textw ! 
;
init_texthw \ @TODO: call from init if a flash build

\ left adjust pixels
: |<<pixels ( bitmap numpix -- adjusted-bitmap numpix )
  \ make the pixels left aligned
  swap over 32 swap - << swap 
;

\ no range checking
: _drawpixline ( addr bitmap numpix -- )
  32 min
  |<<pixels

  \ loop over pixels and draw them in the frame buffer
  0 do 
    ( addr bitmap )

    2dup $80000000 and if 
      fgcolour @ swap h! 
    else 
      drop 
    then 
    1 << 
    swap pixsize + swap
  loop 2drop
;

: _drawcharw ( addr bitmap -- )
  _textw @ _drawpixline
;

: drawbytelines ( char-addr x y height -- )
  
  \ clip x and y
  -rot xyclip rot

  \ check to see if height draw is outside FB
  height-clip ( x y h -- x y h-clip )

  \ convert x and y to address
  -rot fb_addr

  swap 0 do ( char-addr fbaddr height=count -- char-addr fbaddr )
    2dup 
    swap C@ _drawcharw 
    swap 1+ swap  \ next pixel row
    lcd_width pixsize *  +   \ next framebuffer line
  loop 2drop
;


\ spectrum character set
create speccy_char_set
hex
 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 10 c, 10 c, 10 c, 10 c, 00 c, 10 c, 00 c, 
 00 c, 24 c, 24 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 24 c, 7e c, 24 c, 24 c, 7e c, 24 c, 00 c, 
 00 c, 08 c, 3e c, 28 c, 3e c, 0a c, 3e c, 08 c, 00 c, 62 c, 64 c, 08 c, 10 c, 26 c, 46 c, 00 c, 
 00 c, 10 c, 28 c, 10 c, 2a c, 44 c, 3a c, 00 c, 00 c, 08 c, 10 c, 00 c, 00 c, 00 c, 00 c, 00 c, 
 00 c, 04 c, 08 c, 08 c, 08 c, 08 c, 04 c, 00 c, 00 c, 20 c, 10 c, 10 c, 10 c, 10 c, 20 c, 00 c, 
 00 c, 00 c, 14 c, 08 c, 3e c, 08 c, 14 c, 00 c, 00 c, 00 c, 08 c, 08 c, 3e c, 08 c, 08 c, 00 c, 
 00 c, 00 c, 00 c, 00 c, 00 c, 08 c, 08 c, 10 c, 00 c, 00 c, 00 c, 00 c, 3e c, 00 c, 00 c, 00 c, 
 00 c, 00 c, 00 c, 00 c, 00 c, 18 c, 18 c, 00 c, 00 c, 00 c, 02 c, 04 c, 08 c, 10 c, 20 c, 00 c, 
 00 c, 3c c, 46 c, 4a c, 52 c, 62 c, 3c c, 00 c, 00 c, 18 c, 28 c, 08 c, 08 c, 08 c, 3e c, 00 c, 
 00 c, 3c c, 42 c, 02 c, 3c c, 40 c, 7e c, 00 c, 00 c, 3c c, 42 c, 0c c, 02 c, 42 c, 3c c, 00 c, 
 00 c, 08 c, 18 c, 28 c, 48 c, 7e c, 08 c, 00 c, 00 c, 7e c, 40 c, 7c c, 02 c, 42 c, 3c c, 00 c, 
 00 c, 3c c, 40 c, 7c c, 42 c, 42 c, 3c c, 00 c, 00 c, 7e c, 02 c, 04 c, 08 c, 10 c, 10 c, 00 c, 
 00 c, 3c c, 42 c, 3c c, 42 c, 42 c, 3c c, 00 c, 00 c, 3c c, 42 c, 42 c, 3e c, 02 c, 3c c, 00 c, 
 00 c, 00 c, 00 c, 10 c, 00 c, 00 c, 10 c, 00 c, 00 c, 00 c, 10 c, 00 c, 00 c, 10 c, 10 c, 20 c, 
 00 c, 00 c, 04 c, 08 c, 10 c, 08 c, 04 c, 00 c, 00 c, 00 c, 00 c, 3e c, 00 c, 3e c, 00 c, 00 c, 
 00 c, 00 c, 10 c, 08 c, 04 c, 08 c, 10 c, 00 c, 00 c, 3c c, 42 c, 04 c, 08 c, 00 c, 08 c, 00 c, 
 00 c, 3c c, 4a c, 56 c, 5e c, 40 c, 3c c, 00 c, 00 c, 3c c, 42 c, 42 c, 7e c, 42 c, 42 c, 00 c, 
 00 c, 7c c, 42 c, 7c c, 42 c, 42 c, 7c c, 00 c, 00 c, 3c c, 42 c, 40 c, 40 c, 42 c, 3c c, 00 c, 
 00 c, 78 c, 44 c, 42 c, 42 c, 44 c, 78 c, 00 c, 00 c, 7e c, 40 c, 7c c, 40 c, 40 c, 7e c, 00 c, 
 00 c, 7e c, 40 c, 7c c, 40 c, 40 c, 40 c, 00 c, 00 c, 3c c, 42 c, 40 c, 4e c, 42 c, 3c c, 00 c, 
 00 c, 42 c, 42 c, 7e c, 42 c, 42 c, 42 c, 00 c, 00 c, 3e c, 08 c, 08 c, 08 c, 08 c, 3e c, 00 c, 
 00 c, 02 c, 02 c, 02 c, 42 c, 42 c, 3c c, 00 c, 00 c, 44 c, 48 c, 70 c, 48 c, 44 c, 42 c, 00 c, 
 00 c, 40 c, 40 c, 40 c, 40 c, 40 c, 7e c, 00 c, 00 c, 42 c, 66 c, 5a c, 42 c, 42 c, 42 c, 00 c, 
 00 c, 42 c, 62 c, 52 c, 4a c, 46 c, 42 c, 00 c, 00 c, 3c c, 42 c, 42 c, 42 c, 42 c, 3c c, 00 c, 
 00 c, 7c c, 42 c, 42 c, 7c c, 40 c, 40 c, 00 c, 00 c, 3c c, 42 c, 42 c, 52 c, 4a c, 3c c, 00 c, 
 00 c, 7c c, 42 c, 42 c, 7c c, 44 c, 42 c, 00 c, 00 c, 3c c, 40 c, 3c c, 02 c, 42 c, 3c c, 00 c, 
 00 c, fe c, 10 c, 10 c, 10 c, 10 c, 10 c, 00 c, 00 c, 42 c, 42 c, 42 c, 42 c, 42 c, 3c c, 00 c, 
 00 c, 42 c, 42 c, 42 c, 42 c, 24 c, 18 c, 00 c, 00 c, 42 c, 42 c, 42 c, 42 c, 5a c, 24 c, 00 c, 
 00 c, 42 c, 24 c, 18 c, 18 c, 24 c, 42 c, 00 c, 00 c, 82 c, 44 c, 28 c, 10 c, 10 c, 10 c, 00 c, 
 00 c, 7e c, 04 c, 08 c, 10 c, 20 c, 7e c, 00 c, 00 c, 0e c, 08 c, 08 c, 08 c, 08 c, 0e c, 00 c, 
 00 c, 00 c, 40 c, 20 c, 10 c, 08 c, 04 c, 00 c, 00 c, 70 c, 10 c, 10 c, 10 c, 10 c, 70 c, 00 c, 
 00 c, 10 c, 38 c, 54 c, 10 c, 10 c, 10 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, 00 c, ff c, 
 00 c, 1c c, 22 c, 78 c, 20 c, 20 c, 7e c, 00 c, 00 c, 00 c, 38 c, 04 c, 3c c, 44 c, 3c c, 00 c, 
 00 c, 20 c, 20 c, 3c c, 22 c, 22 c, 3c c, 00 c, 00 c, 00 c, 1c c, 20 c, 20 c, 20 c, 1c c, 00 c, 
 00 c, 04 c, 04 c, 3c c, 44 c, 44 c, 3c c, 00 c, 00 c, 00 c, 38 c, 44 c, 78 c, 40 c, 3c c, 00 c, 
 00 c, 0c c, 10 c, 18 c, 10 c, 10 c, 10 c, 00 c, 00 c, 00 c, 3c c, 44 c, 44 c, 3c c, 04 c, 38 c, 
 00 c, 40 c, 40 c, 78 c, 44 c, 44 c, 44 c, 00 c, 00 c, 10 c, 00 c, 30 c, 10 c, 10 c, 38 c, 00 c, 
 00 c, 04 c, 00 c, 04 c, 04 c, 04 c, 24 c, 18 c, 00 c, 20 c, 28 c, 30 c, 30 c, 28 c, 24 c, 00 c, 
 00 c, 10 c, 10 c, 10 c, 10 c, 10 c, 0c c, 00 c, 00 c, 00 c, 68 c, 54 c, 54 c, 54 c, 54 c, 00 c, 
 00 c, 00 c, 78 c, 44 c, 44 c, 44 c, 44 c, 00 c, 00 c, 00 c, 38 c, 44 c, 44 c, 44 c, 38 c, 00 c, 
 00 c, 00 c, 78 c, 44 c, 44 c, 78 c, 40 c, 40 c, 00 c, 00 c, 3c c, 44 c, 44 c, 3c c, 04 c, 06 c, 
 00 c, 00 c, 1c c, 20 c, 20 c, 20 c, 20 c, 00 c, 00 c, 00 c, 38 c, 40 c, 38 c, 04 c, 78 c, 00 c, 
 00 c, 10 c, 38 c, 10 c, 10 c, 10 c, 0c c, 00 c, 00 c, 00 c, 44 c, 44 c, 44 c, 44 c, 38 c, 00 c, 
 00 c, 00 c, 44 c, 44 c, 28 c, 28 c, 10 c, 00 c, 00 c, 00 c, 44 c, 54 c, 54 c, 54 c, 28 c, 00 c, 
 00 c, 00 c, 44 c, 28 c, 10 c, 28 c, 44 c, 00 c, 00 c, 00 c, 44 c, 44 c, 44 c, 3c c, 04 c, 38 c, 
 00 c, 00 c, 7c c, 08 c, 10 c, 20 c, 7c c, 00 c, 00 c, 0e c, 08 c, 30 c, 08 c, 08 c, 0e c, 00 c, 
 00 c, 08 c, 08 c, 08 c, 08 c, 08 c, 08 c, 00 c, 00 c, 70 c, 10 c, 0c c, 10 c, 10 c, 70 c, 00 c, 
 00 c, 14 c, 28 c, 00 c, 00 c, 00 c, 00 c, 00 c, 3c c, 42 c, 99 c, a1 c, a1 c, 99 c, 42 c, 3c c, 
decimal 

\ speccy_char_set 48 + 18 10 8 drawbytelines

variable _textsetaddr
variable bgcolour

: init_text_ctrl 
  speccy_char_set _textsetaddr ! 
  BLACK bgcolour !
;
init_text_ctrl \ @TODO: call from init if a flash build

\ : lcd.fill_rect ( x y w h c -- )
\  fgcolour !  
\ ;


\ All characters have dimensions of 8x8 pixels and there is currently no way to change the font.
: lcd.printch ( x y char -- )
  \ characters below 32 are all spaces
  -32 + 0 max
  \ convert character into bitmap address
  _texth @ * _textsetaddr @ +
  -rot ( char-addr x y )
  _texth @ drawbytelines
;

: lcd.text ( text-addr len x y colour )
  fgcolour !

  2swap
  0 DO ( x y text_addr)
    \ horrible stack hack
    0 2over 2over
    \ ( x y text_addr 0 x y text_addr 0 )
    drop C@ lcd.printch drop
    \ go to next address
    1+
    \ move x by 8 pixels along
    rot _textw @ + -rot
  LOOP
  2drop drop
;

: test_text
  BLACK lcd.fill   
  S" Hello Pico!" 35 15 GREEN lcd.text
  S" This is:" 50 35 RED BLUE + lcd.text
  S" Pico-LCD-0.96" 30 55 GREEN BLUE + lcd.text
  lcd.display
;

: center ( addr n y -- addr n x y )
    over
    8 * lcd_width swap - 2/
    dup 0< IF drop 0 THEN
    swap
;

: center_test
  BLACK lcd.fill   
  S" Hello !!!" 0 center RED GREEN + lcd.text
  S" Rob says 'hi'" 10 center GREEN lcd.text
  S"     ... to everyone" 20 center GREEN lcd.text
  S" RP2040 Zeptoforth" 30 center RED BLUE + lcd.text
  S" on Pico-LCD-0.96" 40 center GREEN BLUE + lcd.text
  lcd.display
;



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

