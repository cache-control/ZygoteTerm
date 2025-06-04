program cryptfile;

uses crt;

var tinfile,toutfile: text;
    infile,outfile,line: string;


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

begin
   clrscr;
   write('infile: '); readln(infile);
   write('outfile: '); readln(outfile);
   assign(tinfile,infile);
   assign(toutfile,outfile);
   reset(tinfile);
   rewrite(toutfile);

   while not eof(tinfile) do
   begin
      readln(tinfile,line);
      writeln(toutfile,'[',cmsg(line),']');
   end;

   close(tinfile);
   close(toutfile);
end.