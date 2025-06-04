unit z_init;

interface
{$F+,O+}

procedure openall;
procedure closeall;
procedure open_cfg(open: boolean);
procedure open_kbd(givename: string; open: boolean);
procedure open_tbl(givename: string; open: boolean);
procedure restorebbs;
procedure changeparams;

implementation

uses crt,dos,z_util,z_comio;

const cfname='ZYGOTE.CFG';  (* configuration     *)
      mfname='ZYGOTE.MAC';  (* macros            *)
      sfname='ZYGOTE.ALS';  (* autologon sys     *)
      pfname='ZYGOTE.PRO';  (* protocol          *)
      afname='ZYGOTE.ACC';  (* mult accounts     *)
      lfname='ZYGOTE.LST';  (* last info file    *)

procedure initaltkey;
var c: char;
begin
   with keyboarddata do
   begin
      fillchar(altkey,sizeof(altkey),0);
      altkey[#3  ]:='@MINIDOS';
      altkey[#15 ]:='$^h^h^h^h^h';
      altkey[#16 ]:='@BINARY_READER';
      altkey[#17 ]:='@CLRSCREEN';
      altkey[#18 ]:='@EMAIL_BOOK';
      altkey[#19 ]:='@TOLLREPORTER';
      altkey[#20 ]:='@TEXTSEARCH';
      altkey[#21 ]:='@BBS_STRIPPER';
      altkey[#22 ]:='@USERINFO';
      altkey[#24 ]:='@SETUP_ZYGOTE';
      altkey[#25 ]:='@CHANGEPARAMS';
      altkey[#30 ]:='@ASCIICHART';
      altkey[#31 ]:='@STAMPTEXT';
      altkey[#32 ]:='@DIAL_MENU';
      altkey[#33 ]:='@DIR_LISTER';
      altkey[#34 ]:='@GRABTEXT';
      altkey[#35 ]:='@HANGUP';
      altkey[#36 ]:='@DOSSHELL';
      altkey[#37 ]:='@KEYLOCK';
      altkey[#38 ]:='@LOADSCRIPT';
      altkey[#44 ]:='@SENDBREAK';
      altkey[#45 ]:='@EXITWINDOW';
      altkey[#46 ]:='@CAPTURETOGGLE';
      altkey[#48 ]:='@CHANGEDNDIR';
      altkey[#49 ]:='@NOTEPAD';
      altkey[#50 ]:='@MACRO_MENU';
      altkey[#59 ]:='$%Ua^M';
      altkey[#60 ]:='$%Ub^M';
      altkey[#61 ]:='$%Uc^M';
      altkey[#62 ]:='$%Bd^M';
      altkey[#63 ]:='$%Ma';
      altkey[#64 ]:='$%Mb';
      altkey[#65 ]:='$%Mc';
      altkey[#66 ]:='$%Md';
      altkey[#67 ]:='$%Me';
      altkey[#68 ]:='$%Mf';
      altkey[#72 ]:='$^[[A';
      altkey[#75 ]:='$^[[D';
      altkey[#77 ]:='$^[[C';
      altkey[#73 ]:='@UPLOAD_FILE';
      altkey[#80 ]:='$^[[B';
      altkey[#81 ]:='@DOWNLOAD_FILE';
      altkey[#82 ]:='$^v';
      altkey[#83 ]:='$'+chr(127);
      altkey[#84 ]:='$%Uf^m';
      altkey[#85 ]:='$%Ui^m';
      altkey[#86 ]:='$%Uj^m';
      altkey[#87 ]:='$%Ug^m';
      altkey[#88 ]:='$%Uh^m';
      altkey[#89 ]:='$%Ue^m';
      altkey[#90 ]:='$%Ud^m';
      altkey[#91 ]:='$%Ea^m';
      altkey[#92 ]:='$%Eb^m';
      altkey[#93 ]:='$%Ee^m';
      altkey[#94 ]:='@ANTIOFF';
      altkey[#95 ]:='$The time is %T, and the date is %D^m';
      altkey[#96 ]:='@MODEMCOMMAND';
      altkey[#97 ]:='@RINGMONITOR';
      altkey[#98 ]:='@BIGCLOCK';
      altkey[#104]:='@SCREENDUMP';
      altkey[#105]:='@CANCELAUTO';
      altkey[#106]:='@CHATMODE';
      altkey[#107]:='@WORLDTIME';
      altkey[#108]:='@BACKGROUND';
      altkey[#109]:='@HISTORY';
      altkey[#110]:='@CALCULATOR';
      altkey[#111]:='@DOORWAY';
      altkey[#112]:='@BOARDHELP';
      altkey[#113]:='@PRINTER';
      altkey[#115]:='@BACKWARDSTEXT';
      altkey[#116]:='@SCROLLBACK';
      altkey[#130]:='@ENCRYPTMSG';
      altkey[#131]:='@HOST_MODE';
   end;
end;

function findport: byte;
const base: array[1..4] of word =($03F8,$02F8,$03E8,$02E8);
var portnum,i: byte;

begin
   portnum:=1;
   for i:=2 to 4 do
   begin
      port[base[i]+1]:=0;
      if (port[base[i]+1]=0) and (port[base[i]+6]=48) then portnum:=i;
   end;
   findport:=portnum;
end;

procedure open_cfg(open: boolean);
var i: integer;
begin
   if open then
   begin
      if exist(cfname) then
      begin
         {$I-}
         assign(filehandle,cfname);
         reset(filehandle,sizeof(configdata));
         if ioresult=0 then
         begin
            i:=filesize(filehandle);
            if i=0 then close(filehandle);
         end else i:=0;
      end else i:=0;
      if i=1 then
      begin
         blockread(filehandle,configdata,1,i);
         close(filehandle);
      end else
      begin
         loadconfig:=true;
         with configdata do
         begin
            initaltkey;
            with param do
            begin
               speed:=2400; parity:='N'; dbit:=8; sbit:=1;
            end;
            comport:=findport; param.graphic:=uANSI; leechmode:='B'; usealtnum:=true; unmarkwhen:=5;
            tabsize:=8; xmitsize:=1024; recvsize:=4096; pstdiff:=0; dlsaving:=false; msgdelay:=8000;
            XonXoff:=false; CtsRts:=true; username:='username'; syscode:='PASSWORD';
            areacode:='000'; LFD:='0000'; getdir(0,updir); if updir[length(updir)]<>'\' then updir:=updir+'\'; antichar:=27;
            dndir:=updir; usealarm:=true; confirmhe:=true; useintense:=false;
            hupdir:=updir; hdndir:=updir; hlevel:='//LEVEL'; Beep:=true; printerport:=0;
            hshutdown:='//SHUTDOWN'; haccess:='//ACCESS'; hopen:=true; blinkfilter:=false; anticounter:=30;
            regname:=''; regpwd:=''; regnumber:=0; registered:=false; callwaiting:='*70,,'; cwtoggle:=false;
            dtrdelay:=8000; rescanafteredit:=false; dofifo:=true; attention:='+++';
            altdndir[1]:='C:\PICTURES\';
            altdndir[2]:='C:\PRIVATE\';
            altdndir[3]:=dndir;
            with param do
            begin
               autolf:=false;         destructBS:=false;
               striphb:=false;        Localecho:=false;
               captureexist:=uAPPEND; captureemul:=true;
            end;
            keeplog:=false; allowmusic:=true; faxprogram:=''; allowfax:=false; showpwd:=false;
            Generatepw:=true; Vretrace:=false; Init_online:=false; showstatbar:=true;
            dos_deinstallport:=false; useDTR:=true; Cryptdecode:=true; expandtab:=false;
            initstr[1]:='ATE1S0=0M1L1V1X4Q0&C1&S1&D2S11=55^M'; initstr[2]:='ATZ^M'; useinit:=1;
            Dialstr[1]:='ATDT'; dialstr[2]:='ATPT'; dialsuffix:='^M'; HangupStr:='ATH0^M'; Diallimit:=50;
            combase[1]:='03F8'; combase[2]:='02F8'; combase[3]:='03E8'; combase[4]:='02E8'; scrollbacksize:=1000;
            comint[1]:=12; comint[2]:=11; comint[3]:=12; comint[4]:=11; usedial:=1; answerstr:='ATA^M'; redialpause:=2500;
            comirq[1]:=4; comirq[2]:=3; comirq[3]:=4; comirq[4]:=3; defaultkeypw:='ZYGOTE'; hostring:=2;
            results[1]:='BUSY'; results[2]:='NO CARRIER'; results[3]:='RING'; results[4]:='VOICE'; results[5]:='CONNECT FAX';
            results[6]:='CONNECT'; results[7]:='CONNECT 1200'; results[8]:='CONNECT 2400'; results[9]:='CONNECT 4800';
            results[10]:='CONNECT 9600'; results[11]:='CONNECT 14400'; results[12]:='CONNECT 19200';
            results[13]:='CONNECT 28800'; results[14]:='CONNECT 38400'; results[15]:='CONNECT 57600';
            modemstring[1]:='Z'; modemstring[2]:='S0=0'; modemstring[3]:='S0=1';
            modemstring[4]:='M'; modemstring[5]:='M1'; modemstring[6]:='E';
            modemstring[7]:='E1'; modemstring[8]:='O1'; modemstring[9]:='';
            modemstring[10]:=''; modemstring[11]:='';
            timech:=':'; datech:='.';
         end;
     end;
   end else
   begin
      {$I-}
      assign(filehandle,cfname);
      rewrite(filehandle,sizeof(configdata));
      blockwrite(filehandle,configdata,1);
      close(filehandle);
      if ioresult=0 then;
   end;
   {$I+}
end;

procedure open_als(open: boolean);
var c: char;
    i: integer;
begin
   if open then
   begin
      if exist(sfname) then
      begin
         {$I-}
         assign(filehandle,sfname);
         reset(filehandle,sizeof(sysdata));
         if ioresult=0 then
         begin
            i:=filesize(filehandle);
            if i=0 then close(filehandle);
         end else i:=0;
      end else i:=0;
      if i=1 then
      begin
         blockread(filehandle,sysdata,1,i);
         close(filehandle);
      end else
      begin
         for c:='A' to 'J' do
         with sysdata[c] do
         begin
            Sysname:='Sample '+c; Comment:='';
            waitfor:='Name?'; dlay:=15;
            sendhandle:=true; sendpw:=true;
            sendlfd:=false;
         end;
      end;
   end else
   begin
      {$I-}
      assign(filehandle,sfname);
      rewrite(filehandle,sizeof(sysdata));
      blockwrite(filehandle,sysdata,1);
      close(filehandle);
      if ioresult=0 then;
   end;
   {$I+}
end;

procedure open_mac;
var tempi: integer;
begin
   fillchar(macdata,sizeof(macdata),0);
   if exist(mfname) then
   begin
      {$I-}
      assign(filehandle,mfname);
      reset(filehandle,sizeof(macdata));
      if filesize(filehandle)=10 then blockread(filehandle,macdata,1,tempi);
      close(filehandle);
      {$I+}
   end;
end;

procedure open_pro(open: boolean);
var c: char;
    i: integer;
begin
   if open then
   begin
      if exist(pfname) then
      begin
         {$I-}
         assign(filehandle,pfname);
         reset(filehandle,sizeof(protodata));
         if ioresult=0 then
         begin
            i:=filesize(filehandle);
            if i=0 then close(filehandle);
         end else i:=0;
      end else i:=0;
      if i=1 then
      begin
         blockread(filehandle,protodata,1,i);
         close(filehandle);
      end else
      begin
         for c:='A' to 'J' do
         with protodata[c] do
         begin
            protoname:='Empty slot';  comment:='';
            wherefile:=''; upcmd:=''; dncmd:='';
            sequence:=''; askdl:=false; changedl:=true; availauto:=false;
         end;
         with protodata['A'] do
         begin
            protoname:='Internal Zmodem';
            wherefile:='//ZMODEM'; sequence:='**B0';
         end;
         with protodata['B'] do
         begin
            protoname:='Internal Zmodem (Leech)';
            wherefile:='//LZMODEM'; sequence:='**B0';
         end;
         with protodata['C'] do
         begin
            protoname:='Internal Xmodem';
            wherefile:='//XMODEM'; askdl:=true;
         end;
         with protodata['D'] do
         begin
            protoname:='Internal Xmodem (Leech)';
            wherefile:='//LXMODEM'; askdl:=true;
         end;
         with protodata['E'] do
         begin
            protoname:='Zmodem            (DSZ)';
            wherefile:='DSZ.EXE';
            sequence:='**B0';
            upcmd:='port %P speed %S sz %F';
            dncmd:='port %P speed %S rz';
         end;
         with protodata['F'] do
         begin
            protoname:='Ymodem            (DSZ)';
            wherefile:='DSZ.EXE';
            upcmd:='port %P speed %S sb %F';
            dncmd:='port %P speed %S rb %F';
         end;
         with protodata['G'] do
         begin
            protoname:='Xmodem            (DSZ)';
            wherefile:='DSZ.EXE';
            upcmd:='port %P speed %S sx %F';
            dncmd:='port %P speed %S rx %F';
            askdl:=true;
         end;
      end;
   end else
   begin
      {$I-}
      assign(filehandle,pfname);
      rewrite(filehandle,sizeof(protodata));
      blockwrite(filehandle,protodata,1);
      close(filehandle);
      if ioresult=0 then;
   end;
   {$I+}
end;

procedure open_acc(open: boolean);
var c: char;
    i: integer;
begin
   if open then
   begin
      if exist(afname) then
      begin
         {$I-}
         assign(filehandle,afname);
         reset(filehandle,sizeof(accountdata));
         if ioresult=0 then
         begin
            i:=filesize(filehandle);
            if i=0 then close(filehandle);
         end else i:=0;
      end else i:=0;
      if i=1 then
      begin
         blockread(filehandle,accountdata,1,i);
         close(filehandle);
      end else fillchar(accountdata,sizeof(accountdata),0);
   end else
   begin
      {$I-}
      assign(filehandle,afname);
      rewrite(filehandle,sizeof(accountdata));
      blockwrite(filehandle,accountdata,1);
      close(filehandle);
      if ioresult=0 then;
   end;
   {$I+}
end;

procedure open_lst;
var i: integer;
begin
   if exist(lfname) then
   begin
      {$I-}
      assign(filehandle,lfname);
      reset(filehandle,sizeof(lastdata));
      if ioresult=0 then
      begin
         i:=filesize(filehandle);
         if i=0 then close(filehandle);
      end else i:=0;
      {$I+}
   end else i:=0;
   if i=1 then
   begin
      blockread(filehandle,lastdata,1,i);
      close(filehandle);
   end else
   with lastdata do
   begin
      lastbbs:=0;
      ptr_buffer:=1;
      lastcalled:=0;
      scl_writeok:=false;
      scl_full:=false;
      scl_nextio:=1;
      scl_filesize:=configdata.scrollbacksize;
      name_dir:='ZYGOTE';
      name_kbd:='ZYGOTE';
      name_tbl:='ZYGOTE';
      fillchar(timesused[0],16,0);
      fillchar(ldcodes,sizeof(ldcodes),0);
      fillchar(grabbuffer,sizeof(grabbuffer),0);
   end;
end;

procedure open_tbl;
var c: char;
    i: integer;
begin
   if open then
   begin
      if givename>'' then
      begin
         if exist(givename+'.TBL') then
         begin
            {$I-}
            assign(filehandle,givename+'.TBL');
            reset(filehandle,sizeof(tabledata));
            if ioresult=0 then
            begin
               i:=filesize(filehandle);
               if i=0 then close(filehandle);
            end else i:=0;
         end else i:=0;
         if i=1 then
         begin
            blockread(filehandle,tabledata,1,i);
            close(filehandle);
         end else
         begin
            for c:=#0 to #255 do
            with tabledata do
            begin
              rx[ord(c)]:=c;
              tx[c]:=ord(c);
           end;
         end;
         lastdata.name_tbl:=givename;
      end;
   end else
   begin
      {$I-}
      assign(filehandle,givename+'.TBL');
      rewrite(filehandle,sizeof(tabledata));
      blockwrite(filehandle,tabledata,1,i);
      close(filehandle);
      if ioresult=0 then;
   end;
   {$I+}
end;

procedure open_kbd;
var i: integer;
begin
   if open then
   begin
      if givename>'' then
      begin
         if exist(givename+'.KBD') then
         begin
            {$I-}
            assign(filehandle,givename+'.KBD');
            reset(filehandle,sizeof(keyboarddata));
            if ioresult=0 then
            begin
               i:=filesize(filehandle);
               if i=0 then close(filehandle);
            end else i:=0;
         end else i:=0;
         if i=1 then
         begin
            blockread(filehandle,keyboarddata,1,i);
            close(filehandle);
         end else initaltkey;
         lastdata.name_kbd:=givename;
      end;
   end else
   begin
      {$I-}
      assign(filehandle,givename+'.KBD');
      rewrite(filehandle,sizeof(keyboarddata));
      blockwrite(filehandle,keyboarddata,1,i);
      close(filehandle);
      if ioresult=0 then;
   end;
   {$I+}
end;

procedure openall;
var tf: text;
begin
   if not exist('ZYGOTE.1') then
   begin
      assign(filehandle,cfname);
      if exist(cfname) then erase(filehandle);
      assign(filehandle,lfname);
      if exist(lfname) then erase(filehandle);
      assign(filehandle,'ZYGOTE.KBD');
      if exist('ZYGOTE.KBD') then erase(filehandle);
      assign(tf,'ZYGOTE.1');
      rewrite(tf);
      writeln(tf,'V',cmsg(zversion));
      close(tf);
   end;
   fillchar(saveflag,sizeof(saveflag),0);
   loadconfig:=false;
   open_cfg(true);
   open_als(true);
   open_mac;
   open_pro(true);
   open_acc(true);
   open_lst;
   open_tbl('ZYGOTE',true);
   open_kbd('ZYGOTE',true);
end;

procedure closeall;
begin
   _deinstall;
   if saveflag[1] then open_kbd(lastdata.name_kbd,false);
   if (saveflag[2]) or (saveflag[3]) then open_tbl(lastdata.name_tbl,false);
   if saveflag[8] then open_als(false);
   if saveflag[10] then open_pro(false);
   if saveflag[12] then open_acc(false);
   if (saveflag[4]) or (saveflag[5]) or (saveflag[6]) or
      (saveflag[7]) or (saveflag[9]) or (saveflag[11]) or
      (saveflag[13]) or (saveflag[14]) or (saveflag[15]) or
      (saveflag[16]) then open_cfg(false);
end;

Procedure restorebbs;
var i: integer;
begin
   if (_CD) and (lastdata.lastbbs>0) then
   begin
      dparam:=lastdata.param;
      dialnumber:=lastdata.lastbbs;
      if exist(dir_phone+'\'+lastdata.name_dir+'.DIR') then
      begin
         assign(filehandle,dir_phone+'\'+lastdata.name_dir+'.DIR');
         {$I-} reset(filehandle,sizeof(dialdata));
         if (ioresult=0) and (lastdata.lastbbs<=filesize(filehandle)) then
         begin
            connected:=true;
            seek(filehandle,lastdata.lastbbs-1);
            blockread(filehandle,dialdata,1,i);
            with dparam do _set_param(speed,parity,dbit,sbit);
         end;
         close(filehandle); {$I+}
         open_tbl(dialdata.file_tbl,true);
         open_kbd(dialdata.file_kbd,true);
      end;
   end else
   begin
      dialdata.file_pad:='GENERAL';
      dialdata.bbsname:='  General Purpose PAD  ';
   end;
   statusbar;
end;

procedure changeparams;
var ch,c: char;
    choice,colr,lo: byte;
    oldname: stringname;

procedure writemenu;
var c,y: byte;
begin
    c:=attr(lightblue,black);
    makebox(c,39,1,80,17,1);
    fwritena('´                   Ã',1,59);
    fwrite('Change Parameters',1,61,attr(yellow,black));
    fwritena('Â',1,58); fwritena('Á',17,58);
    for y:=2 to 16 do fwritena('³',y,58);
    c:=attr(lightcyan,black);
    fwrite('Phone directory',2,41,c);  fwrite(lastdata.name_dir+'.DIR',2,60,c);
    fwrite('Scrollback size',3,41,c);  fwrite(its(lastdata.scl_filesize),3,60,c);
    page.flag:=0;
    timestat.flag:=0;
    sc.x:=40; sc.y:=4;
    sc.s:=18;
    sc.t:=13;
    sc.c:=hattr(white,cyan);
    sc.nc:=attr(cyan,black);
    colr:=attr(lightgray,black);
    fwrite('Keyboard file',4,41,sc.nc);
    fwrite('Translation file',5,41,sc.nc);
    fwrite('.KBD',4,68,colr);              fwrite('.TBL',5,68,colr);
    fwrite(' Speed',6,40,sc.nc);           fwrite(' Parity',7,40,sc.nc);
    fwrite(' Data bit',8,40,sc.nc);        fwrite(' Stop bit',9,40,sc.nc);
    fwrite(' Graphic type',10,40,sc.nc);   fwrite(' Add linefeed',11,40,sc.nc);
    fwrite(' Local echo',12,40,sc.nc);     fwrite(' Strip high bit',13,40,sc.nc);
    fwrite(' Destructive BS',14,40,sc.nc); fwrite(' Keep emul codes',15,40,sc.nc);
    fwrite(' Capture exist',16,40,sc.nc);
end;

begin
   wx:=wherex; wy:=wherey;
   cursor(false);
   savevideo(videoback,true);
   writemenu;
   choice:=1;
   editflag(1,0,0,1,0,1,0);
   with dparam do
   repeat
      fwrite(lastdata.name_kbd+blanks(8-length(lastdata.name_kbd)),4,60,colr);
      fwrite(lastdata.name_tbl+blanks(8-length(lastdata.name_tbl)),5,60,colr);
      fwrite(its(speed)+'   ',6,60,colr);
      fwrite(parity,7,60,colr);
      fwrite(its(dbit),8,60,colr);
      fwrite(its(sbit),9,60,colr);
      case graphic of
           uANSI: fwrite('ANSI graphic  ',10,60,colr);
         uAVATAR: fwrite('AVATAR graphic',10,60,colr);
          uVT100: fwrite('VT100 graphic ',10,60,colr);
           uNONE: fwrite('No graphic    ',10,60,colr);
      end;
      if autolf then fwrite('Yes',11,60,colr) else fwrite('No ',11,60,colr);
      if localecho then fwrite('Yes',12,60,colr) else fwrite('No ',12,60,colr);
      if striphb then fwrite('Yes',13,60,colr) else fwrite('No ',13,60,colr);
      if destructbs then fwrite('Yes',14,60,colr) else fwrite('No ',14,60,colr);
      if captureemul then fwrite('Yes',15,60,colr) else fwrite('No ',15,60,colr);
      if captureexist=uAPPEND then fwrite('Append   ',16,60,colr) else fwrite('Overwrite',16,60,colr);

      lo:=0;
      ch:=scrollchoice(#27+#13,choice);
      if ch=#13 then
      case choice of
        1: begin
              oldname:=lastdata.name_kbd;
              lastdata.name_kbd:=pickfile(60,4,'*.kbd',lastdata.name_kbd);
              if oldname=lastdata.name_kbd then
                 c:=input(colr,60,4,lastdata.name_kbd,8,8,lo) else c:=#13;
              if c=#27 then lastdata.name_kbd:=oldname else
              begin
                 if lastdata.name_kbd='' then lastdata.name_kbd:=oldname;
                 if oldname<>lastdata.name_kbd then
                 begin
                    open_kbd(oldname,false);
                    open_kbd(lastdata.name_kbd,true);
                 end;
              end;
           end;
        2: begin
              oldname:=lastdata.name_tbl;
              lastdata.name_tbl:=pickfile(60,4,'*.tbl',lastdata.name_tbl);
              if oldname=lastdata.name_tbl then
                 c:=input(colr,60,5,lastdata.name_tbl,8,8,lo) else c:=#13;
              if c=#27 then lastdata.name_tbl:=oldname else
              begin
                 if lastdata.name_tbl='' then lastdata.name_tbl:=oldname;
                 if oldname<>lastdata.name_tbl then
                 begin
                    open_tbl(oldname,false);
                    open_tbl(lastdata.name_tbl,true);
                 end;
              end;
           end;
        3: case speed of
                   300: speed:=1200;
                  1200: speed:=2400;
                  2400: speed:=4800;
                  4800: speed:=9600;
                  9600: speed:=14400;
                 14400: speed:=19200;
                 19200: speed:=28800;
                 28800: speed:=38400;
                 38400: speed:=57600;
                 57600: speed:=300;
           end;
        4: case parity of
                 'N': parity:='E';
                 'E': parity:='S';
                 'S': parity:='M';
                 'M': parity:='O';
                 'O': parity:='N';
               end;
        5: if dbit=8 then dbit:=5 else inc(dbit);
        6: if sbit=1 then sbit:=2 else sbit:=1;
        7: case graphic of
                  uANSI: graphic:=uVT100;
                 uVT100: graphic:=uAVATAR;
                uAVATAR: graphic:=uNONE;
                  uNONE: graphic:=uANSI;
           end;
        8: autolf:=not autolf;
        9: localecho:=not localecho;
       10: striphb:=not striphb;
       11: destructbs:=not destructbs;
       12: captureemul:=not captureemul;
       13: if captureexist=uAPPEND then captureexist:=uOVERWRITE else captureexist:=uAPPEND;
      end;
   until ch=#27;
   with dparam do _set_param(speed,parity,dbit,sbit);
   savevideo(videoback,false);
   gotoxy(wx,wy);
   statusbar;
   cursor(true);
end;

end.
