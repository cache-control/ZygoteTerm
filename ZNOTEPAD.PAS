program notepad;

uses crt,dos;

const maxline = 825;
      headerlen = 12;
type thefiletype = record
        seed1,seed2: byte;
        top,bottom,yon,xon,sizeofarray: integer;
        line: array[1..maxline] of string[78];
     end;
     buftype = array[1..160] of byte;
     videotype = array[1..25] of buftype;
     SCtype=record
             x,y,t,s,c,nc: byte;
     end;

var thefile: file;
    thedata: ^thefiletype;
    videoback: videotype;
    colorvideo,ctrlok,cursorok,forcecap,
    digitok,charok,extendok,
    otherok,waitforretrace,
    needtosave,quit,insertmode,noecho: boolean;
    wx,wy: byte;
    thefilename,grabbuffer,searchstr: string;
    baseofscreen: word;
    lastbarlocation,lasttop: integer;
    sc: sctype;
    Timestat: record
                     flag,x,y,colr: byte;
                   end;
    print : record
               portnum,
               cpace,
               lpace,
               start,
               finish: word;
            end;

procedure Cursor(status: boolean);
begin
   if status then
      Inline($31/$C0/$8E/$C0/$26/$A1/$60/$04/$80/$E4/$DF/$89/$C1/$B4/$01/$CD/$10) else
         Inline($31/$C0/$8E/$C0/$26/$A1/$60/$04/$80/$E4/$BF/$80/$CC/$20/$89/$C1/$B4/$01/$CD/$10);
end;

function keystatus(chk: byte): boolean;
(* rs=$1, ls=$2, ctrl=$4, alt=$8,scroll=$10, numl=$20, cap=$40, ins=$80 *)
var key: byte absolute $0000:$0417;
begin
   keystatus:=(chk and key)>0;
end;

Procedure EditFlag(a,b,c,d,e,f,g: byte);
begin
   charok:=  a=1;  cursorok:= b=1;
   ctrlok:= c=1;   digitok:= d=1;
   extendok:= e=1; forcecap:= f=1;  otherok:=  g=1;
end;

Function Attr(foreground,background: byte): byte;
  {-Translates foreground and background colors into video attributes.
    "And 127" masks out the blink bit. Add 128 to the result to set it.}
begin
   Attr:= ((Background Shl 4) + Foreground) And 127;
end;

Function Hattr(foreground,background: byte): byte;
begin
   if not colorvideo then hattr:=112 else hattr:=attr(foreground,background);
end;

Procedure fwrite(St : string; Row, Col, Attr : integer);
  {-Write St directly to video memory, without snow.}
begin
Inline($1E/$31/$C0/$88/$C1/$8A/$AE/>Row/$FE/$CD/$D1/$E9/$89/$CF/$D1/$EF
       /$D1/$EF/$01/$CF/$8B/$8E/>Col/$49/$D1/$E1/$01/$CF/$8E/$06/>BaseOfScreen
       /$8A/$0E/>WaitForRetrace/$8C/$D2/$8E/$DA/$8D/$B6/>St/$FC/$AC/$91
       /$E3/$29/$8A/$A6/>Attr/$D0/$D8/$73/$1D/$BA/$DA/$03/$AC/$89/$C3/$FA
       /$EC/$A8/$08/$75/$09/$D0/$D8/$72/$F7/$EC/$D0/$D8/$73/$FB/$89/$D8
       /$AB/$FB/$E2/$E8/$EB/$04/$AC/$AB/$E2/$FC/$1F);
end;

Procedure fwritev(var St: string; Row, Col, Attr : integer);
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

Procedure fwritena(St : string; Row, Col : integer);
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

Procedure ChangeAttr(Number : Integer; Row, Col, Attr: Byte);
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

Procedure MoveFromScreen(var Source, Dest; Length : word);
 {-Length = number of WORDS to move from video memory (source) to
   dest.}
begin
Inline($8C/$DB/$A0/>WaitForRetrace/$C4/$7E/<Dest/$C5/$76/<Source/$8B/$4E
       /<Length/$FC/$D0/$D8/$73/$19/$BA/$DA/$03/$FA/$EC/$A8/$08/$75/$09
       /$D0/$D8/$72/$F7/$EC/$D0/$D8/$73/$FB/$AD/$FB/$AB/$E2/$EC/$EB/$02
       /$F2/$A5/$8E/$DB);
end;

Procedure MoveToScreen(var Source, Dest; Length : word);
  {-Length = number of WORDS to move to video memory (dest) from source}
begin
Inline($1E/$A0/>WaitForRetrace/$C4/$7E/<Dest/$C5/$76/<Source/$8B/$4E/<Length
       /$FC/$D0/$D8/$73/$1D/$BA/$DA/$03/$AD/$89/$C3/$FA/$EC/$A8/$08/$75/$09
       /$D0/$D8/$72/$F7/$EC/$D0/$D8/$73/$FB/$89/$D8/$AB/$FB/$E2/$E8/$EB/$02
       /$F2/$A5/$1F);
end;

function its(x: longint): string;
var s:string;
begin
   str(x,s); its:=s;
end;

