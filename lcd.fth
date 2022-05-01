\ --------------------------------------
\ LCD controller by Rob Probin 1 May 2022
\ (c) 2022 Rob Probin
\ Released under the MIT licenses
\ --------------------------------------
compiletoflash

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
\ I/O inspired by Peter Jakacki work
\ --------------------------------------
\ We could have used blinky example here, but
\ it's not really complex enough... high, low, 
\ etc. is nice. So this was the fastest option
\ to get something working.


( SIO REGISTERS )

: SIO $D0000000 + ;

$004 constant IOIN
$010 constant IOOUT
$014 constant IOSET  \ GPIO output value set
$018 constant IOCLR  \ GPIO output value clear
$01C constant IOXOR
$020 constant IOOE
$024 constant OESET   \ GPIO output enable set
$028 constant OECLR
$02C constant OEXOR

: >> rshift ;
: << lshift ;
: bit ( bit -- mask ) 1 SWAP << ;

 ( GPIO )
\ GPIO STATUS
: GPSR ( pin -- ) 3 << $40014000 + ;
\ GPIO CONTROL
: GPCR ( pin -- ) 3 << $40014004 + ;

: SIO! ( val reg -- ) SIO ! ;
: SIO@  SIO @ ;
: FLOAT ( pin -- )     bit OECLR SIO! ;
: >OUTPUT ( pin -- ) bit OESET SIO! ;
: >INPUT ( pin -- ) bit OECLR SIO! ;
: PIN@  ( pin -- bit ) IOIN SIO@ SWAP >> 1 AND ;
: PIN? ( pin -- pin bit ) IOIN SIO@ OVER >> 1 AND ;
: HIGH ( pin -- )   bit DUP IOSET SIO! OESET SIO! ;
: LOW ( pin -- )    bit DUP IOCLR SIO! OESET SIO! ;
: PIN! ( b0 pin -- ) SWAP 1 AND IF HIGH ELSE LOW THEN ;

\ --------------------------------------
\ SPI Driver - inspired by Peter Jakacki's bit bashing code
\ --------------------------------------
lcd_clk bit constant CLKMASK
: SPICLK CLKMASK IOSET SIO! CLKMASK IOCLR SIO! ;

( aabbccdd -- bbccddaa ) \ write ms byte to SPI bus and rotate result
: SPIWR 8 0 do ROL DUP lcd_din PIN! SPICLK LOOP ;

( byte -- ) \ write byte to SPI bus
: SPIWB 24 << SPIWR DROP ;

\ Write a set of bytes to the SPI port
: spi_write ( address n -- )
  0 do 
    dup C@ SPIWB 1+ 
  loop drop
;



\ LCD Subsystem
160 constant lcd_width
80 constant lcd_height

: lcd.reset ( -- )
  1 lcd_rst pin!
  200 ms
  0 lcd_rst pin!
  200 ms
  1 lcd_rst pin!
  200 ms
;

: lcd.write_cmd ( byte -- )
  0 lcd_dc pin!
  0 lcd_cs pin!
  SPIWB
  1 lcd_cs pin!
; 

: lcd.write_data ( byte -- )
  1 lcd_dc pin!
  0 lcd_cs pin!
  SPIWB
  1 lcd_cs pin!
; 

: lcd.backlight ( % -- )
  \ not implemented properly yet
  lcd_bl >output  \ could make this PWM

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


\ create space for images
2 constant pixsize
lcd_height lcd_width * pixsize * constant lcd_buf_size
lcd_buf_size buffer: lcd_buffer



: lcd.display ( -- )
  0 lcd_height 1- 0 lcd_width 1- lcd.SetWindows       
  1 lcd_dc pin! 
  0 lcd_cs pin!
  lcd_buffer lcd_buf_size spi_write
  1 lcd_cs pin!
;

: lcd.init
    lcd_cs >output
    1 lcd_cs pin!

    lcd_rst >output

    lcd_dc >output
    1 lcd_dc pin!


    lcd_din >output
    lcd_clk >output


    lcd_CoreInit
    0 lcd_height 1- 0 lcd_width 1- lcd.SetWindows       
;

\ built-in assumption about pixsize
: lcd.fill ( colour -- )
  lcd_buffer 
  lcd_buf_size 2/ 0 do 
    2dup h! 2+
  loop 2drop
;

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


\ to do: 
\ 1b. Do a save to slot
\ 2. time lcd.display
\ 3. 

\ Make this happen
\    lcd.fill(BLACK)   
\    lcd.text("Hello pico!",35,15,GREEN)
\    lcd.text("This is:",50,35,GREEN)    
\    lcd.text("Pico-LCD-0.96",30,55,GREEN)
\    lcd.display()

\ Make this happen    
\    lcd.hline(10,10,140,BLUE)
\    lcd.hline(10,70,140,BLUE)
\    lcd.vline(10,10,60,BLUE)
\    lcd.vline(150,10,60,BLUE)
    
\    lcd.hline(0,0,160,BLUE)
\    lcd.hline(0,79,160,BLUE)
\    lcd.vline(0,0,80,BLUE)
\    lcd.vline(159,0,80,BLUE) 

\ Make this happen
\           lcd.fill_rect(m,n,10,10,WHITE)
\ 

