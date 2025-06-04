program test;

type stringname = string[25];
var tfile: text;
    line: string;

function cmsg(st: string): string;
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
   line:=paramstr(1)+' '+paramstr(2);
   if line=' ' then
   begin
      writeln;
      write('give me something: ');
      readln(line);
   end;
   writeln('input: ',line);
   assign(tfile,'crypt.txt');
   rewrite(tfile);
   writeln(tfile,'SCRAMBLE: ',scramble(line));
   writeln('scramble: ',scramble(line));
   line:=cmsg(line);
   writeln(tfile,'*',line,'*');
   close(tfile);
   writeln('output: *',line,'*');
end.