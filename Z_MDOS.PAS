unit z_mdos;

interface
{$F+,O+}

Procedure minidos;
Procedure systemactive;

implementation

uses crt,dos,z_comio,z_util;

type paramtype = array[1..5] of string[20];
var lastmode: char;
    lastfore,lastback: byte;
    useransi,more,local: boolean;
    globalstr,bootdir: ^string;
    param: ^paramtype;
    lineon,paramnum: byte;

Procedure ansic(fg,bg: byte);
var s: string[20];
    f,b: string[2];
    mode: char;
begin
   if (_CD) and (useransi) then
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

Function nocarrier: boolean;
begin
   nocarrier:=(Not _CD) and (not local);
end;

Procedure print(s: string);
var x: byte;
begin
  if NOT NOCARRIER then
  begin
    if _CD then _putstring(s);
    write(s);
  end;
end;

Procedure println(s: string);
begin
  print(s+#13+#10);
end;

Procedure cls;
begin
   if _CD then _put(12);
   clrscr;
end;

Procedure init;
begin
  more:=true;
  lineon:=0;
  globalstr^:='';
  lastfore:=0;
  lastback:=0;
  local:=not _CD;
  useransi:=true;
  getdir(0,bootdir^);
end;

Procedure help;
begin
   println('');
   ansic(lightred,lastback);
   println('ÄÄÄÍÍÍÍ[ Available functions ]');
   ansic(lightgreen,lastback);
   println('');
   println('  Cd (Chdir)   Cls          Copy   Date     Del           Dir   Exit');
   println('  Md (Mkdir)   Rd (Rmdir)   Time   Toggle   Type (List)   Ver');
   println('');
end;

Procedure showbooleans;
begin
   println('');
   print('Ansi flag  = ');
   if useransi then println('On') else println('Off');
   print('More flag  = ');
   if more then println('On') else println('Off');
   print('Local flag = ');
   if local then println('On') else println('Off');
   println('');
end;

Procedure toggleboolean;
begin
   if paramnum=1 then
   begin
      showbooleans;
      println('TOGGLE <param>');
      println('');
      println('Param = ANSI, MORE, LOCAL');
      println('');
   end else
   begin
     if param^[2]='LOCAL' then local:=not local;
     if param^[2]='ANSI' then useransi:=not useransi else
     if param^[2]='MORE' then more:=not more else println('Invalid parameter '+param^[1]);
     showbooleans;
   end;
end;

Procedure changedir;
var s: string[50];
begin
   if paramnum=1 then
   begin
     println('');
     println('CD <param>, CHDIR <param>');
     println('');
     println('Param = New directory.');
     println('');
   end else
   begin
     {$I-}
     getdir(0,s);
     chdir(param^[2]);
     if IORESULT<>0 then
     begin
        chdir(s);
        println('');
        println('Invalid destination.');
        println('');
     end;
     {$I+}
   end;
end;

Procedure makedir;
var Io: integer;
begin
   if paramnum=1 then
   begin
     println('');
     println('MD <param>, MKDIR <param>');
     println('');
     println('Param = Name of directory.');
     println('');
   end else
   begin
     {$I-}mkdir(param^[2]);{$I+}
     io:=ioresult;
     println('');
     if IO=0 then println('Made '+param^[2]) else println('Was not able to make directory.');
     println('');
   end;
end;

Procedure removedir;
var io: integer;
begin
   if paramnum=1 then
   begin
     println('');
     println('RD <param>, RMDIR <param>');
     println('');
     println('Param = Name of directory.');
     println('');
   end else
   begin
     {$I-}rmdir(param^[2]);{$I+}
     io:=ioresult;
     println('');
     if io=0 then println('Removed '+param^[2]) else println('Was not able to remove directory.');
     println('');
   end;
end;

Function key: char;
var c: char;
begin
   repeat
   until (_rx_ready) or (keypressed) or (Nocarrier);
   if _rx_ready then key:=chr(_get);
   if keypressed then
   begin
      c:=readkb;
      if c=#0 then
      begin
         key:=#0;
         c:=readkb;
         case c of
           #45: ;
         end;
      end else key:=c;
   end;
end;

Function moreprompt: boolean;
var lf: byte;
begin
   if (keypressed) or (_rx_ready) then
   begin
      moreprompt:= not (upcase(key) in [' ','S',#27]);
   end else moreprompt:=true;
   if more then
   begin
     inc(lineon);
     if lineon=24 then
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

Procedure typefile;
var nullfile: text;
    line: string;
begin
   lineon:=0;
   if (paramnum=1) then
   begin
     println('');
     println('TYPE <param>, LIST <param>');
     println('');
     println('Param = Text/Ansi file to read.');
     println('');
   end else
   if exist(param^[2]) then
   begin
     ansic(white,lastback);
     println('');
     assign(nullfile,param^[2]);
     reset(nullfile);
     while (not eof(nullfile)) and (moreprompt) do
     begin
        readln(nullfile,line);
        println(line);
     end;
     close(nullfile);
     println('');
   end else println('File not found!');
end;

Procedure readdir(eraseit: boolean);

const
  MonthStr: array[1..12] of string[3] = (
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

var
  Count: Integer;
  Path,Killpath: string[80];

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

Procedure GetCommand;
var
  I,J: Integer;
  Attr: Word;
  S,D,N,E: string;
  F: File;
begin
  Path := '';
  if paramnum>1 then path:=param^[2];
  Path := FExpand(Path);
  if Path[Length(Path)] <> '\' then
  begin
    Assign(F, Path);
    GetFAttr(F, Attr);
    if (DosError = 0) and (Attr and Directory <> 0) then Path := Path + '\';
  end;
  FSplit(Path, D, N, E);
  if N = '' then N := '*';
  if E = '' then E := '.*';
  killpath:=d;
  Path := D + N + E;
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
  println('Directory of: '+Path);
  FindFirst(Path, ReadOnly + Directory + Archive, F);
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
      if eraseit then
      begin
        inc(kills);
        assign(killfile,killpath+name);
        erase(killfile);
        ansic(lightred+128,lastback);
        print('<< Killed');
      end;
    end;
    println('');
    Inc(Total, Size);
    FindNext(F);
    inc(count);
  end;
  ansic(white,lastback);
  if count=0 then println('No matching files') else
  printLn(#13+#10+blanks(5)+its(Count)+ ' files, '+ its(Total)+ ' bytes, '+its(DiskFree(Ord(Path[1])-64))+ ' bytes free'+#13);
  println('');
end;

begin
  GetCommand;
  FindFiles;
end;

Procedure copyfiles;
begin
  paramnum:=2;
  if bootdir^[length(bootdir^)]<>'\' then param^[2]:=bootdir^+'\'+'NUL' else param^[2]:=bootdir^+'NUL';
  exec(commandlocation,' /c COPY '+copy(globalstr^,6,length(globalstr^))+' > '+param^[2]);
  typefile;
end;

Procedure execute;
begin
  paramnum:=2;
  if bootdir^[length(bootdir^)]<>'\' then param^[2]:=bootdir^+'\'+'NUL' else param^[2]:=bootdir^+'NUL';
  exec(commandlocation,' /c '+copy(globalstr^,6,length(globalstr^))+' > '+param^[2]);
  typefile;
end;

Procedure showver;
begin
   println('');
   println('The Personal ZYG-MiniDOS System');
   println('Version '+cmsg(zversion)+' (C)Copyright Zygote Corp 1989,1991');
   println('            (C)Copyright DigiSEX Inc 1990,1991');
   println('');
end;

Procedure getinput(var s: string);
var max,on: byte;
    ch: char;
begin
   s:='';
   on:=1;
   max:=79-wherex;
   repeat
      ch:=key;
      if ch<>#0 then
      begin
         case ch of
           #8 : if on>1 then
                begin
                  dec(on);
                  print(#8+#32+#8);
                  delete(s,length(s),1);
                end;
           #13,
           #27: ch:=ch;
           else if on<max then
                begin
                   inc(on);
                   print(ch);
                   s:=s+ch;
                end;
         end;
      end;
   until (ch=#13) or (nocarrier);
   while (s[1]=' ') and (s>'') do delete(s,1,1);
   while (s[length(s)]=' ') and (s>'') do delete(s,length(s),1);
   println('');
end;

Procedure startup;
var c: char;
    lt: string[8];
    x: byte;
begin
   window(1,1,80,25);
   ansic(white,black);
   cls;
   showver;
   println('');
end;

Procedure dirname;
var s: string[50];
begin
   getdir(0,s);
   ansic(yellow,lastback);
   print(s+'> ');
end;

Procedure breakline;
var
  x,l: byte;
begin
  l:=1;
  paramnum:=0;
  if globalstr^='' then exit;
  for x:=1 to length(globalstr^) do
  if (globalstr^[x]=' ') then
  begin
    inc(paramnum);
    param^[paramnum]:=copy(globalstr^,l,x-l);
    l:=x+1;
  end;
  if l<=length(globalstr^) then
  begin
    inc(paramnum);
    param^[paramnum]:=copy(globalstr^,l,length(globalstr^)-l+1);
  end;
end;

Procedure minidos;
begin
  new(param);
  new(globalstr);
  new(bootdir);
  init;
  if NOT NOCARRIER then
  begin
    wx:=wherex; wy:=wherey;
    savevideo(videoback,true);
    startup;
    repeat
      dirname;
      ansic(white,lastback);
      getinput(globalstr^);
      globalstr^:=caps(globalstr^);
      breakline;
      if (copy(globalstr^,1,3)='CD\') or (copy(globalstr^,1,3)='CD.') then
      begin
        param^[1]:='CD';
        param^[2]:=copy(globalstr^,3,length(globalstr^));
        paramnum:=2;
      end;
      if (copy(globalstr^,1,4)='DEL\') or (copy(globalstr^,1,4)='DEL.') then
      begin
        param^[1]:='DEL';
        param^[2]:=copy(globalstr^,4,length(globalstr^));
        paramnum:=2;
      end;
      if (globalstr^='HELP') or (globalstr^='?') then help else
      if globalstr^='CLS' then cls else
      if globalstr^='DIR' then readdir(false) else
      if globalstr^='VER' then showver else
      if globalstr^='TIME' then println(#13+#10'The time is '+time(1)+'.'+#10) else
      if globalstr^='DATE' then println(#13+#10'The date is '+date+'.'+#10) else
      if (globalstr^='DEL') or (globalstr^='COPY') then println(#13#10+globalstr^+' <param>'#10) else
      if paramnum>0 then
      begin
         if (length(globalstr^)=2) then if globalstr^[2]=':' then
         begin
           param^[1]:='CD';
           param^[2]:=globalstr^;
           paramnum:=2;
         end;
         if (param^[1]='CD') or (param^[1]='CHDIR') then changedir else
         if (param^[1]='MD') or (param^[1]='MKDIR') then makedir else
         if (param^[1]='RD') or (param^[1]='RMDIR') then removedir else
         if (param^[1]='TYPE') or (param^[1]='LIST') then typefile else
         if (param^[1]='DIR') then readdir(false) else
         if (param^[1]='COPY') then copyfiles else
         if (param^[1]='DEL') then readdir(true) else
         if (param^[1]='TOGGLE') then toggleboolean else
         if (param^[1]='EXEC') then execute;
      end;
    until (globalstr^='EXIT') or (NOCARRIER);
    chdir(bootdir^);
    gotoxy(wx,wy);
    savevideo(videoback,false);
    statusbar;
  end;
  dispose(param);
  dispose(globalstr);
  dispose(bootdir);
end;

procedure systemactive;
var local,wrong,echoback: boolean;
    temp: string[40];

   function out: boolean;
   begin
      out:=((not local) and (not _CD)) or (wrong);
   end;
   procedure printit(s: string);
   begin
      if not out then
      begin
         if _CD then _putstring(s);
         write(s);
      end;
   end;
   procedure cls;
   begin
     if not out then
     begin
        if _CD then _put(12);
        clrscr;
     end;
   end;
   function k: char;
   var c: char;
   begin
      repeat
      until (_rx_ready) or (keypressed) or (out);
      if _rx_ready then k:=chr(_get);
      if keypressed then
      begin
         c:=readkb;
         if c=#0 then
         begin
            k:=#0;
            c:=readkb;
         end else k:=c;
      end;
   end;
   procedure getinput(var s: string; max: byte);
   var on: byte;
       ch: char;
   begin
     s:='';
     on:=1;
     repeat
       ch:=k;
       if ch<>#0 then
       begin
         case ch of
           #8 : if on>1 then
                begin
                   dec(on);
                   printit(#8+#32+#8);
                   delete(s,length(s),1);
                end;
           #13,
           #27: ch:=ch;
           else if on<=max then
                begin
                   inc(on);
                   if echoback then
                   begin
                     if _CD then _put(22);
                     write(ch);
                   end else printit(ch);
                   s:=s+ch;
                end;
         end;
       end;
     until (ch=#13) or (out);
     while (s[1]=' ') and (s>'') do delete(s,1,1);
     while (s[length(s)]=' ') and (s>'') do delete(s,length(s),1);
     printit(#13+#10);
   end;

begin
   wrong:=false;
   local:=not _CD;
   gotoxy(1,wherey);
   clreol;
   keyboarddata.altkey[#4]:='';
   if keystatus($10) then
   begin
      If not out then
      begin
         cls;
         printit('<case sensitive>'+#10+#13);
         printit(' [System code] : ');
         echoback:=true;
         getinput(temp,20);
         echoback:=false;
         wrong:=temp<>configdata.syscode;
         if wrong then
         begin
            wrong:=false;
            printit('Invalid System Code.'+#10+#10+#13);
            wrong:=true;
         end else printit('Validated.'+#10+#10+#13);
         printit('  ÚÄÄÄ´ Access by Remote ÃÄÄÄ¿             '+#10+#13);
         printit('ÚÄ´ Zygote Term by My Nguyen ÃÄÄÄÄÄÄÄÄÄÄÄÄ¿'+#10+#13);
         printit('³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ            ³'+#10+#13);
         printit('³ System owner: '+configdata.username+blanks(25-length(configdata.username))+' ³'+#10+#13);
         printit('³ Help: case sensitive                    ³'+#10+#13);
         printit('ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ'+#10+#13);
         printit('Exec: ');
         getinput(keyboarddata.altkey[#4],50);
      end;
   end else printit('Remote Access Denied: SCROLL LOCK is off.'+#10+#13);
end;

end.
