unit z_misc;

interface
{$F+,O+}

procedure bbsstripper;
procedure userinfo;
procedure emailbook;
procedure sendhistory;

implementation

uses crt,dos,z_util,z_mouse,z_comio;

procedure bbsstripper;
type temptype=record
        ifile,ofile: stringdesc;
        datavail,apend: boolean;
        xphone,lphone,
        xname,lname: word;
     end;
     zlocaltype= array[1..100] of string[90];
var c,on,ncolr,ecolr,lo,maxlines,tempi: byte;
    tfile,t2file: text;
    line,phonestring: string;
    tempstr,compstr: stringname;
    ac,px: string[3];
    ch: char;
    leave,local: boolean;
    temp: ^temptype;
    zlocal: ^zlocaltype;

   procedure writeyn(x,y: byte; b: boolean);
   begin
      if b then fwrite('Yes',y,x,ncolr) else fwrite('No ',y,x,ncolr);
   end;
   procedure writest(x,y,size: byte; st: string);
   begin
      st:=copy(st,1,size);
      fwrite(st+blanks(size-length(st)),y,x,ncolr);
   end;

   function getnum(x,y,size: byte; num: word): word;
   var s: string[5];
       c,i: word;
       o: byte;
   begin
      s:=its(num);
      o:=length(s)+1;
      editflag(0,0,0,1,0,0,0);
      if input(ecolr,x,y,s,size,size,o)=' ' then;
      val(s,i,c);
      if c=0 then getnum:=i else getnum:=num;
   end;
   function sp(s: stringname): stringname;
   var t: stringname;
       i: byte;
   begin
      t:='';
      for i:=1 to length(s) do
         if (s[i]>#47) and (s[i]<#58) then t:=t+s[i];
      sp:=t;
   end;
begin
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   new(temp);
   new(zlocal);
   on:=2;
   ncolr:=attr(white,black);
   ecolr:=hattr(white,blue);
   leave:=false;
   with temp^ do
   begin
      ifile:='c:\zygote\bbslist.lst';
      ofile:='temp\bbslist.zyg';
      datavail:=exist(dir_areadata+'\z_local.dat');
      apend:=false;
      xphone:=1;
      lphone:=16;
      xname:=18;
      lname:=23;
   end;
   page.flag:=0;
   timestat.flag:=0;
   sc.x:=2; sc.y:=2;
   sc.s:=33;
   sc.t:=9;
   sc.c:=hattr(black,lightgray);
   sc.nc:=attr(lightcyan,black);
   c:=attr(lightblue,black);
   makebox(7,1,1,80,25,5);
   makebox(c,1,1,80,11,1);
   fwrite(chars('Ä',80),12,1,c);
   fwrite(chars('Ä',80),25,1,c);
   fwrite('Â',1,35,c);
   fwrite('Á',11,35,c);
   vertchars(c,35,2,10,'³');
   c:=attr(lightgray,black);
   fwrite('This function reads a text-formated file containing the names and phone numbers',13,1,c);
   fwrite('of bulletin board systems, and strips from it all the systems that are local to',14,1,c);
   fwrite('your calling area. Local-call determination is done via the information stored',15,1,c);
   fwrite('in your Z_LOCAL.DAT file. If you haven''t created this file for yourself, please',16,1,c);
   fwrite('read the documentation file now. The output will be stored in the BBSLIST.ZYG',17,1,c);
   fwrite('file, which will be placed in the TEMP directory. This TEMP directory resides',18,1,c);
   fwrite('off of your Zygote directory (i.e C:\ZYGOTE\TEMP). Note that this function',19,1,c);
   fwrite('will not work if you do not have the Z_LOCAL.DAT file installed on your',20,1,c);
   fwrite('system. The format of the output file BBSLIST.ZYG will also be in text format.',21,1,c);
   fwrite('You can use a text editor to view it, or DOS-command TYPE. Also remember to',22,1,c);
   fwrite('specify the area code that you are calling from in the system configuration,',23,1,c);
   fwrite('which is Alt-O from the terminal mode.',24,1,c);
   c:=attr(lightcyan,black);
   fwrite('START',2,16,attr(yellow,black));
   fwrite('Input file',3,3,c);
   fwrite('Column location of phone number',4,3,c);
   fwrite('Length of phone number',5,3,c);
   fwrite('Column location of name field',6,3,c);
   fwrite('Length of name field',7,3,c);
   fwrite('Output file',8,3,c);
   fwrite('Z_LOCAL.DAT available',9,3,c);
   fwrite('Append to output file',10,3,c);
   editflag(1,1,0,1,0,0,1);
   repeat
      writest(37,3,40,temp^.ifile);
      writest(37,4,2,its(temp^.xphone));
      writest(37,5,2,its(temp^.lphone));
      writest(37,6,2,its(temp^.xname));
      writest(37,7,2,its(temp^.lname));
      writest(37,8,40,temp^.ofile);
      writeyn(37,9,temp^.datavail);
      writeyn(37,10,temp^.apend);
      lo:=0;
      ch:=scrollchoice(#27+#13,on);
      if ch=#13 then
      with temp^ do
      case on of
         1: if datavail then
            begin
               if exist(ifile) then
               begin
                  assign(tfile,dir_areadata+'\z_local.dat');
                  reset(tfile);
                  maxlines:=0;
                  while not eof(tfile) do
                  begin
                     inc(maxlines);
                     readln(tfile,zlocal^[maxlines]);
                  end;
                  close(tfile);
                  window(1,13,80,24);
                  color(lightgray,black);
                  clrscr;

                  assign(tfile,ifile);
                  reset(tfile);

                  assign(t2file,ofile);
                  if (not exist(ofile)) or (not apend) then rewrite(t2file) else
                     append(t2file);

                  while not eof(tfile) do
                  begin
                     readln(tfile,line);
                     phonestring:=sp(copy(line,xphone,lphone));
                     if length(phonestring)<7 then
                     begin
                        ac:='000';
                        px:='000';
                     end else
                     if phonestring[1]='1' then
                     begin
                        ac:=copy(phonestring,2,3);
                        px:=copy(phonestring,5,3);
                     end else
                     if length(phonestring)>7 then
                     begin
                        ac:=copy(phonestring,1,3);
                        px:=copy(phonestring,4,3);
                     end else
                     begin
                        ac:=configdata.areacode;
                        px:=copy(phonestring,1,3);
                     end;

                     local:= ac='800';
                     tempstr:='';
                     compstr:=configdata.areacode+','+ac;
                     tempi:=1;
                     while (not local) and (tempi<=maxlines) do
                     begin
                        if pos('AC ',caps(zlocal^[tempi]))=1 then
                           tempstr:=copy(zlocal^[tempi],4,7) else
                           begin
                              if (tempstr=compstr) and (pos(px,zlocal^[tempi])>0) then local:=true;
                           end;
                        inc(tempi);
                     end;
                     if local then
                     begin
                        if length(phonestring)=10 then phonestring:='1'+phonestring;
                        case length(phonestring) of
                           7: insert('-',phonestring,4);
                          11: begin
                                 insert('-',phonestring,2);
                                 insert('-',phonestring,6);
                                 insert('-',phonestring,10);
                              end;
                        end;
                        writeln(copy(line,1,79));
                        writeln(t2file,blanks(14-length(phonestring))+phonestring+'   '+copy(line,xname,lname));
                     end;
                  end;

                  close(tfile);
                  close(t2file);
               end else showmsg('Could not locate the','specified input file');
            end else showmsg('You are missing','AREADATA\Z_LOCAL.DAT');
         2: begin
               editflag(1,1,0,1,0,0,1);
               if input(ecolr,37,3,ifile,40,40,lo)=#0 then;
            end;
         3: xphone:=getnum(37,4,2,xphone);
         4: lphone:=getnum(37,5,2,lphone);
         5: xname:=getnum(37,6,2,xname);
         6: lname:=getnum(37,7,2,lname);
         9: apend:=not apend;
      end else leave:=true;
   until leave;
   window(1,1,80,25);
   gotoxy(wx,wy);
   savevideo(videoback,false);
   statusbar;
   dispose(temp);
   dispose(zlocal);
   cursor(true);
end;

procedure userinfo;
var c,on: byte;
    ch: char;
begin
   if connected then
   begin
      savevideo(videoback,true);
      wx:=wherex; wy:=wherey;
      cursor(false);
      makebox(attr(lightblue,black),1,1,64,17,1);
      fwritena('´                  Ã',1,42); fwrite(' User information ',1,43,attr(white,cyan));
      fwrite(dialdata.bbsname,2,3,attr(yellow,black));
      c:=attr(lightcyan,black);
      with dparam do fwrite(its(speed)+parity+its(dbit)+its(sbit),3,3,attr(cyan,black));
      fwrite('DCE@'+its(dcebps),3,12,attr(lightgray,black));
      fwrite('Use arrow keys to select, Enter to send to modem, Esc to exit',16,3,attr(lightgray,black));
      changeattr(11,16,7,c); changeattr(5,16,29,c); changeattr(3,16,53,c);
      c:=attr(white,black);
      fwrite('%Ua User login',5,3,c);
      fwrite('%Ub User password',6,3,c);
      fwrite('%Uc User LFD',7,3,c);
      fwrite('%Ud Comment',8,3,c);
      fwrite('%Ue Birthdate',9,3,c);
      fwrite('%Uf Real name',10,3,c);
      fwrite('%Ug Home phone',11,3,c);
      fwrite('%Uh Data phone',12,3,c);
      fwrite('%Ui Address',13,3,c);
      fwrite('%Uj City, state',14,3,c);
      c:=attr(lightgray,black);
      for ch:='a' to 'j' do
      begin
         if (ch='b') and (not configdata.showpwd) then
            fwrite(chars('þ',length(dialdata.user.password)),6,23,c) else
                fwrite(ct('%U'+ch,''),5+ord(ch)-ord('a'),23,c);
      end;
      on:=1;
      page.flag:=0;
      timestat.flag:=0;
      sc.x:=23; sc.y:=5;
      sc.s:=40;
      sc.t:=10;
      sc.c:=hattr(white,blue);
      sc.nc:=attr(lightgray,black);
      ch:=scrollchoice(#13+#27,on);
      if ch=#13 then send(ct('%U'+chr(96+on),'')+'^M');
      savevideo(videoback,false);
      gotoxy(wx,wy);
      cursor(true);
   end else showmsg('You are not online via','the dialing menu');
end;

procedure emailbook;
const listsize = 50;
type listrecord = record
        name: string[20];
        addr: array[1..2] of string[35];
        comment: string[35];
        phone: string[16];
        emaddr: string[55];
     end;
     temp = array[1..listsize] of listrecord;
var i,ncolr,b,y: byte;
    rat: mousetype;
    top,bottom,on,laston,numofentries: integer;
    list: ^temp;
    out,eflag: boolean;
    ch: char;

   procedure writest(x,y,size: byte; st: string);
   begin
      st:=copy(st,1,size);
      fwrite(st+blanks(size-length(st)),y,x,ncolr);
   end;

   procedure QSort;
   var pivot: string;
     procedure switch(var a,b: listrecord);
     var c: listrecord;
     begin
        c:=a; a:=b; b:=c;
     end;
     procedure Sort(L,R : integer);
     var I,J: word;
     begin
        I:=L;
        J:=R;
        pivot:=caps(list^[(I+J) div 2].name);
        repeat
           while caps(list^[I].name)<pivot do inc(I);
           while caps(list^[J].name)>pivot do dec(J);
           if I<=J then
           begin
              switch(list^[I],list^[J]);
              Inc(I);
              Dec(J);
           end;
        until I>J;
        if L<J then Sort(L,J);
        if I<R then Sort(I,R);
     end;
   begin
      sort(1,numofentries);
   end;

   procedure openfile(open: boolean);
   const efname='ZYGOTE.EAB';
   var c: char;
       i,l: integer;
       filehandle: file;
   begin
      if open then
      begin
         on:=1;
         top:=1;
         bottom:=10;
         fillchar(list^,sizeof(list^),0);
         if exist(efname) then
         begin
            {$I-}
            assign(filehandle,efname);
            reset(filehandle,sizeof(listrecord));
            if ioresult=0 then
            begin
               i:=filesize(filehandle);
               if i=0 then close(filehandle);
            end else i:=0;
         end else i:=0;
         if i>0 then
         begin
            numofentries:=filesize(filehandle);
            for l:=1 to numofentries do
               blockread(filehandle,list^[l],1,i);
            qsort;
            close(filehandle);
         end else
         with list^[1] do
         begin
            name:='Name';
            comment:='Valid before June 1996';
            addr[1]:='Address';
            addr[2]:='Address';
            emaddr:='n/a';
            phone:='n/a';
         end;
      end else
      begin
         {$I-}
         assign(filehandle,efname);
         rewrite(filehandle,sizeof(listrecord));
         for i:=1 to listsize do
           if length(list^[i].name)>0 then blockwrite(filehandle,list^[i],1);
         close(filehandle);
         if ioresult=0 then;
      end;
      {$I+}
   end;

   procedure adjust;
   begin
      if on<1 then on:=1 else if on>listsize then on:=listsize;
      if on<top then top:=on else if on>bottom then top:=on-9;
      if top<1 then top:=1;
      bottom:=top+9;
      if bottom>listsize then bottom:=listsize;
   end;

begin
   hidemouse;
   new(list);
   out:=false;
   eflag:=false;
   ncolr:=attr(lightgray,black);
   wx:=wherex; wy:=wherey;
   savevideo(videoback,true);
   makebox(attr(lightblue,black),1,1,80,12,1);
   fwrite(chars('Ä',80),14,1,attr(lightblue,black));
   fwrite('(Enter) to send Email Addr (Alt-E)dit account'+
          ' (Alt-D)ial phone number (Esc) exit',13,1,attr(cyan,black));
   i:=attr(lightcyan,black);
   changeattr(5,13,2,i); changeattr(5,13,29,i);
   changeattr(5,13,48,i); changeattr(3,13,72,i);
   fwritena('Â',1,22); fwritena('Á',12,22); vertchars(attr(lightblue,black),22,2,11,'³');
   i:=attr(white,black);
   fwrite('Address:',2,24,i);
   fwrite('Comment:',4,24,i);
   fwrite('Phone number:',5,24,i);
   fwrite('Email address',10,24,attr(lightgreen,black));
   editflag(1,1,1,1,1,0,1);
   openfile(true);
   cursor(false);
   sc.x:=2; sc.y:=2;
   sc.s:=20; sc.t:=10;
   setmouseposition(sc.x+sc.s div 2,sc.y);
   repeat
      hidemouse;
      y:=2;
      for i:=top to bottom do
      begin
         if i=on then b:=hattr(white,blue) else b:=attr(lightgray,black);
         fwrite(list^[i].name+blanks(20-length(list^[i].name)),y,2,b);
         inc(y);
      end;
      writest(33,2,35,list^[on].addr[1]);
      writest(33,3,35,list^[on].addr[2]);
      writest(33,4,35,list^[on].comment);
      writest(38,5,16,list^[on].phone);
      writest(24,11,55,list^[on].emaddr);
      showmouse;
      laston:=on;
      with rat do
      repeat
         mouseposition(rat);
         if (mx>=sc.x) and (mx<=sc.x+sc.s-1) and (my>=sc.y) and (my<=sc.y+sc.t-1) then
         begin
            if stat=leftpress then on:=my-sc.y+top;
            mousepress(leftbutton,rat);
            if (my=lastpy) and (abs(clocktick-clocktemp)<twoclickdelay) and (pcount=1) then
            begin
               send(list^[on].emaddr);
               out:=true;
            end;
            if pcount=1 then clocktemp:=clocktick;
         end else
         if (lastpx>=sc.x) and (lastpx<=sc.x+sc.s-1) and (stat=leftpress) and
            (lastpy>=sc.y) and (lastpy<=sc.y+sc.t-1) then
         begin
            if (my<sc.y) then
            begin
               dec(on);
               delay(200);
            end else
            if (my>sc.y+sc.t-1) then
            begin
               inc(on);
               delay(200);
            end;
            adjust;
         end;
         if stat=rightpress then
         begin
            mousepress(rightbutton,rat);
            out:=rat.pcount=1;
         end;
      until (keypressed) or (out) or (laston<>on);
      if keypressed then
      begin
         ch:=upcase(readkey);
         if ch=#0 then
         begin
            ch:=readkey;
            case ch of
               #32: begin
                       send('ATDT'+list^[on].phone+#13);
                       out:=true;
                    end;
               #18: begin
                       i:=0;
                       eflag:=true;
                       b:=hattr(white,cyan);
                       cursor(true);
                       if input(b,2,on-top+2,list^[on].name,20,20,i)=#0 then; i:=0;
                       if input(b,33,2,list^[on].addr[1],35,35,i)=#0 then; i:=0;
                          writest(33,2,35,list^[on].addr[1]);
                       if input(b,33,3,list^[on].addr[2],35,35,i)=#0 then; i:=0;
                          writest(33,3,35,list^[on].addr[2]);
                       if input(b,33,4,list^[on].comment,35,35,i)=#0 then; i:=0;
                          writest(33,4,35,list^[on].comment);
                       if input(b,38,5,list^[on].phone,16,16,i)=#0 then; i:=0;
                          writest(38,5,16,list^[on].phone);
                       if input(b,24,11,list^[on].emaddr,55,55,i)=#0 then;
                          writest(24,11,55,list^[on].emaddr);
                       cursor(false);
                     end;
                #72: dec(on);
                #80: inc(on);
                #73: dec(on,5);
                #81: inc(on,5);
                #71: on:=1;
                #79: on:=listsize;
            end;
            adjust;
         end else
         case ch of
            #13: begin
                    send(list^[on].emaddr);
                    out:=true;
                 end;
            #27: out:=true;
            'A'..
            'Z': begin
                    for i:=1 to listsize do
                       if upcase(list^[i].name[1])=ch then on:=i;
                    adjust;
                 end;
         end;
      end;
   until out;
   hidemouse;
   if eflag then openfile(false);
   cursor(true);
   savevideo(videoback,false);
   gotoxy(wx,wy);
   dispose(list);
end;

procedure sendhistory;
begin
   _putstring(lastdata.grabbuffer[lastdata.ptr_buffer]);
   if keystatus(16) then
   begin
      inc(lastdata.ptr_buffer);
      if lastdata.ptr_buffer>10 then lastdata.ptr_buffer:=1;
      _put(13);
   end;
end;

end.
