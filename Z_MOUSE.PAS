unit z_mouse;

Interface

Uses DOS,crt;

const leftpress = 1;
      rightpress = 2;
      leftbutton = 0;
      rightbutton = 1;
      centerbutton = 2;

type mousetype=record
        stat,mx,my,
        lastpx,lastpy,pcount,
        lastrx,lastry,rcount: word;
     end;

var mouse_reg: registers;
    mouse_installed,
    mousehidden,fadeon: Boolean;

function initmouse: word;
procedure showmouse;
procedure hidemouse;
procedure mouseposition(var mouse: mousetype);
procedure setmouseposition(mousex, mousey: word);
procedure mousepress(button: word; var mouse: mousetype);
procedure mouserelease(button: word; var mouse: mousetype);
procedure setmousexy(x1,y1,x2,y2: word);
procedure restoremousexy;
procedure setpixeltomickey(horiz,verti : word);
procedure DisableMouseDrvr;
procedure EnableMouseDrvr;

implementation

procedure fadescreen;

Const Colors=64;
      DelayAmt=200;
      Steps=25;

Type  PalType=Array[0..Colors-1] of Record
         R,G,B: Byte;
       end;

Var OrigPal: PalType;
    lms: boolean;
    rat: mousetype;
    i: word;

Procedure GetPal(Var OrigPal: PalType);
var Reg: Registers;
Begin
   With Reg Do
   begin
     ax:=$1017;
     bX:=0;
     cx:=Colors;
     es:=Seg(OrigPal);
     dx:=Ofs(OrigPal);
     Intr($10,Reg);
   end;
end;

Procedure FadePal(OrigPal: PalType; FadeOut: Boolean);
Var Reg: Registers;
    WorkPal: PalType;
    Fade,I: Word;
    Pct: Real;
Begin
   With Reg do
   For Fade:=0 to Steps do
   begin
      Pct:=Fade / Steps;
      If FadeOut Then Pct:=1 - Pct;
      For I:=0 to Colors - 1 do
      With WorkPal[I] do
      Begin
         R:=Round(OrigPal[I].R * Pct);
         G:=Round(OrigPal[I].G * Pct);
         B:=Round(OrigPal[I].B * Pct);
      End;
      ax:=$1012;
      bx:=0;
      cx:=Colors;
      es:=Seg(WorkPal);
      dx:=Ofs(WorkPal);
      Intr($10,Reg);
      Delay(DelayAmt);
   end;
end;

begin
   fadeon:=true;
   lms:=mousehidden;
   hidemouse;
   GetPal(OrigPal);
   FadePal(OrigPal,True);
   repeat
      mouseposition(rat);
   until (keypressed) or (rat.mx<80) or (rat.my>1);
   if keypressed then
   begin
      if readkey=#0 then if readkey=#0 then;
      setmouseposition(79,2);
   end;
   FadePal(OrigPal,False);
   if not lms then showmouse;
   fadeon:=false;
end;

function initmouse: word;
{ Function 0 - Initialize mouse software and hardware }
begin
   mouse_reg.ax:=0;
   intr($33,mouse_reg);
   initmouse:=mouse_reg.ax;
end;

procedure showmouse;
{ function 1 - show mouse cursor }
begin
  mouse_reg.ax:=1;
  intr($33,mouse_reg);
  mousehidden:=false;
end;

procedure hidemouse;
{ function 2 - hide mouse cursor }
begin
  if not mousehidden then
  begin
     mousehidden:=true;
     mouse_reg.ax:=2;
     intr($33,mouse_reg);
  end;
end;

procedure mouseposition(var mouse: mousetype);
{ function 3 - return mouse position and button status }
{ x and y values scaled for 80 col text mode }
begin
   mouse_reg.ax:=3;
   intr($33,mouse_reg);
   with mouse_reg do
   begin
      mouse.mx:=succ(cx div 8);
      mouse.my:=succ(dx div 8);
      mouse.stat:=bx;
      if (not fadeon) and (mouse.mx=80) and (mouse.my=1) then fadescreen;
   end;
end;

procedure setmouseposition(mousex, mousey: word);
{ function 4 - sets mouse position  }
{ x and y values scaled for 80 col text mode }
begin
   mouse_reg.ax:=4;
   mouse_reg.cx:=pred(mousex*8);
   mouse_reg.dx:=pred(mousey*8);
   intr($33,mouse_reg);
end;

procedure mousepress(button: word; var mouse: mousetype);
{ function 5 - gets button press information  }
{ x and y values scaled for 80 col text mode }
{ Returns the current status of all mouse buttons, and the number of
  presses and position of the last press for a specifed mouse button
  since the last call to this procedure for that button.  The press
  counter for the button is reset to zero.
  Call:    Button = button identifier
      0 = left button
      1 = right button
      2 = center button
  Returns: Stat   = button status
      bit(s)  Significance(if set)
      0       left button is down
      1       right button is down
      2       center button is down
      3-15    reserved(0)
    Count  = button press counter
    Horiz  = horizontal (X) coordinate of last button press
    Vert   = vertical (Y) coordinate of last button press
}
begin
   mouse_reg.ax:=5;
   mouse_reg.bx:=button;
   intr($33,mouse_reg);;
   mouse.stat:=mouse_reg.ax;
   mouse.pcount:=mouse_reg.bx;
   mouse.lastpx:=succ(mouse_reg.cx div 8);
   mouse.lastpy:=succ(mouse_reg.dx div 8);
end;

procedure mouserelease(button: word; var mouse: mousetype);
{ function 6 - gets button release information  }
{ x and y values scaled for 80 col text mode }
begin
  mouse_reg.ax:=6;
  mouse_reg.bx:=button;
  intr($33,mouse_reg);;
  mouse.stat:=mouse_reg.ax;
  mouse.rcount:=mouse_reg.bx;
  mouse.lastrx:=succ(mouse_reg.cx div 8);
  mouse.lastry:=succ(mouse_reg.dx div 8);
end;

procedure setmousexy(x1,y1,x2,y2: word);
{ functions 7 and 8 - sets min/max values for horizontal/vertical  }
{ x and y values scaled for 80 col text mode }
begin
  mouse_reg.ax:=7;
  mouse_reg.cx:=pred(x1*8);
  mouse_reg.dx:=pred(x2*8);
  intr($33,mouse_reg);
  mouse_reg.ax:=8;
  mouse_reg.cx:=pred(y1*8);
  mouse_reg.dx:=pred(y2*8);
  intr($33,mouse_reg);
end;

procedure restoremousexy;
{ functions 7 and 8 - restores min/max values for CGA screen }
begin
  mouse_reg.ax:=7;
  mouse_reg.cx:=0;
  mouse_reg.dx:=639;
  intr($33,mouse_reg);
  mouse_reg.ax:=8;
  mouse_reg.cx:=0;
  mouse_reg.dx:=199;
  intr($33,mouse_reg);
end;

procedure setpixeltomickey(horiz,verti : word);
{ function 15 - sets the mickey to pixel ratio }
begin
   with mouse_reg do
   begin
      ax:=15;
      cx:=horiz;
      dx:=verti;
   end;
   intr($33,mouse_reg)
end;

procedure DisableMouseDrvr;
begin
   mouse_reg.ax:=31;
   intr($33,mouse_reg);
   mouse_installed:=false;
end;

procedure EnableMouseDrvr;
begin
  mouse_reg.ax:=32;
  intr($33,mouse_reg);
end;

begin
  enablemousedrvr;
  mouse_installed:= initmouse = 65535;
  mousehidden:=true;
  fadeon:=false;
end.
