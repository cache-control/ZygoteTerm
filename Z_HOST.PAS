unit z_host;

interface
{$F+,O+}

Procedure Loadhost;

implementation

uses Z_util,z_comio,Crt,Dos;

const  ufname='Z_HOST.USR';
       mfname='Z_HOST.MSG';
       linesize = 79;
type   usertype=record
           name: stringname;
           password: stringpw;
           messageon: integer;
           useransi: boolean;
           access: byte;
       end;
       messagetype=record
           forwhom,from,subject: stringname;
           timedate: string[26];
           line: array[1..51] of string[linesize];
           lastline: byte;
           private: boolean;
       end;

var userfile: file of usertype;
    userdata: ^usertype;
    messagefile: file of messagetype;
    messagedata: ^messagetype;
    lastmode: char;
    lineon,lastfore,lastback: byte;
    local,echoback,zygoteuser,more,quithost: boolean;
    currentdir,path: ^string80;
    lastcheck,totalcalls: integer;

Procedure ansic(fg,bg: byte);
var s: string[20];
    f,b: string[2];
    mode: char;
begin
   if (_CD) and (userdata^.useransi) then
   begin
      if fg in [black..lightgray] then mode:='0' else mode:='1';
      case fg of
        black,darkgray: f:='30'; green,lightgreen: f:='32'; red,lightred: f:='31';
        brown,yellow: f:='33';   blue,lightblue: f:='34';   cyan,lightcyan: f:='36';
        magenta,lightmagenta: f:='35'; lightgray,white: f:='37';
      end;
      case bg of
        black: b:='40'; blue: b:='44'; green: b:='42'; cyan: b:='46'; red: b:='41';
        magenta: b:='45'; brown: b:='43'; lightgray: b:='47';
      end;
      if mode=lastmode then s:='[' else
      begin
         s:='['+mode+';';
         lastmode:=mode;
      end;
      if fg=lastfore then f:='';
      if bg=lastback then b:='';
      if (f=b) and (f='') then s:='' else
      begin
         s:=s+f;
         if (b>'') and (f>'') then s:=s+';';
         if b='' then s:=s+'m' else s:=s+b+'m';
      end;
      _putstring(s);
   end;
   color(fg,bg);
   lastfore:=fg; lastback:=bg; lastmode:=mode;
end;

Function logoff: boolean;
begin
   logoff:=((Not _cd) and (not local)) or (quithost);
end;

Procedure print(s: string);
begin
   if not logoff then
   begin
      if _cd then _putstring(s);
      write(s);
   end;
end;

