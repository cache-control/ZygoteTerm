unit z_util;

interface

const    zversion='ÄÒÎ';
         zpassword='Ù­¯²»§·Ð';
         dir_temp='TEMP';
         dir_host='HOST';
         dir_notepad='NOTEPAD';
         dir_capture='CAPTURE';
         dir_script='SCRIPT';
         dir_binary='BINARY';
         dir_phone='PHONE';
         dir_areadata='AREADATA';
         twoclickdelay=5;
type     string80=string[80];
         StringDir=string[80];
         StringName=string[25];
         StringPW=string[20];
         StringDesc=string[40];
         GraphicType = (uANSI,uVT100,uAVATAR,uNONE);
         AppendType = (uAPPEND,uOVERWRITE);
         ParamType=Record
                Speed: word;
                Parity: char;
                Dbit,Sbit: byte;
                graphic: graphictype;
                autolf,striphb,localecho,
                destructbs,captureemul: boolean;
                captureexist: appendtype;
         end;
         AccountType=Record
                Handle,
                RealName: stringname;
                Password: stringpw;
                LFD: string[4];
                Birthdate: string[8];
                HomePhone,
                DataPhone: string[14];
                Comment,
                Address,
                City_State: stringdesc;
         end;
         AccountFileType=Array['A'..'E'] of accounttype;
         ProtoType=Record
                ProtoName: stringname;
                WhereFile: stringdir;
                Comment,
                UpCmd,
                DnCmd,
                Sequence: stringdesc;
                AskDl,
                ChangeDl,
                AvailAuto: boolean;
         end;
         ProtoFiletype=Array['A'..'J'] of prototype;
         TransTableType=Record
                Rx: array[0..255] of char;
                Tx: array[#0..#255] of byte;
         end;
         MacType=array[1..6] of string[250];
         SysType=Record
                SysName: stringname;
                Comment: stringdesc;
                Dlay: byte;
                Waitfor: stringdesc;
                SendHandle,
                SendPW,
                SendLFD: boolean;
                LastCh: char;
         end;
         SysFileType=Array['A'..'J'] of systype;
         Configtype=Record
             Param: paramtype;
             Username,regname: stringname;
             Syscode,Hlevel, Defaultkeypw,
             Hshutdown,Haccess,regpwd: stringpw;
             AreaCode,LFD: string[4];
             Updir,Dndir,Hupdir,Hdndir: stringdir;
             altdndir: array[1..3] of stringdir;
             Leechmode: char;
             Datech,Timech: string[1];
             dtrdelay: word;
             Comport, XmitSize, RecvSize, redialpause,
             msgdelay,scrollbacksize,regnumber: integer;
             XonXoff, CtsRts, BlinkFilter, dofifo,
             Keeplog, Hopen, allowfax, showpwd, rescanafteredit,
             GeneratePW, Beep, Confirmhe, usealtnum, useintense,
             Vretrace, Init_online, ShowStatBar, UseAlarm,
             dos_deinstallport, UseDTR, Cryptdecode, cwtoggle,
             ExpandTab, dlsaving,allowmusic,registered: boolean;
             InitStr: array[1..2] of stringdesc;
             Dialstr: array[1..2] of string[10];
             Dialsuffix: string[5];
             Modemstring: array[1..11] of string[10];
             Hangupstr,answerstr,callwaiting,attention: string[10];
             ComBase: array[1..4] of string[4];
             ComIRQ,ComINT: array[1..4] of byte;
             Results: array[1..15] of string[15];
             Faxprogram: string[30];
             AntiChar,Anticounter,Tabsize,
             Diallimit, Usedial, printerport,
             UseInit, Hostring, pstdiff, unmarkwhen: byte;
         end;
         DialType=Record
                BBSname: string[23];
                BBSphone: string[16];
                Altphone: array[1..2] of string[16];
                Comment: stringdesc;
                Syspass: stringpw;
                emailaddr: array[1..5] of stringdesc;
                User: accounttype;
                Param: paramtype;
                Autosys,Protocol: char;
                usedial: byte;
                Timescalled: integer;
                Checknotepad,Redialflag,autocapture: boolean;
                Scriptname,Lastdate,
                file_kbd,file_tbl,
                file_cap,file_pad: string[8];
                Location: string[24];
                Toll: byte;
                execute: stringdesc;
         End;
         keyboardtype=record
            altkey: array[#3..#166] of string[50];
         end;
         Lasttype=record
            lastbbs,ptr_buffer,lastcalled: byte;
            lasttime: longint;
            param: paramtype;
            ldcodes: array[1..5] of string[40];
            name_dir,name_kbd,name_tbl: string[8];
            grabbuffer: array[1..10] of string[80];
            scl_writeok,scl_full: boolean;
            scl_nextio,scl_filesize: integer;
            timesused: array[0..7] of word;
         end;
         BufType= array[1..160] of byte;
         VideoType= array[1..25] of buftype;
         fielddesctype= array[1..22] of string[100];
         SCtype=record
             x,y,t,s,c,nc: byte;
         end;

var      SC: sctype;
         bigsc: array[1..15] of sctype;
         ClockTick: word absolute $40:$6C;
         Dparam: paramtype;
         bbson: integer;
         Wx,Wy,Dialnumber,sctotal,scptr,
         Activescreensize,lastfg,lastbg: Byte;
         Connected,Capture,Script,Autolog,antioff,
         Keylocked,Quitzygote,Waitforretrace,Useprinter,
         Colorvideo,ctrlok,cursorok,forcecap,
         digitok,charok,extendok,otherok,loadconfig: boolean;
         saveflag: array[1..16] of boolean;
         VideoBack: videotype;
         MacData: mactype;
         configdata: configtype;
         SysData: sysfiletype;
         ProtoData: protofiletype;
         AccountData: accountfiletype;
         keyboarddata: keyboardtype;
         DialData: dialtype;
         TableData: transtabletype;
         Lastdata: lasttype;
         keylockpw: stringpw;
         BaseOfScreen,dcebps,clocktemp: Word;
         fielddesc: ^fielddesctype;
         filehandle: file;
         tabpos: array[1..80] of boolean;
         region: record
                    active: boolean;
                    top,bottom: byte;
                 end;
         Page,Timestat: record
                           flag,x,y,colr: byte;
                        end;

Function  CT(s,filename: string): string;
Function  ReadKb: char;
Function  Time(o: byte): stringname;
Function  Date: stringname;
Function  Exist(Tfile: string80): boolean;
Function  Its(x: longint): stringname;
Procedure Hilight(a,b: byte);
Procedure Color(a,b: byte);
Procedure Restorecolor;
Function  Diskspace(t: byte): string80;
Function  Commandlocation: string80;
Function  Chars(C : char; n: integer): string;
Function  Caps(s: string): string;
Procedure Statusbar;
Procedure Cursor(status: boolean);
Procedure Send(s: string);
Procedure Xy(x,y: byte; s: string);
Procedure Readbinfile(s: string80; Wait: boolean);
Procedure Waitkey;
Procedure Screendump(keych: char);
Function  Input(colr,startx,starty: byte; var line: string; len,field: byte; var laston: byte): char;
Function  Blanks(x: integer): string;
Procedure Makebox(colr,x1,y1,x2,y2,w: byte);
Procedure savevideo(var buf; wt: boolean);
function  asciichart(keych: char; var ch: char): boolean;
Procedure Grabline(keych: char);
Function  Checkpaste(var s: string; keych: char; lb,rb: byte): boolean;
Function  Conv(speed: longint): stringname;
Function  Keystatus(chk: byte): boolean;
Procedure EditFlag(a,b,c,d,e,f,g: byte);
Function  Attr(Foreground, Background: Byte): byte;
Function  Hattr(Foreground,Background: byte): byte;
Procedure fwrite(St: String80; Row, Col, Attr: integer);
Procedure fwritev(var St: string80; Row, Col, Attr: integer);
Procedure fwritena(St: String80; Row, Col: integer);
Procedure ChangeAttr(Number: Integer; Row, Col, Attr: integer);
Procedure MoveFromScreen(var Source, Dest; Length: word);
Procedure MoveToScreen(var Source, Dest; Length: word);
Function  ReadDesc(filename,s: string): boolean;
Procedure FixDesc;
Procedure WriteDescField;
Function  ScrollChoice(Out: stringname; Var on: byte): char;
Procedure showmsg(s1,s2: stringdesc);
Procedure vertchars(colr,x,y,y2: byte; c: char);
function  cmsg(st: string80): string80;
function  pickfile(x,y: byte; spec,lastfile: stringname): stringname;

implementation

uses Dos,Crt,z_comio,z_mouse;

function ct;
   procedure replace(match,replacewith: string; var thestr: string);
   var x: integer;
   begin
      x:=pos(match,thestr);
      if x>0 then
         thestr:=copy(thestr,1,x-1)+replacewith+copy(thestr,x+length(match),length(thestr));
   end;
begin
   replace('%P',its(configdata.comport),s);
   replace('%S',its(dparam.speed),s);
   replace('%F',filename,s);
   replace('%D',date,s);
   replace('%T',time(1),s);
   replace('%Ma',macdata[1],s);
   replace('%Mb',macdata[2],s);
   replace('%Mc',macdata[3],s);
   replace('%Md',macdata[4],s);
   replace('%Me',macdata[5],s);
   replace('%Mf',macdata[6],s);
   with dialdata do
   begin
      replace('%Ba',bbsname,s);
      replace('%Bb',bbsphone,s);
      replace('%Bc',comment,s);
      replace('%Bd',syspass,s);

      replace('%Ua',user.handle,s);
      replace('%Ub',user.password,s);
      replace('%Uc',user.lfd,s);
      replace('%Ud',user.comment,s);
      replace('%Ue',user.birthdate,s);
      replace('%Uf',user.realname,s);
      replace('%Ug',user.homephone,s);
      replace('%Uh',user.dataphone,s);
      replace('%Ui',user.address,s);
      replace('%Uj',user.city_state,s);

      replace('%Ea',emailaddr[1],s);
      replace('%Eb',emailaddr[2],s);
      replace('%Ec',emailaddr[3],s);
      replace('%Ed',emailaddr[4],s);
      replace('%Ee',emailaddr[5],s);
   end;
   ct:=s;
end;

function readkb;
var s: string[12];
    rat: mousetype;
    c: char;
begin
   c:=#0;
   repeat
      if timestat.flag=1 then
      if s<>time(1) then
      begin
         s:=time(1);
         fwrite(s,timestat.y,timestat.x,timestat.colr);
      end;
      mouseposition(rat);
      if rat.stat=leftpress then
      begin
         mousepress(leftbutton,rat);
         if rat.pcount=1 then c:=#13;
      end else
      if rat.stat=rightpress then
      begin
         mousepress(rightbutton,rat);
         if rat.pcount=1 then c:=#27;
      end;
   until (keypressed) or (c>#0);
   if c>#0 then readkb:=c else readkb:=readkey;
end;

function exist;
var checkfile: text;
begin
   if tfile='' then exist:=false else
   begin
      {$I-}
      assign(checkfile,tfile);
      reset(checkfile);
      if ioresult=0 then
      begin
         exist:=true;
         close(checkfile);
      end else exist:=false;
      {$I+}
   end;
end;

Function time;
var hour,minute,second,sec100: word;
    s: string[6];
begin
  gettime(hour,minute,second,sec100);
  if o=3 then time:=its(hour)+configdata.timech+its(minute) else
  begin
     s:=configdata.timech+chars('0',2-length(its(minute)))+its(minute)+
        configdata.timech+chars('0',2-length(its(second)))+its(second);
     if o=1 then
     begin
        if hour>12 then
        begin
           dec(hour,12);
           if hour<10 Then Time:='0'+its(hour)+s+' PM' else time:=its(hour)+s+' PM';
        end else
        case hour of
            0:  Time:='12'+s+' AM';
           12:  Time:='12'+s+' PM';
           else Time:=chars('0',2-length(its(hour)))+its(hour)+s+' AM';
        end;
     end else time:=chars('0',2-length(its(hour)))+its(hour)+s;
  end;
end;

function date;
var year,month,day,dayofweek: word;
begin
   getdate(year,month,day,dayofweek);
   date:=chars('0',2-length(its(month)))+its(month)+configdata.datech+
         chars('0',2-length(its(day)))+its(day)+configdata.datech+copy(its(year),3,2);
end;

function its;
var s:string;
begin
   str(x,s); its:=s;
end;

procedure color;
begin
   if not colorvideo then
   begin
      a:=7;
      b:=0;
   end else
   begin
      b:=b mod 16;
      if b>7 then a:=a+16;
   end;
   textcolor(a); textbackground(b);
end;

procedure hilight(a,b: byte);
begin
   if not colorvideo then
   begin
      textcolor(0);
      textbackground(7);
   end else color(a,b);
end;

procedure restorecolor;
begin
   color(lastfg,lastbg);
end;

function diskspace;
var diskstr: string[12];
    down: integer;
    now: boolean;
begin
   diskstr:='';
   now:=false;
   if T=0 then
   str(diskfree(0),diskstr) else str(diskfree(0) div 1024,diskstr);
   if (length(diskstr)>3) then
   begin
      down:=length(diskstr)-2;
      repeat
         if (down<2) then now:=true;
         If Not Now Then insert(',',diskstr,down);
         dec(down,3);
      until now;
   end;
   if T=0 then diskspace:=diskstr+' Bytes' else diskspace:=diskstr+'K';
end;

function commandlocation;
var env_seg,I: word;
    cst,temp: string;
    ch: char;
begin
   env_seg:=memw[prefixseg:$2c];
   I:=0;
   cst:='';
   while (mem[env_seg:I]<>0) and (cst='') do
   begin
      temp:='';
      while chr(mem[env_seg:I])<>'=' do
      begin
         temp:=temp+chr(mem[env_seg:I]);
         inc(i);
      end;
      if temp='COMSPEC' then
      begin
         inc(i);
         while mem[env_seg:I]<>0 do
         begin
            cst:=cst+chr(mem[env_seg:I]);
            inc(I);
         end;
      end else
      repeat
         inc(I);
      until mem[env_seg:I-1]=0;
   end;
   commandlocation:=cst;
end;

Function Chars;
Var s: string;
Begin
   if n<1 then chars:='' else
   begin
      fillchar(s[1],n,c);
      s[0]:=chr(n);
      chars:=s;
   end;
end;

function caps;
Var x: byte;
Begin
   For x:=1 To Length(S) do s[x]:=upcase(s[x]);
   caps:=s;
end;

procedure statusbar;
var c: byte;

procedure writeboolean(x: byte);
var tc: byte;
begin
   tc:=attr(lightgreen,blue);
   if antioff then fwrite('A',25,x,tc);
   if configdata.beep then fwrite('B',25,x+1,tc);
   if dparam.localecho then fwrite('E',25,x+2,tc);
   if configdata.cryptdecode then fwrite('D',25,x+3,tc);
end;

begin
   wx:=wherex; wy:=wherey;
   if configdata.showstatbar then
   begin
      if wy=25 then wy:=24;
      If Connected then
      with dialdata do
      begin
         c:=attr(lightgray,blue);
         fwrite(' Ý                       Ý        Ý         Ý           Ý                    Ý ',25,1,c);
         c:=attr(white,blue);
         fwritev(bbsname,25,((25-length(bbsname)) div 2)+2,c);
         writeboolean(29);
         c:=attr(lightred,blue);
         with dparam do
            fwrite(conv(speed)+parity+its(dbit)+its(sbit),25,48,c);
         c:=attr(yellow,blue);
         if script then fwrite('Scripts',25,37,c) else
         if autolog then fwrite('Auto-On',25,37,c) else
         if capture then fwrite('Capture',25,37,c) else
         if useprinter then fwrite('Printer',25,37,c) else
         if antioff then fwrite('AntiOff',25,37,c) else
         fwrite('On-Line',25,37,c);
      end else
      if _CD then
      begin
         c:=attr(lightgray,blue);
         fwrite(' Ý    Ý                                                           Ý           Ý',25,1,c);
         with dparam do
            fwrite('Manual Connection with Zygote Term v'+cmsg(zversion)+' @'+conv(speed)+
            parity+its(dbit)+its(sbit),25,14,attr(white,blue));
         writeboolean(3);
      end else
      begin
         c:=attr(white,blue);
         fwrite(' Ý                    Ý                                    Ý      Ý           Ý ',
                25,1,attr(lightgray,blue));
         if keyboarddata.altkey[#119]='' then fwrite(cmsg('­™ž‡Ç¡§ª£Å‚ŒÁˆº²­'),25,4,c) else
         fwrite(cmsg('¾»£Í˜Ž‰†ˆŠŠƒŠ‡’'),25,4,c);
         fwrite(cmsg('©‹–Ÿ›‹Í¸Ž˜„È‘')+cmsg(zversion)+cmsg('ÓˆÐ¢—Í¢ŒŸ‰'),25,28,c);
         writeboolean(62);
      end;
      changeattr(11,25,68,attr(white,blue));
   end;
   window(1,1,80,activescreensize);
   gotoxy(wx,wy);
   restorecolor;
end;

procedure Cursor;
begin
   if status then
      Inline($31/$C0/$8E/$C0/$26/$A1/$60/$04/$80/$E4/$DF/$89/$C1/$B4/$01/$CD/$10) else
         Inline($31/$C0/$8E/$C0/$26/$A1/$60/$04/$80/$E4/$BF/$80/$CC/$20/$89/$C1/$B4/$01/$CD/$10);
end;

procedure send(s: string);
var y,len: integer;
    c,nc: byte;
begin
   y:=1;
   s:=ct(s,'');
   len:=length(s);
   If len>0 then
   Repeat
       nc:=ord(s[y]);
       if y+1>len then c:=0 else c:=ord(upcase(s[y+1]));
       if (nc=94) and (c>64) then
       begin
          _put(c-64);
          inc(y);
       end else _put(nc);
       delay(1);
       inc(y);
   until y>len;
end;

procedure xy;
var z,o: byte;
begin
   gotoxy(x,y);
   z:=1;
   if length(s)>0 then
   repeat
     case s[z] of
        ^f: begin
               textcolor(ord(upcase(s[z+1]))-65);
               inc(z);
            end;
        ^b: begin
              textbackground(ord(upcase(s[z+1]))-65);
              inc(z);
            end;
       else write(s[z]);
     end;
     inc(z);
   until z>length(s);
end;

procedure readbinfile;
var binfile: file;
    x: integer;
begin
   if exist(s) then
   begin
      nosound;
      if wait then
      begin
         savevideo(videoback,true);
         cursor(false);
      end;
      assign(binfile,s);
      reset(binfile,4000);
      blockread(binfile,mem[baseofscreen:0],1,x);
      close(binfile);
      if wait then
      begin
         waitkey;
         savevideo(videoback,false);
         cursor(true);
      end;
   end else showmsg('You are missing ',caps(s));
end;

procedure waitkey;
var ch: char;
    count: byte;
    hour,min,sec,lastsec,hund: word;
begin
   count:=0;
   repeat
      gettime(hour,min,sec,hund);
      if sec<>lastsec then
      begin
         lastsec:=sec;
         inc(count);
      end;
   until (keypressed) or (count>60);
   if keypressed then
   if readkb=#0 then
   begin
      ch:=readkb;
      grabline(ch);
      screendump(ch);
   end;
end;

procedure screendump(keych: char);
var binfile: file;
    s: string[12];
    x: word;
begin
   if keyboarddata.altkey[keych]='@SCREENDUMP' then
   if diskfree(0)>4000 then 
   begin
      x:=1;
      repeat
         s:='Z_'+chars('0',5-length(its(x)))+its(x)+'.BIN';
         inc(x);
      until (not exist(dir_binary+'\'+s)) or (x=65000);
      {$I-}
      assign(binfile,dir_binary+'\'+s);
      rewrite(binfile,4000);
      blockwrite(binfile,mem[baseofscreen:0],1);
      close(binfile);
      if ioresult=0 then showmsg('Screen saved to binary file',s) else
         showmsg('Problem creating file','Aborting '+s);
      {$I+}
   end else showmsg('Cannot save screen to file','Not enough disk space');
end;

Function input;
var on: byte;
    kb,mych: char;
    rat: mousetype;
    o,lb,rb: integer;
    s: string;
    ins,lastmousestat: boolean;

    procedure CursorChange (New: integer; VAR Old: integer);
    begin
       Inline($31/$C0/$8E/$C0/$26/$A1/$60/$04/$C4/$7E/<OLD/$AB/$B4/$01/$8B/$4E/<NEW/$CD/$10);
    end;

begin
   lastmousestat:=mousehidden;
   hidemouse;
   ins:=false;
   cursor(false);
   lb:=1; rb:=field;
   s:=line;
   on:=length(s)+1;
   if laston=0 then laston:=on;
   if length(s)<len then s:=s+blanks(len-length(s));
   if laston>field then on:=field else on:=laston;
   fwrite(copy(s,1,field),starty,startx,colr);
   gotoxy(startx+on-1,starty);
   cursor(true);
   repeat
      kb:=#0;
      showmouse;
      with rat do
      repeat
         mouseposition(rat);
         if (rat.my=starty) and (rat.mx>=startx) and (rat.mx<startx+field) then
         begin
            if rat.stat=leftpress then
            begin
               mousepress(leftbutton,rat);
               if (my=lastpy) and (abs(clocktick-clocktemp)<twoclickdelay) and (pcount=1) then
               begin
                  input:=#13;
                  kb:=#13;
               end else
               if rat.pcount=1 then
               begin
                  clocktemp:=clocktick;
                  if cursorok then on:=rat.mx-startx+lb;
                  gotoxy(startx+on-lb,starty);
               end;
            end;
         end;
         if rat.stat=rightpress then
         begin
            mousepress(rightbutton,rat);
            if rat.pcount=1 then
            begin
               kb:=#27;
               input:=#27;
            end;
         end;
      until (keypressed) or (kb<>#0);
      hidemouse;
      if keypressed then
      begin
      kb:=readkb;
      if kb=#0 then
      begin
         kb:=readkb;
         cursor(false);
         case kb of
           #71: if cursorok then
                begin
                   on:=1;
                   while (on<len) and (s[on]=' ') do inc(on);
                   if (on=len) and (s[on]=' ') then on:=1;
                   lb:=on;
                   rb:=lb+field-1;
                   if rb>len then
                   begin
                      rb:=len;
                      lb:=rb-field+1;
                   end;
                   fwrite(copy(s,lb,field),starty,startx,colr);
                end;
           #72: input:='U';
           #73: input:='P';
           #80: input:='D';
           #81: input:='N';
           #75: if (on>1) and (cursorok) then dec(on);
           #77: if (on<len) and (cursorok) then inc(on);
           #79: if cursorok then
                begin
                   on:=len;
                   while (on>1) and (s[on]=' ') do dec(on);
                   if (on=1) and (s[1]=' ') then on:=0;
                   if on<len then inc(on);
                   rb:=on;
                   lb:=on-field+1;
                   if lb<1 then
                   begin
                      lb:=1;
                      rb:=field;
                   end;
                   fwrite(copy(s,lb,field),starty,startx,colr);
                end;
           #82: if cursorok then
                Begin
                   ins:=not Ins;
                   if ins then cursorchange(13,O) else cursorchange(O,O);
                end;
           #83: if (on<=len) and (cursorok) then
                Begin
                   delete(s,on,1);
                   s:=s+' ';
                   fwrite(copy(s,lb,field),starty,startx,colr);
                end;
          #119: begin
                   s:=blanks(len);
                   on:=1; lb:=1; rb:=field;
                   fwrite(copy(s,lb,field),starty,startx,colr);
                end;
         end;
         if (extendok) and (asciichart(kb,mych)) then
         begin
            s[on]:=mych;
            fwrite(copy(s,lb,field),starty,startx,colr);
         end;
         grabline(kb);
         screendump(kb);
         if checkpaste(s,kb,on,length(s)) then
            fwrite(copy(s,lb,field),starty,startx,colr);
         if on<lb then
         begin
            lb:=on;
            rb:=lb+field-1;
            fwrite(copy(s,lb,field),starty,startx,colr);
         end else
         if on>rb then
         begin
            rb:=on;
            lb:=rb-field+1;
            fwrite(copy(s,lb,field),starty,startx,colr);
         end;
         cursor(true);
         gotoxy(startx+on-lb,StartY);
      end else
      begin
        if forcecap then kb:=upcase(kb);
        if (kb in ['A'..'Z','a'..'z']) and (not charok) then kb:=#0;
        if (kb in ['0'..'9']) and (not digitok) then kb:=#0;
        if (ord(kb) in [0..7,9..12,14..23,25,26,28..31,127]) and (not ctrlok) then kb:=#0;
        if (ord(kb) in [128..255]) and (not extendok) then kb:=#0;
        if (ord(kb) in [32..47,58..64,94..96]) and (not otherok) then kb:=#0;

        case kb of
          #0: ;
          #8: begin
                 if ins then
                 begin
                    if (on=len) and (s[on]<>' ') then
                    begin
                       delete(s,on,1);
                       s:=s+' ';
                    end else
                    if on>1 then
                    begin
                       dec(on);
                       delete(s,on,1);
                       s:=s+' ';
                    end;
                 end else
                 begin
                    if (on=len) and (s[on]<>' ') then s[on]:=' ' else
                    begin
                       dec(on);
                       if on<1 then on:=1;
                       if on<lb then
                       begin
                          lb:=on;
                          rb:=lb+field-1;
                       end;
                       s[on]:=' ';
                    end;
                 end;
                 fwrite(copy(s,lb,field),starty,startx,colr);
                 Gotoxy(startx+on-lb,StartY);
               end;
          #13,
          #27: input:=kb;
          else if on<=len then
               begin
                  cursor(false);
                  if ins then
                  begin
                     if s[len]=' ' then
                     begin
                        delete(s,length(s),1);
                        insert(kb,s,on);
                        inc(on);
                     end;
                  end else
                  begin
                     s[on]:=kb;
                     inc(on);
                  end;
                  if on>len then on:=len;
                  if on>rb then
                  begin
                     rb:=on;
                     lb:=rb-field+1;
                  end;
                  fwrite(copy(s,lb,field),starty,startx,colr);
                  gotoxy(startx+on-lb,starty);
                  cursor(true);
               end;
               kb:=#0;
        end;
      end;
      end;
   until kb in [#13,#27,#72,#80,#73,#81];
   laston:=on-lb+1;
   while s[length(s)]=' ' do delete(s,length(s),1);
   line:=copy(s,1,len);
   if ins then cursorchange(O,O);
   cursor(true);
   if not lastmousestat then showmouse;
end;

Function blanks;
var s: string;
Begin
   if x<0 then x:=0;
   fillchar(s[1],x,#32);
   s[0]:=chr(x);
   blanks:=s;
end;

procedure makebox;
var x,i,index: byte;
    wc: array[1..4] of byte;
    adder: integer;
    tl,c,tr,bl,br,s: array[1..5] of char;
begin
   x:=x2-x1+1;
   tl[1]:='Ú'; c[1]:='Ä'; tr[1]:='¿'; bl[1]:='À'; br[1]:='Ù'; s[1]:='³';
   tl[2]:='Õ'; c[2]:='Í'; tr[2]:='¸'; bl[2]:='Ô'; br[2]:='¾'; s[2]:='³';
   tl[3]:='Ö'; c[3]:='Ä'; tr[3]:='·'; bl[3]:='Ó'; br[3]:='½'; s[3]:='º';
   tl[4]:='É'; c[4]:='Í'; tr[4]:='»'; bl[4]:='È'; br[4]:='¼'; s[4]:='º';
   tl[5]:=' '; c[5]:=' '; tr[5]:=' '; bl[5]:=' '; br[5]:=' '; s[5]:=' ';
   fwrite(tl[w]+chars(c[w],x-2)+tr[w],y1,x1,colr);
   for i:=y1+1 to y2-1 do fwrite(s[w]+blanks(x-2)+s[w],i,x1,colr);
   fwrite(bl[w]+chars(c[w],x-2)+br[w],y2,x1,colr);
   if colr=0 then
   begin
      adder:=1;
      index:=1;
      wc[1]:=1; wc[2]:=9; wc[3]:=3; wc[4]:=11;
      for i:=x1 to x2 do
      begin
         changeattr(1,y1,i,wc[index]);
         changeattr(1,y2,i,wc[index]);
         index:=index+adder;
         if index=4 then adder:=-1;
         if index=1 then adder:=1;
      end;
      index:=2;
      adder:=1;
      for i:=(y1+1) to (y2-1) do
      begin
         changeattr(1,i,x1,wc[index]);
         changeattr(1,i,x2,wc[index]);
         index:=index+adder;
         if index=4 then adder:=-1;
         if index=1 then adder:=1;
      end;
   end;
end;

procedure savevideo(var buf; wt: boolean);
begin
   if wt then movefromscreen(mem[baseofscreen:0],buf,2000) else
      movetoscreen(buf,mem[baseofscreen:0],2000);
end;

function asciichart;
type buffertype = array[1..40] of byte;
var xcor,ycor,i,nc,hc,pc: byte;
    lastmousestat: boolean;
    buffer: array[2..15] of buffertype;
    rat: mousetype;
    tempch: char;
begin
   if keyboarddata.altkey[keych]='@ASCIICHART' then
   begin
      lastmousestat:=mousehidden;
      hidemouse;
      for i:=2 to 15 do
      movefromscreen(mem[baseofscreen:160*(i-1)+118],buffer[i],20);
      nc:=attr(lightgray,black);
      hc:=hattr(white,cyan);
      pc:=attr(blue,cyan);
      makebox(attr(cyan,black),60,2,79,15,1);
      fwritena('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',11,60);
      fwrite('Value:',12,62,nc);
      fwrite('Send : [Enter ]',13,62,attr(white,black));
      fwrite('Quit : [Escape]',14,62,attr(white,black));
      for ycor:=3 to 10 do
         for xcor:=62 to 77 do fwrite(chr(ycor*16+xcor+18),ycor,xcor,nc);
      xcor:=62; ycor:=3;
      for i:=3 to 10 do changeattr(1,i,xcor,hc);
      changeattr(16,ycor,62,hc);
      repeat
          setmouseposition(xcor,ycor);
          fwrite(its(ycor*16+xcor+18)+' ',12,69,attr(yellow,black));
          changeattr(1,ycor,xcor,pc);
          tempch:=#0;
          repeat
             mouseposition(rat);
             if rat.mx<xcor then tempch:=#75 else
             if rat.mx>xcor then tempch:=#77 else
             if rat.my<ycor then tempch:=#72 else
             if rat.my>ycor then tempch:=#80;
             if rat.stat=leftpress then
             begin
                mousepress(leftbutton,rat);
                if rat.pcount=1 then tempch:=#13;
             end else
             if rat.stat=rightpress then
             begin
                mousepress(rightbutton,rat);
                if rat.pcount=1 then tempch:=#27;
             end;
          until (keypressed) or (tempch>#0);
          if keypressed then
          begin
             tempch:=readkey;
             if tempch=#0 then tempch:=readkey;
          end;
          case tempch of
             #72: if ycor>3 then
                  begin
                     changeattr(16,ycor,62,nc);
                     changeattr(1,ycor,xcor,hc);
                     dec(ycor);
                     changeattr(16,ycor,62,hc);
                  end;
             #80: if ycor<10 then
                  begin
                     changeattr(16,ycor,62,nc);
                     changeattr(1,ycor,xcor,hc);
                     inc(ycor);
                     changeattr(16,ycor,62,hc);
                  end;
             #75: if xcor>62 then
                  begin
                     for i:=3 to 10 do changeattr(1,i,xcor,nc);
                     changeattr(1,ycor,xcor,hc);
                     dec(xcor);
                     for i:=3 to 10 do changeattr(1,i,xcor,hc);
                  end;
             #77: if xcor<77 then
                  begin
                     for i:=3 to 10 do changeattr(1,i,xcor,nc);
                     changeattr(1,ycor,xcor,hc);
                     inc(xcor);
                     for i:=3 to 10 do changeattr(1,i,xcor,hc);
                  end;
          end;
      until (tempch=#27) or (tempch=#13);
      for i:=2 to 15 do
      movetoscreen(buffer[i],mem[baseofscreen:160*(i-1)+118],20);
      if tempch=#27 then asciichart:=false else
      begin
         asciichart:=true;
         ch:=chr(ycor*16+xcor+18);
      end;
      if not lastmousestat then showmouse;
   end else asciichart:=false;
end;

Procedure grabline;
var c: char;
    lx,ly,yloc,mc,i,
    xloc,startx,starty: byte;
    grab,quit,out,lms: boolean;
    back: videotype;
    rat: mousetype;

procedure strip;
var x,y,i: byte;
    s: string;
begin
   if (c=#13) and (grab) then
   begin
      i:=lastdata.ptr_buffer;
      inc(i);
      if i>10 then i:=1;
      for y:=starty to yloc do
      begin
         s:='';
         inc(lastdata.ptr_buffer);
         if lastdata.ptr_buffer>10 then lastdata.ptr_buffer:=1;
         for x:=startx to xloc do s:=s+chr(back[y][2*x-1]);
         lastdata.grabbuffer[lastdata.ptr_buffer]:=s;
      end;
      lastdata.ptr_buffer:=i;
   end;
end;

function where: word;
begin
   where:=160*(yloc-1) + 2*xloc-2;
end;

Begin
   if keyboarddata.altkey[keych]='@GRABTEXT' then
   begin
      lms:=mousehidden;
      lx:=wherex;
      ly:=wherey;
      xloc:=lx;
      yloc:=ly;
      setmouseposition(lx,ly);
      hidemouse;
      savevideo(back,true);
      mc:=hattr(blue,cyan)+128;
      quit:=false;
      grab:=false;
      repeat
         setmouseposition(xloc,yloc);
         if not grab then fwrite('',yloc,xloc,mc) else
            for i:=starty to rat.my do
              changeattr(xloc-startx+1,i,startx,attr(0,7));
         out:=false;
         repeat
             mouseposition(rat);
             if rat.stat=leftpress then
             begin
                mousepress(leftbutton,rat);
                if rat.pcount=1 then
                begin
                   if not grab then
                   begin
                      out:=true;
                      grab:=true;
                      startx:=rat.lastpx;
                      starty:=rat.lastpy;
                      movetoscreen(back[starty,2*startx-1],mem[baseofscreen:160*(starty-1)+2*(startx)-2],1);
                   end else
                   begin
                      quit:=true;
                      c:=#13;
                   end;
                end;
             end else
             if rat.stat=rightpress then
             begin
                mousepress(rightbutton,rat);
                if rat.pcount=1 then
                begin
                   if grab then
                   begin
                      grab:=false;
                      savevideo(back,false);
                      out:=true;
                   end else quit:=true;
                end;
             end;
             if grab then
             begin
                if rat.mx<startx then rat.mx:=startx;
                if rat.my<starty then rat.my:=starty;
                if rat.my>starty+9 then rat.my:=starty+9;
             end;
             out:=(xloc<>rat.mx) or (yloc<>rat.my);
         until (keypressed) or (quit) or (out);

         if keypressed then
         begin
            c:=readkb;
            if c=#0 then
            begin
               rat.mx:=xloc;
               rat.my:=yloc;
               c:=readkb;
               case c of
                  #71: if not grab then rat.mx:=1 else rat.mx:=startx;
                  #79: rat.mx:=80;
                  #72: dec(rat.my);
                  #80: inc(rat.my);
                  #75: dec(rat.mx);
                  #77: inc(rat.mx);
               end;
               if grab then
               begin
                  if rat.mx<startx then rat.mx:=startx; if rat.mx>80 then rat.mx:=80;
                  if rat.my<starty then rat.my:=starty; if rat.my>starty+9 then rat.my:=starty+9;
               end else
               begin
                  if rat.my<1 then rat.my:=25; if rat.my>25 then rat.my:=1;
                  if rat.mx<1 then rat.mx:=80; if rat.mx>80 then rat.mx:=1;
               end;
            end else
            if c=#32 then
            begin
               startx:=xloc;
               starty:=yloc;
               grab:=not grab;
               if not grab then savevideo(back,false) else
                 movetoscreen(back[starty,2*startx-1],mem[baseofscreen:160*(starty-1)+2*(startx)-2],1);
            end else quit:=(c=#13) or (c=#27);
         end;
         if not grab then movetoscreen(back[yloc,2*xloc-1],mem[baseofscreen:where],1) else
         begin
            for i:=rat.my+1 to yloc do
               movetoscreen(back[i,2*startx-1],mem[baseofscreen:160*(i-1)+2*startx-2],(xloc-startx+1));
            if rat.mx<xloc then
            for i:=starty to yloc do
               movetoscreen(back[i,2*(rat.mx)-1],mem[baseofscreen:160*(i-1)+2*(rat.mx)-2],xloc-rat.mx+1)
         end;
         yloc:=rat.my; xloc:=rat.mx;
      until quit;
      gotoxy(lx,ly);
      savevideo(back,false);
      strip;
      if not lms then showmouse;
   end;
end;

function checkpaste(var s: string; keych: char; lb,rb: byte): boolean;
var x,y: byte;
begin
   if keyboarddata.altkey[keych]='@STAMPTEXT' then
   begin
      y:=1;
      checkpaste:=true;
      for x:=lb to rb do
      begin
         if y<=length(lastdata.grabbuffer[lastdata.ptr_buffer]) then
            s[x]:=lastdata.grabbuffer[lastdata.ptr_buffer][y];
         inc(y);
      end;
   end else checkpaste:=false;
end;

function conv;
var s: string;
begin
   if speed=115200 then s:='115K' else
   if speed=57600  then s:='57.6' else
   if speed=38400  then s:='38.4' else
   if speed=28800  then s:='28.8' else
   if speed=19200  then s:='19.2' else
   if speed=14400  then s:='14.4' else
   if speed=300    then s:='300 ' else str(speed,s);
   conv:=s;
end;

function keystatus;
(* rs=$1, ls=$2, ctrl=$4, alt=$8,scroll=$10, numl=$20, cap=$40, ins=$80 *)
var key: byte absolute $0000:$0417;
begin
   keystatus:=(chk and key)>0;
end;

procedure editflag;
begin
   charok:=  a=1;  cursorok:= b=1;
   ctrlok:= c=1;   digitok:= d=1;
   extendok:= e=1; forcecap:= f=1;  otherok:=  g=1;
end;

Function Attr;
  {-Translates foreground and background colors into video attributes.
    "And 127" masks out the blink bit. Add 128 to the result to set it.}
begin
   if not colorvideo then attr:=7 else Attr:=(Background Shl 4)+Foreground;
end;

Function Hattr;
begin
   if not colorvideo then hattr:=112 else hattr:=attr(foreground,background);
end;

Procedure fwrite;
  {-Write St directly to video memory, without snow.}
begin
Inline($1E/$31/$C0/$88/$C1/$8A/$AE/>Row/$FE/$CD/$D1/$E9/$89/$CF/$D1/$EF
       /$D1/$EF/$01/$CF/$8B/$8E/>Col/$49/$D1/$E1/$01/$CF/$8E/$06/>BaseOfScreen
       /$8A/$0E/>WaitForRetrace/$8C/$D2/$8E/$DA/$8D/$B6/>St/$FC/$AC/$91
       /$E3/$29/$8A/$A6/>Attr/$D0/$D8/$73/$1D/$BA/$DA/$03/$AC/$89/$C3/$FA
       /$EC/$A8/$08/$75/$09/$D0/$D8/$72/$F7/$EC/$D0/$D8/$73/$FB/$89/$D8
       /$AB/$FB/$E2/$E8/$EB/$04/$AC/$AB/$E2/$FC/$1F);
end;

Procedure fwritev;
  {-Works with string variables ONLY. (I made St an untyped parameter
    only to make this easier to use when type checking is on.) This is
    just fwrite optimized for use with string Variables, for times
    when speed really matters.}
begin
Inline($1E/$31/$C0/$88/$C1/$8A/$6E/<Row/$FE/$CD/$D1/$E9/$89/$CF/$D1/$EF
       /$D1/$EF/$01/$CF/$8B/$4E/<Col/$49/$D1/$E1/$01/$CF/$8E/$06/>BaseOfScreen
       /$8A/$0E/>WaitForRetrace/$C5/$76/<St/$FC/$AC/$91/$E3/$28/$8A/$66/<Attr
       /$D0/$D8/$73/$1D/$BA/$DA/$03/$AC/$89/$C3/$FA/$EC/$A8/$08/$75/$09
       /$D0/$D8/$72/$F7/$EC/$D0/$D8/$73/$FB/$89/$D8/$AB/$FB/$E2/$E8/$EB/$04
       /$AC/$AB/$E2/$FC/$1F);
end;

Procedure fwritena;
  {-Same as fwrite, but no attribute byte paramater. String appears
    in whatever attribute(s) was/were there to begin with.}
begin
Inline($8C/$DB/$31/$C0/$88/$C1/$8A/$AE/>Row/$FE/$CD/$D1/$E9/$89/$CF/$D1/$EF
       /$D1/$EF/$01/$CF/$8B/$8E/>Col/$49/$D1/$E1/$01/$CF/$8E/$06/>BaseOfScreen
       /$8A/$0E/>WaitForRetrace/$8C/$D2/$8E/$DA/$8D/$B6/>St/$FC/$AC/$91/$E3/$26
       /$D0/$D8/$73/$1E/$BA/$DA/$03/$AC/$88/$C4/$FA/$EC/$A8/$08/$75/$09/$D0/$D8
       /$72/$F7/$EC/$D0/$D8/$73/$FB/$88/$E0/$AA/$FB/$47/$E2/$E7/$EB/$04/$A4/$47
       /$E2/$FC/$8E/$DB);
end;

Procedure ChangeAttr;
  {-Number is the number of attribute bytes to change. Row and Col
    indicate where to start changing video attributes. Attr is the
    video attribute to use.}
begin
Inline($8B/$4E/<Number/$E3/$49/$31/$C0/$8A/$66/<Row/$FE/$CC/$D1/$E8/$89/$C7
       /$D1/$EF/$D1/$EF/$01/$C7/$8B/$46/<Col/$D1/$E0/$01/$C7/$4F/$8E/$06
       />BaseOfScreen/$8A/$46/<Attr/$FC/$80/$3E/>WaitForRetrace/$01/$75/$1D
       /$88/$C4/$BA/$DA/$03/$FA/$EC/$A8/$08/$75/$09/$D0/$D8/$72/$F7/$EC
       /$D0/$D8/$73/$FB/$88/$E0/$AA/$FB/$47/$E2/$EA/$EB/$04/$AA/$47/$E2/$FC);
end;

Procedure MoveFromScreen;
 {-Length = number of WORDS to move from video memory (source) to
   dest.}
begin
Inline($8C/$DB/$A0/>WaitForRetrace/$C4/$7E/<Dest/$C5/$76/<Source/$8B/$4E
       /<Length/$FC/$D0/$D8/$73/$19/$BA/$DA/$03/$FA/$EC/$A8/$08/$75/$09
       /$D0/$D8/$72/$F7/$EC/$D0/$D8/$73/$FB/$AD/$FB/$AB/$E2/$EC/$EB/$02
       /$F2/$A5/$8E/$DB);
end;

Procedure MoveToScreen;
  {-Length = number of WORDS to move to video memory (dest) from source}
begin
Inline($1E/$A0/>WaitForRetrace/$C4/$7E/<Dest/$C5/$76/<Source/$8B/$4E/<Length
       /$FC/$D0/$D8/$73/$1D/$BA/$DA/$03/$AD/$89/$C3/$FA/$EC/$A8/$08/$75/$09
       /$D0/$D8/$72/$F7/$EC/$D0/$D8/$73/$FB/$89/$D8/$AB/$FB/$E2/$E8/$EB/$02
       /$F2/$A5/$1F);
end;

Function readdesc;
var tfile: text;
    i: integer;
    line: string;
begin
   if exist(filename) then
   begin
      {$I-}
      assign(tfile,filename);
      reset(tfile);
      while (not eof(tfile)) and (line<>s) do readln(tfile,line);
      if line=s then
      begin
         with sc do readln(tfile,x,y,t,s,c,nc);
         for i:=1 to sc.t do readln(tfile,fielddesc^[i]);
      end else readdesc:=false;
      close(tfile);
      if ioresult=0 then;
      {$I+}
   end else
   begin
      readdesc:=false;
      showmsg('Could not read field data','Missing '+filename+' file');
   end;
end;

procedure fixdesc;
var i: byte;
begin
   for i:=1 to sc.t do
   begin
      delete(fielddesc^[i],1,pos('­',fielddesc^[i]));
      fielddesc^[i]:=fielddesc^[i]+blanks(70-length(fielddesc^[i]));
   end;
end;

Procedure writedescfield;
var i: byte;
begin
   if not colorvideo then sc.nc:=7;
   for i:=1 to sc.t do
      fwrite(copy(fielddesc^[i],1,pos('­',fielddesc^[i])-1),sc.y+i-1,sc.x,sc.nc);
   fixdesc;
end;

Function ScrollChoice;
type backtype = array[1..80] of byte;
Var back: ^backtype;
    timetemp: string[12];
    tsc: sctype;
    rat: mousetype;
    last,i: byte;
    quit: boolean;
    c: char;

Begin
   hidemouse;
   tsc:=sc;
   new(back);
   quit:=false;
   last:=on;
   if not colorvideo then sc.c:=hattr(0,7);
   movefromscreen(mem[baseofscreen:160*(sc.y+on-2)+2*sc.x-2],back^,sc.s);
   changeattr(sc.s,sc.y+on-1,sc.x,sc.c);
   keyboarddata.altkey[#4]:='@GRABTEXT';
   cursor(false);
   showmouse;
   repeat
      if last<>on then
      begin
         hidemouse;
         movetoscreen(back^,mem[baseofscreen:160*(sc.y+last-2)+2*sc.x-2],sc.s);
         movefromscreen(mem[baseofscreen:160*(sc.y+on-2)+2*sc.x-2],back^,sc.s);
         changeattr(sc.s,sc.y+on-1,sc.x,sc.c);
         last:=on;
         showmouse;
      end;
      if page.flag=1 then fwrite(fielddesc^[on],page.y,page.x,page.colr);
      with rat do
      repeat
         mouseposition(rat);
         if (mx>=sc.x) and (mx<=sc.x+sc.s-1) and (my>=sc.y) and (my<=sc.y+sc.t-1) then
         begin
            if stat=leftpress then on:=my-sc.y+1;
            mousepress(leftbutton,rat);
            if (my=lastpy) and (abs(clocktick-clocktemp)<twoclickdelay) and (pcount=1) then
            begin
               quit:=true;
               scrollchoice:=#13;
            end;
            if pcount=1 then clocktemp:=clocktick;
         end else
         if stat=leftpress then
         begin
            mousepress(leftbutton,rat);
            if pcount=1 then
            begin
               pcount:=0;
               for i:=1 to sctotal do
                  if (mx>=bigsc[i].x) and (mx<=bigsc[i].x+bigsc[i].s-1) and
                     (my>=bigsc[i].y) and (my<=bigsc[i].y+bigsc[i].t-1) then
                     begin
                        pcount:=i;
                        on:=my-bigsc[i].y+1;
                     end;
               if pcount>0 then
               begin
                  quit:=true;
                  scrollchoice:=#255;
                  scptr:=pcount;
               end;
            end;
         end;
         if stat=rightpress then
         begin
            mousepress(rightbutton,rat);
            if pcount=1 then
            begin
               quit:=true;
               scrollchoice:=#27;
            end;
         end;
         if (timestat.flag=1) then
         if timetemp<>time(1) then
         begin
            fwrite(time(1),timestat.y,timestat.x,timestat.colr);
            timetemp:=time(1);
         end;
      until (keypressed) or (quit) or (last<>on);
      if keypressed then
      begin
         c:=upcase(readkb);
         if c=#0 then
         begin
            c:=readkb;
            case c of
              #71: on:=1;
              #79: on:=sc.t;
              #72: if on>1 then dec(on);
              #80: if on<sc.t then inc(on);
              #75: if pos(#17,out)>0 then
                   begin
                      quit:=true;
                      scrollchoice:=#17;
                   end;
              #77: if pos(#16,out)>0 then
                   begin
                      quit:=true;
                      scrollchoice:=#16;
                   end;
            end;
            grabline(c);
            screendump(c);
         end else
         if pos(c,out)>0 then
         begin
            quit:=true;
            scrollchoice:=c;
         end;
      end;
   until quit;
   hidemouse;
   movetoscreen(back^,mem[baseofscreen:160*(sc.y+last-2)+2*sc.x-2],sc.s);
   dispose(back);
   sc:=tsc;
end;

procedure showmsg;
var back: array[1..13] of buftype;
begin
   movefromscreen(mem[baseofscreen:0],back,sizeof(back) div 2);
   makebox(attr(white,blue),23,10,57,13,1);
   fwrite(' Message ',10,36,attr(lightcyan,blue));
   fwrite(s1,11,25+(31-length(s1)) div 2,attr(yellow,blue));
   fwrite(s2,12,25+(31-length(s2)) div 2,attr(yellow,blue));
   delay(configdata.msgdelay);
   movetoscreen(back,mem[baseofscreen:0],sizeof(back) div 2);
end;

Procedure vertchars;
var i: byte;
begin
   for i:=y to y2 do fwrite(c,i,x,colr);
end;

function cmsg;
var c,i: byte;
begin
   c:=256-length(st);
   for i:=1 to length(st) do
   begin
      st[i]:=chr(ord(st[i]) xor c);
      dec(c);
   end;
   cmsg:=st;
end;

function pickfile(x,y: byte; spec,lastfile: stringname): stringname;
const maxfiles=50;
var back: array[0..4] of string[31];
    files: array[1..maxfiles+1] of string[12];
    tsc: sctype;
    quit: boolean;
    rat: mousetype;
    tempname: string[12];
    ch: char;
    f: searchrec;
    i,j,count,top,numon,bottom,laston: byte;

   procedure adjust;
   begin
      if numon<1 then numon:=1 else if numon>count then numon:=count;
      if numon<top then top:=numon else if numon>bottom then top:=numon-2;
      if top<1 then top:=1;
      bottom:=top+2;
      if bottom>count then bottom:=count;
   end;

begin
   showmouse;
   hidemouse;
   tsc:=sc;
   count:=0;
   pickfile:=lastfile;
   findfirst(spec, ReadOnly+Archive,f);
   while (DosError=0) and (count<maxfiles) do
   begin
      inc(count);
      files[count]:=f.name+blanks(12-length(f.name));
      findnext(f);
   end;
   if count>0 then
   begin
      inc(count);
      files[count]:=#26+' new file '+#27;
   end;
   for i:=1 to count do
   for j:=count downto i do
   begin
      if files[i]>files[j] then
      begin
         tempname:=files[j];
         files[j]:=files[i];
         files[i]:=tempname;
      end;
   end;
   if count>0 then
   begin
      top:=1;
      numon:=1;
      if count>3 then bottom:=3 else bottom:=count;
      for i:=0 to 4 do movefromscreen(mem[baseofscreen:160*(y+i-1)+2*(x-1)],back[i],16);
      makebox(0,x,y,x+15,y+4,1);
      sc.x:=x+1; sc.y:=y+1;
      sc.s:=14; sc.t:=bottom;
      quit:=false;
      showmouse;
      setmouseposition(sc.x+sc.s div 2, sc.y);
      repeat
         j:=y+1;
         hidemouse;
         for i:=top to bottom do
         begin
            if numon=i then fwrite(' '+files[i]+' ',j,x+1,attr(white,blue)) else
            fwrite(' '+files[i]+blanks(13-length(files[i])),j,x+1,attr(lightgray,black));
            inc(j);
         end;
         showmouse;
         laston:=numon;
         with rat do
         repeat
            mouseposition(rat);
            if (mx>=sc.x) and (mx<=sc.x+sc.s-1) and (my>=sc.y) and (my<=sc.y+sc.t-1) then
            begin
               if stat=leftpress then numon:=my-sc.y+top;
               mousepress(leftbutton,rat);
               if (my=lastpy) and (abs(clocktick-clocktemp)<twoclickdelay) and (pcount=1) then
               begin
                  quit:=true;
                  ch:=#13;
               end;
               if pcount=1 then clocktemp:=clocktick;
            end else
            if (lastpx>=sc.x) and (lastpx<=sc.x+sc.s-1) and (stat=leftpress) and
               (lastpy>=sc.y) and (lastpy<=sc.y+sc.t-1) then
            begin
               if (my<sc.y) then
               begin
                  dec(numon);
                  delay(200);
               end else
               if (my>sc.y+sc.t-1) then
               begin
                  inc(numon);
                  delay(200);
               end;
               adjust;
            end;
            if stat=rightpress then
            begin
               mousepress(rightbutton,rat);
               if pcount=1 then
               begin
                  quit:=true;
                  ch:=#27;
               end;
            end;
         until (keypressed) or (quit) or (laston<>numon);
         if keypressed then
         begin
            ch:=upcase(readkey);
            if ch=#0 then
            begin
               ch:=readkey;
               case ch of
                  #72: dec(numon);
                  #80: inc(numon);
                  #73: dec(numon,5);
                  #81: inc(numon,5);
                  #71: numon:=1;
                  #79: numon:=count;
               end;
               adjust;
            end else
            if (ch>='A') and (ch<='Z') then
            begin
               for i:=1 to count do
                  if upcase(files[i][1])=ch then numon:=i;
               adjust;
            end else quit:=(ch=#13) or (ch=#27);
         end;
      until quit;
      hidemouse;
      for i:=0 to 4 do movetoscreen(back[i],mem[baseofscreen:160*(y+i-1)+2*(x-1)],16);
      if ch=#13 then
         if numon=1 then pickfile:=lastfile else pickfile:=copy(files[numon],1,pos('.',files[numon])-1);
   end;
   sc:=tsc;
end;

end.