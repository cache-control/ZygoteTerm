unit z_dial;

interface
{$F+,O+}

uses crt,dos,z_util,z_comio,z_mouse;

var lastsize: byte;
    newcarrier,
    newdirfile: boolean;

procedure dialmenu;
procedure findloc(var a: stringname; var b: byte);

implementation

const maxentry = 99;
      lsresult: array[1..10] of string[15] =('Busy signal    ','No carrier     ',
         'Ring detected  ','Voice call     ','Facsimile      ','Waiting...     ',
         'Time expired   ','Skip this entry','Recycling      ','User aborted   ');
      tollresult: array[0..2] of string[9] =('<Unknown>','Non-toll ','Toll call');

type TempType= array[1..maxentry] of record
                   name: stringname;
                   comments: stringdesc;
                   auto,proto: char;
                   params: paramtype;
                   notereq,flag: boolean;
                   str: string[62];
                   loc: string[24];
                   lsptr,tollptr,usedial: byte;
                   altnumber: array[1..2] of string[16];
                   TBNX: array[1..4] of integer;
                   emailflag: array[1..5] of char;
                   carrierbps: word;
               end;

var  size,top,bottom,lasttop,laston,
     totalmarked,nontolls,tempi: integer;
     markcheck: array[1..maxentry] of boolean;
     rat: mousetype;
     bbses: temptype;
     video: ^videotype;
     findstr: string[23];
     dirup: boolean;

procedure findloc(var a: stringname; var b: byte);
type areatype=record
        area,prefix: string[3];
        city: string[20];
        state: string[2];
     end;

var foundprefix,
    local: boolean;
    localfile: text;
    areafile: file of areatype;
    areadata: areatype;
    line: string;
    city,temp: string[24];
    compstr: string[7];
    ac,px: string[3];
    x,y: integer;

function getseek(area: stringname): integer;
var x: integer;
begin
   x:=0;
   if area='201' then x:=1;
   if area='202' then x:=664;
   if area='203' then x:=1256;
   if area='204' then x:=1699;
   if area='205' then x:=2032;
   if area='206' then x:=2615;
   if area='207' then x:=3122;
   if area='208' then x:=3447;
   if area='209' then x:=3712;
   if area='212' then x:=4007;
   if area='213' then x:=4631;
   if area='214' then x:=5289;
   if area='215' then x:=5954;
   if area='216' then x:=6508;
   if area='217' then x:=7030;
   if area='218' then x:=7371;
   if area='219' then x:=7639;

   if area='301' then x:=1;
   if area='302' then x:=647;
   if area='303' then x:=745;
   if area='304' then x:=1212;
   if area='305' then x:=1526;
   if area='306' then x:=1954;
   if area='307' then x:=2389;
   if area='308' then x:=2529;
   if area='309' then x:=2719;
   if area='312' then x:=2969;
   if area='313' then x:=3727;
   if area='314' then x:=4310;
   if area='315' then x:=4803;
   if area='316' then x:=5049;
   if area='317' then x:=5392;
   if area='318' then x:=5765;
   if area='319' then x:=6086;

   if area='401' then x:=1;
   if area='402' then x:=121;
   if area='403' then x:=518;
   if area='404' then x:=1095;
   if area='405' then x:=1700;
   if area='406' then x:=2177;
   if area='407' then x:=2506;
   if area='408' then x:=2840;
   if area='409' then x:=3106;
   if area='412' then x:=3369;
   if area='413' then x:=3778;
   if area='414' then x:=3903;
   if area='415' then x:=4323;
   if area='416' then x:=4909;
   if area='417' then x:=5481;
   if area='418' then x:=5669;
   if area='419' then x:=6018;

   if area='501' then x:=1;
   if area='502' then x:=516;
   if area='503' then x:=842;
   if area='504' then x:=1324;
   if area='505' then x:=1630;
   if area='506' then x:=1918;
   if area='507' then x:=2078;
   if area='508' then x:=2330;
   if area='509' then x:=2497;
   if area='512' then x:=2720;
   if area='513' then x:=3298;
   if area='514' then x:=3747;
   if area='515' then x:=4195;
   if area='516' then x:=4584;
   if area='517' then x:=4926;
   if area='518' then x:=5229;
   if area='519' then x:=5464;

   if area='601' then x:=1;
   if area='602' then x:=380;
   if area='603' then x:=932;
   if area='604' then x:=1151;
   if area='605' then x:=1665;
   if area='606' then x:=1985;
   if area='607' then x:=2240;
   if area='608' then x:=2401;
   if area='609' then x:=2627;
   if area='612' then x:=2879;
   if area='613' then x:=3359;
   if area='614' then x:=3618;
   if area='615' then x:=3996;
   if area='616' then x:=4483;
   if area='617' then x:=4832;
   if area='618' then x:=5168;
   if area='619' then x:=5475;

   if area='701' then x:=1;
   if area='702' then x:=343;
   if area='703' then x:=592;
   if area='704' then x:=1101;
   if area='705' then x:=1413;
   if area='707' then x:=1669;
   if area='708' then x:=1832;
   if area='709' then x:=2043;
   if area='712' then x:=2293;
   if area='713' then x:=2559;
   if area='714' then x:=3034;
   if area='715' then x:=3535;
   if area='716' then x:=3829;
   if area='717' then x:=4181;
   if area='718' then x:=4636;
   if area='719' then x:=5002;

   if area='801' then x:=1;
   if area='802' then x:=306;
   if area='803' then x:=477;
   if area='804' then x:=946;
   if area='805' then x:=1389;
   if area='806' then x:=1636;
   if area='807' then x:=1874;
   if area='808' then x:=1977;
   if area='809' then x:=2201;
   if area='812' then x:=2614;
   if area='813' then x:=2874;
   if area='814' then x:=3322;
   if area='815' then x:=3578;
   if area='816' then x:=3849;
   if area='817' then x:=4277;
   if area='818' then x:=4716;
   if area='819' then x:=5023;

   if area='901' then x:=1;
   if area='902' then x:=204;
   if area='904' then x:=421;
   if area='906' then x:=884;
   if area='907' then x:=992;
   if area='912' then x:=1382;
   if area='913' then x:=1688;
   if area='914' then x:=2104;
   if area='915' then x:=2412;
   if area='916' then x:=2692;
   if area='918' then x:=3063;
   if area='919' then x:=3341;
   getseek:=x;
end;

