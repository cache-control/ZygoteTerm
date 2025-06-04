unit z_xmodem;

interface
{$F+,O+}

procedure xmdnload(name: string; leech: boolean);
procedure xmupload(name: string);

implementation

uses z_util,z_comio,crt,dos;

const maxxmtries = 9;
      mxblocks   = 25;
      xblocksize = 128;

      NAK     = 21;
      ACK     = 06;
      CAN     = 24;
      SOH     = 01;
      EOT     = 04;
      TIMEOUT = 00;

type xblocktype = array[1..xblocksize] of byte;
     xblockstype = array[1..mxblocks] of xblocktype;

var xblocks: ^xblockstype;
    bytesxfer,starttime,endtime: longint;
    hour,min,sec,hund,totalblocks: word;
    lasttime: string[12];

procedure displaywin(do_ul: boolean);
var colr,i: byte;
   procedure button(x,y: byte; out: boolean);
   var color1,color2: byte;
   begin
      if out then
      begin
         color1:=attr(darkgray,lightgray);
         color2:=attr(white,lightgray);
      end else
      begin
         color1:=attr(white,lightgray);
         color2:=attr(darkgray,lightgray);
      end;
      makebox(color1,x,y,x+48,y+16,1);
      changeattr(48,y,x,color2);
      for color1:=1 to 16 do changeattr(1,y+color1,x,color2);
   end;
begin
   button(1,2,do_ul);
   colr:=attr(blue,lightgray);
   fwrite('Protocol name',3,3,colr);
   fwrite('Name of file',4,3,colr);
   fwrite('Size of file',5,3,colr);
   fwrite('Number of blocks',6,3,colr);
   fwrite('Direction',7,3,colr);
   fwrite('Completion',8,3,colr);
   fwrite('Error checking',9,3,colr);
   fwrite('Mode of xfer',10,3,colr);
   fwrite('Current time',11,3,colr);
   fwrite('Elapsed time',12,3,colr);
   fwrite('Wait count',13,3,colr);
   fwrite('CPS rate',14,3,colr);
   fwrite('Bytes xfer',15,3,colr);
   fwrite('Total blocks',16,3,colr);
   fwrite('Status message',17,3,colr);
   for i:=3 to 17 do fwrite('³',i,20,attr(cyan,lightgray));
   fwrite('³'+blanks(20)+'³',8,22,attr(green,lightgray));
   fwrite('Xmodem-128b',3,22,attr(red,lightgray));
   fwrite('Checksum',9,22,attr(black,lightgray));
   fwrite('0 bytes',16,22,attr(black,lightgray));
end;

procedure msg(s: string);
begin
   fwrite(s+blanks(26-length(s)),17,22,attr(black,lightgray));
end;

