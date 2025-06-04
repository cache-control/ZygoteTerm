unit z_other;

interface
{$F+,O+}

var dirname: string[80];

procedure createdirs;
procedure alarm(s: string);
procedure Saveback(save: boolean; name: string);
procedure DosShell;
procedure HangUp;
procedure Macros(screennum: integer);
procedure ClosingScr;
procedure Exechotkey(I: string);
function  Dirlist(var path: string; var laston: integer; showmark: boolean): string;
procedure Script_Autosysoff;
procedure Backwards;
procedure Readbinfiles;
procedure Logfile(S: String);
procedure Dialstatus;
procedure Loadfiledir;
procedure Readcrypt;
procedure Writecrypt;
procedure history;
procedure boardhelp;
procedure notepad(filename: string);

implementation

uses crt,dos,Z_util,z_comio,z_mouse;

procedure createdirs;
   procedure makedir(s: string80);
      function DirExist(stDir: dirstr): boolean;
      var woFattr: word;
          fiTemp: file;
      begin
         assign(fiTemp,stDir+'.');
         getfattr(fiTemp,woFattr);
         if doserror<>0 then DirExist:=false else direxist:=(woFattr and directory)<>0;
      end;
   begin
      if not direxist(s) then
      begin
         mkdir(s);
         showmsg('Could not find directory','Creating '+s+'\ now');
      end;
   end;

begin
   makedir(dir_host);
   makedir(dir_notepad);
   makedir(dir_capture);
   makedir(dir_script);
   makedir(dir_binary);
   makedir(dir_phone);
   makedir(dir_temp);
   makedir(dir_areadata);
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
     fwrite('ÜÜÜÜ',15,4*(j-1)+21,attr(lightcyan,black));
     for I:=1 to 150 do
     begin
        Sound(500);
        Delay(10);
        NoSound;
     end;
     Delay(1200);
   until (J=10) or (keypressed);
   movetoscreen(buf,mem[baseofscreen:1920],320);
   if keypressed then waitkey;
end;

procedure saveback(save: boolean; name: string);
var bfile: file;
begin
   if name='' then name:='ZYGOTE.BKG';
   if save then
   begin
      if disksize(0)>4000 then
      begin
         {$I-}
         assign(bfile,name);
         rewrite(bfile,4000);
         blockwrite(bfile,mem[baseofscreen:0],1);
         close(bfile);
         if ioresult<>0 then showmsg('Problem creating file',name);
         {$I+}
      end;
   end else if exist(name) then readbinfile(name,true);
end;

procedure DosShell;
var s: string80;
    ch: char;
begin
   disablemousedrvr;
   wx:=wherex; wy:=wherey;
   window(1,1,80,25);
   savevideo(videoback,true);
   logfile('  Shelled to DOS');
   color(7,0); clrscr;
   fwrite(chars('Ü',80),1,1,attr(lightcyan,black));
   fwrite(blanks(80),2,1,attr(yellow,cyan));
   fwrite(chars('ß',80),3,1,attr(darkgray,black));
   fwritena('³ Dos Shell ³',2,2);  fwrite('Type EXIT to return to Zygote',2,17,attr(black,cyan));
   fwrite('There are '+diskspace(0)+' free.',4,2,attr(lightgray,black));
   gotoxy(1,5);
   getdir(0,s);
   if configdata.dos_deinstallport then
   begin
      _deinstall;
      exec(commandlocation,'');
      _install(configdata.comport);
      _dtr(true);
   end else exec(commandlocation,'');
   with dparam do _set_param(speed,parity,dbit,sbit);
   chdir(s); saveback(true,'');
   logfile('  Returned from DOS');
   savevideo(videoback,false);
   gotoxy(wx,wy);
   statusbar;
   enablemousedrvr;
   mouse_installed:=initmouse=65535;
end;

