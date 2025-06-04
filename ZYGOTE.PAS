(* FILES: z_config,z_other,zygote *)
(* tollreporter,alt.dir,emailbook,notepad,userinfo
   hostmode,minidos,encrypt
*)
program Zygote_Term;
{$M 13000,0,20000}

uses Overlay,Crt,Dos,Z_comio,Z_util,Z_init,Z_dial,Z_other,Z_config,
     Z_misc,Z_host,Z_mdos,Z_emul,Z_extra,Z_xmodem,Z_zmodem,z_mouse;

const tickdiff=18;
      name_scl='ZYGOTE.SCL';
      scroll_savewhen=50;
      scroll_arraysize=75;
      mbufsize=60;

type  scrolltype = array[1..scroll_arraysize] of buftype;
      capbuftype = array[1..1024] of char;
      scripttype = record
                      str: string[30];
                      cmd,ch: char;
                   end;
      globaltype = record
                      str,val: string[30];
                      ch: char;
                   end;
      consttype = record
                     str: string[15];
                     val: string[10];
                  end;

var   oldcd: boolean;
      rat: mousetype;
      amorpm: string[2];
      hour,min,sec,hund,lasttick: word;
      ModemCh,Keybdch: char;
      Capfile: text;
      Capbuf: capbuftype;
      Nextline,Maxconst,Somecounter,
      Endscript,Maxglobal: byte;
      haltvalue,scroll_numon,
      loopcnt,mbufptr: integer;
      ScriptLine: array[1..50] of scripttype;
      Global: array[1..5] of globaltype;
      Consts: array[1..5] of consttype;
      scroll_file: file of buftype;
      scroll_data: ^scrolltype;
      totalsec: longint;
      mbuf: array[1..mbufsize] of char;
      mbuffull,lastemul,doorwaymode: boolean;

{$O Z_init  } {$O Z_config} {$O Z_dial  } {$O Z_other } {$O Z_host  }
{$O Z_misc  } {$O Z_mdos  } {$O Z_extra } {$O Z_xmodem} {$O Z_zmodem}

procedure inittab;
var tab,i: byte;
begin
   tab:=configdata.tabsize+1;
   for i:=1 to 80 do
   begin
      if i=tab then
      begin
         tabpos[i]:=true;
         tab:=tab+configdata.tabsize;
      end else tabpos[i]:=false;
   end;
end;

procedure checkscrollfile;
var temp: buftype;
    x,sizeoffile: integer;
    templongint: longint;

    procedure statbox;
    begin
       fwrite('ÚÄÄÄÄÂÄÄÄ´            ÃÄÄÄ¿',10,26,attr(cyan,black));
       fwrite('³   %³                    ³',11,26,attr(cyan,black));
       fwrite('ÀÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',12,26,attr(cyan,black));
       fwrite(' '+name_scl+' ',10,36,attr(white,blue));
    end;

begin
   assign(scroll_file,name_scl);
   if not exist(name_scl) then
   begin
      rewrite(scroll_file);
      sizeoffile:=0;
   end else
   begin
      reset(scroll_file);
      sizeoffile:=filesize(scroll_file);
   end;
   if (sizeoffile<>configdata.scrollbacksize) or (sizeoffile=0) then
   with lastdata do
   begin
      close(scroll_file);
      assign(scroll_file,name_scl);
      rewrite(scroll_file);
      scl_nextio:=1;
      scl_full:=false;
      fillchar(temp,sizeof(buftype),0);
      templongint:=longint(diskfree(0) div sizeof(buftype));
      if templongint>configdata.scrollbacksize then
         templongint:=configdata.scrollbacksize else
         templongint:=templongint-((sizeof(configdata) div sizeof(buftype))+10);
      scl_filesize:=templongint;
      configdata.scrollbacksize:=scl_filesize;
      scl_writeok:= scl_filesize>0;
      showmsg('Creating file for scrollback',name_scl+' will hold '+its(scl_filesize)+' lines');
      savevideo(videoback,true);
      cursor(false);
      statbox;
      for x:=1 to scl_filesize do
      begin
         write(scroll_file,temp);
         fwrite(its(trunc(x/scl_filesize*100)),11,27,attr(lightgray,black));
         fwrite(chars('Û',trunc(x/scl_filesize*20)),11,32,attr(lightcyan,black));
      end;
      savevideo(videoback,false);
      open_cfg(false);
      showmsg('New scrollback created','Saving system configuration');
      cursor(true);
   end else lastdata.scl_writeok:=true;
end;

procedure writescrollfile(howmany: integer);
var x: integer;
begin
   if lastdata.scl_writeok then
   with lastdata do
   begin
      seek(scroll_file,scl_nextio-1);
      for x:=1 to howmany do
      begin
         write(scroll_file,scroll_data^[x]);
         inc(scl_nextio);
         if scl_nextio>scl_filesize then
         begin
            scl_nextio:=1;
            scl_full:=true;
            seek(scroll_file,0);
         end;
      end;
   end;
end;

procedure readscrollfile(head,start,stop: integer);
var i: integer;
begin
   if lastdata.scl_writeok then
   begin
      seek(scroll_file,head-1);
      for i:=start to stop do
      begin
         read(scroll_file,scroll_data^[i]);
         inc(head);
         if head>lastdata.scl_filesize then
         begin
            head:=1;
            seek(scroll_file,0);
         end;
      end;
   end;
end;