Procedure println(s: string);
begin
   print(s+#13+#10);
end;

Procedure cls;
begin
   if _cd then _put(12);
   clrscr;
end;

Procedure init;
begin
   echoback:=false;
   more:=true;
   lineon:=0;
   with userdata^ do
   begin
      name:='';
      password:='';
      messageon:=1;
      useransi:=false;
      access:=0;
   end;
end;

Procedure showstatus;
var lx,ly: byte;
begin
   if not logoff then
   begin
      lx:=wherex; ly:=wherey;
      color(9,1);
      window(1,1,80,25);
      makebox(attr(9,1),1,1,40,5,3);
      makebox(attr(9,1),41,1,80,5,3);
      xy(5,1,'´ Alt-S = Setup         Ã'); xy(45,1,'´ Alt-E = Toggle access Ã');
      xy(5,5,'´ Alt-A = Toggle Ansi   Ã'); xy(45,5,'´ Alt-C = Chatmode      Ã');
      color(15,1);
      xy(5,2,'User : ');      xy(45,2,'Acc(E)ss : ');
      xy(5,3,'Password : ');  xy(45,3,'Messageon : ');
      xy(5,4,'(A)nsi : ');      xy(45,4,'Zygote Version : ');
      color(7,1);
      xy(12,2,userdata^.name);
      xy(16,3,userdata^.password);
      gotoxy(14,4); write(userdata^.useransi);
      xy(56,2,its(userdata^.access));
      xy(57,3,its(userdata^.messageon));
      xy(62,4,cmsg(zversion));
      window(1,6,80,25);
      gotoxy(lx,ly);
      ansic(lastfore,lastback);
   end;
end;

Procedure editconfig;
var c: char;
    lx,ly,sx,on,m,colr: byte;
    s: string[25];

    procedure addbl(var s: string80);
    begin
       if s[length(s)]<>'\' then s:=s+'\';
    end;

begin
   m:=0;
   on:=1;
   print('[Hold]');
   lx:=wherex; ly:=wherey;
   color(yellow,blue);
   window(1,1,80,5);
   clrscr;
   xy(5,1,'Upload directory  : ');
   xy(5,2,'Dnload directory  : ');
   xy(5,3,'Showdown password : ');
   xy(5,4,'Level 1 password  : ');
   xy(5,5,'Closed system PW  : ');
   sx:=wherex;
   editflag(1,1,0,1,1,1,1);
   repeat
      colr:=attr(lightgray,blue);
      fwrite(copy(configdata.hupdir,1,50)+blanks(50-length(configdata.hupdir)),1,sx,colr);
      fwrite(copy(configdata.hdndir,1,50)+blanks(50-length(configdata.hdndir)),2,sx,colr);
      fwrite(configdata.hshutdown+blanks(20-length(configdata.hshutdown)),3,sx,colr);
      fwrite(configdata.hlevel+blanks(20-length(configdata.hlevel)),4,sx,colr);
      fwrite(configdata.haccess+blanks(20-length(configdata.haccess)),5,sx,colr);
      colr:=attr(white,red);
      case on of
        1: begin
              c:=input(colr,sx,on,configdata.hupdir,40,40,m);
              addbl(configdata.hupdir);
           end;
        2: begin
              c:=input(colr,sx,on,configdata.hdndir,40,40,m);
              addbl(configdata.hdndir);
           end;
        3: c:=input(colr,sx,on,configdata.hshutdown,20,20,m);
        4: c:=input(colr,sx,on,configdata.hlevel,20,20,m);
        5: c:=input(colr,sx,on,configdata.haccess,20,20,m);
      end;
      if c in ['U','P'] then dec(on) else
      if c in ['D','N'] then inc(on) else
      if c=#13 then
      begin
         m:=1;
         inc(on);
      end;
      if on<1 then on:=5;
      if on>5 then on:=1;
   until c=#27;
   window(1,6,80,25);
   gotoxy(lx,ly);
   showstatus;
   ansic(lastfore,lastback);
   for sx:=1 to 6 do print(#8+' '+#8);
end;

Procedure chatmode;
const hostc = yellow;
      userc = lightred;
var c: char;
    exitchat: boolean;
    line: string[linesize];
    x,lastf,lastb,lastspace: byte;

begin
   lastf:=lastfore;
   lastb:=lastback;
   exitchat:=false;
   line:='';
   ansic(lightcyan,black);
   println('');
   println('ÄÄÄÄÄÍÍÍÍÍµ Entering chat /w the host operator '+configdata.username+' ³');
   println('');
   repeat
       repeat
       until (logoff) or (keypressed) or (_rx_ready);
       if keypressed then
       begin
          c:=readkb;
          if c=#0 then
          begin
             c:=readkb;
             exitchat:= c = #46;
          end else ansic(hostc,lastback);
       end else
       if _rx_ready then
       begin
          c:=chr(_get);
          ansic(userc,lastback);
       end;
       if (not logoff) and (not exitchat) then
       case c of
          #0 : ;
          #8 : begin
                  delete(line,length(line),1);
                  print(^h+' '+^h);
               end;
          #10,
          #13: begin
                  println('');
                  line:='';
               end;
          ^X : begin
                  for x:=length(line) downto 1 do print(^h+' '+^h);
                  line:='';
               end;
          #27: ;
          else if c>#31 then
               begin
                  line:=line+c;
                  if length(line)=linesize then
                  begin
                     lastspace:=linesize;
                     while (line[lastspace]<>' ') and (lastspace>1) do dec(lastspace);
                     line:=copy(line,lastspace+1,linesize-lastspace);
                     for x:=linesize downto lastspace+1 do print(^h+' '+^h);
                     println('');
                     print(line);
                  end else print(c);
               end;
       end;
   until (logoff) or (exitchat);
   ansic(lightcyan,lastback);
   println('');
   println('ÄÄÄÄÄÍÍÍÍÍµ Escaping chat /w the host operator '+configdata.username+' ³');
   println('');
   ansic(lastf,lastb);
end;

Function key: char;
var c: char;
begin
   repeat
     repeat
     until (_rx_ready) or (keypressed) or (logoff);
     if _rx_ready then key:=chr(_get);
     if keypressed then
     begin
       c:=readkb;
       if c=#0 then
       begin
         key:=#0;
         c:=readkb;
         case c of
           #18: begin
                  if userdata^.access=0 then userdata^.access:=1 else userdata^.access:=0;
                  showstatus;
                end;
           #30: begin
                  userdata^.useransi:=not userdata^.useransi;
                  showstatus;
                end;
           #31: editconfig;
           #45: quithost:=true;
           #46: chatmode;
         end;
         c:=#0;
       end else key:=c;
     end;
   until (logoff) or (c<>#0);
end;

Function moreprompt: boolean;
var lf: byte;
    lm: byte;
begin
   if (keypressed) or (_rx_ready) then
   begin
      moreprompt:= not (upcase(key) in [' ','S',#27]);
   end else moreprompt:=true;
   if more then
   begin
     inc(lineon);
     if lineon=19 then
     begin
        lineon:=0;
        lf:=lastfore;
        ansic(lightmagenta,lastback);
        print('More (Y/n)? ');
        ansic(lf,lastback);
        moreprompt:=upcase(key) <> 'N';
        print(#13+'            '+#13);
     end;
   end;
end;

Procedure sendfile(s: string);
var nullfile: text;
    line: string;
begin
   lineon:=0;
   if userdata^.useransi then s:=dir_host+'\'+s+'.ANS' else s:=dir_host+'\'+s+'.ASC';
   ansic(white,lastback);
   if exist(s) then
   begin
     assign(nullfile,s);
     reset(nullfile);
     while (not eof(nullfile)) and (moreprompt) do
     begin
        readln(nullfile,line);
        println(line);
     end;
     close(nullfile);
   end else println(#13+#10+'Hostop error = Missing '+s+' file.'+#13+#10);
end;

Function getyn: boolean;
begin
   if not logoff then
   begin
      if upcase(key)='Y' then
      begin
         ansic(lightgreen,lastback);
         println('Yes');
         getyn:=true;
      end else
      begin
         ansic(lightred,lastback);
         println('No');
         getyn:=false;
      end;
   end;
end;

Procedure getinput(var s: string; max: byte);
var on: byte;
    ch: char;
begin
   s:='';
   print(blanks(max));
   for on:=1 to max do print(^h);
   on:=1;
   repeat
      ch:=key;
      if ch<>#0 then
      begin
         case ch of
           #8 : if on>1 then
                begin
                   dec(on);
                   print(^h+' '+^h);
                   delete(s,length(s),1);
                end;
           #13,
           #27: ch:=ch;
           else if on<=max then
                begin
                   inc(on);
                   if _cd then if echoback then _put(22) else _put(ord(ch));
                   write(ch);
                   s:=s+ch;
                end;
         end;
      end;
   until (ch=#13) or (logoff);
   while (s[1]=' ') and (s>'') do delete(s,1,1);
   while (s[length(s)]=' ') and (s>'') do delete(s,length(s),1);
   ansic(lastfore,black);
   println('');
end;

Procedure handlefile(open: boolean);
begin
   if open then
   begin
      assign(userfile,dir_host+'\'+ufname);
      assign(messagefile,dir_host+'\'+mfname);
      if exist(dir_host+'\'+ufname) then reset(userfile) else rewrite(userfile);
      if exist(dir_host+'\'+mfname) then reset(messagefile) else rewrite(messagefile);
   end else
   begin
      close(userfile);
      close(messagefile);
   end;
end;

Function validuser: boolean;
var c: char;
    lt: string[8];
    attempt: byte;
    x: integer;
    newuser: boolean;
    temp: usertype;

begin
   if not logoff then
   begin
     x:=3; c:=#0; attempt:=1;
     if _cd then
     begin
        _putstring('#ZYGOTE­');
        repeat
           if _rx_ready then c:=chr(_get);
           if lt<>time(0) then
           begin
              lt:=time(0);
              dec(x);
           end;
        until (x=0) or (c=#2);
        zygoteuser:= c = #2;
     end else zygoteuser:=true;
     showstatus;
     newuser:=true;
     window(1,6,80,25);
     ansic(lightgray,black);
     cls;
     if zygoteuser then println('ó Welcome Zygote User @'+conv(dparam.speed)+' baud ò')
     else println('ó Welcome Non-Zygote User @'+conv(dparam.speed)+' baud ò');
     println('');
     print('Can you support ANSI graphics? ');
     userdata^.useransi:=getyn;
     more:=false;
     sendfile('INITSCR');
     println('');
     showstatus;
     if not configdata.hopen then
     repeat
        ansic(7,black);
        print('Host PW: ');
        getinput(temp.password,20);
        temp.password:=caps(temp.password);
        if temp.password=configdata.haccess then attempt:=1 else inc(attempt);
     until (logoff) or (attempt=1) or (attempt=5);
     if attempt=1 then
     repeat
       ansic(lightgray,black);
       println('[Attempt = '+its(attempt)+'/4]');
       ansic(yellow,black);
       print('Name: ');
       ansic(white,blue);
       getinput(userdata^.name,25);
       userdata^.password:='';
       userdata^.name:=caps(userdata^.name);
       if userdata^.name<>'' then
       begin
         x:=1;
         if filesize(userfile)=0 then newuser:=true else
         repeat
            {$I-}
            seek(userfile,x-1);
            read(userfile,temp);
            if ioresult=0 then;
            {$I+}
            newuser:= temp.name<>userdata^.name;
            lastcheck:=x;
            inc(x);
         until (x>filesize(userfile)) or (not newuser);
         if not newuser then userdata^:=temp;
         showstatus;
         If newuser then
         begin
           ansic(lightred,black);
           println('');
           println('');
           println('Could not locate your account.');
           ansic(lightblue,black);
           print('Did you enter your name correctly, '+userdata^.name+'? ');
           if getyn=true then
           begin
             newuser:=false;
             repeat
               ansic(yellow,black);
               print('Enter a password: ');
               ansic(white,blue);
               getinput(userdata^.password,20);
               userdata^.password:=caps(userdata^.password);
             until (logoff) or (userdata^.password<>'');
             if not logoff then
             begin
               ansic(lightgreen,black);
               println('<NewUser> Saving your account...');
               {$I-}
               seek(userfile,filesize(userfile));
               write(userfile,userdata^);
               if ioresult=0 then;
               {$I+}
               lastcheck:=filesize(userfile);
             end;
           end;
         end else
         begin
           ansic(yellow,black);
           print('Pwd:  ');
           ansic(white,blue);
           echoback:=true;
           getinput(userdata^.password,20);
           echoback:=false;
           userdata^.password:=caps(userdata^.password);
           {$I-}
           seek(userfile,lastcheck-1);
           read(userfile,temp);
           if ioresult=0 then;
           {$I+}
           newuser:= temp.password<>userdata^.password;
           if newuser then
           begin
              ansic(lightred,black);
              println('Incorrect password, '+userdata^.name+'.');
           end;
         end;
         if newuser then println('');
       end;
       inc(attempt);
     until (logoff) or (not newuser) or (attempt=5);
   end;
   validuser:= (not logoff) and (not newuser);
end;

Procedure waiting;
type str3 = string[3];
var s: string;
    x,ringcnt,on,
    colr,lo,lx,ly: byte;
    c,tempc: char;

    Function checkstr(s: string): string;
    var x,y: byte;
    begin
       y:=0;
       checkstr:='HOSTMODE';
       for x:=1 to 14 do if pos(configdata.results[x],s)>0 then y:=x;
       case y of
          1: checkstr:='';             2: checkstr:='';
          3: checkstr:='RING';         4: checkstr:='';           5: checkstr:='';
          6: dparam.speed:=300;        7: dparam.speed:=1200;     8: dparam.speed:=2400;
          9: dparam.speed:=4800;      10: dparam.speed:=9600;    11: dparam.speed:=14400;
         12: dparam.speed:=19200;     13: dparam.speed:=28800;   14: dparam.speed:=38400;
         15: dparam.speed:=57600;
         else checkstr:='';
       end;
    end;

   procedure button(st: str3; x,y: byte; out: boolean);
   var color1,color2: byte;
   begin
      if out then
      begin
         color1:=attr(darkgray,cyan);
         color2:=attr(white,cyan);
      end else
      begin
         color1:=attr(white,cyan);
         color2:=attr(darkgray,cyan);
      end;
      makebox(color1,x,y,x+4,y+2,1);
      changeattr(4,y,x,color2);
      changeattr(1,y+1,x,color2);
      changeattr(1,y+2,x,color2);
      if out then fwrite(st,y+1,x+1,attr(black,cyan));
   end;

    procedure drawboxes;
    var colr: byte;
    begin
       colr:=attr(white,cyan);
       makebox(colr,1,1,80,14,1);   fwritena('´             Ã',1,3);
       makebox(colr,1,15,54,25,1);  fwritena('´             Ã',15,3);
       makebox(colr,55,15,80,25,1); fwritena('´             Ã',15,57);
       fwritena('Â',15,24);  fwritena('Á',25,24);
       for colr:=16 to 24 do fwritena('³',colr,24);
       fwritena('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´',22,1);
       fwritena('ÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂ',22,35); fwritena('³              ³',23,35);
       fwritena('³              ³',24,35); fwritena('ÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁ',25,35);
       colr:=attr(white,blue);      fwrite(' Modem watch ',1,4,colr);
       fwrite(' Host setup  ',15,4,colr);  fwrite(' Key command ',15,58,colr);
       colr:=attr(blue,cyan);
       fwrite('# of callers today',23,3,colr);  fwrite('Parameters',24,3,colr);
       fwrite('Ring counter',23,37,colr);  fwrite('Answer',24,37,colr);
       fwrite('Quit Hostmode',17,63,colr);  fwrite('Logon locally',20,63,colr);
       fwrite('Edit setup',23,63,colr);
       button('Esc',57,16,true);  button(' L ',57,19,true); button(' E ',57,22,true);
       colr:=attr(yellow,cyan);
       fwrite('Upload directory',16,3,colr);
       fwrite('Download directory',17,3,colr);
       fwrite('Shutdown PWD',18,3,colr);
       fwrite('Level 1 PWD',19,3,colr);
       fwrite('Closed system PWD',20,3,colr);
       fwrite('Closed system toggle',21,3,colr);
       sc.x:=2; sc.y:=16; sc.t:=6; sc.s:=22;
       sc.c:=attr(black,lightgray); sc.nc:=attr(yellow,cyan);
       colr:=attr(lightcyan,cyan);
       with configdata do
       begin
          fwrite(copy(hupdir,1,27),16,26,colr);
          fwrite(copy(hdndir,1,27),17,26,colr);
          fwrite(hshutdown,18,26,colr);
          fwrite(hlevel,19,26,colr);
          fwrite(haccess,20,26,colr);
          if hopen then fwrite('Open',21,26,colr) else fwrite('Close',21,26,colr);
       end;
       colr:=attr(red,cyan);
       fwrite('0',23,52,colr);
       fwrite(its(configdata.hostring),24,52,colr);
       fwrite(its(totalcalls),23,26,colr);
       with dparam do fwrite(its(speed)+parity+its(dbit)+its(sbit),24,26,colr);
    end;
   procedure writest(x,y,size: byte; st: string);
   begin
      st:=copy(st,1,size);
      fwrite(st+blanks(size-length(st)),y,x,colr);
   end;

begin
   s:='';
   quithost:=false;
   page.flag:=0;
   if not _cd then
   begin
      dparam:=configdata.param;
      with dparam do _set_param(speed,parity,dbit,sbit);
      send('^MATS0=0^M');
   end;
   drawboxes;
   window(2,2,79,13);
   x:=0;
   cursor(true);
   ringcnt:=0;
   color(black,cyan);
   repeat
     if ringcnt=configdata.hostring then
     begin
        send(configdata.answerstr);
        ringcnt:=0;
     end;
     while _rx_ready do
     begin
        c:=chr(_get);
        s:=s+c;
        write(c);
        if c=#13 then
        begin
           if checkstr(s)='RING' then
           begin
              inc(ringcnt);
              fwrite(its(ringcnt),23,52,attr(red,cyan));
           end;
           if checkstr(s)='HOSTMODE' then x:=1;
           s:='';
        end;
        if length(s)=254 then s:='';
     end;
     if keypressed then
     case upcase(readkb) of
        'E': begin
                on:=1;
                button(' E ',57,22,false);
                lx:=wherex; ly:=wherey;
                window(1,1,80,25);
                editflag(1,1,0,1,0,1,1);
                repeat
                    colr:=attr(lightcyan,cyan);
                    with configdata do
                    begin
                       writest(26,16,27,hupdir);
                       writest(26,17,27,hdndir);
                       writest(26,18,20,hshutdown+'');
                       writest(26,19,20,hlevel+'');
                       writest(26,20,20,haccess+'');
                       if hopen then fwrite('Open ',21,26,colr) else fwrite('Close',21,26,colr);
                    end;
                    tempc:=scrollchoice(#27+#13,on);
                    lo:=0;
                    colr:=hattr(white,red);
                    if tempc=#13 then
                      with configdata do
                      case on of
                         1: if input(colr,26,16,hupdir,40,27,lo)=' ' then;
                         2: if input(colr,26,17,hdndir,40,27,lo)=' ' then;
                         3: if input(colr,26,18,hshutdown,20,20,lo)=' ' then;
                         4: if input(colr,26,19,hlevel,20,20,lo)=' ' then;
                         5: if input(colr,26,20,haccess,20,20,lo)=' ' then;
                         6: hopen:=not hopen;
                      end;
                until tempc=#27;
                window(2,2,79,13);
                gotoxy(lx,ly);
                button(' E ',57,22,true);
             end;
        'L': begin
                x:=1;
                button(' L ',57,19,false);
                delay(300);
             end;
        #27: begin
                x:=1;
                button('Esc',57,16,false);
                delay(300);
                quithost:=true;
             end;
        else x:=0;
     end;
   until x=1;
   cursor(true);
   local:=not _cd;
   with dparam do _set_param(speed,parity,dbit,sbit);
end;

Procedure toggleansi;
begin
   userdata^.useransi:=not userdata^.useransi;
   ansic(white,black);
   println('');
   print('[ANSI] graphics: ');
   ansic(yellow,black);
   if userdata^.useransi then println('ON') else println('OFF');
   showstatus;
end;

Procedure callsysop;
var I,J: Byte;
begin
   ansic(lightred,black);
   println('');
   if not keystatus($10) then
   begin
     print('Please wait...Calling the host operator');
     ansic(yellow,black);
     J:=0;
     repeat
       inc(J);
       for I := 1 to 100 do
       begin
         Sound(1000);
         Delay(10);
         NoSound;
       end;
       Delay(800);
       print('!');
     until (J>5) or (keypressed) or (_rx_ready) or (logoff);
     if (keypressed) or (_rx_ready) then i:=ord(key);
     if j>5 then print(#10+#13+'The operator will break in if he is here.');
   end else
   begin
      println('The host operator is not available.');
      showmsg('Turn the SCROLL LOCK key off','to allow user to call Hostop');
   end;
   println('');
end;

Procedure listusers;
var x,sx: integer;
    temp: usertype;
begin
   x:=1;
   sx:=filesize(userfile);
   lineon:=4;
   ansic(lightgray,black);
   println('');
   println('ÄÄÍÍµ Users on the hosting system ³');
   println('');
   ansic(yellow,black);
   while (moreprompt) and (x<=sx) do
   begin
      {$I-}
      seek(userfile,x-1);
      read(userfile,temp);
      if ioresult=0 then;
      {$I+}
      if x=lastcheck then
      begin
         ansic(white,blue);
         print(temp.name+blanks(25-length(temp.name)));
         ansic(lightgreen,black);
         println('');
      end else println(temp.name+blanks(25-length(temp.name)));
      inc(x);
   end;
end;

Procedure GetCommand;
var
  I,J: Integer;
  Attr: Word;
  S,D,N,E: string;
  F: File;
begin
  path^ := FExpand(path^);
  if path^[Length(path^)] <> '\' then
  begin
    Assign(F, path^);
    GetFAttr(F, Attr);
    if (DosError = 0) and (Attr and Directory <> 0) then path^ := path^ + '\';
  end;
  FSplit(path^, D, N, E);
  if N = '' then N := '*';
  if E = '' then E := '.*';
  currentdir^:=d;
  path^ := D + N + E;
end;

Procedure listdirs;
const
  MonthStr: array[1..12] of string[3] = (
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

var
  c: char;
  Count: Integer;

Function NumStr(N, D: Integer): String;
begin
  NumStr[0] := Chr(D);
  while D > 0 do
  begin
    NumStr[D] := Chr(N mod 10 + Ord('0'));
    N := N div 10;
    Dec(D);
  end;
end;

Procedure FindFiles;
var
  killfile: file;
  total: longint;
  F: SearchRec;
  P,kills: integer;
  N,E: string;
  T: datetime;
begin
  kills:=0;
  total:=0;
  Count := 0;
  lineon:=2;
  ansic(white,lastback);
  println('');
  println('Directory of: '+path^);
  FindFirst(path^, ReadOnly + Directory + Archive, F);
  while (DosError = 0) and (moreprompt) do
  with f do
  begin
    P := Pos('.', Name);
    if P > 1 then
    begin
      N := Copy(Name, 1, P - 1);
      E := Copy(Name, P + 1, 3);
    end else
    begin
      N := Name;
      E := '';
    end;
    ansic(lightgreen,lastback);
    print(N+ ' '+blanks(9 - Length(N))+ E+ ' '+blanks(4 - Length(E)));
    ansic(lightred,lastback);
    if Attr and Directory <> 0 then print('<DIR>   ') else
    begin
      print(blanks(8-length(its(size)))+its(Size));
      UnpackTime(Time, T);
      ansic(lightcyan,lastback);
      print(blanks(5-length(its(t.day)))+its(T.Day)+'-'+
            MonthStr[T.Month]+ '-'+
            NumStr(T.Year mod 100, 2)+
            blanks(4-length(its(t.hour)))+its(T.Hour)+ ':'+
            NumStr(T.Min, 2)+' ');
    end;
    println('');
    Inc(Total, Size);
    FindNext(F);
    inc(count);
  end;
  ansic(white,lastback);
  if count=0 then println('No matching files') else
  printLn(#13+#10+blanks(5)+its(Count)+ ' files, '+ its(Total)+ ' bytes, '+its(DiskFree(Ord(path^[1])-64))+ ' bytes free'+#13);
  println('');
end;

begin
  ansic(lightgray,black);
  cls;
  println('');
  println('ÄÄÄÍÍÍµ Choose a directory to list. ³');
  ansic(yellow,lastback);
  println('');
  println('U)pload directory');
  println('D)ownload directory');
  if userdata^.access=1 then println('O)ther directory');
  println('');
  print(': ');
  c:=upcase(key);
  if (c in ['U','D']) or ((c='O') and (userdata^.access=1)) then
  begin
     println(c);
     println('');
     case c of
       'U': path^:=configdata.hupdir;
       'D': path^:=configdata.hdndir;
       'O': begin
               print('Path = ');
               getinput(path^,70);
               println('');
            end;
     end;
     GetCommand;
     FindFiles;
  end else println('');
end;

Function pickprotocol: char;
var c: char;
begin
   ansic(lightgray,black);
   println('');
   println('ÄÄÄÍÍÍµ Choose a protocol to use. ³');
   println('');
   ansic(lightgray,lastback);
   for c:='A' to 'J' do println(c+') '+protodata[c].protoname);
   ansic(yellow,lastback);
   println('');
   print('Protocol choice (A..J)? ');
   pickprotocol:=upcase(key);
   println('');
end;

Procedure dnload;
var filename: string[12];
    x: byte;
    c: char;
begin
   if userdata^.access=1 then
   begin
     ansic(lightgray,black);
     println('');
     println('ÄÄÄÍÍÍµ Where do you want to download from? ³');
     ansic(yellow,lastback);
     println('');
     println('D)ownload directory');
     println('O)ther directory');
     println('');
     print(': ');
     c:=upcase(key);
     println(c);
     case c of
       'O': begin
               print('Dir = ');
               getinput(path^,70);
               if path^='' then path^:=configdata.hdndir;
               println('');
            end;
       else path^:=configdata.hdndir;
     end;
   end else path^:=configdata.hdndir;
   getcommand;
   ansic(lightred,black);
   println('');
   println('ÄÄÄÍÍÍµ Enter filename to download ³');
   ansic(yellow,lastback);
   println('');
   print(currentdir^);
   ansic(white,black);
   getinput(filename,12);
   if filename>'' then
   begin
      c:=pickprotocol;
      if c in ['A'..'J'] then
      begin
         with protodata[c] do
            exec(commandlocation,' /c '+wherefile+' '+ct(upcmd,currentdir^+filename));
         showstatus;
      end;
   end;
end;

Procedure upload;
var filename: string[12];
    ldir,cdir: string80;
    x: byte;
    pc,c: char;
begin
   pc:=pickprotocol;
   if pc in ['A'..'J'] then
   begin
      currentdir^:=configdata.hupdir;
      if protodata[pc].askdl then
      begin
         if userdata^.access=1 then
         begin
            ansic(lightgray,black);
            println('');
            println('ÄÄÄÍÍÍµ Where do you want to upload to? ³');
            ansic(yellow,lastback);
            println('');
            println('U)pload directory');
            println('O)ther directory');
            println('');
            print(': ');
            c:=upcase(key);
            println(c);
            case c of
              'O': begin
                      print('Dir = ');
                      getinput(path^,70);
                      if path^='' then path^:=configdata.hupdir;
                      println('');
                    end;
              else path^:=configdata.hupdir;
            end;
         end else path^:=configdata.hupdir;
         getcommand;
         ansic(lightred,black);
         println('');
         println('ÄÄÄÍÍÍµ Enter filename to upload ³');
         ansic(yellow,lastback);
         println('');
         print(currentdir^);
         ansic(white,black);
         getinput(filename,12);
      end else filename:='';
      getdir(0,ldir);
      if protodata[pc].changedl then
      begin
         cdir:=currentdir^;
         if (length(cdir)>3) and (cdir[length(cdir)]='\') then delete(cdir,length(cdir),1);
         {$I-}
         chdir(cdir);
         if ioresult<>0 then showmsg('Problem changing','directory');
         {$I+}
      end;
      with protodata[pc] do
         exec(commandlocation,' /c '+wherefile+' '+ct(dncmd,currentdir^+filename));
      chdir(ldir);
      showstatus;
   end;
end;

Procedure shutdown;
var pass: string[25];
begin
   ansic(lightgray,black);
   println('');
   println('ÄÄÄÍÍÍµ Enter shutdown (exit) password ³');
   ansic(yellow,black);
   print('PWD: ');
   echoback:=true;
   getinput(pass,20);
   echoback:=false;
   quithost:=caps(configdata.hshutdown)=caps(pass);
   println('');
   ansic(lightred,black);
   if quithost then println('Shutdown activated.') else println('Incorrect password.');
   println('');
end;

Procedure accesslevel;
var pass: string[25];
begin
   ansic(lightgray,black);
   println('');
   println('ÄÄÄÍÍÍµ Enter Access toggle (Sysop) password ³');
   ansic(yellow,black);
   print('PWD: ');
   echoback:=true;
   getinput(pass,20);
   echoback:=false;
   if caps(configdata.hlevel)=caps(pass) then
   if userdata^.access=1 then userdata^.access:=0 else userdata^.access:=1;
   println('');
   ansic(lightred,black);
   println('Access = '+its(userdata^.access));
   println('');
   showstatus;
end;

Procedure goodbye;
begin
   _dtr(false);
   delay(configdata.dtrdelay);
   _dtr(true);
   if not configdata.usedtr then _putstring(configdata.hangupstr);
   delay(configdata.dtrdelay);
   _flush_rx;
   _flush_tx;
   println('');
   sendfile('BYESCR');
   local:=false;
end;

Procedure message(whattype: char);
var c: char;
    x,y: integer;
    lastspace: byte;
    exitmessage,saveit: boolean;
    temp: usertype;
    mn: string[5];

begin
   with messagedata^ do
   begin
      line[1]:='';
      lastline:=1;
      timedate:='at '+time(1)+' on '+date;
      from:=userdata^.name;
      private:=false;
      saveit:=false;
      exitmessage:=false;
      println('');
      if whattype='P' then forwhom:='All Zygote users' else
      begin
         y:=filesize(userfile);
         private:=true;
         ansic(lightcyan,black);
         repeat
            x:=0;
            print('To : ');
            getinput(forwhom,25);
            forwhom:=caps(forwhom);
            {$I-}
            repeat
               seek(userfile,x);
               read(userfile,temp);
               if ioresult=0 then;
               inc(x);
            until (x=y) or (logoff) or (forwhom=temp.name);
            {$I+}
         until (forwhom=temp.name) or (forwhom='') or (logoff);
         exitmessage:=(logoff) or (forwhom='');
      end;
      if not exitmessage then
      begin
         ansic(yellow,black);
         print('Subject : ');
         getinput(subject,25);
         if subject='' then subject:='General Talk';
         println('');
         ansic(lightcyan,blue);
         mn:='['+its(filesize(messagefile)+1)+']';
         print('Õ'+chars('Í',78)+'¸');
         print('³  To     : '+forwhom+blanks(67-length(forwhom))+'³');
         print('³  From   : '+from+blanks(67-length(from))+'³');
         print('³  Subject: '+subject+blanks(67-length(subject))+'³');
         print('³  Status : '); if private then print('Private ') else print('Public  ');
         print(mn+blanks(59-length(mn))+'³');
         print('Ô'+chars('Í',78)+'¾');
         ansic(lightgreen,blue);
         print('ÄÄÍÍµ Help: ^K=abort  ^Z=Save ³');
         ansic(lightgray,black);
         println('');
         println('');
         repeat
            c:=key;
            if (not logoff) and (not exitmessage) then
            case c of
                #0,
                #27: ;
                #8 : begin
                        delete(line[lastline],length(line[lastline]),1);
                        print(^h+' '+^h);
                     end;
                #10,
                #13: begin
                        inc(lastline);
                        println('');
                        line[lastline]:='';
                     end;
                ^K : begin
                        saveit:=false;
                        ansic(lightred,black);
                        print('Abort? ');
                        ansic(lightgray,black);
                        exitmessage:=upcase(key)='Y';
                        for x:=1 to 7 do print(^h+' '+^h);
                     end;
                ^Z : begin
                        ansic(lightgreen,black);
                        print('Save? ');
                        ansic(lightgray,black);
                        saveit:=upcase(key)='Y';
                        exitmessage:=saveit;
                        for x:=1 to 6 do print(^h+' '+^h);
                     end;
                ^X : begin
                        for x:=1 to length(line[lastline]) do print(^h+' '+^h);
                        line[lastline]:='';
                     end;
                else if c>#31 then
                     begin
                        line[lastline]:=line[lastline]+c;
                        if length(line[lastline])=linesize then
                        begin
                           lastspace:=linesize;
                           while (lastspace>1) and (line[lastline][lastspace]<>' ') do dec(lastspace);
                           line[lastline+1]:=copy(line[lastline],lastspace+1,linesize-lastspace);
                           for x:=linesize downto lastspace+1 do
                           begin
                              delete(line[lastline],length(line[lastline]),1);
                              print(^h+' '+^h);
                           end;
                           inc(lastline);
                           println('');
                           print(line[lastline]);
                        end else print(c);
                     end;
            end;
            if lastline>50 then
            begin
               exitmessage:=true;
               saveit:=true;
            end;
         until (logoff) or (exitmessage);
         if saveit then
         begin
            {$I-}
            seek(messagefile,filesize(messagefile));
            write(messagefile,messagedata^);
            if ioresult=0 then;
            {$I+}
         end;
      end;
      println('');
   end;
end;

Procedure readmessages;
var exitread: boolean;
    mx,temp,x: integer;
    mn: string[20];
begin
   mn:='';
   mx:=filesize(messagefile);
   if userdata^.messageon<1 then userdata^.messageon:=1;
   if userdata^.messageon>mx then
   begin
      ansic(yellow,black);
      println('');
      print('ÄÄÍÍ[Q=uit, '+its(userdata^.messageon)+'/'+its(mx)+'] : ');
      getinput(mn,5);
      if mn='' then inc(userdata^.messageon) else
      begin
         val(mn,temp,x);
         if x=0 then userdata^.messageon:=temp;
      end;
      if userdata^.messageon>mx then userdata^.messageon:=mx+1;
   end;
   exitread:=(userdata^.messageon>mx) or (mn='Q') or (mn='q') or (userdata^.messageon<1);
   while (not exitread) do
   with messagedata^ do
   begin
      mn:='';
      {$I-}
      seek(messagefile,userdata^.messageon-1);
      read(messagefile,messagedata^);
      if ioresult=0 then;
      {$I+}
      if (userdata^.access=1) or (private=false) or (forwhom=userdata^.name) or (from=userdata^.name) then
      begin
         ansic(lightgray,black);
         clrscr;
         mn:='['+its(userdata^.messageon)+'/'+its(mx)+']';
         ansic(white,cyan);
         println('Õ'+chars('Í',77)+'¸');
         println('³  To     : '+forwhom+blanks(66-length(forwhom))+'³');
         println('³  From   : '+from+'  '+timedate+blanks(26-length(timedate))+blanks(38-length(from))+'³');
         println('³  Subject: '+subject+blanks(66-length(subject))+'³');
         print('³  Status : '); if private then print('Private ') else print('Public  ');
         println(mn+blanks(58-length(mn))+'³');
         print('Ô'+chars('Í',77)+'¾');
         ansic(lightgray,black);
         println('');
         println('');
         x:=1; lineon:=5;
         while (moreprompt) and (x<=lastline) and (not logoff) do
         begin
            println(line[x]);
            inc(x);
         end;
         ansic(yellow,black);
         println('');
         print('ÄÄÍÍ[Q=uit, Cr=Next, '+its(userdata^.messageon)+'/'+its(mx)+'] : ');
         getinput(mn,5);
         if mn='' then inc(userdata^.messageon) else
         begin
            val(mn,temp,x);
            if x=0 then userdata^.messageon:=temp;
         end;
      end else inc(userdata^.messageon);
      exitread:=(userdata^.messageon>mx) or (userdata^.messageon<1) or (mn='Q') or (mn='q');
   end;
   if userdata^.messageon<1 then userdata^.messageon:=1;
   showstatus;
end;

procedure help;
begin
   ansic(yellow,black);
   println('');
   println('?) This help screen');
   println('A)nsi toggler');
   println('C)all the host operator');
   println('D)ownload from this system');
   println('E)mail user on system');
   println('G)oodbye. See you later');
   println('L)ist files');
   println('P)ost bulletin');
   println('R)ead mail/posts');
   println('U)pload to system');
   println('X) shutdown system (PW required)');
   println('*) list users on system');
   println('%) toggle to access level 1 (PW required)');
   println('');
end;

Procedure mainhost;
var ch: char;
begin
   if _cd then inc(totalcalls);
   showstatus;
   more:=true;
   sendfile('BULLETIN');
   repeat
      ansic(yellow,black);    print('[');
      ansic(white,blue);      print(copy(time(1),1,5)+copy(time(1),9,3));
      ansic(yellow,black);    println(']');
      ansic(lightgray,black); print('('+its(userdata^.access)+') ');
      ansic(yellow,black);    print('<?=Help>');
      ansic(lightcyan,black); print('Command: ');
      ansic(white,black);
      ch:=upcase(key);
      if ch in ['A','C','D','E','G','L','P','R','U','X','?','*','%'] then
      begin
        println(ch);
        case ch of
          '?': help;
          'A': toggleansi;
          'C': callsysop;
          'D': dnload;
          'E',
          'P': message(ch);
          'G': goodbye;
          'L': listdirs;
          'R': readmessages;
          'U': upload;
          'X': shutdown;
          '*': listusers;
          '%': accesslevel;
        end;
      end else println('');
      println('');
   until (logoff) or (ch='G');
   {$I-}
   seek(userfile,lastcheck-1);
   write(userfile,userdata^);
   if ioresult=0 then;
   {$I+}
end;

Procedure loadhost;
begin
   new(userdata);
   new(messagedata);
   new(path);
   new(currentdir);
   totalcalls:=0;
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   repeat
      handlefile(true);
      init;
      waiting;
      if validuser then mainhost;
      handlefile(false);
   until quithost;
   savevideo(videoback,false);
   window(1,1,80,activescreensize);
   gotoxy(wx,wy);
   statusbar;
   dispose(userdata);
   dispose(messagedata);
   dispose(path);
   dispose(currentdir);
end;

end.
