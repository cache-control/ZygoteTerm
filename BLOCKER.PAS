(*
        CallùBlocker PA4.3
                     2 June, 1996

        Description: Monitors CallùBlocker circuit, and compares
                     inputed value to values in the database. There
                     are ten (10) entries in the database, each
                     consisted with an access code field and a comment
                     field.
*)
program call_blocker;

uses crt,dos,z_util;

const D6=64;

type callertype1=record
         code: string[15];
         comment: string[60];
     end;
     callertype=array[1..10] of callertype1;

var callerfile: file of callertype;
    callerdata: callertype;
    map: array[1..16] of char;
    bits: byte;
    base: word;
    quit: boolean;

function checkvideo: boolean;
var regs: registers;
begin
    regs.ah:=$F;
    intr($10,regs);
    checkvideo:=regs.al<>7;
end;

procedure alarm(s: string);
var i,j: Byte;
    buf: array[1..640] of byte;
begin
   J:=0;
   movefromscreen(mem[baseofscreen:1920],buf,320);
   makebox(attr(cyan,black),19,13,62,16,1);
   fwrite('Alarm,',14,21,attr(white,black));
   fwrite(s,14,28,attr(yellow,black));
   fwrite(chars('Ü',40),15,21,attr(cyan,black));
   repeat
     inc(J);
     fwrite('ÜÜ',15,4*(j-1)+21,attr(lightcyan,black));
     for I:=1 to 150 do
     begin
        Sound(500);
        Delay(10);
        NoSound;
     end;
     Delay(1400);
   until (J=10) or (keypressed);
   movetoscreen(buf,mem[baseofscreen:1920],320);
   if keypressed then waitkey;
end;

procedure startup;
var loop: byte;
begin
   cursor(false);
   quit:=false;
   base:=888;
   port[base]:=0;
   delay(100);
   port[base]:=3;
   port[base+2]:=0;
   delay(100);
   map[1]:='1';
   map[2]:='2';
   map[3]:='3';
   map[4]:='4';
   map[5]:='5';
   map[6]:='6';
   map[7]:='7';
   map[8]:='8';
   map[9]:='9';
   map[10]:='0';
   map[11]:='*';
   map[12]:='#';
   map[13]:='A';
   map[14]:='B';
   map[15]:='C';
   map[16]:='D';
   configdata.timech:='ù';
   configdata.datech:=':';
   colorvideo:=checkvideo;
   if colorvideo then baseofscreen:=$b800 else baseofscreen:=$b000;
   makebox(attr(lightblue,black),1,1,80,25,1);
   fwritena('Ã'+chars('Ä',78)+'´',3,1);
   fwritena('Ã'+chars('Ä',78)+'´',12,1);
   fwritena('Ã'+chars('Ä',78)+'´',14,1);
   fwrite(' PA4.3 CallùBlocker by My Nguyen ',1,4,attr(lightgray,black));
   fwrite('Access Code',2,3,attr(yellow,black));
   fwrite('Date     Time',2,19,attr(cyan,black));
   fwritena('³',2,40);
   fwritena('Â',1,40);
   fwritena('Á',3,40);
   fwritena('Â',14,17);
   fwrite('input=',2,42,attr(lightgreen,black));
   vertchars(attr(lightblue,black),17,15,24,'³');
   fwritena('Á',25,17);
   fwrite('Access Code',13,3,attr(lightred,black));
   fwrite('Name/Comment',13,19,attr(white,black));
   fillchar(callerdata,sizeof(callerdata),0);
   if not exist('callers.dat') then
   begin
      callerdata[1].code:='272101';
      callerdata[1].comment:='sample access code';
   end else
   begin
      assign(callerfile,'callers.dat');
      reset(callerfile);
      read(callerfile,callerdata);
      close(callerfile);
   end;
   for loop:=1 to 10 do
   begin
      fwrite(callerdata[loop].code,14+loop,2,attr(lightgray,black));
      fwrite(callerdata[loop].comment,14+loop,19,attr(lightgray,black));
   end;
end;

procedure main;
var stalled: boolean;
    store: string;
    lasttick: word;
    start,add: integer;
    found,lasty,
    loop,laston,temp: byte;
    ch: char;