procedure showscroll;
const screensize = 23;
var scroll_top,scroll_size,temp_size,
    temp,diff,temp_head,first,last,y,i: integer;
    c: char;

   function adjust(number: integer): integer;
   begin
      if number<1 then adjust:=lastdata.scl_filesize+number else
         if number>lastdata.scl_filesize then adjust:=number-lastdata.scl_filesize else
            adjust:=number;
   end;
   procedure readupper;
   var y,i: integer;
   begin
      if (temp_head>first) and (scroll_size<lastdata.scl_filesize) then
      begin
         dec(temp_head,scroll_savewhen);
         if temp_head<first then
         begin
            temp:=abs(first-temp_head);
            temp_head:=first;
         end else temp:=scroll_savewhen;

         y:=scroll_size-temp;
         for i:=scroll_size downto temp+1 do
         begin
            scroll_data^[i]:=scroll_data^[y];
            dec(y);
         end;
         readscrollfile(adjust(temp_head),1,temp);
         scroll_top:=temp-1;
      end;
   end;
   procedure readlower;
   begin
      if (temp_head<last) and (scroll_size<lastdata.scl_filesize) then
      begin
         inc(temp_head,scroll_savewhen);
         if temp_head>last then
         begin
            temp:=abs(temp_head-last);
            temp_head:=last;
         end else temp:=scroll_savewhen;
         movetoscreen(scroll_data^[temp+1],scroll_data^[1],(scroll_size-temp)*80);
         readscrollfile(adjust(temp_head+scroll_size-temp),scroll_size-temp+1,scroll_size);
         scroll_top:=3;
      end;
   end;
   procedure readhome;
   begin
      temp_head:=first;
      scroll_top:=1;
      readscrollfile(adjust(temp_head),1,scroll_size);
   end;
   procedure readend;
   begin
      temp_head:=last;
      scroll_top:=scroll_size-screensize;
      readscrollfile(adjust(temp_head),1,scroll_size);
   end;
   procedure drawstat;
   begin
      makebox(0,1,24,80,25,1);
      fwrite('´             Ã',24,64,attr(lightgray,black));
      fwrite('´             Ã',25,64,attr(lightgray,black));
      fwrite(' Scroll-back ',25,65,attr(white,blue));
   end;

begin
   cursor(false);
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   temp_size:=lastdata.scl_filesize;
   if lastdata.scl_full then
   begin
      if lastdata.scl_filesize>scroll_arraysize then scroll_size:=scroll_arraysize else
         scroll_size:=lastdata.scl_filesize;
      first:=lastdata.scl_nextio;
      last:=lastdata.scl_nextio+lastdata.scl_filesize;
   end else
   begin
      if lastdata.scl_nextio>scroll_arraysize then scroll_size:=scroll_arraysize else
         scroll_size:=lastdata.scl_nextio;
      first:=1;
      last:=lastdata.scl_nextio;
      lastdata.scl_filesize:=last;
   end;

   if lastdata.scl_filesize>scroll_size then last:=last-scroll_size+1 else last:=first;

   temp_head:=last;
   readscrollfile(adjust(temp_head),1,scroll_size);
   scroll_top:=scroll_size-screensize;
   if scroll_top<1 then scroll_top:=1;
   if scroll_size<screensize then makebox(7,1,1,80,23,5);
   diff:=first-1;
   drawstat;
   if not lastdata.scl_writeok then showmsg('Read/write denied','Error in '+name_scl) else
   repeat
       if screensize>scroll_size then temp:=scroll_size else temp:=screensize;
       movetoscreen(scroll_data^[scroll_top],mem[baseofscreen:0],temp*80);
       y:=temp_head-diff+scroll_top-1;
       i:=adjust(y);
       y:=adjust(y+temp-1);
       fwrite(chars(' ',4-length(its(i)))+its(i)+','+its(y)+
                chars(' ',4-length(its(y))),24,67,attr(lightred,black));
       c:=readkey;
       if c=#0 then
       begin
          c:=readkey;
          case c of
            #72: if scroll_top>1 then dec(scroll_top) else readupper;
            #80: if scroll_top+screensize<scroll_size then inc(scroll_top) else readlower;
            #73: if scroll_top>5 then dec(scroll_top,5) else readupper;
            #81: if scroll_top+screensize+4<scroll_size then inc(scroll_top,5) else readlower;
            #71: if scroll_size<lastdata.scl_filesize then readhome else
                 begin
                    scroll_top:=1;
                    temp_head:=first;
                 end;
            #79: if scroll_size<lastdata.scl_filesize then readend else
                 if scroll_size>screensize then
                 begin
                    scroll_top:=scroll_size-screensize;
                    temp_head:=last;
                 end;
          end;
          grabline(c);
          screendump(c);
          if keyboarddata.altkey[c]='@TEXTSEARCH' then
          begin
             textsearch;
             movefromscreen(mem[baseofscreen:0],scroll_data^[scroll_top],screensize*80);
             cursor(false);
          end;
       end;
   until c=#27;
   lastdata.scl_filesize:=temp_size;
   savevideo(videoback,false);
   gotoxy(wx,wy);
   cursor(true);
end;

procedure scrollback;
begin
   if scroll_numon>0 then writescrollfile(scroll_numon);
   scroll_numon:=0;
   showscroll;
end;

procedure opencapfile(s: string);
begin
   if not capture then
   begin
      {$I-}
      assign(capfile,s);
      settextbuf(capfile,capbuf);
      if not exist(s) then rewrite(capfile) else
      if dparam.captureexist=uAPPEND then append(capfile) else rewrite(capfile);
      if ioresult=0 then
      begin
         capture:=true;
         logfile('  Opening '+caps(s)+' file for capture');
         showmsg('Opening file for capture',s);
         if connected then s:=dialdata.bbsname else s:='Unspecified Board';
         s:=^j^m+'[Capture system]:= '+s+^m^j^j;
         write(capfile,s);
      end else showmsg('Could not open file','Aborting capture');
      {$I+}
   end;
end;

procedure capturetoggle;
var s: string[80];
    x: byte;
    ch: char;