function nameonly(s: string): string;
var i: byte;
begin
   i:=length(s);
   while (i>1) and (s[i]<>':') and (s[i]<>'\') do dec(i);
   if (s[i]<>':') and (s[i]<>'\') then nameonly:=caps(s) else
      nameonly:=caps(copy(s,i+1,length(s)));
end;

function _timed_char(seconds: byte): byte;
var lastsec: word;
    countsec: byte;
    c: char;

begin
  gettime(hour,min,lastsec,hund);
  countsec:=0;
  repeat
      gettime(hour,min,sec,hund);
      if lastsec<>sec then
      begin
         lastsec:=sec;
         inc(countsec);
         fwrite(its(countsec)+' Sec  ',13,22,attr(black,lightgray));
      end;
  until (_rx_ready) or (countsec=seconds);
  if countsec=seconds then _timed_char:=timeout else _timed_char:=_get;
end;

function readxblock(var xblock: xblocktype; bn: integer): boolean;
var i,checksum      : integer;
    blocknumerror,
    checksumerror   : boolean;
    c,bnum,bnumcomp : byte;

begin
   bnum:=_timed_char(5);
   bnumcomp:=_timed_char(5);
   if bnum+bnumcomp<>255 then blocknumerror:=true else
      if bnum<>bn then blocknumerror:=true else
      begin
         blocknumerror:=false;
         for i:=1 to xblocksize do xblock[i]:=_timed_char(5);
         c:=_timed_char(5);
         checksum:=0;
         for i:=1 to xblocksize do checksum:=(checksum+xblock[i]) mod 256;
         checksumerror:=c <> checksum;
         bytesxfer:=bytesxfer+xblocksize;
      end;

   if blocknumerror then
   repeat
      c:=_timed_char(5);
   until c=timeout;
   readxblock:=not (blocknumerror or checksumerror);
end;

procedure xmdnload(name: string; leech: boolean);
var xfile        : file;
    count,numxbs,
    blockreads,
    blocknum     : integer;
    done,
    okio,
    transferok   : boolean;
    c: byte;

   procedure savexblocks;
   var i: integer;
   begin
      {$I-}
      for i:=1 to numxbs do
      begin
         blockwrite(xfile,xblocks^[i],1);
         okio:=ioresult = 0;
         if not okio then exit;
         msg('Saving block #'+its(i));
      end;
      numxbs:= 0;
      {$I+}
   end;

begin
   {$I-}
   cursor(false);
   assign(xfile,name);
   rewrite(xfile);
   okio:=ioresult = 0;
   displaywin(false);

   if not okio then
   begin
      msg('Problem opening file');
      _put(CAN);
      exit;
   end;

   new(xblocks);
   fwrite(nameonly(name),4,22,attr(black,lightgray));
   fwrite('Not available',5,22,attr(black,lightgray));
   fwrite('Not available',6,22,attr(black,lightgray));
   fwrite('Receive',7,22,attr(black,lightgray));
   fwrite('Not available',8,24,attr(black,lightgray));
   if leech then fwrite('Leech',10,22,attr(black,lightgray)) else fwrite('Normal',10,22,attr(black,lightgray));

   count:=0;
   bytesxfer:=0;
   totalblocks:=0;
   repeat
      _put(NAK);
      inc(count);
      c:=_timed_char(10);
   until (c in [SOH,EOT,CAN]) or (count=maxxmtries) or keypressed;

   numxbs:=0;
   blocknum:=1;
   blockreads:=0;
   done:=false;

   gettime(hour,min,sec,hund);
   starttime:=hour*3600 + min*60 + sec;
   repeat
      if lasttime<>time(1) then
      begin
         lasttime:=time(1);
         gettime(hour,min,sec,hund);
         endtime:=hour*3600 + min*60 + sec;
         if endtime<starttime then endtime:=endtime+86400;
         endtime:=endtime-starttime;
         if endtime=0 then endtime:=1;
         fwrite(lasttime+'',11,22,attr(black,lightgray));
         fwrite(its(endtime div 3600)+' hr. '+its(EndTime div 60)+' min. '+
                its(endtime mod 60)+' Sec. ',12,22,attr(black,lightgray));
         fwrite('0 Sec  ',13,22,attr(black,lightgray));
         fwrite(its(Round(Bytesxfer/endtime))+' cps   ',14,22,attr(black,lightgray));
         fwrite(its(bytesxfer)+' bytes   ',15,22,attr(black,lightgray));
      end;
      if not _cd then
      begin
         _put(CAN);
         msg('Lost carrier');
         done:=true;
         transferok:=false;
      end else
      if keypressed then
      begin
         if readkey=^[ then
         begin
            _put(CAN);
            _put(CAN);
            msg('Xfer cancelled by user.');
            done:=true;
            transferok:=false;
         end;
      end else
      case c of
               EOT: begin
                       if leech then
                       begin
                          _put(CAN);
                          _put(CAN);
                          _put(CAN);
                          _put(CAN);
                          _put(CAN);
                          msg('Leeching file');
                       end else
                       begin
                          _put(ACK);
                          msg('Download completed.');
                       end;
                       delay(800);
                       savexblocks;
                       done:=true;
                       transferok:=true;
                    end;
               CAN: begin
                       msg('Host cancelled xfer.');
                       done:=true;
                       transferok:=false;
                    end;
           TIMEOUT: begin
                       _put(CAN);
                       _put(CAN);
                       msg('Timeout, xfer cancelled.');
                       done:= true;
                       transferok:= false;
                    end;
               else if readxblock(xblocks^[numxbs+1],blocknum) then
                    begin
                       msg('Block #'+its(blocknum)+' good.');
                       inc(blocknum);
                       inc(totalblocks);
                       fwrite(its(totalblocks)+' blocks.     ',16,22,attr(black,lightgray));
                       if blocknum>255 then blocknum:=0;
                       blockreads:=0;
                       inc(numxbs);
                       if numxbs=mxblocks then savexblocks;
                       if okio then _put(ACK) else _put(CAN);
                    end else
                    begin
                       inc(blockreads);
                       msg('Block #'+its(blocknum)+' Bad. Retrying.');
                       if blockreads=maxxmtries then
                       begin
                          done:= true;
                          transferok:= false;
                          msg('Bad Block #'+its(blocknum)+', abort.');
                       end;
                       _put(NAK);
                    end;
      end;
      if (not done) and (okio) then c:=_timed_char(20);
   until (done) or (not okio);
   if okio then
   begin
      if leech then _putstring(^C+^X+^C+^X+^C+^X+^C+^X+^C+^X+^C+^X);
      close(xfile);
      okio:=ioresult = 0;
   end;
   if not okio then msg('Problem saving file.');
   delay(1500);
   dispose(xblocks);
   cursor(true);
   {$I+}
end;

procedure writexblock(xblock: xblocktype; bn: integer);
const dnum = 1; { amount to delay betweeen characters.  Trial and error! }
var i,checksum: integer;

begin
   _put(SOH);
   delay(dnum);
   _put(bn);
   delay(dnum);
   _put(255-bn);
   delay(dnum);
   checksum:=0;
   for i:=1 to xblocksize do
   begin
      checksum:=(checksum+xblock[i]) mod 256;
      _put(xblock[i]);
      delay(dnum);
   end;
   _put(checksum);
   delay(dnum);
   bytesxfer:=bytesxfer+xblocksize;
end;

procedure xmupload(name: string);
var xfile: file;
    blockwrites,
    blocknum,
    numread,numxbs,
    nxb,count: integer;
    sizeoffile: longint;
    numofblocks: word;
    okio,abort,
    transferdone: boolean;
    c: byte;

   procedure readblocks;
   begin
      {$I-}
      numxbs:= 0;
      while okio and (numread=xblocksize) and (numxbs<mxblocks) do
      begin
         fillchar(xblocks^[numxbs+1],xblocksize,0);
         blockread(xfile,xblocks^[numxbs+1],xblocksize,numread);
         okio:= ioresult = 0;
         if okio then
         begin
            inc(numxbs);
            msg('Reading block #'+its(numxbs));
         end;
      end;
      nxb:=numxbs;
      if okio then if (numxbs=0) and (numread<xblocksize) then transferdone:=true;
      {$I+}
   end;

begin
   {$I-}
   cursor(false);
   assign(xfile,name);
   reset(xfile,1);
   displaywin(true);
   okio:= ioresult = 0;
   if (not okio) or (name='') then
   begin
      msg('File not found.');
      exit;
   end else
   begin
      sizeoffile:=filesize(xfile);
      numofblocks:=trunc(sizeoffile / xblocksize);
      if sizeoffile mod xblocksize>0 then inc(numofblocks);
   end;
   new(xblocks);
   fwrite(nameonly(name),4,22,attr(black,lightgray));
   fwrite(its(sizeoffile)+' bytes',5,22,attr(black,lightgray));
   fwrite(its(numofblocks)+' blocks',6,22,attr(black,lightgray));
   fwrite('Send',7,22,attr(black,lightgray));
   fwrite('Normal',10,22,attr(black,lightgray));
   numread:=xblocksize;
   readblocks;
   count:= 0;
   totalblocks:=0;
   bytesxfer:=0;
   if _cd then
   repeat
      inc(count);
      c:=_timed_char(10);
   until (c in [NAK,EOT,CAN]) or (count=maxxmtries) or keypressed;

   blocknum:=1;
   blockwrites:=0;
   transferdone:=false;
   abort:=false;

   gettime(hour,min,sec,hund);
   starttime:=hour*3600 + min*60 + sec;
   repeat
      if lasttime<>time(1) then
      begin
         lasttime:=time(1);
         gettime(hour,min,sec,hund);
         endtime:=hour*3600 + min*60 + sec;
         if endtime<starttime then endtime:=endtime+86400;
         endtime:=endtime-starttime;
         if endtime=0 then endtime:=1;
         fwrite(lasttime+'',11,22,attr(black,lightgray));
         fwrite(its(endtime div 3600)+' hr. '+its(EndTime div 60)+' min. '+
                its(endtime mod 60)+' Sec. ',12,22,attr(black,lightgray));
         fwrite('0 Sec  ',13,22,attr(black,lightgray));
         fwrite(its(Round(Bytesxfer/endtime))+' cps   ',14,22,attr(black,lightgray));
         fwrite(its(bytesxfer)+' bytes   ',15,22,attr(black,lightgray));
      end;
      if not _cd then
      begin
         _put(CAN);
         msg('Lost carrier');
         abort:=true;
      end else
      if not okio then
      begin
         msg('Problem reading file.');
         _put(CAN);
      end else
      if keypressed then
      begin
         if readkey=^[ then
         begin
            _put(CAN);
            _put(CAN);
            msg('Xfer aborted, Keypressed.');
            abort:=true;
         end;
      end else
      case c of
           CAN: begin
                   msg('Host cancelled transfer.');
                   abort:= true;
                end;
       TIMEOUT: begin
                   _put(CAN);
                   msg('Timeout occurred.');
                   abort:= true;
                end;
           ACK,
           NAK: begin
                   if numxbs=0 then readblocks;
                   if not transferdone then writexblock(xblocks^[nxb+1-numxbs],blocknum);
                end;
      end;

      if not abort and not transferdone then
      begin
         count:= 0;
         repeat
             inc(count);
             c:=_timed_char(10);
         until (c<>timeout) or (count=maxxmtries) or keypressed;

         if c=ACK then
         begin
            msg('Block #'+its(blocknum)+' good.');
            inc(blocknum);
            inc(totalblocks);
            fwrite(its(totalblocks)+' blocks.     ',16,22,attr(black,lightgray));
            fwrite(chars('Û',trunc(totalblocks/numofblocks*210)),8,23,attr(cyan,lightgray));
            if blocknum>255 then blocknum:= 0;
            blockwrites:= 0;
            dec(numxbs);
            if (numxbs=0) and (numread<xblocksize) then transferdone:=true;
         end else
         if c=NAK then
         begin
            inc(blockwrites);
            msg('Block #'+its(blocknum)+' bad.');
            if blockwrites=maxxmtries then
            begin
               abort:= true;
               msg('Problem with block #'+its(blocknum)+'.');
            end;
         end;
      end;
   until abort or transferdone;

   if okio then
   begin
      close(xfile);
      okio:=ioresult = 0;
   end;

   if transferdone then
   begin
      _put(EOT);
      c:=_timed_char(20);
      if c=ACK then msg('Xfer successful.') else msg('ACK not received.');
   end;

   delay(1500);
   dispose(xblocks);
   cursor(true);
   {$I+}
end;

end.
