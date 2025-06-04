unit z_config;

interface
{$F+,O+}

procedure LoadZYG;
procedure RunconfigZYG;
function checkarg(s: string): byte;
procedure setblink;

implementation

uses crt,dos,z_util,z_comio;

const cmname='ZYGOTE.CMD';  (* config. menu data *)

function checkarg(s: string): byte;
var x,y: byte;
begin
   y:=0;
   for x:=1 to paramcount do if s=caps(paramstr(x)) then y:=x;
   checkarg:=y;
end;

Function checkvideo: boolean;
var regs: registers;
begin
    regs.ah:=$F;
    intr($10,regs);
    checkvideo:=regs.al<>7;
end;

procedure initscr;
var c,c2: byte;
begin
   with configdata do
   begin
      c:=attr(cyan,black);
      makebox(c,1,1,80,13,1);
      fwritena('´                        Ã',1,4);
      fwrite(cmsg('¾»£Í˜Ž‰†ˆŠŠƒŠ‡’'),1,9,attr(yellow,black));
      fwritena('Â',1,31); vertchars(c,31,2,12,'³'); fwritena('Á',13,31);
      fwritena('ÖÄ· · ·ÖÄ·ÖÄ·ÄÒÄÒÄ·',2,4);
      fwrite('ÖÄ½ ÓÄ¶º Òº º º ÇÄ',3,4,attr(lightcyan,black));
      fwritena('ÓÄÄ½ÄÄ½ÓÄ½ÓÄ½ Ð ÐÄ½',4,4);
      fwrite('(TM)',4,24,attr(lightgray,black));
      fwritena('ÄÄÍ Version '+cmsg(zversion)+' ÍÄÄ',5,4);
      c:=attr(lightgray,black); c2:=attr(white,black);
      fwrite('Author:',7,4,c);  fwrite(cmsg('ºÕº”‡ˆ•'),7,12,c2);
      fwrite('Line status:',8,4,c);    if _CD then fwrite('Online',8,17,c2) else fwrite('Offline',8,17,c2);
      fwrite('Log session:',9,4,c);    if keeplog then fwrite('Open',9,17,c2) else fwrite('Close',9,17,c2);
      fwrite('Operation:',10,4,c);    if (lastdata.lastbbs>0) and (_CD) then fwrite('Continuation',10,15,c2)
                                         else fwrite('Initialization',10,15,c2);
      fwrite('Disk free:',11,4,c);     fwrite(diskspace(1),11,15,c2);
      fwrite('Times used:',12,4,c); fwrite(its(lastdata.timesused[7]),12,16,c2);
      fwrite('Registered to:',2,34,c); if registered then fwrite(regname,2,49,c2) else
      fwrite(cmsg('¡½ ´·¦½¹©¹¯­'),2,49,c2);
      fwrite('User name:',3,34,c);   fwrite(username,3,45,c2);
      fwrite('Area code:',4,34,c);   fwrite(areacode,4,45,c2);
      fwrite('Graphic:',5,34,c);     case dparam.graphic of
                                          uANSI: fwrite('ANSI graphic',5,43,c2);
                                         uVT100: fwrite('VT100 graphic',5,43,c2);
                                        uAVATAR: fwrite('AVATAR graphic',5,43,c2);
                                          uNONE: fwrite('No graphic',5,43,c2);
                                     end;
      fwrite('Xmit buffer:',6,34,c); fwrite(its(xmitsize)+' bytes',6,47,c2);
      fwrite('Recv buffer:',7,34,c); fwrite(its(recvsize)+' bytes',7,47,c2);
      fwrite('Serial port:',8,34,c); fwrite('Com'+its(comport),8,47,c2);
      fwrite('Parameters:',9,34,c);  with param do fwrite(its(speed)+parity+its(dbit)+its(sbit),9,46,c2);
      fwrite('XON/XOFF:',10,34,c);   if xonxoff then fwrite('Active',10,44,c2) else fwrite('Disabled',10,44,c2);
      fwrite('CTS/RTS:',11,34,c);    if ctsrts then fwrite('Active',11,43,c2) else fwrite('Disabled',11,43,c2);
      fwrite('Scrollback size: ',12,34,c); fwrite(its(scrollbacksize)+' lines',12,51,c2);
   end;

   {unregistered
   fwrite(cmsg('Ø¤¾½«ª¥¸¾¬º¢¢Ï'),12,64,attr(lightblue,black));
   changeattr(12,12,65,attr(lightcyan,black));
   }

end;

procedure SetIntense;
var regs: registers;
begin
  FillChar(Regs,SizeOf(Regs),0);
  Regs.AH := $10;
  Regs.AL := $03;
  Regs.BL := $00;
  Intr($10,Regs);
end;

procedure SetBlink;
var regs: registers;
begin
  FillChar(Regs,SizeOf(Regs),0);
  Regs.AH := $10;
  Regs.AL := $03;
  Regs.BL := $01;
  Intr($10,Regs);
end;

Procedure configzyg;
var  Video1: ^videotype;
     lo: array[0..3] of byte;
     checkch: char;
     dcolr,ncolr,ecolr: byte;

procedure mainmenu;
var y: byte;
begin
   fwrite('  ÖÄ· · ·ÖÄ·ÖÄ·ÄÒÄÒÄ· ',1,1,attr(lightcyan,black));
   fwrite('  ÖÄ½ ÓÄ¶º Òº º º ÇÄ  ',2,1,attr(cyan,black));
   fwrite('  ÓÄÄ½ÄÄ½ÓÄ½ÓÄ½ Ð ÐÄ½ ',3,1,attr(lightcyan,black));
   makebox(attr(cyan,black),23,1,80,3,1);
   fwritena('Â',1,68); fwritena('³',2,68); fwritena('Á',3,68);
   fwrite('System configuration',2,36,attr(yellow,black));
   makebox(attr(lightgray,black),1,4,80,24,5);
   makebox(attr(lightcyan,blue),3,5,32,23,5);
   fwritena('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',5,4);
   fwritena('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',23,4);
   fwrite(' Detail: ',25,1,attr(lightgray,black));
   fwrite(blanks(71),25,10,attr(white,black));
   fwrite('þ System status þ',5,42,attr(lightcyan,black));
   fwrite('ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ',6,42,attr(cyan,black));
end;