begin
   temp:='';
   with dialdata do
   for x:=1 to length(bbsphone) do if bbsphone[x] in ['0'..'9'] then temp:=temp+bbsphone[x];
   if length(temp)<7 then
   begin
      ac:='000';
      px:='000';
   end else
   if temp[1]='1' then
   begin
      ac:=copy(temp,2,3);
      px:=copy(temp,5,3);
   end else
   begin
      ac:=configdata.areacode;
      px:=copy(temp,1,3);
   end;
   temp:='Z_AREA'+ac[1]+'.DAT';
   x:=getseek(ac);
   if ac='000' then city:='Unknown city' else
   if exist(dir_areadata+'\'+temp) then
   begin
      assign(areafile,dir_areadata+'\'+temp);
      reset(areafile);
      foundprefix:=false;
      y:=filesize(areafile);
      city:='Unknown city';
      if (x>0) and (y>0) then
      repeat
          seek(areafile,x-1);
          read(areafile,areadata);
          if (areadata.area=ac) and (areadata.prefix=px) then
          begin
             city:=areadata.city+', '+areadata.state;
             foundprefix:=true;
          end else inc(x);
      until (foundprefix) or (ac<>areadata.area) or (x>y);
      close(areafile);
   end else
   begin
      city:='Missing '+temp;
      showmsg('You are missing',dir_areadata+'\'+temp);
   end;
   a:=city+blanks(24-length(city));;
   if exist(dir_areadata+'\Z_local.dat') then
   begin
      assign(localfile,dir_areadata+'\Z_local.dat');
      reset(localfile);
      local:= ac='800';
      temp:='';
      compstr:=configdata.areacode+','+ac;
      while (not local) and (not eof(localfile)) do
      begin
         readln(localfile,line);
         if pos('AC ',caps(line))=1 then temp:=copy(line,4,7) else
         begin
            if (temp=compstr) and (pos(px,line)>0) then local:=true;
         end;
      end;
      close(localfile);
      if local then b:=1 else b:=2;
   end else
   begin
      b:=0;
      showmsg('You are missing',dir_areadata+'\Z_LOCAL.DAT');
   end;
end;

procedure msg(s: string);
begin
   fwrite(s+blanks(34-length(s)),23,4,hattr(white,blue));
end;

procedure assignbbs(x: byte);
var y: byte;
begin
   with dialdata do
   with bbses[x] do
   begin
       bbses[x].str:=chars('0',2-length(its(x)))+its(X)+' '+bbsname+blanks(23-length(bbsname))+' '+
        lastdate+blanks(8-length(lastdate))+' '+blanks(16-length(bbsphone))+bbsphone+
         ' '+conv(dialdata.param.speed)+' '+its(timescalled)+blanks(4-length(its(timescalled)));
       bbses[x].flag:=redialflag;
       name:=user.handle+blanks(25-length(user.handle)); auto:=autosys; proto:=protocol;
       params:=param;
       notereq:=checknotepad;
       y:=(40-length(comment)) div 2; comments:=blanks(y)+comment+blanks(40-length(comment)-y);
       loc:=location;
       tollptr:=toll;
       markcheck[x]:=redialflag;
       fillchar(TBNX,sizeof(TBNX),0);
       for y:=1 to 2 do altnumber[y]:=altphone[y];
       for y:=1 to 5 do if dialdata.emailaddr[y]>'' then emailflag[y]:='û' else emailflag[y]:=' ';
    end;
    bbses[x].usedial:=dialdata.usedial;
end;

procedure Assignbbsarray;
var x: integer;
begin
   totalmarked:=0;
   nontolls:=0;
   seek(filehandle,0);
   for x:=1 to filesize(filehandle) do
   with bbses[x] do
   begin
      blockread(filehandle,dialdata,1,tempi);
      assignbbs(x);
      carrierbps:=0;
      if tollptr=1 then inc(nontolls);
      if flag then inc(totalmarked);
      lsptr:=6;
   end;
end;

procedure dialarg(n: byte; s1,s2: string);
var x: byte;
begin
   with dialdata do
   begin
      param:=configdata.param;
      usedial:=configdata.usedial;
      fillchar(emailaddr,sizeof(emailaddr),0);
      file_kbd:='ZYGOTE';      file_tbl:='ZYGOTE';
      file_pad:='BBS'+its(n);  autocapture:=false;
      altphone[1]:='';         altphone[2]:='';
      bbsname:=s1;             Syspass:='';
      bbsphone:=s2;            protocol:='A';
      autosys:='*';            Comment:='/* No Comments */';
      checknotepad:=false;     redialflag:=false;
      timescalled:=0;          lastdate:='New';
      scriptname:='';          file_cap:='BBS'+its(n);
      execute:='';
      with user do
      begin
         if configdata.generatepw then
         begin
            password:='';
            for x:=1 to 8 do password:=password+chr(random(36)+48);
         end;
         handle:=configdata.username;
         lfd:=configdata.lfd;
         comment:='/* Comment */';
         birthdate:='';
         realname:=handle;
         homephone:='';
         dataphone:='';
         address:='';
         city_state:='';
      end;
      findloc(location,toll);
   end;
   bbses[n].lsptr:=6;
   assignbbs(n);
   blockwrite(filehandle,dialdata,1);
end;

procedure Opendirfile;
begin
   assign(filehandle,dir_phone+'\'+lastdata.name_dir+'.DIR');
   if exist(dir_phone+'\'+lastdata.name_dir+'.DIR') then reset(filehandle,sizeof(dialdata)) else
   begin
      totalmarked:=0;
      nontolls:=0;
      showmsg('Could not locate '+lastdata.name_dir+'.DIR','Creating new phone file');
      rewrite(filehandle,sizeof(dialdata));
      if diskfree(0)<(2*sizeof(dialdata)) then msg(' Out of disk space') else
      begin
         dialarg(1,'Comtrick','1-805-522-4211');
         dialarg(2,'Holographic','1-813-848-1981');
         newdirfile:=true;
      end;
   end;
   size:=filesize(filehandle);
end;

function ldstr(s: stringname): stringdesc;
var t,x: byte;
begin
   t:=1;
   if s>'' then
   repeat
      case s[t] of
        '!': x:=1;
        '@': x:=2;
        '#': x:=3;
        '$': x:=4;
        '%': x:=5;
        else x:=0;
      end;
      if x>0 then
      begin
         delete(s,t,1);
         insert(lastdata.ldcodes[x],s,t);
      end;
      inc(t);
   until t>length(s);
   ldstr:=s;
end;

function checkresult(s: string): byte;
var x,y: byte;
begin
   y:=0;
   for x:=1 to 14 do if pos(configdata.results[x],s)>0 then y:=x;
   case y of
      6: dparam.speed:=300;    7: dparam.speed:=1200;
      8: dparam.speed:=2400;   9: dparam.speed:=4800;  10: dparam.speed:=9600;
     11: dparam.speed:=14400; 12: dparam.speed:=19200; 13: dparam.speed:=28800;
     14: dparam.speed:=38400; 15: dparam.speed:=57600;
    else begin
            checkresult:=y;
            if y=1 then inc(bbses[bbson].TBNX[2]);
            if y=2 then inc(bbses[bbson].TBNX[3]);
         end;
   end;
end;

procedure showstatl;
var a: byte;
begin
   with bbses[bbson] do
   begin
      fwrite(comments,1,14,attr(lightgray,black));
      a:=attr(lightgray,black);
      fwrite(name,16,14,attr(white,black));
      if auto='*' then fwrite('None in use         ',17,14,a) else
         fwrite(sysdata[auto].sysname+blanks(20-length(sysdata[auto].sysname)),17,14,a);
      fwrite(protodata[proto].protoname+blanks(25-length(protodata[proto].protoname)),18,14,a);
      with params do fwrite(parity+its(dbit)+its(sbit),19,14,a);
      fwrite(its(carrierbps)+' bps'+blanks(5-length(its(carrierbps))),19,29,attr(lightcyan,black));
      if notereq then fwrite('Yes',20,14,a) else fwrite('No ',20,14,a);
      fwrite(lsresult[lsptr],21,14,a);
      fwrite(loc+'  '+tollresult[tollptr],22,14,a);
      for a:=1 to 5 do fwrite(emailflag[a],a+17,79,attr(yellow,black));
   end;
end;

procedure writetime;
begin
   fwrite(time(1),timestat.y,timestat.x,attr(lightgreen,black));
end;

procedure showstatr;
var c: byte;
begin
   c:=attr(lightgray,black);
   fwrite(chars('0',2-length(its(size)))+its(size),16,52,c);
   fwrite(chars('0',2-length(its(totalmarked)))+its(totalmarked),17,52,c);
   fwrite(chars('0',2-length(its(nontolls)))+its(nontolls),18,52,c);
   fwrite(chars('0',2-length(its(size-nontolls)))+its(size-nontolls),19,52,c);
   fwrite(date,20,52,c);
   fwrite('Version '+cmsg(zversion),22,52,c);
   if (lastdata.lastcalled>0) and (lastdata.lastcalled<=size) then
   fwrite(copy(bbses[lastdata.lastcalled].str,4,23),25,16,attr(lightgreen,black)) else
   fwrite('/* None yet */',25,16,attr(lightgreen,black));
   writetime;
end;

function dialunit(colr,x,y: byte; show: boolean): char;
var s: string;
    cs: string[5];
    rat: mousetype;
    cwstring: string[10];
    out,carrier,escpressed: boolean;
    limit,whichnumber,ms: byte;
    hour,min,sec,lastsec,hund: word;
    code: integer;
    c: char;

function stripsp(s: stringname): stringname;
var i: byte;
begin
   i:=pos(' ',s);
   while (s>'') and (i>0) do
   begin
      delete(s,i,1);
      i:=pos(' ',s);
   end;
   stripsp:=s;
end;

begin
   dialunit:=#0;
   whichnumber:=0;
   if configdata.cwtoggle then cwstring:=configdata.callwaiting else cwstring:='';
   with configdata do
   repeat
      s:='';
      ms:=0;
      limit:=0;
      out:=false;
      escpressed:=false;
      with bbses[bbson].params do _set_param(speed,parity,dbit,sbit);
      case whichnumber of
         0: send(dialstr[bbses[bbson].usedial]+ldstr(cwstring+stripsp(copy(bbses[bbson].str,37,16)))+dialsuffix);
         1,
         2: begin
               showmsg('Resorting to alternative number',
               'Option ('+its(whichnumber)+') '+bbses[bbson].altnumber[whichnumber]);
               send(dialstr[bbses[bbson].usedial]+ldstr(cwstring+bbses[bbson].altnumber[whichnumber])+dialsuffix);
            end;
      end;
      repeat
         if _rx_ready then
         begin
            c:=chr(_get);
            if show then write(c);
            s:=s+c;
            if c=#10 then
            begin
               tempi:=pos('CARRIER ',s);
               if tempi>0 then
               begin
                  cs:=copy(s,tempi+8,5);
                  while (cs>'') and ( (cs[length(cs)]=#10) or
                      (cs[length(cs)]=' ') or (cs[length(cs)]=#13) ) do
                         delete(cs,length(cs),1);
                  val(cs,bbses[bbson].carrierbps,code);
               end;
               ms:=checkresult(s);
               out:=ms>0;
            end;
         end;
         if keypressed then
         begin
            c:=upcase(readkb);
            if c=#0 then
            begin
               c:=readkb;
               screendump(c);
               grabline(c);
            end else if c='M' then limit:=0 else
            begin
               if c=' ' then out:=true else
               begin
                  out:= c in [^[,'U','S'];
                  escpressed:=true;
               end;
            end;
         end;
         gettime(hour,min,sec,hund);
         if sec<>lastsec then
         begin
            lastsec:=sec;
            writetime;
            inc(limit);
            fwrite(chars('0',2-length(its(limit)))+its(limit),y,x,colr);
         end;
         carrier:=(_cd) and (ms>0);
         mouseposition(rat);
         if rat.stat=rightpress then
         begin
            mousepress(rightbutton,rat);
            out:=rat.pcount=1;
         end;
      until (limit>diallimit) or (out) or (carrier);

      if carrier then
      begin
         whichnumber:=3;
         _flush_rx;
         bbses[bbson].lsptr:=6;
         if bbses[bbson].flag then dec(totalmarked);
         lastdata.lastcalled:=bbson;
         connected:=true;
         newcarrier:=true;
         dialnumber:=bbson;
         seek(filehandle,bbson-1);
         blockread(filehandle,dialdata,1,tempi);
         with dialdata do
         begin
            lastdate:=date;
            redialflag:=false;
            inc(timescalled);
            if timescalled>9999 then timescalled:=0;
            dparam:=param;
         end;
         with dparam do _set_param(speed,parity,dbit,sbit);
         seek(filehandle,bbson-1);
         blockwrite(filehandle,dialdata,1);
         assignbbs(bbson);
      end else
      begin
         inc(whichnumber);
         while (whichnumber<3) and (bbses[bbson].altnumber[whichnumber]='') do
            inc(whichnumber);
         inc(bbses[bbson].TBNX[1]);
         if limit>configdata.diallimit then
         begin
            bbses[bbson].lsptr:=7;
            inc(bbses[bbson].TBNX[4]);
         end;
         case upcase(c) of
           'S': bbses[bbson].lsptr:=8;
           ' ': begin
                   whichnumber:=0;
                   bbses[bbson].lsptr:=9;
                   showmsg('Recycling this call','Restorting to primary number');
                end;
           'U': if bbses[bbson].flag=true then
                begin
                   s:='Un-marked';
                   bbses[bbson].flag:=false;
                   dec(totalmarked);
                end;
           '': begin
                   bbses[bbson].lsptr:=10;
                   dialunit:=c;
                end;
         end;
         if ms>0 then bbses[bbson].lsptr:=ms;
         msg(' Hanging up modem...');
         send(#13);
         _dtr(false); delay(configdata.dtrdelay); _dtr(true);
         send(#13);
         delay(1000);
         msg(' Continue dialing...');
         _flush_rx;
         with dparam do _set_param(speed,parity,dbit,sbit);
         if ((bbses[bbson].TBNX[3]+bbses[bbson].TBNX[4])>=unmarkwhen) and (unmarkwhen>0) then
         if bbses[bbson].flag then
         begin
            fillchar(bbses[bbson].TBNX,8,0);
            showmsg('Unmarking this entry','limit of non-BUSY tries reached');
            bbses[bbson].flag:=false;
            dec(totalmarked);
            whichnumber:=3;
         end;
      end;
      showstatl;
      if (escpressed) or (not configdata.usealtnum) then whichnumber:=3;
   until whichnumber>2;
end;

procedure dial;
var y: byte;
begin
   if _cd then msg(' Modem online - dial aborted') else
   begin
      msg(' Dial mode');
      savevideo(video^,true);
      y:=bbson-top+3;
      makebox(attr(white,cyan),1,y,65,y+2,1);
      fwritena('´ Dial mode Ã',y,3);
      fwritena('(00/'+its(configdata.diallimit)+')',y,58);
      fwrite(bbses[bbson].str,y+1,3,attr(yellow,cyan));
      dialunit(attr(white,cyan),59,y,false);
      if not _cd then savevideo(video^,false);
      showstatl;
      showstatr;
   end;
end;

procedure showaccounts;
var y,z,c: byte;

begin
   z:=3;
   for y:=top to bottom do
   begin
      inc(z);
      c:=attr(lightcyan,black);
      if bbses[y].flag then fwrite('',z,2,c) else fwrite(' ',z,2,c);
      if y=bbson then c:=hattr(white,cyan) else
      begin
         if bbses[y].tollptr=2 then c:=attr(darkgray,black) else
         c:=attr(lightgray,black);
      end;
      fwrite(bbses[y].str,z,3,c);
   end;
   showstatl;
end;

procedure adjustpos;
begin
   if bbson<1 then bbson:=1 else if bbson>size then bbson:=size;
   if bbson<top then top:=bbson else if bbson>bottom then top:=bbson-9;
   if top<1 then top:=1;
   bottom:=top+9;
   if bottom>size then bottom:=size;
end;

procedure entryedit;
const dmname ='ZYGOTE.DMD';
type temparray = array[1..2] of fielddesctype;
var ch: char;
    lo,colr,lo3,lasttollptr: byte;
    tempname: string[8];
    lastphone: string[16];
    fdesc: ^temparray;

   procedure win(tx,ty,bx,by: byte);
   var i,y: byte;
   begin
      makebox(attr(lightblue,black),tx,ty,bx,by,1);
      fwritena('Â',ty,sc.s+tx+1);
      y:=by-1;
      if sc.t<22 then
      begin
         y:=ty+sc.t;
         fwritena('Ã'+chars('Ä',bx-tx-1)+'´',ty+sc.t+1,1);
         fwritena('Á',ty+sc.t+1,sc.s+tx+1);
      end else fwritena('Á',by,sc.s+tx+1);
      for i:=ty+1 to y do fwritena('³',i,sc.s+tx+1);
   end;
   procedure writest(x,y,size: byte; st: string);
   begin
      st:=copy(st,1,size);
      fwrite(st+blanks(size-length(st)),y,x,attr(lightgray,black));
   end;
   function numonly(s: string): string;
   var i: byte;
       temp: string[16];
   begin
      temp:='';
      for i:=1 to length(s) do if s[i] in ['0'..'9'] then temp:=temp+s[i];
      numonly:=temp;
   end;
begin
   new(fdesc);
   if readdesc(dmname,'@EDIT_L') then
   begin
      lasttop:=0;
      lasttollptr:=bbses[bbson].tollptr;
      sc.c:=hattr(white,cyan);
      sc.nc:=attr(lightcyan,black);
      timestat.flag:=0;
      page.flag:=1;
      page.x:=11;
      page.y:=25;
      page.colr:=attr(yellow,black);
      colr:=hattr(white,blue);
      lo:=1;
      savevideo(video^,true);
      win(1,1,80,24);
      writedescfield;
      fdesc^[1]:=fielddesc^;
      bigsc[1]:=sc;
      if readdesc(dmname,'@EDIT_R') then
      begin
         fwritena('Â',1,59);
         fwritena('Á',24,59);
         for lo3:=2 to 23 do fwrite('³',lo3,59,attr(lightblue,black));
         sc.c:=hattr(white,cyan);
         sc.nc:=attr(lightcyan,black);
         writedescfield;
         fdesc^[2]:=fielddesc^;
         bigsc[2]:=sc;
      end;
      fwrite(' Detail : ',25,1,attr(white,black));
      {$I-}
      seek(filehandle,bbson-1);
      blockread(filehandle,dialdata,1,tempi);
      dialdata.redialflag:=bbses[bbson].flag;
      lastphone:=numonly(dialdata.bbsphone);
      sc:=bigsc[1];
      fielddesc^:=fdesc^[1];
      sctotal:=2;
      scptr:=1;
      if ioresult=0 then
      with dialdata do
      repeat
          if scptr=1 then
          begin
             writest(48,6,4,' ('+autosys+')');
             writest(48,7,4,' ('+protocol+')');
             writest(23,2,23,bbsname);
             writest(23,3,16,bbsphone);
             writest(23,4,35,comment);
             if configdata.showpwd then writest(23,5,20,syspass) else
                writest(23,5,20,chars('þ',length(syspass)));
             if autosys='*' then writest(23,6,25,'None in use') else
                writest(23,6,25,sysdata[autosys].sysname);
             writest(23,7,25,protodata[protocol].protoname);
             writest(23,8,8,scriptname); writest(31,8,4,'.SCR');
             writest(23,9,5,its(param.speed));
             writest(23,10,1,param.parity);
             writest(23,11,1,its(param.dbit));
             writest(23,12,1,its(param.sbit));
             case param.graphic of
                   uANSI: writest(23,13,14,'ANSI graphic');
                  uVT100: writest(23,13,14,'VT100 graphic');
                 uAVATAR: writest(23,13,14,'AVATAR graphic');
                   uNONE: writest(23,13,14,'No graphic');
             end;
             with user do
             begin
                writest(23,14,25,handle);
                if configdata.showpwd then writest(23,15,20,password) else
                   writest(23,15,20,chars('þ',length(password)));
                writest(23,16,4,lfd);
                writest(23,17,35,comment);
                writest(23,18,8,birthdate);
                writest(23,19,25,realname);
                writest(23,20,14,homephone);
                writest(23,21,14,dataphone);
                writest(23,22,35,address);
                writest(23,23,35,city_state);
             end;
          end else
          begin
             writest(42,2,16,altphone[1]);
             writest(42,3,16,altphone[2]);
             writest(23,4,35,execute);
             writest(57,5,1,its(usedial));
             if checknotepad then writest(55,6,3,'Yes') else writest(55,6,3,' No');
             writest(46,7,8,file_kbd); writest(54,7,4,'.KBD');
             writest(46,8,8,file_tbl); writest(54,8,4,'.TBL');
             writest(46,9,8,file_pad); writest(54,9,4,'.PAD');
             writest(50,10,8,file_cap);
             with param do
             begin
                if destructbs then writest(55,11,3,'Yes') else writest(55,11,3,' No');
                if autolf then writest(55,12,3,'Yes') else writest(55,12,3,' No');
                if localecho then writest(55,13,3,'Yes') else writest(55,13,3,' No');
                if striphb then writest(55,14,3,'Yes') else writest(55,14,3,' No');
                if autocapture then writest(55,15,3,'Yes') else writest(55,15,3,' No');
                if captureemul then writest(55,16,3,'Yes') else writest(55,16,3,' No');
                if captureexist=uAPPend then writest(49,17,9,'   Append') else writest(49,17,9,'Overwrite');
             end;
             for lo3:=1 to 5 do writest(23,17+lo3,35,emailaddr[lo3]);
          end;
          editflag(1,1,1,1,1,0,1);
          ch:=scrollchoice(#13+#16+#17+#27+'*ABCDEFHIJ',lo);
          lo3:=0;
          if (ch=#255) then
          begin
             sc:=bigsc[scptr];
             fielddesc^:=fdesc^[scptr];
             makebox(attr(lightblue,black),23,2,57,23,5);
          end else
          if (ch=#16) or (ch=#17) then
          begin
             if scptr=1 then scptr:=sctotal else scptr:=1;
             sc:=bigsc[scptr];
             fielddesc^:=fdesc^[scptr];
             makebox(attr(lightblue,black),23,2,57,23,5);
          end else
          if ch<>#27 then
          begin
             if scptr=1 then
             case lo of
                1: if ch=#13 then if input(colr,23,lo+1,bbsname,23,23,lo3)=' ' then;
                2: if ch=#13 then if input(colr,23,lo+1,bbsphone,16,16,lo3)=' ' then;
                3: if ch=#13 then if input(colr,23,lo+1,comment,40,35,lo3)=' ' then;
                4: if ch=#13 then if input(colr,23,lo+1,syspass,20,20,lo3)=' ' then;
                5: if ch>#13 then autosys:=ch else
                      case autosys of
                        '*': autosys:='A';
                        'J': autosys:='*';
                        else autosys:=chr(ord(autosys)+1);
                      end;
                6: if ch in ['A'..'J'] then protocol:=ch else
                      case protocol of
                         'J': protocol:='A';
                         else protocol:=chr(ord(protocol)+1);
                      end;
                7: if ch=#13 then
                   begin
                      editflag(1,0,0,1,0,1,0);
                      tempname:=scriptname;
                      scriptname:=pickfile(23,lo+1,dir_script+'\*.scr',scriptname);
                      if scriptname=tempname then
                      if input(colr,23,lo+1,scriptname,8,8,lo3)=' ' then;
                   end;
                8: if ch=#13 then
                      case param.speed of
                          300: param.speed:=1200;
                         1200: param.speed:=2400;
                         2400: param.speed:=4800;
                         4800: param.speed:=9600;
                         9600: param.speed:=14400;
                        14400: param.speed:=19200;
                        19200: param.speed:=28800;
                        28800: param.speed:=38400;
                        38400: param.speed:=57600;
                        57600: param.speed:=300;
                      end;
                9: if ch=#13 then
                      case param.parity of
                         'N': param.parity:='E';
                         'E': param.parity:='S';
                         'S': param.parity:='M';
                         'M': param.parity:='O';
                         'O': param.parity:='N';
                      end;
               10: if ch=#13 then if param.dbit=8 then param.dbit:=5 else inc(param.dbit);
               11: if ch=#13 then if param.sbit=1 then param.sbit:=2 else param.sbit:=1;
               12: if ch=#13 then
                      case param.graphic of
                          uANSI: param.graphic:=uVT100;
                         uVT100: param.graphic:=uAVATAR;
                        uAVATAR: param.graphic:=uNONE;
                          uNONE: param.graphic:=uANSI;
                      end;
               13: if ch in ['A'..'E'] then user:=accountdata[ch] else
                      if input(colr,23,lo+1,user.handle,25,25,lo3)=' ' then;
               14: if ch=#13 then if input(colr,23,lo+1,user.password,20,20,lo3)=' ' then;
               15: if ch=#13 then if input(colr,23,lo+1,user.lfd,4,4,lo3)=' ' then;
               16: if ch=#13 then if input(colr,23,lo+1,user.comment,40,35,lo3)=' ' then;
               17: if ch=#13 then if input(colr,23,lo+1,user.birthdate,8,8,lo3)=' ' then;
               18: if ch=#13 then if input(colr,23,lo+1,user.realname,25,25,lo3)=' ' then;
               19: if ch=#13 then if input(colr,23,lo+1,user.homephone,14,14,lo3)=' ' then;
               20: if ch=#13 then if input(colr,23,lo+1,user.dataphone,14,14,lo3)=' ' then;
               21: if ch=#13 then if input(colr,23,lo+1,user.address,40,35,lo3)=' ' then;
               22: if ch=#13 then if input(colr,23,lo+1,user.city_state,40,35,lo3)=' ' then;
             end else
             case lo of
                1,2: if ch=#13 then if input(colr,42,lo+1,altphone[lo],16,16,lo3)=' ' then;
                3: begin
                      editflag(1,1,1,1,1,0,1);
                      if ch=#13 then if input(colr,23,lo+1,execute,40,35,lo3)=' ' then;
                   end;
                4: if usedial=1 then usedial:=2 else usedial:=1;
                5: checknotepad:=not checknotepad;
                6: begin
                      editflag(1,0,0,1,0,1,0);
                      tempname:=file_kbd;
                      file_kbd:=pickfile(29,lo+1,'*.kbd',file_kbd);
                      if file_kbd=tempname then
                      if ch=#13 then if input(colr,46,lo+1,file_kbd,8,8,lo3)=' ' then;
                   end;
                7: begin
                      editflag(1,0,0,1,0,1,0);
                      tempname:=file_tbl;
                      file_tbl:=pickfile(29,lo+1,'*.tbl',file_tbl);
                      if file_tbl=tempname then
                      if ch=#13 then if input(colr,46,lo+1,file_tbl,8,8,lo3)=' ' then;
                   end;
                8: begin
                      editflag(1,0,0,1,0,1,0);
                      tempname:=file_pad;
                      file_pad:=pickfile(29,lo+1,dir_notepad+'\*.pad',file_pad);
                      if file_pad=tempname then
                      if ch=#13 then if input(colr,46,lo+1,file_pad,8,8,lo3)=' ' then;
                   end;
                9: begin
                      editflag(1,0,0,1,0,1,0);
                      if ch=#13 then if input(colr,50,lo+1,file_cap,8,8,lo3)=' ' then;
                   end;
               10: param.destructbs:=not param.destructbs;
               11: param.autolf:=not param.autolf;
               12: param.localecho:=not param.localecho;
               13: param.striphb:=not param.striphb;
               14: autocapture:=not autocapture;
               15: param.captureemul:=not param.captureemul;
               16: if param.captureexist=uAPPend then param.captureexist:=uOVERWRITE else
                      param.captureexist:=uAPPend;
               17..
               21: if ch=#13 then
                     if input(colr,23,lo+1,emailaddr[lo-16],40,35,lo3)=' ' then;
             end;
          end;
      until ch=#27;
      if (lastphone<>numonly(dialdata.bbsphone)) or (configdata.rescanafteredit)
         or (exist(dir_areadata+'\'+copy(dialdata.location,9,11))) then findloc(dialdata.location,dialdata.toll);
      assignbbs(bbson);
      if (lasttollptr<>1) and (bbses[bbson].tollptr=1) then inc(nontolls);
      if (lasttollptr=1) and (bbses[bbson].tollptr<>1) then dec(nontolls);
      savevideo(video^,false);
      seek(filehandle,bbson-1);
      blockwrite(filehandle,dialdata,1);
      if ioresult=0 then;
      {$I+}
      timestat.flag:=1;
   end;
   page.flag:=0;
   dispose(fdesc);
   showstatl;
   showstatr;
   sctotal:=0;
   sc.x:=3; sc.y:=4;
   sc.s:=62;

end;

procedure redial;
var numon: byte;
    out: boolean;

procedure writewindow;
var c,i: byte;
begin
   c:=attr(lightblue,black);
   fwrite('Ã'+chars('Ä',36)+'ÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ´',5,1,c);
   for i:=6 to 10 do fwrite('³              ³          ³',i,39,c);
   fwrite('ÃÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´',11,39,c);
   fwrite('³                         ³',12,39,c);
   fwrite('³                         ³',13,39,c);
   fwrite('ÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ',14,39,c);
   c:=attr(yellow,black);
   fwrite('of '+chars('0',2-length(its(configdata.diallimit)))+its(configdata.diallimit),6,59,c);
   fwrite('Counter',6,41,c);
   fwrite('Tries',7,41,c);
   fwrite('Busy',8,41,c);
   fwrite('No carrier',9,41,c);
   fwrite('Time Expired',10,41,c);
   fwrite('M)ore time  S)kip',12,41,c);
   fwrite('U)nmark    ^[) Exit',13,41,c);
   makebox(attr(lightgray,black),2,6,38,13,5);
end;

procedure writedata;
var c,y: byte;
begin
   showstatl;
   showstatr;
   fwrite(' '+bbses[bbson].str,4,2,attr(white,black));
   c:=attr(lightcyan,black);
   for y:=1 to 4 do
   with bbses[bbson] do
      fwrite(chars('0',2-length(its(TBNX[y])))+its(TBNX[y]),y+6,56,c);
end;

begin
   if _cd then msg(' Modem online - redial aborted') else
   if totalmarked>0 then
   begin
      savevideo(video^,true);
      lasttop:=0;
      writewindow;
      numon:=bbson;
      laston:=bbson;
      out:=false;
      cursor(true);
      color(lightgray,black);
      window(3,6,38,13);
      repeat
         if bbses[bbson].flag then
         begin
            laston:=bbson;
            writedata;
            msg(' Pausing for modem...');
            delay(configdata.redialpause);
            msg(' Continue redialing...');
            out:=dialunit(attr(lightcyan,black),56,6,true)=#27;
         end;
         if (_cd) or (totalmarked<1) then out:=true else
         begin
            inc(bbson);
            if bbson>size then bbson:=1;
         end;
     until out;
     cursor(false);
     if not _cd then
     begin
        savevideo(video^,false);
        bbson:=numon;
     end else adjustpos;
     showstatr;
     window(1,1,80,25);
   end else msg(' No marked entries');
end;

procedure ldcodes;
var c,m: byte;
    ch: char;
begin
   sc.x:=31; sc.y:=15;
   sc.s:=4; sc.t:=5;
   sc.nc:=attr(lightcyan,black);
   sc.c:=hattr(white,cyan);
   savevideo(video^,true);
   msg(' Editing LD codes');
   editflag(1,1,0,1,0,0,1);
   c:=attr(lightblue,black);
   makebox(c,30,14,68,20,1);
   fwritena('Â',14,35); fwritena('Á',20,35); vertchars(c,35,15,19,'³');
   fwrite('!:',15,32,sc.nc); fwrite('@:',16,32,sc.nc); fwrite('#:',17,32,sc.nc);
   fwrite('$:',18,32,sc.nc); fwrite('%:',19,32,sc.nc);
   for c:=1 to sc.t do fwrite(lastdata.ldcodes[c],c+14,36,attr(cyan,black));
   c:=1;
   repeat
      m:=0;
      ch:=scrollchoice(#27+#13,c);
      if ch=#13 then
      begin
         if input(hattr(white,cyan),36,c+14,lastdata.ldcodes[c],30,30,m)=' ' then;
         changeattr(30,c+14,36,attr(cyan,black));
      end;
   until ch=#27;
   savevideo(video^,false);
   cursor(false);
end;

procedure add;
begin
   if size>maxentry-1 then showmsg('Reached max # of','entries supported') else
   if diskfree(0)>sizeof(dialdata) then
   begin
      msg('');
      hilight(white,blue);
      xy(4,23,' Add new entry #'+its(filesize(filehandle)+1)+' ? ');
      cursor(true);
      if upcase(readkb)='Y' then
      begin
         size:=filesize(filehandle)+1;
         bbson:=size;
         bottom:=size;
         seek(filehandle,size-1);
         dialarg(size,'New Board','');
         if bottom>10 then top:=bottom-9 else top:=1;
         msg(' Added a new entry');
      end else msg(' Add - user aborted');
      cursor(false);
      showstatr;
   end else showmsg('Cannot add new entry','Not enough disk space');
   lasttop:=0;
end;

procedure conv2text;
var x: byte;
   df: text;
begin
   if diskfree(0)>(filesize(filehandle)*sizeof(dialdata))+1250 then
   begin
      msg(' Convert to text');
      assign(df,dir_phone+'\'+lastdata.name_dir+'.BBS');
      rewrite(df);
      writeln(df,'® Convertion of '+lastdata.name_dir+'.DIR'+' to text format '+lastdata.name_dir+'.BBS ¯');
      writeln(df,'These numbers are called from area code '+configdata.areacode);
      writeln(df,'There is a total of '+its(filesize(filehandle))+' number entry(ies).');
      writeln(df,'');
      writeln(df,'## BBS Description           Date      Phone Number  Rate Tc  ');
      writeln(df,'--------------------------------------------------------------');
      writeln(df,'');
      for x:=1 to filesize(filehandle) do writeln(df,bbses[x].str);
      close(df);
      showmsg(lastdata.name_dir+'.BBS','Conversion completed');
   end else msg(' Not enough disk space');
end;

procedure FindBBS(repeatit: boolean);
Var x: byte;
    ch: char;
begin
   laston:=bbson;
   if repeatit then
   begin
      ch:=#13;
      x:=bbson+1;
      if x>size then x:=size;
   end else
   begin
      findstr:=''; x:=0;
      editflag(1,1,0,1,1,1,1);
      msg(' Find : ');
      ch:=input(hattr(white,blue),12,23,findstr,23,23,x);
      cursor(false); x:=1;
   end;
   if ch=#27 then msg(' Find aborted');
   if ch=#13 then
   begin
     repeat
        if Pos(findstr,caps(bbses[x].str))>0 Then
        begin
           ch:='Y';
           bbson:=x;
           adjustpos;
        end;
        inc(x);
     until (x>size) or (ch='Y');
     if ch='Y' then msg(' Found it') else msg(' String was not found');
   end;
   laston:=bbson;
   lasttop:=0;
   cursor(false);
end;

procedure drawborder;
var i,maxp: byte;
begin
   i:=attr(lightblue,black);
   makebox(i,1,1,65,14,1);  makebox(i,66,1,80,14,1);
   makebox(i,1,15,65,23,1); makebox(i,66,15,80,23,1);
   fwritena('´'+blanks(12)+'Ã',15,51);
   fwrite(lastdata.name_dir+blanks(8-length(lastdata.name_dir))+'.DIR',15,52,hattr(white,blue));
   fwritena('´',23,3);  fwritena('Ã',23,38);  fwritena('´                                        Ã',1,13);
   fwritena('Ã'+chars('Ä',12)+'Ä´',12,66);
   fwritena('Ã'+chars('Ä',63)+'´',3,1);
   fwritena('Â',15,12); fwritena('Â',15,50); fwritena('Á',23,50);
   vertchars(i,12,16,22,'³');
   vertchars(i,50,16,22,'³');

   fwritena('Â',15,76); fwritena('³',16,76); fwritena('Á',23,78);
   vertchars(i,78,18,22,'³');
   fwritena('ÃÄÄÄÄÄÄÄÄÄÁÄÂÄ´',17,66);

   maxp:=0;
   for i:=0 to 6 do
   begin
      tempi:=trunc(10*lastdata.timesused[i]/lastdata.timesused[7]);
      if tempi>maxp then maxp:=tempi;
   end;
   if maxp<10 then inc(maxp);
   for i:=1 to 10 do
       fwrite(blanks(3-length(its(i*maxp)))+its(i*maxp)+'%',12-i,67,attr(lightcyan,black));
   gotoxy(1,24);
   for i:=0 to 6 do
   begin
       tempi:=12-trunc(100*lastdata.timesused[i]/lastdata.timesused[7]/maxp);
       vertchars(attr(lightgreen,black),73+i,tempi,11,'þ');
   end;
   i:=attr(cyan,black);
   fwrite('usage',13,67,attr(lightgray,black));
   fwrite('SMTWTFS',13,73,attr(lightcyan,black));
   changeattr(1,13,74,i); changeattr(1,13,76,i); changeattr(1,13,78,i);
   fwrite(configdata.areacode,16,77,attr(yellow,black));
   i:=attr(lightblue,black);
   fwrite('## BBS Description           Date      Phone Number  Rate Tc  ',2,3,hattr(white,blue));
   fwrite('                                       (A)dd     (C)odes  (E)dit (F)ind  (K)ill ',24,1,i);
   fwrite('                                       (N)ew dir (R)edial (T)ext ( )Mark (/)    ',25,1,i);
   i:=attr(lightcyan,black);
   fwrite('Last called:',25,3,attr(cyan,black));
   changeattr(1,24,41,i); changeattr(1,24,51,i); changeattr(1,24,60,i);
   changeattr(1,24,67,i); changeattr(1,24,75,i); changeattr(1,25,41,i);
   changeattr(1,25,51,i); changeattr(1,25,60,i); changeattr(1,25,75,i);
   i:=attr(cyan,black);
   fwrite('DCE',19,24,attr(yellow,black)); fwritena('('+blanks(9)+')',19,28);
   fwrite('Login',16,3,i);     fwrite('Entries',16,40,i);
   fwrite('Auto Sys',17,3,i);  fwrite('Marked',17,40,i);
   fwrite('Protocol',18,3,i);  fwrite('Non-Toll',18,40,i);
   fwrite('Params',19,3,i);    fwrite('Toll/Unkn',19,40,i);
   fwrite('NotePad',20,3,i);   fwrite('Date',20,40,i);
   fwrite('Status',21,3,i);    fwrite('Time',21,40,i);
   fwrite('Location',22,3,i);  fwrite('Areacode',16,67,attr(lightcyan,black));
   fwrite('Internet',18,67,i); fwrite('FIDOnet',19,67,i);
   fwrite('WWIVnet',20,67,i);  fwrite('Virtualnet',21,67,i);
   fwrite('Other net',22,67,i);
   msg(' System OK - ready for use');
end;

procedure scannewfile;
begin
   if newdirfile then
   begin
      assignbbsarray;
      size:=filesize(filehandle);
      if size>=10 then bottom:=10 else bottom:=size;
      top:=1; bbson:=1; laston:=1;
      dirup:=false;
      newdirfile:=false;
   end;
end;

procedure newdir;
var x: byte;
    s: string[12];
begin
   x:=0;
   editflag(1,0,0,1,0,1,0);
   msg(' Enter a new dir file');
   s:=pickfile(50,15,dir_phone+'\*.dir',lastdata.name_dir);
   if s=lastdata.name_dir then
   if input(hattr(white,blue),52,15,s,8,8,x)=#13 then;
   cursor(false);
   if (lastdata.name_dir<>s) and (length(s)>0) then
   begin
      lastdata.lastcalled:=0;
      lastdata.name_dir:=s;
      msg(' New phone file');
      lasttop:=0;
      bbson:=1;
      newdirfile:=true;
      close(filehandle);
      opendirfile;
      scannewfile;
      drawborder;
      showstatr;
   end else
   begin
      msg(' Same phone file');
      fwrite(lastdata.name_dir,15,52,hattr(white,blue));
   end;
end;

procedure kill;
var myfile: file of dialtype;
    x,y: byte;
begin
  if filesize(filehandle)>1 then
  begin
     msg('');
     hilight(white,blue);
     xy(4,23,' Kill this entry #'+its(bbson)+' ? ');
     cursor(true);
     if upcase(readkb)='Y' then
     begin
        cursor(false);
        if diskfree(0)>(filesize(filehandle)*sizeof(dialdata)) then
        begin
           if bbses[bbson].flag then dec(totalmarked);
           if bbses[bbson].tollptr=1 then dec(nontolls);
           msg(' Update phone file');
           assign(myfile,dir_phone+'\!!TEMP!!.!!!');
           rewrite(myfile);
           y:=1;
           for X:=1 to size do
           if X<>BBSon then
           begin
              seek(filehandle,x-1);
              blockread(filehandle,dialdata,1,tempi);
              write(myfile,dialdata);
              assignbbs(y);
              inc(y);
           end;
           close(myfile);
           close(filehandle);
           assign(filehandle,dir_phone+'\'+lastdata.name_dir+'.DIR');
           erase(filehandle);
           assign(myfile,dir_phone+'\'+'!!TEMP!!.!!!');
           rename(myfile,dir_phone+'\'+lastdata.name_dir+'.DIR');
           opendirfile;
           if bottom>size then bottom:=size;
           if bbson>bottom then bbson:=bottom;
           top:=bottom-9;
           if top<1 then top:=1;
           lasttop:=top;
           laston:=bbson;
           drawborder;
           showaccounts;
           showstatr;
        end else showmsg('Cannot kill entry','Not enough disk space');
     end else msg(' Kill - user aborted');
     cursor(false);
  end else showmsg('Cannot kill this entry','There is only 1 entry left');
end;

procedure key_alt;
var ch: char;
begin
   ch:=readkb;
   lasttop:=top;
   laston:=bbson;
   case ch of
      #71: begin
              bbson:=1;
              msg(' top entry');
           end;
      #79: begin
              bbson:=size;
              msg(' bottom entry');
           end;
      #72: if bbson>1 then
           begin
              dec(bbson);
              DIRUP:=true;
              msg(' moving up');
           end;
      #80: if bbson<size then
           begin
              inc(bbson);
              DIRUP:=false;
              msg(' moving down');
           end;
      #73: dec(bbson,5);
      #81: inc(bbson,5);
     end;
     grabline(ch);
     screendump(ch);
     adjustpos;
end;

procedure tagbbs;
begin
   lasttop:=0;
   bbses[bbson].flag:=not bbses[bbson].flag;
   if not bbses[bbson].flag then
   begin
      msg(' Unmarked entry');
      dec(totalmarked);
   end else
   begin
      msg(' Marked entry');
      inc(totalmarked);
   end;
   if dirup then dec(bbson) else inc(bbson);
   adjustpos;
   showstatr;
end;

procedure singleaccount;
var c,row: byte;
begin
   row:=laston-top+4;
   c:=attr(lightcyan,black);
   if bbses[laston].flag then fwrite('',row,2,c) else fwrite(' ',row,2,c);
   if bbses[laston].tollptr=2 then c:=attr(darkgray,black) else c:=attr(lightgray,black);
   fwrite(bbses[laston].str,row,3,c);
   row:=bbson-top+4;
   c:=attr(lightcyan,black);
   if bbses[BBSon].flag then fwrite('',row,2,c) else fwrite(' ',row,2,c);
   fwrite(bbses[bbson].str,row,3,hattr(white,cyan));
   showstatl;
end;

procedure dialmenu;
var ldate: string[8];
    timetemp: string[12];
    ch: char;

procedure Dialbbs;
var num: string[2];
    X,Y: integer;
    m: byte;
begin
   num:=ch+'0';
   val(num,x,y);
   if y<>0 then x:=bbson;
   laston:=bbson;
   if x<=size then
   begin
      num:=ch;
      m:=0;
      msg(' Enter # : ');
      editflag(0,1,0,1,0,0,0);
      if input(hattr(white,blue),15,23,num,2,2,m)=#13 then
      begin
         val(num,x,y);
         if (x>size) or (x<1) then BBSon:=BBSon else BBSon:=x;
         adjustpos;
         showaccounts;
         cursor(false);
         dial;
      end;
      cursor(false);
   end else
   begin
      num:=ch;
      val(num,x,y);
      BBSon:=x;
      adjustpos;
      showaccounts;
      dial;
   end;
   laston:=bbson;
end;

begin
   showmouse;
   hidemouse;
   new(video);
   new(fielddesc);
   with timestat do
   begin
      flag:=1;
      x:=52;
      y:=21;
      colr:=attr(lightgreen,black);
   end;
   cursor(false);
   wx:=wherex; wy:=wherey;
   window(1,1,80,25);
   savevideo(videoback,true);
   drawborder;
   newcarrier:=false;
   lasttop:=0;
   opendirfile;
   newdirfile:=lastsize<>size;
   scannewfile;
   showstatr;
   sc.x:=3; sc.y:=4;
   sc.s:=62;
   repeat
       ch:=#0;
       showmouse;
       hidemouse;
       if size>10 then sc.t:=10 else sc.t:=size;
       if size>0 then
       begin
          if lasttop<>top then showaccounts else
          if laston<>bbson then singleaccount;
       end;
       if ldate<>date then
       begin
          fwrite(date,20,52,attr(lightgray,black));
          ldate:=date;
       end;
       laston:=bbson;
       showmouse;
       with rat do
       repeat
           mouseposition(rat);
           if (mx>=sc.x) and (mx<=sc.x+sc.s-1) and (my>=sc.y) and (my<=sc.y+sc.t-1) then
           begin
              mousepress(rightbutton,rat);
              if stat=leftpress then bbson:=my-sc.y+top;
              if (stat=rightpress) and (rat.pcount=1) then
              begin
                 bbson:=my-sc.y+top;
                 tagbbs;
                 bbson:=my-sc.y+top;
                 ch:=#1;
              end;
              mousepress(leftbutton,rat);
              if (my=lastpy) and (abs(clocktick-clocktemp)<twoclickdelay) and (pcount=1) then
              begin
                 hidemouse;
                 dial;
                 showmouse;
              end;
              if pcount=1 then clocktemp:=clocktick;
           end else
           if (lastpx>=sc.x) and (lastpx<=sc.x+sc.s-1) and (stat=leftpress) and
              (lastpy>=sc.y) and (lastpy<=sc.y+sc.t-1) then
           begin
              if (my<sc.y) then
              begin
                 dirup:=true;
                 dec(bbson);
                 delay(200);
              end else
              if (my>sc.y+sc.t-1) then
              begin
                 dirup:=false;
                 inc(bbson);
                 delay(200);
              end;
              adjustpos;
           end else
           if stat=rightpress then
           begin
              mousepress(rightbutton,rat);
              if rat.pcount=1 then ch:=#27;
           end;
           if timetemp<>time(1) then
           begin
              fwrite(time(1),timestat.y,timestat.x,timestat.colr);
              timetemp:=time(1);
           end;
       until (laston<>bbson) or (keypressed) or (ch<>#0) or (newcarrier);
       if keypressed then
       begin
          hidemouse;
          ch:=upcase(readkb);
          if ch=#0 then key_alt else
             case ch of
                #13: dial;
                '1'..
                '9': dialbbs;
                'A': add;
                'C': ldcodes;
                'E': entryedit;
                'F': findbbs(false);
                'K': kill;
                'N': newdir;
                'R': redial;
                'T': conv2text;
                '/': findbbs(true);
                ' ': tagbbs;
             end;
       end;
   until (ch=#27) or (newcarrier);
   hidemouse;
   gotoxy(wx,wy);
   timestat.flag:=0;
   for wx:=1 to size do
   if markcheck[wx]<>bbses[wx].flag then
   begin
      markcheck[wx]:=bbses[wx].flag;
      seek(filehandle,wx-1);
      blockread(filehandle,dialdata,1,tempi);
      seek(filehandle,wx-1);
      dialdata.redialflag:=markcheck[wx];
      blockwrite(filehandle,dialdata,1);
   end;
   if connected then wx:=dialnumber else wx:=bbson;
   if wx in [1..size] then
   begin
      seek(filehandle,wx-1);
      blockread(filehandle,dialdata,1,tempi);
      assignbbs(wx);
   end;
   if newcarrier then
   begin
      dcebps:=bbses[bbson].carrierbps;
      color(7,0);
      clrscr;
   end else savevideo(videoback,false);
   close(filehandle);
   cursor(true);
   statusbar;
   lastsize:=size;
   dispose(fielddesc);
   dispose(video);
end;

end.
