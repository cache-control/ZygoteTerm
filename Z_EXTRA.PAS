unit z_extra;

interface
{$F+,O+}

var tsbuffer: string[20];

procedure worldtime;
procedure chatmode;
procedure keylock;
procedure asciisend(name: string);
procedure calculator;
procedure exitwindow;
procedure toggleantioff;
procedure regmsg;
procedure sendmodemstring;
procedure ringmonitor;
procedure bigclock;
procedure textsearch;
procedure helpscreen;
procedure changedndir;

implementation

uses crt,dos,z_util,z_comio,z_mouse;

procedure worldtime;
const numcities = 18;
      wtname = 'ZYGOTE.WTD';   (* world time data *)
type zonedifftype = record
         timediff,timex,timey,timecolor,use_ds: byte;
         name: string[20];
         namex,namey,namecolor: byte;
     end;
     zonediffarray = array[1..numcities] of zonedifftype;
var i,c: integer;
    cities: ^zonediffarray;
    cfile: text;
    temp: string[10];

function newtime(diff: integer): string;
var hr,min,sec,temp: word;
    h,m,s,t: string[2];
begin
   gettime(hr,min,sec,temp);
   if hr=0 then hr:=24;
   hr:=hr+diff;
   for temp:=1 to 2 do if hr>24 then dec(hr,24);
   if hr>12 then
   begin
      t:='pm';
      dec(hr,12);
   end else t:='am';
   h:=its(hr); m:=its(min); s:=its(sec);
   newtime:=chars('0',2-length(h))+h+':'+chars('0',2-length(m))+m+'.'+chars('0',2-length(s))+s+t;
end;

begin
   I:=-1;
   new(cities);
   if exist(wtname) then
   begin
      {$I-}
      assign(cfile,wtname);
      reset(cfile);
      for i:=1 to numcities do
      begin
         with cities^[i] do
            readln(cfile,name,namex,namey,namecolor,timediff,timex,timey,timecolor,use_ds);
         if not colorvideo then
         begin
            cities^[i].namecolor:=112;
            cities^[i].timecolor:=7;
         end;
      end;
      close(cfile);
      i:=ioresult
      {$I+}
   end;
   if I=0 then
   begin
      i:=6;
      c:=attr(cyan,blue);
      cursor(false);
      wx:=wherex; wy:=wherey;
      savevideo(videoback,true);
      fwrite('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿',5,5,c);
      repeat
         fwrite('³                      ³            ³                      ³            ³',i,5,c);
         fwrite('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄ´',i+1,5,c);
         inc(i,2);
      until i>22;
      fwrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÙ',23,5,c);
      makebox(attr(12,0),1,1,22,3,1);
      fwrite('World Time display',2,3,attr(11,0));
      for i:=1 to numcities do
          with cities^[i] do fwrite(name,namey,namex,namecolor);
      repeat
          if temp<>newtime(0) then
          begin
             temp:=newtime(0); fwrite(' '+temp+' ',1,6,attr(15,0));
             for i:=1 to numcities do
                 with cities^[i] do
                 begin
                    if configdata.dlsaving then
                       fwrite(newtime(configdata.pstdiff+timediff+use_ds),timey,timex,timecolor) else
                         fwrite(newtime(configdata.pstdiff+timediff),timey,timex,timecolor);
                 end;
          end;
      until keypressed;
      waitkey;
      gotoxy(wx,wy);
      savevideo(videoback,false);
      cursor(true);
   end;
   dispose(cities);
end;

procedure chatmode;
const cborder = lightcyan; {attr(lightcyan,black)}
      ctime = yellow;      {attr(yellow,black)}
      ctext = white;       {attr(white,black)}
      cdesc = lightred;    {attr(lightred,black)}

var tbuffer,bbuffer: string[80];
    remotech,localch,ch: char;
    lasttime: string[12];
    tx,ty,bx,by,lastspace: byte;

    procedure updatetime;
    begin
       if lasttime<>time(1) then
       begin
          lasttime:=time(1);
          fwrite(lasttime,12,36,ctime);
       end;
    end;

begin
   localch:=#0;
   tbuffer:='';
   bbuffer:='';
   tx:=1; ty:=1;
   bx:=1; by:=1;
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   makebox(ctext,1,1,80,25,5);
   fwrite('ÖÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄ´           ÃÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ·',12,1,cborder);
   fwrite('º                       ³                               ³                      º',13,1,cborder);
   fwrite('ÓÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄ´           ÃÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ½',14,1,cborder);
   fwrite('°  Local  °°°°°°°°°°°°',13,2,ctext);         fwrite('°°°°°°°°°°°  Remote °',13,58,ctext);
   fwrite('Zygote Telecommunication v'+cmsg(zversion),13,27,cdesc);  fwrite('Chat mode',14,37,ctime);
   repeat
       updatetime;
       if _rx_ready then
       begin
          color(lightblue,black);
          window(1,1,80,11);
          gotoxy(bx,by);
          while _rx_ready do
          begin
             remotech:=chr(_get);
             case remotech of
                #0 : ;
                #8 : begin
                        delete(bbuffer,length(bbuffer),1);
                        write(^h,' ',^h);
                     end;
                #10,
                #13: begin
                        writeln;
                        bbuffer:='';
                     end;
                else begin
                        bbuffer:=bbuffer+remotech;
                        if length(bbuffer)=80 then
                        begin
                           lastspace:=80;
                           while (bbuffer[lastspace]<>' ') and (lastspace>1) do dec(lastspace);
                           bbuffer:=copy(bbuffer,lastspace+1,80-lastspace);
                           gotoxy(lastspace,wherey);
                           clreol;
                           writeln;
                           write(bbuffer);
                        end else write(remotech);
                     end;
             end;
          end;
          bx:=wherex; by:=wherey;
          window(1,15,80,25);
          gotoxy(tx,ty);
       end else
       if keypressed then
       begin
          window(1,15,80,25);
          gotoxy(tx,ty);
          color(lightgreen,black);
          while keypressed do
          begin
             localch:=readkb;
             case localch of
                #0 : begin
                        ch:=readkb;
                        grabline(ch);
                        screendump(ch);
                     end;
                #8 : begin
                        _put(8);
                        delete(tbuffer,length(tbuffer),1);
                        write(^h,' ',^h);
                     end;
                #10,
                #13: begin
                        _put(13);
                        writeln;
                        tbuffer:='';
                     end;
                else begin
                        tbuffer:=tbuffer+localch;
                        if length(tbuffer)=80 then
                        begin
                           lastspace:=80;
                           while (tbuffer[lastspace]<>' ') and (lastspace>1) do dec(lastspace);
                           tbuffer:=copy(tbuffer,lastspace+1,80-lastspace);
                           gotoxy(lastspace,wherey);
                           clreol;
                           writeln;
                           write(tbuffer);
                        end else write(localch);
                        _put(ord(localch));
                     end;
             end;
          end;
          tx:=wherex; ty:=wherey;
       end;
   until localch = #27;
   savevideo(videoback,false);
   window(1,1,80,activescreensize);
   gotoxy(wx,wy);
   statusbar;