procedure givestatus;
var c,c2: byte;
begin
   c:=attr(lightgray,black);
   c2:=attr(white,black);
   with configdata do
   begin
      fwrite('Area code:',7,42,c);    fwrite(areacode,7,53,c2);
      fwrite('Comport:',8,42,c);      fwrite('COM'+its(comport),8,51,c2);
      fwrite('Parameters:',9,42,c);
      with param do fwrite(its(speed)+parity+its(dbit)+its(sbit),9,54,c2);
      fwrite('KBD file:',10,42,c);    fwrite(lastdata.name_kbd+'.KBD',10,52,c2);
      fwrite('TBL file:',11,42,c);    fwrite(lastdata.name_tbl+'.TBL',11,52,c2);
      fwrite('Xmit buffer:',12,42,c); fwrite(its(xmitsize)+' bytes',12,55,c2);
      fwrite('Recv buffer:',13,42,c); fwrite(its(recvsize)+' bytes',13,55,c2);
      fwrite('Hardware flow:',14,42,c);
      if ctsrts then fwrite('ON',14,57,c2) else fwrite('OFF',14,57,c2);
      fwrite('Software flow:',15,42,c);
      if xonxoff then fwrite('ON',15,57,c2) else fwrite('OFF',15,57,c2);
      fwrite('Scrollback size:',16,42,c); fwrite(its(scrollbacksize)+' lines',16,59,c2);
      fwrite('Message delay time:',17,42,c); fwrite(its(msgdelay)+' ms',17,62,c2);
      fwrite('Printer port:',18,42,c); fwrite('LPT'+its(printerport+1),18,56,c2);
      fwrite('Use 16550 FIFO buffer:',19,42,c);
      if dofifo then fwrite('Yes',19,65,c2) else fwrite('No ',19,65,c2);
      fwrite('Registered copy:',20,42,c);
      if registered then fwrite('REGISTERED    ',20,59,c2) else
         fwrite('NOT REGISTERED',20,59,c2);
   end;
   fwrite(cmsg('¾»£Í˜Ž‰†ˆŠŠƒŠ‡’'),22,42,attr(lightgreen,black));
   fwrite(cmsg('¬€‡Ê›€Ž‘—Ã„“º¬«¹¿'),23,42,attr(lightgreen,black));
end;

procedure win(tx,ty,bx,by: byte);
var i,y: byte;
begin
   makebox(attr(cyan,black),tx,ty,bx,by,1);
   if sc.t>0 then
   begin
      fwritena('Â',ty,sc.s+tx+1);
      y:=by-1;
      if sc.t<18 then
      begin
         y:=ty+sc.t;
         fwritena('Ã'+chars('Ä',bx-tx-1)+'´',ty+sc.t+1,1);
         fwritena('Á',ty+sc.t+1,sc.s+tx+1);
      end else fwritena('Á',by,sc.s+tx+1);
      for i:=ty+1 to y do fwritena('³',i,sc.s+tx+1);
   end;
