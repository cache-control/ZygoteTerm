unit Z_emul;

interface

const musicbufsize = 250;
type vtgtype = (us,uk,sp);
     keypadtype = (application,numeric);
     vtcharsettype = (g0_,g1_);
var lemulch: char;
    musicbuf: string[250];
    musicbufptr,codedlf: byte;
    Arg: Array[1..6] of string[3];
    SaveX,SaveY,needbytes,
    Foreground,Argnum: byte;
    Bold,Blink,getparams,
    musicmode,emulmode: boolean;
    vtcharset: vtcharsettype;
    g0,g1,gvt: vtgtype;

procedure scrollup(top,bot: byte);
procedure ansi(ch: char);
procedure vt100(ch: char);
procedure avatar(ch: char);
procedure bgsound(freq,dur,idle: word);
procedure bgcheck;
procedure bgstop;
function  bgactive: boolean;
procedure playmusic(var tune:string);
procedure beepproc;
procedure tabproc;

implementation

uses crt,z_comio,z_util;

const VTresp = '[?1;0c';
      SharpOffset = 60;
      special : array[1..32] of char = (#32,#4,#176,#9,#12,#13,#10,#248,#241,#18,#11,#217,
                                        #191,#218,#192,#197,#196,#196,#196,#196,#196,#195,
                                        #180,#193,#194,#179,#243,#242,#227,#216,#156,#7);
Type QuePtr = ^QueNode;
     QueNode = Record
                  freq,dur,idle: word;
                  Next: QuePtr;
               end;
     QueRec = Record
                 Head,Tail: QuePtr;
              end;

var keypad: keypadtype;
    PitchArray : Array[1..120] Of Integer;
    BaseOctave,Octave,
    GenNoteType,tempo : integer;
    PlayFrac: Byte;
    ClockTickByte: word absolute $40:$6C;
    StartTick,TestTicks,startidle: word;
    BGstat: Boolean;
    duration,idle_time: word;
    Que: QueRec;

procedure QueInit(Var Que: QueRec);
begin
   Que.Head:=Nil;
   Que.Tail:=Nil;
end;

procedure InsertQue(Var Que: QueRec; Freq,Dur,Idle: Word);
Var temp: QuePtr;
begin
   if Que.Head=Nil then
   begin
      New(Que.Head);
      Que.Head^.Freq:=Freq;
      Que.Head^.Dur:=Dur;
      Que.Head^.Idle:=Idle;
      Que.Head^.Next:=Nil;
      Que.Tail:=Que.Head;
   end else
   begin
      temp:=Que.Tail^.Next;
      New(temp);
      Que.Tail^.Next:=temp;
      temp^.Freq:=Freq;
      temp^.Dur:=Dur;
      temp^.Idle:=Idle;
      temp^.Next:=Nil;
      Que.Tail:=temp;
   end;
end;

procedure RetrieveQue(Var Que: QueRec; var Freq,Dur,Idle: Word);
Var temp: QuePtr;
begin
   if Que.Head=Nil then
   begin
      Freq:=0;
      Dur:=0;
      Idle:=0;
   end else
   begin
      Freq:=Que.Head^.Freq;
      Dur:=Que.Head^.Dur;
      Idle:=Que.Head^.Idle;
      temp:=Que.Head;
      Que.Head:=Que.Head^.Next;
      Dispose(temp);
   end;
end;

procedure BGsound(freq,dur,idle: word);
begin
   if memavail>20 then insertQue(Que,freq,dur,idle);
end;

procedure BGcheck;
var freq,dur,idle: word;
    real_duration: real;
begin
   if (Que.Head=Nil) and (not BGstat) then Exit;
   if BGstat then
   begin
      TestTicks:=ClockTickByte-StartTick;
      if TestTicks>=duration then
      begin
        startidle:=clocktickbyte;
        BGstat:=False;
        NoSound;
      end;
   end else
   if idle_time>0 then
   begin
      testticks:=clocktickbyte-startidle;
      if testticks>=idle_time then idle_time:=0;
   end else
   if Que.Head<>Nil then
   begin
      RetrieveQue(Que,freq,dur,idle);
      if freq>0 then Sound(freq) else NoSound;
      BGstat:=True;
      StartTick:=ClockTickByte;
      real_duration:=dur/55.5555555; {convert dur from ms to clock ticks}
      duration:=round(real_duration);
      real_duration:=idle/55.5555555;
      idle_time:=round(real_duration);
   end;
end;

procedure BGstop;
var freq,dur,idle: word;
begin
   BGstat:=false;
   NoSound;
   While Que.Head<>Nil do RetrieveQue(Que,freq,dur,idle);
end;

function BGactive: boolean;
begin
   BGactive:=(BGstat) or (Que.Head<>Nil);
end;

procedure PlayInit;
Const NextFreq = 1.05946309436;
Var   RealFreq: Array[1..7] Of Real;
      BaseFreq: Real;
      J,K     : Integer;
begin
   BaseOctave:=0;
   Octave:=3;
   GenNoteType:=4;
   tempo:=120;
   PlayFrac:=7;
   BaseFreq:=27.5;
   For J:=0 To 7 Do
   begin
      RealFreq[1]:=BaseFreq;
      RealFreq[2]:=RealFreq[1]*NextFreq*NextFreq;
      RealFreq[3]:=RealFreq[2]*NextFreq;
      RealFreq[4]:=RealFreq[3]*NextFreq*NextFreq;
      RealFreq[5]:=RealFreq[4]*NextFreq*NextFreq;
      RealFreq[6]:=RealFreq[5]*NextFreq;
      RealFreq[7]:=RealFreq[6]*NextFreq*NextFreq;
      BaseFreq:=BaseFreq * 2;
      For K:=1 to 7 Do
      begin
         PitchArray[J*7+K]:=Round(RealFreq[K]);
         PitchArray[J*7+K+SharpOffset]:=Round(RealFreq[K]*NextFreq);
      end;
   end;
end;

procedure Playmusic(var tune:string);
Var PlayTime,IdleTime,DotTime,NoteTime,
    NoteType,PitchIndex,Position,Number,
    Code,tunelen,RealOctave: integer;
    Character: Char;

    procedure nval(Pos:integer; var v, code: integer);
    var posn:integer;
    begin
       v:=0;
       posn:=Pos;
       while (posn<=tunelen) and (tune[posn]>='0') and (tune[posn]<='9') do
       begin
          v:=v*10+ord(tune[posn])-48;
          inc(posn);
       end;
       code:=posn-Pos+1;
    end;

    procedure CheckDots;
    begin
       while (Position<=tunelen) and (tune[Position]='.') do
       begin
          DotTime:=DotTime + DotTime div 2;
          inc(Position)
       end;
    end;

begin
   tunelen:=length(tune);
   Position:=1;
   Repeat
      NoteType:=GenNoteType;
      DotTime:=1000;
      Character:=upcase(tune[Position]);
      Case Character Of
        'A'..'G' : begin
                      PitchIndex :=ord(Character)-64+Octave*7;
                      if (Character='A') or (Character='B') then inc(PitchIndex,7);
                      inc(Position);
                      if Position <= tunelen then
                      case tune[Position] of
                        '#',
                        '+': begin
                                inc(PitchIndex,SharpOffset);
                                inc(Position);
                             end;
                        '-': begin
                                inc(PitchIndex,SharpOffset-1);
                                inc(Position);
                             end;
                      end;
                      if (Position<=tunelen) and (tune[Position]>='0') and (tune[position]<='9') then
                      begin
                         nval(Position,NoteType,Code);
                         inc(Position,Code-1)
                      end;
                      CheckDots;
                      NoteTime:=Round(DotTime/tempo/NoteType*240);
                      PlayTime:=Round(NoteTime*PlayFrac/8);
                      IdleTime:=NoteTime-PlayTime;
                      bgsound(PitchArray[PitchIndex],playtime,idletime);
                   end;
             'L' : begin
                      nval(Position+1,GenNoteType,Code);
                      if (GenNoteType<1) or (GenNoteType>64) then GenNoteType:=4;
                      inc(Position,Code);
                   end;
             'M' : if Position<tunelen then
                   begin
                      Case upcase(tune[Position+1]) Of
                         'S': PlayFrac:=6;
                         'N': PlayFrac:=7;
                         'L': PlayFrac:=8;
                      end;
                      inc(Position,2);
                   end;
             '>' : begin
                      RealOctave:=Octave+1;
                      if RealOctave>7 then RealOctave:=3;
                      nval(Position+1,Octave,Code);
                      inc(Position,Code);
                      Octave:=RealOctave;
                   end;
             '<' : begin
                      RealOctave:=Octave-1;
                      if RealOctave<0 then RealOctave:=3;
                      nval(Position+1,Octave,Code);
                      inc(Position,Code);
                      Octave:=RealOctave;
                   end;
             'O' : begin
                      nval(Position+1,Octave,Code);
                      Octave:=Octave+BaseOctave;
                      if Octave>7 then Octave:=3;
                      inc(Position,Code);
                   end;
             'P' : begin
                      NoSound;
                      nval(Position+1,NoteType,Code);
                      if (NoteType<1) or (NoteType>64) then NoteType:=GenNoteType;
                      inc(Position,Code);
                      CheckDots;
                      Idle_Time:=DotTime Div tempo * (240 Div NoteType);
                   end;
             'T' : begin
                      nval(Position+1,tempo,Code);
                      if (tempo<32) or (tempo>255) then tempo:=120;
                      inc(Position,Code);
                   end;
              else inc(Position);
      end;
   Until Position>tunelen;
end;

procedure beepproc;
begin
   wx:=wherex;
   wy:=wherey;
   if configdata.beep then write(^g) else
      changeattr(1,wy,wx,attr(random(7)+9,4)+128);
end;

procedure tabproc;
begin
    wx:=wherex+1;
    while (wx<80) and (not tabpos[wx]) do inc(wx);
    if wx>80 then wx:=80;
    gotoxy(wx,wherey);
{
    x:=wherex;
    i:=configdata.tabsize+1;
    while x>=i do i:=i+configdata.tabsize;
    if i>80 then i:=80;
    gotoxy(i,wherey);
}
end;

procedure clr;
begin
   color(7,0);
   clrscr;
   color(lastfg,lastbg);
end;

procedure scrollup(top,bot: byte);
begin
   movetoscreen(mem[baseofscreen:160*top],mem[baseofscreen:160*(top-1)],(bot-top)*80);
   fwrite(blanks(80),bot,1,7);
end;

procedure scrolldown(num,top,bot: byte);
var dx,i,y: byte;
begin
   y:=bot;
   for i:=(bot-num) downto top do
   begin
      movetoscreen(mem[baseofscreen:160*(i-1)],mem[baseofscreen:160*(y-1)],80);
      dec(y);
   end;
   for dx:=1 to num do fwrite(blanks(80),top+dx-1,1,7);
end;

procedure ModeCode(c: byte);
var v: integer;
begin
   case c of
     0: begin
           foreground:=7;
           lastbg:=0;
           blink:=false;
           bold:=false;
        end;
     1: bold:=true;
     4: if colorvideo then
        begin
           foreground:=3;
           lastbg:=0;
        end else
        begin
           bold:=true;
           blink:=true;
        end;
     5: blink:=true;
     7: begin
           foreground:=0;
           lastbg:=7;
        end;
    30: foreground:=0;        31: foreground:=4;
    32: foreground:=2;        33: foreground:=6;
    34: foreground:=1;        35: foreground:=5;
    36: foreground:=3;        37: foreground:=7;
    40: lastbg:=0;        41: lastbg:=4;
    42: lastbg:=2;        43: lastbg:=6;
    44: lastbg:=1;        45: lastbg:=5;
    46: lastbg:=3;        47: lastbg:=7;
   end;
   if (blink) and (not configdata.blinkfilter) then v:=128 else v:=0;
   if bold then inc(v,8);
   lastfg:=foreground+v;
   restorecolor;
end;

procedure checkcode(c: char);
var i: byte;
    x,y,code: integer;

begin
   if musicmode then
   begin
      case c of
        '0'..'9',
        'A'..'G',
        '#','+',
        '-','L',
        'M','S',
        '<','>',
        'O','P',
        'T','N': begin
                    inc(musicbufptr);
                    musicbuf[musicbufptr]:=c;
                    exit;
                 end;
            '': begin
                    inc(musicbufptr);
                    musicbuf[musicbufptr]:=c;
                    musicbuf[0]:=chr(musicbufptr);
                    if configdata.allowmusic then playmusic(musicbuf);
                 end;
      end;
   end else
   case c of
     '(',
     '#',
     ')',
     '[': if lemulch=^[ then
          begin
             argnum:=0;
             arg[1]:='';
             exit;
          end;
     '0': if lemulch='(' then g0:=sp else
          if lemulch=')' then g1:=sp else
          begin
             if argnum=0 then argnum:=1;
             arg[argnum]:=arg[argnum]+'0';
             exit;
          end;
     '1'..
     '9',
     '?': if lemulch=^[ then
          begin
             if c='7' then
             begin
                savex:=wherex;
                savey:=wherey;
             end else if c='8' then gotoxy(savex,savey);
          end else
          if lemulch='#' then begin end else
          begin
             if argnum=0 then argnum:=1;
             arg[argnum]:=arg[argnum]+c;
             exit;
          end;
     ';': begin
             if argnum=0 then argnum:=2 else inc(argnum);
             arg[argnum]:='';
             exit;
          end;
     'A': if lemulch='(' then g0:=uk else
          if lemulch=')' then g1:=uk else
          begin
             if argnum=0 then x:=1 else val(arg[1],x,code);
             if (code<>0) or (x=0) then x:=1;
             gotoxy(wherex,wherey-x);
          end;
     'B': if lemulch='(' then g0:=us else
          if lemulch=')' then g1:=us else
          begin
             if argnum=0 then x:=1 else val(arg[1],x,code);
             if (code<>0) or (x=0) then x:=1;
             gotoxy(wherex,wherey+x);
          end;
     'C': begin
             if argnum=0 then x:=1 else val(arg[1],x,code);
             if (code<>0) or (x=0) then x:=1;
             gotoxy(wherex+x,wherey);
          end;
     'c': if lemulch<>^[ then
          begin
             val(arg[1],x,code);
             if x=0 then _putstring(VTresp);
          end;
     'D': if lemulch=^[ then
          begin
             codedlf:=wherey-1;
             if wherey=region.bottom then
                scrollup(region.top,region.bottom) else write(^j);
          end else
          begin
             if argnum=0 then x:=1 else val(arg[1],x,code);
             if (code<>0) or (x=0) then x:=1;
             gotoxy(wherex-x,wherey);
          end;
     'E': if lemulch=^[ then
          begin
             codedlf:=wherey-1;
             if wherey=region.bottom then
                scrollup(region.top,region.bottom) else writeln;
          end;
     'g': begin
             val(arg[1],x,code);
             if code<>0 then x:=0;
             if x=0 then tabpos[wherex]:=false else
                if x=3 then for x:=1 to 80 do tabpos[x]:=false;
          end;
     'H',
     'f': if lemulch=^[ then tabpos[wherex]:=true else
          begin
             case argnum of
               2: begin
                    val(arg[2],x,code);
                    if (code<>0) or (x=0) then x:=1;
                    val(arg[1],y,code);
                    if (code<>0) or (y=0) then y:=1;
                  end;
               1: begin
                    val(arg[1],y,code);
                    if (code<>0) or (y=0) then y:=1; x:=1;
                  end;
               0: begin
                     x:=1;
                     y:=1;
                  end;
             end;
             gotoxy(x,y);
          end;
     'J': begin
             color(7,0);
             val(arg[1],x,code);
             if code<>0 then x:=0;
             case x of
               0: makebox(7,1,wherey,80,activescreensize,5);
               1: makebox(7,1,1,80,wherey,5);
               2: clrscr;
             end;
             color(lastfg,lastbg);
          end;
     'K': begin
             val(arg[1],x,code);
             if code<>0 then x:=0;
             wx:=wherex; wy:=wherey;
             case x of
               0: fwrite(blanks(81-wx),wy,wx,7);
               1: fwrite(blanks(wx),wy,1,7);
               2: fwrite(blanks(80),wy,1,7);
             end;
          end;
     'M': if lemulch=^[ then
          begin
             if wherey=region.top then scrolldown(1,region.top,region.bottom) else
                gotoxy(wherex,wherey-1);
          end else
          if lemulch='[' then
          begin
             musicbufptr:=1;
             musicbuf[1]:='M';
             musicmode:=true;
             exit;
          end;
     'm': if argnum=0 then modecode(0) else
             for y:=1 to argnum do
             begin
                val(arg[y],x,code);
                if code<>0 then x:=1;
                modecode(x);
             end;
     'n': begin
             val(arg[1],x,code);
             case x of
               5: _putstring(^[+'0n');
               6: _putstring(#27+'['+its(wherex)+';'+its(wherey)+'R');
             end;
          end;
     'r': case argnum of
             0: begin
                   region.active:=false;
                   region.top:=1;
                   region.bottom:=activescreensize;
                end;
             2: begin
                   val(arg[1],x,code);
                   if (code<>0) or (x<1) or (x>activescreensize) then
                      region.top:=1 else region.top:=x;
                   val(arg[2],x,code);
                   if (code<>0) or (x<1) or (x>activescreensize) then
                      region.bottom:=activescreensize else region.bottom:=x;
                   if region.bottom<region.top then
                   begin
                      region.top:=1;
                      region.bottom:=activescreensize;
                   end;
                   if region.bottom=activescreensize then region.active:=false else
                      region.active:=true;
                end;
          end;
     's': begin
             saveX:=wherex;
             saveY:=wherey;
          end;
     'u': gotoxy(saveX,saveY);
   end;
   emulmode:=false;
   musicmode:=false;
end;

procedure ansi;
begin
   case ch of
      #0: ;
      ^[: emulmode:=true;
      ^L: clr;
      ^G: beepproc;
      ^I: tabproc;
      ^H: if dparam.destructbs then write(^H,' ',^H) else write(^H);
     else if emulmode then checkcode(ch) else write(ch);
   end;
   lemulch:=ch;
end;

procedure vt100;
begin
   case ch of
     #0 : ;
     ^[ : emulmode:=true;
     ^G : beepproc;
     ^I : tabproc;
     ^H : if dparam.destructbs then write(^H,' ',^H) else write(^H);
     'Z': if lemulch=^[ then _putstring(VTresp) else write('Z');
     '=': if lemulch=^[ then keypad:=application else write('=');
     '>': if lemulch=^[ then keypad:=numeric else write('>');
     ^J,
     ^K,
     ^L : begin
             if ch<>^j then codedlf:=wherey-1;
             if wherey=region.bottom then
                scrollup(region.top,region.bottom) else write(^j);
          end;
     ^O : vtcharset:=g0_;
     ^N : vtcharset:=g1_;
     else if not emulmode then
          begin
             if vtcharset=g0_ then gvt:=g0 else gvt:=g1;
             case gvt of
               us: write(ch);
               sp: if (ch>'^') and (ch<'€') then write(special[ord(ch)-94]);
               uk: if ch='#' then write('œ') else write(ch);
             end;
          end else checkcode(ch);
   end;
   lemulch:=ch;
end;

procedure avatar;
begin
   if getparams then
   begin
      case lemulch of
         ^A: begin
                wx:=ord(ch);
                lastfg:= wx and 15;
                lastbg:= wx shr 4;
                color(lastfg,lastbg);
                getparams:=false;
                emulmode:=false;
             end;
         ^H: begin
                case needbytes of
                   2: savey:=ord(ch);
                   1: savex:=ord(ch);
                end;
                dec(needbytes);
                if needbytes=0 then
                begin
                   gotoxy(savex,savey);
                   getparams:=false;
                   emulmode:=false;
                end;
             end;
         ^Y: begin
                case needbytes of
                   2: savex:=ord(ch);
                   1: savey:=ord(ch);
                end;
                dec(needbytes);
                if needbytes=0 then
                begin
                   lemulch:=chr(savex);
                   for wx:=1 to savey do write(lemulch);
                   getparams:=false;
                   emulmode:=false;
                end;
             end;
        else begin
                getparams:=false;
                emulmode:=false;
                lemulch:=#0;
             end;
       end;
   end else
   case ch of
      ^L: begin
             lastfg:=cyan; lastbg:=black;
             color(lastfg,lastbg);
             clrscr;
          end;
      ^Y: begin
             lemulch:=^Y;
             emulmode:=true;
             getparams:=true;
             needbytes:=2;
          end;
      ^V: begin
             lemulch:=^V;
             emulmode:=true;
             getparams:=false;
          end;
      ^A: if lemulch=^V then
          begin
             lemulch:=^A;
             getparams:=true;
          end else write(^A);
      ^B: if lemulch=^V then
          begin
             if not configdata.blinkfilter then inc(lastfg,128);
             emulmode:=false;
          end else write(^B);
      ^C: if lemulch=^V then
          begin
             wy:=wherey;
             if wy<>1 then gotoxy(wherex,wy-1);
             emulmode:=false;
          end else write(^C);
      ^D: if lemulch=^V then
          begin
             wy:=wherey;
             if wy<>activescreensize then gotoxy(wherex,wy+1);
             emulmode:=false;
          end else write(^D);
      ^E: if lemulch=^V then
          begin
             wx:=wherex;
             if wx<>1 then gotoxy(wx-1,wherey);
             emulmode:=false;
          end else write(^E);
      ^F: if lemulch=^V then
          begin
             wx:=wherex;
             if wx<>80 then gotoxy(wx+1,wherey);
             emulmode:=false;
          end else write(^F);
      ^I: tabproc;
      ^G: if lemulch=^V then
          begin
             wx:=wherex;
             wy:=wherey;
             fwrite(blanks(80-wx+1),wy,wx,attr(lastfg,lastbg));
             emulmode:=false;
          end else beepproc;
      ^H: if lemulch=^V then
          begin
             lemulch:=^H;
             needbytes:=2;
             getparams:=true;
          end else if dparam.destructbs then write(^H,' ',^H) else write(^H);
     else ansi(ch);
   end;
end;

begin
   getparams:=false;
   codedlf:=0;
   emulmode:=false;
   QueInit(Que);
   BGstat:=false;
   NoSound;
   PlayInit;
end.