end;

procedure keylock;
var x,y: byte;
    temp: stringpw;
    lo: byte;

begin
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   x:=23; y:=13; lo:=0;
   makebox(attr(lightblue,black),x,y,x+39,y+2,1);
   changeattr(40,y+3,x+2,8);
   changeattr(2,y+2,x+40,8);
   changeattr(2,y+1,x+40,8);
   editflag(1,1,0,1,0,1,0);
   if keylocked then
   begin
      temp:='';
      keylocked:=false;
      if keypressed then if readkey=#0 then if readkey=#0 then;
      fwrite('Keyboard lock :',y+1,x+2,attr(lightcyan,black));
      if input(attr(cyan,black),x+18,y+1,temp,20,20,lo)=#13 then;
      keylocked:=not (keylockpw=temp);
   end else
   begin
      keylockpw:=configdata.defaultkeypw;
      fwrite('New password  :',y+1,x+2,attr(lightcyan,black));
      if input(attr(cyan,black),x+18,y+1,keylockpw,20,20,lo)=#13 then
         keylocked:= keylockpw>'';
   end;
   savevideo(videoback,false);
   gotoxy(wx,wy);
   statusbar;
end;

procedure asciisend(name: string);
var on,colr,lp,cp,crlf: byte;
    usetrans,striphbit: boolean;
    size: word;
    tfile: text;
    line: string;
    out: boolean;
    ch: char;

   function getnum(x,y,size,num: byte): byte;
   var s: string[3];
       c,i: integer;
       o: byte;
   begin
      s:=its(num);
      o:=length(s)+1;
      editflag(0,0,0,1,0,0,0);
      if input(colr,x,y,s,size,size,o)<>' ' then cursor(false);
      val(s,i,c);
      if c=0 then getnum:=i else getnum:=num;
   end;

   procedure init;
   begin
      on:=1;
      lp:=0;
      cp:=0;
      crlf:=1;
      size:=0;
      out:=false;
      usetrans:=false;
      striphbit:=false;
      cursor(false);
      color(7,0);
      clrscr;
   end;

   procedure showdata;
   begin
      fwrite('Start xfer',2,28,colr);
      fwrite(its(lp)+blanks(3-length(its(lp))),3,28,colr);
      fwrite(its(cp)+blanks(3-length(its(cp))),4,28,colr);
      if usetrans then fwrite('Yes',5,28,colr) else fwrite('No ',5,28,colr);
      case crlf of
         1: fwrite('Add LF after CR',6,28,colr);
         2: fwrite('Add CR after LF',6,28,colr);
         3: fwrite('Add CR only    ',6,28,colr);
         4: fwrite('Add LF only    ',6,28,colr);
      end;
      if striphbit then fwrite('Yes',7,28,colr) else fwrite('No ',7,28,colr);
      fwrite('0',8,28,colr);
   end;