begin
   savevideo(videoback,true);
   wx:=wherex; wy:=wherey;
   if not capture then
   begin
      sc.x:=2;  sc.y:=2;
      sc.s:=12; sc.t:=4;
      sc.c:=hattr(white,cyan);
      sc.nc:=attr(lightgray,blue);
      makebox(attr(white,blue),1,1,47,6,1);
      fwritena('Â',1,14); fwritena('Á',6,14);
      vertchars(attr(white,blue),14,2,5,'³');
      fwrite(' COMMAND    ',2,2,sc.nc);
      fwrite(' If exist   ',3,2,sc.nc);
      fwrite(' Emul codes ',4,2,sc.nc);
      fwrite(' Filename   ',5,2,sc.nc);
      if connected then x:=dialnumber else x:=0;
      s:=dir_capture+'\Z_TEXT.'+chars('0',3-length(its(x)))+its(x);
      fwrite('ENTER=start, ESC=abort',2,16,attr(yellow,blue));
      fwrite(copy(s,1,30),5,16,attr(yellow,blue));
      x:=1;
      repeat
         if dparam.captureexist=uAPPEND then fwrite('Append   ',3,16,attr(yellow,blue)) else
            fwrite('Overwrite',3,16,attr(yellow,blue));
         if dparam.captureemul then fwrite('Accept    ',4,16,attr(yellow,blue)) else
            fwrite('Filter out',4,16,attr(yellow,blue));
         ch:=scrollchoice(#27+#13+'EFCN',x);
         if ch<>#27 then
         begin
            case ch of
               'C': x:=1; 'I': x:=2;
               'E': x:=3; 'F': x:=4;
            end;
            case x of
               1: opencapfile(s);
               2: if dparam.captureexist=uAPPEND then dparam.captureexist:=uOVERWRITE else
                     dparam.captureexist:=uAPPEND;
               3: dparam.captureemul:=not dparam.captureemul;
               4: begin
                     x:=0;
                     editflag(1,0,0,1,0,1,1);
                     if input(attr(yellow,blue),16,5,s,80,30,x)=#0 then;
                     x:=4;
                  end;
            end;
         end;
      until (ch=#27) or (x=1);
      cursor(true);
   end else
   begin
      capture:=false;
      close(capfile);
      logfile('  Closing capture file');
      showmsg('Capture toggle','Closing last opened file');
   end;
   savevideo(videoback,false);
   gotoxy(wx,wy);
   statusbar;
end;

procedure askname(var s: string);
var lo: byte;
begin
   lo:=0;
   editflag(1,1,0,1,1,1,1);
   makebox(attr(white,blue),1,1,80,3,1);
   fwritena('[ Disk Space Free = '+diskspace(0)+' ]',1,3);
   changeattr(76,4,3,8);
   fwrite('Drive:\Path\Name : ',2,3,attr(lightcyan,blue));
   if input(attr(lightgray,blue),22,2,s,50,50,lo)<>#13 then s:='|ESC|';
end;

procedure protocolwindow(uploading: boolean);
var pch: char;
    laston: integer;
    filename: string;

function pickprotocol: char;
var y : byte;
    protocolon: char;
    s: string[11];
begin
   s:='';
   cursor(false);
   page.flag:=0;
   timestat.flag:=0;
   sc.x:=5; sc.y:=9;
   sc.s:=30;
   sc.c:=hattr(white,blue);
   sc.nc:=attr(lightgray,black);
   makebox(attr(lightcyan,black),4,8,77,20,1);
   fwritena('Â',8,35); fwritena('Á',20,35);
   vertchars(attr(lightcyan,black),35,9,19,'³');
   sc.t:=10;
   s:='ABCDEFGHIJ';
   for y:=1 to 10 do
   begin
      fwrite(chr(y+64),sc.y+y-1,sc.x+1,attr(lightgreen,black));
      fwrite(') '+protodata[chr(y+64)].protoname,sc.y+y-1,sc.x+2,sc.nc);
   end;
   if uploading then
   begin
      sc.t:=11;
      for y:=1 to 10 do fwrite(protodata[chr(y+64)].upcmd,y+8,37,attr(white,black));
      fwrite('K',sc.y+sc.t-1,sc.x+1,attr(lightgreen,black));
      fwrite(') Ascii upload',sc.y+sc.t-1,sc.x+2,sc.nc);
      s:=s+'K';
   end else
   for y:=1 to 10 do
       fwrite(protodata[chr(y+64)].dncmd,y+8,37,attr(white,black));
   protocolon:=dialdata.protocol;
   if (pos(protocolon,s)=0) or (not connected) then protocolon:='A';
   y:=ord(protocolon)-64;
   protocolon:=scrollchoice(s+#13+#27,y);
   if protocolon=#27 then pickprotocol:=#27 else
      if protocolon=#13 then pickprotocol:=chr(y+64) else pickprotocol:=protocolon;
end;

procedure execprotocol;
var lastdir,cdir: string80;
begin
   if pch='K' then asciisend(dirname+filename) else
   with protodata[pch] do
   begin
      disablemousedrvr;
      getdir(0,lastdir);
      zbaud:=dparam.speed;
      if uploading then
      begin
         if (length(dirname)>3) and (dirname[length(dirname)]='\') then delete(dirname,length(dirname),1);
         {$I-}
         chdir(dirname);
         if ioresult<>0 then showmsg('Problem changing','directory');
         {$I+}
         if (wherefile='//XMODEM') or (wherefile='//LXMODEM') then xmupload(filename) else
         if (wherefile='//ZMODEM') or (wherefile='//LZMODEM') then batchzmodem(filename) else
         begin
            cursor(true);
            window(1,1,80,25);
            color(7,0); clrscr;
            _dtr(true);
            _deinstall;
            exec(commandlocation,' /c '+wherefile+' '+ct(upcmd,filename));
            _install(configdata.comport);
            _dtr(true);
         end;
         chdir(lastdir);
      end else
      begin
         if changedl then
         begin
            cdir:=configdata.dndir;
            if (length(cdir)>3) and (cdir[length(cdir)]='\') then delete(cdir,length(cdir),1);
            {$I-}
            chdir(cdir);
            if ioresult<>0 then showmsg('Problem changing','directory');
            {$I+}
         end;
         if wherefile='//XMODEM' then xmdnload(filename,false) else
         if wherefile='//LXMODEM' then xmdnload(filename,true) else
         if wherefile='//ZMODEM' then zmodem_receive('N',filename) else
         if wherefile='//LZMODEM' then zmodem_receive(configdata.leechmode,filename) else
         begin
            cursor(true);
            window(1,1,80,25);
            color(7,0); clrscr;
            _dtr(true);
            _deinstall;
            exec(commandlocation,' /c '+wherefile+' '+ct(dncmd,filename));
            _install(configdata.comport);
            _dtr(true);
         end;
         chdir(lastdir);
      end;
      saveback(true,'');
      with dparam do _set_param(speed,parity,dbit,sbit);
      if uploading then logfile('  Uled - '+copy(caps(filename),1,40)) else
         logfile('  Dled - '+copy(caps(filename),1,40));
      cursor(false);
      if configdata.usealarm then alarm('transfer completed');
      enablemousedrvr;
      mouse_installed:= initmouse = 65535;
   end;
end;

begin
   cursor(false);
   laston:=1;
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   pch:=pickprotocol;
   savevideo(videoback,false);
   if pch<>#27 then
   begin
      filename:=configdata.updir;
      if uploading then
      begin
         filename:=dirlist(filename,laston,true);
         savevideo(videoback,false);
      end else filename:='';
      if filename='|ESC|' then
      begin
         dirname:='';
         if uploading then filename:=configdata.updir else filename:=configdata.dndir;
         askname(filename);
         savevideo(videoback,false);
      end else
      if (protodata[pch].askdl) and (not uploading) then
      begin
         dirname:='';
         filename:=configdata.dndir;
         askname(filename);
         savevideo(videoback,false);
      end;
      if filename<>'|ESC|' then
      begin
         execprotocol;
         savevideo(videoback,false);
      end;
   end;
   cursor(true);
   gotoxy(wx,wy);
   statusbar;
end;

function match_mbuf(submbuf: string): boolean;
var foundit: boolean;
    size,n1,n2,n3,n4,i: integer;
begin
   size:=length(submbuf);
   if (size<=mbufptr) or (mbuffull and (size<=mbufsize)) then
   begin
      if mbuffull then
      begin
         n2:=mbufptr+1;
         i:=mbufptr+mbufsize-size+1;
      end else
      begin
         n2:=1;
         i:=mbufptr-size+1;
      end;
      repeat
         if i>mbufsize then n4:=i-mbufsize else n4:=i;
         foundit:= submbuf[1] = mbuf[n4];
         if foundit then
         begin
            n1:=1;
            n3:=i;
            while (foundit) and (n1<size) do
            begin
               inc(n1);
               inc(n3);
               if n3>mbufsize then n4:=n3-mbufsize else n4:=n3;
               foundit:= submbuf[n1] = mbuf[n4];
            end;
         end;
         dec(i);
      until (foundit) or (i<n2);
      match_mbuf:=foundit;
   end else match_mbuf:=false;
end;

Function readscriptfile(name: string): byte;
var scriptfile: text;
    ch: char;
    s1,line: string;
    x,initial,tempi,i,
    final: word;
begin
   if name>'' then name:=dir_script+'\'+name+'.SCR';
   if exist(name) then
   begin
      script:=true;
      autolog:=false;
      assign(scriptfile,name);
      reset(scriptfile);
      x:=0; maxglobal:=0;
      nextline:=1; maxconst:=0;
      repeat
         readln(scriptfile,line);
         s1:=caps(line);
         ch:=#0;
         if pos('WAIT(',s1)>0 then ch:='W' else if pos('SEND(',s1)>0 then ch:='S' else
         if pos('QUIT(',s1)>0 then ch:='Q' else if pos('EXEC(',s1)>0 then ch:='E' else
         if pos('HANGUP(',s1)>0 then ch:='H' else if pos('CAPTURE(',s1)>0 then ch:='C' else
         if pos('LABEL(',s1)>0 then ch:='L' else if pos('GOTO(',s1)>0 then ch:='G' else
         if pos('IFFIND(',s1)>0 then ch:='I' else if pos('PRINT(',s1)>0 then ch:='P';
         if ch<>#0 then
         begin
            inc(x);
            initial:=Pos('("',line)+2;
            final:=pos('");',line);
            scriptline[x].cmd:=ch;
            scriptline[x].str:=copy(line,initial,final-initial);
            scriptline[x].ch:=scriptline[x].str[final-initial];
         end;
         if (pos('GLOBAL=',s1)>0) and (maxglobal<5) then
         begin
            inc(maxglobal);
            initial:=pos('="',line)+2;
            final:=pos('",',line);
            global[maxglobal].str:=copy(line,initial,final-initial);
            initial:=pos(',"',line)+2;
            final:=pos('";',line);
            global[maxglobal].val:=copy(line,initial,final-initial);
            s1:=global[maxglobal].str;
            global[maxglobal].ch:=s1[length(s1)];
         end;
         if (pos('CONST=',s1)>0) and (maxconst<5) then
         begin
            inc(maxconst);
            initial:=pos('=[',s1)+2;
            final:=pos('],',s1);
            consts[maxconst].str:=copy(s1,initial,final-initial);
            initial:=pos(',[',s1)+2;
            final:=pos('];',s1);
            consts[maxconst].val:=copy(s1,initial,final-initial);
         end;
      until (eof(scriptfile)) or (x=50);
      close(scriptfile);
      if x=0 then script:=false else
      begin
         for tempi:=1 to x do
         begin
            if scriptline[tempi].cmd='G' then
            begin
               for i:=1 to x do
               begin
                  if scriptline[i].cmd='L' then
                  begin
                     if scriptline[i].str=scriptline[tempi].str then
                        scriptline[tempi].ch:=chr(i);
                  end;
               end;
            end;
         end;
         tempi:=1;
         repeat
            if scriptline[tempi].cmd='L' then
            begin
               dec(x);
               for i:=tempi to x do scriptline[i]:=scriptline[i+1];
            end;
            inc(tempi);
         until tempi>=x;
         if x=0 then script:=false;
      end;
      readscriptfile:=x;
   end else
   begin
      if name>'' then showmsg('Could not locate script file','Disabling script');
      maxglobal:=0;
      nextline:=0;
      readscriptfile:=0;
      script:=false;
   end;
end;

procedure loadscript;
var s: string[50];
    lo: byte;
    c: char;
begin
   if not script then
   begin
      lo:=0;
      s:='';
      editflag(1,0,0,1,0,1,0);
      wx:=wherex; wy:=wherey;
      savevideo(videoback,true);
      makebox(attr(cyan,black),14,11,67,13,1);
      fwritena('´             Ã',11,15);
      fwrite('Load script',11,17,attr(lightcyan,black));
      fwrite(dir_script+'\        .SCR'+blanks(31),12,15,attr(white,black));
      s:=pickfile(14,14,dir_script+'\*.scr','');
      if s='' then c:=input(attr(white,black),22,12,s,8,8,lo) else c:=#13;
      if c=#13 then endscript:=readscriptfile(s);
      savevideo(videoback,false);
      gotoxy(wx,wy);
      statusbar;
   end else showmsg('Script is Active','Must cancel it first');
end;

procedure doscript;
var i: byte;
label redoit;
begin
redoit:
   case scriptline[nextline].cmd of
       'C': begin
               if not capture then
               begin
                  assign(capfile,scriptline[nextline].str);
                  for i:=1 to maxconst do
                  begin
                     if pos('$EXIST$',consts[i].str)>0 then
                     begin
                        if pos('APPEND',consts[i].val)>0 then dparam.captureexist:=uAPPEND else
                        if pos('OVERWRITE',consts[i].val)>0 then dparam.captureexist:=uOVERWRITE;
                     end;
                     if pos('$KEEPEMUL$',consts[i].str)>0 then
                     begin
                        if pos('TRUE',consts[i].val)>0 then dparam.captureemul:=true else
                        if pos('FALSE',consts[i].val)>0 then dparam.captureemul:=false;
                     end;
                  end;
                  opencapfile(scriptline[nextline].str);
               end else capturetoggle;
               inc(nextline);
               statusbar;
            end;
       'E': begin
               exec(commandlocation,' /c '+scriptline[nextline].str);
               inc(nextline);
            end;
       'H': begin
               If pos('YES',caps(scriptline[nextline].str))>0 then hangup;
               inc(nextline);
            end;
       'I': while (scriptline[nextline].cmd='I') and (nextline<=endscript) do
            begin
               if scriptline[nextline].ch=modemch then
               begin
                  if match_mbuf(scriptline[nextline].str) then inc(nextline) else inc(nextline,2);
               end else inc(nextline,2);
            end;
       'P': begin
               write(scriptline[nextline].str);
               inc(nextline);
            end;
       'Q': begin
               if Pos('YES',caps(scriptline[nextline].str))>0 then quitzygote:=true;
               inc(nextline);
            end;
       'S': begin
               send(scriptline[nextline].str);
               inc(nextline);
            end;
       'W': if scriptline[nextline].ch=modemch then
               if match_mbuf(scriptline[nextline].str) then inc(nextline);
   end;
   if maxglobal>0 then
   begin
      for i:=1 to maxglobal do if global[i].ch=modemch then
      begin
         if match_mbuf(global[i].str) then
         begin
            mbufptr:=0;
            mbuffull:=false;
            send(global[i].val);
         end;
      end;
   end;
   if nextline>endscript then
   begin
      script:=false;
      statusbar;
   end else
   if scriptline[nextline].cmd='G' then
   begin
      nextline:=ord(scriptline[nextline].ch);
      goto redoit;
   end;
end;

procedure savelastfile;
begin
   {$I-}
   assign(filehandle,'ZYGOTE.LST');
   rewrite(filehandle,sizeof(lastdata));
   blockwrite(filehandle,lastdata,1);
   if ioresult=0 then close(filehandle) else
      showmsg('Problem writing file','ZYGOTE.LST');
   {$I+}
end;

procedure loaddialmenu;
begin
   dialmenu;
   if newcarrier then
   begin
      inittab;
      oldcd:=_CD;
      blink:=false;
      g0:=us;
      g1:=us;
      vtcharset:=g0_;
      with lastdata do
      begin
         param:=dparam;
         lastbbs:=dialnumber;
         gettime(hour,min,sec,hund);
         lasttime:=3600*hour+60*min+sec;
      end;
      savelastfile;
      script:=false;
      region.active:=false;
      region.top:=1;
      region.bottom:=activescreensize;
      lastbg:=0;
      lastfg:=7;
      endscript:=readscriptfile(dialdata.scriptname);
      statusbar;
      logfile('['+dialdata.bbsname+blanks(23-length(dialdata.bbsname))+'] Carrier detected');
      open_tbl(dialdata.file_tbl,true);
      open_kbd(dialdata.file_kbd,true);
      dialstatus;
      if dialdata.autocapture then opencapfile(dir_capture+'\'+dialdata.file_cap);
      if configdata.usealarm then alarm('connection established');
      if dialdata.checknotepad then notepad(dialdata.file_pad);
      statusbar;
      color(7,0);
   end;
end;

function sendchptr(pno: word; ch: char): boolean;
var p_error: word;

   function DoInt17(Ch : Char; LPTNo : Word) : Byte;
   Inline($5A/$58/$B4/$00/$CD/$17/$86/$E0);

   function LPTStat(LPTNo : Word) : Byte;
   Inline($5A/$B4/$02/$CD/$17/$86/$C4);

begin
   p_error:=lptstat(pno);
   if p_error and 48 = 16 then
      sendchptr:=doint17(ch,pno) and 48 = 16 else sendchptr:=false;
end;

procedure toggleprinter;
   function sendptr(s: string): boolean;
   var x: byte;
   begin
      sendptr:=true;
      for x:=1 to length(s) do
         if not sendchptr(configdata.printerport,s[x]) then
         begin
            sendptr:=false;
            exit;
         end;
   end;
begin
   if useprinter then
   begin
      useprinter:=false;
      if not sendptr(#10+#13) then
         showmsg('Printer not ready','Port #'+its(configdata.printerport+1));
      showmsg('Printer is now Off','Port #'+its(configdata.printerport+1));
   end else
   begin
      if sendptr(#27+'@'+#0) then
      begin
         if not sendptr(#27+'x'+#0) then
         begin
            showmsg('Printer not ready','Port #'+its(configdata.printerport+1));
            useprinter:=false;
         end else useprinter:=true;
      end else
      begin
         showmsg('Printer not ready','Port #'+its(configdata.printerport+1));
         useprinter:=false;
      end;
      if useprinter then showmsg('Printer is now On','Port #'+its(configdata.printerport+1));
   end;
end;

procedure tollreporter;
const tollresult: array[0..2] of string[9] = ('Unknown','Non-toll call','Toll call');
var phone,tempstr: stringdesc;
    city: string[24];
    lo,i,tollvalue: byte;
begin
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   phone:='';
   lo:=0;
   editflag(1,1,0,1,0,0,1);
   makebox(0,1,23,80,25,1);
   fwrite(' phone number : '+blanks(62),24,2,attr(lightcyan,black));
   if input(attr(cyan,black),18,24,phone,40,40,lo)=#13 then
   begin
      tempstr:='';
      for i:=1 to length(phone) do
          if phone[i] in ['0'..'9'] then tempstr:=tempstr+phone[i];
      if (length(tempstr)>7) and (tempstr[1]<>'1') then tempstr:='1'+tempstr;
      phone:=dialdata.bbsphone;
      dialdata.bbsphone:=tempstr;
      findloc(city,tollvalue);
      dialdata.bbsphone:=phone;
      makebox(0,1,19,43,22,1);
      fwrite('city name    : ',20,3,attr(lightred,black));
      fwrite('toll report  : ',21,3,attr(yellow,black));
      fwrite(city,20,18,attr(white,black));
      fwrite(tollresult[tollvalue],21,18,attr(white,black));
      waitkey;
   end;
   savevideo(videoback,false);
   gotoxy(wx,wy);
end;

procedure checkaltkey(x: char);
var s: string[50];
    code: integer;
    ch: char;
begin
   hidemouse;
   s:=keyboarddata.altkey[x];
   if s='' then ch:=#0 else ch:=s[1];
   with configdata do
   case ch of
    '!': with keyboarddata do
         begin
            altkey[#4]:='';
            s:=copy(s,2,length(s));
            if pos('%F',s)>0 then
            begin
               savevideo(videoback,true);
               wx:=wherex; wy:=wherey;
               askname(altkey[#4]);
               gotoxy(wx,wy);
               if altkey[#4]='|ESC|' then altkey[#4]:='';
               savevideo(videoback,false);
            end;
            s:=ct(s,altkey[#4]);
            exechotkey(s);
         end;
    '#': begin
            s:=copy(s,2,length(s)-1);
            val(s,haltvalue,code);
            quitzygote:=true;
         end;
    '@': begin
           nosound;
           if pos('_',s)>0 then
           begin
              if scroll_numon>0 then
              begin
                 writescrollfile(scroll_numon);
                 scroll_numon:=0;
              end;
              dispose(scroll_data);
              if s='@DIAL_MENU' then loaddialmenu else
              if s='@DIR_LISTER' then loadfiledir else
              if s='@UPLOAD_FILE' then protocolwindow(true) else
              if s='@DOWNLOAD_FILE' then protocolwindow(false) else
              if s='@BINARY_READER' then readbinfiles else
              if s='@MACRO_MENU' then macros(0) else
              if s='@SETUP_ZYGOTE' then
              begin
                 close(scroll_file);
                 runconfigzyg;
                 checkscrollfile;
              end else
              if s='@EMAIL_BOOK' then
              begin
                 {unregistered
                 regmsg;}
                 emailbook;
              end else
              if s='@BBS_STRIPPER' then bbsstripper else
              if s='@HOST_MODE' then
              begin
                 {unregistered
                 regmsg;}
                 if registered then loadhost;
              end;
              new(scroll_data);
           end else
           begin
              if s='@CLRSCREEN' then clrscr else
              if s='@SCREENDUMP' then screendump(x) else
              if s='@HANGUP' then hangup else
              if s='@DOSSHELL' then
              begin
                 close(scroll_file);
                 dosshell;
                 createdirs;
                 checkscrollfile;
              end else
              if s='@CANCELAUTO' then script_autosysoff else
              if s='@CHANGEPARAMS' then changeparams else
              if s='@SCROLLBACK' then scrollback else
              if s='@GRABTEXT' then grabline(x) else
              if s='@STAMPTEXT' then sendhistory else
              if s='@TEXTSEARCH' then textsearch else
              if s='@ASCIICHART' then begin if asciichart(x,ch) then _put(ord(ch)); end else
              if s='@HISTORY' then history else
              if s='@CAPTURETOGGLE' then capturetoggle else
              if s='@BACKWARDSTEXT' then backwards else
              if s='@NOTEPAD' then
              begin
                 {unregistered
                 regmsg;}
                 notepad(dialdata.file_pad);
              end else
              if s='@USERINFO' then
              begin
                 {unregistered
                 regmsg;}
                 userinfo;
              end else
              if s='@TOLLREPORTER' then
              begin
                 {unregistered
                 regmsg;}
                 tollreporter;
              end else
              if s='@BACKGROUND' then saveback(false,'') else
              if s='@BOARDHELP' then boardhelp else
              if s='@PRINTER' then toggleprinter else
              if s='@CALCULATOR' then calculator else
              if s='@MINIDOS' then
              begin
                 {unregistered
                 regmsg;}
                 if registered then
                 begin
                    close(scroll_file);
                    minidos;
                    createdirs;
                    checkscrollfile;
                 end;
              end else
              if s='@ENCRYPTMSG' then
              begin
                 {unregistered
                 regmsg;}
                 if registered then writecrypt;
              end else
              if s='@KEYLOCK' then keylock else
              if s='@ANTIOFF' then toggleantioff else
              if s='@MODEMCOMMAND' then sendmodemstring else
              if s='@CHANGEDNDIR' then
              begin
                 {unregistered
                 regmsg;}
                 changedndir;
              end else
              if s='@CHATMODE' then chatmode else
              if s='@SENDBREAK' then _sendbreak else
              if s='@WORLDTIME' then worldtime else
              if s='@EXITWINDOW' then exitwindow else
              if s='@LOADSCRIPT' then loadscript else
              if s='@RINGMONITOR' then ringmonitor else
              if s='@BIGCLOCK' then bigclock else
              if s='@DOORWAY' then
              begin
                 doorwaymode:=true;
                 showmsg('Activating DOORWAY','Same key to deactivate');
              end;
           end;
         end;
    '$': send(copy(s,2,length(s)));
    else helpscreen;
   end;
   showmouse;
end;

procedure Init1;
var s: string[80];
begin
   randomize;
   sctotal:=0;
   haltvalue:=0;
   argnum:=0;
   g0:=us;
   g1:=us;
   vtcharset:=g0_;
   musicmode:=false;
   emulmode:=false;
   lemulch:=#0;
   tsbuffer:='';
   checkbreak:=false;
   newcarrier:=false;
   newdirfile:=true;
   lastsize:=0;
   blink:=false;
   oldcd:=_CD;
   scroll_numon:=0;
   mbufptr:=0;
   mbuffull:=false;
   region.active:=false;
   region.top:=1;
   region.bottom:=24;
   doorwaymode:=false;
   dcebps:=0;
   assign(scroll_file,name_scl);
   if exist(name_scl) then reset(scroll_file) else rewrite(scroll_file);
   s:=paramstr(0);
   delete(s,pos('ZYGOTE.EXE',caps(s)),10);
   if length(s)>3 then delete(s,length(s),1);
   chdir(s);
end;

procedure init2;
var x: byte;
begin
   keyboarddata.altkey[#5]:='';
   restorebbs;
   inittab;
   x:=checkarg('/L');
   if x>0 then endscript:=readscriptfile(paramstr(x+1));
   if x=0 then
   begin
      x:=checkarg('/F');
      if x>0 then
      begin
         keyboarddata.altkey[#4]:=caps(paramstr(x+1));
         checkaltkey(#4);
         if (newcarrier) and (dialdata.execute>'') then
         begin
            keyboarddata.altkey[#4]:=dialdata.execute;
            checkaltkey(#4);
            newcarrier:=false;
         end;
      end;
   end;
   createdirs;
   checkscrollfile;
   logfile('ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ Zygote v'+cmsg(zversion)+' Loaded ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿');
end;

procedure changedCD;
begin
   if not _CD then
   begin
      if connected then logfile('['+dialdata.bbsname+blanks(23-length(dialdata.bbsname))+'] Carrier dropped');
      connected:=false;
      script:=false;
      autolog:=false;
   end;
   statusbar;
   oldCD:=_CD;
end;

procedure overlayunits;
begin
   Ovrinit('ZYGOTE.OVR');
   If OvrResult<>0 then
   begin
      clrscr;
      writeln('Overlay Error: ',ovrresult);
      halt(0);
   end;
end;

procedure doecho;
begin
   case keybdch of
      #7 : beepproc;
      #8 : if dparam.destructbs then write(^h,' ',^h) else write(^h);
      #9 : tabproc;
      #12: clrscr;
      #13: writeln;
      else write(keybdch);
   end;
end;

Procedure Autoprotocol(which: char);
var lastdir,cdir: string80;
begin
   disablemousedrvr;
   clreol;
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   getdir(0,lastdir);
   logfile('  Start Auto-'+protodata[which].protoname);
   if protodata[which].changedl then
   begin
      cdir:=configdata.dndir;
      if (length(cdir)>3) and (cdir[length(cdir)]='\') then delete(cdir,length(cdir),1);
      {$I-}
      chdir(cdir);
      if ioresult<>0 then showmsg('Problem changing','directory');
      {$I+}
   end;
   if protodata[which].wherefile='//ZMODEM' then zmodem_receive('N','') else
   if protodata[which].wherefile='//LZMODEM' then zmodem_receive(configdata.leechmode,'') else
   begin
      window(1,1,80,25);
      color(7,0);
      clrscr;
      fwrite(chars('Ü',80),1,1,attr(white,black));
      fwrite(blanks(80),2,1,attr(black,lightgray));
      fwrite(blanks(80),3,1,attr(black,lightgray));
      fwrite(chars('ß',80),4,1,attr(darkgray,black));
      fwritena('Protocol   :',2,2);  fwritena('Free :',2,56);
      fwritena('Parameters :',3,2);  fwritena('Time :',3,56);
      fwrite(protodata[which].protoname,2,15,attr(blue,lightgray));
      fwrite(protodata[which].dncmd,3,15,attr(blue,lightgray));
      fwrite(diskspace(0),2,63,attr(blue,lightgray));
      fwrite(time(1),3,63,attr(blue,lightgray));
      gotoxy(1,5);
      _dtr(true);
      _deinstall;
      exec(commandlocation,' /c '+protodata[which].wherefile+' '+ct(protodata[which].dncmd,''));
      _install(configdata.comport);
      _dtr(true);
      with dparam do _set_param(speed,parity,dbit,sbit);
   end;
   chdir(lastdir);
   saveback(true,'');
   logfile('  End Auto-'+protodata[which].protoname);
   gotoxy(wx,wy);
   savevideo(videoback,false);
   statusbar;
   if configdata.usealarm then alarm('transfer completed');
   enablemousedrvr;
   mouse_installed:= initmouse = 65535;
end;

begin
   init1;
   overlayunits;
   openall;
   loadzyg;
   new(scroll_data);
   init2;
   showmouse;
   repeat
      if _rx_ready then
      begin
         hidemouse;
         while _rx_ready do
         begin
            if dparam.striphb then modemch:=tabledata.rx[_get and 127]
              else modemch:=tabledata.rx[_get];
            lastemul:=emulmode;
            case dparam.graphic of
                  uANSI: ansi(modemch);
                 uVT100: vt100(modemch);
                uAVATAR: avatar(modemch);
                    else write(modemch);
            end;
            if capture then
            begin
               {$I-}
               if dparam.captureemul then write(capfile,modemch) else
               if (not emulmode) and (not lastemul) then write(capfile,modemch);
               if ioresult<>0 then
               begin
                  showmsg('Disk error','Closing capture file');
                  capture:=false;
                  close(capfile);
               end;
               {$I+}
            end;
            if (not emulmode) and (not lastemul) then
            begin
               if useprinter then
               if not sendchptr(configdata.printerport,modemch) then
               begin
                  showmsg('Printer not ready','Port #'+its(configdata.printerport+1));
                  useprinter:=false;
               end;
               inc(mbufptr);
               if mbufptr>mbufsize then
               begin
                  mbufptr:=1;
                  mbuffull:=true;
               end;
               mbuf[mbufptr]:=modemch;
               case modemch of
                 '­': begin
                         if match_mbuf('#îï€â˜ž­') then
                         begin
                            modemch:=#0;
                            mbufptr:=0;
                            mbuffull:=false;
                            if configdata.cryptdecode then readcrypt;
                         end else
                         if match_mbuf('#SYSTEM­') then
                         begin
                            modemch:=#0;
                            mbufptr:=0;
                            mbuffull:=false;
                            systemactive;
                            if keyboarddata.altkey[#4]>'' then checkaltkey(#4);
                         end else
                         if match_mbuf('#ZYGOTE­') then
                         begin
                            modemch:=#0;
                            _put(2);
                         end;
                      end;
                 #10: codedlf:=wherey-1;
                 #13: begin
                         if dparam.autolf then write(#10);
                         if configdata.allowfax then
                            if match_mbuf(configdata.results[5]) then exechotkey(configdata.faxprogram);
                         for keybdch:='A' to 'J' do if protodata[keybdch].availauto then
                            if match_mbuf(protodata[keybdch].sequence) then autoprotocol(keybdch);
                         mbufptr:=0;
                         mbuffull:=false;
                      end;
               end;
               if script then doscript else
               if autolog then
               begin
                  if modemch=sysdata[dialdata.autosys].lastch then
                  if match_mbuf(sysdata[dialdata.autosys].waitfor) then
                  begin
                     loopcnt:=sysdata[dialdata.autosys].dlay*100;
                     if sysdata[dialdata.autosys].sendhandle then
                     begin
                        send('%Ua^M');
                        delay(loopcnt);
                     end;
                     if sysdata[dialdata.autosys].sendpw then
                     begin
                        send('%Ub^M');
                        delay(loopcnt);
                     end;
                     if sysdata[dialdata.autosys].sendlfd then
                     begin
                        send('%Uc^M');
                        delay(loopcnt);
                     end;
                     mbufptr:=0;
                     mbuffull:=false;
                     autolog:=false;
                     statusbar;
                  end;
               end;
            end;
            if codedlf>0 then
            begin
               inc(scroll_numon);
               movefromscreen(mem[baseofscreen:160*(codedlf-1)],scroll_data^[scroll_numon],80);
               if scroll_numon=scroll_savewhen then
               begin
                  _rts(false);
                  writescrollfile(scroll_savewhen);
                  _rts(true);
                  scroll_numon:=0;
               end;
               codedlf:=0;
            end;
         end;
         showmouse;
      end;
      if keypressed then
      begin
         if keylocked then keylock else
         begin
            keybdch:=readkb;
            if keybdch=#0 then
            begin
               keybdch:=readkb;
               if doorwaymode then
               begin
                  if keyboarddata.altkey[keybdch]='@DOORWAY' then doorwaymode:=false;
                  if doorwaymode then
                  begin
                     _put(0);
                     _put(ord(keybdch));
                  end else showmsg('Deactivating DOORWAY','Local functions active.');
               end else
               begin
                  directvideo:=true;
                  checkaltkey(keybdch);
                  if keyboarddata.altkey[#5]>'' then checkaltkey(#5);
                  keyboarddata.altkey[#5]:='';
                  if (newcarrier) and (dialdata.execute>'') then
                  begin
                     keyboarddata.altkey[#4]:=dialdata.execute;
                     checkaltkey(#4);
                     newcarrier:=false;
                  end;
               end;
            end else
            begin
               _put(tabledata.tx[keybdch]);
               if keybdch=#13 then if dparam.autolf then _put(10);
               if dparam.localecho then doecho;
            end;
         end;
      end;
      bgcheck;
      if script then doscript;
      if oldcd<>_cd then changedcd;
      mouseposition(rat);
      if rat.stat=leftpress then
      begin
         mousepress(leftbutton,rat);
         case rat.my of
            1: if rat.pcount=1 then
               begin
                  hidemouse;
                  helpscreen;
                  if keyboarddata.altkey[#5]>'' then checkaltkey(#5);
                  keyboarddata.altkey[#5]:='';
                  showmouse;
               end;
           25: if rat.pcount=1 then _put(13);
          else if rat.pcount=1 then
               begin
                  keyboarddata.altkey[#4]:='@GRABTEXT';
                  grabline(#4);
               end;
         end;
      end else
      if rat.stat=rightpress then
      begin
         mousepress(rightbutton,rat);
         if rat.pcount=1 then
         begin
            if rat.my=25 then _put(27) else sendhistory;
         end;
      end;
      if configdata.showstatbar then
      begin
         if abs(clocktick-lasttick)>tickdiff then
         begin
            gettime(hour,min,sec,hund);
            lasttick:=clocktick;
            if hour>11 then
            begin
               amorpm:='PM';
               if hour>12 then loopcnt:=hour-12 else loopcnt:=12;
            end else
            if hour=0 then
            begin
               amorpm:='AM';
               loopcnt:=12;
            end else
            begin
               amorpm:='AM';
               loopcnt:=hour;
            end;
            fwritena(chars('0',2-length(its(loopcnt)))+its(loopcnt)+':'+chars('0',2-length(its(min)))+its(min)+':'+
                     chars('0',2-length(its(sec)))+its(sec)+' '+amorpm,25,68);
            if connected then
            begin
               totalsec:=hour*3600+min*60+sec;
               if lastdata.lasttime>totalsec then lastdata.lasttime:=totalsec;
               totalsec:=totalsec-lastdata.lasttime;
               hour:=longint(totalsec div 3600);
               min:=longint(totalsec mod 3600 div 60);
               sec:=longint(totalsec mod 60);
               fwrite(chars('0',2-length(its(hour)))+its(hour)+':'+chars('0',2-length(its(min)))+its(min)+':'+
                      chars('0',2-length(its(sec)))+its(sec),25,59,attr(white,blue));
            end;
            if antioff then
            begin
               inc(somecounter);
               if somecounter>configdata.anticounter then
               begin
                  somecounter:=0;
                  _put(configdata.antichar);
               end;
            end;
         end;
      end;
   until quitzygote;
   hidemouse;
   savelastfile;
   if capture then capturetoggle;
   closeall;
   close(scroll_file);
   dispose(scroll_data);
   closingscr;
   setblink;
   {unregistered
   regmsg;}
   halt(haltvalue);
end.
