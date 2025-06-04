program saver;

uses crt,dos,z_util;
{$m 16000,0,20000}

var name: string;

begin
   configdata.datech:='Ä';
   name:=date;
   name:=name+'.NTM';
   clrscr;
   writeln('creating .zip file in f: drive');
   exec(commandlocation,' /c pkzip -eX -sname a:\'+name+' z*.pas phone\*.dir '+
       'z*.?md z*.wtd z*.doc areadata\z_local.dat *.txt ');
   writeln('done.');
end.
