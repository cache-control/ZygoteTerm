program key;

uses crt,dos;

var ch: char;

begin
   writeln;
   writeln;
   repeat
      ch:=readkey;
      if ch=#0 then
      begin
         ch:=readkey;
         writeln('#0,',ord(ch));
      end;
   until ch=#27;
end.