begin
   stalled:=false;
   store:='';
   lasttick:=clocktick;
   start:=11;
   add:=1;
   laston:=1;
   lasty:=1;
   changeattr(1,1,start,15);
   repeat
      if clocktick-lasttick>18 then
      begin
         lasttick:=clocktick;
         fwrite(time(1),2,69,attr(lightcyan,black));
         changeattr(1,1,start,7);
         start:=start+add;
         if start>22 then
         begin
            add:=-1;
            start:=21;
         end;
         if start<11 then
         begin
            add:=1;
            start:=12;
         end;
         changeattr(1,1,start,15);
      end;
      if (port[base+2] xor 1)=1 then
      begin
         fwrite('ON ',2,37,attr(lightcyan,black));
         bits:=PORT[base+1];
         if (bits and D6)=D6 then
         begin
            if (bits and 128)=128 then bits:=(bits shl 1)+128
              else bits:=bits shl 1;
            bits:=bits shr 4;
            repeat until (port[base+1] and D6)=0;
            if bits<11 then store:=store+map[bits];
            if length(store)>20 then delete(store,1,1);
            fwrite(store+blanks(20-length(store)),2,48,attr(yellow,black));
            if bits=12 then
            begin
               found:=0;
               for loop:=1 to 10 do
                  if store=callerdata[loop].code then found:=loop;

               if found>0 then
               begin
                  window(2,4,39,11);
                  color(lightgray,black);
                  gotoxy(1,lasty);  write(callerdata[found].code);
                  gotoxy(18,lasty); write(date);
                  gotoxy(27,lasty); writeln(time(1));
                  lasty:=wherey;
                  window(1,1,80,25);
                  fwrite('STALLED',13,73,attr(red,black));
                  port[base]:=2;
                  fwrite('INCOMING CALL:',5,42,attr(lightred,black)+128);
                  fwrite('Pick up phone then press any key',6,42,attr(lightred,black));
                  alarm('INCOMING CALL --- NEED RESPONSE');
                  fwrite('              ',5,42,attr(lightred,black)+128);
                  fwrite('                                    ',6,42,attr(lightred,black));
                  fwrite('       ',13,73,attr(red,black));
                  port[base]:=3;
               end;
               port[base]:=1;
               delay(1000);
               port[base]:=3;
               fwrite('       ',13,73,attr(red,black));
               port[base]:=3;
               stalled:=false;
            end;
         end;
      end else
      begin
         fwrite('OFF',2,37,attr(lightred,black));
         if store>'' then
         begin
            store:='';
            fwritena(chars(' ',20),2,48);
         end;
      end;

      if keypressed then
      begin
         ch:=upcase(readkey);
         if ch=#0 then ch:=readkey else
         begin
            case ch of
               'R': begin
                       port[base]:=1;
                       delay(1000);
                       port[base]:=3;
                       store:='';
                       fwritena(chars(' ',20),2,48);
                    end;
               'S': begin
                       stalled:=not stalled;
                       if stalled then
                       begin
                          fwrite('STALLED',13,73,attr(red,black));
                          port[base]:=2;
                       end else
                       begin
                          fwrite('       ',13,73,attr(red,black));
                          port[base]:=3;
                       end;
                    end;
               #13: begin
                       page.flag:=0;
                       timestat.flag:=0;
                       sc.x:=2; sc.y:=15;
                       sc.s:=15;
                       sc.c:=hattr(white,blue);
                       sc.nc:=attr(lightgray,black);
                       sc.t:=10;
                       if scrollchoice(#27+#13,laston)=#13 then
                       begin
                          temp:=0;
                          editflag(0,0,0,1,0,0,0);
                          if input(attr(white,red),2,14+laston,callerdata[laston].code,15,15,temp)=#0 then;
                          temp:=0;
                          editflag(1,0,0,1,1,0,1);
                          if input(attr(white,red),19,14+laston,callerdata[laston].comment,60,60,temp)=#0 then;
                          fwrite(callerdata[laston].code+blanks(15-length(callerdata[laston].code)),
                             14+laston,2,attr(lightgray,black));
                          fwrite(callerdata[laston].comment+blanks(60-length(callerdata[laston].comment)),
                             14+laston,19,attr(lightgray,black));
                          cursor(false);
                       end;
                    end;
               #27: quit:=true;
            end;
         end;
      end;
    until quit;
end;


procedure shutdown;
var loop: byte;
begin
   assign(callerfile,'callers.dat');
   rewrite(callerfile);
   write(callerfile,callerdata);
   close(callerfile);
   cursor(true);
   color(lightgray,black);
   clrscr;
end;

begin
   startup;
   main;
   shutdown;
end.