procedure hangup;
var on: byte;
begin
   cursor(false);
   savevideo(videoback,true);
   changeattr(25,23,55,8);
   for on:=19 to 22 do changeattr(2,on,78,8);
   makebox(attr(white,cyan),49,18,77,22,1);
   sc.x:=50; sc.y:=19; sc.s:=27; sc.t:=3; page.flag:=0;
   sc.nc:=attr(black,cyan);
   sc.c:=hattr(white,blue);
   fwritena('´              Ã',18,52);
   fwrite('Drop carrier',18,54,attr(yellow,cyan));
   fwrite(' Send hangup string        ',19,50,sc.nc);
   fwrite(' Lower DTR to drop carrier ',20,50,sc.nc);
   fwrite(' Abort                     ',21,50,sc.nc);
   if configdata.usedtr then on:=2 else on:=1;
   if not configdata.confirmhe then
   begin
      changeattr(sc.s,sc.y+on-1,sc.x,sc.c);
      delay(200);
   end else if scrollchoice(#27+#13,on)=#27 then on:=3;
   if on=1 then
   begin
      send(configdata.attention);
      delay(10000);
      send(configdata.hangupstr);
   end else
   if on=2 then
   begin
      _dtr(false);
      delay(configdata.dtrdelay);
      _dtr(true);
   end;
   savevideo(videoback,false);
   statusbar;
   cursor(true);
end;

procedure macros;
const mfname = 'ZYGOTE.MAC';
var ch: char;
    tempi: integer;
    mactemp: ^mactype;
    lastnum,x,m: byte;

procedure makemacro;
var io,size: integer;
begin
   assign(filehandle,mfname);
   if exist(mfname) then
   begin
      {$I-}
      reset(filehandle,sizeof(macdata));
   end else
   begin
      {$I-}
      rewrite(filehandle,sizeof(macdata));
   end;
   io:=ioresult;
   size:=filesize(filehandle);
   if (size<10) and (io=0) then
   begin
      fillchar(macdata,sizeof(macdata),0);
      while (filesize(filehandle)<10) and (io=0) do
      begin
         blockwrite(filehandle,macdata,1);
         io:=ioresult;
      end;
   end;
   screennum:=io;
end;

procedure showmacro;
var i,colr: byte;
begin
   colr:=attr(cyan,black);
   fwrite(its(screennum),7,15,attr(yellow,black));
   for i:=1 to 6 do
      fwrite(macdata[i]+blanks(65-length(macdata[i])),i+9,10,colr);
end;

begin
   makemacro;
   if screennum=0 then
   begin
      lastnum:=0;
      cursor(false);
      wx:=wherex; wy:=wherey;
      savevideo(videoback,true);
      makebox(attr(lightblue,black),2,7,76,17,1);
      fwritena('´           Ã',7,5);
      fwrite('Screen #',7,7,attr(yellow,black));
      color(lightcyan,black);
      xy(5,8,'Valid keys (Use arrow keys, Enter, ESC=Abort)');
      for x:=10 to 15 do xy(5,x,'%M'+chr(87+x)+': ');
      for x:=8 to 17 do changeattr(2,x,77,8);
      changeattr(75,18,4,8);
      showmacro;
      x:=1;
      editflag(1,1,1,1,1,0,1);
      sc.x:=10; sc.y:=10;
      sc.s:=65; sc.t:=6;
      sc.nc:=attr(cyan,black);
      sc.c:=hattr(white,blue);
      page.flag:=0;
      timestat.flag:=0;
      repeat
         showmacro;
         ch:=scrollchoice(#13+#27+#16+#17,x);
         if ch<>#27 then
         case ch of
           #13: begin
                   m:=0;
                   if input(hattr(yellow,green),10,x+9,macdata[x],250,65,m)=#0 then;
                end;
           #17: dec(screennum);
           #16: inc(screennum);
         end;
         if screennum<0 then screennum:=9;
         if screennum>9 then screennum:=0;
         if lastnum<>screennum then
         begin
            seek(filehandle,lastnum);   blockwrite(filehandle,macdata,1);
            seek(filehandle,screennum); blockread(filehandle,macdata,1,tempi);
            lastnum:=screennum;
         end;
      until ch=#27;
      savevideo(videoback,false);
      gotoxy(wx,wy);
      statusbar;
      cursor(true);
      new(mactemp);
      if screennum>0 then
      begin
         seek(filehandle,0);
         blockread(filehandle,mactemp^,1,tempi);
      end;
      seek(filehandle,0);
      blockwrite(filehandle,macdata,1);
      if screennum>0 then
      begin
         seek(filehandle,screennum);
         blockwrite(filehandle,mactemp^,1);
      end;
      dispose(mactemp);
   end else showmsg('Error opening macro file',mfname);
   close(filehandle);
   if ioresult=0 then;
   {$I+}
end;

procedure closingscr;
var i: byte;
    s1,s2: stringpw;
begin
   logfile('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Zygote v'+cmsg(zversion)+' Exited ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'+#13+#10);
   window(1,1,80,25); color(lightgray,black); clrscr;
   makebox(0,1,1,52,3,1); makebox(0,78,1,80,3,1);
   fwrite('The evolution of telecommunications',2,10,attr(lightgray,black));
   changeattr(14,2,21,attr(white,black));
   fwrite('(TM)',1,74,attr(white,black));
   fwrite('ÖÄ· · ·ÖÄ·ÖÄ·ÄÒÄÒÄ·',1,54,attr(cyan,black));
   fwrite('ÖÄ½ ÓÄ¶º Òº º º ÇÄ',2,54,attr(lightcyan,black));
   fwrite('ÓÄÄ½ÄÄ½ÓÄ½ÓÄ½ Ğ ĞÄ½',3,54,attr(cyan,black));
   fwrite('NTM technologies',4,1,attr(lightred,black));
   xy(1,5,'oExited at p'+time(1)+' oon p'+date);
   xy(66,4,'hMade in the mUpSjA');
   color(lightgray,black);
   writeln;

   {unregistered
   s1:='';
   writeln;
   writeln('*UNREGISTERED* version');
   for i:=1 to 5 do s1:=s1+chr(random(26)+65);
   repeat
      writeln('(exit pwd is ',s1,')');
      write('enter exit pwd: ');
      readln(s2);
   until s1=s2;
   }
end;

procedure exechotkey;
var d: string;
begin
   nosound;
   savevideo(videoback,true);
   wx:=wherex; wy:=wherey;
   window(1,1,80,25);
   color(15,0); clrscr;
   getdir(0,d);
   i:=ct(i,'');
   logfile('  Executing program ('+i+blanks(30-length(i))+')');
   _deinstall;
   exec(commandlocation,' /c '+i);
   _install(configdata.comport);
   _dtr(true);
   with dparam do _set_param(speed,parity,dbit,sbit);
   chdir(d);
   saveback(true,'');
   savevideo(videoback,false);
   gotoxy(wx,wy);
   statusbar;
end;

function dirlist(var path: string; var laston: integer; showmark: boolean): string;
const maxfiles=250;
      boxsize = 17;
type  filetype= record
              desc: string[24];
              tag: boolean;
              dt: string[8];
              xt: string[5];
      end;
      filetype2=array[1..maxfiles] of filetype;

var files: ^filetype2;
    timetemp: string[12];
    tsc: sctype;
    rat: mousetype;
    ch: char;
    out,dirup: boolean;
    origdir: string80;
    totalbytes: longint;
    totalfiles,x,diron,
    top,bottom,on,totalmarked: integer;

function lint(l: longint): string;
var i: real;
    s: string[5];
begin
   i:=0.0;
   case dparam.speed of
       300: i:= l / 29.0;
      1200: i:=l / 116;
      2400: i:=l / 233;
      4800: i:=l / 466;
      9600: i:=l / 932;
     14400: i:=l / 1392;
     19200: i:=l / 1864;
     38400: i:=l / 3728;
     57600: i:=l / 5592;
   end;
   str((i/60):0:1,s);
   lint:=s;
end;

procedure GetCommand;
var I,J: Integer;
    Attr: Word;
    S,D,N,E: string;
    F: File;
begin
   while (path[1]=' ') and (length(path)>0) do delete(path,1,1);
   path:=FExpand(path);
   if path[Length(path)] <> '\' then
   begin
      Assign(F,path);
      GetFAttr(F,Attr);
      if (DosError = 0) and (Attr and Directory <> 0) then path:=path+'\';
   end;
   FSplit(path,D,N,E);
   if N='' then N:='*';
   if E='' then E:='.*';
   dirname:=d;
   path:=D+N+E;
end;

function Foundfiles: boolean;
var F: SearchRec;
    T: datetime;
    S: filetype;
begin
   on:=1;
   diron:=0;
   out:=false;
   totalbytes:=0;
   totalfiles:=0;
   totalmarked:=0;
   files^[1].xt:='0.0';
   files^[1].desc:='   No matching files.   ';
   findfirst(path,readOnly+directory+archive,f);
   while (doserror=0) and (totalfiles<=maxfiles) do
   with F do
   begin
      inc(totalfiles);
      with files^[totalfiles] do
      begin
         xt:='0.0';
         dt:='[dir]   ';
         tag:=false;
         desc:=name+blanks(13-length(name));
         if (attr and directory<>0) then desc:=desc+'[directory]' else
         begin
            desc:=desc+blanks(11-length(its(size)))+its(size);
            unpacktime(time,t);
            dt:=chars('0',2-length(its(t.month)))+its(t.month)+'Ä'+
                chars('0',2-length(its(t.day)))+its(t.day)+'Ä'+
                chars('0',2-length(its(t.year mod 100)))+its(t.year mod 100);
            xt:=lint(size);
         end;
         if pos('[directory]',desc)>0 then
         begin
            repeat
               inc(diron);
            until (pos('[directory]',files^[diron].desc)=0) or (diron>=totalfiles);
            s:=files^[diron];
            files^[diron]:=files^[totalfiles];
            files^[totalfiles]:=s;
         end;
      end;
      inc(totalbytes,size);
      findnext(F);
   end;
   foundfiles:=totalfiles>0;
   top:=1;
   if totalfiles<=boxsize then bottom:=totalfiles else bottom:=boxsize;
end;

procedure QSort;
var pivot: string;

  procedure switch(var a,b: filetype);
  var c: filetype;
  begin
     c:=a; a:=b; b:=c;
  end;

  procedure Sort(L,R : integer);
  var I,J: word;
   begin
      I:= L;
      J:= R;
      {pivot:=chr( (ord(files^[I].desc[1])+ord(files^[J].desc[1])) div 2 );}
      pivot:=files^[(I+J) div 2].desc;
      repeat
         while files^[I].desc<pivot do Inc(I);
         while files^[J].desc>pivot do Dec(J);
         if I<=J then
         begin
            switch(files^[I],files^[J]);
            Inc(I);
            Dec(J)
         end;
      until I>J;
      if L<J then Sort(L,J);
      if I<R then Sort(I,R)
   end;

begin
   if diron>1 then sort(1,diron);
   if totalfiles>diron+1 then Sort(diron+1,totalfiles);
end;

procedure showwindows;
var i,c: byte;
begin
    hidemouse;
    cursor(false);
    c:=attr(cyan,black);
    fwrite('ÚÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿',2,20,c);
    fwrite('³ PATH ³                                                   ³',3,20,c);
    fwrite('ÃÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ´',4,20,c);
    fwrite('³                         ³ Sútúaútúiúsútúiúcús ³# Files   ³',5,20,c);
    fwrite('³                         ÃÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄ´',6,20,c);
    fwrite('³                         ³ Date ³              ³          ³',7,20,c);
    fwrite('³                         ³ Xfer ³              ÃÄÄÄÄÄÄÄÄÄÄ´',8,20,c);
    fwrite('³                         ³ Rate ³              ³# Tags    ³',9,20,c);
    fwrite('³                         ÃÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄ´',10,20,c);
    fwrite('³                         ³    Húeúlúp  Búoúx   ³          ³',11,20,c);
    fwrite('³                         ÃÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄ´',12,20,c);
    fwrite('³                         ³SPACE ³              ³Total size³',13,20,c);
    fwrite('³                         ³ENTER ³              ÃÄÄÄÄÄÄÄÄÄÄ´',14,20,c);
    fwrite('³                         ³ESCAPE³              ³          ³',15,20,c);
    fwrite('³                         ³Alt-P ³              ÃÄÄÄÄÄÄÄÄÄÄ´',16,20,c);
    fwrite('³                         ³A to Z³              ³Allow tag ³',17,20,c);
    fwrite('³                         ³Time  ³              ÃÄÄÄÄÄÄÄÄÄÄ´',18,20,c);
    fwrite('³                         ÃÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´          ³',19,20,c);
    fwrite('³                         ³         Home/End  ÃÄÄÄÄÄÂÄÄÄÄ´',20,20,c);
    fwrite('³                         ³                     ³# on ³    ³',21,20,c);
    fwrite('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÙ',22,20,c);
    c:=attr(white,black);
    fwrite(copy(path,1,48),3,29,c);
    fwrite(conv(dparam.speed)+' bps',9,55,c);
    fwrite('Tag',13,55,c);
    fwrite('Accept tag',14,55,c);
    fwrite('Quit',15,55,c);
    fwrite('Path change',16,55,c);
    fwrite('Search',17,55,c);
    fwrite('Up/down  Top/bottom',21,48,c);
    fwrite(its(totalfiles)+'   ',7,69,c);
    fwrite(its(totalmarked),11,69,c);
    fwrite(its(totalbytes),15,69,c);
    if showmark then fwrite('Yes',19,69,c) else fwrite('No ',19,69,c);
    showmouse;
end;

procedure checkonx;
begin
   if on<1 then on:=1;
   if on>totalfiles then on:=totalfiles;
   if on>bottom then
   begin
      bottom:=on;
      top:=bottom-boxsize+1;
      if top<1 then top:=1;
   end else if on<top then
   begin
      top:=on;
      bottom:=top+boxsize-1;
      if bottom>totalfiles then bottom:=totalfiles;
   end;
end;

procedure checkon;
begin
   if on<1 then on:=1 else if on>totalfiles then on:=totalfiles;
   if on<top then top:=on else if on>bottom then top:=on-boxsize+1;
   if top<1 then top:=1;
   bottom:=top+boxsize-1;
   if bottom>totalfiles then bottom:=totalfiles;
end;


procedure changepath;
var m : byte;
    last: string[80];
begin
   m:=0;
   last:=path;
   editflag(1,1,0,1,1,1,1);
   ch:=input(attr(white,black),29,3,path,80,48,m);
   if ch<>#13 then path:=last;
   if last<>path then
   begin
      getcommand;
      if foundfiles then qsort;
      showwindows;
   end;
   cursor(false);
end;

procedure tagfile;
begin
   if (totalfiles>0) and (showmark) and (pos('[directory]',files^[on].desc)=0) then
   begin
      if files^[on].Tag=true then
      begin
         dec(totalmarked);
         files^[on].Tag:=false;
      end else
      begin
         inc(totalmarked);
         files^[on].Tag:=true;
      end;
      fwrite(its(totalmarked)+'   ',11,69,attr(yellow,black));
      if dirup then dec(on) else inc(on);
      checkon;
   end;
end;

procedure chosefile;
var s: string;
    f: text;
    x,io: integer;
begin
   if totalfiles<1 then dirlist:='|ESC|' else
   if pos('[directory]',files^[on].desc)=0 then
   begin
      s:='';
      out:=true;
      if totalmarked=0 then files^[on].tag:=true;
      {$I-}
      if showmark then
      begin
         io:=0;
         assign(f,dir_temp+'\BATCH.LST');
         rewrite(f);
      end;
      for x:=1 to totalfiles do
         if files^[x].tag then
         begin
           s:=s+copy(files^[x].desc,1,pos(' ',files^[x].desc));
           if showmark then
           begin
              writeln(f,dirname+copy(files^[x].desc,1,pos(' ',files^[x].desc)-1));
              if ioresult<>0 then
              begin
                 showmsg('Problem creating',dir_temp+'\BATCH.LST');
                 io:=-1;
              end;
           end;
         end;
      if (io=0) and (showmark) then close(f);
      {$I+}
      if (showmark) and (totalmarked>1) then
      begin
         if length(origdir)>3 then dirlist:='@'+origdir+'\'+dir_temp+'\BATCH.LST' else
            dirlist:='@'+origdir+dir_temp+'\BATCH.LST';
      end else dirlist:=s;
   end else
   if copy(files^[on].desc,1,2)<>'. ' then
   begin
      path:=dirname+copy(files^[on].Desc,1,pos(' ',files^[on].desc)-1);
      getcommand;
      if foundfiles then
      begin
         qsort;
         showwindows;
      end else out:=true;
   end;
end;

procedure showfiles;
const tagmark : array[boolean] of char = (' ','');
var I: integer;
    Y,c: byte;
begin
   if totalfiles<1 then fwrite(files^[1].desc+' ',5,21,hattr(white,blue)) else
   begin
      Y:=5;
      for i:=top to bottom do
      with files^[I] do
      begin
         fwrite(tagmark[tag],y,21,attr(lightgreen,black));
         if i=on then c:=hattr(white,blue) else c:=attr(lightgray,black);
         fwrite(desc,y,22,c);
         inc(Y);
      end;
      c:=attr(yellow,black);
      fwrite(files^[on].dt,7,55,c);
      fwrite(files^[on].xt+' min   ',8,55,c);
      fwrite(its(on)+' ',21,75,c);
   end;
end;

procedure searchchar(c: char);
var found: boolean;
    y: integer;
begin
   c:=upcase(c);
   found:=false;
   y:=1;
   repeat
     if (files^[y].desc[1]=c) and (pos('[directory]',files^[y].desc)=0) then
     begin
        found:=true;
        on:=y;
        checkON;
     end;
     inc(y);
   until (found) or (y>totalfiles);
end;

begin
   tsc:=sc;
   new(files);
   getcommand;
   timestat.flag:=1;
   timestat.colr:=attr(yellow,black);
   timestat.x:=55;
   timestat.y:=18;
   if foundfiles then
   begin
      qsort;
      getdir(0,origdir);
      dirlist:='|ESC|';
      if laston<=totalfiles then on:=laston;
      checkon;
      showwindows;
      sc.x:=22; sc.y:=5;
      sc.s:=24;
      showmouse;
      setmouseposition(sc.x+sc.s div 2, sc.y);
      repeat
         hidemouse;
         if totalfiles<boxsize then sc.t:=totalfiles else sc.t:=boxsize;
         showfiles;
         showmouse;
         laston:=on;
         with rat do
         repeat
            mouseposition(rat);
            if (mx>=sc.x) and (mx<=sc.x+sc.s-1) and (my>=sc.y) and (my<=sc.y+sc.t-1) then
            begin
               mousepress(rightbutton,rat);
               if stat=leftpress then on:=my-sc.y+top;
               if (stat=rightpress) and (rat.pcount=1) then
               begin
                  laston:=0;
                  on:=my-sc.y+top;
                  tagfile;
                  on:=my-sc.y+top;
               end;
               mousepress(leftbutton,rat);
               if (my=lastpy) and (abs(clocktick-clocktemp)<twoclickdelay) and (pcount=1) then
                  chosefile;
               if pcount=1 then clocktemp:=clocktick;
            end else
            if (lastpx>=sc.x) and (lastpx<=sc.x+sc.s-1) and (stat=leftpress) and
               (lastpy>=sc.y) and (lastpy<=sc.y+sc.t-1) then
            begin
               if (my<sc.y) then
               begin
                  dirup:=true;
                  dec(on);
                  delay(200);
               end else
               if (my>sc.y+sc.t-1) then
               begin
                  dirup:=false;
                  inc(on);
                  delay(200);
               end;
               checkon;
            end else
            if stat=rightpress then
            begin
               mousepress(rightbutton,rat);
               out:=true;
               dirname:='';
            end;
            if timetemp<>time(1) then
            begin
               fwrite(time(1),timestat.y,timestat.x,timestat.colr);
               timetemp:=time(1);
            end;
         until (keypressed) or (out) or (laston<>on);
         if keypressed then
         begin
            ch:=readkb;
            if ch=#0 then
            begin
               ch:=readkb;
               case ch of
                 #73: begin
                         dec(on,5);
                         dirup:=true;
                      end;
                 #81: begin
                         inc(on,5);
                         dirup:=false;
                      end;
                 #72: begin
                         dec(on);
                         dirup:=true;
                      end;
                 #80: begin
                         inc(on);
                         dirup:=false;
                      end;
                 #71: on:=1;
                 #79: on:=totalfiles;
                 #25: changepath;
               end;
               grabline(ch);
               screendump(ch);
               checkon;
            end else
            case upcase(ch) of
              'A'..'Z',
              '0'..
              '9': searchchar(upcase(ch));
              ' ': tagfile;
              #13: chosefile;
              #27: begin
                      out:=true;
                      dirname:='';
                   end;
            end;
         end;
      until out;
      chdir(origdir);
   end else dirlist:='|ESC|';
   hidemouse;
   timestat.flag:=0;
   dispose(files);
   laston:=on;
   cursor(true);
   sc:=tsc;
end;

procedure script_autosysoff;
begin
   autolog:=false;
   script:=false;
   statusbar;
end;

procedure backwards;
var x: byte;
    line: string;
begin
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   cursor(false);
   makebox(attr(white,blue),2,10,76,12,1);
   for x:=11 to 12 do changeattr(2,x,77,8);
   changeattr(75,13,4,8);
   x:=0;
   line:='';
   color(yellow,blue);
   xy(4,11,'Text : ');
   editflag(1,1,1,1,1,0,1);
   if input(attr(lightgray,blue),wherex,wherey,line,250,63,x)=#13 then
   for x:=length(line) downto 1 do _put(ord(line[x]));
   savevideo(videoback,false);
   gotoxy(wx,wy);
   statusbar;
end;

procedure readbinfiles;
var binfile,path: string80;
    x,y: integer;
    thefile: file;
begin
   savevideo(videoback,true);
   wx:=wherex; wy:=wherey;
   path:=dir_binary+'\Z_?????.BIN';
   y:=1;
   Repeat
      binfile:=dirlist(path,y,false);
      if exist(dir_binary+'\'+binfile) then
      begin
         assign(thefile,dir_binary+'\'+binfile);
         reset(thefile,1);
         blockread(thefile,mem[baseofscreen:0],4000,x);
         close(thefile);
         cursor(false);
         waitkey;
      end;
   Until binfile='|ESC|';
   savevideo(videoback,false);
   gotoxy(wx,wy);
   statusbar;
   cursor(true);
end;

procedure logfile(s: string);
var loghandle: text;
begin
   if configdata.keeplog then
   if diskfree(0)<255 then showmsg('procedure logfile:','Not enough disk space') else
   begin
      assign(loghandle,'ZYGOTE.LOG');
      if exist('ZYGOTE.LOG') then append(loghandle) else
      begin
         rewrite(loghandle);
         writeln(loghandle,'Log opened on '+date);
         writeln(loghandle,'');
      end;
      writeln(loghandle,copy(time(0),1,5)+', '+date+' ğ '+s);
      close(loghandle);
   end;
end;

procedure dialstatus;
var y,c: byte;
    s,scr: string[20];

begin
   with dialdata do
   begin
      if autosys in ['A'..'J'] then autolog:=true else autolog:=false;
      if autolog then s:=sysdata[autosys].sysname else s:='Autosys disabled';
      if script then
      begin
         scr:=scriptname+'.SCR';
         s:='Script enabled';
         autolog:=false;
      end else scr:='Script disabled';
      c:=attr(cyan,black);
      makebox(c,1,1,80,4,1);
      fwritena('Â',1,12); vertchars(c,12,2,3,'³'); fwritena('Á',4,12);
      c:=attr(lightcyan,black);
      makebox(c,1,5,80,11,1);
      fwritena('Â',5,12);  fwritena('Â',5,40);  fwritena('Â',5,51);
      fwritena('Á',11,12); fwritena('Á',11,40); fwritena('Á',11,51);
      vertchars(c,12,6,10,'³');
      vertchars(c,40,6,10,'³');
      vertchars(c,51,6,10,'³');

      c:=attr(lightcyan,black);
      fwrite('System',2,3,c);   fwrite('Comment',3,3,c);
      fwrite('DCE',7,63,attr(lightgreen,black));
      c:=attr(cyan,black);
      fwrite('Handle',6,3,c);    fwrite('LFD',6,42,c);
      fwrite('Script',7,3,c);    fwrite('Params',7,42,c);
      fwrite('Auto on',8,3,c);   fwrite('Connects',8,42,c);
      fwrite('Xlation',9,3,c);   fwrite('Protocol',9,42,c);
      fwrite('Keyboard',10,3,c); fwrite('Graphics',10,42,c);

      c:=attr(lightgray,black);
      fwrite(bbsname+' ğ '+bbsphone,2,14,attr(white,black));
      fwrite(comment,3,14,attr(lightblue,black));
      fwrite(its(dcebps)+' bps',7,67,c);
      fwrite(user.handle,6,14,attr(yellow,black));
      fwrite(user.lfd,6,53,c);
      fwrite(scr,7,14,c);  with dparam do fwrite(its(speed)+parity+its(dbit)+its(sbit),7,53,c);
      fwrite(s,8,14,c);    fwrite(its(timescalled),8,53,c);
      fwrite(lastdata.name_tbl+'.TBL',9,14,c); fwrite(protodata[protocol].protoname,9,53,c);
      fwrite(lastdata.name_kbd+'.KBD',10,14,c);
      case dparam.graphic of
        uANSI: fwrite('ANSI',10,53,c);
        uVT100: fwrite('VT100',10,53,c);
        uAVATAR: fwrite('AVATAR',10,53,c);
        uNONE: fwrite('NONE, TTY',10,53,c)
      end;
      gotoxy(1,14);

      {unregistered
      fwrite(cmsg('Ø¤¾½«ª¥¸¾¬º¢¢Ï'),13,1,attr(lightred,black));
      changeattr(12,13,2,attr(yellow,black));
      }

   end;
end;

procedure loadfiledir;
var p: string80;
    x: integer;
begin
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   cursor(false);
   x:=1; p:='*.*';
   p:=dirlist(p,x,false);
   savevideo(videoback,false);
   gotoxy(wx,wy);
   statusbar;
   cursor(true);
end;

function crypt(code: byte; ch: char): byte;
var x,y: byte;
begin
   y:=ord(ch);
   if (y>32) then
   begin
      x:=(code xor ord(ch));
      if x<33 then x:=255-x;
      if x=127 then x:=128;
      crypt:=x;
   end else crypt:=y;
end;

function decrypt(code: byte; ch: char): char;
var c,z,x: byte;
begin
    c:=32;
    z:=ord(ch);
    if (z>32) then
    repeat
       inc(c);
       x:=(code xor c);
       if x<33 then x:=255-x;
       if x=127 then x:=128;
    until z=x else c:=ord(ch);
    decrypt:=chr(c);
end;

function cryptlevel(c: char): byte;
var x: byte;
begin
   case upcase(c) of
     'A': x:=177; 'I': x:=109;
     'X': x:=221; 'B': x:=239;
     'G': x:=231; 'O': x:=253;
     'C': x:=193; 'J': x:=255;
     'W': x:=177; 'D': x:=99;
     'K': x:=181; 'R': x:=97;
     'E': x:=229; 'H': x:=241;
     'V': x:=189; 'F': x:=199;
     'L': x:=251; 'S': x:=101;
     'M': x:=161; 'N': x:=167;
     'P': x:=121; 'Q': x:=247;
     'T': x:=139; 'U': x:=201;
     'Y': x:=157; 'Z': x:=155;
     Else x:=255;
   end;
   cryptlevel:=x;
end;

function cryptpassword(code: byte; s: string): string;
var x: byte;
begin
    for x:=1 to length(s) do s[x]:=chr(crypt(code,s[x]));
    cryptpassword:=s;
end;

function decryptpassword(code: byte; s: string): string;
var x: byte;
begin
   for x:=1 to length(s) do s[x]:=decrypt(code,s[x]);
   decryptpassword:=s;
end;

procedure writecrypt;
var ch: char;
    out: boolean;
    code,x: byte;
    p: string[8];
begin
   if _cd then
   begin
      out:=false;
      color(14,0); p:=''; clrscr;
      xy(1,wherey,'Do you want to add a password (y/N)? ');
      color(10,0);
      if upcase(readkb)='Y' then
      begin
         writeln('Yes!');
         color(11,0); x:=0;
         editflag(1,0,0,1,0,1,0);
         xy(1,wherey,'Enter password : ');
         ch:=input(attr(15,0),wherex,wherey,p,8,8,x);
         textbackground(0);
         writeln;
      end else writeln('No!');
      ch:=chr(random(26)+65);
      code:=cryptlevel(ch);
      wy:=wherey;
      gotoxy(1,wherey); color(15,1); clreol;
      xy(15,wherey,'Crypting message - Level [k'+ch+'p]  (lESCp=lapep)');
      gotoxy(1,wherey+1);
      send('#îï€â˜­A'+cryptpassword(code,p)+ch+#13);
      repeat
         if _rx_ready then ch:=chr(_get);
      until (ch=#13) or (keypressed);
      restorecolor;
      repeat
         if _rx_ready then
         begin
            ch:=chr(_get);
            write(decrypt(code,ch));
         end;
         while keypressed do
         begin
            ch:=readkb;
            if ch=#27 then out:=true else _put(crypt(code,ch))
         end;
      until out;
      send(#13+'ğäïDğ'+#13);
      statusbar;
   end else writeln(#13+#10+'You need to be connected to a Bulletin Board.');
end;

procedure readcrypt;
var code,x: byte;
    ch,version: char;
    p: string[8];
    s: string[10];
    out,start: boolean;

begin
    start:=false;
    s:='';
    repeat
        if _rx_ready then
        begin
           ch:=chr(_get);
           if ch<>#13 then s:=s+ch;
       end;
    until (keypressed) or (ch=#13);
    if length(s)>1 then
    begin
       gotoxy(1,wherey); clreol;
       ch:=s[length(s)];
       version:=s[1];
       code:=cryptlevel(ch);
       delete(s,1,1);
       delete(s,length(s),1);
       start:=true;
    end;
    if (start) and (s>'') then
    begin
       p:=''; x:=0; writeln;
       s:=decryptpassword(code,s); color(14,0);
       writeln('This message is password protected.');
       editflag(1,0,0,1,0,1,0);
       write('Enter the password : ');
       if input(attr(7,0),wherex,wherey,p,8,8,x)=#0 then;
       color(15,0);
       if caps(s)=p then writeln(#13+#10+'Access granted!') else
       begin
          start:=false;
          writeln(#13+#10+'Access denied!');
          restorecolor;
       end;
    end;

    If start then
    begin
       s:=blanks(5); writeln; color(15,4); clreol;
       xy(15,wherey,'Reading crypted message - Level [o'+ch+'p]   (kESCp=kapep)');
       color(7,0);
       writeln; out:=false;
       repeat
          while (_rx_ready) and (not out) do
          begin
             ch:=chr(_get);
             delete(s,1,1);
             s:=s+ch;
             if ch='ğ' then
             if s='ğäïDğ' then
             begin
                out:=true;
                xy(1,wherey,blanks(5)+#13);
             end;
             ch:=decrypt(code,ch);
             if not out then write(ch);
          end;
          while keypressed do
          begin
             ch:=readkb;
             out:=readkb=#27;
             _put(ord(ch));
          end;
       until out;
       statusbar;
    end;
end;

procedure history;
var ch: char;
    numon,lo: byte;

   procedure drawmenu;
   var i,c: byte;
   begin
      makebox(attr(lightblue,black),1,6,80,17,1);
      fwritena('´              Ã',6,33);
      fwrite('History menu',6,35,attr(lightcyan,black));
      c:=attr(white,black);
      fwrite(' Use <,> to choose, <E>dit          Press <Enter> to select ',17,11,c);
      for i:=7 to 16 do
         fwrite(copy(lastdata.grabbuffer[i-6],1,78),i,2,attr(lightgray,black));
      numon:=lastdata.ptr_buffer;
      page.flag:=0;
      timestat.flag:=0;
      sc.x:=2; sc.y:=7;
      sc.s:=78;
      sc.c:=hattr(white,blue);
      sc.nc:=attr(lightgray,black);
      sc.t:=10;
   end;
begin
   wx:=wherex; wy:=wherey;
   cursor(false);
   savevideo(videoback,true);
   drawmenu;
   repeat
      ch:=scrollchoice(#13+#27+'E',numon);
      if ch='E' then
      begin
         lo:=0;
         editflag(1,1,1,1,1,0,1);
         if input(attr(white,black),2,numon+6,lastdata.grabbuffer[numon],80,78,lo)=' ' then;
         changeattr(78,numon+6,2,attr(lightgray,black));
      end;
   until ch in [#27,#13];
   if ch=#13 then lastdata.ptr_buffer:=numon;
   savevideo(videoback,false);
   gotoxy(wx,wy);
   cursor(true);
end;

procedure boardhelp;
const main  = 'BBS_MAIN.HLP';
      files = 'BBS_FILE.HLP';
      mesg  = 'BBS_MSGE.HLP';
      other = 'BBS_OTHR.HLP';
var name: string;
    ch: char;
    c: byte;
begin
   cursor(false);
   savevideo(videoback,true);
   c:=attr(cyan,black);
   fwrite('ÛßßßßßßßßßÛßßßßßßßßßß              ßßßßßßßßßÛ',10,19,c);
   fwrite('İ         Û                                 Ş',11,19,c);
   fwrite('İ         Û                                 Ş',12,19,c);
   fwrite('ÛÜÜÜÜÜÜÜÜÜÛÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÛ',13,19,c);
   fwrite(' Help screens ',10,40,attr(lightcyan,black));
   c:=attr(yellow,black);
   fwrite('Restore',11,21,c);
   fwrite('Save',12,21,c);
   c:=attr(white,black);
   fwrite('[ ]ain [ ]ile M[ ]ssage [ ]ther',11,31,c);
   fwrite('[ ]ain [ ]ile M[ ]ssage [ ]ther',12,31,c);
   c:=attr(red,black);
   fwrite('m',11,32,c); fwrite('f',11,39,c); fwrite('e',11,47,c); fwrite('o',11,56,c);
   c:=attr(lightred,black);
   fwrite('M',12,32,c); fwrite('F',12,39,c); fwrite('E',12,47,c); fwrite('O',12,56,c);
   ch:=readkb;
   if ch in ['M','F','E','O'] then
   begin
      savevideo(videoback,false);
      if connected then name:=dialdata.bbsname else name:='UNKNOWN';
      fwrite(' System name:                                      ³ Help for                 ³ ',25,1,attr(black,lightgray));
      fwritena(name+'',25,15);
      case ch of
         'M': begin
                 fwritena('Main section',25,63);
                 saveback(true,dir_temp+'\'+main);
              end;
         'F': begin
                 fwritena('File section',25,63);
                 saveback(true,dir_temp+'\'+files);
              end;
         'E': begin
                 fwritena('Message section',25,63);
                 saveback(true,dir_temp+'\'+mesg);
              end;
         'O': begin
                 fwritena('Other section',25,63);
                 saveback(true,dir_temp+'\'+other);
              end;
      end;
   end else
   if ch in ['m','f','e','o'] then
   begin
      case ch of
         'm': name:=dir_temp+'\'+main;
         'f': name:=dir_temp+'\'+files;
         'e': name:=dir_temp+'\'+mesg;
         'o': name:=dir_temp+'\'+other;
      end;
      readbinfile(name,false);
      if exist(name) then waitkey;
   end;
   savevideo(videoback,false);
   cursor(true);
end;

procedure notepad;
type  notetype=record
         note: array[1..22] of string[78];
         lastx,lasty: byte;
         insertmode: boolean;
         bbsname: string[23];
      end;
var   notefile: file of notetype;
      rat: mousetype;
      notedata: notetype;
      exitpad,savepad: boolean;
      temp: string;
      ch,mych: char;
      i: byte;
      o: integer;

procedure CursorChange (New: integer; VAR Old: integer);
begin
  Inline($31/$C0/$8E/$C0/$26/$A1/$60/$04/$C4/$7E/<OLD/$AB/$B4/$01/$8B/$4E/<NEW/$CD/$10);
end;

procedure init;
var j: byte;
begin
   with notedata do
   begin
      lastx:=1; lasty:=1;
      insertmode:=false;
      for j:=1 to 22 do note[j]:=blanks(78);
   end;
   j:=(23-length(dialdata.bbsname)) div 2;
   notedata.bbsname:=blanks(j)+dialdata.bbsname+blanks(23-j-length(dialdata.bbsname));
end;

function openpadfile: boolean;
begin
   assign(notefile,dir_notepad+'\'+filename+'.PAD');
   if exist(dir_notepad+'\'+filename+'.PAD') then
   begin
      {$I-}
      reset(notefile);
      if filesize(notefile)=1 then read(notefile,notedata) else init;
   end else
   begin
      {$I-}
      showmsg('Could not locate file',dir_notepad+'\'+filename+'.PAD');
      init;
      rewrite(notefile);
   end;
   if ioresult=0 then openpadfile:=true else
   begin
      showmsg('Problem opening file',dir_notepad+'\'+filename+'.PAD');
      openpadfile:=false;
      exitpad:=true;
      savepad:=false;
   end;
   {$I+}
end;

procedure saveit;
begin
   if savepad then
   begin
      {$I-}
      seek(notefile,0);
      write(notefile,notedata);
      close(notefile);
      if ioresult<>0 then
      begin
         showmsg('Problem saving file',dir_notepad+'\'+filename+'.PAD');
         exitpad:=true;
         savepad:=false;
      end;
      {$I+}
   end;
end;

procedure showdata;
var y,c: byte;
begin
   c:=attr(white,blue);
   for y:=2 to 23 do fwrite(notedata.note[y-1],y,2,c);
   fwrite(' '+notedata.bbsname+' ',1,29,attr(white,cyan));
   fwritena('[ Alt-N:         .PAD ]',24,2);
   fwritena(filename+'',24,11);
end;

begin
   if filename>'' then
   begin
      hidemouse;
      if openpadfile then
      with notedata do
      begin
         exitpad:=false;
         savepad:=true;
         cursor(true);
         savevideo(videoback,true);
         wx:=wherex; wy:=wherey;
         window(1,1,80,25);
         makebox(attr(white,blue),1,1,80,24,1);
         fwritena('´'+blanks(25)+'Ã',1,28);
         i:=hattr(white,cyan);
         fwrite(blanks(30)+'1.7K static Notepad'+blanks(31),25,1,i);
         i:=(23-length(dialdata.bbsname)) div 2;
         notedata.bbsname:=blanks(i)+dialdata.bbsname+blanks(23-i-length(dialdata.bbsname));
         showdata;
         gotoxy(lastx+1,lasty+1);
         if insertmode then cursorchange(5,o);
         color(yellow,blue);
         repeat
            showmouse;
            repeat
               mouseposition(rat);
               if (rat.mx>1) and (rat.mx<80) and (rat.my>1) and (rat.my<24) then
               begin
                  if rat.stat=leftpress then
                  begin
                     mousepress(leftbutton,rat);
                     if rat.pcount=1 then
                     begin
                        lastx:=rat.mx-1; lasty:=rat.my-1;
                        gotoxy(rat.mx,rat.my);
                     end;
                  end else
                  if rat.stat=rightpress then
                  begin
                     mousepress(rightbutton,rat);
                     exitpad:=rat.pcount=1;
                  end;
               end;
            until (keypressed) or (exitpad);
            hidemouse;
            if keypressed then
            begin
            ch:=readkb;
            if ch=#0 then
            begin
               ch:=readkb;
               case ch of
                  #49: begin
                          i:=0;
                          editflag(1,0,0,1,0,1,0);
                          temp:=pickfile(9,19,dir_notepad+'\*.pad',filename);
                          if temp=filename then
                          mych:=input(attr(white,blue),11,24,temp,8,8,i) else mych:=#13;
                          if (mych=#13) and (temp<>filename) then
                          begin
                             saveit;
                             filename:=temp;
                             if openpadfile then;
                          end;
                          showdata;
                       end;
                  #72: dec(lasty);
                  #80: inc(lasty);
                  #75: dec(lastx);
                  #77: inc(lastx);
                  #71: begin
                          lastx:=1;
                          while (lastx<78) and (note[lasty][lastx]=' ') do inc(lastx);
                          if (lastx=78) and (note[lasty][lastx]=' ') then lastx:=1;
                       end;
                  #79: begin
                          lastx:=78;
                          while (lastx>1) and (note[lasty][lastx]=' ') do dec(lastx);
                          if (lastx=1) and (note[lasty][lastx]=' ') then lastx:=78;
                       end;
                  #73: dec(lasty,5);
                  #81: inc(lasty,5);
                  #82: begin
                          insertmode:=not insertmode;
                          if insertmode then cursorchange(5,o) else cursorchange(o,o);
                       end;
                  #83: begin
                          cursor(false);
                          delete(note[lasty],lastx,1);
                          note[lasty]:=note[lasty]+' ';
                          gotoxy(2,lasty+1);
                          write(note[lasty]);
                          cursor(true);
                      end;
               end;
               if asciichart(ch,mych) then
               begin
                  note[lasty][lastx]:=mych;
                  fwritena(mych,lasty+1,lastx+1);
               end;
               grabline(ch);
               screendump(ch);
               if checkpaste(note[lasty],ch,lastx,78) then xy(2,lasty+1,note[lasty]);
               if lasty>22 then lasty:=1;
               if lasty<1 then lasty:=22;
               if lastx>78 then lastx:=1;
               if lastx<1 then lastx:=78;
            end else
            case ch of
               ^X,
               ^Y: begin
                      cursor(false);
                      note[lasty]:=blanks(78);
                      gotoxy(2,lasty+1); write(note[lasty]);
                      cursor(true);
                      lastx:=1;
                   end;
               #8: begin
                      dec(lastx);
                      if lastx<1 then
                      begin
                         lastx:=78;
                         dec(lasty);
                      end;
                      if lasty<1 then lasty:=22;
                      if insertmode then
                      begin
                         cursor(false);
                         delete(note[lasty],lastx,1);
                         note[lasty]:=note[lasty]+' ';
                         gotoxy(2,lasty+1);
                         write(note[lasty]);
                         cursor(true);
                      end else
                      begin
                         note[lasty][lastx]:=' ';
                         gotoxy(lastx+1,lasty+1);
                         write(' '+#8);
                      end;
                   end;
              #13: begin
                      lastx:=1;
                      inc(lasty);
                      if lasty>22 then lasty:=1;
                   end;
              #27: exitpad:=true;
              else if insertmode then
                   begin
                      if note[lasty][78]=' ' then
                      begin
                         cursor(false);
                         delete(note[lasty],78,1);
                         insert(ch,note[lasty],lastx);
                         gotoxy(2,lasty+1);
                         write(note[lasty]);
                         cursor(true);
                         inc(lastx);
                         if lastx>78 then
                         begin
                            lastx:=1;
                            inc(lasty);
                         end;
                         if lasty>22 then lasty:=1;
                      end;
                   end else
                   begin
                      write(ch);
                      note[lasty][lastx]:=ch;
                      inc(lastx);
                      if lastx>78 then
                      begin
                         lastx:=1;
                         inc(lasty);
                      end;
                      if lasty>22 then lasty:=1;
                   end;
            end;
            gotoxy(lastx+1,lasty+1);
            end;
         Until exitpad;
         saveit;
         savevideo(videoback,false);
         if notedata.insertmode then cursorchange(o,o);
         gotoxy(wx,wy);
         statusbar;
      end;
      {$I+}
   end else showmsg('NOTEPAD error','No file name specified');
end;

end.
