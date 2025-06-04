unit z_comio;

interface

uses crt,dos;

(*
3F8/2F8 (Uart_Data) Write: transmit buffer.  Read: receive buffer, or
baud rate divisor LSB if port 3FB, bit 7 = 1.

3F9/2F9 (Uart_Ier) Write: interrupt enable register or baud rate divisor
MSB if port 3FB, bit 7 = 1.
PCjr baud rate divisor is different from other models;
clock input is 1.7895 megahertz rather than 1.8432 megahertz.

interrupt enable register:
    bits 7-4  forced to 0
    bit 3     1=enable change-in-modem-status interrupt
    bit 2     1=enable line-status interrupt
    bit 1     1=enable transmit-register-empty interrupt
    bit 0     1=data-available interrupt

3FA/2FA (Uart_Iir) interrupt identification register (prioritized)
     bits 7-3     forced to 0
     bits 2-1  00=change-in-modem-status (lowest)
     bits 2-1  01=transmit-register-empty (low)
     bits 2-1  10=data-available (high)
     bits 2-1  11=line status (highest)
     bit 0     1=no interrupt pending
     bit 0     0=interrupt pending

3FA/2FA (uart_fcr) fifo control register (write only)

     bits 7-6  11=trigger rv fifo when 14 bytes filled
     bits 7-6  10=trigger rv fifo when 8 bytes filled
     bits 7-6  01=trigger rv fifo when 4 bytes filled
     bits 7-6  00=trigger rv fifo when 1 byte filled
     bit 5     reserved
     bit 4     reserved
     bit 3     1=word length; changes the rxrdy and txrdy pins
                from mode 0 to mode 1 if bit 0 is set
     bit 2     1=clears all bytes in tx fifo
     bit 1     1=clears all bytes in rv fifo
     bit 0     1=enable tx and rv fifos

3FB/2FB (Uart_Lcr) Line control register
     bit 7    0=normal, 1=address baud rate divisor registers
     bit 6    0=break disabled, 1=enabled
     bit 5    0=don't force parity
              1=if bit 4-3=01 parity always 1
                if bit 4-3=11 parity always 0
                if bit 3=0 no parity
     bit 4    0=odd parity,1=even
     bit 3    0=no parity,1=parity
     bit 2    0=1 stop bit
              1=1.5 stop bits if 5 bits/character or
                  2 stop bits if 6-8 bits/character
   bits 1-0  00=5 bits/character
             01=6 bits/character
             10=7 bits/character
             11=8 bits/character

   bits 5-3 000=No parity
            001=odd parity
            010=No parity
            011=Even parity
            100=No parity
            101=Parity always 1
            110=No parity
            111=Parity always 0

3FC/2FC (Uart_Mcr) Modem control register
     bits 7-5  forced to zero
     bit 4     0=normal, 1=loop back test
     bits 3-2  all PCs except PCjr
     bit 3     1=interrupts to system bus, user-designated output: OUT2
     bit 2     user-designated output, OUT1
     bit 1     1=activate rts
     bit 0     1=activate dtr

3FD/2FD (Uart_Lsr) Line status register
     bit 7  forced to 0
     bit 6  1=transmit shift register is empty
     bit 5  1=transmit hold register is empty
     bit 4  1=break received
     bit 3  1=framing Error received
     bit 2  1=parity Error received
     bit 1  1=overrun Error received
     bit 0  1=data received

3FE/2FE (Uart_Msr) Modem status register
     bit 7  1=receive line signal detect
     bit 6  1=ring indicator (all PCs except PCjr)
     bit 5  1=dsr
     bit 4  1=cts
     bit 3  1=receive line signal detect has changed state
     bit 2  1=ring indicator has changed state (all PCs except PCjr)
     bit 1  1=dsr has changed state
     bit 0  1=cts has changed state

3FF/2FF (Uart_Spr) Scratch pad register.
*)

const
  XON  = 17;
  XOFF = 19;
  Max_Port = 4;
  Com_installed: Boolean = False;

type rx_queue_Type = array[1..6144] of byte;
     tx_queue_Type = array[1..1024] of byte;