end;
   procedure writeyn(x,y: byte; b: boolean);
   begin
      if b then fwrite('Yes',y,x,ncolr) else fwrite('No ',y,x,ncolr);
   end;
   procedure writest(x,y,size: byte; st: string);
   begin
      st:=copy(st,1,size);
      fwrite(st+blanks(size-length(st)),y,x,ncolr);
   end;

   function getnum(x,y,size: byte; num: word): word;
   var s: string[5];
       c,i: word;
       o: byte;
   begin
      s:=its(num);
      o:=length(s)+1;
      editflag(0,0,0,1,0,0,0);
      if input(ecolr,x,y,s,size,size,o)=' ' then;
      val(s,i,c);
      if c=0 then getnum:=i else getnum:=num;
   end;

   procedure page0_1;
   var x,y: byte;
       c: char;

       function keynum(whichcol,whichon: byte): char;
       var n: byte;
       begin
          case whichcol of
            1: case whichon of
                 1:  n:=30; 2:  n:=48; 3:  n:=46; 4:  n:=32; 5:  n:=18; 6:  n:=33;
                 7:  n:=34; 8:  n:=35; 9:  n:=23; 10: n:=36; 11: n:=37; 12: n:=38;
                 13: n:=50; 14: n:=49; 15: n:=24; 16: n:=25; 17: n:=16; 18: n:=19;
               end;
            2: case whichon of
                 1:  n:=31; 2:  n:=20; 3:  n:=22; 4:  n:=47; 5:  n:=17; 6:  n:=45;
                 7:  n:=21; 8:  n:=44; 9:  n:=59; 10: n:=60; 11: n:=61; 12: n:=62;
                 13: n:=63; 14: n:=64; 15: n:=65; 16: n:=66; 17: n:=67; 18: n:=68;
               end;
            3: case whichon of
                 1:  n:=84; 2:  n:=85; 3:  n:=86; 4:  n:=87; 5:  n:=88;  6:  n:=89;
                 7:  n:=90; 8:  n:=91; 9:  n:=92; 10: n:=93; 11: n:=94;  12: n:=95;
                 13: n:=96; 14: n:=97; 15: n:=98; 16: n:=99; 17: n:=100; 18: n:=101;
               end;
            4: case whichon of
                 1:  n:=102; 2:  n:=103; 3:  n:=104; 4:  n:=105; 5:  n:=106;  6:  n:=107;
                 7:  n:=108; 8:  n:=109; 9:  n:=110; 10: n:=111; 11: n:=112;  12: n:=113;
                 13: n:=72; 14:  n:=75; 15:  n:=77;  16: n:=115; 17: n:=116;  18: n:=80;
               end;
            5: case whichon of
                 1:  n:=71;  2:  n:=79;  3:  n:=73;  4:  n:=81;  5:  n:=82;   6:  n:=83;
                 7:  n:=119; 8:  n:=117; 9:  n:=132; 10: n:=118; 11: n:=165;  12: n:=166;
                 13: n:=15; 14:  n:=129; 15: n:=120; 16: n:=121; 17: n:=122;  18: n:=123;
               end;
            6: case whichon of
                 1:  n:=124; 2:  n:=125; 3:  n:=126;  4:  n:=127;  5:  n:=128;
                 6:  n:=3;   7:  n:=114; 8:  n:=130;  9:  n:=131;
               end;
          end;
          keynum:=chr(n);
       end;

       procedure writekeys(x,y,wcol: byte);
       var n: byte;
           s: string;
       begin
          for n:=1 to bigsc[wcol].t do
              writest(x,y+n-1,18,copy(keyboarddata.altkey[keynum(wcol,n)],1,18));
          for n:=bigsc[wcol].t+1 to 18 do writest(x,y+n-1,18,blanks(18));
       end;

   begin
      sctotal:=6;
      bigsc[1]:=sc;
      for scptr:=2 to 6 do
      begin
         x:=10*scptr+1;
         fwritena('Â',4,x);
         fwritena('Á',23,x);
         for y:=5 to 22 do fwritena('³',y,x);
         if readdesc(cmname,'@0-1#'+its(scptr)) then writedescfield;
         bigsc[scptr]:=sc;
      end;
      fwrite('Modifying '+lastdata.name_kbd+'.KBD',24,2,attr(lightblue,black));
      repeat
         writekeys(62,5,scptr);
         checkch:=scrollchoice(#13+#16+#17+#27+'L',lo[1]);
         case checkch of
          #255: begin
                   sc:=bigsc[scptr];
                   if lo[1]>sc.t then lo[1]:=sc.t;
                end;
           #16: begin
                   inc(scptr);
                   if scptr>6 then scptr:=1;
                   sc:=bigsc[scptr];
                   if lo[1]>sc.t then lo[1]:=sc.t;
                end;
           #17: begin
                   dec(scptr);
                   if scptr<1 then scptr:=6;
                   sc:=bigsc[scptr];
                   if lo[1]>sc.t then lo[1]:=sc.t;
                end;
           #13: with keyboarddata do
                begin
                   lo[3]:=0;
                   editflag(1,1,1,1,1,0,1);
                   if input(ecolr,62,5+lo[1]-1,altkey[keynum(scptr,lo[1])],50,18,lo[3])=' ' then;
                   if altkey[keynum(scptr,lo[1])][1]='@' then altkey[keynum(scptr,lo[1])]:=caps(altkey[keynum(scptr,lo[1])]);
                end;
         end;
      until checkch=#27;
      sctotal:=0;
   end;

   procedure page0_2and3(which: char);
   var x,y,i,temp: byte;
       num: word;
   begin
      x:=6;
      sc.x:=2;
      sc.y:=5;
      sc.s:=4;
      sc.t:=18;
      sc.nc:=15;
      sc.c:=112;
      for i:=1 to 15 do
      with tabledata do
      begin
         bigsc[i]:=sc;
         bigsc[i].x:=x-4;
         fwritena('Â',4,x);
         fwritena('Á',23,x);
         for y:=5 to 22 do
         begin
            fwritena('³',y,x);
            num:=(i-1)*18+(y-4);
            if num<256 then
            begin
               if which='T' then fwrite(chr(tx[chr(num)])+its(tx[chr(num)]),y,x-4,sc.nc) else
                  fwrite(rx[num]+its(ord(rx[num])),y,x-4,sc.nc);
            end;
         end;
         inc(x,5);
      end;
      bigsc[i].t:=3;
      i:=1;
      fwrite('Modifying '+lastdata.name_tbl+'.TBL',24,2,attr(lightblue,black));
      scptr:=1;
      sctotal:=15;
      repeat
         for y:=1 to 18 do
         begin
            temp:=18*(scptr-1)+y;
            fielddesc^[y]:='Original value ['+chr(temp)+'] '+its(temp);
            fielddesc^[y]:=fielddesc^[y]+blanks(70-length(fielddesc^[y]));
         end;
         checkch:=scrollchoice(#13+#16+#17+#27,lo[1]);
         case checkch of
          #255: begin
                   sc:=bigsc[scptr];
                   if lo[1]>sc.t then lo[1]:=sc.t;
                end;
           #16: begin
                   inc(scptr);
                   if scptr>sctotal then scptr:=1;
                   sc:=bigsc[scptr];
                   if lo[1]>sc.t then lo[1]:=sc.t;
                end;
           #17: begin
                   dec(scptr);
                   if scptr<1 then scptr:=sctotal;
                   sc:=bigsc[scptr];
                   if lo[1]>sc.t then lo[1]:=sc.t;
                end;
           #13: with tabledata do
                begin
                   temp:=(scptr-1)*18+lo[1];
                   if which='T' then
                   begin
                      num:=tx[chr(temp)];
                      tx[chr(temp)]:=getnum(5*(scptr-1)+3,lo[1]+4,3,num);
                      writest(5*(scptr-1)+2,lo[1]+4,4,chr(tx[chr(temp)])+its(tx[chr(temp)]));
                   end else
                   begin
                      num:=ord(rx[temp]);
                      rx[temp]:=chr(getnum(5*(scptr-1)+3,lo[1]+4,3,num));
                      writest(5*(scptr-1)+2,lo[1]+4,4,rx[temp]+its(ord(rx[temp])));
                   end;
                end;
         end;
      until checkch=#27;
      sctotal:=0;
   end;

   procedure page0_4;
   begin
      with configdata do
      repeat
         writest(29,5,4,'Com'+its(comport));
         writest(29,6,8,its(param.speed)+'bps');
         writest(29,7,1,param.parity);
         writest(29,8,1,its(param.dbit));
         writest(29,9,1,its(param.sbit));
         case param.graphic of
              uANSI: writest(29,10,14,'ANSI graphic');
             uVT100: writest(29,10,14,'VT100 graphic');
            uAVATAR: writest(29,10,14,'AVATAR graphic');
              uNONE: writest(29,10,14,'No graphic');
         end;
         writest(29,11,4,its(xmitsize));
         writest(29,12,4,its(recvsize));
         writeyn(29,13,xonxoff);
         writeyn(29,14,ctsrts);
         writest(29,15,1,its(printerport+1));
         writest(29,16,3,its(antichar));
         writest(29,17,3,its(anticounter));
         checkch:=scrollchoice(#27+#13,lo[1]);
         if checkch=#13 then
         case lo[1] of
            1: if comport=4 then comport:=1 else inc(comport);
            2: case param.speed of
                   300: param.speed:=1200;
                  1200: param.speed:=2400;
                  2400: param.speed:=4800;
                  4800: param.speed:=9600;
                  9600: param.speed:=14400;
                 14400: param.speed:=19200;
                 19200: param.speed:=28800;
                 28800: param.speed:=38400;
                 38400: param.speed:=57600;
                 57600: param.speed:=300;
               end;
            3: case param.parity of
                 'N': param.parity:='E';
                 'E': param.parity:='S';
                 'S': param.parity:='M';
                 'M': param.parity:='O';
                 'O': param.parity:='N';
               end;
            4: if param.dbit=8 then param.dbit:=5 else inc(param.dbit);
            5: if param.sbit=1 then param.sbit:=2 else param.sbit:=1;
            6: case param.graphic of
                    uANSI: param.graphic:=uVT100;
                   uVT100: param.graphic:=uAVATAR;
                  uAVATAR: param.graphic:=uNONE;
                    uNONE: param.graphic:=uANSI;
               end;
            7: begin
                  xmitsize:=getnum(29,lo[1]+4,4,xmitsize);
                  if xmitsize<128 then xmitsize:=128;
                  if xmitsize>1024 then xmitsize:=1024;
               end;
            8: begin
                  recvsize:=getnum(29,lo[1]+4,4,recvsize);
                  if recvsize<1024 then recvsize:=1024;
                  if recvsize>6144 then recvsize:=6144;
               end;
            9: xonxoff:=not xonxoff;
           10: ctsrts:=not ctsrts;
           11: begin
                  inc(printerport);
                  if printerport>2 then printerport:=0;
               end;
           12: antichar:=getnum(29,lo[1]+4,3,antichar);
           13: anticounter:=getnum(29,lo[1]+4,3,anticounter);
         end;
      until checkch=#27;
   end;

   procedure page0_5;
      procedure addbl(var s: string80);
      begin
         if s[length(s)]<>'\' then s:=s+'\';
      end;
   begin
      with configdata do
      repeat
         lo[3]:=0;
         writest(29,5,25,username);
         if configdata.showpwd then
            writest(29,6,20,syscode) else
               writest(29,6,20,chars('þ',length(syscode)));
         writest(29,7,3,areacode);
         writest(29,8,4,lfd);
         writest(29,9,40,updir);
         writest(29,10,40,dndir);
         writest(29,11,40,hupdir);
         writest(29,12,40,hdndir);
         writest(29,13,20,hlevel);
         writest(29,14,20,hshutdown);
         writest(29,15,20,haccess);
         writeyn(29,16,hopen);
         writest(29,17,1,its(hostring));
         writest(29,18,4,its(scrollbacksize));
         writest(29,19,2,its(pstdiff));
         writeyn(29,20,dlsaving);
         writest(29,21,4,its(msgdelay));
         writest(29,22,2,its(tabsize));
         editflag(1,1,0,1,0,1,1);
         checkch:=scrollchoice(#27+#13,lo[1]);
         if checkch=#13 then
            case lo[1] of
              1: begin
                    editflag(1,1,1,1,1,0,1);
                    if input(ecolr,29,lo[1]+4,username,25,25,lo[3])=' ' then;
                 end;
              2: if input(ecolr,29,lo[1]+4,syscode,20,20,lo[3])=' ' then;
              3: begin
                    editflag(0,1,0,1,0,0,0);
                    if input(ecolr,29,lo[1]+4,areacode,3,3,lo[3])=' ' then;
                 end;
              4: begin
                    editflag(0,1,0,1,0,0,0);
                    if input(ecolr,29,lo[1]+4,lfd,4,4,lo[3])=' ' then;
                 end;
              5: if input(ecolr,29,lo[1]+4,updir,40,40,lo[3])>#0 then addbl(updir);
              6: if input(ecolr,29,lo[1]+4,dndir,40,40,lo[3])>#0 then addbl(dndir);
              7: if input(ecolr,29,lo[1]+4,hupdir,40,40,lo[3])>#0 then addbl(hupdir);
              8: if input(ecolr,29,lo[1]+4,hdndir,40,40,lo[3])>#0 then addbl(hdndir);
              9: if input(ecolr,29,lo[1]+4,hlevel,20,20,lo[3])>#0 then;
             10: if input(ecolr,29,lo[1]+4,hshutdown,20,20,lo[3])>#0 then;
             11: if input(ecolr,29,lo[1]+4,haccess,20,20,lo[3])>#0 then;
             12: hopen:=not hopen;
             13: begin
                    hostring:=getnum(29,lo[1]+4,1,hostring);
                    if hostring<1 then hostring:=2;
                 end;
             14: scrollbacksize:=getnum(29,lo[1]+4,4,scrollbacksize);
             15: begin
                    pstdiff:=getnum(29,lo[1]+4,2,pstdiff);
                    if pstdiff>23 then pstdiff:=0;
                 end;
             16: dlsaving:=not dlsaving;
             17: msgdelay:=getnum(29,lo[1]+4,4,msgdelay);
             18: tabsize:=getnum(29,lo[1]+4,2,tabsize);
            end;
      until checkch=#27;
   end;

   procedure page0_6;
      procedure addbl(var s: string80);
      begin
         if s[length(s)]<>'\' then s:=s+'\';
      end;
   begin
      with configdata do
      repeat
         lo[3]:=0;
         writest(29,5,4,its(dtrdelay));
         writest(29,6,10,callwaiting);
         writeyn(29,7,cwtoggle);
         writest(29,8,1,datech);
         writest(29,9,1,timech);
         writeyn(29,10,rescanafteredit);
         writeyn(29,11,dofifo);
         writest(29,12,40,altdndir[1]);
         writest(29,13,40,altdndir[2]);
         writest(29,14,40,altdndir[3]);
         writest(29,15,20,defaultkeypw);
         checkch:=scrollchoice(#27+#13,lo[1]);
         if lo[1]>5 then editflag(1,1,0,1,0,1,1) else editflag(1,1,1,1,1,0,1);
         if checkch=#13 then
            case lo[1] of
              1: dtrdelay:=getnum(29,lo[1]+4,4,dtrdelay);
              2: if input(ecolr,29,lo[1]+4,callwaiting,10,10,lo[3])>#0 then;
              3: cwtoggle:=not cwtoggle;
              4: if input(ecolr,29,lo[1]+4,datech,1,1,lo[3])>#0 then;
              5: if input(ecolr,29,lo[1]+4,timech,1,1,lo[3])>#0 then;
              6: rescanafteredit:=not rescanafteredit;
              7: dofifo:=not dofifo;
              8: if input(ecolr,29,lo[1]+4,altdndir[1],40,40,lo[3])>#0 then addbl(altdndir[1]);
              9: if input(ecolr,29,lo[1]+4,altdndir[2],40,40,lo[3])>#0 then addbl(altdndir[2]);
             10: if input(ecolr,29,lo[1]+4,altdndir[3],40,40,lo[3])>#0 then addbl(altdndir[3]);
             11: begin
                    editflag(1,1,0,1,0,1,0);
                    if input(ecolr,29,lo[1]+4,defaultkeypw,20,20,lo[3])>#0 then;
                 end;
            end;
      until checkch=#27;
   end;

   procedure page0_7;
   begin
      with configdata do
      repeat
         writeyn(29,5,blinkfilter);        writeyn(29,6,param.autolf);
         writeyn(29,7,param.destructbs);   writeyn(29,8,keeplog);
         writeyn(29,9,allowmusic);         writeyn(29,10,param.localecho);
         writeyn(29,11,generatepw);        writeyn(29,12,vretrace);
         writeyn(29,13,init_online);       writeyn(29,14,showstatbar);
         writeyn(29,15,dos_deinstallport); writeyn(29,16,usedtr);
         writeyn(29,17,cryptdecode);       writeyn(29,18,confirmhe);
         writeyn(29,19,usealarm);          writeyn(29,20,expandtab);
         writeyn(29,21,beep);              writeyn(29,22,showpwd);
         checkch:=scrollchoice(#27+#13,lo[1]);
         if checkch=#13 then
            case lo[1] of
               1: blinkfilter:=not blinkfilter;               2: param.autolf:=not param.autolf;
               3: param.destructBS:=not param.destructBS;     4: keeplog:=not keeplog;
               5: allowmusic:=not allowmusic;                 6: param.localecho:=not param.localecho;
               7: generatePW:=not generatePW;                 8: Vretrace:=not Vretrace;
               9: init_online:=not init_online;              10: showstatbar:=not showstatbar;
               11: dos_deinstallport:=not dos_deinstallport; 12: useDTR:=not useDTR;
               13: cryptdecode:=not cryptdecode;             14: confirmhe:=not confirmhe;
               15: usealarm:=not usealarm;                   16: expandtab:=not expandtab;
               17: beep:=not beep;                           18: showpwd:=not showpwd;
            end;
      until checkch=#27;
   end;

   procedure page0_8;
   var on: char;
   begin
      on:='A';
      repeat
         with sysdata[on] do
         begin
            lo[3]:=0;
            writest(29,7,25,sysname); writest(54,7,4,' ('+on+')');
            writest(29,8,40,comment);
            writest(29,9,3,its(dlay));
            writest(29,10,40,waitfor);
            writeyn(29,11,sendhandle);
            writeyn(29,12,sendpw);
            writeyn(29,13,sendlfd);
            lastch:=waitfor[length(waitfor)];
            editflag(1,1,1,1,1,0,1);
            checkch:=scrollchoice(#27+#13,lo[1]);
            if checkch=#13 then
               case lo[1] of
                 1: if on='A' then on:='J' else on:=chr(ord(on)-1);
                 2: if on='J' then on:='A' else on:=chr(ord(on)+1);
                 3: if input(ecolr,29,lo[1]+4,sysname,25,25,lo[3])=' ' then;
                 4: if input(ecolr,29,lo[1]+4,comment,40,40,lo[3])=' ' then;
                 5: dlay:=getnum(29,lo[1]+4,3,dlay);
                 6: if input(ecolr,29,lo[1]+4,waitfor,40,40,lo[3])=' ' then;
                 7: sendhandle:=not sendhandle;
                 8: sendpw:=not sendpw;
                 9: sendlfd:=not sendlfd;
               end;
         end;
      until checkch=#27;
   end;

   procedure page0_9;
   begin
   end;

   procedure page0_10;
   var on: char;
   begin
      on:='A';
      fwrite('%P = The current active serial port',17,3,dcolr);
      fwrite('%S = The current active baudrate (speed)',18,3,dcolr);
      fwrite('%F = File name to transfer',19,3,dcolr);
      fwrite('%F = @your_drive:\your_zygote_home_dir\TEMP\BATCH.LST, when 2 or more files',20,3,dcolr);
      fwrite('i.e PROTOCOL.EXE portnum=%P speed=%S send=%F',21,3,dcolr);
      fwrite('    Zygote will convert %P,%S,%F to appropriate values',22,3,dcolr);
      repeat
         with protodata[on] do
         begin
            lo[3]:=0;
            writest(29,7,25,protoname); writest(54,7,4,' ('+on+')');
            writest(29,8,40,comment);
            writest(29,9,45,wherefile);
            writest(29,10,40,upcmd);
            writest(29,11,40,dncmd);
            writest(29,12,40,sequence);
            writeyn(29,13,askdl);
            writeyn(29,14,changedl);
            writeyn(29,15,availauto);
            editflag(1,1,1,1,1,0,1);
            checkch:=scrollchoice(#27+#13,lo[1]);
            if checkch=#13 then
               case lo[1] of
                 1: if on='A' then on:='J' else on:=chr(ord(on)-1);
                 2: if on='J' then on:='A' else on:=chr(ord(on)+1);
                 3: if input(ecolr,29,lo[1]+4,protoname,25,25,lo[3])=' ' then;
                 4: if input(ecolr,29,lo[1]+4,comment,40,40,lo[3])=' ' then;
                 5: begin
                       forcecap:=true;
                       if input(ecolr,29,lo[1]+4,wherefile,80,45,lo[3])=' ' then;
                    end;
                 6: if input(ecolr,29,lo[1]+4,upcmd,40,40,lo[3])=' ' then;
                 7: if input(ecolr,29,lo[1]+4,dncmd,40,40,lo[3])=' ' then;
                 8: if input(ecolr,29,lo[1]+4,sequence,40,40,lo[3])=' ' then;
                 9: askdl:=not askdl;
                10: changedl:=not changedl;
                11: availauto:=not availauto;
               end;
         end;
      until checkch=#27;
   end;

   procedure page0_11;
   begin
      with configdata do
      repeat
         writest(29,5,40,initstr[1]);
         writest(29,6,40,initstr[2]);
         writest(29,7,10,dialstr[1]);
         writest(29,8,10,dialstr[2]);
         writest(29,9,5,dialsuffix);
         writest(29,10,1,its(useinit));
         writest(29,11,1,its(usedial));
         writest(29,12,10,answerstr);
         writest(29,13,10,hangupstr);
         writest(29,14,2,its(diallimit));
         writest(29,15,5,its(redialpause));
         writest(29,16,10,attention);
         writest(29,17,1,leechmode);
         writeyn(29,18,usealtnum);
         writest(29,19,4,its(unmarkwhen));
         writeyn(29,20,useintense);
         writeyn(29,21,allowfax);
         writest(29,22,30,faxprogram);
         lo[3]:=0;
         editflag(1,1,1,1,1,1,1);
         checkch:=scrollchoice(#27+#13,lo[1]);
         if checkch=#13 then
            case lo[1] of
              1,2: if input(ecolr,29,lo[1]+4,initstr[lo[1]],40,40,lo[3])=' ' then;
              3,4: if input(ecolr,29,lo[1]+4,dialstr[lo[1]-2],10,10,lo[3])=' ' then;
                5: if input(ecolr,29,lo[1]+4,dialsuffix,5,5,lo[3])=' ' then;
                6: if useinit=1 then useinit:=2 else useinit:=1;
                7: if usedial=1 then usedial:=2 else usedial:=1;
                8: if input(ecolr,29,lo[1]+4,answerstr,10,10,lo[3])=' ' then;
                9: if input(ecolr,29,lo[1]+4,hangupstr,10,10,lo[3])=' ' then;
               10: diallimit:=getnum(29,lo[1]+4,2,diallimit);
               11: redialpause:=getnum(29,lo[1]+4,5,redialpause);
               12: begin
                      editflag(1,1,1,1,0,0,1);
                      if input(ecolr,29,lo[1]+4,attention,10,10,lo[3])>#0 then;
                   end;
               13: if leechmode='B' then leechmode:='S' else leechmode:='B';
               14: usealtnum:=not usealtnum;
               15: unmarkwhen:=getnum(29,lo[1]+4,4,unmarkwhen);
               16: begin
                      useintense:=not useintense;
                      if useintense then setintense else setblink;
                   end;
               17: allowfax:=not allowfax;
               18: if input(ecolr,29,lo[1]+4,faxprogram,30,30,lo[3])=' ' then;
            end;
      until checkch=#27;
   end;

   procedure page0_12;
   var on: char;
   begin
      on:='A';
      repeat
         with accountdata[on] do
         begin
            lo[3]:=0;
            writest(29,7,25,handle); writest(54,7,4,' ('+on+')');
            if configdata.showpwd then
               writest(29,8,20,password) else
                  writest(29,8,20,chars('þ',length(password)));
            writest(29,9,4,lfd);
            writest(29,10,40,comment);
            writest(29,11,8,birthdate);
            writest(29,12,25,realname);
            writest(29,13,14,homephone);
            writest(29,14,14,dataphone);
            writest(29,15,40,address);
            writest(29,16,40,city_state);
            editflag(1,1,1,1,1,0,1);
            checkch:=scrollchoice(#27+#13,lo[1]);
            if checkch=#13 then
               case lo[1] of
                  1: if on='A' then on:='E' else on:=chr(ord(on)-1);
                  2: if on='E' then on:='A' else on:=chr(ord(on)+1);
                  3: if input(ecolr,29,lo[1]+4,handle,25,25,lo[3])=' ' then;
                  4: if input(ecolr,29,lo[1]+4,password,20,20,lo[3])=' ' then;
                  5: begin
                        editflag(0,1,0,1,0,0,0);
                        if input(ecolr,29,lo[1]+4,lfd,4,4,lo[3])=' ' then;
                     end;
                  6: if input(ecolr,29,lo[1]+4,comment,40,40,lo[3])=' ' then;
                  7: if input(ecolr,29,lo[1]+4,birthdate,8,8,lo[3])=' ' then;
                  8: if input(ecolr,29,lo[1]+4,realname,25,25,lo[3])=' ' then;
                  9: if input(ecolr,29,lo[1]+4,homephone,14,14,lo[3])=' ' then;
                 10: if input(ecolr,29,lo[1]+4,dataphone,14,14,lo[3])=' ' then;
                 11: if input(ecolr,29,lo[1]+4,address,40,40,lo[3])=' ' then;
                 12: if input(ecolr,29,lo[1]+4,city_state,40,40,lo[3])=' ' then;
               end;
         end;
      until checkch=#27;
   end;

   procedure page0_13;
   var i: byte;
   begin
      with configdata do
      repeat
         lo[3]:=0;
         for i:=1 to 4 do writest(29,i+4,5,'$'+combase[i]);
         for i:=1 to 4 do
         begin
            writest(29,i+8,1,its(comirq[i]));
            writest(29,i+12,2,its(comint[i]));
         end;
         editflag(1,1,0,1,0,1,0);
         checkch:=scrollchoice(#27+#13,lo[1]);
         if checkch=#13 then
            case lo[1] of
              1..4: input(ecolr,30,lo[1]+4,combase[lo[1]],4,4,lo[3]);
              5..8: comirq[lo[1]-4]:=getnum(29,lo[1]+4,1,comirq[lo[1]-4]);
              9..12: comint[lo[1]-8]:=getnum(29,lo[1]+4,2,comint[lo[1]-8]);
            end;
      until checkch=#27;
   end;

   procedure page0_14;
   var i: byte;
   begin
      repeat
         lo[2]:=0;
         editflag(1,1,0,1,0,1,1);
         for i:=1 to 15 do writest(29,i+4,15,configdata.results[i]);
         checkch:=scrollchoice(#27+#13,lo[1]);
         if checkch=#13 then
            if input(ecolr,29,lo[1]+4,configdata.results[lo[1]],15,15,lo[2])=' ' then;
      until checkch=#27;
   end;

   procedure page0_15;
      function scramble(s: stringname): integer;
      var x,t: byte;
          total: integer;
      begin
         total:=0;
         t:=length(s);
         for x:=1 to t do total:=total+ord(s[x]);
         scramble:=total+t*1000+(t div 2);
      end;
   begin
      with configdata do
      begin
         repeat
            lo[2]:=0;
            editflag(1,1,0,1,1,1,1);
            writest(29,5,25,regname);
            writest(29,6,20,regpwd);
            writest(29,7,5,its(regnumber));
            checkch:=scrollchoice(#27+#13,lo[1]);
            if checkch=#13 then
            case lo[1] of
               1: if input(ecolr,29,lo[1]+4,regname,25,25,lo[2])=' ' then;
               2: if input(ecolr,29,lo[1]+4,regpwd,20,20,lo[2])=' ' then;
               3: regnumber:=getnum(29,lo[1]+4,5,regnumber);
            end;
         until checkch=#27;
         registered:= (regnumber=scramble(regname)) and (cmsg(regpwd)=zpassword)
                      and (regnumber>0);
         if not registered then showmsg('MUST REGISTER','incorrect information');
      end;
   end;

   procedure page0_16;
   var i: byte;
   begin
      repeat
         lo[2]:=0;
         editflag(1,1,0,1,0,0,1);
         for i:=1 to 11 do writest(29,i+4,15,'AT'+configdata.modemstring[i]+'^M');
         checkch:=scrollchoice(#27+#13,lo[1]);
         if checkch=#13 then
            if input(ecolr,31,lo[1]+4,configdata.modemstring[lo[1]],10,10,lo[2])=' ' then;
      until checkch=#27;
   end;

begin
   new(fielddesc);
   if readdesc(cmname,'@0') then
   begin
      dcolr:=attr(lightgray,black);
      ncolr:=attr(lightcyan,black);
      ecolr:=hattr(white,blue);
      page.flag:=1;
      page.x:=10;
      page.y:=25;
      page.colr:=attr(white,black);
      timestat.flag:=1;
      timestat.x:=69;
      timestat.y:=2;
      timestat.colr:=attr(white,black);
      wx:=wherex; wy:=wherey;
      window(1,1,80,25);
      savevideo(videoback,true);
      mainmenu;
      writedescfield;
      lo[0]:=1;
      repeat
         givestatus;
         if scrollchoice(#13+#27,lo[0])=#13 then
         begin
            if readdesc(cmname,'@0-'+its(lo[0])) then
            begin
               new(video1);
               savevideo(video1^,true);
               win(1,4,80,23);
               writedescfield;
               lo[1]:=1;
               saveflag[lo[0]]:=true;
               case lo[0] of
                  1: page0_1;
                  2: page0_2and3('T');
                  3: page0_2and3('R');
                  4: page0_4;
                  5: page0_5;
                  6: page0_6;
                  7: page0_7;
                  8: page0_8;
                  9: page0_9;
                 10: page0_10;
                 11: page0_11;
                 12: page0_12;
                 13: page0_13;
                 14: page0_14;
                 15: page0_15;
                 16: page0_16;
               end;
               if readdesc(cmname,'@0') then fixdesc;
               savevideo(video1^,false);
               dispose(video1);
            end;
         end else lo[0]:=17;
      until lo[0] in [17];
      savevideo(videoback,false);
      gotoxy(wx,wy);
      page.flag:=0;
      timestat.flag:=0;
      cursor(true);
   end;
   dispose(fielddesc);
end;

procedure arghelp;
var c: byte;
begin
   color(15,0);
   clrscr;
   makebox(attr(cyan,black),1,1,80,11,3);
   fwritena('Â',1,18); fwritena('Á',11,18);
   vertchars(attr(cyan,black),18,2,10,'³');
   vertchars(attr(lightcyan,black),2,3,9,'/');
   fwritena('´                  Ã',1,60);
   fwrite(' Valid parameters ',1,61,attr(white,blue));
   fwritena('C',3,3); fwritena('F name',4,3); fwritena('H',5,3);
   fwritena('L filename.ext',6,3); fwritena('N',7,3);
   fwritena('R filename.ext',8,3); fwritena('S',9,3);
   c:=attr(lightgray,black);
   fwrite('(C)onfigurate Zygote prior to execution',3,20,c);
   fwrite('Load Zygote (F)unction "name"',4,20,c);
   fwrite('This (H)elp',5,20,c);
   fwrite('(L)oad script file "filename.ext"',6,20,c);
   fwrite('(N)o initial opening screen',7,20,c);
   fwrite('(R)ead binary file "filename.ext"',8,20,c);
   fwrite('Use (S)now checking',9,20,c);
   fwrite('*',25,1,attr(lightred,black));
   fwrite('parameter ''/N'' is only valid in registered versions',25,3,attr(white,black));
   cursor(false);
   waitkey;
   cursor(true);
end;

procedure initparams;
   function hex(s: string): word;
   var total,temp: word;
       len,x: byte;
   begin
      total:=$0000;
      len:=length(s);
      x:=len;
      if len=0 then hex:=total else
      begin
         repeat
             case s[x] of
                'A'..'F': temp:=ord(s[x])-55;
                '0'..'9': temp:=ord(s[x])-48;
                else temp:=$0000;
             end;
             temp:=temp shl (abs(x-len)*4);
             total:=temp + total;
             dec(x);
         until x=0;
         hex:=total;
      end;
   end;
begin
   with configdata do
   begin
      uart_base:=hex(combase[comport]);
      intnums:=comint[comport];
      I8259Levels:=comirq[comport];
      _do_RTSCTS:=ctsrts;
      _do_XONXOFF:=xonxoff;
      _do_fifo:=dofifo;
      Rx_queue_size:=recvsize;
      Tx_queue_size:=xmitsize;
      lastdata.scl_filesize:=scrollbacksize;
      waitforretrace:=vretrace;
   end;
end;

procedure openingscreen;
var i,j: byte;
   procedure w(colr,x,y: byte; s: string);
   var i: byte;
   begin
      for i:=1 to length(s) do
         if s[i]<>' ' then fwrite(s[i],y,x+i-1,colr);
   end;
begin
   cursor(false);
   for i:=1 to 6 do makebox(0,1,2*i-1,80,2*i,1);
   makebox(1,1,14,80,16,1);
   makebox(1,1,17,80,22,1);
   makebox(1,1,23,80,25,1);
   fwrite(cmsg('‰´¾ú¼®¸º  º½¿ð ¨í¸®¦¬«¨«¨±­«¢¡Ë×ÒÒÈ'),15,23,attr(yellow,black));
   fwrite(cmsg('¾»£Í˜Ž‰†ˆŠŠƒŠ‡’'),18,33,attr(lightblue,black));
   fwrite(cmsg('ÅÌÂÊª‡—Ÿ—„Š•Àîçååö')+'96 '+cmsg('¯˜À‘¹¨¥¾´õø–º¹ô¡»¶¸»½í¾®¹¬º±£¡'),19,15,attr(lightcyan,black));
   fwrite('C',19,16,attr(lightgray,black));
   fwrite(cmsg('®€›“”Œ†––„„ÿ­´²¸¿ùéîîì'),20,30,attr(cyan,black));

   {unregistered}
   fwrite(cmsg('£µ¨§¾¸®¸¬¬Ç¥ª´º'),24,3,attr(white,black));
   {fwrite(cmsg('º ¿©¬£º¼¢´  Ã¡®°†'),24,3,attr(white,black));}

   fwrite(cmsg('¬†€‹†„„ÿ¼¤ü–£ù–°£¬±½'),24,56,attr(cyan,black));
   fwritena('Â',23,54); fwritena('³',24,54); fwritena('Á',25,54);
   i:=attr(red,black); j:=attr(lightred,black);
   fwrite(cmsg('Ô¯·Ð'),4,76,attr(white,black));
   fwrite(cmsg('®’„†œœÑ')+cmsg(zversion),3,35,attr(white,black));
   w(i,3,3,'                                                      ÛÛÛÛÛ                 ');
   w(i,3,4,'                                                      ÛÛÛÛ                  ');
   w(i,3,5,'ÛÛÛÛÛÛÛÛÛÛÛÛÛ ÛÛÛÛÛ  ÛÛÛÛÛÛ ÜÛÛÛÛÜÛÛÛÛÛ ÜÛÛÛÛÛÛÛÛÛÜ ÛÛÛÛÛÛÛÛÛÛÛ   ÜÛÛÛÛÛÛÛÜ ');
   w(i,3,6,'ÛÛ      ÛÛÛÛÛ  ÛÛÛÛ   ÛÛÛÛ ÛÛÛÛ   ÛÛÛÛ ÛÛÛÛÛ   ÛÛÛÛÛ  ÛÛÛÛ       ÛÛÛÛ   ÛÛÛÛ');
   w(j,3,7,'      ÛÛÛÛÛ    ÛÛÛÛ   ÛÛÛÛ ÛÛÛÛ   ÛÛÛÛ ÛÛÛÛÛ   ÛÛÛÛÛ  ÛÛÛÛ       ÛÛÛÛ   ÛÛÛÛ');
   w(j,3,8,'    ÛÛÛÛÛ      ÛÛÛÛ   ÛÛÛÛ ÛÛÛÛ   ÛÛÛÛ ÛÛÛÛÛ   ÛÛÛÛÛ  ÛÛÛÛ       ÛÛÛÛÜÜÜÛÛÛß');
   w(j,3,9,'  ÛÛÛÛÛ        ÛÛÛÛ   ÛÛÛÛ ÛÛÛÛ   ÛÛÛÛ ÛÛÛÛÛ   ÛÛÛÛÛ  ÛÛÛÛ       ÛÛÛÛ       ');
   w(i,3,10,'ÛÛÛÛÛÛ     ÛÛ   ßÛÛÜÜÜÛÛÛÛ  ßÛÛÜÜÜÛÛÛÛ ÛÛÛÛÛ   ÛÛÛÛÛ  ÛÛÛÛ   ÛÛÛ ÛÛÛÛ   ÛÛÛÛ');
   w(i,3,11,'ÛÛÛÛÛÛÛÛÛÛÛÛÛ         ÛÛÛÛ        ÛÛÛÛ  ßÛÛÛÛÛÛÛÛÛß    ßÛÛÛÛÛÛß   ßÛÛÛÛÛÛÛß ');
   w(i,3,12,'                ÛÛÛ   ÛÛÛÛ  ÛÛÛ   ÛÛÛÛ                                      ');
   w(i,3,13,'                 ßÛÛÛÛÛÛß    ßÛÛÛÛÛÛß                                       ');
   waitkey;
   clrscr;
   cursor(true);
end;

procedure loadZYG;
var year,month,day,dayofweek: word;
begin
   antioff:=false;
   connected:=false; colorvideo:=checkvideo;   capture:=false;
   bbson:=1;         lastfg:=7;                lastbg:=0;
   script:=false;    autolog:=false;           quitzygote:=false;
   keylocked:=false; waitforretrace:=false;    useprinter:=false;
   if configdata.useintense then setintense else setblink;
   if colorvideo then baseofscreen:=$b800 else baseofscreen:=$b000;
   checksnow:=checkarg('/S')>0;
   loadconfig:=(checkarg('/C')>0) or (loadconfig);
   if checkarg('/H')>0 then arghelp;
   color(lastfg,lastbg);
   clrscr;
   if LoadConfig then configzyg;
   wx:=checkarg('/R');
   if wx>0 then readbinfile(paramstr(wx+1),true) else
   if (checkarg('/N')=0) then openingscreen else
   begin
      if (not configdata.registered) then openingscreen;
   end;
   initparams;
   with configdata do
   begin
      dparam:=param;
      with param do
      begin
         _install(comport);
         _set_param(speed,parity,dbit,sbit);
         if not com_installed then showmsg('COM'+its(comport)+' is not responding','Try a different port');
      end;
      getdate(year,month,day,dayofweek);
      inc(lastdata.timesused[dayofweek]);
      with lastdata do
         timesused[7]:=timesused[0]+timesused[1]+timesused[2]+
                       timesused[3]+timesused[4]+timesused[5]+
                       timesused[6];
      initscr;
      dparam:=param;
      if (not _CD) or (init_online) then
      begin
         _flush_rx;
         xy(1,14,'Jaþk Initialization string Jþ');
         for day:=1 to 10 do changeattr(1,14,day*2+2,attr(green,black));
         send(initstr[useinit]);
      end;
      if showstatbar then activescreensize:=24 else activescreensize:=25;
   end;
   gotoxy(1,15);
   statusbar;
end;

procedure runconfigzyg;
var lshowstatbar: boolean;
begin
    lshowstatbar:=configdata.showstatbar;
    configzyg;
    if configdata.showstatbar then activescreensize:=24 else activescreensize:=25;
    if (lshowstatbar) and (not configdata.showstatbar) then fwrite(blanks(80),25,1,0);
    _deinstall;
    initparams;
    _install(configdata.comport);
    if not com_installed then showmsg('COM'+its(configdata.comport)+' is not responding','Try a different port');
    statusbar;
end;

end.
