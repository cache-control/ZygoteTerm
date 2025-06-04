program dir_converter;

uses crt,dos,z_util;

const tempname='!!!!!!!!.!!!';

type     DialType75=Record
                BBSname: string[23];
                BBSphone: string[16];
                Altphone: array[1..2] of string[16];
                Comment: stringdesc;
                Syspass: stringpw;
                emailaddr: array[1..5] of stringdesc;
                User: accounttype;
                Param: paramtype;
                Autosys,Protocol: char;
                usedial: byte;
                Timescalled: integer;
                Checknotepad,Redialflag,autocapture: boolean;
                Scriptname,Lastdate,
                file_kbd,file_tbl,
                file_cap,file_pad: string[8];
                Location: string[24];
                Toll: string[9];
         End;
         DialType85=Record
                BBSname: string[23];
                BBSphone: string[16];
                Altphone: array[1..2] of string[16];
                Comment: stringdesc;
                Syspass: stringpw;
                emailaddr: array[1..5] of stringdesc;
                User: accounttype;
                Param: paramtype;
                Autosys,Protocol: char;
                usedial: byte;
                Timescalled: integer;
                Checknotepad,Redialflag,autocapture: boolean;
                Scriptname,Lastdate,
                file_kbd,file_tbl,
                file_cap,file_pad: string[8];
                Location: string[24];
                Toll: byte;
                execute: stringdesc;
         End;

var lasty,choicei,tempi: byte;
    inname,outname: stringdesc;
    infile,outfile: file;
    choice,tempch: char;
    ioerror: integer;
    count,counter: word;

Function checkvideo: boolean;
var regs: registers;
begin
    regs.ah:=$F;
    intr($10,regs);
    checkvideo:=regs.al<>7;
end;

procedure message(c: byte; s: string);
begin
   window(45,2,79,18);
   gotoxy(1,lasty);
   if c=0 then textcolor(lightred) else textcolor(lightcyan);
   writeln(s);
   lasty:=wherey;
   window(1,1,80,25);
end;

procedure initialize;
begin
   lasty:=1;
   inname:='PHONE\ZYGOTE.DIR';
   outname:='PHONE\ZYGOTE.DIR';
   editflag(1,1,0,1,0,1,1);
   if checkvideo then
   begin
      colorvideo:=true;
      baseofscreen:=$b800;
   end else
   begin
      colorvideo:=false;
      baseofscreen:=$b000;
   end;
   textbackground(0);
   clrscr;
   makebox(attr(cyan,black),1,1,41,19,1);
   fwrite('Zygote to Zygote',1,4,attr(lightcyan,black));
   fwrite('other to Zygote',1,24,attr(lightcyan,black));
   fwritena('Â',1,21); fwritena('Á',19,21);
   vertchars(attr(cyan,black),21,2,18,'³');
   makebox(attr(lightcyan,black),43,1,80,19,1);
   fwrite('messages',1,67,attr(cyan,black));
   makebox(attr(blue,black),1,20,80,22,1);
   fwrite('Input  [                                        ]',21,3,attr(yellow,black));
   makebox(attr(lightblue,black),1,23,80,25,1);
   fwrite('Output [                                        ]',24,3,attr(lightcyan,black));
   fwrite('v7.5 to v8.5',2,3,attr(white,black));
   page.flag:=0;
   timestat.flag:=0;
   with sc do
   begin
      x:=2; y:=2;
      t:=1; s:=19;
      choicei:=1;
      c:=attr(black,lightgray);
      nc:=attr(white,black);
   end;
end;

procedure z75to85;
var indata: dialtype75;
    outdata: dialtype85;
begin
   {$I-}
   counter:=0;
   ioerror:=-1;
   assign(infile,inname);
   reset(infile,sizeof(indata));
   if ioresult=0 then
   begin
      ioerror:=0;
      message(1,'input file opened');
      assign(outfile,tempname);
      rewrite(outfile,sizeof(outdata));
      if ioresult=0 then
      begin
         ioerror:=0;
         message(1,'temp file created');
         while not eof(infile) do
         begin
            inc(counter);
            blockread(infile,indata,1,count);
            ioerror:=ioresult;
            if ioerror=0 then
            begin
               move(indata,outdata,sizeof(indata)-10);
               if pos('Non',indata.toll)>0 then outdata.toll:=1 else
               if pos('Unkn',indata.toll)>0 then outdata.toll:=0 else
                  outdata.toll:=2;
               outdata.execute:='';
               blockwrite(outfile,outdata,1);
               ioerror:=ioresult;
               if ioerror=0 then
               begin
                  message(1,'wrote entry '+its(counter)+'      ');
                  dec(lasty);
               end else message(0,'error found in writing output file')
            end else message(0,'error found in reading input file');
         end;
         close(outfile);
      end else message(0,'problem creating temp file');
      close(infile);
   end else message(0,'problem opening input file');
   {$I+}
end;

procedure temptooutput;
var tempfile: file;
begin
   if ioerror=0 then
   begin
      if exist(tempname) then
      begin
         inc(lasty);
         message(1,'temp file found');
         if exist(outname) then
         begin
            message(1,'output already exists, deleting');
            assign(tempfile,outname);
            erase(tempfile);
         end;
         message(1,'rename temp file to output file');
         {$I-}
         assign(tempfile,tempname);
         rename(tempfile,outname);
         if ioresult=0 then message(1,'output file created') else
            message(0,'problem creating output file');
         {$I+}
      end else message(0,'temp file does not exist');
   end else message(0,'output file not created');
end;

begin
   initialize;
   repeat
      choice:=scrollchoice(#27+#13,choicei);
      if choice=#13 then
      begin
         lasty:=1;
         makebox(attr(lightgray,black),44,2,79,18,5);
         tempi:=0;
         tempch:=input(attr(white,blue),11,21,inname,40,40,tempi);
         tempi:=0;
         if tempch=#13 then tempch:=input(attr(white,blue),11,24,outname,40,40,tempi);
         if tempch=#27 then message(0,'user aborted') else
         begin
           if diskfree(0)>200000 then
           begin
              message(1,'enough diskspace available');
              if exist(inname) then
              begin
                 message(1,'input file found');
                 case choicei of
                   1: z75to85;
                 end;
                 temptooutput;
              end else message(0,'input file could not be found');
           end else message(0,'need a minimum of 200K free diskspace');
         end;
      end;
      fwrite(chars(' ',40),21,11,attr(white,black));
      fwrite(chars(' ',40),24,11,attr(white,black));
   until choice=#27;
   cursor(true);
   color(15,0);
   clrscr;
   writeln('Zygote directory converter');
end.