var
  Uart_Base: word;
  intNums: byte;
  I8259Levels: byte;

  Uart_Data,       { Data register                     }
  Uart_Ier,        { interrupt enable register         }
  Uart_Iir,        { interrupt identification register }
  uart_fcr,        { fifo control register             }
  Uart_Lcr,        { Line control register             }
  Uart_Mcr,        { Modem control register            }
  Uart_Lsr,        { Line status register              }
  Uart_Msr,        { Modem status register             }
  Uart_Spr : word; { Scratch pad register              }

  Old_Ier,
  Old_Mcr,
  I8259Bit,
  intNum,           { interrupt vector number }
  Old_I8259_Mask: byte;

  Old_Vector: Pointer;

  Rx_Queue: ^rx_queue_type;
  Rx_in,
  Rx_Out,
  Rx_Chars: word;

  Tx_Queue: ^tx_queue_type;
  Tx_in,
  Tx_Out,
  Tx_Chars: word;

  Exit_Save: Pointer;

  rx_queue_size,
  tx_queue_size,
  rx_lowpoint,
  rx_almostfull,
  rx_almostfull2: word;

  _do_XONXOFF,
  _do_RTSCTS,
  _do_fifo,
  _allowsend: boolean;
  _send_ch,
  _sent_ch: byte;

procedure _sendbreak;
procedure _flush_rx;
procedure _flush_tx;
function  _cd: Boolean;
function  _get: byte;
function  _rx_ready: boolean;
procedure _put(ch: byte);
procedure _putstring(st: String);
procedure _dtr(state: boolean);
procedure _set_param(Speed: word; parity: char; Data_Bits,Stop_Bits: byte);
procedure _install(PortNum: word);
procedure _deinstall;
procedure _rts(state: boolean);

implementation

