unit z_zmodem;

interface
{$F+,O+}

var zbaud: word;

function Zmodem_Receive(leechit: char; path: string): boolean;
procedure batchzmodem(s: string);

implementation
uses crt,dos,z_util,z_comio;

const zbufsize = 1024;

type hdrtype = array[0..3] of byte;
     buftype = array[0..1023] of byte;

const
   ZPAD = 42;  { '*' }
   ZDLE = 24;  { ^X  }
   ZDLEE = 88;
   ZBIN = 65;  { 'A' }
   ZHEX = 66;  { 'B' }
   ZBIN32 = 67;{ 'C' }
   ZRQINIT = 0;
   ZRINIT = 1;
   ZSINIT = 2;
   ZACK = 3;
   ZFILE = 4;
   ZSKIP = 5;
   ZNAK = 6;
   ZABORT = 7;
   ZFIN = 8;
   ZRPOS = 9;
   ZDATA = 10;
   ZEOF = 11;
   ZFERR = 12;
   ZCRC = 13;
   ZCHALLENGE = 14;
   ZCOMPL = 15;
   ZCAN = 16;
   ZFREECNT = 17;
   ZCOMMAND = 18;
   ZSTDERR = 19;
   ZCRCE = 104; { 'h' }
   ZCRCG = 105; { 'i' }
   ZCRCQ = 106; { 'j' }
   ZCRCW = 107; { 'k' }
   ZRUB0 = 108; { 'l' }
   ZRUB1 = 109; { 'm' }
   ZOK = 0;
   ZERROR = -1;
   ZTIMEOUT = -2;
   RCDO = -3;
   FUBAR = -4;
   GOTOR = 256;
   GOTCRCE = 360; { 'h' or 256 }
   GOTCRCG = 361; { 'i' "   "  }
   GOTCRCQ = 362; { 'j' "   "  }
   GOTCRCW = 363; { 'k' "   "  }
   GOTCAN = 272;  { CAN or  "  }

{ xmodem paramaters }
   ENQ = 5;
   CAN = 24;
   XOFF = 19;
   XON = 17;
   SOH = 1;
   STX = 2;
   EOT = 4;
   ACK = 6;
   NAK = 21;
   CPMEOF = 26;

{ byte positions }
   ZF0 = 3;
   ZF1 = 2;
   ZF2 = 1;
   ZF3 = 0;
   ZP0 = 0;
   ZP1 = 1;
   ZP2 = 2;
   ZP3 = 3;

{ bit masks for ZRINIT }
   CANFDX = 1;    { can handle full-duplex          (yes for PC's)}
   CANOVIO = 2;   { can overlay disk and serial I/O (ditto)       }
   CANBRK = 4;    { can send a break - true but superfluous       }
   CANCRY = 8;    { can encrypt/decrypt - not defined yet         }
   CANLZW = 16;   { can LZ compress - not defined yet             }
   CANFC32 = 32;  { can use 32 bit crc frame checks - true        }
   ESCALL = 64;   { escapes all control chars. not implemented    }
   ESC8 = 128;    { escapes the 8th bit. not implemented          }

{ bit masks for ZSINIT }
   TESCCTL = 64;
   TESC8 = 128;

{ paramaters for ZFILE }
{ ZF0 }
   ZCBIN = 1;
   ZCNL = 2;
   ZCRESUM = 3;
{ ZF1 }
   ZMNEW = 1;   {I haven't implemented these as of yet - most are}
   ZMCRC = 2;   {superfluous on a BBS - Would be nice from a comm}
   ZMAPND = 3;  {programs' point of view however                 }
   ZMCLOB = 4;
   ZMSPARS = 5;
   ZMDIFF = 6;
   ZMPROT = 7;
{ ZF2 }
   ZTLZW = 1;   {encryption, compression and funny file handling }
   ZTCRYPT = 2; {flags - My docs (03/88) from OMEN say these have}
   ZTRLE = 3;   {not been defined yet                            }
{ ZF3 }
   ZCACK1 = 1;  {God only knows...                               }
   lastsent: byte = 0;

   C1970 = 2440588;
   D0 = 1461;
   D1 = 146097;
   D2 = 1721119;
   crctable: array[0..255] of word = (
   $0000,  $1021,  $2042,  $3063,  $4084,  $50a5,  $60c6,  $70e7,
   $8108,  $9129,  $a14a,  $b16b,  $c18c,  $d1ad,  $e1ce,  $f1ef,
   $1231,  $0210,  $3273,  $2252,  $52b5,  $4294,  $72f7,  $62d6,
   $9339,  $8318,  $b37b,  $a35a,  $d3bd,  $c39c,  $f3ff,  $e3de,
   $2462,  $3443,  $0420,  $1401,  $64e6,  $74c7,  $44a4,  $5485,
   $a56a,  $b54b,  $8528,  $9509,  $e5ee,  $f5cf,  $c5ac,  $d58d,
   $3653,  $2672,  $1611,  $0630,  $76d7,  $66f6,  $5695,  $46b4,
   $b75b,  $a77a,  $9719,  $8738,  $f7df,  $e7fe,  $d79d,  $c7bc,
   $48c4,  $58e5,  $6886,  $78a7,  $0840,  $1861,  $2802,  $3823,
   $c9cc,  $d9ed,  $e98e,  $f9af,  $8948,  $9969,  $a90a,  $b92b,
   $5af5,  $4ad4,  $7ab7,  $6a96,  $1a71,  $0a50,  $3a33,  $2a12,
   $dbfd,  $cbdc,  $fbbf,  $eb9e,  $9b79,  $8b58,  $bb3b,  $ab1a,
   $6ca6,  $7c87,  $4ce4,  $5cc5,  $2c22,  $3c03,  $0c60,  $1c41,
   $edae,  $fd8f,  $cdec,  $ddcd,  $ad2a,  $bd0b,  $8d68,  $9d49,
   $7e97,  $6eb6,  $5ed5,  $4ef4,  $3e13,  $2e32,  $1e51,  $0e70,
   $ff9f,  $efbe,  $dfdd,  $cffc,  $bf1b,  $af3a,  $9f59,  $8f78,
   $9188,  $81a9,  $b1ca,  $a1eb,  $d10c,  $c12d,  $f14e,  $e16f,
   $1080,  $00a1,  $30c2,  $20e3,  $5004,  $4025,  $7046,  $6067,
   $83b9,  $9398,  $a3fb,  $b3da,  $c33d,  $d31c,  $e37f,  $f35e,
   $02b1,  $1290,  $22f3,  $32d2,  $4235,  $5214,  $6277,  $7256,
   $b5ea,  $a5cb,  $95a8,  $8589,  $f56e,  $e54f,  $d52c,  $c50d,
   $34e2,  $24c3,  $14a0,  $0481,  $7466,  $6447,  $5424,  $4405,
   $a7db,  $b7fa,  $8799,  $97b8,  $e75f,  $f77e,  $c71d,  $d73c,
   $26d3,  $36f2,  $0691,  $16b0,  $6657,  $7676,  $4615,  $5634,
   $d94c,  $c96d,  $f90e,  $e92f,  $99c8,  $89e9,  $b98a,  $a9ab,
   $5844,  $4865,  $7806,  $6827,  $18c0,  $08e1,  $3882,  $28a3,
   $cb7d,  $db5c,  $eb3f,  $fb1e,  $8bf9,  $9bd8,  $abbb,  $bb9a,
   $4a75,  $5a54,  $6a37,  $7a16,  $0af1,  $1ad0,  $2ab3,  $3a92,
   $fd2e,  $ed0f,  $dd6c,  $cd4d,  $bdaa,  $ad8b,  $9de8,  $8dc9,
   $7c26,  $6c07,  $5c64,  $4c45,  $3ca2,  $2c83,  $1ce0,  $0cc1,
   $ef1f,  $ff3e,  $cf5d,  $df7c,  $af9b,  $bfba,  $8fd9,  $9ff8,
   $6e17,  $7e36,  $4e55,  $5e74,  $2e93,  $3eb2,  $0ed1,  $1ef0);
   c32table: array[0..255] of longint = (
   $00000000, $77073096, $ee0e612c, $990951ba, $076dc419, $706af48f, $e963a535, $9e6495a3,
   $0edb8832, $79dcb8a4, $e0d5e91e, $97d2d988, $09b64c2b, $7eb17cbd, $e7b82d07, $90bf1d91,
   $1db71064, $6ab020f2, $f3b97148, $84be41de, $1adad47d, $6ddde4eb, $f4d4b551, $83d385c7,
   $136c9856, $646ba8c0, $fd62f97a, $8a65c9ec, $14015c4f, $63066cd9, $fa0f3d63, $8d080df5,
   $3b6e20c8, $4c69105e, $d56041e4, $a2677172, $3c03e4d1, $4b04d447, $d20d85fd, $a50ab56b,
   $35b5a8fa, $42b2986c, $dbbbc9d6, $acbcf940, $32d86ce3, $45df5c75, $dcd60dcf, $abd13d59,
   $26d930ac, $51de003a, $c8d75180, $bfd06116, $21b4f4b5, $56b3c423, $cfba9599, $b8bda50f,
   $2802b89e, $5f058808, $c60cd9b2, $b10be924, $2f6f7c87, $58684c11, $c1611dab, $b6662d3d,
   $76dc4190, $01db7106, $98d220bc, $efd5102a, $71b18589, $06b6b51f, $9fbfe4a5, $e8b8d433,
   $7807c9a2, $0f00f934, $9609a88e, $e10e9818, $7f6a0dbb, $086d3d2d, $91646c97, $e6635c01,
   $6b6b51f4, $1c6c6162, $856530d8, $f262004e, $6c0695ed, $1b01a57b, $8208f4c1, $f50fc457,
   $65b0d9c6, $12b7e950, $8bbeb8ea, $fcb9887c, $62dd1ddf, $15da2d49, $8cd37cf3, $fbd44c65,
   $4db26158, $3ab551ce, $a3bc0074, $d4bb30e2, $4adfa541, $3dd895d7, $a4d1c46d, $d3d6f4fb,
   $4369e96a, $346ed9fc, $ad678846, $da60b8d0, $44042d73, $33031de5, $aa0a4c5f, $dd0d7cc9,
   $5005713c, $270241aa, $be0b1010, $c90c2086, $5768b525, $206f85b3, $b966d409, $ce61e49f,
   $5edef90e, $29d9c998, $b0d09822, $c7d7a8b4, $59b33d17, $2eb40d81, $b7bd5c3b, $c0ba6cad,
   $edb88320, $9abfb3b6, $03b6e20c, $74b1d29a, $ead54739, $9dd277af, $04db2615, $73dc1683,
   $e3630b12, $94643b84, $0d6d6a3e, $7a6a5aa8, $e40ecf0b, $9309ff9d, $0a00ae27, $7d079eb1,
   $f00f9344, $8708a3d2, $1e01f268, $6906c2fe, $f762575d, $806567cb, $196c3671, $6e6b06e7,
   $fed41b76, $89d32be0, $10da7a5a, $67dd4acc, $f9b9df6f, $8ebeeff9, $17b7be43, $60b08ed5,
   $d6d6a3e8, $a1d1937e, $38d8c2c4, $4fdff252, $d1bb67f1, $a6bc5767, $3fb506dd, $48b2364b,
   $d80d2bda, $af0a1b4c, $36034af6, $41047a60, $df60efc3, $a867df55, $316e8eef, $4669be79,
   $cb61b38c, $bc66831a, $256fd2a0, $5268e236, $cc0c7795, $bb0b4703, $220216b9, $5505262f,
   $c5ba3bbe, $b2bd0b28, $2bb45a92, $5cb36a04, $c2d7ffa7, $b5d0cf31, $2cd99e8b, $5bdeae1d,
   $9b64c2b0, $ec63f226, $756aa39c, $026d930a, $9c0906a9, $eb0e363f, $72076785, $05005713,
   $95bf4a82, $e2b87a14, $7bb12bae, $0cb61b38, $92d28e9b, $e5d5be0d, $7cdcefb7, $0bdbdf21,
   $86d3d2d4, $f1d4e242, $68ddb3f8, $1fda836e, $81be16cd, $f6b9265b, $6fb077e1, $18b74777,
   $88085ae6, $ff0f6a70, $66063bca, $11010b5c, $8f659eff, $f862ae69, $616bffd3, $166ccf45,
   $a00ae278, $d70dd2ee, $4e048354, $3903b3c2, $a7672661, $d06016f7, $4969474d, $3e6e77db,
   $aed16a4a, $d9d65adc, $40df0b66, $37d83bf0, $a9bcae53, $debb9ec5, $47b2cf7f, $30b5ffe9,
   $bdbdf21c, $cabac28a, $53b39330, $24b4a3a6, $bad03605, $cdd70693, $54de5729, $23d967bf,
   $b3667a2e, $c4614ab8, $5d681b02, $2a6f2b94, $b40bbe37, $c30c8ea1, $5a05df1b, $2d02ef8d);

var rxpos,
    ftime,fsize,
    txpos,ztime: longint;
    rxhdr,txhdr: hdrtype;
    rxtimeout,rxtype,
    rxframeind,fmode: integer;
    fname: string;
    usecrc32: boolean;
    leechmode: char;
    zcps, zerrors: word;
    attn,secbuf: ^buftype;

function z_openfile(var f: file; pathname: string): boolean;
begin {$I-}
   assign(f,pathname);
   reset(f,1);
   z_openfile:= ioresult=0;
end;  {$I+}

function z_makefile(var f: file; pathname: string): boolean;
begin {$I-}
   assign(f,pathname);
   rewrite(f,1);
   z_makefile:= ioresult=0;
end;  {$I+}

procedure z_closefile(var f: file);
begin {$I-}
   Close(f);
   if ioresult=0 then;
end;  {$I+}

function z_seekfile(var f: file; fpos: longint): boolean;
begin {$I-}
   Seek(f,fpos);
   z_seekfile:= ioresult=0;
end;  {$I+}

function z_writefile(var f: file; var buff; bytes: word): boolean;
begin {$I-}
   BlockWrite(f,buff,bytes);
   z_writefile:= ioresult=0;
end; {$I+}

function z_readfile(var f: file; var buff; btoread: word; var bread: word): boolean;
begin {$I-}
   BlockRead(f,buff,btoread,bread);
   z_readfile:= ioresult=0;
end; {$I+}

function z_findfile(pathname: string; var name: string; var size, time: longint): boolean;
var sr: searchrec;
begin {$I-}
   findfirst(pathname,archive,sr);
   if (doserror<>0) or (ioresult<>0) then z_findfile:=false else
   begin
      name:= sr.Name;
      size:= sr.Size;
      time:= sr.Time;
      z_findfile:= true
   end;
end; {$I+}

procedure z_setftime(var f: file; time: longint);
begin {$I-}
   setftime(f,time);
   if ioresult=0 then;
end;  {$I+}

procedure GregorianToJulianDN(year,month,day: integer; var JulianDN: longint);
var Century,xyear: longint;
begin
   if month<=2 then
   begin
      year:=pred(year);
      inc(month,12);
   end;
   dec(month,3);
   Century:= year div 100;
   xyear:= year mod 100;
   Century:= (Century * D1) shr 2;
   xyear:= (xyear * D0) shr 2;
   JulianDN:= ((((month * 153) + 2) div 5)+day)+D2+xyear+Century;
end;

procedure JulianDNToGregorian(JulianDN: longint; var year,month,day: integer);
var temp,xyear: longint;
    yyear,ymonth,yday: integer;
begin
   temp:= (((JulianDN - D2) shl 2) - 1);
   xyear:= (temp mod D1) or 3;
   JulianDN:= temp div D1;
   yyear:= (xyear div D0);
   temp:= ((((xyear mod D0) + 4) shr 2) * 5) - 3;
   ymonth:= temp div 153;
   if ymonth>=10 then
   begin
      inc(yyear);
      dec(ymonth,12);
   end;
   inc(ymonth,3);
   yday:= temp mod 153;
   yday:= (yday + 5) div 5;
   year:= yyear + (JulianDN * 100);
   month:= ymonth;
   day:= yday;
end;

function z_toUnixDate(fdate: longint): string;
var dt: DateTime;
    secspast,datenum, dayspast: longint;
    s: string;
begin
   UnpackTime(fdate,dt);
   GregorianToJulianDN(dt.year,dt.month,dt.day,datenum);
   dayspast:= datenum - c1970;
   secspast:= dayspast * 86400;
   secspast:= secspast + dt.hour * 3600 + dt.min * 60 + dt.sec;
   s:='';
   while (secspast<>0) and (length(s)<255) do
   begin
      s:=Chr((secspast and 7) + $30) + s;
      secspast:=secspast shr 3;
   end;
   s:='0'+s;
   Z_ToUnixDate:=s;
end;

function z_fromUnixDate(s: string): longint;
var dt: DateTime;
    secspast, datenum: longint;
    n: word;
begin
   secspast:= longint(0);
   for n:= 1 to length(s) do secspast:= (secspast shl 3) + Ord(s[n]) - $30;
   datenum := (secspast div 86400) + c1970;
   JulianDNToGregorian(datenum,integer(dt.year),integer(dt.month),integer(dt.day));
   secspast:= secspast mod 86400;
   dt.hour:= secspast div 3600;
   secspast:= secspast mod 3600;
   dt.min:= secspast div 60;
   dt.sec:= secspast mod 60;
   PackTime(dt,secspast);
   Z_FromUnixDate := secspast
end;

function updateCRC(cp: byte; crc: word): word;
begin
   updateCRC := crctable[((crc shr 8) and 255)] xor (crc SHL 8) xor cp;
end;

function updateC32(octet: byte; crc: longint): longint;
begin
   updateC32:= c32table[byte(crc xor longint(octet))] xor ((crc shr 8) and $00FFFFFF);
end;

function RtoS(r: real; width, decimals: word): string;
var s: string;
begin
   {$I-}
   Str(r:width:decimals,s);
   {$I+}
   if ioresult<>0 then s:='' else while (Length(s)>0) and (s[1]=' ') do delete(s,1,1);
   RtoS:=s;
end;

procedure Z_OpenWindow;
var c: byte;
begin
   cursor(false);
   makebox(0,36,2,73,19,1);
   makebox(attr(white,black),52,3,72,18,5);
   c:=attr(lightcyan,black);
   fwrite('Mode',5,38,c);
   fwrite('Direction',6,38,c);
   fwrite('File name',7,38,c);
   fwrite('Total bytes',8,38,c);
   fwrite('Total blocks',9,38,c);
   fwrite('Xfer time',10,38,c);
   fwrite('Clock',11,38,c);
   fwrite('On byte #',12,38,c);
   fwrite('On block #',13,38,c);
   fwrite('# of Errors',14,38,c);
   fwrite('Last frame',15,38,c);
   fwrite('Message',16,38,c);
   fwrite('Progress bar',17,38,c);
   vertchars(attr(lightgray,black),50,5,17,'³');
   fwrite(chars('Û',20),17,52,attr(lightcyan,black));
   fwritena('0',14,52);
end;

procedure Z_ShowName(filename: string);
begin
   if Length(filename)>14 then filename[0]:=#14 else filename:=filename+blanks(14-length(filename));
   fwritena(filename+'',7,52);
end;

procedure Z_ShowSize(l: longint);
begin
   fwritena(Its(l)+'        ',8,52);
   if l mod 128<>0 then l:=(l div 128)+1 else l:=l div 128;
   fwritena(Its(l)+'        ',9,52);
end;

procedure Z_ShowCheck(is32: boolean);
begin
   if is32 then fwrite('Zmodem-CRC32',3,49,attr(blue,lightgray)) else
      fwrite('Zmodem-CRC16',3,49,attr(blue,lightgray));
end;

procedure Z_ShowTransferTime(fsize, zbaud: longint);
var bits: real;
begin
   bits:= fsize * 10.0;
   if zbaud=0 then zbaud:=1;
   if bits<>0.0 then fwritena(RtoS(((bits / zbaud) / 60),10,2)+' min.       ',10,52) else
      fwritena('0 min.            ',10,2);
end;

procedure Z_Message(s: string);
begin
   if Length(s)>20 then s[0]:=#20 else s:=s+blanks(20-length(s));
   fwritena(s+'',16,52);
end;

procedure Z_Frame(n: integer);
var s: string;
begin
   case n of
      -3 : s:='ZNOCARRIER';
      -2 : s:='ZTIMEOUT  ';
      -1 : s:='ZERROR    ';
      0  : s:='ZRQINIT   ';
      1  : s:='ZRINIT    ';
      2  : s:='ZSINIT    ';
      3  : s:='ZACK      ';
      4  : s:='ZFILE     ';
      5  : s:='ZSKIP     ';
      6  : s:='ZNAK      ';
      7  : s:='ZABORT    ';
      8  : s:='ZFIN      ';
      9  : s:='ZRPOS     ';
      10 : s:='ZDATA     ';
      11 : s:='ZEOF      ';
      12 : s:='ZFERR     ';
      13 : s:='ZCRC      ';
      14 : s:='ZCHALLENGE';
      15 : s:='ZCOMPL    ';
      16 : s:='ZCAN      ';
      17 : s:='ZFREECNT  ';
      18 : s:='ZCOMMAND  ';
      19 : s:='ZSTDERR   ';
      else s:='ZWHAT?    ';
   end;
   fwritena(s+'',15,52);
end;

procedure Z_ShowLoc(l,f: longint);
begin
   fwrite(chars('Û',trunc(l/f*20)),17,52,attr(blue,lightgray));
   fwritena(Its(l)+'           ',12,52);
   if l mod 128<>0 then l:=(l div 128)+1 else l:=l div 128;
   fwritena(Its(l)+'           ',13,52);
   fwritena(time(1),11,52);
end;

procedure Z_Errors(w: word);
begin
   fwritena(Its(w)+'    ',14,52);
end;

procedure Z_ClearInbound;
var hr,min,sec,lastsec,hund: word;
    ch: byte;
begin
   repeat
       gettime(hr,min,lastsec,hund);
       repeat
           gettime(hr,min,sec,hund);
       until (_rx_ready) or (sec<>lastsec);
       ch:=_get;
   until (not _rx_ready) or (keypressed);
end;

procedure Z_ClearOutbound;
begin
   _flush_tx;
end;

function Z_SetTimer: longint;
var h,m,s,x: word;
begin
   GetTime(h,m,s,x);
   Z_SetTimer:= h*3600+m*60+s;
end;

function Z_FileCRC32(var f: file): longint;
var fbuf: buftype;
    crc: longint;
    bread, n: integer;
begin {$I-}
   crc:= $FFFFFFFF;
   Seek(f,0);
   if ioresult=0 then;
   repeat
      BlockRead(f,fbuf,ZBUFSIZE,bread);
      for n:=0 to bread-1 do crc:=updateC32(fbuf[n],crc);
   until (bread<ZBUFSIZE) or (ioresult<>0);
   Seek(f,0);
   if ioresult=0 then;
   Z_FileCRC32:= crc;
end;  {$I+}

function Z_GetByte(howmany: integer): integer;
var ClockTick: word absolute $40:$6C;
    lasttick: word;
begin
   if _rx_ready then z_getbyte:=_get else
   begin
      lasttick:=clocktick;
      repeat
         if _rx_ready then
         begin
            Z_GetByte:= _get;
            exit;
         end;
         if not _cd then
         begin
            Z_GetByte:= RCDO;
            exit;
         end;
         if abs(clocktick-lasttick)>18 then
         begin
            lasttick:=clocktick;
            dec(howmany);
         end;
      until howmany<0;
      Z_GetByte:=ZTIMEOUT;
   end;
end;

function Z_TimedRead: integer;
(* A Z_qk_read, that strips parity and *)
(* ignores XON/XOFF characters.        *)
var c: integer;
begin
   c:= Z_GetByte(rxtimeout) and $FF7F;
   if (c<>XON) and (c<>XOFF) then z_timedread:=c else
   begin
      repeat
         c:= Z_GetByte(rxtimeout) and $FF7F;
      until (c<>XON) and (c<>XOFF);
      Z_TimedRead:=c;
   end;
end;

procedure Z_SendCan;
var n: byte;
begin
   Z_ClearOutbound;
   for n:=1 to 8 do
   begin
      _put(CAN);
      Delay(10);
   end;
   for n:=1 to 10 do _put(8);
end;

procedure Z_Putstring(var p: buftype);
(* Outputs an ASCII-Z type string (null terminated) *)
(* Processes meta characters 221 (send break) and   *)
(* 222 (2 second delay).                            *)
var n: integer;
begin
   for n:=0 to (ZBUFSIZE-1) do
   begin
      if p[n]=0 then exit else
      case p[n] of
         221: _sendbreak;
         222: delay(2000);
         else _put(p[n]);
      end;
   end;
end;

procedure Z_PutHex(b: byte);
(* Output a byte as two hex digits (in ASCII) *)
(* Uses lower case to avoid confusion with    *)
(* escaped control characters.                *)
const hex: array[0..15] of CHAR = '0123456789abcdef';
begin
   _put(Ord(hex[b shr 4]));  { high nybble }
   _put(Ord(hex[b and $0F])) { low nybble  }
end;

procedure Z_SendHexHeader(htype: byte; var hdr: hdrtype);
(* Sends a zmodem hex type header *)
var crc: word;
    n, i: integer;
begin
   _put(ZPAD);
   _put(ZPAD);
   _put(ZDLE);
   _put(ZHEX);
   Z_PutHex(htype);
   crc:= updateCRC(htype,0);
   for n:=0 to 3 do
   begin
      Z_PutHex(hdr[n]);
      crc:= updateCRC(hdr[n],crc)
   end;
   crc:= updateCRC(0,crc);
   crc:= updateCRC(0,crc);
   Z_PutHex(Lo(crc shr 8));
   Z_PutHex(Lo(crc));
   _put(13);
   _put(10);
   if (htype<>ZFIN) and (htype<>ZACK) then _put(XON);  { Prophylactic XON to assure flow   }
   if not _cd then Z_ClearOutbound
end;

function Z_PullLongFromHeader(var hdr: hdrtype): longint;
(* Stuffs a longint into a header variable - N.B. - bytes are REVERSED! *)
var l: longint;
begin
   l:= hdr[ZP3];
   l:= (l shl 8) or hdr[ZP2];
   l:= (l shl 8) or hdr[ZP1];
   l:= (l shl 8) or hdr[ZP0];
   Z_PullLongFromHeader:= l;
end;

procedure Z_PutLongIntoHeader(l: longint);
(* Reverse of above *)
begin
   txhdr[ZP0]:= byte(l);
   txhdr[ZP1]:= byte(l shr 8);
   txhdr[ZP2]:= byte(l shr 16);
   txhdr[ZP3]:= byte(l shr 24);
end;

function Z_GetZDL: integer;
(* Gets a byte and processes for ZMODEM escaping or CANcel sequence *)
var c, d: integer;
begin
   if not _cd then z_getzdl:=RCDO else
   begin
      c:= z_getbyte(rxtimeout);
      if c<>ZDLE then z_getzdl:=c else
      begin
         c:= Z_GetByte(rxtimeout);
         if c=CAN then
         begin
            c:= Z_GetByte(rxtimeout);
            if c=CAN then
            begin
               c:= Z_GetByte(rxtimeout);
               if c=CAN then c:=Z_GetByte(rxtimeout);
            end;
         end;

         { Flags set in high byte }
         case c of
             ZCRCE,
             ZCRCG,
             ZCRCQ,
             ZCRCW: Z_GetZDL:= c or GOTOR;
             ZRUB0: Z_GetZDL:= 127;
             ZRUB1: Z_GetZDL:= 255;
               CAN: Z_GetZDL:= GOTCAN;
               else begin
                       if c<0 then Z_GetZDL:=c else
                       if c and $60=$40 then Z_GetZDL:= c xor $40 else
                          Z_GetZDL:=ZERROR;
                    end;
         end;
      end;
   end;
end;

function Z_GetHex: integer;
(* Get a byte that has been received as two ASCII hex digits *)
var c, n: integer;
begin
   n:= Z_TimedRead;
   if n<0 then z_gethex:=n else
   begin
      n:=n-48;
      if n>9 then n:=n-39;
      if n and $FFF0<>0 then z_gethex:=ZERROR else
      begin
         c:= Z_TimedRead;
         if c<0 then z_gethex:=c else
         begin
            c:=c-$30;
            if c>9 then c:=c-39;
            if c and $FFF0<>0 then z_gethex:=ZERROR else
            Z_GetHex:=(n shl 4) or c;
         end;
      end;
   end;
end;

function Z_GetHexHeader(var hdr: hdrtype): integer;
(* Receives a zmodem hex type header *)
var crc: word;
    c,n: integer;
begin
   c:= Z_GetHex;
   if c<0 then z_gethexheader:=c else
   begin
      rxtype:= c;
      crc:= updateCRC(rxtype,0);
      for n:=0 to 3 do
      begin
         c:= Z_GetHex;
         if c<0 then
         begin
            Z_GetHexHeader:= c;
            exit;
         end;
         hdr[n]:=Lo(c);
         crc:=updateCRC(Lo(c),crc);
      end;
      c:=Z_GetHex;
      if c<0 then z_gethexheader:=c else
      begin
         crc:= updateCRC(Lo(c),crc);
         c:= Z_GetHex;
         if c<0 then z_gethexheader:=c else
         begin
            crc:= updateCRC(Lo(c),crc);
            if crc<>0 then
            begin
               inc(zerrors);
               Z_Errors(zerrors);
               Z_GetHexHeader:= ZERROR;
            end else
            begin
               if Z_GetByte(2)=13 then c:=Z_GetByte(2);
               Z_GetHexHeader:= rxtype;
            end;
         end;
      end;
   end;
end;

function Z_GetBinaryHeader(var hdr: hdrtype): integer;
(* Same as above, but binary with 16 bit CRC *)
var crc: word;
    c,n: integer;
begin
   c := Z_GetZDL;
   if c<0 then z_getbinaryheader:=c else
   begin
      rxtype:=c;
      crc:= updateCRC(rxtype,0);
      for n:=0 to 3 do
      begin
         c:= Z_GetZDL;
         if Hi(c)<>0 then
         begin
            Z_GetBinaryHeader:= c;
            exit;
         end;
         hdr[n]:= Lo(c);
         crc:=updateCRC(Lo(c),crc);
      end;
      c:= Z_GetZDL;
      if Hi(c)<>0 then z_getbinaryheader:=c else
      begin
         crc:= updateCRC(Lo(c),crc);
         c:= Z_GetZDL;
         if Hi(c)<>0 then z_getbinaryheader:=c else
         begin
            crc:= updateCRC(Lo(c),crc);
            if crc<>0 then
            begin
               inc(zerrors);
               Z_Errors(zerrors);
            end else z_getbinaryheader:= rxtype;
         end;
      end;
   end;
end;

function Z_GetBinaryHead32(var hdr: hdrtype): integer;
(* Same as above but with 32 bit CRC *)
var crc: longint;
    c,n: integer;
begin
   c:= Z_GetZDL;
   if c<0 then z_getbinaryhead32:=c else
   begin
      rxtype:= c;
      crc:= updateC32(rxtype,$FFFFFFFF);
      for n:= 0 to 3 do
      begin
         c:= Z_GetZDL;
         if Hi(c)<>0 then
         begin
            Z_GetBinaryHead32:= c;
            exit;
         end;
         hdr[n]:= Lo(c);
         crc:= updateC32(Lo(c),crc);
      end;
      for n:= 0 to 3 do
      begin
         c:= Z_GetZDL;
         if Hi(c)<>0 then
         begin
            Z_GetBinaryHead32:= c;
            exit;
         end;
         crc:= updateC32(Lo(c),crc)
      end;
      if crc<>$DEBB20E3 then
      begin
         inc(zerrors);
         Z_Errors(zerrors);
         Z_GetBinaryHead32:= ZERROR;
      end else Z_GetBinaryHead32:= rxtype;
   end;
end;

function Z_GetHeader(var hdr: hdrtype): integer;
(* Use this routine to get a header - it will figure out  *)
(* what type it is getting (hex, bin16 or bin32) and call *)
(* the appropriate routine.                               *)
label gotcan, again, agn2, splat, done;
var c, cancount: integer;
    n: longint;
begin
   n:= zbaud * 2;                    {A guess at the # of garbage characters}
   cancount:= 5;                     {to expect.                            }
   usecrc32:= false;                 {assume 16 bit until proven otherwise  }
again:
   if KeyPressed then
      if ReadKey=#27 then
      begin
         Z_SendCan;
         Z_message('User aborted');
         Z_GetHeader:=ZCAN;
         exit;
      end;
   rxframeind:= 0;
   rxtype:= 0;
   c:= Z_TimedRead;
   case c of
          ZPAD: ;
          RCDO,
      ZTIMEOUT: goto done;
           CAN: begin
gotcan:            dec(cancount);
                   if cancount<0 then
                   begin
                      c:= ZCAN;
                      goto done;
                   end;
                   c:= Z_GetByte(2);
                   case c of
                       ZTIMEOUT: goto again;
                          ZCRCW: begin
                                    c:= ZERROR;
                                    goto done;
                                 end;
                           RCDO: goto done;
                            CAN: begin
                                    dec(cancount);
                                    if cancount<0 then
                                    begin
                                       c:= ZCAN;
                                       goto done;
                                    end;
                                    goto again;
                                 end;
                            else ;
                   end;
                end;
           else begin
agn2:              dec(n);
                   if n<1 then
                   begin
                      inc(zerrors);
                      Z_Errors(zerrors);
                      Z_message('FUBAR header');
                      Z_GetHeader:=ZERROR;
                      exit;
                   end;
                   if c<>CAN then cancount:=5;
                   goto again;
                end;
   end;
   cancount:=5;

splat:
   c := Z_TimedRead;
   case c of
          ZDLE: ;
          ZPAD: goto splat;
          RCDO,
      ZTIMEOUT: goto done;
           else goto agn2
   end;
   c:= Z_TimedRead;
   case c of
        ZBIN32: begin
                   rxframeind:= ZBIN32;
                   c:= Z_GetBinaryHead32(hdr);
                end;
          ZBIN: begin
                   rxframeind:= ZBIN;
                   c:= Z_GetBinaryHeader(hdr);
                end;
          ZHEX: begin
                   rxframeind:= ZHEX;
                   c:= Z_GetHexHeader(hdr);
                end;
           CAN: goto gotcan;
          RCDO,
      ZTIMEOUT: goto done;
           else goto agn2;
   end;
   rxpos:= Z_PullLongFromHeader(hdr);
done:
   Z_GetHeader:=c;
end;

(***************************************************)
(* RECEIVE file ROUTINES                           *)
(***************************************************)

const ZATTNLEN = 32;
      lastwritten: byte = 0;
var t: longint;
    rzbatch: boolean;
    outfile: file;
    tryzhdrtype: byte;
    rxcount: integer;
    filestart: longint;
    isbinary, eofseen: boolean;
    zconv: byte;
    zrxpath: string;

function RZ_ReceiveDa32(var buf: buftype; blength: integer): integer;
label crcfoo;
var c, n: integer;
    crc: longint;
    loop: word;
begin
   usecrc32:=true;
   crc:=$FFFFFFFF;
   rxcount:=0;
   for loop:=0 to 65535 do
   begin
      c:= Z_GetZDL;
      if hi(c)=0 then
      begin
         dec(blength);
         if blength<0 then
         begin
            Z_message('Long packet');
            RZ_ReceiveDa32:=ZERROR;
            exit;
         end;
         buf[rxcount]:=Lo(c);
         inc(rxcount);
         crc:= updateC32(Lo(c),crc)
      end else
      begin
crcfoo:  case c of
            GOTCRCE,
            GOTCRCG,
            GOTCRCQ,
            GOTCRCW: begin
                        rz_receiveda32:=c;
                        crc:= updateC32(Lo(c),crc);
                        for n:=0 to 3 do
                        begin
                           c:= Z_GetZDL;
                           if hi(c)=0 then crc:= updateC32(Lo(c),crc) else goto crcfoo;
                        end;
                        if crc<>$DEBB20E3 then
                        begin
                           inc(zerrors);
                           Z_Errors(zerrors);
                           RZ_ReceiveDa32:=ZERROR;
                        end;
                     end;
             GOTCAN: RZ_ReceiveDa32:= ZCAN;
           ZTIMEOUT: RZ_ReceiveDa32:= c;
               RCDO: RZ_ReceiveDa32:= c;
                else begin
                        Z_message('Junk');
                        Z_ClearInbound;
                        RZ_ReceiveDa32:= c;
                     end;
         end;
         exit;
      end;
   end;
end;

function RZ_ReceiveData(var buf: buftype; blength: integer): integer;
(* get a 16 bit CRC data block *)
label crcfoo;
var c: integer;
    crc,loop: word;
begin
   if rxframeind=ZBIN32 then
   begin
      Z_ShowCheck(true);
      RZ_ReceiveData:=RZ_ReceiveDa32(buf,blength);
   end else
   begin
      Z_ShowCheck(false);
      crc:=0;
      rxcount:=0;
      for loop:=0 to 65535 do
      begin
         c:= Z_GetZDL;
         if hi(c)=0 then
         begin
            dec(blength);
            if blength<0 then
            begin
               Z_message('Long packet');
               RZ_ReceiveData:= ZERROR;
               exit;
            end;
            buf[rxcount]:= Lo(c);
            inc(rxcount);
            crc:= updateCRC(Lo(c),crc);
         end else
         begin
crcfoo:     case c of
               GOTCRCE,
               GOTCRCG,
               GOTCRCQ,
               GOTCRCW: begin
                           rz_receivedata:=c;
                           crc:= updateCRC(Lo(c),crc);
                           c:= Z_GetZDL;
                           if Hi(c)<>0 then goto crcfoo;
                           crc:= updateCRC(Lo(c),crc);
                           c:= Z_GetZDL;
                           if Hi(c)<>0 then goto crcfoo;
                           crc:= updateCRC(Lo(c),crc);
                           if crc<>0 then
                           begin
                              inc(zerrors);
                              Z_Errors(zerrors);
                              RZ_ReceiveData:=ZERROR;
                           end;
                        end;
                GOTCAN: begin
                           Z_Message('Cancel received');
                           RZ_ReceiveData:=ZCAN;
                        end;
              ZTIMEOUT: RZ_ReceiveData:=c;
                  RCDO: begin
                           Z_Message('Lost carrier');
                           RZ_ReceiveData:=c;
                        end;
                   else begin
                           Z_message('Junk');
                           Z_ClearInbound;
                           RZ_ReceiveData:=c;
                        end;
            end;
            exit;
         end;
      end;
   end;
end;

procedure rz_ackbye;
(* ACKnowledge the other ends request to terminate cleanly *)
var loop: byte;
begin
   Z_PutLongIntoHeader(rxpos);
   Z_ClearInbound;
   for loop:=4 downto 0 do
   begin
      Z_SendHexHeader(ZFIN,txhdr);
      case Z_GetByte(10) of
         ZTIMEOUT,
             RCDO: exit;
               79: begin
                      if Z_GetByte(10)=79 then;
                      Z_ClearInbound;
                      exit;
                   end;
              else Z_ClearInbound;
      end;
   end;
end;

function RZ_InitReceiver: integer;
label again;
var c,n,errors: integer;
begin
   FillChar(attn^,SizeOf(attn^),0);
   zerrors:= 0;
   for n:=10 downto 0 do
   begin
      if not _cd then
      begin
         Z_Message('Lost carrier');
         RZ_InitReceiver:= ZERROR;
         exit;
      end;
      Z_PutLongIntoHeader(0);
      txhdr[ZF0]:= CANFDX or CANOVIO or CANFC32 or CANBRK;
      Z_SendHexHeader(tryzhdrtype,txhdr);
      if tryzhdrtype=ZSKIP then tryzhdrtype:=ZRINIT;
again:
      c:= Z_GetHeader(rxhdr);
      Z_Frame(c);
      case c of
            ZFILE: begin
                      zconv:= rxhdr[ZF0];
                      tryzhdrtype:= ZRINIT;
                      c:= RZ_ReceiveData(secbuf^,ZBUFSIZE);
                      Z_Frame(c);
                      if c=GOTCRCW then
                      begin
                         RZ_InitReceiver:= ZFILE;
                         exit;
                      end;
                      Z_SendHexHeader(ZNAK,txhdr);
                      goto again;
                   end;
           ZSINIT: begin
                      c:= RZ_ReceiveData(attn^,ZBUFSIZE);
                      Z_Frame(c);
                      if c=GOTCRCW then Z_SendHexHeader(ZACK,txhdr)
                         else Z_SendHexHeader(ZNAK,txhdr);
                      goto again;
                   end;
         ZFREECNT: begin
                      Z_PutLongIntoHeader(DiskFree(0));
                      Z_SendHexHeader(ZACK,txhdr);
                      goto again;
                   end;
         ZCOMMAND: begin
                      c:= RZ_ReceiveData(secbuf^,ZBUFSIZE);
                      Z_Frame(c);
                      if c=GOTCRCW then
                      begin
                         Z_PutLongIntoHeader(0);
                         repeat
                            Z_SendHexHeader(ZCOMPL,txhdr);
                            inc(errors)
                         until (errors>10) or (Z_GetHeader(rxhdr)=ZFIN);
                         rz_ackbye;
                         RZ_InitReceiver:= ZCOMPL;
                         exit;
                      end;
                      Z_SendHexHeader(ZNAK,txhdr);
                      goto again;
                   end;
             ZFIN,
           ZCOMPL: begin
                      RZ_InitReceiver:= ZCOMPL;
                      exit;
                   end;
            ZCAN,
            RCDO: begin
                     RZ_InitReceiver:= c;
                     exit;
                  end;
      end;
   end;
   Z_message('Timeout');
   RZ_InitReceiver:=ZERROR;
end;

function RZ_GetHeader: integer;
var e, p, n, i: integer;
    multiplier,
    ttime, tsize: longint;
    tname,s: string;
begin
   isbinary:= true;
   fsize:=0;
   p:= 0;
   s:='';
   while (p<255) and (secbuf^[p]<>0) do
   begin
      s:=s+UpCase(Chr(secbuf^[p]));
      inc(p);
   end;
   inc(p);
   while Pos(':',s)>0 do Delete(s,1,Pos(':',s));
   while Pos('\',s)>0 do Delete(s,1,Pos('\',s));
   fname:= s;

   fsize:=0;
   while (p<ZBUFSIZE) and (secbuf^[p]<>$20) and (secbuf^[p]<>0) do
   begin
      fsize:=(fsize *10) + Ord(secbuf^[p]) - $30;
      inc(p);
   end;
   inc(p);

   s:='';
   while (p<ZBUFSIZE) and (secbuf^[p]>=$30) and (secbuf^[p]<=$37) do
   begin
      s:=s+Chr(secbuf^[p]);
      inc(p);
   end;
   inc(p);
   ftime:=Z_FromUnixDate(s);

   if Z_FindFile(zrxpath+fname,tname,tsize,ttime) then
   begin
      if (zconv=ZCRESUM) and (fsize>tsize) then
      begin
         filestart:=tsize;
         if not Z_OpenFile(outfile,zrxpath + fname) then
         begin
            Z_message('Problem opening '+fname);
            RZ_GetHeader:= ZERROR;
            exit;
         end;
         if not Z_SeekFile(outfile,tsize) then
         begin
            Z_Message('Problem positioning file');
            RZ_GetHeader:=ZERROR;
            exit;
         end;
         Z_Message('Recovering')
      end else
      begin
         Z_ShowName(fname);
         Z_Message('File completed');
         RZ_GetHeader:=ZSKIP;
         exit;
      end;
   end else
   begin
      filestart:= 0;
      if not Z_MakeFile(outfile,zrxpath+fname) then
      begin
         Z_message('Problem creating '+fname);
         RZ_GetHeader:= ZERROR;
         exit;
      end;
   end;
   Z_ShowName(fname);
   Z_ShowSize(fsize);
   Z_ShowTransferTime(fsize,zbaud);
   RZ_GetHeader:= ZOK;
end;

function RZ_SaveToDisk(var rxbytes: longint): integer;
begin
   if KeyPressed then
      if ReadKey=#27 then
      begin
         Z_message('User aborted');
         Z_SendCan;
         RZ_SaveToDisk:= ZERROR;
         exit;
      end;
   if not Z_WriteFile(outfile,secbuf^,rxcount) then
   begin
      Z_Message('Disk write problem');
      RZ_SaveToDisk:= ZERROR;
   end else RZ_SaveToDisk:=ZOK;
   rxbytes:= rxbytes+rxcount;
end;

function RZ_ReceiveFile: integer;
label err, nxthdr,moredata;
var c,n: integer;
    loop: word;
    rxbytes: longint;
    sptr: string;
begin
   zerrors:=0;
   eofseen:= false;
   c:=RZ_GetHeader;
   if c<>ZOK then
   begin
      if c=ZSKIP then tryzhdrtype:=ZSKIP;
      RZ_ReceiveFile:=c;
      exit;
   end;
   c:=ZOK;
   n:=10;
   rxbytes:= filestart;
   rxpos:= filestart;
   ztime:= Z_SetTimer-1;
   zcps:= 0;
   for loop:=0 to 65535 do
   begin
      Z_PutLongIntoHeader(rxbytes);
      Z_SendHexHeader(ZRPOS,txhdr);
nxthdr:
      c:=Z_GetHeader(rxhdr);

      Z_Frame(c);
      case c of
         ZDATA: begin
                   if rxpos=rxbytes then
                   begin
moredata:             c:= RZ_ReceiveData(secbuf^,ZBUFSIZE);
                      Z_Frame(c);
                      case c of
                                ZCAN,
                                RCDO: goto err;
                              ZERROR: begin
                                         dec(n);
                                         inc(zerrors);
                                         Z_Errors(zerrors);
                                         if n<0 then goto err;
                                         Z_Putstring(attn^);
                                       end;
                             ZTIMEOUT: begin
                                          dec(n);
                                          if n<0 then goto err;
                                       end;
                              GOTCRCW: begin
                                          n:= 10;
                                          c:= RZ_SaveToDisk(rxbytes);
                                          if c<>ZOK then
                                          begin
                                             RZ_ReceiveFile:= c;
                                             exit;
                                          end;
                                          Z_ShowLoc(rxbytes,fsize);
                                          Z_PutLongIntoHeader(rxbytes);
                                          Z_SendHexHeader(ZACK,txhdr);
                                          goto nxthdr;
                                      end;
                              GOTCRCQ: begin
                                          n:=10;
                                          c:= RZ_SaveToDisk(rxbytes);
                                          if c<>ZOK then
                                          begin
                                             RZ_ReceiveFile:= c;
                                             exit;
                                          end;
                                          Z_ShowLoc(rxbytes,fsize);
                                          Z_PutLongIntoHeader(rxbytes);
                                          Z_SendHexHeader(ZACK,txhdr);
                                          goto moredata;
                                       end;
                              GOTCRCG: begin
                                          n:= 10;
                                          c:= RZ_SaveToDisk(rxbytes);
                                          if c<>ZOK then
                                          begin
                                             RZ_ReceiveFile:= c;
                                             exit;
                                          end;
                                          Z_ShowLoc(rxbytes,fsize);
                                          goto moredata;
                                       end;
                              GOTCRCE: begin
                                          n:= 10;
                                          c:= RZ_SaveToDisk(rxbytes);
                                          if c<>ZOK then
                                          begin
                                             RZ_ReceiveFile:= c;
                                             exit;
                                          end;
                                          Z_ShowLoc(rxbytes,fsize);
                                          goto nxthdr;
                                       end;
                      end;
                   end else
                   begin
                      dec(n);
                      inc(zerrors);
                      Z_Errors(zerrors);
                      if n<0 then goto err;
                      Z_message('Bad position');
                      Z_Putstring(attn^);
                   end;
                end;
          ZNAK,
      ZTIMEOUT: begin
                   dec(n);
                   if n<0 then goto err;
                   Z_ShowLoc(rxbytes,fsize);
                end;
         ZFILE: begin
                   c:= RZ_ReceiveData(secbuf^,ZBUFSIZE);
                   Z_Frame(c);
                end;
         ZEOF: if rxpos=rxbytes then
               begin
                  if leechmode='B' then Z_SendHexHeader(ZSKIP,txhdr) else
                  if leechmode='S' then z_sendcan;
                  RZ_ReceiveFile:= c;
                  exit;
               end else goto nxthdr;
       ZERROR: begin
                  dec(n);
                  if n<0 then goto err;
                  Z_ShowLoc(rxbytes,fsize);
                  Z_Putstring(attn^)
               end;
          else goto err;
      end;
   end;
err:
   RZ_ReceiveFile:= ZERROR;
end;

function RZ_ReceiveBatch: integer;
var s: string;
    c: integer;
begin
   Z_Message('Now receiving');
   repeat
      if not _cd then
      begin
         RZ_ReceiveBatch:= ZERROR;
         exit;
      end;
      fwrite(chars('Û',20),17,52,attr(lightcyan,lightgray));
      c:= RZ_ReceiveFile;
      zcps:= fsize div (Z_SetTimer - ztime);
      Z_Frame(c);
      Z_SetFTime(outfile,ftime);
      Z_CloseFile(outfile);
      Str(zcps:0,s);
      Z_Message(s+' cps');
      case c of
          ZEOF,
         ZSKIP: begin
                   c:= RZ_InitReceiver;
                   Z_Frame(c);
                   case c of
                       ZFILE: ;
                      ZCOMPL: begin
                                 rz_ackbye;
                                 RZ_ReceiveBatch:= ZOK;
                                 exit;
                              end;
                         else begin
                                 RZ_ReceiveBatch:= ZERROR;
                                 exit;
                              end;
                   end;
                end;
           else begin
                   RZ_ReceiveBatch:= c;
                   exit;
                end;
      end;
   until 0=1;
end;

function Zmodem_Receive;
var i: integer;
begin
   new(secbuf);
   new(attn);
   Z_OpenWindow;
   leechmode:=leechit;
   if leechit='B' then fwrite('Leech batch',5,52,attr(lightred,black)) else
   if leechit='S' then fwrite('Leech single',5,52,attr(lightred,black)) else
      fwrite('Normal',5,52,attr(lightred,black));
   fwrite('Receive mode',6,52,attr(lightred,black));
   Z_Message('Starting up');
   zrxpath:= path;
   if (zrxpath[Length(zrxpath)]<>'\') and (zrxpath<>'') then zrxpath:=zrxpath+'\';
   rxtimeout:=10;
   tryzhdrtype:= ZRINIT;
   i:= RZ_InitReceiver;
   if (i=ZCOMPL) or ((i= ZFILE) and (RZ_ReceiveBatch=ZOK)) then
   begin
      Z_Message('Successful');
      cursor(true);
      Zmodem_Receive:=true;
   end else
   begin
      Z_ClearOutbound;
      Z_Message('Signaling CANcel');
      Z_SendCan;
      Z_Message('Unsuccessful');
      cursor(true);
      Zmodem_Receive:= false;
   end;
   dispose(attn);
   dispose(secbuf);
end;

(*######### Send ROUTINES #####################################*)
var infile: file;
    strtpos: longint;
    rxbuflen,
    blkred: integer;
    txbuf: ^buftype;

procedure SZ_Z_SendByte(b: byte);
begin
   if ((b and $7F) in [16,17,19,24]) or (((b and $7F)=13) and ((lastsent and $7F)=64)) then
   begin
      _put(ZDLE);
      lastsent:=b XOR 64;
   end else lastsent:=b;
   _put(lastsent);
end;

procedure SZ_SendBinaryHead32(htype: byte; var hdr: hdrtype);
var crc: longint;
    n: integer;
begin
   _put(ZPAD);
   _put(ZDLE);
   _put(ZBIN32);
   SZ_Z_SendByte(htype);
   crc:= updateC32(htype,$FFFFFFFF);
   for n:=0 to 3 do
   begin
      SZ_Z_SendByte(hdr[n]);
      crc:= updateC32(hdr[n],crc);
   end;
   crc:=not crc;
   for n:=0 to 3 do
   begin
      SZ_Z_SendByte(byte(crc));
      crc:=crc shr 8;
   end;
   if htype<>ZDATA then Delay(500);
end;

procedure SZ_SendBinaryHeader(htype: byte; var hdr: hdrtype);
var crc: word;
    n: integer;
begin
   if usecrc32 then
   begin
      SZ_SendBinaryHead32(htype,hdr);
      exit;
   end;
   _put(ZPAD);
   _put(ZDLE);
   _put(ZBIN);
   SZ_Z_SendByte(htype);
   crc:= updateCRC(htype,0);
   for n:=0 to 3 do
   begin
      SZ_Z_SendByte(hdr[n]);
      crc:= updateCRC(hdr[n],crc);
   end;
   crc:= updateCRC(0,crc);
   crc:= updateCRC(0,crc);
   SZ_Z_SendByte(Lo(crc shr 8));
   SZ_Z_SendByte(Lo(crc));
   if htype<>ZDATA then Delay(500);
end;

procedure SZ_SendDa32(var buf: buftype; blength: integer; frameend: byte);
var crc: longint;
    t: integer;
begin
   crc:= $FFFFFFFF;
   for t:=0 to blength-1 do
   begin
      SZ_Z_SendByte(buf[t]);
      crc:= updateC32(buf[t],crc)
   end;
   crc:= updateC32(frameend,crc);
   crc:=not crc;
   _put(ZDLE);
   _put(frameend);
   for t:=0 to 3 do
   begin
      SZ_Z_SendByte(byte(crc));
      crc:=crc shr 8;
   end;
   _put(XON);
   Delay(500);
end;

procedure SZ_SendData(var buf: buftype; blength: integer; frameend: byte);
var crc: word;
    t: integer;
begin
   if usecrc32 then SZ_SendDa32(buf,blength,frameend) else
   begin
      crc:= 0;
      for t:=0 to blength-1 do
      begin
         SZ_Z_SendByte(buf[t]);
         crc:= updateCRC(buf[t],crc);
      end;
      crc:= updateCRC(frameend,crc);
      _put(ZDLE);
      _put(frameend);
      crc:= updateCRC(0,crc);
      crc:= updateCRC(0,crc);
      SZ_Z_SendByte(Lo(crc shr 8));
      SZ_Z_SendByte(Lo(crc));
      if frameend=ZCRCW then
      begin
         _put(XON);
         Delay(500);
      end;
   end;
end;

procedure SZ_endSend;
begin
   repeat
      Z_PutLongIntoHeader(txpos);
      SZ_SendBinaryHeader(ZFIN,txhdr);
      case Z_GetHeader(rxhdr) of
            ZFIN: begin
                     _put(Ord('O'));
                     _put(Ord('O'));
                     Delay(500);
                     Z_ClearOutbound;
                     exit;
                  end;
             ZCAN,
             RCDO,
            ZFERR,
         ZTIMEOUT: exit;
      end;
   until 0=1;
end;

function SZ_GetReceiverInfo: integer;
var n,c: integer;
begin
   Z_Message('Retrieving status');
   for n:=1 to 20 do
   begin
      c:= Z_GetHeader(rxhdr);
      Z_Frame(c);
      case c of
         ZCHALLENGE: begin
                        Z_PutLongIntoHeader(rxpos);
                        Z_SendHexHeader(ZACK,txhdr)
                     end;
           ZCOMMAND: begin
                        Z_PutLongIntoHeader(0);
                        Z_SendHexHeader(ZRQINIT,txhdr)
                     end;
             ZRINIT: begin
                        rxbuflen:= (word(rxhdr[ZP1]) shl 8) or rxhdr[ZP0];
                        usecrc32:= (rxhdr[ZF0] and CANFC32)<> 0;
                        Z_ShowCheck(usecrc32);
                        SZ_GetReceiverInfo:= ZOK;
                        exit;
                     end;
               ZCAN,
               RCDO,
           ZTIMEOUT: begin
                        SZ_GetReceiverInfo:= ZERROR;
                        exit;
                     end;
                else if (c<>ZRQINIT) or (rxhdr[ZF0]<>ZCOMMAND) then Z_SendHexHeader(ZNAK,txhdr)
      end;
   end;
   SZ_GetReceiverInfo:= ZERROR;
end;

function SZ_SyncWithReceiver: integer;
var c,num_errs: integer;
    loop: word;
begin
   num_errs:= 7;
   for loop:=0 to 65535 do
   begin
      c:= Z_GetHeader(rxhdr);
      Z_Frame(c);
      Z_ClearInbound;
      case c of
         ZTIMEOUT: begin
                      dec(num_errs);
                      if num_errs<0 then
                      begin
                         SZ_SyncWithReceiver:= ZERROR;
                         exit;
                      end;
                   end;
             ZCAN,
           ZABORT,
             ZFIN,
             RCDO: begin
                      SZ_SyncWithReceiver:= ZERROR;
                      exit;
                   end;
            ZRPOS: begin
                      if not Z_SeekFile(infile,rxpos) then
                      begin
                         Z_Message('File seek problem');
                         SZ_SyncWithReceiver:= ZERROR;
                         exit;
                      end;
                      Z_Message('Repositioning');
                      Z_ShowLoc(rxpos,fsize);
                      txpos:= rxpos;
                      SZ_SyncWithReceiver:= c;
                      exit;
                   end;
            ZSKIP,
           ZRINIT,
             ZACK: begin
                      SZ_SyncWithReceiver:= c;
                      exit;
                   end;
              else begin
                      Z_Message('Only God knows');
                      SZ_SendBinaryHeader(ZNAK,txhdr)
                   end;
      end;
   end;
end;

function SZ_SendFileData: integer;
label waitack,somemore;
var c,e: integer;
    newcnt, blklen, blkred,
    maxblklen, goodblks, goodneeded: word;
begin
   Z_Message('Now Sending');
   goodneeded:= 1;
   if zbaud<300 then maxblklen:=128 else maxblklen:=(word(zbaud) div 300)*256;
   if maxblklen>ZBUFSIZE then maxblklen:= ZBUFSIZE;
   if (rxbuflen>0) and (rxbuflen<maxblklen) then maxblklen:= rxbuflen;
   blklen:= maxblklen;
   ztime:= Z_SetTimer-1;
somemore:
   if _rx_ready then
   begin
WaitAck:
      c:= SZ_SyncWithReceiver;
      Z_Frame(c);
      case c of
         ZSKIP: begin
                   SZ_SendFileData:= ZSKIP;
                   exit;
                end;
          ZACK: ;
         ZRPOS: begin
                   inc(zerrors);
                   Z_Errors(zerrors);
                   if (blklen shr 2)>32 then blklen:=blklen shr 2 else blklen:=32;
                   goodblks:= 0;
                   goodneeded:=(goodneeded shl 1) or 1;
                end;
        ZRINIT: begin
                    SZ_SendFileData:= ZOK;
                    exit;
                end;
           else begin
                   SZ_SendFileData:=ZERROR;
                   exit;
                end;
      end;
      while _rx_ready do
      begin
         case Z_GetByte(2) of
             CAN,
            ZPAD: goto waitack;
            RCDO: begin
                     SZ_SendFileData:= ZERROR;
                     exit;
                  end;
         end;
      end;
   end;
   newcnt:=rxbuflen;
   Z_PutLongIntoHeader(txpos);
   SZ_SendBinaryHeader(ZDATA,txhdr);
   Z_Message('Sending data header');
   repeat
      if KeyPressed then
         if ReadKey=#27 then
         begin
            Z_Message('User aborted');
            Z_SendCan;
            SZ_SendFileData:= ZERROR;
            exit;
         end;
      if not _cd then
      begin
         SZ_SendFileData:=ZERROR;
         exit;
      end;
      if not Z_ReadFile(infile,txbuf^,blklen,blkred) then
      begin
         Z_Message('Problem reading disk');
         Z_SendCan;
         SZ_SendFileData:=ZERROR;
         exit;
      end;
      if blkred<blklen then e:= ZCRCE else
      if (rxbuflen<>0) and (newcnt-blkred<=0) then
      begin
         newcnt:=newcnt-blkred;
         e:=ZCRCW;
      end else e:=ZCRCG;
      SZ_SendData(txbuf^,blkred,e);
      txpos:=txpos+blkred;
      Z_ShowLoc(txpos,fsize);
      inc(goodblks);
      if (blklen<maxblklen) and (goodblks>goodneeded) then
      begin
         if blklen shl 1<maxblklen then blklen:=blklen shl 1 else blklen:=maxblklen;
         goodblks:= 0;
      end;
      if e=ZCRCW then goto waitack;
      while _rx_ready do
      case Z_GetByte(2) of
             CAN,
            ZPAD: begin
                     Z_Message('Problem somewhere');
                     Z_ClearOutbound;
                     SZ_SendData(txbuf^,0,ZCRCE);
                     goto waitack;
                  end;
            RCDO: begin
                     SZ_SendFileData:=ZERROR;
                     exit;
                  end;
      end;
   until e<>ZCRCG;
   repeat
      Z_PutLongIntoHeader(txpos);
      Z_Message('Signaling EOF');
      SZ_SendBinaryHeader(ZEOF,txhdr);
      c:=SZ_SyncWithReceiver;
      case c of
           ZACK: ;
          ZRPOS: goto somemore;
         ZRINIT: begin
                    SZ_SendFileData:= ZOK;
                    exit;
                 end;
         ZSKIP: begin
                   SZ_SendFileData:= c;
                   exit;
                end;
           else begin
                   SZ_SendFileData:= ZERROR;
                   exit;
                end;
      end;
   until c<>ZACK;
end;

function SZ_SendFile: integer;
var c: integer;
begin
   zerrors:= word(0);
   fwrite(chars('Û',20),17,52,attr(lightcyan,lightgray));
   repeat
      if KeyPressed then
         if ReadKey=#27 then
         begin
            Z_SendCan;
            Z_Message('User aborted');
            SZ_SendFile:= ZERROR;
            exit;
         end;
      if not _cd then
      begin
         Z_Message('Lost carrier');
         SZ_SendFile:= ZERROR;
         exit;
      end;
      FillChar(txhdr,4,0);
      txhdr[ZF0]:= ZCRESUM;
      SZ_SendBinaryHeader(ZFILE,txhdr);
      SZ_SendData(txbuf^,ZBUFSIZE,ZCRCW);
      repeat
         c := Z_GetHeader(rxhdr);
         Z_Frame(c);
         case c of
              ZCAN,
              RCDO,
          ZTIMEOUT,
              ZFIN,
            ZABORT: begin
                       SZ_SendFile:= ZERROR;
                       exit;
                    end;
            ZRINIT: ;
              ZCRC: begin
                       Z_PutLongIntoHeader(Z_FileCRC32(infile));
                       Z_SendHexHeader(ZCRC,txhdr)
                    end;
             ZSKIP: begin
                       SZ_SendFile:= c;
                       exit;
                    end;
             ZRPOS: begin
                       if not Z_SeekFile(infile,rxpos) then
                       begin
                          Z_Message('File positioning problem');
                          Z_SendHexHeader(ZFERR,txhdr);
                          SZ_SendFile:= ZERROR;
                          exit;
                       end;
                       Z_Message('Placing start position');
                       Z_ShowLoc(rxpos,fsize);
                       strtpos:= rxpos;
                       txpos:= rxpos;
                       SZ_SendFile:= SZ_SendFileData;
                       exit;
                    end;
         end;
      until c<>ZRINIT;
   until 0=1;
end;

function Zmodem_Send(pathname: string; lastfile: boolean): boolean;
var s: string;
    n: integer;
begin
   zerrors:= 0;
   Z_OpenWindow;
   fwrite('Normal',5,52,attr(lightred,black));
   fwrite('Send mode',6,52,attr(lightred,black));
   zmodem_send:=false;
   if not _cd then
   begin
      Z_Message('Lost carrier');
      Delay(2000);
   end else
   begin
      if not Z_FindFile(pathname,fname,fsize,ftime) then
      begin
         Z_Message('Problem opening file');
         SZ_endSend;
      end else
      begin
         Z_ShowName(fname);
         Z_ShowSize(fsize);
         Z_ShowTransferTime(fsize,zbaud);
         str(fsize,s);
         s:=fname+#0+s+' '+Z_ToUnixDate(ftime);
         for n:=1 to Length(s) do if s[n] in ['A'..'Z'] then s[n]:=Chr(Ord(s[n])+$20);
         fillChar(txbuf^,ZBUFSIZE,0);
         move(s[1],txbuf^[0],Length(s));
         rxtimeout:=10;
         attn^[0]:= Ord('r');
         attn^[1]:= Ord('z');
         attn^[3]:= 13;
         attn^[4]:= 0;
         Z_Putstring(attn^);
         FillChar(attn^,SizeOf(attn^),0);
         Z_PutLongIntoHeader(0);
         Z_Message('Signaling ZRQINIT');
         Z_SendHexHeader(ZRQINIT,txhdr);
         if SZ_GetReceiverInfo<>ZERROR then
         begin
            if not Z_OpenFile(infile,pathname) then
            begin
               Z_Message('Problem opening file');
               Z_SendCan;
            end else
            begin
               n:= SZ_SendFile;
               zcps:= fsize div (Z_SetTimer - ztime);
               Z_CloseFile(infile);
               Z_Frame(n);
               str(zcps:0,s);
               Z_Message(s+' cps');
               if (n=ZOK) and (lastfile) then SZ_endSend;
               Zmodem_Send:= true;
           end;
         end;
      end;
   end;
   cursor(true);
end;

procedure batchzmodem(s: string);
var line: string;
    f: text;
    good,lastfile: boolean;

begin
   new(txbuf);
   new(secbuf);
   new(attn);
   if s[1]='@' then
   begin
      delete(s,1,1);
      if exist(s) then
      begin
         good:=true;
         assign(f,s);
         reset(f);
         while (good) and (not eof(f)) and (_cd) do
         begin
            readln(f,line);
            lastfile:=eof(f);
            good:=zmodem_send(line,lastfile);
         end;
         close(f);
      end else showmsg('Could not find',s);
   end else good:=zmodem_send(s,true);
   dispose(attn);
   dispose(secbuf);
   dispose(txbuf);
end;

end.