Function  Blanks(x: integer): string;
var s: string;
Begin
   fillchar(s[1],x,#32);
   s[0]:=chr(x);
   blanks:=s;
end;

Function  Chars(C : char; N: integer): string;
Var s: string;
Begin
   if n<1 then chars:='' else
   begin
      fillchar(s[1],n,c);
      s[0]:=chr(n);
      chars:=s;
   end;
end;

procedure writetime;
var year,month,day,dayofweek: word;
    hour,minute,second,sec100: word;
    colr: byte;
    hr,amorpm: string[2];
    s: string[6];
begin
  gettime(hour,minute,second,sec100);
  s:=':'+chars('0',2-length(its(minute)))+its(minute)+':'+chars('0',2-length(its(second)))+its(second);
  if hour>12 then
  begin
     colr:=attr(lightgreen,black);
     dec(hour,12);
     amorpm:='PM';
     if hour<10 Then hr:='0'+its(hour) else hr:=its(hour);
  end else
  case hour of
         0: begin
               hr:='12';
               amorpm:='AM';
               colr:=attr(lightred,black);
            end;
        12: begin
               hr:='12';
               amorpm:='PM';
               colr:=attr(lightgreen,black);
            end;
       else begin
               hr:=chars('0',2-length(its(hour)))+its(hour);
               amorpm:='AM';
               colr:=attr(lightred,black);
            end;
  end;
  fwrite(hr+s,23,69,attr(white,black));
  fwrite(amorpm+'',23,78,colr);
  getdate(year,month,day,dayofweek);
  fwrite(chars('0',2-length(its(month)))+its(month)+'ฤ'+
         chars('0',2-length(its(day)))+its(day)+'ฤ'+its(year),22,69,attr(white,black));
end;

function readkb: char;
var ClockTick: word absolute $40:$6C;
    lasttick: word;
begin
   repeat
      if abs(clocktick-lasttick)>18 then
      begin
         lasttick:=clocktick;
         writetime;
      end;
   until keypressed;
   readkb:=readkey;
end;

Procedure Makebox(colr,x1,y1,x2,y2,w: byte);
var x,i: byte;
    tl,c,tr,bl,br,s: array[1..5] of char;
begin
   x:=x2-x1+1;
   tl[1]:='ฺ'; c[1]:='ฤ'; tr[1]:='ฟ'; bl[1]:='ภ'; br[1]:='ู'; s[1]:='ณ';
   tl[2]:='ี'; c[2]:='อ'; tr[2]:='ธ'; bl[2]:='ิ'; br[2]:='พ'; s[2]:='ณ';
   tl[3]:='ึ'; c[3]:='ฤ'; tr[3]:='ท'; bl[3]:='ำ'; br[3]:='ฝ'; s[3]:='บ';
   tl[4]:='ษ'; c[4]:='อ'; tr[4]:='ป'; bl[4]:='ศ'; br[4]:='ผ'; s[4]:='บ';
   tl[5]:=' '; c[5]:=' '; tr[5]:=' '; bl[5]:=' '; br[5]:=' '; s[5]:=' ';
   fwrite(tl[w]+chars(c[w],x-2)+tr[w],y1,x1,colr);
   for i:=y1+1 to y2-1 do fwrite(s[w]+blanks(x-2)+s[w],i,x1,colr);
   fwrite(bl[w]+chars(c[w],x-2)+br[w],y2,x1,colr);
end;

Procedure vertchars(colr,x,y,y2: byte; c: char);
var i: byte;
begin
   for i:=y to y2 do fwrite(c+'',i,x,colr);
end;

Procedure showmsg(s1,s2: string);
var back: array[1..13] of buftype;
begin
   movefromscreen(mem[baseofscreen:0],back,sizeof(back) div 2);
   makebox(attr(white,lightgray),23,10,57,13,1);
   changeattr(34,13,24,attr(darkgray,lightgray));
   changeattr(1,11,57,attr(darkgray,lightgray));
   changeattr(1,12,57,attr(darkgray,lightgray));
   fwritena(' Message ',10,36);
   fwrite(blanks((31-length(s1)) div 2)+s1,11,25,attr(black,lightgray));
   fwrite(blanks((31-length(s2)) div 2)+s2,12,25,attr(black,lightgray));
   delay(2500);
   movetoscreen(back,mem[baseofscreen:0],sizeof(back) div 2);
end;

function  asciichart(var ch: char): boolean;
type buffertype = array[1..40] of byte;
var xcor,ycor,i,nc,hc,pc: byte;
    buffer: array[2..15] of buffertype;
    tempch: char;
begin
   for i:=2 to 15 do
   movefromscreen(mem[baseofscreen:160*(i-1)+118],buffer[i],20);
   nc:=attr(lightgray,black);
   hc:=hattr(white,cyan);
   pc:=attr(blue,cyan);
   makebox(attr(cyan,black),60,2,79,15,2);
   fwritena('ฦออออออออออออออออออต',11,60);
   fwrite('Value:',12,62,nc);
   fwrite('Send : [Enter ]',13,62,attr(white,black));
   fwrite('Quit : [Escape]',14,62,attr(white,black));
   for ycor:=3 to 10 do
      for xcor:=62 to 77 do fwrite(chr(ycor*16+xcor+18)+'',ycor,xcor,nc);
   xcor:=62; ycor:=3;
   for i:=3 to 10 do changeattr(1,i,xcor,hc);
   changeattr(16,ycor,62,hc);
   repeat
      fwrite(its(ycor*16+xcor+18)+' ',12,69,attr(yellow,black));
      changeattr(1,ycor,xcor,pc);
      tempch:=readkey;
      if tempch=#0 then
      begin
         tempch:=readkey;
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
      end;
   until (tempch=#27) or (tempch=#13);
   for i:=2 to 15 do
   movetoscreen(buffer[i],mem[baseofscreen:160*(i-1)+118],20);
   if tempch=#27 then asciichart:=false else
   begin
      asciichart:=true;
      ch:=chr(ycor*16+xcor+18);
   end;
end;

procedure savevideo(var buf; wt: boolean);
begin
   if wt then movefromscreen(mem[baseofscreen:0],buf,2000) else
      movetoscreen(buf,mem[baseofscreen:0],2000);
end;

procedure CursorChange (New: integer; VAR Old: integer);
begin
   Inline($31/$C0/$8E/$C0/$26/$A1/$60/$04/$C4/$7E/<OLD/$AB/$B4/$01/$8B/$4E/<NEW/$CD/$10);
end;

Procedure Grabline;
var c: char;
    lx,ly,yloc,mc,
    xloc,startx: byte;
    grab: boolean;
    back: videotype;

procedure strip;
var x: byte;
    s: string;
begin
   if (c=#13) and (grab) then
   begin
      s:='';
      for x:=startx to xloc do s:=s+chr(back[yloc][2*x-1]);
      grabbuffer:=s;
   end;
end;

function cc: byte;
var i: byte;
begin
   i:=back[yloc][2*xloc];
   if i>35 then i:=i-18 else i:=i+18;
   cc:=i;
end;

function where: word;
begin
   where:=160*(yloc-1) + 2*xloc-2;
end;

Begin
   lx:=wherex;
   ly:=wherey;
   xloc:=lx;
   yloc:=ly;
   grab:=false;
   savevideo(back,true);
   mc:=hattr(blue,cyan)+128;
   repeat
      if not grab then fwrite('',yloc,xloc,mc);
      c:=readkb;
      if not grab then movetoscreen(back[yloc,2*xloc-1],mem[baseofscreen:where],1);
      if c=#0 then
      begin
         c:=readkb;
         case c of
              #71: if not grab then xloc:=1;
              #79: begin
                      if grab then
                         for xloc:=startx to 80 do changeattr(1,yloc,xloc,cc);
                      xloc:=80;
                   end;
              #72: if not grab then dec(yloc);
              #80: if not grab then inc(yloc);
              #75: begin
                      movetoscreen(back[yloc,2*xloc-1],mem[baseofscreen:where],1);
                      dec(xloc);
                      if xloc<1 then xloc:=1;
                      if grab then
                      begin
                         if xloc<startx then xloc:=startx;
                         changeattr(1,yloc,xloc,cc);
                      end;
                   end;
              #77: begin
                      inc(xloc);
                      if xloc>80 then xloc:=80;
                      if grab then changeattr(1,yloc,xloc,cc);
                   end;
         end;
         if yloc<1 then yloc:=25;
         if yloc>25 then yloc:=1;
      end else if c=#32 then
      begin
         startx:=xloc;
         grab:=not grab;
         if not grab then savevideo(back,false) else changeattr(1,yloc,xloc,cc);
      end;
   until c in [#13,#27];
   gotoxy(lx,ly);
   savevideo(back,false);
   strip;
End;

function checkpaste(var s: string; lb,rb: byte): boolean;
var x,y: byte;
begin
   y:=1;
   checkpaste:=true;
   for x:=lb to rb do
   begin
      if y<=length(grabbuffer) then
         s[x]:=grabbuffer[y];
      inc(y);
   end;
end;

Function  Input(colr,startx,starty: byte; var line: string; len,field: byte; var laston: byte): char;
const pwc = #22;
var on: byte;
    kb,mych: char;
    o,lb,rb: integer;
    s: string;
    ins: boolean;

    procedure CursorChange (New: integer; VAR Old: integer);
    begin
       Inline($31/$C0/$8E/$C0/$26/$A1/$60/$04/$C4/$7E/<OLD/$AB/$B4/$01/$8B/$4E/<NEW/$CD/$10);
    end;

procedure charp(lb: byte);
var t: string;
    i: integer;
begin
   t:=copy(s,lb,field);
   for i:=1 to length(t) do if t[i]<>' ' then t[i]:=pwc;
   fwrite(t+'',starty,startx,colr);
end;

begin
   ins:=false;
   cursor(false);
   lb:=1; rb:=field;
   s:=line;
   on:=length(s)+1;
   if laston=0 then laston:=on;
   if length(s)<len then s:=s+blanks(len-length(s));
   if laston>field then on:=field else on:=laston;
   if noecho then charp(1) else
   fwrite(copy(s,1,field),starty,startx,colr);
   gotoxy(startx+on-1,starty);
   cursor(true);
   repeat
      kb:=readkb;
      if kb=#0 then
      begin
         kb:=readkb;
         cursor(false);
         case kb of
           #30: if (extendok) and (asciichart(mych)) then
                begin
                   s[on]:=mych;
                   if noecho then charp(lb) else
                   fwrite(copy(s,lb,field),starty,startx,colr);
                end;
           #34: grabline;
           #31: if checkpaste(s,on,length(s)) then
                begin
                   if noecho then charp(lb) else
                   fwrite(copy(s,lb,field),starty,startx,colr);
                end;
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
                   if noecho then charp(lb) else
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
                   if noecho then charp(lb) else
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
                   if noecho then charp(lb) else
                   fwrite(copy(s,lb,field),starty,startx,colr);
                end;
          #119: begin
                   s:=blanks(len);
                   on:=1; lb:=1; rb:=field;
                   if noecho then charp(lb) else
                   fwrite(copy(s,lb,field),starty,startx,colr);
                end;
         end;
         if on<lb then
         begin
            lb:=on;
            rb:=lb+field-1;
            if noecho then charp(lb) else
            fwrite(copy(s,lb,field),starty,startx,colr);
         end else
         if on>rb then
         begin
            rb:=on;
            lb:=rb-field+1;
            if noecho then charp(lb) else
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
                 if noecho then charp(lb) else
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
                  if noecho then charp(lb) else
                  fwrite(copy(s,lb,field),starty,startx,colr);
                  gotoxy(startx+on-lb,starty);
                  cursor(true);
               end;
               kb:=#0;
        end;
      end;
   until kb in [#13,#27,#72,#80,#73,#81];
   laston:=on-lb+1;
   while s[length(s)]=' ' do delete(s,length(s),1);
   line:=copy(s,1,len);
   if ins then cursorchange(O,O);
   cursor(true);
end;

function ask(desc: string; var s: string; size: byte): boolean;
var buffer: array[1..480] of byte;
    border,textc,hilight,
    field,lo,lx,ly: byte;
    mystr: string;
    ch: char;
begin
   movefromscreen(mem[baseofscreen:160],buffer,240);
   lx:=wherex; ly:=wherey;
   border:=attr(cyan,black);
   textc:=attr(white,black);
   hilight:=attr(yellow,blue);
   fwrite('ฦอออออออออออออออออออออออออออต',2,26,border);
   fwrite('ณ                           ณ',3,26,border);
   fwrite('ิออออออออต        ฦอออออออออพ',4,26,border);
   fwrite(desc+'',4,36,hilight);
   if size>27 then field:=27 else field:=size;
   lo:=0;
   mystr:=s;
   ch:=input(textc,27,3,mystr,size,field,lo);
   if ch=#13 then
   begin
      s:=mystr;
      ask:=true;
   end else ask:=false;
   gotoxy(lx,ly);
   movetoscreen(buffer,mem[baseofscreen:160],240);
end;

function exist(tfile: string): boolean;
var checkfile: text;
begin
   if tfile='' then exist:=false else
   begin
      assign(checkfile,tfile);
      {$I-} reset(checkfile); {$I+}
      if ioresult=0 then
      begin
         exist:=true;
         close(checkfile);
      end else exist:=false;
   end;
end;

Function  ScrollChoice(Out: string; Var on: byte): char;
Var back: array[1..80] of byte;
    s: string;
    last: byte;
    quit: boolean;
    c: char;

Begin
   quit:=false;
   last:=on;
   if not colorvideo then sc.c:=hattr(0,7);
   movefromscreen(mem[baseofscreen:160*(sc.y+on-2)+2*sc.x-2],back,sc.s);
   changeattr(sc.s,sc.y+on-1,sc.x,sc.c);
   cursor(false);
   repeat
      if last<>on then
      begin
         movetoscreen(back,mem[baseofscreen:160*(sc.y+last-2)+2*sc.x-2],sc.s);
         movefromscreen(mem[baseofscreen:160*(sc.y+on-2)+2*sc.x-2],back,sc.s);
         changeattr(sc.s,sc.y+on-1,sc.x,sc.c);
         last:=on;
      end;
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
      end else
      if pos(c,out)>0 then
      begin
         quit:=true;
         scrollchoice:=c;
      end;
   until quit;
   movetoscreen(back,mem[baseofscreen:160*(sc.y+last-2)+2*sc.x-2],sc.s);
end;

(************** We'll start here ******************)

procedure initprogram;
const ImageData : array [1..4000] of Char = (
    'R' ,#7  ,'e' ,#7  ,'g' ,#7  ,'i' ,#7  ,'s' ,#7  ,'t' ,#7  ,'e' ,#7  ,
    'r' ,#7  ,'e' ,#7  ,'d' ,#7  ,' ' ,#7  ,'e' ,#7  ,'x' ,#7  ,'c' ,#7  ,
    'l' ,#7  ,'u' ,#7  ,'s' ,#7  ,'i' ,#7  ,'v' ,#7  ,'e' ,#7  ,'l' ,#7  ,
    'y' ,#7  ,' ' ,#7  ,'t' ,#7  ,'o' ,#7  ,':' ,#7  ,' ' ,#7  ,'L' ,#15 ,
    'o' ,#15 ,'n' ,#15 ,'g' ,#15 ,' ' ,#15 ,'P' ,#15 ,'h' ,#15 ,'u' ,#15 ,
    ' ' ,#15 ,'N' ,#15 ,'g' ,#15 ,'u' ,#15 ,'y' ,#15 ,'e' ,#15 ,'n' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,'า' ,#3  ,'ฤ' ,#3  ,
    'ท' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'ึ' ,#3  ,'ฤ' ,#3  ,'ท' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'ฤ' ,#3  ,'า' ,#3  ,'ฤ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,'า' ,#3  ,'ฤ' ,#3  ,'ท' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,'า' ,#3  ,'ฤ' ,#3  ,'ท' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    'ึ' ,#3  ,'ฤ' ,#3  ,'ท' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'า' ,#3  ,
    'ฤ' ,#3  ,'ท' ,#3  ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    'บ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    'บ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'บ' ,#11 ,' ' ,#11 ,'บ' ,#11 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,'บ' ,#11 ,' ' ,#11 ,'บ' ,#11 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#11 ,'บ' ,#11 ,' ' ,#11 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,'ว' ,#11 ,'ฤ' ,#11 ,' ' ,#11 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    'ว' ,#11 ,'ฤ' ,#11 ,'ฝ' ,#11 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,'ว' ,#11 ,
    'ฤ' ,#11 ,'ถ' ,#11 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,'บ' ,#11 ,' ' ,#11 ,
    'บ' ,#11 ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#15 ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    'บ' ,#11 ,' ' ,#11 ,'บ' ,#11 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,'บ' ,#11 ,
    ' ' ,#11 ,'บ' ,#11 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#11 ,'บ' ,#11 ,
    ' ' ,#11 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,'บ' ,#11 ,' ' ,#11 ,' ' ,#11 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,'บ' ,#11 ,' ' ,#11 ,' ' ,#11 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,'บ' ,#11 ,' ' ,#11 ,'บ' ,#11 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,'บ' ,#11 ,' ' ,#11 ,'บ' ,#11 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    'บ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,
    'บ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,' ' ,#3  ,'บ' ,#3  ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'ะ' ,#3  ,
    ' ' ,#3  ,'ะ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'ำ' ,#3  ,'ฤ' ,#3  ,
    'ฝ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'ะ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,'ะ' ,#3  ,'ฤ' ,#3  ,'ฝ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,'ะ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,'ฝ' ,#3  ,' ' ,#3  ,'ำ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    'ะ' ,#3  ,'ฤ' ,#3  ,'ฝ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,' ' ,#3  ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,'V' ,#14 ,'e' ,#14 ,'r' ,#14 ,'s' ,#14 ,
    'i' ,#14 ,'o' ,#14 ,'n' ,#14 ,' ' ,#14 ,'1' ,#14 ,'.' ,#14 ,'1' ,#14 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    'E' ,#9  ,'n' ,#9  ,'c' ,#9  ,'r' ,#9  ,'y' ,#9  ,'p' ,#9  ,'t' ,#9  ,
    'i' ,#9  ,'o' ,#9  ,'n' ,#9  ,'/' ,#9  ,'D' ,#9  ,'e' ,#9  ,'c' ,#9  ,
    'r' ,#9  ,'y' ,#9  ,'p' ,#9  ,'t' ,#9  ,' ' ,#9  ,'o' ,#9  ,'p' ,#9  ,
    't' ,#9  ,'i' ,#9  ,'o' ,#9  ,'n' ,#9  ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#9  ,' ' ,#9  ,
    ' ' ,#9  ,' ' ,#9  ,' ' ,#9  ,' ' ,#9  ,' ' ,#9  ,' ' ,#9  ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    'Z' ,#7  ,'y' ,#7  ,'g' ,#7  ,'o' ,#7  ,'t' ,#7  ,'e' ,#7  ,' ' ,#7  ,
    'T' ,#7  ,'e' ,#7  ,'r' ,#7  ,'m' ,#7  ,' ' ,#7  ,'P' ,#7  ,'r' ,#7  ,
    'o' ,#7  ,'d' ,#7  ,'u' ,#7  ,'c' ,#7  ,'t' ,#7  ,' ' ,#7  ,'(' ,#7  ,
    'T' ,#7  ,'M' ,#7  ,')' ,#7  ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,'(' ,#7  ,'C' ,#7  ,')' ,#7  ,' ' ,#7  ,
    'C' ,#7  ,'o' ,#7  ,'p' ,#7  ,'y' ,#7  ,'r' ,#7  ,'i' ,#7  ,'g' ,#7  ,
    'h' ,#7  ,'t' ,#7  ,'e' ,#7  ,'d' ,#7  ,' ' ,#7  ,'1' ,#7  ,'9' ,#7  ,
    '9' ,#7  ,'4' ,#7  ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,'A' ,#7  ,
    'l' ,#7  ,'l' ,#7  ,' ' ,#7  ,'R' ,#7  ,'i' ,#7  ,'g' ,#7  ,'h' ,#7  ,
    't' ,#7  ,'s' ,#7  ,' ' ,#7  ,'R' ,#7  ,'e' ,#7  ,'s' ,#7  ,'e' ,#7  ,
    'r' ,#7  ,'v' ,#7  ,'e' ,#7  ,'d' ,#7  ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#7  ,' ' ,#7  ,' ' ,#7  ,' ' ,#7  ,' ' ,#7  ,' ' ,#7  ,' ' ,#7  ,
    ' ' ,#7  ,' ' ,#7  ,'W' ,#7  ,'r' ,#7  ,'i' ,#7  ,'t' ,#7  ,'t' ,#7  ,
    'e' ,#7  ,'n' ,#7  ,' ' ,#7  ,'b' ,#7  ,'y' ,#7  ,' ' ,#7  ,'M' ,#7  ,
    'y' ,#7  ,' ' ,#7  ,'N' ,#7  ,'g' ,#7  ,'u' ,#7  ,'y' ,#7  ,'e' ,#7  ,
    'n' ,#7  ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,
    ' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#15 ,' ' ,#7  );
   Function checkvideo: boolean;
   var regs: registers;
   begin
      regs.ah:=$F;
      intr($10,regs);
      checkvideo:=regs.al<>7;
   end;
begin
   wx:=wherex; wy:=wherey;
   gotoxy(2,2);
   new(thedata);
   with print do
   begin
      portnum:=1;
      cpace:=0;
      lpace:=0;
      start:=0;
      finish:=0;
   end;
   with thedata^ do
   begin
      xon:=1;
      yon:=1;
      top:=1;
      bottom:=1;
      sizeofarray:=1;
      line[1]:=blanks(78);
      insertmode:=false;
   end;
   thefilename:='NOTEPAD.DAT';
   searchstr:='';
   grabbuffer:='';
   quit:=false;
   lasttop:=0;
   noecho:=false;
   needtosave:=false;
   waitforretrace:=false;
   lastbarlocation:=0;
   colorvideo:=checkvideo;
   if colorvideo then baseofscreen:=$b800 else baseofscreen:=$b000;
   savevideo(videoback,true);
   savevideo(imagedata,false);
   cursor(false);
   if readkey=#0 then if readkey=#0 then;
   cursor(true);
end;

procedure closeprogram;
begin
   dispose(thedata);
   savevideo(videoback,false);
   gotoxy(wx,wy);
end;

procedure slidebar;
var i: integer;
    s1,s2,s3,s4: string[3];
begin
   if thedata^.yon=1 then i:=1 else
   i:= trunc( thedata^.yon / thedata^.sizeofarray * 19 );
   if i=0 then i:=1;
   if i<>lastbarlocation then
   begin
      if lastbarlocation=0 then lastbarlocation:=1;
      fwritena('ฑ',lastbarlocation+1,80);
      fwritena('þ',i+1,80);
      lastbarlocation:=i;
   end;
   s1:=its(thedata^.xon); s2:=its(thedata^.yon);
   s3:=its(thedata^.top); s4:=its(thedata^.bottom);
   fwritena(chars('0',3-length(s1))+s1+','+chars('0',3-length(s2))+s2,1,3);
   fwritena(chars('0',3-length(s3))+s3+'/'+chars('0',3-length(s4))+s4,24,73);
   if needtosave then fwritena('้',24,70) else fwritena(' ',24,70);
   s1:=its( (thedata^.yon div 20)+1); s2:=its(thedata^.sizeofarray);
   fwritena(chars('0',2-length(s1))+s1+', '+chars('0',3-length(s2))+s2,1,71);
end;

procedure drawwindow;
var border,altkeys,thetext,
    sidebar,thetitle: byte;
begin
    border:=attr(cyan,black);
    altkeys:=attr(yellow,black);
    thetext:=attr(lightgray,black);
    sidebar:=attr(white,cyan);
    thetitle:=hattr(white,green);
    makebox(border,1,1,80,25,2);
    fwritena('[       ]',1,2);
    fwritena('[ Page   ,     ]',1,64);
    fwritena('ต                           ฦ',1,26);
    fwritena('ฦอออออออัอออออออออออออออัอออออออัอออออออออออัอออออออัออออออออออออออัอออออออออออต',21,1);
    fwritena('ิอออออออฯอออออออออออออออฯอออออออฯอออออออออออฯอออออออฯออออออออออออออฯอออออออออออพ',25,1);
    vertchars(border,9,22,24,'ณ'); vertchars(border,25,22,24,'ณ'); vertchars(border,33,22,24,'ณ');
    vertchars(border,45,22,24,'ณ'); vertchars(border,53,22,24,'ณ'); vertchars(border,68,22,24,'ณ');
    fwrite(' Notepad ',1,27,thetitle);
    vertchars(sidebar,80,2,20,'ฑ');
    fwrite('Alt-A',22,3,altkeys); fwrite('Alt-G',22,27,altkeys); fwrite('Alt-P',22,47,altkeys);
    fwrite('Alt-E',23,3,altkeys); fwrite('Alt-J',23,27,altkeys); fwrite('Alt-Q',23,47,altkeys);
    fwrite('Alt-F',24,3,altkeys); fwrite('Alt-L',24,27,altkeys); fwrite('Alt-S',24,47,altkeys);
    fwrite('Ascii chart',22,11,thetext);  fwrite('Grab text',22,35,thetext); fwrite('Print',22,55,thetext);
    fwrite('Erase line',23,11,thetext);   fwrite('Jump page',23,35,thetext); fwrite('Quit program',23,55,thetext);
    fwrite('Find word',24,11,thetext);    fwrite('Load file',24,35,thetext); fwrite('Stamp text',24,55,thetext);
end;

function getyn(msg: string): boolean;
var buffer: array[1..480] of byte;
    lx,ly: byte;
    c: char;
begin
   lx:=wherex; ly:=wherey;
   movefromscreen(mem[baseofscreen:160],buffer,240);
   makebox(attr(cyan,black),48,2,79,4,2);
   fwrite(msg+'',3,49,attr(lightgray,black)); fwrite('(Y/n)',3,72,attr(lightgray,black));
   fwritena('ั',2,77); fwritena('ณ',3,77); fwritena('ฯ',4,77);
   gotoxy(78,3);
   repeat
      c:=upcase(readkey);
   until c in ['N','Y',#13];
   getyn:= c <> 'N';
   movetoscreen(buffer,mem[baseofscreen:160],240);
   gotoxy(lx,ly);
end;

procedure loadfile(name: string);
var tempdata: ^thefiletype;
    loop,recsread: integer;
    seed1x,seed2x: byte;
    s: string[8];

   procedure getseed(pwd: string);
   var i,j: integer;
   begin
      seed1x:=0;
      seed2x:=0;
      j:=length(pwd);
      for i:=1 to length(pwd) do
      begin
         seed1x:=ord(pwd[i])*i + seed1x;
         seed2x:=ord(pwd[i])*j + seed2x;
         dec(j);
      end;
   end;

   procedure decode;
   var y,x: integer;
       i1,i2: byte;
   begin
      showmsg('Now start read','and begin decoding');
      with tempdata^ do
      begin
         i1:=seed1; i2:=seed2;
         for y:=1 to sizeofarray do
         begin
            for x:=1 to 78 do
            begin
               i1:=i1-x; i2:=i2+x;
               if odd(x) then line[y][x]:=chr(ord(line[y][x])+i1) else
                  line[y][x]:=chr(ord(line[y][x])-i2);
            end;
         end;
      end;
   end;

begin
   lasttop:=0;
   needtosave:=false;
   new(tempdata);
   if exist(name) then
   begin
      {$I-}
      assign(thefile,name);
      reset(thefile,1);
      blockread(thefile,tempdata^,headerlen,recsread);
      s:='';
      noecho:=true;
      editflag(1,0,0,1,0,1,0);
      if (ask('Password',s,8)) and (s>'') then
      begin
         getseed(s);
         if (seed1x=tempdata^.seed1) and (seed2x=tempdata^.seed2) then
         begin
            for loop:=1 to tempdata^.sizeofarray do
                blockread(thefile,tempdata^.line[loop],sizeof(tempdata^.line[loop]),recsread);
            if ioresult=0 then
            begin
               decode;
               thedata^:=tempdata^;
            end else showmsg('Problem reading file',name);
         end else showmsg('Load aborted','bad password');
      end else showmsg('Load aborted','bad password');
      noecho:=false;
      close(thefile);
      if ioresult=0 then;
     {$I+}
   end else
   begin
      showmsg('File not found '+name,'Creating new file');
      with thedata^ do
      begin
         xon:=1;
         yon:=1;
         top:=1;
         bottom:=1;
         lastbarlocation:=0;
         sizeofarray:=1;
         line[1]:=blanks(78);
      end;
   end;
   dispose(tempdata);
end;

procedure savefile(name: string);
var loop: integer;
    pwd: string[8];
    tempdata: ^thefiletype;

   procedure getseed(pwd: string);
   var i,j: integer;
   begin
      with tempdata^ do
      begin
         seed1:=0;
         seed2:=0;
         j:=length(pwd);
         for i:=1 to length(pwd) do
         begin
            seed1:=ord(pwd[i])*i+seed1;
            seed2:=ord(pwd[i])*j+seed2;
            dec(j);
         end;
      end;
   end;

   procedure encode;
   var i1,i2: byte;
       x,y: integer;
   begin
      showmsg('Now start encoding','and begin write');
      with tempdata^ do
      begin
         i1:=seed1; i2:=seed2;
         for y:=1 to sizeofarray do
         begin
            with tempdata^ do
            for x:=1 to 78 do
            begin
               i1:=i1-x; i2:=i2+x;
               if odd(x) then line[y][x]:=chr(ord(line[y][x])-i1) else
                  line[y][x]:=chr(ord(line[y][x])+i2);
            end;
         end;
      end;
   end;

begin
   new(tempdata);
   pwd:='';
   noecho:=true;
   editflag(1,0,0,1,0,1,0);
   if (ask('Password',pwd,8)) and (pwd>'') then
   begin
      {$I-}
      tempdata^:=thedata^;
      getseed(pwd);
      encode;
      assign(thefile,name);
      rewrite(thefile,1);
      blockwrite(thefile,tempdata^,headerlen);
      for loop:=1 to tempdata^.sizeofarray do
          blockwrite(thefile,tempdata^.line[loop],sizeof(tempdata^.line[loop]));
      if ioresult=0 then
      begin
         needtosave:=false;
         close(thefile);
         showmsg('File has been saved',name);
      end else showmsg('Problem saving file',name);
      {$I+}
   end else showmsg('Save aborted','bad password');
   noecho:=false;
   dispose(tempdata);
end;

procedure checkquit;
begin
   if getyn('Do you want to quit') then
   begin
      quit:=true;
      if needtosave then
      begin
         if getyn('Save working file first') then
         begin
            editflag(1,0,0,1,0,1,1);
            if (ask('  Save  ',thefilename,250)) and (thefilename>'') then
                savefile(thefilename) else showmsg('Save aborted','by user');
         end;
      end;
   end;
end;

procedure checksave;
begin
   editflag(1,0,0,1,0,1,1);
   if (ask('  Save  ',thefilename,250)) and (thefilename>'') then
       savefile(thefilename) else showmsg('Save aborted','by user');
end;

procedure checkload;
begin
   editflag(1,0,0,1,0,1,1);
   if needtosave then
   begin
      if getyn('Save working file first') then checksave;
   end;
   thefilename:='';
   if (ask('  Load  ',thefilename,250)) and (thefilename>'') then
      loadfile(thefilename) else showmsg('Load aborted','by user');
end;

procedure writeallarray;
var i: integer;
    c,y: byte;
begin
   y:=2;
   with thedata^ do
   begin
      for i:=top to bottom do
      begin
         if i=yon then c:=attr(black,lightgray) else c:=attr(white,black);
         fwrite(line[i]+blanks(78-length(line[i])),y,2,c);
         inc(y);
      end;
      for i:=bottom+1 to 19 do fwrite(blanks(78),i+1,2,attr(lightgray,black));
   end;
end;

procedure writesingle(colr: byte);
var i: integer;
begin
   with thedata^ do
   begin
      i:=yon-top+2;
      fwrite(line[yon]+blanks(78-length(line[yon])),i,2,colr);
   end;
end;

procedure adjustyon;
const boxsize = 19;
begin
   with thedata^ do
   begin
      if bottom>sizeofarray then
      begin
         bottom:=sizeofarray;
         top:=bottom-boxsize+1;
      end;
      if top<1 then top:=1;
      if yon>bottom then
      begin
         if yon>sizeofarray then yon:=sizeofarray;
         bottom:=yon;
         top:=bottom-boxsize+1;
         if top<1 then top:=1;
      end else if yon<top then
      begin
         if yon<1 then yon:=1;
         top:=yon;
         bottom:=top+boxsize-1;
         if bottom>sizeofarray then bottom:=sizeofarray;
      end;
   end;
end;

procedure jump;
var s: string[3];
    i,c: integer;
begin
   s:='';
   editflag(0,0,0,1,0,0,0);
   if (ask(' Page # ',s,3)) and (s>'') then
   begin
      val(s,i,c);
      if (c=0) and (i<>0) then thedata^.yon:=20*(i-1);
      if thedata^.yon=0 then thedata^.yon:=1;
      lasttop:=0;
   end;
end;

procedure find;
var loop,p,y: integer;
begin
   editflag(1,1,1,1,1,0,1);
   if (ask('  Find  ',searchstr,78)) and (searchstr>'') then
   begin
      p:=0;
      y:=thedata^.yon;
      repeat
         inc(y);
         if y>thedata^.sizeofarray then y:=1;
         p:=pos(searchstr,thedata^.line[y]);
      until (p>0) or (y=thedata^.yon);
      if p>0 then
      begin
         thedata^.yon:=y;
         thedata^.xon:=p;
      end else showmsg('String search was','unsuccessful');
      lasttop:=0;
   end;
end;

function sendptr(pno: word; s: string): boolean;
var p_error,
    i: word;

   function DoInt17(Ch : Char; LPTNo : Word) : Byte;
   Inline($5A/$58/$B4/$00/$CD/$17/$86/$E0);

   function LPTStat(LPTNo : Word) : Byte;
   Inline($5A/$B4/$02/$CD/$17/$86/$C4);

   function LPTReady(ErrorCode : Word) : Boolean;
   begin
      lptready:= errorcode and 48 = 16;
   end;

begin
   pno:=pno-1;
   p_error:=lptstat(pno);
   if lptready(p_error) then
   begin
      sendptr:=true;
      for i:=1 to length(s) do
      begin
         delay(print.cpace);
         p_error:=doint17(s[i],pno);
         if not lptready(p_error) then
         begin
            sendptr:=false;
            exit;
         end;
      end;
   end else sendptr:=false;
end;

procedure printit;
var i,c,ecolr,on: byte;
    loop: word;
    ch: char;

   function getnum(x,y,size: byte; num: integer): integer;
   var s: string[5];
       c,i: integer;
       o: byte;
   begin
      s:=its(num);
      o:=length(s)+1;
      editflag(0,0,0,1,0,0,0);
      if input(ecolr,x,y,s,size,size,o)=' ' then;
      val(s,i,c);
      if c=0 then getnum:=i else getnum:=num;
   end;
begin
   c:=attr(9,0);
   on:=1;
   lasttop:=0;
   ecolr:=attr(white,blue);
   sc.x:=3; sc.y:=3; sc.s:=19; sc.t:=6; sc.c:=hattr(15,3); sc.nc:=attr(11,0);
   fwrite('ีอออออออออออออออออออัอออออออธ',2,2,c);
   fwrite('ณ Port Lpt #        ณ       ณ',3,2,c);
   fwrite('ณ Character pacing  ณ       ณ',4,2,c);
   fwrite('ณ Line pacing       ณ       ณ',5,2,c);
   fwrite('ณ Start from line # ณ       ณ',6,2,c);
   fwrite('ณ Finish at line #  ณ       ณ',7,2,c);
   fwrite('ณ Print             ณ Go    ณ',8,2,c);
   fwrite('ิอออออออออออออออออออฯอออออออพ',9,2,c);
   for i:=3 to 8 do
   begin
      changeattr(sc.s,i,3,sc.nc);
      changeattr(7,i,23,sc.nc);
   end;
   with print do
   repeat
       fwrite(its(portnum)+' ',3,24,sc.nc);
       fwrite(its(cpace)+blanks(4-length(its(cpace))),4,24,sc.nc);
       fwrite(its(lpace)+blanks(4-length(its(lpace))),5,24,sc.nc);
       fwrite(its(start)+blanks(4-length(its(start))),6,24,sc.nc);
       fwrite(its(finish)+blanks(4-length(its(finish))),7,24,sc.nc);
       ch:=scrollchoice(#13+#27,on);
       if ch=#13 then
       case on of
         1: portnum:=getnum(24,3,1,portnum);
         2: cpace:=getnum(24,4,4,cpace);
         3: lpace:=getnum(24,5,4,lpace);
         4: start:=getnum(24,6,4,start);
         5: finish:=getnum(24,7,4,finish);
       end;
   until (ch=#27) or (on=6);
   if ch=#13 then
   with print do
   begin
      if (start<=finish) and (finish<=thedata^.sizeofarray) and (start>0) then
      begin
         showmsg('Initializing printer...','Port #'+its(portnum));
         if sendptr(portnum,#27+'@') then
         begin
            if sendptr(portnum,#27+'x'+#1) then
            if sendptr(portnum,#27+'<') then
            for loop:=start to finish do
            begin
               delay(lpace);
               if not sendptr(portnum,thedata^.line[loop]+#10+#13) then
               begin
                  showmsg('Printer not ready.','Port #'+its(portnum));
                  cursor(true);
                  exit;
               end;
            end;
         end else showmsg('Printer not ready.','Port #'+its(portnum));
      end else showmsg('Range error','Need new values.');
   end;
   cursor(true);
end;

procedure createbox;
type mytype = array[0..3999] of byte;
var x,y,xdir,ydir,xsize,ysize,i,tempx,tempy,loop,c: integer;
    tempstr: string;
    mybuffer: ^mytype;
    ch: char;
begin
   new(mybuffer);
   tempx:=wherex; tempy:=wherey;
   c:=attr(yellow,black);
   movefromscreen(mem[baseofscreen:0],mybuffer^,2000);
   xdir:=2; ydir:=2;
   x:=thedata^.xon+1; y:=thedata^.yon-thedata^.top+2;
   xsize:=78-x+2; ysize:=thedata^.bottom-y+2;
   if (xsize>=xdir) and (ysize>=ydir) then
   begin
      repeat
         fwrite('ฺ'+chars('ฤ',xdir-2)+'ฟ',y,x,c);
         for i:=y+1 to (y+ydir-1)-1 do
         begin
            fwrite('ณ',i,x,c);
            fwrite('ณ',i,x+xdir-1,c);
         end;
         fwrite('ภ'+chars('ฤ',xdir-2)+'ู',y+ydir-1,x,c);

         ch:=readkey;
         if ch=#0 then
         begin
            for i:=tempy to (tempy+ydir-1) do
               movetoscreen(mybuffer^[160*(i-1)+(tempx-1)*2],mem[baseofscreen:160*(i-1)+(tempx-1)*2],xdir);
            ch:=readkey;
            case ch of
               #75: if xdir>2 then dec(xdir);
               #77: if xsize>xdir then inc(xdir);
               #72: if ydir>2 then dec(ydir);
               #80: if ysize>ydir then inc(ydir);
            end;
         end;
      until ch in [#13,#27];
      if ch=#13 then
      with thedata^ do
      begin
         needtosave:=true;
         i:=thedata^.xon;
         tempstr:='ฺ'+chars('ฤ',xdir-2)+'ฟ';
         move(tempstr[1],line[yon][xon],length(tempstr));

         for i:=yon+1 to (yon+ydir-2) do
         begin
            line[i][xon]:='ณ';
            line[i][xon+xdir-1]:='ณ';
         end;

         tempstr:='ภ'+chars('ฤ',xdir-2)+'ู';
         move(tempstr[1],line[yon+ydir-1][xon],length(tempstr));
      end;
   end;
   dispose(mybuffer);
   writeallarray;
end;

procedure main;
var ch: char;
    cursorvar,
    i,loop: integer;
begin
   initprogram;
   drawwindow;
   loadfile(thefilename);
   repeat
      adjustyon;
      slidebar;
      gotoxy(thedata^.xon+1,thedata^.yon-thedata^.top+2);
      if lasttop<>thedata^.top then
      begin
         lasttop:=thedata^.top;
         writeallarray;
      end else writesingle(attr(black,lightgray));
      ch:=readkb;
      if ch=#0 then
      begin
         ch:=readkey;
         with thedata^ do
         case ch of
            #16: checkquit;
            #18: if sizeofarray>1 then
                 begin
                    dec(sizeofarray);
                    for loop:=yon to sizeofarray do line[loop]:=line[loop+1];
                    lasttop:=0;
                 end;
            #25: printit;
            #60: checksave;
            #30: if asciichart(ch) then
                 begin
                    line[yon][xon]:=ch;
                    fwritena(line[yon]+'',yon-top+2,2);
                 end;
            #31: if checkpaste(line[yon],xon,length(line[yon])) then fwritena(line[yon],yon-top+2,2);
            #33: find;
            #34: grabline;
            #36: jump;
            #38: checkload;
            #48: createbox;
            #71: begin
                    xon:=1;
                    while (xon<78) and (line[yon][xon]=' ') do inc(xon);
                    if (xon=78) and (line[yon][xon]=' ') then xon:=1;
                 end;
            #79: begin
                    xon:=78;
                    while (xon>1) and (line[yon][xon]=' ') do dec(xon);
                    if (xon=1) and (line[yon][xon]=' ') then xon:=77;
                    if xon<78 then inc(xon);
                 end;
            #72: if yon>1 then
                 begin
                    writesingle(attr(white,black));
                    dec(yon);
                 end;
            #80: if yon<sizeofarray then
                 begin
                    writesingle(attr(white,black));
                    inc(yon);
                 end;
            #73: begin
                    writesingle(attr(white,black));
                    dec(yon,10);
                 end;
            #81: begin
                    writesingle(attr(white,black));
                    inc(yon,10);
                 end;
            #75: if xon>1 then dec(xon);
            #77: if xon<78 then inc(xon);
            #82: begin
                    insertmode:=not insertmode;
                    if insertmode then cursorchange(13,cursorvar) else cursorchange(cursorvar,cursorvar);
                 end;
            #83: begin
                    delete(line[yon],xon,1);
                    line[yon]:=line[yon]+' ';
                    fwritena(line[yon]+'',yon-top+2,2);
                 end;
           #119: begin
                    writesingle(attr(white,black));
                    yon:=1;
                 end;
           #117: begin
                    writesingle(attr(white,black));
                    yon:=sizeofarray;
                 end;
         end;
      end else
      begin
         needtosave:=true;
         case ch of
            #07,
            #10,
            #27: ;
            #08: with thedata^ do
                 begin
                    dec(xon);
                    if xon<1 then xon:=1;
                    if insertmode then
                    begin
                       delete(line[yon],xon,1);
                       line[yon]:=line[yon]+' ';
                       fwritena(line[yon]+'',yon-top+2,2);
                    end else
                    begin
                       line[yon][xon]:=' ';
                       fwritena(' ',yon-top+2,xon+1);
                    end;
                 end;
            #13: if not insertmode then
                 begin
                    writesingle(attr(white,black));
                    inc(thedata^.yon);
                    thedata^.xon:=1;
                 end else
                 begin
                    if thedata^.sizeofarray<maxline then
                    with thedata^ do
                    begin
                       if yon<bottom then writesingle(attr(white,black));
                       inc(yon);
                       inc(bottom);
                       if bottom>19 then inc(top);
                       inc(sizeofarray);
                       i:=78-xon+1;
                       for loop:=sizeofarray downto yon do
                           line[loop]:=line[loop-1]+blanks(78-length(line[loop-1]));
                       move(line[yon-1][xon],line[yon][1],i);
                       for loop:=xon to 78 do line[yon-1][loop]:=' ';
                       for loop:=i+1 to 78 do line[yon][loop]:=' ';
                       lasttop:=0;
                       xon:=1;
                    end;
                 end;
            else with thedata^ do
                 if insertmode then
                 begin
                    if line[yon][78]=' ' then
                    begin
                       cursor(false);
                       delete(line[yon],78,1);
                       insert(ch,line[yon],xon);
                       fwritena(line[yon],yon-top+2,2);
                       cursor(true);
                       inc(xon);
                       if xon>78 then xon:=78;
                    end;
                 end else
                 begin
                    line[yon][xon]:=ch;
                    fwritena(ch,yon-top+2,xon+1);
                    inc(xon);
                    if xon>78 then xon:=78;
                 end;
         end;
      end;
   until quit;
   if insertmode then cursorchange(cursorvar,cursorvar);
   closeprogram;
end;

begin
   main;
end.