{$R-,S-}      (* range checking off, stack-overflow off *)
procedure Com_interrupt_Driver; interrupt;
var b: byte;
begin
    b:=Port[Uart_Iir];
    while not odd(b) do
    begin
       case (b and 7) of
          0: begin
                b:=Port[Uart_Msr];
                if odd(b) then   (* change in cts? *)
                begin
                   if odd(b shr 4) then port[Uart_Ier]:=(port[Uart_Ier] or 2)
                      else port[Uart_Ier]:=(port[Uart_Ier] and not 2);
                end;
             end;

          2: begin
                while ((Tx_chars>0) or (_send_ch>0)) and (_allowsend) and
                      (odd(port[uart_msr] shr 4)) and odd(port[uart_lsr] shr 5) do
                begin
                   if _send_ch>0 then
                   begin
                      _sent_ch:=_send_ch;
                      Port[Uart_Data]:=_send_ch;
                      _send_ch:=0;
                   end else
                   begin
                      Port[Uart_Data]:=Tx_Queue^[Tx_Out];
                      inc(Tx_Out);
                      if Tx_Out>Tx_Queue_Size then Tx_Out:=1;
                      dec(Tx_Chars);
                   end;
                end;
                if (Tx_chars<1) and (_send_ch=0) then
                Port[Uart_Ier]:=(Port[Uart_Ier] and not 2); {thre off}
             end;

          4: while odd(port[uart_lsr]) do  {data avail}
             begin
                b:=Port[Uart_Data];
                if (b=XON ) and (_do_XONXOFF) then _allowsend:=true else
                if (b=XOFF) and (_do_XONXOFF) then _allowsend:=false else
                if Rx_Chars<=Rx_Queue_Size then
                begin
                   Rx_Queue^[Rx_in]:=b;
                   inc(Rx_in);
                   if Rx_in>Rx_Queue_Size then Rx_in:=1;
                   Rx_Chars:=Succ(Rx_Chars);
                   if (rx_chars=rx_almostfull) or (rx_chars=rx_almostfull2) then
                   begin
                      if _do_XONXOFF then
                      begin
                         _send_ch:=XOFF;
                         port[uart_ier]:=port[uart_ier] or 2;
                      end;
                      if _do_RTSCTS then port[uart_mcr]:=port[uart_mcr] and not 2;
                   end;
                end;
             end;

          6: b:=Port[Uart_Lsr]; { dummy read }
       end;
       b:=Port[Uart_Iir];
    end;

    {Tell the interrupt controller that we're done with this interrupt}
    Port[$20]:=$20;
end;
{$R+,S+}

procedure _sendbreak;
var w: byte;
begin
   w:=Port[Uart_Lcr];        { Save current value of LCR }
   port[Uart_Lcr]:=w or $40; { Turn on bit 6 (BREAK)     }
   delay(5000);              { Wait for remote to notice }
   port[Uart_Lcr]:=w;        { Restore value of LCR      }
end;

procedure _flush_rx;
begin
   asm CLI; end;
   Rx_Chars:=0;
   Rx_in:=1;
   Rx_Out:=1;
   asm STI; end;
end;

procedure _flush_tx;
begin
   asm CLI; end;
   Tx_Chars:=0;
   Tx_in:=1;
   Tx_Out:=1;
   asm STI; end;
end;

function _cd: Boolean;
begin
   _cd:=Com_installed and odd(Port[Uart_Msr] shr 7);
end;

function _get: byte;
begin
   asm CLI; end;
   _get:=Rx_Queue^[Rx_Out];
   inc(Rx_Out);
   if Rx_Out>Rx_Queue_Size then Rx_Out:=1;
   dec(Rx_Chars);
   if (rx_chars=rx_lowpoint) or (rx_chars=0) then
   begin
      if (_do_XONXOFF) and (_sent_ch=XOFF) then
      begin
         _sent_ch:=0;
         _send_ch:=XON;
         port[uart_ier]:=port[uart_ier] or 2;                  {thre on}
      end;
      if _do_RTSCTS then port[uart_mcr]:=port[uart_mcr] or 2;  {rts on}
   end;
   asm STI; end;
end;

function _rx_ready: boolean;
begin
   _rx_ready:=(Rx_Chars>0) and com_installed;
end;

procedure _put(ch: byte);
begin
   if Com_installed then
   begin
      repeat until Tx_Chars<Tx_Queue_Size;
      asm CLI; end;
      Tx_Queue^[Tx_in]:=ch;
      if Tx_in<Tx_Queue_Size then inc(Tx_in) else Tx_in:=1;
      inc(Tx_Chars);
      if odd(Port[Uart_Msr] shr 4) then Port[Uart_Ier]:=Port[Uart_Ier] or 2;
      asm STI; end;
   end;
end;

procedure _putstring(st: String);
var i: byte;
begin
   For i:=1 to length(st) do _put(ord(st[i]));
end;

procedure _dtr;
begin
   if Com_installed then
   begin
      asm CLI; end;
      if state then Port[Uart_Mcr]:=Port[Uart_Mcr] or 1 else
         Port[Uart_Mcr]:=Port[Uart_Mcr] and not 1;
      asm STI; end;
   end;
end;

procedure _set_param(Speed: word; parity: char; Data_Bits,Stop_Bits: byte);
var lcr,p,db: byte;
    divisor: word;
begin
   if com_installed then
   begin
      case data_bits of
        5: db:=$00;
        6: db:=$02;
        7: db:=$01;
        8: db:=$03;
      end;
      case parity of
         'N': p:=$00;
         'O': p:=$08;
         'E': p:=$18;
         'M': p:=$28;
         'S': p:=$38;
      end;
      lcr:=p or db;
      if Stop_Bits=2 then lcr:=lcr or $04;

      asm CLI; end;

      if speed<2 then speed:=2;
      divisor:=115200 div speed;
      Port[Uart_Lcr]:=Port[Uart_Lcr] or $80;
      Portw[Uart_Data]:=divisor;
      Port[Uart_Lcr]:=Port[Uart_Lcr] and not $80;

      Port[Uart_Lcr]:=Port[Uart_Lcr] and $40 or lcr;

      asm STI; end;
   end;
end;

function _found16550(addr: word): boolean;
var i,j: byte;
begin
   i:=Port[addr];
   Port[addr]:=$C1;
   delay(100);
   j:=Port[addr];
   Port[addr]:=i;
   _found16550:= ((j shr 6) in [2,3]) and (_do_fifo);
end;

{install the communications driver.  Portnum should be 1..Max_Port.
Error codes returned are:

  0 - No Error
  1 - invalid port number
  2 - UART for that port is not present
  3 - Already installed, new installation ignored}

procedure _install(PortNum: word);
var ier: byte;
begin
   if (not Com_installed) and (portnum in [1..max_port]) then
   begin
      Rx_lowpoint:= (Rx_Queue_size div 4);
      Rx_almostfull:= (Rx_Queue_size div 4) * 3;
      Rx_almostfull2:= (Rx_Queue_size div 10) * 9;
      _allowsend:=true;
      _send_ch:=0;
      _sent_ch:=0;

      {Set i/o addresses and other hardware specifics for selected port}
      Uart_Data:=Uart_Base;
      Uart_Ier:=Uart_Data + 1;
      Uart_Iir:=Uart_Data + 2;
      uart_fcr:=uart_data + 2;
      Uart_Lcr:=Uart_Data + 3;
      Uart_Mcr:=Uart_Data + 4;
      Uart_Lsr:=Uart_Data + 5;
      Uart_Msr:=Uart_Data + 6;
      Uart_Spr:=Uart_Data + 7;
      intNum:=intNums;
      I8259Bit:=1 shl I8259Levels;

      {Return Error if hardware not installed}
      Old_Ier:=Port[Uart_Ier];
      Port[Uart_Ier]:=0;
      if Port[Uart_Ier]=0 then
      begin
         getmem(rx_queue,rx_queue_size);
         getmem(tx_queue,tx_queue_size);
         {Save original interrupt controller mask, then disable the
          interrupt controller for this interrupt.}
         asm CLI; end;
         Old_I8259_Mask:=Port[$21];
         Port[$21]:=Old_I8259_Mask or I8259Bit;
         asm STI; end;

         {Clear the transmit and receive queues}
         _flush_tx;
         _flush_rx;

         {Save current interrupt vector, then set the interrupt vector to
          the address of our interrupt driver.}
         GetintVec(intNum, Old_Vector);
         SetintVec(intNum, @Com_interrupt_Driver);
         Com_installed:=True;

         {Set parity to none, turn off BREAK signal, and make sure
          we're not addressing the baud rate registers.}
         Port[Uart_Lcr]:=3;

         {Save original contents of modem control register, then enable
          interrupts to system bus and activate RTS.  Leave DTR the way
          it was.}
         asm CLI; end;
         Old_Mcr:=Port[Uart_Mcr];
         port[uart_mcr]:=$B;         {dtr on/rts on/interr to sys bus}
         asm STI; end;

         {Enable interrupt on data-available and interrupt upon change in
          modem status register (specifically, DSR).  The interrupt for
          transmit-ready is enabled when a character is put into the
          transmit queue, and disabled when the transmit queue is empty.}
         if _found16550(uart_fcr) then
           port[uart_fcr]:=$c7 else port[uart_fcr]:=$00;
         Port[Uart_Ier]:=9;      {data avail, modem stat}

         {Enable the interrupt controller for this interrupt.}
         asm CLI; end;
         Port[$21]:=Port[$21] and not I8259Bit;
         asm STI; end;
      end;
   end;
end;

procedure _deinstall;
begin
   if Com_installed then
   begin
      freemem(rx_queue,rx_queue_size);
      freemem(tx_queue,tx_queue_size);
      Com_installed:=False;
      {Restore Modem-Control-Register and interrupt-Enable-Register.}

      Port[Uart_Mcr]:=Old_Mcr or 1;  {activate dtr}
      Port[Uart_Ier]:=Old_Ier;
      port[uart_fcr]:=$00;           {turning fifo off}

      {Restore appropriate bit of interrupt controller's mask}
      asm CLI; end;
      Port[$21]:=Port[$21] and not I8259Bit or
      Old_I8259_Mask and I8259Bit;
      asm STI; end;

      {Reset the interrupt vector}
      SetintVec (intNum, Old_Vector);
    end;
end;

procedure _rts(state: boolean);
begin
   if Com_installed then
   begin
      asm CLI; end;
      if state then Port[Uart_Mcr]:=Port[Uart_Mcr] or 2 else
         Port[Uart_Mcr]:=Port[Uart_Mcr] and not 2;
      asm STI; end;
   end;
end;

{This procedure is called when the program exits for any reason.  It
deinstalls the interrupt driver.}

{$F+} procedure Exit_procedure; {$F-}
begin
   _deinstall;
   ExitProc:=Exit_Save;
end;

begin
  Exit_Save:=ExitProc;
  ExitProc:=@Exit_procedure;
end.