begin
   if exist(name) then
   begin
      cursor(false);
      init;
      colr:=attr(lightblue,black);
      makebox(colr,1,1,80,9,1);
      fwritena('Á',9,26);
      vertchars(colr,26,2,8,'³');
      fwrite('['+blanks(74)+']',1,3,colr);
      colr:=attr(lightgray,black);
      fwrite('Send',2,3,colr);
      fwrite('Line pacing (1/10 sec)',3,3,colr);
      fwrite('Char pacing (1/10 sec)',4,3,colr);
      fwrite('Use translation',5,3,colr);
      fwrite('CR/LF',6,3,colr);
      fwrite('Strip high bit',7,3,colr);
      fwrite('Byte #',8,3,colr);
      colr:=attr(lightcyan,black);
      fwrite(caps(copy(name,1,74)),1,4,attr(white,black));
      showdata;
      page.flag:=0;
      timestat.flag:=0;
      sc.x:=2; sc.y:=2;
      sc.s:=24;
      sc.t:=7;
      sc.c:=hattr(white,blue);
      sc.nc:=attr(lightgray,black);
      repeat
          showdata;
          ch:=scrollchoice(#13+#27,on);
          if ch=#13 then
          begin
             case on of
               2: lp:=getnum(28,3,3,lp);
               3: cp:=getnum(28,4,3,cp);
               4: usetrans:=not usetrans;
               5: inc(crlf);
               6: striphbit:=not striphbit;
             end;
             if crlf>4 then crlf:=1;
          end;
      until (ch=#27) or ((on=1) and (ch=#13));
      if (ch<>#27) and (exist(name)) then
      begin
         window(1,10,80,25);
         assign(tfile,name);
         reset(tfile);
         while (not eof(tfile)) and (not out) do
         begin
            if keypressed then out:=readkb=^[;
            readln(tfile,line);
            for on:=1 to length(line) do
            begin
               inc(size);
               ch:=line[on];
               if striphbit then ch:=chr(ord(ch)+128);
               if usetrans then ch:=chr(tabledata.tx[ch]);
               _put(ord(ch));
               color(7,0);
               if _rx_ready then
               begin
                  ch:=chr(_get);
                  if usetrans then write(tabledata.rx[ord(ch)]) else write(ch);
               end;
               fwrite(its(size),8,28,colr);
               delay(cp*10);
            end;
            case crlf of
               1: _putstring(#13+#10);
               2: _putstring(#10+#13);
               3: if usetrans then _put(tabledata.tx[#13]) else _put(13);
               4: if usetrans then _put(tabledata.tx[#10]) else _put(10);
            end;
            delay(lp*10);
         end;
         close(tfile);
      end;
      if keypressed then waitkey;
      window(1,1,80,activescreensize);
   end;
end;

procedure calculator;
const size = 26;
type str3 = string[3];
     strsize = string[size];
var lastnumlock,period: boolean;
    str1,str2 : strsize;
    ch,mathfunc: char;
    answer,temp: real;
    code: integer;

   procedure button(st: str3; x,y: byte; out: boolean);
   var color1,color2: byte;
   begin
      if out then
      begin
         color1:=attr(8,7);
         color2:=attr(white,7);
      end else
      begin
         color1:=attr(white,7);
         color2:=attr(8,7);
      end;
      makebox(color1,x,y,x+4,y+2,1);
      changeattr(4,y,x,color2);
      changeattr(1,y+1,x,color2);
      changeattr(1,y+2,x,color2);
      if out then fwrite(st,y+1,x+1,attr(black,7));
   end;
   procedure zero(x,y: byte; out: boolean);
   var color1,color2: byte;
   begin
      if out then
      begin
         color1:=attr(8,7);
         color2:=attr(white,7);
      end else
      begin
         color1:=attr(white,7);
         color2:=attr(8,7);
      end;
      makebox(color1,x,y,x+11,y+2,1);
      changeattr(11,y,x,color2);
      changeattr(1,y+1,x,color2);
      changeattr(1,y+2,x,color2);
      if out then fwrite('0',y+1,x+2,attr(black,7));
   end;
   procedure plus(x,y: byte; out: boolean);
   var color1,color2: byte;
   begin
      if out then
      begin
         color1:=attr(8,7);
         color2:=attr(white,7);
      end else
      begin
         color1:=attr(white,7);
         color2:=attr(8,7);
      end;
      makebox(color1,x,y,x+4,y+4,1);
      changeattr(4,y,x,color2);
      for color1:=1 to 4 do changeattr(1,y+color1,x,color2);
      if out then fwrite('+',y+2,x+2,attr(black,7));
   end;
   procedure enter(x,y: byte; out: boolean);
   var color1,color2: byte;
   begin
      if out then
      begin
         color1:=attr(8,7);
         color2:=attr(white,7);
      end else
      begin
         color1:=attr(white,7);
         color2:=attr(8,7);
      end;
      makebox(color1,x,y,x+4,y+6,1);
      changeattr(4,y,x,color2);
      for color1:=1 to 6 do changeattr(1,y+color1,x,color2);
      if out then
      begin
         fwrite('E',y+1,x+2,attr(black,7));
         fwrite('n',y+2,x+2,attr(black,7));
         fwrite('t',y+3,x+2,attr(black,7));
         fwrite('e',y+4,x+2,attr(black,7));
         fwrite('r',y+5,x+2,attr(black,7));
      end;
   end;
   procedure drawbutton(whichone: char; out: boolean);
   begin
      case whichone of
         '0': zero(49,19,out);
         '1': button(' 1 ',49,16,out);
         '2': button(' 2 ',56,16,out);
         '3': button(' 3 ',63,16,out);
         '4': button(' 4 ',49,13,out);
         '5': button(' 5 ',56,13,out);
         '6': button(' 6 ',63,13,out);
         '7': button(' 7 ',49,10,out);
         '8': button(' 8 ',56,10,out);
         '9': button(' 9 ',63,10,out);
         'N': button('Num',49,07,out);
         '/': button(' / ',56,07,out);
         '*': button(' * ',63,07,out);
         '-': button(' - ',70,07,out);
         '+': plus(70,10,out);
         #13: enter(70,15,out);
         '.': button(' . ',63,19,out);
      end;
   end;
   procedure drawcalc;
   var num: char;
   begin
      makebox(attr(black,7),47,1,76,22,1);
      fwrite(' '+chars('Ü',26)+' ',2,48,attr(white,blue));
      fwrite(blanks(28),3,48,attr(white,blue));
      fwrite(blanks(26),3,49,attr(white,7));
      fwrite(blanks(28),4,48,attr(white,blue));
      fwrite(chars('Ä',26),4,49,attr(white,7));
      fwrite(blanks(28),5,48,attr(white,blue));
      fwrite(blanks(26),5,49,attr(white,7));
      fwrite(' '+chars('ß',26)+' ',6,48,attr(8,blue));
      fwrite(chars('Ü',80),23,1,attr(lightcyan,0));
      fwrite('³                              ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´                               ³',24,1,attr(white,cyan));
      fwrite('Simple 4-Function calculator',24,3,attr(black,cyan));
      fwrite('Hit ''C'' to clear, Esc to Exit',24,50,attr(black,cyan));
      fwrite(chars('ß',80),25,1,attr(8,black));
      lastnumlock:=keystatus($20);
      for num:='*' to '9' do drawbutton(num,true);
      drawbutton(#13,true);
      drawbutton('N',not keystatus($20));
   end;
   function getkey: char;
   var c: char;
   begin
      c:=#0;
      repeat
          if lastnumlock<>keystatus($20) then
          begin
             lastnumlock:=keystatus($20);
             drawbutton('N',not lastnumlock);
          end;
          if keypressed then
          begin
             c:=upcase(readkb);
             if c=#0 then
             begin
                c:=readkb;
                grabline(c);
                screendump(c);
             end;
          end;
      until c in ['0'..'9','/','*','-','+','.',#13,#27,#8,'C'];
      getkey:=c;
      if not (c in [#27,#8,'C']) then
      begin
         drawbutton(c,false);
         delay(100);
         drawbutton(c,true);
      end;
   end;
begin
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   str1:='';
   str2:='0.0';
   drawcalc;
   period:=false;
   mathfunc:=#0;
   answer:=0.0;
   gotoxy(74,5);
   repeat
      fwrite(blanks(size-length(str1))+str1,5,49,attr(red,7));
      fwrite(blanks(size-length(str2))+str2,3,49,attr(blue,7));
      ch:=getkey;
      case upcase(ch) of
        '0'..
        '9': if length(str1)<=size then str1:=str1+ch;
        '.': if (length(str1)<=size) and (not period) then
             begin
                str1:=str1+'.';
                period:=true;
             end;
        '/',
        '*',
        '-',
        '+': if mathfunc=#0 then
             begin
                mathfunc:=ch;
                str2:=str1;
                val(str2,answer,code);
                if (code<>0) or (str2='') then
                begin
                   str2:='0.0';
                   answer:=0.0;
                   mathfunc:=#0;
                end;
                str1:='';
                period:=false;
             end else
             begin
                val(str1,temp,code);
                if code<>0 then temp:=0.0;
                case mathfunc of
                  '-': answer:=answer-temp;
                  '+': answer:=answer+temp;
                  '/': if temp<>0.0 then answer:=answer / temp;
                  '*': answer:=answer*temp;
                end;
                str1:='';
                period:=false;
                str(answer:size:4,str2);
                mathfunc:=ch;
             end;
        'C': begin
                str1:='';
                str2:='0.0';
                answer:=0.0;
                mathfunc:=#0;
                period:=false;
             end;
         #8: begin
                if str1[length(str1)]='.' then period:=false;
                delete(str1,length(str1),1);
             end;
        #13: begin
                val(str1,temp,code);
                if code<>0 then temp:=0.0;
                case mathfunc of
                  '-': answer:=answer-temp;
                  '+': answer:=answer+temp;
                  '/': if temp<>0.0 then answer:=answer / temp;
                  '*': answer:=answer*temp;
                end;
                period:=false;
                str1:='';
                str(answer:size:4,str2);
                mathfunc:=ch;
             end;
      end;
   until ch=#27;
   savevideo(videoback,false);
   gotoxy(wx,wy);
end;

procedure exitwindow;
var on: byte;
begin
   cursor(false);
   savevideo(videoback,true);
   makebox(attr(white,cyan),3,18,31,22,1);
   changeattr(29,23,5,8);
   for on:=19 to 22 do changeattr(2,on,32,8);
   sc.x:=4; sc.y:=19; sc.s:=27; sc.t:=3; page.flag:=0;
   sc.nc:=attr(black,cyan);
   sc.c:=hattr(white,blue);
   fwritena('´             Ã',18,5);
   fwrite('EXIT Zygote',18,7,attr(yellow,cyan));
   fwrite(' Drop carrier then exit    ',19,4,sc.nc);
   fwrite(' Just exit                 ',20,4,sc.nc);
   fwrite(' Abort                     ',21,4,sc.nc);
   on:=2;
   if not configdata.confirmhe then
   begin
      changeattr(sc.s,sc.y+on-1,sc.x,sc.c);
      delay(200);
   end else if scrollchoice(#13+#27,on)=#27 then on:=3;
   quitzygote:= on<3;
   if on=1 then
   begin
      if configdata.usedtr then
      begin
         _dtr(false);
         delay(configdata.dtrdelay);
         _dtr(true);
      end else send(configdata.hangupstr);
   end;
   savevideo(videoback,false);
   statusbar;
   cursor(true);
end;

procedure toggleantioff;
begin
   antioff:=not antioff;
   if antioff then showmsg('Anti-Logoff is now','ON') else
      showmsg('Anti-Logoff is now','OFF');
   statusbar;
end;

procedure regmsg;
var i: byte;
begin
   cursor(false);
   savevideo(videoback,true);
   makebox(attr(cyan,black),11,7,68,19,1);
   fwrite(chars('Ä',52),9,14,attr(lightblue,black));
   i:=attr(lightgray,black);
   fwrite(cmsg('¾¤»­ ¯¶°¦°¤¤ÿ„„›”œø')+cmsg(zversion),8,14,attr(white,black));
   fwrite(cmsg('…¸¦½í¥¸ê¨¦ç³«¶¦¥¨³ËÛÏÙßšÏİÅÅÜÛİ’ŞÖôÔËÄŞÌ†‡õÊÉÆ'),10,14,i);
   fwrite(cmsg('©»£¯¿£¦¦´æ­¥µ§á¢ÚÛÓœßÓÊÙÕÚĞĞŸ’ŞÄÇËßß‹ËÛÍ‡Ö×ÁÀÇÅÅû'),11,14,i);
   fwrite(cmsg('®²ê½ ®µå³¢°¯©ÑÙÑŞÉÊÙĞÓ›”çÚÔÉÛÁÀ‹ØÌÏÎÕÑÁÑÇÅ€éûïïòõ÷'),12,14,i);
   fwrite(cmsg('¦½í¯§¯¨¦ç©£ä¢®­àÈßÏÒÒÔŞ˜ÄÕÇÑÖÜÂœÏÃÈ‹ËÅÄ‡ÀÀÅ××ÓÅì'),13,14,i);
   fwrite(cmsg('°¢ªî¨¢ª¨¥­£èå—¦¬¥àÖĞÅÔÏË˜ÅÓÒİÀÆÃÑÛÇÂÂ‹ÌÆÚÊ†ÑË'),14,14,i);
   fwrite(cmsg('†´­²°½µïº¢öë‡°è‰¡°½¦¬áàŸòï÷™ìÒÕİÚÜŞŞ×ÆËŞ'),16,14,i);
   fwrite(cmsg('²³ïô÷àäşÿşíìëêéèçæåäãâáàŸ‡ŒŒ›ûÊĞÛ×ÛĞ“‘…'),17,14,i);
   fwrite(cmsg('šª¦ ¬ç²¬¨¯øáŠÊĞØœŠƒ€—–•”“áØİÆûÍÇÆÌÑ‹†æåƒ›’©«°¯ª©ª'),18,14,i);
   i:=attr(yellow,black);
   changeattr(9,16,26,attr(white,black));
   changeattr(11,16,14,i); changeattr(4,17,14,i); changeattr(11,18,14,i);
   changeattr(16,16,40,attr(lightcyan,black));
   changeattr(14,17,40,attr(cyan,black));
   changeattr(26,18,40,attr(cyan,black));
   waitkey;
   cursor(true);
   savevideo(videoback,false);
end;

procedure sendmodemstring;
var c,on: byte;
    ch: char;
begin
   if readdesc('ZYGOTE.CMD','@0-16') then
   begin
      savevideo(videoback,true);
      cursor(false);
      on:=1;
      page.flag:=0;
      timestat.flag:=0;
      sc.x:=64; sc.y:=2;
      sc.s:=16;
      sc.t:=11;
      sc.c:=hattr(white,blue);
      sc.nc:=attr(lightgray,black);
      makebox(attr(cyan,black),63,1,80,13,1);
      writedescfield;
      ch:=scrollchoice(#13+#27,on);
      if ch=#13 then send('AT'+configdata.modemstring[on]+#13);
      savevideo(videoback,false);
      cursor(true);
   end;
end;

procedure ringmonitor;
const sizeofarray = 20;
type ringtype=record
         flag: boolean;
         sequence: string[3];
         action: string[30];
     end;
     ringarraytype=array[1..9] of ringtype;
var quit: boolean;
    vback: videotype;
    ringfile: file of ringarraytype;
    ringdata: ringarraytype;
    ringarray: array[1..sizeofarray] of string[25];
    ClockTick: word absolute $40:$6C;
    etime,ringcount,index,diff,temp,t1,lastclock: word;
    lx,ly: byte;
    ch: char;
    s,stemp: string[25];

procedure showagenda;
var i: byte;
begin
   for i:=1 to 9 do
   with ringdata[i] do
   begin
      fwrite(its(i),15+i,3,attr(lightgray,black));
      if flag then fwrite('!',15+i,6,attr(yellow,black)) else fwrite(' ',15+i,6,attr(yellow,black));
      fwrite(chr(i+64),15+i,7,attr(lightred,black));
      fwrite(sequence+chars(' ',3-length(sequence)),15+i,13,attr(white,blue));
      fwrite(action+chars(' ',30-length(action)),15+i,21,attr(white,blue));
   end;
end;

procedure editagenda(whichone: byte);
var c,lo: byte;
begin
   lo:=0;
   lx:=wherex; ly:=wherey;
   window(1,1,80,25);
   c:=attr(white,blue);
   editflag(0,0,0,1,0,0,0);
   if input(c,13,15+whichone,ringdata[whichone].sequence,3,3,lo)=#0 then;
   lo:=0;
   editflag(1,1,0,1,0,0,1);
   if input(c,21,15+whichone,ringdata[whichone].action,30,30,lo)=#0 then;
   window(2,2,50,11);
   gotoxy(lx,ly);
end;

procedure open_rng(open: boolean);
const rfname='ZYGOTE.RNG';
var c: char;
    i: integer;
begin
   if open then
   begin
      if exist(rfname) then
      begin
         {$I-}
         assign(filehandle,rfname);
         reset(filehandle,sizeof(ringdata));
         if ioresult=0 then
         begin
            i:=filesize(filehandle);
            if i=0 then close(filehandle);
         end else i:=0;
      end else i:=0;
      if i=1 then
      begin
         blockread(filehandle,ringdata,1,i);
         close(filehandle);
      end else fillchar(ringdata,sizeof(ringdata),0);
   end else
   begin
      {$I-}
      assign(filehandle,rfname);
      rewrite(filehandle,sizeof(ringdata));
      blockwrite(filehandle,ringdata,1);
      close(filehandle);
      if ioresult=0 then;
   end;
   {$I+}
end;

procedure init;
var c: byte;
begin
   window(1,1,80,25);
   color(lightgray,black);
   clrscr;
   c:=attr(cyan,black);
   makebox(0,1,1,51,12,1);
   makebox(0,52,1,80,25,1);
   fwrite(chars('Ä',27),3,53,c);
   fwrite(chars('Ä',50),13,1,c);
   fwrite(chars('Ä',50),15,1,c);
   fwrite(chars('Ä',50),25,1,c);
   c:=attr(blue,lightgray);
   fwrite(' Incoming ',1,3,c);
   fwrite(' Status ',1,54,c);
   fwrite(' Agenda ',13,3,c);
   fwrite('rings   time/date',2,54,attr(lightcyan,black));
   fwrite('toggle   sequence          action',14,3,attr(lightcyan,black));
   window(2,2,50,11);
   fillchar(ringarray,sizeof(ringarray),0);
   open_rng(true);
   showagenda;
   quit:=false;
   index:=0;
   ringcount:=0;
   s:='';
end;

begin
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   init;
   repeat
       if keypressed then
       begin
          ch:=readkey;
          if ch=#0 then ch:=readkey else
          begin
             case upcase(ch) of
                '1'..
                '9': editagenda(ord(ch)-48);
                'A'..
                'I': begin
                        temp:=ord(upcase(ch))-64;
                        if ringdata[temp].sequence>'' then
                        begin
                           ringdata[temp].flag:=not ringdata[temp].flag;
                           showagenda;
                        end;
                     end;
                #27: quit:=true;
             end;
          end;
       end;
       if _rx_ready then
       begin
          while _rx_ready do
          begin
             ch:=chr(_get);
             s:=s+ch;
             if ch=#10 then
             begin
                if s=configdata.results[3]+#13+#10 then
                begin
                   inc(ringcount);
                   if ringcount=1 then
                   begin
                      stemp:=time(1)+'  '+date;
                      fwrite('*',2,53,attr(lightred,black)+blink);
                   end;
                   etime:=clocktick;
                end;
                s:='';
             end;
             write(ch);
          end;
       end;
       diff:=abs(clocktick-etime);
       if (ringcount>0) and (diff>115) then
       begin
          clrscr;
          inc(index);
          if index>sizeofarray then
          begin
             for temp:=1 to (sizeofarray-1) do ringarray[temp]:=ringarray[temp+1];
             index:=sizeofarray;
          end;
          ringarray[index]:=its(ringcount)+chars(' ',4-length(its(ringcount)))+stemp;
          ringcount:=0;
          fwrite(' ',2,53,attr(lightgray,black));
          for temp:=1 to index do fwrite(ringarray[temp],4+temp,54,attr(white,black));
          for temp:=1 to 9 do
          if ringdata[temp].flag then
          with ringdata[temp] do
          begin
             if index>=length(sequence) then
             begin
                stemp:='';
                for t1:=length(sequence) downto 1 do
                   stemp:=stemp+ringarray[index-t1+1][1];
                if stemp=sequence then
                begin
                   savevideo(vback,true);
                   lx:=wherex; ly:=wherey;
                   exec(commandlocation,' /c '+action);
                   window(2,2,50,11);
                   gotoxy(lx,ly);
                   savevideo(vback,false);
                end;
             end;
          end;
       end;
       if (abs(clocktick-lastclock)>18) then
       begin
          lastclock:=clocktick;
          fwrite(time(1),14,40,attr(yellow,black));
       end;
   until quit;
   open_rng(false);
   savevideo(videoback,false);
   window(1,1,80,activescreensize);
   gotoxy(wx,wy);
   statusbar;
end;

procedure bigclock;
type ROMentry = array[0..7] of byte;
    ROMtable = array[0..127] of ROMentry;
    title_type = string[10];

var table : ROMtable absolute $F000:$FA6E;
    temptime: string[10];

procedure ShowEntry(entry: ROMentry; col, row : byte; CH: char);
var eRow, eCol  : 0..7;
    AByte       : byte;
begin
   for eRow := 0 to 7 do
   begin
      AByte := entry[eRow];
      for eCol := 7 downto 0 do
      begin
         gotoXY(col + eCol, row + eRow);
         if odd(AByte) then write(ch) else write(' ');
         AByte := AByte shr 1;
      end;
   end;
end;

procedure MakeTitle(title: title_type; Starting_row, Offset: byte; ch: char);
var n, starting_col, this_col : byte;
begin
   starting_col:= (((80 - 8*length(title)) div 2) and $00FF) + offset;
   for N:= 1 to length(title) do
   begin
      this_col := starting_col + 8*(N-1) +1;
      if ord(title[N]) <= 127 then
      if ch=#0 then ShowEntry(table[ord(title[N])],This_Col,starting_Row,title[N])
        else ShowEntry(table[ord(title[N])],This_Col,starting_Row, CH);
   end;
end;

begin
  wx:=wherex; wy:=wherey;
  savevideo(videoback,true);
  cursor(false);
  makebox(0,1,1,80,25,1);
  repeat
     if temptime<>time(2) then
     begin
        temptime:=time(2);
        textcolor(cyan);
        maketitle(date,2,0,#219);
        textcolor(lightcyan);
        MakeTitle(time(2),17,0,#219);
     end;
  until keypressed;
  gotoxy(wx,wy);
  savevideo(videoback,false);
  statusbar;
  waitkey;
  cursor(true);
end;

procedure textsearch;
var ch: char;
    lo,y,x,lx,ly: byte;
    temp: string[80];
    back: array[9..13] of string[61];

function where(xloc,yloc: byte): word;
begin
   where:=160*(yloc-1) + 2*xloc-2;
end;
begin
   lx:=wherex; ly:=wherey;
   for lo:=9 to 13 do movefromscreen(mem[baseofscreen:where(25,lo)],back[lo],31);
   lo:=0;
   makebox(attr(cyan,blue),25,9,55,13,1);
   fwrite('Text search',10,35,attr(lightcyan,blue));
   fwrite('match:',12,27,attr(yellow,blue));
   editflag(1,1,1,1,1,1,1);
   ch:=input(attr(white,cyan),34,12,tsbuffer,20,20,lo);
   for lo:=9 to 13 do movetoscreen(back[lo],mem[baseofscreen:where(25,lo)],31);
   if (ch=#13) and (tsbuffer>'') then
   begin
      temp:=blanks(80);
      tsbuffer:=caps(tsbuffer);
      for y:=1 to activescreensize do
      begin
         for x:=1 to 80 do temp[x]:=upcase(chr(mem[baseofscreen:where(x,y)]));
         for x:=1 to (80-length(tsbuffer)+1) do
         begin
            lo:=pos(tsbuffer,temp);
            temp[x]:=#0;
            if lo>0 then changeattr(length(tsbuffer),y,lo,attr(yellow,cyan));
         end;
      end;
   end;
   gotoxy(lx,ly);
end;

function tellzvar(s: string): string;
var desc: string[12];
begin
   if pos('%P',s)>0 then desc:='Send port # ' else
   if pos('%S',s)>0 then desc:='Send baud   ' else
   if pos('%F',s)>0 then desc:='Send fname  ' else
   if pos('%D',s)>0 then desc:='Send date   ' else
   if pos('%T',s)>0 then desc:='Send time   ' else
   if pos('%Ma',s)>0 then desc:='Send mac #1 ' else
   if pos('%Mb',s)>0 then desc:='Send mac #2 ' else
   if pos('%Mc',s)>0 then desc:='Send mac #3 ' else
   if pos('%Md',s)>0 then desc:='Send mac #4 ' else
   if pos('%Me',s)>0 then desc:='Send mac #5 ' else
   if pos('%Mf',s)>0 then desc:='Send mac #6 ' else
   if pos('%Ba',s)>0 then desc:='Send bname  ' else
   if pos('%Bb',s)>0 then desc:='Send bphone ' else
   if pos('%Bc',s)>0 then desc:='Send bcommt ' else
   if pos('%Bd',s)>0 then desc:='Send NUP    ' else
   if pos('%Ua',s)>0 then desc:='Send handle ' else
   if pos('%Ub',s)>0 then desc:='Send passwd ' else
   if pos('%Uc',s)>0 then desc:='Send LFD    ' else
   if pos('%Ud',s)>0 then desc:='Send ucommt ' else
   if pos('%Ue',s)>0 then desc:='Send uBD    ' else
   if pos('%Uf',s)>0 then desc:='Send rname  ' else
   if pos('%Ug',s)>0 then desc:='Send hphone ' else
   if pos('%Uh',s)>0 then desc:='Send dphone ' else
   if pos('%Ui',s)>0 then desc:='Send addr   ' else
   if pos('%Uj',s)>0 then desc:='Send city   ' else
   if pos('%Ea',s)>0 then desc:='Send intnet ' else
   if pos('%Eb',s)>0 then desc:='Send fido   ' else
   if pos('%Ec',s)>0 then desc:='Send wwiv   ' else
   if pos('%Ed',s)>0 then desc:='Send virt   ' else
   if pos('%Ee',s)>0 then desc:='Send other  ' else desc:='Send <cmd>  ';
   tellzvar:=desc;
end;

function tellzfunc(var s: string): string;
var desc: string[12];
begin
   if s='@MINIDOS' then  desc:='MiniDOS     ' else
   if s='@BINARY_READER' then desc:='Bin reader  ' else
   if s='@CLRSCREEN' then desc:='Clear scrn  ' else
   if s='@TOLLREPORTER' then desc:='Toll report ' else
   if s='@TEXTSEARCH' then desc:='Text search ' else
   if s='@SETUP_ZYGOTE' then desc:='Sys setup   ' else
   if s='@CHANGEPARAMS' then desc:='Param edit  ' else
   if s='@ASCIICHART' then desc:='Ascii chart ' else
   if s='@STAMPTEXT' then desc:='Stamp text  ' else
   if s='@DIAL_MENU' then desc:='Dial menu   ' else
   if s='@DIR_LISTER' then desc:='File lister ' else
   if s='@GRABTEXT' then desc:='Text grab   ' else
   if s='@HANGUP' then desc:='Hangup      ' else
   if s='@DOSSHELL' then desc:='DOS shell   ' else
   if s='@KEYLOCK' then desc:='Keybd lock  ' else
   if s='@LOADSCRIPT' then desc:='Load script ' else
   if s='@SENDBREAK' then desc:='Send break  ' else
   if s='@EXITWINDOW' then desc:='Exit Zygote ' else
   if s='@CAPTURETOGGLE' then desc:='Capture     ' else
   if s='@NOTEPAD' then desc:='Notepad     ' else
   if s='@MACRO_MENU' then desc:='Edit macro  ' else
   if s='@UPLOAD_FILE' then desc:='Upload menu ' else
   if s='@DOWNLOAD_FILE' then desc:='Downld menu ' else
   if s='@ANTIOFF' then desc:='Anti-logoff ' else
   if s='@MODEMCOMMAND' then desc:='Modem cmds  ' else
   if s='@BBS_STRIPPER' then desc:='BBS strip   ' else
   if s='@RINGMONITOR' then desc:='Phone watch ' else
   if s='@BIGCLOCK' then desc:='Big clock   ' else
   if s='@SCREENDUMP' then desc:='Screen dump ' else
   if s='@CANCELAUTO' then desc:='Aut/scr off ' else
   if s='@CHATMODE' then desc:='Chatmode    ' else
   if s='@WORLDTIME' then desc:='World time  ' else
   if s='@BACKGROUND' then desc:='See bckgrnd ' else
   if s='@HISTORY' then desc:='Grab histry ' else
   if s='@CALCULATOR' then desc:='4F calc     ' else
   if s='@DOORWAY' then desc:='DoorwayMode ' else
   if s='@BOARDHELP' then desc:='Board help  ' else
   if s='@PRINTER' then desc:='Printer     ' else
   if s='@BACKWARDSTEXT' then desc:='ReverseText ' else
   if s='@SCROLLBACK' then desc:='Scrollback  ' else
   if s='@ENCRYPTMSG' then desc:='EncryptMail ' else
   if s='@HOST_MODE' then desc:='Hostmode    ' else
   if s='@USERINFO' then desc:='User info   ' else
   if s='@EMAIL_BOOK' then desc:='Email book  ' else
   if s='@CHANGEDNDIR' then desc:='Alt. DL dir ' else desc:='            ';
   tellzfunc:=desc;
end;

procedure helpscreen;
const thekey: array[1..99] of char =(#30,#48,#46,#32,#18,#33,#34,#35,#23,#36,
              #37,#38,#50,#49,#24,#25,#16,#19,#31,#20,#22,#47,#17,#45,#21,
              #44,#59,#60,#61,#62,#63,#64,#65,#66,#67,#68,#104,#105,#106,
              #107,#108,#109,#110,#111,#112,#113,#94,#95,#96,#97,#98,#99,
              #100,#101,#102,#103,#84,#85,#86,#87,#88,#89,#90,#91,#92,#93,
              #129,#120,#121,#122,#123,#124,#125,#126,#127,#128,#3,#71,#79,
              #73,#81,#82,#83,#119,#117,#132,#118,#165,#166,#75,#77,#72,#80,
              #115,#116,#15,#130,#131,#114);
var i,c,c1,c2,c3,c4,x,y: byte;
    ch: char;
    rat: mousetype;
begin
   hidemouse;
   savevideo(videoback,true);
   makebox(7,1,1,80,25,5);
   makebox(0,27,1,80,2,1);
   c:=attr(lightgreen,blue);
   fwrite(' ø=Alt  ^=Ctrl  ~=Shft ',1,2,attr(white,blue));
   changeattr(1,1,3,c); changeattr(1,1,10,c); changeattr(1,1,18,c);
   fwrite(chars('ß',23),2,3,attr(darkgray,black));
   fwrite('Ü',1,25,attr(darkgray,black));
   c:=attr(lightblue,black);
   for i:=1 to 23 do fwrite('ø'+chr(i+64),i+2,1,c);     (* Alt-A/V *)
   for i:=24 to 26 do fwrite('ø'+chr(i+64),i-21,17,c);  (* Alt-V/Z *)
   for i:=1 to 10 do fwrite('F'+its(i),i+5,17,c);       (* F1-F10 *)
   for i:=1 to 9 do fwrite('øF'+its(i),i+15,17,c);      (* Alt-F1/F9 *)
   fwrite('øF0',25,17,c);                               (* Alt-F10 *)
   for i:=1 to 9 do fwrite('^F'+its(i),i+2,33,c);       (* Ctrl-F1/F9 *)
   fwrite('^F0',12,33,c);                               (* Ctrl-F10 *)
   for i:=1 to 9 do fwrite('~F'+its(i),i+12,33,c);      (* Shft-F1/F9 *)
   fwrite('~F0',22,33,c);                               (* Shft-F10 *)
   for i:=0 to 2 do fwrite('ø'+chr(i+48),i+23,33,c);    (* Alt-0/2 *)
   for i:=3 to 9 do fwrite('ø'+chr(i+48),i,49,c);       (* Alt-3/9 *)
   fwrite('^2',10,49,c);                                (* Ctrl-2 *)
   fwrite('HOM',11,49,c);
   fwrite('END',12,49,c);
   fwrite('PUP',13,49,c);
   fwrite('PDN',14,49,c);
   fwrite('INS',15,49,c);
   fwrite('DEL',16,49,c);
   fwrite('^HO',17,49,c);
   fwrite('^EN',18,49,c);
   fwrite('^UP',19,49,c);
   fwrite('^DN',20,49,c);
   fwrite('^IN',21,49,c);
   fwrite('^DL',22,49,c);
   fwrite(#27,23,49,c);                            (* arrows *)
   fwrite(#26,24,49,c);
   fwrite(#24,25,49,c);
   fwrite(#25,3,65,c);
   fwrite('^'#27,4,65,c);
   fwrite('^'#26,5,65,c);
   fwrite('~TB',6,65,c);
   fwrite('ø-',7,65,c);
   fwrite('ø=',8,65,c);
   fwrite('^*',9,65,c);
   x:=5; y:=3; c3:=attr(yellow,black); c4:=attr(lightred,black);
   c1:=attr(lightcyan,black); c2:=attr(cyan,black);
   for i:=1 to 99 do
   begin
      if keyboarddata.altkey[thekey[i]][1]='@' then
         fwrite(tellzfunc(keyboarddata.altkey[thekey[i]]),y,x,c1) else
      if keyboarddata.altkey[thekey[i]][1]='$' then
         fwrite(tellzvar(keyboarddata.altkey[thekey[i]]),y,x,c2) else
      if keyboarddata.altkey[thekey[i]][1]='!' then
         fwrite('[DOS exec]  ',y,x,c3) else
      if keyboarddata.altkey[thekey[i]][1]='#' then
         fwrite('[SWAP]      ',y,x,c4);
      inc(y);
      if y mod 26=0 then
      begin
         x:=x+16;
         y:=3;
      end;
   end;
   for i:=1 to 5 do
   begin
      bigsc[i].x:=(i-1)*16+5;
      bigsc[i].y:=3;
      bigsc[i].s:=11;
      bigsc[i].t:=23;
      bigsc[i].c:=hattr(yellow,green);
   end;
   bigsc[5].t:=7;
   sctotal:=5;
   scptr:=1;
   i:=1;
   cursor(false);
   sc:=bigsc[scptr];
   repeat
       ch:=scrollchoice(#13+#16+#17+#27,i);
       case ch of
          #255: begin
                   sc:=bigsc[scptr];
                   if i>sc.t then i:=sc.t;
                end;
           #16: begin
                   inc(scptr);
                   if scptr>sctotal then scptr:=1;
                   sc:=bigsc[scptr];
                   if i>sc.t then i:=sc.t;
                end;
           #17: begin
                   dec(scptr);
                   if scptr<1 then scptr:=sctotal;
                   sc:=bigsc[scptr];
                   if i>sc.t then i:=sc.t;
                end;
           #13: keyboarddata.altkey[#5]:=keyboarddata.altkey[thekey[23*(scptr-1)+i]];
       end;
   until (ch=#13) or (ch=#27);
   cursor(true);
   savevideo(videoback,false);
end;

procedure changedndir;
var i,on: byte;
    ch: char;
begin
   savevideo(videoback,true);
   wx:=wherex; wy:=wherey;
   cursor(false);
   page.flag:=0;
   timestat.flag:=0;
   sc.x:=21; sc.y:=10;
   sc.s:=40;
   sc.c:=hattr(white,blue);
   sc.nc:=attr(lightgray,black);
   sc.t:=3;
   on:=1;
   makebox(attr(lightblue,black),20,7,61,13,1);
   fwrite(' Change DL directory ',7,31,attr(yellow,black));
   fwritena('Ã'+chars('Ä',40)+'´',9,20);
   fwrite(configdata.dndir,8,21,attr(white,black));
   for i:=1 to 3 do
      fwrite(configdata.altdndir[i],9+i,21,attr(lightgray,black));
   ch:=scrollchoice(#27+#13,on);
   if ch=#13 then configdata.dndir:=configdata.altdndir[on];
   savevideo(videoback,false);
   cursor(true);
   gotoxy(wx,wy);
end;

end.