{$B-,S-,R-,V-,D-,L-}
PROGRAM Tetris;

USES RunError, Crt, Graph, Mouse, Strings, Misc, Fade, BgiChr, Sys, Keyb, Screen, Graph3D, Music2, Dos;

CONST
  ESC     = #27;
  ENTER   = #13;
  SPACE   = #32;
  UP      = #72;
  DN      = #80;
  LT      = #75;
  RT      = #77;
  Home    = #71;
  kEnd    = #79; { END je rezervirana beseda }
  kDelete = #83; { Delete je Pascalova procedura }
  kInsert = #82; { -,,- }
  PgUP    = #73;
  PgDN    = #81;
  TAB     = #9;
  BkSPACE = #8;
  F1      = #59;
  F2      = #60;
  F3      = #61;
  F4      = #62;
  F5      = #63;
  F6      = #64;
  F7      = #65;
  F8      = #66;
  F9      = #67;
  F10     = #68;
  Testing = False;

  a=22;      { Sirina  kvadrata }
  PoljeX=12; { Sirina  polja    }
  PoljeY=21; { Dolzina polja    }

TYPE TSettings=RECORD { RECORD za shranjevanje nastavitev v datoteko }
  gLT,gRT,gDN,gUP,gNext,gLevel,gShoot: ARRAY [1..2] OF Char;
  HotgLT,HotgRT,HotgDN,HotgUP,HotgNext,HotgLevel,HotgShoot: ARRAY [1..2] OF Boolean;
  SoundOn,Grid,DisplayScore,DisplayRows,DisplayLevel,DisplayPlace,DisplayNext: Boolean;
  Keys,Mode,Level,Pattern,Language: Integer;
END;

TYPE THighScore=RECORD { RECORD za HighScore }
  Name : ARRAY [1..20] OF String[31];
  Score: ARRAY [1..20] OF LongInt;
END;

VAR Gd,Gm, { Za inicializacijo grafike }

  I,J,        { Stevca }
  X,Y,        { Koordinati lika }
  D,          { Sirina lika }
  Level,      { Trenutna stopnja v menuju }
  GameLevel,  { Trenutna stopnja v igri }
  Rot,        { Rotacija lika }
  Now,        { Zaporedna stevilka trenutnega lika }
  Next,       { Zaporedna stevilka naslednjega lika }
  Time,       { Cas, ki je parameter procedure delay (med padanjem lika),
  spreminja se v odvisnosti od Level }
  SpustY,     { Visina, s katere je bil vrzen lik - podatek za tocke }
  Mode,       { Ce je Mode 1, potem je trenutna igra Tetris, ce je 2 pa Pentix }
  Pattern,    { Trenutni vzorec }
  Keys,       { Nabora tipk sta lahko dva, ta spremenljivka oznacuje zaporedno st. nabora }
  NrHighScore,{ Zaporedna stevilka lestvice }
  Language,   { 1: SLO, 2: ANG }
  TempInt,
  OldGetPlace,
  CannonLine,  {vrstica, kjer je cev topa}
  DemoRot,     {katera rotacija je najboljsa za demo?}
  DemoX        {na kateri X naj vrze lik}
  : Integer;
  Score,      { Tocke }
  OldScore,   { OldScore rabimo pri povecevanju Level, ko Score preseze veckratnik
  stevila 5000 }
  Rows,        { Stevilo podrtih vrstic }
  Time1,       {cas pred zacetkom igre}
  Time2,        {cas ob koncu igre}
  StLikov    {stevilo pritisnjenih tipk med igro}
  : LongInt;
  Pod,       { Podatek o aktivnem liku }
  Temp,      { Spremenljivka, v katero se shrani zacasen podatek }
  Name,       { Ime igralca }
  DiffH, DiffM, DiffS  {razlika casov}
  : String;
  C: Char;
  gLT,gRT,gDN,gUP,gNext,gLevel,gShoot: ARRAY [1..2] OF Char; { Igralne tipke }
  HotgLT,HotgRT,HotgDN,HotgUP,HotgNext,HotgLevel,HotgShoot: ARRAY [1..2] OF Boolean; { Igralne tipke }
  Spust,     { Ali lik pada (Drop) }
  SoundOn,Grid,DisplayScore,DisplayRows,DisplayLevel,DisplayPlace,DisplayNext,
  GameDisplayNext,
  Shoot,    { TRUE, ce je bil lik enkrat ze prestreljen }
  CannonText, { TRUE, ce naj bo text prikazan }
  DemoMode   {TRUE, ce igra racunalnik}
  : Boolean;
  Settings: TSettings;
  HighScore,EmptyHighScore: THighScore;
  TempHighScore: ARRAY [1..20] OF LongInt;
  { Polje je na vsaki strani po X in na spodnji strani Y, za 1 vecje zaradi robov}
  Polje: ARRAY [0..PoljeX+1,1..PoljeY+1] OF Integer;
  { Liki TETRISA }
  Lik1: ARRAY [1..7,1..4] OF String;
  { Liki PENTIXA }
  Lik2: ARRAY [1..17,1..4] OF String;
  { Za GetImage & PutImage }
  Size: Word;
  { Za GetImage & PutImage }
  P: ARRAY [0..11] OF Pointer;
  { V OldPatette shranimo trenutno paleto }
  OldPalette: PaletteType;
  Mesto: ARRAY [1..20] OF Byte;


LABEL Start;

CONST  gseg : word = $a000;
  spd = 2; size = 3; curve = 125;
  xmax = 231 div size;
  ymax = 150 div size;
  sofs = 50; samp = 10; slen = 255;

VAR stab : array[0..slen] of word;
  Alpha,xp,yp,i: Integer;
  Line1: ARRAY [1..150] OF String;

procedure csin; var i : byte; begin
  for I := 0 to slen do stab[i] := round(sin(i*4*pi/slen)*samp)+sofs; end;

procedure displaymap;
type scrarray = array[0..xmax,0..ymax] of byte;
var
  postab : array[0..xmax,0..ymax] of word;
  bitmap : scrarray;
  x,y,xp,yp,sidx : word;
begin
  fillchar(bitmap,sizeof(bitmap),0);
  sidx := 0;
  for y := 0 to (ymax div 3) do
      for x := 0 to xmax do bitmap[x,y] := Blue;
  for y := (ymax div 3) to 2*(ymax div 3) do
      for x := 0 to xmax do bitmap[x,y] := White;
  for y := 2*(ymax div 3) to ymax do
      for x := 0 to xmax do bitmap[x,y] := Red;
  bitmap[39,13]:=Red;bitmap[40,13]:=Red;bitmap[38,14]:=Red;bitmap[39,14]:=Red;
  bitmap[40,14]:=Red;bitmap[41,14]:=Red;bitmap[37,15]:=Red;bitmap[38,15]:=Red;
  bitmap[39,15]:=Red;bitmap[40,15]:=Red;bitmap[41,15]:=Red;bitmap[42,15]:=Red;
  bitmap[36,16]:=Red;bitmap[37,16]:=Red;bitmap[38,16]:=Red;bitmap[39,16]:=Red;
  bitmap[40,16]:=Red;bitmap[41,16]:=Red;bitmap[42,16]:=Red;bitmap[43,16]:=Red;
  bitmap[35,17]:=Red;bitmap[36,17]:=Red;bitmap[37,17]:=Red;bitmap[38,17]:=Red;
  bitmap[39,17]:=Red;bitmap[40,17]:=Red;bitmap[41,17]:=Red;bitmap[42,17]:=Red;
  bitmap[43,17]:=Red;bitmap[44,17]:=Red;bitmap[34,18]:=Red;bitmap[35,18]:=Red;
  bitmap[36,18]:=Red;bitmap[37,18]:=Red;bitmap[38,18]:=Red;bitmap[39,18]:=Red;
  bitmap[40,18]:=Red;bitmap[41,18]:=Red;bitmap[42,18]:=Red;bitmap[43,18]:=Red;
  bitmap[44,18]:=Red;bitmap[45,18]:=Red;bitmap[25,19]:=Red;bitmap[26,19]:=Red;
  bitmap[27,19]:=Red;bitmap[28,19]:=Red;bitmap[29,19]:=Red;bitmap[30,19]:=Red;
  bitmap[31,19]:=Red;bitmap[32,19]:=Red;bitmap[33,19]:=Red;bitmap[34,19]:=Red;
  bitmap[35,19]:=Red;bitmap[36,19]:=Red;bitmap[37,19]:=Red;bitmap[38,19]:=Red;
  bitmap[39,19]:=Red;bitmap[40,19]:=Red;bitmap[41,19]:=Red;bitmap[42,19]:=Red;
  bitmap[43,19]:=Red;bitmap[44,19]:=Red;bitmap[45,19]:=Red;bitmap[46,19]:=Red;
  bitmap[47,19]:=Red;bitmap[48,19]:=Red;bitmap[49,19]:=Red;bitmap[50,19]:=Red;
  bitmap[51,19]:=Red;bitmap[52,19]:=Red;bitmap[53,19]:=Red;bitmap[54,19]:=Red;
  bitmap[26,20]:=Red;bitmap[27,20]:=Red;bitmap[28,20]:=Red;bitmap[29,20]:=Red;
  bitmap[30,20]:=Red;bitmap[31,20]:=Red;bitmap[32,20]:=Red;bitmap[33,20]:=Red;
  bitmap[34,20]:=Red;bitmap[35,20]:=Red;bitmap[36,20]:=Red;bitmap[37,20]:=Red;
  bitmap[38,20]:=Red;bitmap[39,20]:=Red;bitmap[40,20]:=Red;bitmap[41,20]:=Red;
  bitmap[42,20]:=Red;bitmap[43,20]:=Red;bitmap[44,20]:=Red;bitmap[45,20]:=Red;
  bitmap[46,20]:=Red;bitmap[47,20]:=Red;bitmap[48,20]:=Red;bitmap[49,20]:=Red;
  bitmap[50,20]:=Red;bitmap[51,20]:=Red;bitmap[52,20]:=Red;bitmap[53,20]:=Red;
  bitmap[27,21]:=Red;bitmap[28,21]:=Red;bitmap[29,21]:=Red;bitmap[30,21]:=Red;
  bitmap[31,21]:=Red;bitmap[32,21]:=Red;bitmap[33,21]:=Red;bitmap[34,21]:=Red;
  bitmap[35,21]:=Red;bitmap[36,21]:=Red;bitmap[37,21]:=Red;bitmap[38,21]:=Red;
  bitmap[39,21]:=Red;bitmap[40,21]:=Red;bitmap[41,21]:=Red;bitmap[42,21]:=Red;
  bitmap[43,21]:=Red;bitmap[44,21]:=Red;bitmap[45,21]:=Red;bitmap[46,21]:=Red;
  bitmap[47,21]:=Red;bitmap[48,21]:=Red;bitmap[49,21]:=Red;bitmap[50,21]:=Red;
  bitmap[51,21]:=Red;bitmap[52,21]:=Red;bitmap[29,22]:=Red;bitmap[30,22]:=Red;
  bitmap[31,22]:=Red;bitmap[32,22]:=Red;bitmap[33,22]:=Red;bitmap[34,22]:=Red;
  bitmap[35,22]:=Red;bitmap[36,22]:=Red;bitmap[37,22]:=Red;bitmap[38,22]:=Red;
  bitmap[39,22]:=Red;bitmap[40,22]:=Red;bitmap[41,22]:=Red;bitmap[42,22]:=Red;
  bitmap[43,22]:=Red;bitmap[44,22]:=Red;bitmap[45,22]:=Red;bitmap[46,22]:=Red;
  bitmap[47,22]:=Red;bitmap[48,22]:=Red;bitmap[49,22]:=Red;bitmap[50,22]:=Red;
  bitmap[30,23]:=Red;bitmap[31,23]:=Red;bitmap[32,23]:=Red;bitmap[33,23]:=Red;
  bitmap[34,23]:=Red;bitmap[35,23]:=Red;bitmap[36,23]:=Red;bitmap[37,23]:=Red;
  bitmap[38,23]:=Red;bitmap[39,23]:=Red;bitmap[40,23]:=Red;bitmap[41,23]:=Red;
  bitmap[42,23]:=Red;bitmap[43,23]:=Red;bitmap[44,23]:=Red;bitmap[45,23]:=Red;
  bitmap[46,23]:=Red;bitmap[47,23]:=Red;bitmap[48,23]:=Red;bitmap[49,23]:=Red;
  bitmap[31,24]:=Red;bitmap[32,24]:=Red;bitmap[33,24]:=Red;bitmap[34,24]:=Red;
  bitmap[35,24]:=Red;bitmap[36,24]:=Red;bitmap[37,24]:=Red;bitmap[38,24]:=Red;
  bitmap[39,24]:=Red;bitmap[40,24]:=Red;bitmap[41,24]:=Red;bitmap[42,24]:=Red;
  bitmap[43,24]:=Red;bitmap[44,24]:=Red;bitmap[45,24]:=Red;bitmap[46,24]:=Red;
  bitmap[47,24]:=Red;bitmap[48,24]:=Red;bitmap[32,25]:=Red;bitmap[33,25]:=Red;
  bitmap[34,25]:=Red;bitmap[35,25]:=Red;bitmap[36,25]:=Red;bitmap[37,25]:=Red;
  bitmap[38,25]:=Red;bitmap[39,25]:=Red;bitmap[40,25]:=Red;bitmap[41,25]:=Red;
  bitmap[42,25]:=Red;bitmap[43,25]:=Red;bitmap[44,25]:=Red;bitmap[45,25]:=Red;
  bitmap[46,25]:=Red;bitmap[47,25]:=Red;bitmap[33,26]:=Red;bitmap[34,26]:=Red;
  bitmap[35,26]:=Red;bitmap[36,26]:=Red;bitmap[37,26]:=Red;bitmap[38,26]:=Red;
  bitmap[39,26]:=Red;bitmap[40,26]:=Red;bitmap[41,26]:=Red;bitmap[42,26]:=Red;
  bitmap[43,26]:=Red;bitmap[44,26]:=Red;bitmap[45,26]:=Red;bitmap[46,26]:=Red;
  bitmap[32,27]:=Red;bitmap[33,27]:=Red;bitmap[34,27]:=Red;bitmap[35,27]:=Red;
  bitmap[36,27]:=Red;bitmap[37,27]:=Red;bitmap[38,27]:=Red;bitmap[39,27]:=Red;
  bitmap[40,27]:=Red;bitmap[41,27]:=Red;bitmap[42,27]:=Red;bitmap[43,27]:=Red;
  bitmap[44,27]:=Red;bitmap[45,27]:=Red;bitmap[46,27]:=Red;bitmap[47,27]:=Red;
  bitmap[31,28]:=Red;bitmap[32,28]:=Red;bitmap[33,28]:=Red;bitmap[34,28]:=Red;
  bitmap[35,28]:=Red;bitmap[36,28]:=Red;bitmap[37,28]:=Red;bitmap[38,28]:=Red;
  bitmap[39,28]:=Red;bitmap[40,28]:=Red;bitmap[41,28]:=Red;bitmap[42,28]:=Red;
  bitmap[43,28]:=Red;bitmap[44,28]:=Red;bitmap[45,28]:=Red;bitmap[46,28]:=Red;
  bitmap[47,28]:=Red;bitmap[48,28]:=Red;bitmap[30,29]:=Red;bitmap[31,29]:=Red;
  bitmap[32,29]:=Red;bitmap[33,29]:=Red;bitmap[34,29]:=Red;bitmap[35,29]:=Red;
  bitmap[36,29]:=Red;bitmap[37,29]:=Red;bitmap[38,29]:=Red;bitmap[41,29]:=Red;
  bitmap[42,29]:=Red;bitmap[43,29]:=Red;bitmap[44,29]:=Red;bitmap[45,29]:=Red;
  bitmap[46,29]:=Red;bitmap[47,29]:=Red;bitmap[48,29]:=Red;bitmap[49,29]:=Red;
  bitmap[29,30]:=Red;bitmap[30,30]:=Red;bitmap[31,30]:=Red;bitmap[32,30]:=Red;
  bitmap[35,30]:=Red;bitmap[36,30]:=Red;bitmap[37,30]:=Red;bitmap[42,30]:=Red;
  bitmap[43,30]:=Red;bitmap[44,30]:=Red;bitmap[45,30]:=Red;bitmap[46,30]:=Red;
  bitmap[47,30]:=Red;bitmap[48,30]:=Red;bitmap[49,30]:=Red;bitmap[50,30]:=Red;
  bitmap[28,31]:=Red;bitmap[29,31]:=Red;bitmap[30,31]:=Red;bitmap[31,31]:=Red;
  bitmap[32,31]:=Red;bitmap[33,31]:=Red;bitmap[34,31]:=Red;bitmap[35,31]:=Red;
  bitmap[36,31]:=Red;bitmap[43,31]:=Red;bitmap[44,31]:=Red;bitmap[45,31]:=Red;
  bitmap[46,31]:=Red;bitmap[47,31]:=Red;bitmap[48,31]:=Red;bitmap[49,31]:=Red;
  bitmap[50,31]:=Red;bitmap[51,31]:=Red;bitmap[27,32]:=Red;bitmap[28,32]:=Red;
  bitmap[29,32]:=Red;bitmap[30,32]:=Red;bitmap[31,32]:=Red;bitmap[32,32]:=Red;
  bitmap[33,32]:=Red;bitmap[46,32]:=Red;bitmap[47,32]:=Red;bitmap[48,32]:=Red;
  bitmap[49,32]:=Red;bitmap[50,32]:=Red;bitmap[51,32]:=Red;bitmap[52,32]:=Red;
  bitmap[28,33]:=Red;bitmap[29,33]:=Red;bitmap[30,33]:=Red;bitmap[31,33]:=Red;
  bitmap[48,33]:=Red;bitmap[49,33]:=Red;bitmap[50,33]:=Red;bitmap[51,33]:=Red;
  bitmap[33,30]:=Red;bitmap[34,30]:=Red;
  bitmap[39,13]:=Yellow;bitmap[40,13]:=Yellow;bitmap[38,14]:=Yellow;bitmap[41,14]:=Yellow;
  bitmap[37,15]:=Yellow;bitmap[42,15]:=Yellow;bitmap[36,16]:=Yellow;bitmap[43,16]:=Yellow;
  bitmap[35,17]:=Yellow;bitmap[44,17]:=Yellow;bitmap[34,18]:=Yellow;bitmap[45,18]:=Yellow;
  bitmap[25,19]:=Yellow;bitmap[26,19]:=Yellow;bitmap[27,19]:=Yellow;bitmap[28,19]:=Yellow;
  bitmap[29,19]:=Yellow;bitmap[30,19]:=Yellow;bitmap[31,19]:=Yellow;bitmap[32,19]:=Yellow;
  bitmap[33,19]:=Yellow;bitmap[46,19]:=Yellow;bitmap[47,19]:=Yellow;bitmap[48,19]:=Yellow;
  bitmap[49,19]:=Yellow;bitmap[50,19]:=Yellow;bitmap[51,19]:=Yellow;bitmap[52,19]:=Yellow;
  bitmap[53,19]:=Yellow;bitmap[54,19]:=Yellow;bitmap[26,20]:=Yellow;bitmap[53,20]:=Yellow;
  bitmap[27,21]:=Yellow;bitmap[28,21]:=Yellow;bitmap[51,21]:=Yellow;bitmap[52,21]:=Yellow;
  bitmap[29,22]:=Yellow;bitmap[50,22]:=Yellow;bitmap[30,23]:=Yellow;bitmap[49,23]:=Yellow;
  bitmap[31,24]:=Yellow;bitmap[48,24]:=Yellow;bitmap[32,25]:=Yellow;bitmap[33,25]:=Yellow;
  bitmap[46,25]:=Yellow;bitmap[47,25]:=Yellow;bitmap[33,26]:=Yellow;bitmap[46,26]:=Yellow;
  bitmap[32,27]:=Yellow;bitmap[47,27]:=Yellow;bitmap[31,28]:=Yellow;bitmap[39,28]:=Yellow;
  bitmap[40,28]:=Yellow;bitmap[48,28]:=Yellow;bitmap[30,29]:=Yellow;bitmap[38,29]:=Yellow;
  bitmap[41,29]:=Yellow;bitmap[49,29]:=Yellow;bitmap[29,30]:=Yellow;bitmap[37,30]:=Yellow;
  bitmap[42,30]:=Yellow;bitmap[50,30]:=Yellow;bitmap[28,31]:=Yellow;bitmap[34,31]:=Yellow;
  bitmap[35,31]:=Yellow;bitmap[36,31]:=Yellow;bitmap[43,31]:=Yellow;bitmap[44,31]:=Yellow;
  bitmap[45,31]:=Yellow;bitmap[51,31]:=Yellow;bitmap[27,32]:=Yellow;bitmap[32,32]:=Yellow;
  bitmap[33,32]:=Yellow;bitmap[46,32]:=Yellow;bitmap[47,32]:=Yellow;bitmap[52,32]:=Yellow;
  bitmap[28,33]:=Yellow;bitmap[29,33]:=Yellow;bitmap[30,33]:=Yellow;bitmap[31,33]:=Yellow;
  bitmap[48,33]:=Yellow;bitmap[49,33]:=Yellow;bitmap[50,33]:=Yellow;bitmap[51,33]:=Yellow;
  REPEAT
    WHILE (port[$3da] and 8) <> 0 do;
    while (port[$3da] and 8) = 0 do;
    for x := 0 to xmax do
      for y := ymax downto 0 do begin
        mem[gseg:postab[x,y]] := 0;
        xp := size*(x-1)+stab[(sidx+curve*x+curve*y) mod slen];
        yp := size*(y-8)+stab[(sidx+4*x+curve*y+y) mod slen];
        postab[x,y] := xp+yp*320;
        mem[gseg:postab[x,y]] := bitmap[x,y];
      end;
    sidx := (sidx+spd) mod slen;
  UNTIL (KeyPressed)OR(GetMouseButton<>0);
  IF KeyPressed THEN C:=Read_Key ELSE C:=ENTER;
end;

begin
  csin;
  asm mov ax,13h; int 10h; end;
  displaymap;
  textmode(lastmode);
  Gd:=Detect;
  InitGraph(Gd,Gm,'');
end;

PROCEDURE Rotiraj(Mode,N: Integer);FORWARD;
FUNCTION GetPlace: Integer;FORWARD;

Procedure OpenWhistle;
Var
  Frequency : Integer;
begin
  For Frequency := 500 to 1000 do
  begin
    Delay(1);
    Sound(Frequency)
  end;
  NoSound
end;

{************************************************************************}
FUNCTION GetKeyName(C: Char; HotKey: Boolean): String;
{vrne ime pritisnjene tipke}
BEGIN
  IF NOT(HotKey) THEN
  BEGIN
    IF C=ENTER THEN GetKeyName:='Enter' ELSE
      IF C=SPACE THEN GetKeyName:='Space' ELSE
        IF C=BkSPACE THEN GetKeyName:='Bk Space' ELSE
          IF C=TAB THEN GetKeyName:='Tab' ELSE
            GetKeyName:=UpString(C)
  END ELSE
    CASE C OF
      UP      : IF Language=2 THEN GetKeyName:='Up' ELSE GetKeyName:='Gor';
      DN      : IF Language=2 THEN GetKeyName:='Down' ELSE GetKeyName:='Dol';
      LT      : IF Language=2 THEN GetKeyName:='Left' ELSE GetKeyName:='Levo';
      RT      : IF Language=2 THEN GetKeyName:='Right' ELSE GetKeyName:='Desno';
      PgUP    : GetKeyName:='PgUp';
      PgDN    : GetKeyName:='PgDown';
      Home    : GetKeyName:='Home';
      kEnd    : GetKeyName:='End';
      kDelete : GetKeyName:='Delete';
      kInsert : GetKeyName:='Insert';
      F1      : GetKeyName:='F1';
      F2      : GetKeyName:='F2';
      F3      : GetKeyName:='F3';
      F4      : GetKeyName:='F4';
      F5      : GetKeyName:='F5';
      F6      : GetKeyName:='F6';
      F7      : GetKeyName:='F7';
      F8      : GetKeyName:='F8';
      F9      : GetKeyName:='F9';
      F10     : GetKeyName:='F10';
      ELSE GetKeyName:='Unknown Key';
    END;
END;

FUNCTION Timer: LongInt;
VAR H,M,S,S100: Word;
BEGIN
  GetTime(H,M,S,S100);
  Timer:=3600*H+60*M+S;
END;

PROCEDURE GetTimeDifference(Time1, Time2: LongInt);
VAR Sec: LongInt;
BEGIN
 IF Time2>=Time1 THEN Sec:=Time2-Time1 ELSE Sec:=86400-Time1+Time2;
 DiffH:=ToStrL(Sec DIV 3600);
 IF Length(DiffH)=1 THEN DiffH:='0'+DiffH;
 Sec:=Sec MOD 3600;
 DiffM:=ToStrL(Sec DIV 60);
 IF Length(DiffM)=1 THEN DiffM:='0'+DiffM;
 Sec:=Sec MOD 60;
 DiffS:=ToStrL(Sec);
 IF Length(DiffS)=1 THEN DiffS:='0'+DiffS;
END;

{************************************************************************}
PROCEDURE DrawKey(X,Y,Color: Word; C: Char);
{ Izpise tipko C - prepozna tudi vroce tipke}
BEGIN
  SetTextJustify(LeftText,TopText);
  IF Color<>-1 THEN SetColor(White) ELSE SetColor(LightGray); { Zbrise }
  OutTextXY(X,Y,GetKeyName(C,HotKey));
  IF Color<>-1 THEN SetColor(Color) ELSE SetColor(LightGray); { Zbrise }
  OutTextXY(X+1,Y+1,GetKeyName(C,HotKey));
  SetTextJustify(CenterText,CenterText);
END;

{************************************************************************}
PROCEDURE DrawCannonText(X,Y,Color: Word; C: Char; HotKey: Boolean);
{ Izpise tipko C - prepozna tudi vroce tipke}
BEGIN
  SetTextStyle(SmallFont,HorizDir,4);
  SetTextJustify(CenterText,TopText);
  SetColor(Color);
  IF Language=1 THEN
    OutTextXY(X+1,Y,'Pritisni tipko '+GetKeyName(C,HotKey)+' za strel') ELSE
      OutTextXY(X+1,Y,'Press '+GetKeyName(C,HotKey)+' key to shoot');
  SetTextJustify(LeftText,TopText);
END;

{***********************************************************************}
{***************************** InitShapes ******************************}
{***********************************************************************}
PROCEDURE InitShapes;
{ Definira like }
BEGIN
  { Nastavi 1. rotacijo posameznega lika }
  { TETRIS }
  Lik1[1,1]:='1110103';
  Lik1[2,1]:='0111103';
  Lik1[3,1]:='1100113';
  Lik1[4,1]:='11112';
  Lik1[5,1]:='001000010000100001005';Lik1[5,2]:='11114';
  Lik1[5,3]:='0010010010013';Lik1[5,4]:='11114';
  Lik1[6,1]:='1001113';
  Lik1[7,1]:='0011113';
  Rotiraj(1,1);Rotiraj(1,2);Rotiraj(1,3);
  Rotiraj(1,4);Rotiraj(1,6);Rotiraj(1,7);

  { PENTIX }
  Lik2[1,1]:='100011114';
  Lik2[2,1]:='000111114';
  Lik2[3,1]:='101110102';
  Lik2[4,1]:='011101012';
  Lik2[5,1]:='1110010013';
  Lik2[6,1]:='110001114';
  Lik2[7,1]:='011111004';
  Lik2[8,1]:='0101100113';
  Lik2[9,1]:='0100111103';
  Lik2[10,1]:='0101110103';
  Lik2[11,1]:='0110101103';
  Lik2[12,1]:='1100100113';
  Lik2[13,1]:='0100101113';
  Lik2[14,1]:='0111112';
  Lik2[15,1]:='1011112';
  Lik2[16,1]:='00100001000010000100001005';Lik2[16,2]:='111115';
  Lik2[16,3]:='0010010010010013';Lik2[16,4]:='111115';
  Lik2[17,1]:='1111013';
  Rotiraj(2,1);Rotiraj(2,2);Rotiraj(2,3);Rotiraj(2,4);Rotiraj(2,5);
  Rotiraj(2,6);Rotiraj(2,7);Rotiraj(2,8);Rotiraj(2,9);Rotiraj(2,10);
  Rotiraj(2,11);Rotiraj(2,12);Rotiraj(2,13);Rotiraj(2,14);Rotiraj(2,15);
  Rotiraj(2,17);
END;

{***********************************************************************}
{********************************* Init ********************************}
{***********************************************************************}
PROCEDURE Init;
{ Nastavi vse potrebno za zacetek programa }
VAR I: Integer;
BEGIN
  SetRateAndDelay(32,1);
  CheckBreak:=FALSE;
  Randomize;
  RegisterBGIDriver(@EgaVga);
  RegisterBGIFont(@Small);
  RegisterBGIFont(@Triplex);
  Gd:=Detect;
  InitGraph(Gd,Gm,'');
  GetPalette(OldPalette); { Trenutno paleto shranimo v spremenljivko OldPalette }
  FOR I:=1 TO GetMaxColor DO SetPalette(I,Black); { Vse barve spremenimo v crno }
  { V Pointer-e shrani vse kvadrate, za izris kvadratov likov (s PutImage)  }
  FOR I:=1 TO 11 DO
  BEGIN
    SetColor(Black);
    CASE I OF
      1:SetFillStyle(1,Black);
      2:SetFillStyle(1,Brown);
      3:SetFillStyle(1,Green);
      4:SetFillStyle(1,Blue);
      5:SetFillStyle(1,Cyan);
      6:SetFillStyle(1,Red);
      7:SetFillStyle(1,LightGray);
      8:SetFillStyle(1,Magenta);
      9:SetFillStyle(1,Yellow);
      10:SetFillStyle(1,DarkGray);
      11:SetFillStyle(1,Green);
    END;
    Bar((I-1)*(a+1)+1,1,(I-1)*(a+1)+(a-2)+1,a-1);
    IF I<>1 THEN
    BEGIN
      IF (I=7)OR(I=3)OR(I=5)OR(I=11) THEN SetColor(White) ELSE
        IF I=9 THEN SetColor(White) ELSE
          SetColor(LightGray);
      Line((I-1)*(a+1)+1,1,(I-1)*(a+1)+(a-2)+1,1);
      Line((I-1)*(a+1)+1,1,(I-1)*(a+1)+1,a-1);
    END;
    SetColor(Black);
    Line(10*(a+1)+1,1,10*(a+1)+(a-2)+1,a-1);
    Line(10*(a+1)+(a-2)+1,1,10*(a+1)+1,a-1);
    Size:=ImageSize((I-1)*(a+1),0,(I-1)*(a+1)+(a-2)+2,a);
    GetMem(P[I-1],Size);
    GetImage((I-1)*(a+1),0,(I-1)*(a+1)+(a-2)+2,a,P[I-1]^);
  END;

  { Krogla za top }
  SetColor(White);
  SetFillStyle(1,White);
  Bar(33,41,27+a,30+a);
  Arc(41,41,0,180,8);
  FloodFill(30+11,32+5,White);
  SetColor(Red);
  Circle(37,41,2);
  Circle(27+a-4,41,2);
  Line(33,41,33,30+a);
  Line(27+a,41,27+a,30+a);
  Line(33,30+a,27+a,30+a);
  Arc(41,41,0,180,8);
  SetFillStyle(1,Red);
  FloodFill(37,41,Red);
  FloodFill(27+a-4,41,Red);
  Arc(41,47,180,00,3);
  Size:=ImageSize(30,30,27+a,30+a);
  GetMem(P[11],Size);
  GetImage(30,30,27+a,30+a,P[11]^);
  ClearDevice;
  SetAllPalette(OldPalette); { Nastavimo staro (Default) paleto }
END;

{***********************************************************************}
{******************************** Stop *********************************}
{***********************************************************************}
PROCEDURE Stop;
{ Prekine izvajanje programa }
BEGIN
  ClearDevice;
  CloseGraph;
  TextBackground(Black);
  TextColor(LightGray);
  Halt(1);
END;

{***********************************************************************}
{******************************* Razcleni ******************************}
{***********************************************************************}
PROCEDURE Razcleni(S: String);
{ Postavi lik S za aktivnega }
BEGIN
  Pod:=Copy(S, 1, Length(S)-1);
  D:=ToInt(Copy(S, Length(S), 1));
END;

{***********************************************************************}
{******************************* Prosto ********************************}
{***********************************************************************}
FUNCTION Prosto(X,Y: Integer): Boolean;
{ Preveri, ce so polja, ki so potrebna za nek lik, ze zasedena }
VAR I: Integer;
BEGIN
  Prosto:=TRUE;
  FOR I:=1 TO Length(Pod) DO
  BEGIN
    IF I MOD D = 0 THEN
    BEGIN
      IF (Polje[X+D-1, Y+(I-1) DIV D]>0)AND(Pod[I]='1') THEN Prosto:=FALSE
    END ELSE
      IF (Polje[X+I MOD D - 1, Y+I DIV D]>0)AND(Pod[I]='1') THEN Prosto:=FALSE;
  END;
END;

{***********************************************************************}
{***************************** InitField *******************************}
{***********************************************************************}
PROCEDURE InitField;
{ Vsa polja, razen robov (ti so 1), postavi na 0
  Narise vzorce Pattern }
VAR X,Y: Integer;
BEGIN

  FOR X:=0 TO PoljeX+1 DO
    FOR Y:=1 TO PoljeY+1 DO
    BEGIN
      IF (X=0)OR(X=PoljeX+1)OR(Y=PoljeY+1) THEN Polje[X,Y]:=1 ELSE { Robovi }
        Polje[X,Y]:=0;
    END;

  CASE Pattern OF
    2: { Cannon }
    BEGIN
      FOR Y:=16 TO 21 DO
      BEGIN
        Polje[7,Y]:=1;
        PutImage(7*a-a+188,Y*a-a,P[10]^,NormalPut);
      END;
      Polje[5,21]:=1;
      PutImage(5*a-a+188,21*a-a,P[6]^,NormalPut);
      Polje[6,20]:=1;
      PutImage(6*a-a+188,20*a-a,P[1]^,NormalPut);
      Polje[8,20]:=1;
      PutImage(8*a-a+188,20*a-a,P[1]^,NormalPut);
      Polje[9,21]:=1;
      PutImage(9*a-a+188,21*a-a,P[6]^,NormalPut);
    END;
    3: { Castle }
    BEGIN
      FOR X:=1 TO 12 DO
        IF Odd(X) THEN
        BEGIN
          Polje[X,17]:=1;
          PutImage(X*a-a+188,17*a-a,P[3]^,NormalPut);
        END;
      FOR X:=1 TO 12 DO
        IF X MOD 4<>0 THEN
        BEGIN
          Polje[X,18]:=1;
          PutImage(X*a-a+188,18*a-a,P[3]^,NormalPut);
        END;
      FOR Y:=19 TO 21 DO
        FOR X:=1 TO 10 DO
          IF NOT(Odd(X)) THEN
          BEGIN
            Polje[X,Y]:=1;
            PutImage(X*a-a+188,Y*a-a,P[6]^,NormalPut);
          END;
    END;
    4: { Chess }
      FOR Y:=17 TO 21 DO
        FOR X:=1 TO 12 DO
          IF Odd(X+Y+1) THEN
          BEGIN
            Polje[X,Y]:=1;
            PutImage(X*a-a+188,Y*a-a,P[6]^,NormalPut); { White }
          END;
    5: { Columns }
      FOR Y:=18 TO 21 DO
        FOR X:=1 TO 12 DO
          IF Odd(X) THEN
          BEGIN
            Polje[X,Y]:=1;
            IF Odd(Y+Round(X/2)) THEN PutImage(X*a-a+188,Y*a-a,P[4]^,NormalPut) ELSE
              PutImage(X*a-a+188,Y*a-a,P[5]^,NormalPut)
          END;
    6: { Cross }
    BEGIN
      FOR Y:=16 TO 21 DO
      BEGIN
        Polje[6,Y]:=1;
        PutImage(6*a-a+188,Y*a-a,P[4]^,NormalPut);
        Polje[7,Y]:=1;
        PutImage(7*a-a+188,Y*a-a,P[4]^,NormalPut);
      END;
      FOR X:=4 TO 9 DO
      BEGIN
        Polje[X,18]:=1;
        PutImage(X*a-a+188,18*a-a,P[4]^,NormalPut);
        Polje[X,19]:=1;
        PutImage(X*a-a+188,19*a-a,P[4]^,NormalPut);
      END;
    END;
    7: { Diagonal }
    BEGIN
      FOR Y:=14 TO 19 DO
      BEGIN
        Polje[(Y-10),Y]:=1;
        PutImage((Y-10)*a-a+188,Y*a-a,P[5]^,NormalPut);
      END;
    END;
    8: { Diamond }
    BEGIN
      I:=-1;
      FOR Y:=15 TO 21 DO
      BEGIN
        IF Y<=18 THEN Inc(I) ELSE Dec(I);
        FOR X:=7-I TO 7+I DO
        BEGIN
          Polje[X,Y]:=1;
          IF (X=7-I)OR(X=7+I) THEN PutImage(X*a-a+188,Y*a-a,P[4]^,NormalPut) ELSE
            PutImage(X*a-a+188,Y*a-a,P[6]^,NormalPut)
        END;
      END;
    END;
    9: { Hat }
    BEGIN
      FOR X:=3 TO 10 DO
      BEGIN
        Polje[X,19]:=1;
        PutImage(X*a-a+188,19*a-a,P[6]^,NormalPut);
        IF (X>=5)AND(X<=8) THEN
        BEGIN
          Polje[X,21]:=1;
          PutImage(X*a-a+188,21*a-a,P[1]^,NormalPut);
        END;
      END;
      Polje[5,20]:=1;
      PutImage(5*a-a+188,20*a-a,P[1]^,NormalPut);
      Polje[8,20]:=1;
      PutImage(8*a-a+188,20*a-a,P[1]^,NormalPut);
    END;
    10: { Hill }
    BEGIN
      X:=6;
      FOR Y:=16 TO 21 DO
      BEGIN
        Inc(X);
        Polje[X,Y]:=1;
        PutImage(X*a-a+188,Y*a-a,P[2]^,NormalPut);
      END;
      X:=0;
      FOR Y:=21 DOWNTO 16 DO
      BEGIN
        Inc(X);
        Polje[X,Y]:=1;
        PutImage(X*a-a+188,Y*a-a,P[2]^,NormalPut);
      END;
    END;
    11: { Horizontal }
    BEGIN
      FOR X:=4 TO 9 DO
      BEGIN
        Polje[X,18]:=1;
        IF Odd(X) THEN PutImage(X*a-a+188,18*a-a,P[6]^,NormalPut) ELSE
          PutImage(X*a-a+188,18*a-a,P[7]^,NormalPut)
      END;
    END;
    12: { House }
    BEGIN
      FOR Y:=17 TO 21 DO
        FOR X:=5 TO 9 DO
        BEGIN
          IF (Y=17)OR(Y=21)OR(Y=18) THEN
          BEGIN
            Polje[X,Y]:=1;
            IF Y=17 THEN PutImage(X*a-a+188,Y*a-a,P[5]^,NormalPut) ELSE
              IF Y=21 THEN PutImage(X*a-a+188,Y*a-a,P[8]^,NormalPut) ELSE
                IF Y=18 THEN PutImage(X*a-a+188,Y*a-a,P[8]^,NormalPut) ELSE
          END;
          IF ((X=5)OR(X=9))AND((Y<>17)AND(Y<>21)) THEN
          BEGIN
            Polje[X,Y]:=1;
            PutImage(X*a-a+188,Y*a-a,P[8]^,NormalPut);
          END;
        END;
      X:=6;
      FOR Y:=14 TO 17 DO
      BEGIN
        Inc(X);
        Polje[X,Y]:=1;
        PutImage(X*a-a+188,Y*a-a,P[5]^,NormalPut);
      END;
      X:=3;
      FOR Y:=17 DOWNTO 14 DO
      BEGIN
        Inc(X);
        Polje[X,Y]:=1;
        PutImage(X*a-a+188,Y*a-a,P[5]^,NormalPut);
      END;
      Polje[7,15]:=1;
      PutImage(7*a-a+188,15*a-a,P[5]^,NormalPut);
      Polje[7,16]:=1;
      PutImage(7*a-a+188,16*a-a,P[5]^,NormalPut);
      Polje[6,16]:=1;
      PutImage(6*a-a+188,16*a-a,P[5]^,NormalPut);
      Polje[8,16]:=1;
      PutImage(8*a-a+188,16*a-a,P[5]^,NormalPut);
    END;
    13: { Pi }
    BEGIN
      FOR X:=5 TO 9 DO
      BEGIN
        Polje[X,14]:=1;
        PutImage(X*a-a+188,14*a-a,P[5]^,NormalPut);
      END;
      FOR Y:=15 TO 19 DO
      BEGIN
        Polje[6,Y]:=1;
        PutImage(6*a-a+188,Y*a-a,P[2]^,NormalPut);
        Polje[8,Y]:=1;
        PutImage(8*a-a+188,Y*a-a,P[3]^,NormalPut);
      END;
    END;
    14: { Points }
    BEGIN
      Polje[4,17]:=1;
      PutImage(4*a-a+188,17*a-a,P[7]^,NormalPut);
      Polje[9,17]:=1;
      PutImage(9*a-a+188,17*a-a,P[2]^,NormalPut);
    END;
    15: { Random }
    BEGIN
      FOR Y:=17 TO 21 DO
      BEGIN
        X:=Random(12)+1;
        Polje[X,Y]:=1;
        PutImage(X*a-a+188,Y*a-a,P[6]^,NormalPut);
        X:=Random(12)+1;
        Polje[X,Y]:=1;
        PutImage(X*a-a+188,Y*a-a,P[6]^,NormalPut);
      END;
    END;
    16: { Sieve #1 }
    BEGIN
      FOR X:=1 TO 12 DO
        IF Odd(X) THEN
        BEGIN
          Polje[X,19]:=1;
          PutImage(X*a-a+188,19*a-a,P[3]^,NormalPut);
        END;
    END;
    17: { Sieve #2 }
    BEGIN
      X:=1;
      FOR I:=1 TO 6 DO
      BEGIN
        Inc(X,2);
        IF Odd(I) THEN
        BEGIN
          Polje[X,14]:=1;
          PutImage(X*a-a+188,14*a-a,P[4]^,NormalPut);
          Polje[X+1,14]:=1;
          PutImage((X+1)*a-a+188,14*a-a,P[4]^,NormalPut);
        END;
      END;
      X:=-1;
      FOR I:=1 TO 6 DO
      BEGIN
        Inc(X,2);
        IF Odd(I) THEN
        BEGIN
          Polje[X,19]:=1;
          PutImage(X*a-a+188,19*a-a,P[3]^,NormalPut);
          Polje[X+1,19]:=1;
          PutImage((X+1)*a-a+188,19*a-a,P[3]^,NormalPut);
        END;
      END;
    END;
    18: { Stairs }
    BEGIN
      X:=0;
      FOR Y:=21 DOWNTO 16 DO
      BEGIN
        Inc(X);
        Polje[X,Y]:=1;
        PutImage(X*a-a+188,Y*a-a,P[1]^,NormalPut); { Brown }
        Inc(X);
        Polje[X,Y]:=1;
        PutImage(X*a-a+188,Y*a-a,P[5]^,NormalPut); { Red }
      END;
    END;
    19: { Vertical }
    BEGIN
      FOR Y:=14 TO 19 DO
      BEGIN
        Polje[6,Y]:=1;
        IF Odd(Y) THEN PutImage(6*a-a+188,Y*a-a,P[7]^,NormalPut) ELSE
          PutImage(6*a-a+188,Y*a-a,P[2]^,NormalPut)
      END;
    END;
    20: { Waves }
    BEGIN
      Polje[1,21]:=1;
      PutImage(1*a-a+188,21*a-a,P[3]^,NormalPut);
      Polje[2,21]:=1;
      PutImage(2*a-a+188,21*a-a,P[3]^,NormalPut);
      Polje[3,20]:=1;
      PutImage(3*a-a+188,20*a-a,P[3]^,NormalPut);
      Polje[4,19]:=1;
      PutImage(4*a-a+188,19*a-a,P[3]^,NormalPut);
      Polje[5,20]:=1;
      PutImage(5*a-a+188,20*a-a,P[3]^,NormalPut);
      Polje[6,21]:=1;
      PutImage(6*a-a+188,21*a-a,P[3]^,NormalPut);
      Polje[7,21]:=1;
      PutImage(7*a-a+188,21*a-a,P[3]^,NormalPut);
      Polje[8,20]:=1;
      PutImage(8*a-a+188,20*a-a,P[3]^,NormalPut);
      Polje[9,19]:=1;
      PutImage(9*a-a+188,19*a-a,P[3]^,NormalPut);
      Polje[10,20]:=1;
      PutImage(10*a-a+188,20*a-a,P[3]^,NormalPut);
      Polje[11,21]:=1;
      PutImage(11*a-a+188,21*a-a,P[3]^,NormalPut);
      Polje[12,21]:=1;
      PutImage(12*a-a+188,21*a-a,P[3]^,NormalPut);
    END;
  END;
END;

{***********************************************************************}
{***************************** NastaviPolja ****************************}
{***********************************************************************}
PROCEDURE NastaviPolja(N: Integer);
{ Poljem, na katerih je aktiven lik, dodeli vrednost N }
VAR I: Integer;
BEGIN
  FOR I:=1 TO Length(Pod) DO
  BEGIN
    IF I MOD D = 0 THEN
    BEGIN
      IF Copy(Pod,I,1)='1' THEN
        Polje[X+D-1, Y+(I-1) DIV D]:=N;
    END ELSE
    BEGIN
      IF Copy(Pod,I,1)='1' THEN
        Polje[X+I MOD D - 1, Y+I DIV D]:=N;
    END;
  END;
END;

{***********************************************************************}
{****************************** Rotacija *******************************}
{***********************************************************************}
FUNCTION Rotacija(Lik: String): String;
{ Vrne lik, ki je rotacija vhodnega lika - Lik}
VAR I,J,S,D: Integer;
  Rot: String;
BEGIN
  Rot:='';
  D:=ToInt(Copy(Lik,Length(Lik),1));
  Delete(Lik,Length(Lik),1);
  S:=Length(Lik) DIV D;
  FOR I:=D DOWNTO 1 DO
    FOR J:=0 TO S-1 DO
      Insert(Copy(Lik,I+J*D,1),Rot,Length(Rot)+1);
  Insert(ToStr(S),Rot,Length(Rot)+1);
  Rotacija:=Rot;
END;

{***********************************************************************}
{****************************** Rotiraj ********************************}
{***********************************************************************}
PROCEDURE Rotiraj(Mode,N: Integer);
{ Generira se ostale 3 rotacije izbranega lika }
BEGIN
  IF Mode=1 THEN
  BEGIN
    Lik1[N,2]:=Rotacija(Lik1[N,1]);
    Lik1[N,3]:=Rotacija(Lik1[N,2]);
    Lik1[N,4]:=Rotacija(Lik1[N,3]);
  END ELSE
    IF Mode=2 THEN
    BEGIN
      Lik2[N,2]:=Rotacija(Lik2[N,1]);
      Lik2[N,3]:=Rotacija(Lik2[N,2]);
      Lik2[N,4]:=Rotacija(Lik2[N,3]);
    END;
END;

{***********************************************************************}
{******************************** ReFresh ******************************}
{***********************************************************************}
PROCEDURE ReFresh;
{ Obnovi ekran }
VAR I,J,K,L: Integer;
  { Postopek: najprej narise nov lik, potem pa zbrise ostanek starega -
  preprecitev utripanja }
BEGIN
  FOR I:=1 TO Length(Pod) DO
  BEGIN
    IF I MOD D = 0 THEN
    BEGIN
      IF Copy(Pod,I,1)='1' THEN
      BEGIN
        IF Polje[X+D-1, Y+(I-1) DIV D]<>-1 THEN
          CASE Mode OF
            1:
              CASE Now OF
                1:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[1]^,NormalPut);
                2:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[2]^,NormalPut);
                3:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[3]^,NormalPut);
                4:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[4]^,NormalPut);
                5:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[5]^,NormalPut);
                6:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[6]^,NormalPut);
                7:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[7]^,NormalPut);
              END;
            2:
              CASE Now OF
                1:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[7]^,NormalPut);
                2:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[6]^,NormalPut);
                3:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[1]^,NormalPut);
                4:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[8]^,NormalPut);
                5:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[5]^,NormalPut);
                6:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[3]^,NormalPut);
                7:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[2]^,NormalPut);
                8:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[5]^,NormalPut);
                9:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[1]^,NormalPut);
                10:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[4]^,NormalPut);
                11:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[7]^,NormalPut);
                12:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[6]^,NormalPut);
                13:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[9]^,NormalPut);
                14:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[3]^,NormalPut);
                15:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[4]^,NormalPut);
                16:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[5]^,NormalPut);
                17:PutImage((X+D-1)*a-a+188,(Y+(I-1) DIV D)*a-a,P[2]^,NormalPut);
              END;
          END;
        Polje[X+D-1, Y+(I-1) DIV D]:=-2;
      END;
    END ELSE
    BEGIN
      IF Copy(Pod,I,1)='1' THEN
      BEGIN
        IF Polje[X+I MOD D - 1, Y+I DIV D]<>-1 THEN
          CASE Mode OF
            1:CASE Now OF
              1:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[1]^,NormalPut);
              2:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[2]^,NormalPut);
              3:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[3]^,NormalPut);
              4:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[4]^,NormalPut);
              5:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[5]^,NormalPut);
              6:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[6]^,NormalPut);
              7:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[7]^,NormalPut);
            END;
            2: CASE Now OF
              1:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[7]^,NormalPut);
              2:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[6]^,NormalPut);
              3:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[1]^,NormalPut);
              4:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[8]^,NormalPut);
              5:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[5]^,NormalPut);
              6:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[3]^,NormalPut);
              7:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[2]^,NormalPut);
              8:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[5]^,NormalPut);
              9:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[1]^,NormalPut);
              10:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[4]^,NormalPut);
              11:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[7]^,NormalPut);
              12:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[6]^,NormalPut);
              13:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[9]^,NormalPut);
              14:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[3]^,NormalPut);
              15:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[4]^,NormalPut);
              16:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[5]^,NormalPut);
              17:PutImage((X+I MOD D - 1)*a-a+188,(Y+I DIV D)*a-a,P[2]^,NormalPut);
            END;
          END;
        Polje[X+I MOD D - 1, Y+I DIV D]:=-2;
      END;
    END;
  END;
  FOR J:=1 TO PoljeY DO
    FOR I:=1 TO PoljeX DO
    BEGIN
      IF Polje[I,J]=-1 THEN
      BEGIN
        PutImage(I*a-a+188,J*a-a,P[0]^,NormalPut);
        IF (Grid)AND(I>1) THEN
          PutPixel(189+(I-1)*a,(J-1)*a+1,Cyan);
        Polje[I,J]:=0;
      END;
      IF Polje[I,J]=-2 THEN
      BEGIN
        Polje[I,J]:=-1;
      END;
    END;
END;

{***********************************************************************}
{******************************* Podri *********************************}
{***********************************************************************}
PROCEDURE Podri;
{ Izbrise polne vrste }
VAR I, J,K: Integer;
  Point: Pointer;
  Size: Word;

PROCEDURE ZamenjajVrste(P1,P2: Integer);
VAR I: Integer;
BEGIN
  FOR I:=1 TO PoljeX DO SwapInt(Polje[I,P1],Polje[I,P2]);
END;

FUNCTION VrsticaPolna(Y: Integer): Boolean;
VAR I: Integer;
BEGIN
  VrsticaPolna:=TRUE;
  FOR I:=1 TO PoljeX DO IF Polje[I,Y]<>1 THEN BEGIN VrsticaPolna:=FALSE;Break;END;
END;

BEGIN
  FOR I:=Y TO PoljeY DO
  BEGIN
    IF VrsticaPolna(I) THEN
    BEGIN
      {Rusenje topa}
      IF (Pattern=2)AND(I>=CannonLine) THEN Inc(CannonLine);
      Size:=ImageSize(188,0,453,(I-1)*a);
      GetMem(Point,Size);
      GetImage(188,0,453,(I-1)*a,Point^);
      FOR K:=1 TO PoljeX DO
      IF Polje[K,1]=1 THEN
      BEGIN
        PutImage(K*a-a+188,1*a-a,P[0]^,NormalPut);
        IF (Grid)AND(K>1) THEN
          PutPixel(189+(K-1)*a,(1-1)*a+1,Cyan);
      END;
      PutImage(188,a,Point^,NormalPut);
      FOR J:=I DOWNTO 2 DO ZamenjajVrste(J,J-1);
      { Premakne zgornje vrste navzdol }
      IF SoundOn THEN FOR J:=1 TO 5 DO SFX(J*400,Sqr(J));
      FOR J:=1 TO PoljeX DO Polje[J,1]:=0;
      FreeMem(Point,Size);
      Inc(Rows);
      Inc(Score,10+Level);
      ClearKBBuffer;
    END;
  END;
END;

{***********************************************************************}
{****************************** DrawField ******************************}
{***********************************************************************}
PROCEDURE DrawField;
{ Narise igralno polje }
VAR I,J: Integer;
BEGIN
  SetFillStyle(1,LightGray);
  SetColor(White);
  Line(187,0,187,464);
  Line(453,0,453,464);
  Line(187,464,453,464);
  IF Grid THEN
  FOR I:=0 TO 20 DO
    FOR J:=1 TO 11 DO
      PutPixel(189+J*a,I*a+1,Cyan);
  SetColor(Green);
  SetTextStyle(SmallFont,HorizDir,7);
  SetLineStyle(0,0,1);
  SetTextJustify(LeftText,TopText);
  IF Language=1 THEN
  BEGIN
    IF DisplayScore THEN
    BEGIN
      OutTextXY(62-Round(TextWidth('Tocke:')/2),30,'Tocke:');
      Line(55,37,55-2,37-2);
      Line(55,37,55+2,37-2);
    END;
    IF DisplayRows THEN
      OutTextXY(62-Round(TextWidth('Vrste:')/2),100,'Vrste:');
    IF DisplayLevel THEN
      OutTextXY(62-Round(TextWidth('Stopnja:')/2),170,'Stopnja:');
    IF DisplayPlace THEN
      OutTextXY(62-Round(TextWidth('Mesto:')/2),240,'Mesto:');
    IF GameDisplayNext THEN
      OutTextXY(62-Round(TextWidth('Naslednji:')/2),310,'Naslednji:');
  END ELSE
  BEGIN
    IF DisplayScore THEN
      OutTextXY(62-Round(TextWidth('Score:')/2),30,'Score:');
    IF DisplayRows THEN
      OutTextXY(62-Round(TextWidth('Rows:')/2),100,'Rows:');
    IF DisplayLevel THEN
      OutTextXY(62-Round(TextWidth('Level:')/2),170,'Level:');
    IF DisplayPlace THEN
      OutTextXY(62-Round(TextWidth('Place:')/2),240,'Place:');
    IF GameDisplayNext THEN
      OutTextXY(62-Round(TextWidth('Next:')/2),310,'Next:');
  END;
END;


{***********************************************************************}
{****************************** DrawStatistics *************************}
{***********************************************************************}
PROCEDURE DrawStatistics;
{ Narise statistiko (Score, Rows, Level, Place, Next) }
VAR I: Integer;
BEGIN
  SetTextStyle(SmallFont, HorizDir, 7);
  SetColor(Cyan);
  SetFillStyle(1,Black);
  IF DisplayScore THEN
  BEGIN
    Bar(0+3,65-3,124-3,80-3);
    OutTextXY(Round(62-TextWidth(ToStrL(Score))/2),60-4,ToStrL(Score));
  END;
  IF DisplayRows THEN
  BEGIN
    Bar(0+3,135-3,124-3,150-3);
    OutTextXY(Round(62-TextWidth(ToStrL(Rows))/2),130-4,ToStrL(Rows));
  END;
  IF DisplayLevel THEN
  BEGIN
    Bar(0+3,205-3,124-3,220-3);
    OutTextXY(Round(62-TextWidth(ToStr(GameLevel))/2),200-4,ToStr(GameLevel));
  END;
  IF DisplayPlace THEN
  BEGIN
    Bar(0+3,275-3,124-3,290-3);
    TempInt:=GetPlace;
    IF TempInt>0 THEN
    BEGIN
      FOR I:=1 TO 20 DO
        IF I=1 THEN Mesto[I]:=1 ELSE
          IF HighScore.Score[I]=HighScore.Score[I-1] THEN Mesto[I]:=Mesto[I-1] ELSE Mesto[I]:=I;
      IF HighScore.Score[Mesto[TempInt-1]]=Score THEN TempInt:=Mesto[TempInt-1] ELSE TempInt:=Mesto[TempInt-1]+1;
    END;
    IF TempInt=0 THEN
    OutTextXY(Round(62-TextWidth('-')/2),270-4,'-') ELSE
    OutTextXY(Round(62-TextWidth(ToStr(TempInt))/2),270-4,ToStr(TempInt));
  END;
END;

{***********************************************************************}
{******************************* DrawNext ******************************}
{***********************************************************************}
PROCEDURE DrawNext;
{ Narise naslednji lik }
VAR I,J,D,Y,O: Integer;
  Pod: String;
BEGIN
  CASE Mode OF
    1:
    BEGIN
      D:=ToInt(Copy(Lik1[Next,1],Length(Lik1[Next,1]),1));
      Pod:=Copy(Lik1[Next,1],1,Length(Lik1[Next,1])-1);
    END;
    2:
    BEGIN
      D:=ToInt(Copy(Lik2[Next,1],Length(Lik2[Next,1]),1));
      Pod:=Copy(Lik2[Next,1],1,Length(Lik2[Next,1])-1);
    END;
  END;
  SetFillStyle(1,Black);
  Bar(0,352,185-1,462);
  O:=62-D*11;
  Y:=16;
  FOR I:=1 TO Length(Pod) DO
  BEGIN
    IF I MOD D = 0 THEN
    BEGIN
      IF Copy(Pod,I,1)='1' THEN
      BEGIN
        CASE Mode OF
          1:
            CASE Next OF
              1:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[1]^,NormalPut);
              2:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[2]^,NormalPut);
              3:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[3]^,NormalPut);
              4:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[4]^,NormalPut);
              5:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[5]^,NormalPut);
              6:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[6]^,NormalPut);
              7:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[7]^,NormalPut);
            END;
          2:
            CASE Next OF
              1:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[7]^,NormalPut);
              2:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[6]^,NormalPut);
              3:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[1]^,NormalPut);
              4:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[8]^,NormalPut);
              5:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[5]^,NormalPut);
              6:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[3]^,NormalPut);
              7:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[2]^,NormalPut);
              8:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[5]^,NormalPut);
              9:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[1]^,NormalPut);
              10:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[4]^,NormalPut);
              11:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[7]^,NormalPut);
              12:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[6]^,NormalPut);
              13:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[9]^,NormalPut);
              14:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[3]^,NormalPut);
              15:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[4]^,NormalPut);
              16:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[5]^,NormalPut);
              17:PutImage((D-1)*a+O,(Y+(I-1) DIV D)*a,P[2]^,NormalPut);
            END;
        END;
      END;
    END ELSE
    BEGIN
      IF Copy(Pod,I,1)='1' THEN
      BEGIN
        CASE Mode OF
          1:CASE Next OF
            1:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[1]^,NormalPut);
            2:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[2]^,NormalPut);
            3:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[3]^,NormalPut);
            4:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[4]^,NormalPut);
            5:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[5]^,NormalPut);
            6:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[6]^,NormalPut);
            7:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[7]^,NormalPut);
          END;
          2: CASE Next OF
            1:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[7]^,NormalPut);
            2:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[6]^,NormalPut);
            3:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[1]^,NormalPut);
            4:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[8]^,NormalPut);
            5:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[5]^,NormalPut);
            6:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[3]^,NormalPut);
            7:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[2]^,NormalPut);
            8:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[5]^,NormalPut);
            9:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[1]^,NormalPut);
            10:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[4]^,NormalPut);
            11:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[7]^,NormalPut);
            12:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[6]^,NormalPut);
            13:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[9]^,NormalPut);
            14:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[3]^,NormalPut);
            15:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[4]^,NormalPut);
            16:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[5]^,NormalPut);
            17:PutImage((I MOD D - 1)*a+O,(Y+I DIV D)*a,P[2]^,NormalPut);
          END;
        END;
      END;
    END;
  END;
END;

{***********************************************************************}
{******************************* GameOver ******************************}
{***********************************************************************}
PROCEDURE GameOver;
{ Izpiçe sporocilo "Game Over" }
VAR I,J: Integer;
BEGIN
  IF Testing THEN
  BEGIN
    SetFillStyle(1,Black);
    OutTextXY(500,400,Pod);
    OutTextXY(500,420,ToStr(Now));
    OutTextXY(500,450,ToStr(Next));
    FOR I:=1 TO PoljeX DO
      FOR J:=1 TO PoljeY DO
        IF Polje[I,J]=-1 THEN
        BEGIN
          SetColor(Red);
          OutTextXY(450+I*12,J*15,'9')
        END ELSE
        IF Polje[I,J]=1 THEN
        BEGIN
          SetColor(Green);
          OutTextXY(450+I*12,J*15,ToStr(Polje[I,J]));
        END ELSE
        BEGIN
          SetColor(Cyan);
          OutTextXY(450+I*12,J*15,ToStr(Polje[I,J]));
        END;
  END;

{  Bar(189,177,451,285);}
  Time2:=Timer;
  GetTimeDifference(Time1,Time2);
  SetColor(Green);
  SetTextStyle(SmallFont,HorizDir,7);
  SetTextJustify(LeftText,TopText);
  IF Language=1 THEN
  BEGIN
    OutTextXY(62-Round(TextWidth('Tocke:')/2),30,'Tocke:');
    Line(55,37,55-2,37-2);
    Line(55,37,55+2,37-2);
    OutTextXY(62-Round(TextWidth('Vrste:')/2),100,'Vrste:');
    OutTextXY(62-Round(TextWidth('Stopnja:')/2),170,'Stopnja:');
    OutTextXY(62-Round(TextWidth('Mesto:')/2),240,'Mesto:');
    OutTextXY(578-Round(TextWidth('Cas:')/2),30,'Cas:');
    Line(559,33,559-2,33-2);
    Line(559,33,559+2,33-2);
    OutTextXY(578-Round(TextWidth('Liki:')/2),100,'Liki:');
  END ELSE
  BEGIN
    OutTextXY(62-Round(TextWidth('Score:')/2),30,'Score:');
    OutTextXY(62-Round(TextWidth('Rows:')/2),100,'Rows:');
    OutTextXY(62-Round(TextWidth('Level:')/2),170,'Level:');
    OutTextXY(62-Round(TextWidth('Place:')/2),240,'Place:');
    OutTextXY(578-Round(TextWidth('Time:')/2),30,'Time:');
    OutTextXY(578-Round(TextWidth('Figures:')/2),100,'Figures:');
  END;
  SetTextStyle(SmallFont, HorizDir, 7);
  SetColor(Cyan);
  SetFillStyle(1,Black);
  Bar(0+3,65-3,124-3,80-3);
  OutTextXY(Round(62-TextWidth(ToStrL(Score))/2),60-4,ToStrL(Score));
  Bar(0+3,135-3,124-3,150-3);
  OutTextXY(Round(62-TextWidth(ToStrL(Rows))/2),130-4,ToStrL(Rows));
  Bar(0+3,205-3,124-3,220-3);
  OutTextXY(Round(62-TextWidth(ToStr(GameLevel))/2),200-4,ToStr(GameLevel));
  Bar(0+3,275-3,124-3,290-3);
  TempInt:=GetPlace;
  IF TempInt>0 THEN
  BEGIN
    FOR I:=1 TO 20 DO
      IF I=1 THEN Mesto[I]:=1 ELSE
        IF HighScore.Score[I]=HighScore.Score[I-1] THEN Mesto[I]:=Mesto[I-1] ELSE Mesto[I]:=I;
    IF HighScore.Score[Mesto[TempInt-1]]=Score THEN TempInt:=Mesto[TempInt-1] ELSE TempInt:=Mesto[TempInt-1]+1;
  END;
  IF TempInt=0 THEN
    OutTextXY(Round(62-TextWidth('-')/2),270-4,'-') ELSE
    OutTextXY(Round(62-TextWidth(ToStr(TempInt))/2),270-4,ToStr(TempInt));
  OutTextXY(Round(578-TextWidth(DiffH+':'+DiffM+':'+DiffS)/2),60-4,DiffH+':'+DiffM+':'+DiffS);
  OutTextXY(Round(578-TextWidth(ToStrL(StLikov-1))/2),130-4,ToStrL(StLikov-1));
  SetTextJustify(LeftText, TopText);
  SetFillStyle(1,White);
  FOR I:=189 TO 320 DO
    FOR J:=177 TO 285 DO
    BEGIN
      PutPixel(I,J,White);
      PutPixel(451-(I-189),J,White);
    END;
  SetColor(Black);
  Rectangle(189+2,177+2,451-2,285-2);
  SetTextStyle(TriplexFont,HorizDir,4);
  SetTextJustify(CenterText,CenterText);
  IF Language=1 THEN OutTextXY(320,228,'KONEC IGRE') ELSE OutTextXY(320,228,'GAME OVER');
  IF SoundOn THEN
  FOR I := 1 To 6 DO
  BEGIN
    Play_SB($A0, SBNotes[i]);
    Play_SB($B0, SBOctaves[i + 3 * 12]);
    UniDelay(100);
    Init_SB;
    Reset_SB;
  END;
  UniDelay(300);
  ClearKBBuffer;
  REPEAT UNTIL (KeyPressed)OR(GetMouseButton<>0);
  IF KeyPressed THEN C:=Read_Key ELSE C:=ENTER;
END;

{***********************************************************************}
{******************************** SaveSettings *************************}
{***********************************************************************}
PROCEDURE SaveSettings;
{ Trenutne nastavitve menuja shrani v datoteko tetris.cfg }
VAR F: File OF TSettings;
  I: Integer;
  Path: String;
BEGIN
  Path:=ParamStr(0);
  FOR I:=Length(Path) DOWNTO 1 DO
    IF Path[I]='\' THEN Break;
  Assign(F,Copy(Path,1,I)+'tetris.cfg');
  Rewrite(F);
  Settings.Language     := Language;
  Settings.DisplayScore := DisplayScore;
  Settings.DisplayRows  := DisplayRows;
  Settings.DisplayLevel := DisplayLevel;
  Settings.DisplayPlace := DisplayPlace;
  Settings.DisplayNext  := DisplayNext;
  Settings.SoundOn        := SoundOn;
  Settings.Grid         := Grid;
  Settings.Keys         := Keys;
  Settings.Mode         := Mode;
  Settings.Level        := Level;
  Settings.Pattern      := Pattern;
  FOR I:=1 TO 2 DO
  BEGIN
    Settings.gUP[I]    := gUP[I];
    Settings.gDN[I]    := gDN[I];
    Settings.gLT[I]    := gLT[I];
    Settings.gRT[I]    := gRT[I];
    Settings.gNext[I]  := gNext[I];
    Settings.gLevel[I] := gLevel[I];
    Settings.gShoot[I] := gShoot[I];
    Settings.HotgUP[I]    := HotgUP[I];
    Settings.HotgDN[I]    := HotgDN[I];
    Settings.HotgLT[I]    := HotgLT[I];
    Settings.HotgRT[I]    := HotgRT[I];
    Settings.HotgNext[I]  := HotgNext[I];
    Settings.HotgLevel[I] := HotgLevel[I];
    Settings.HotgShoot[I] := HotgShoot[I];
  END;
  Seek(F,0);
  Write(F,Settings);
  Close(F);
END;

{***********************************************************************}
{******************************* OpenSettings **************************}
{***********************************************************************}
PROCEDURE OpenSettings;
{ Prebere nastavitve menuja iz datoteke tetris.cfg }
VAR F: File OF TSettings;
  I: Integer;
  Path: String;
BEGIN
  Path:=ParamStr(0);
  FOR I:=Length(Path) DOWNTO 1 DO
    IF Path[I]='\' THEN Break;
  Assign(F,Copy(Path,1,I)+'tetris.cfg');
  {$I-}
  Reset(F);
  {$I+}
  IF IOResult<>0 THEN
  BEGIN
    Language:=1;
    Level:=5;
    Keys:=1;
    Pattern:=1;
    Mode:=1;
    SoundOn:=TRUE;
    Grid:=TRUE;
    DisplayScore:=TRUE;
    DisplayRows:=TRUE;
    DisplayPlace:=TRUE;
    DisplayLevel:=TRUE;
    DisplayNext:=TRUE;
    gUP[1]:=UP;
    gDN[1]:=DN;
    gLT[1]:=LT;
    gRT[1]:=RT;
    gLevel[1]:='+';
    gNext[1]:='N';
    gShoot[1]:=SPACE;
    HotgUP[1]:=TRUE;
    HotgDN[1]:=TRUE;
    HotgLT[1]:=TRUE;
    HotgRT[1]:=TRUE;
    HotgLevel[1]:=FALSE;
    HotgNext[1]:=FALSE;
    HotgShoot[1]:=FALSE;
    gUP[2]:='8';
    gDN[2]:='4';
    gLT[2]:='7';
    gRT[2]:='9';
    gLevel[2]:='6';
    gNext[2]:='1';
    gShoot[2]:='5';
    HotgUP[2]:=FALSE;
    HotgDN[2]:=FALSE;
    HotgLT[2]:=FALSE;
    HotgRT[2]:=FALSE;
    HotgLevel[2]:=FALSE;
    HotgNext[2]:=FALSE;
    HotgShoot[2]:=FALSE;
  END ELSE
  BEGIN
    Seek(F,0);
    Read(F,Settings);
    Language     := Settings.Language;
    DisplayScore := Settings.DisplayScore;
    DisplayRows  := Settings.DisplayRows;
    DisplayLevel := Settings.DisplayLevel;
    DisplayPlace := Settings.DisplayPlace;
    DisplayNext  := Settings.DisplayNext;
    SoundOn        := Settings.SoundOn;
    Grid         := Settings.Grid;
    Keys         := Settings.Keys;
    Mode         := Settings.Mode;
    Level        := Settings.Level;
    Pattern      := Settings.Pattern;
    FOR I:=1 TO 2 DO
    BEGIN
      gUP[I]    := Settings.gUP[I];
      gDN[I]    := Settings.gDN[I];
      gLT[I]    := Settings.gLT[I];
      gRT[I]    := Settings.gRT[I];
      gNext[I]  := Settings.gNext[I];
      gLevel[I] := Settings.gLevel[I];
      gShoot[I] := Settings.gShoot[I];
      HotgUP[I]    := Settings.HotgUP[I];
      HotgDN[I]    := Settings.HotgDN[I];
      HotgLT[I]    := Settings.HotgLT[I];
      HotgRT[I]    := Settings.HotgRT[I];
      HotgNext[I]  := Settings.HotgNext[I];
      HotgLevel[I] := Settings.HotgLevel[I];
      HotgShoot[I] := Settings.HotgShoot[I];
    END;
    Close(F);
  END;
END;

{***********************************************************************}
{******************************* SaveHighScore *************************}
{***********************************************************************}
PROCEDURE SaveHighScore;
{ Doda lestvico za trenutno igro v datoteko tetris.hsc }
VAR F: File OF THighScore;
    I: Integer;
    Path: String;
BEGIN
  NrHighScore:=((Mode-1)*20)+Pattern;
  Path:=ParamStr(0);
  FOR I:=Length(Path) DOWNTO 1 DO
    IF Path[I]='\' THEN Break;
  Assign(F,Copy(Path,1,I)+'tetris.hsc');
  {$I-}
  Reset(F);
  {$I+}
  IF IOResult<>0 THEN
  BEGIN
    Rewrite(F);
    FOR I:=0 TO 39 DO
    BEGIN
      Seek(F,I);
      Write(F,EmptyHighScore);
    END;
  END;
  Seek(F,NrHighScore-1);
  FOR I:=1 TO 20 DO
  BEGIN
    HighScore.Name[I]:=Code(HighScore.Name[I]);
    HighScore.Score[I]:=HighScore.Score[I]+1;
  END;
  Write(F,HighScore);
  Close(F);
END;

{***********************************************************************}
{******************************* OpenHighScore *************************}
{***********************************************************************}
PROCEDURE OpenHighScore;
{ Prebere lestvico za trenutno igro iz datoteke tetris.hsc }
VAR F: File OF THighScore;
    I: Integer;
    Path: String;
BEGIN
  NrHighScore:=((Mode-1)*20)+Pattern;
  Path:=ParamStr(0);
  FOR I:=Length(Path) DOWNTO 1 DO
    IF Path[I]='\' THEN Break;
  Assign(F,Copy(Path,1,I)+'tetris.hsc');
  {$i-}
  Reset(F);
  {$i+}
  IF IOResult<>0 THEN
  BEGIN
    FOR I:=1 TO 20 DO BEGIN HighScore.Name[I]:='';HighScore.Score[I]:=0 END;
  END ELSE
  BEGIN
    Seek(F,NrHighScore-1);
    Read(F,HighScore);
    FOR I:=1 TO 20 DO
    BEGIN
      HighScore.Name[I]:=Code(HighScore.Name[I]);
      HighScore.Score[I]:=HighScore.Score[I]-1;
      IF HighScore.Score[I]=-1 THEN HighScore.Score[I]:=0;
    END;
    Close(F);
  END;
END;

{***********************************************************************}
{**************************** SortHighScore ****************************}
{***********************************************************************}
PROCEDURE SortHighScore;
{ Sortira imena in tocke na lestvici }
VAR I,J: Integer;
PROCEDURE SwapHighScore(HighScore1,HighScore2: Integer);
VAR TempName  : String;
  TempScore : LongInt;
BEGIN
  TempName                    := HighScore.Name[HighScore1];
  HighScore.Name[HighScore1]  := HighScore.Name[HighScore2];
  HighScore.Name[HighScore2]  := TempName;
  TempScore                   := HighScore.Score[HighScore1];
  HighScore.Score[HighScore1] := HighScore.Score[HighScore2];
  HighScore.Score[HighScore2] := TempScore;
END;
BEGIN
  FOR I:=1 TO 20 DO
    FOR J:=I+1 TO 20 DO
      IF HighScore.Score[I]<HighScore.Score[J] THEN SwapHighScore(I,J);
END;

{***********************************************************************}
{********************************* GetPlace ****************************}
{***********************************************************************}
FUNCTION GetPlace: Integer;
{ Vrne uvrstitev igralca s tockami Score }
VAR I: Integer;
BEGIN
  GetPlace:=0;
  IF ((Score=0)AND(HighScore.Score[1]=0))OR(Score>HighScore.Score[1]) THEN GetPlace:=1 ELSE
    IF (Score=0)AND(HighScore.Score[20]=0) THEN
    BEGIN
      FOR I:=20 DOWNTO 2 DO
        IF HighScore.Score[I]>0 THEN BEGIN GetPlace:=I+1;Break;END;
    END ELSE
    FOR I:=20 DOWNTO 2 DO
      IF (Score>HighScore.Score[I])AND(Score<=HighScore.Score[I-1]) THEN GetPlace:=I;
END;

{***********************************************************************}
{******************************** Beri *********************************}
{***********************************************************************}
PROCEDURE Beri(X,Y,Lngth: Integer; VAR Text: String);
{ Vnos Stringa }
VAR C,OldC: Char;
BEGIN
  SetTextJustify(CenterText,CenterText);
  Text:='';
  SetFillStyle(1,LightGray);
  REPEAT
    SetColor(Blue);
    Line(X+Round(TextWidth(Text)/2),Y+10,X+Round(TextWidth(Text)/2)+8,Y+10);
    SetColor(Black);
    REPEAT
      OldC:=C;
      C:=ReadKey;
      IF C=#0 THEN C:=ReadKey ELSE
      BEGIN
        IF C=ESC THEN BEGIN Text:='';Break;END;
        IF ((Ord(C)>=33)AND(Ord(C)<=126))OR(C=BKSPACE)OR(C=ENTER)
           OR((C=SPACE)AND(Length(Text)>0)AND(OldC<>Space))
        THEN Break;
      END;
    UNTIL FALSE;
    IF C=ESC THEN Break;
    IF C=BKSPACE THEN Delete(Text,Length(Text),1);
    IF (Length(Text)<=Lngth)AND(C<>ENTER) THEN
    BEGIN
      IF C<>BKSPACE THEN Text:=Text+C;
      Bar(X-Round(TextWidth(Text)/2)-20,Y-15,X+Round(TextWidth(Text)/2)+20,Y+20);
      OutTextXY(X,Y,Text);
    END;
  UNTIL (C=ENTER)AND(Length(Text)>0);
  SetTextJustify(LeftText,TopText);
END;

{***********************************************************************}
{**************************** DrawHighScore ****************************}
{***********************************************************************}
PROCEDURE DrawHighScore;
{ Narise tabelo s trenutno lestvico }
VAR I: Integer;
BEGIN
  SetTextJustify(LeftText,TopText);
  SetTextStyle(SmallFont,HorizDir,5);
  SetFillStyle(1,LightGray);
  HideMouseCursor;
  Bar(0,0,GetMaxX,GetMaxY);
  FrameIn(90,32,550,409);
  LineIn(450,32,450,409);
  LineIn(150,32,150,409);
  SetColor(Blue);
  IF Language=1 THEN
  BEGIN
    SetColor(Blue);
    OutTextXY(290,32,'Ime');
    OutTextXY(480,32,'Tocke');
    OutTextXY(101,32,'Mesto');
    Stresica(499,37);
  END ELSE
  BEGIN
    SetColor(Blue);
    OutTextXY(290,32,'Name');
    OutTextXY(480,32,'Score');
    OutTextXY(101,32,'Place');
  END;
  OpenHighScore;
  FOR I:=1 TO 20 DO
  BEGIN
    IF I=1 THEN Mesto[I]:=1 ELSE
      IF HighScore.Score[I]=HighScore.Score[I-1] THEN Mesto[I]:=Mesto[I-1] ELSE Mesto[I]:=I;
    LineIn(90,32+I*18,550,32+I*18);
    IF (I=OldGetPlace)AND(Name<>'')AND(Name=HighScore.Name[I]) THEN SetColor(Red) ELSE SetColor(Black);
    SetTextJustify(CenterText,TopText);
    IF HighScore.Name[I]='' THEN OutTextXY(120,33+(18*I),'-') ELSE
      OutTextXY(120,33+(18*I),ToStr(Mesto[I]));
    SetTextJustify(LeftText,TopText);
    IF HighScore.Name[I]='' THEN
    BEGIN
      IF Language=1 THEN OutTextXY(160,33+(18*I),'Prazno') ELSE
        OutTextXY(160,33+(18*I),'Empty')
    END
    ELSE
      OutTextXY(160,33+(18*I),HighScore.Name[I]);
    OutTextXY(540-TextWidth(ToStr(HighScore.Score[I])),33+(18*I),ToStr(HighScore.Score[I]));
  END;
  SetMouseCursor(Normal);
  ShowMouseCursor;
END;

{***********************************************************************}
{********************************* Uvod ********************************}
{***********************************************************************}
PROCEDURE Uvod;
{ Uvodna rotacija telesa in naslov igre }
CONST
  Points = 8;

TYPE TPoint = RECORD
  X,Y: Integer;
END;

  { 3D lik je sestavljen iz dveh ploskev (2D), katerih ogljisca so povezana
  med seboj }
VAR Alpha, { Srediscni kot elipse }
  A, { 1. polmer elipse, po kateri se rotira lik }
  B  { 2. polmer elipse, po kateri se rotira lik }
  : Integer;
  Point: ARRAY [1..Points] OF TPoint;
  X0,Y0 { Sredisce rotacije }
  : ARRAY[1..2] OF Integer;
  Desno,Prvic: Boolean;

PROCEDURE Draw(Color: Word);
{ Narise telo }
VAR I: Integer;
  X,Y: ARRAY [1..Points] OF Integer;
BEGIN
  { Zaradi vecje preglednosti sem shranil spremenljivke Point[] v spremenljivke
  s krajsimi imeni }
  FOR I:=1 TO 8 DO
  BEGIN
    X[I]:=Point[I].X;
    Y[I]:=Point[I].Y;
  END;
  { Ce bi narisal 10 tock (ogljisc telesa), bi moral nekatere tocke
  bolj oddaljiti od sredisca rotacije, ce bi to storil, bi tocki
  manjkalo 22.5 (90/4) stopinj do pravega kota, ker pa je to realno stevilo,
  koordinate pa so lahko samo cele, pride do popacenja.
  Sedaj se rotira samo en kvadrat, ostale crte pa se narisejo glede na
  4 ogljisca tega kvadrata. Ta 4 ogljisca kvadrata potujejo po elipsi
  z radijema A in B, med sabo pa so oddaljene 90 stopinj (4*90=360) }
  SetColor(Color);
  { 1. ploskev }
  Line(X[1]-(X[2]-X[1]),Y[1]-(Y[2]-Y[1]),X[2]+(X[2]-X[1]),Y[2]+(Y[2]-Y[1]));
  Line(X[1],Y[1],X[3],Y[3]);
  Line(X[2],Y[2],X[4],Y[4]);
  Line(X[3]-(X[4]-X[3]),Y[3]-(Y[4]-Y[3]),X[4]+(X[4]-X[3]),Y[4]+(Y[4]-Y[3]));
  Line(X[3],Y[3],X[1]+(X[1]-X[3]),Y[1]+(Y[1]-Y[3]));
  Line(X[3]-(X[4]-X[3]),
  Y[3]-(Y[4]-Y[3]),X[1]-(X[2]-X[1])+(X[1]-(X[2]-X[1])-(X[3]-(X[4]-X[3]))),
  (Y[1]-(Y[2]-Y[1])+(Y[1]-(Y[2]-Y[1])-(Y[3]-(Y[4]-Y[3])))));
  Line(X[2]+(X[2]-X[1]),Y[2]+(Y[2]-Y[1]),X[4]+(X[4]-X[3]),Y[4]+(Y[4]-Y[3]));
  Line(X[1]+(X[1]-X[3]),Y[1]+(Y[1]-Y[3]),X[1]-(X[2]-X[1])+(X[1]-(X[2]-X[1])-(X[3]-(X[4]-X[3]))),
  (Y[1]-(Y[2]-Y[1])+(Y[1]-(Y[2]-Y[1])-(Y[3]-(Y[4]-Y[3])))));
  { 2. ploskev }
  Line(X[5]-(X[6]-X[5]),Y[5]-(Y[6]-Y[5]),X[6]+(X[6]-X[5]),Y[6]+(Y[6]-Y[5]));
  Line(X[5],Y[5],X[7],Y[7]);
  Line(X[6],Y[6],X[8],Y[8]);
  Line(X[7]-(X[8]-X[7]),Y[7]-(Y[8]-Y[7]),X[8]+(X[8]-X[7]),Y[8]+(Y[8]-Y[7]));
  Line(X[7],Y[7],X[5]+(X[5]-X[7]),Y[5]+(Y[5]-Y[7]));
  Line(X[7]-(X[8]-X[7]),
  Y[7]-(Y[8]-Y[7]),X[5]-(X[6]-X[5])+(X[5]-(X[6]-X[5])-(X[7]-(X[8]-X[7]))),
  (Y[5]-(Y[6]-Y[5])+(Y[5]-(Y[6]-Y[5])-(Y[7]-(Y[8]-Y[7])))));
  Line(X[6]+(X[6]-X[5]),Y[6]+(Y[6]-Y[5]),X[8]+(X[8]-X[7]),Y[8]+(Y[8]-Y[7]));
  Line(X[5]+(X[5]-X[7]),Y[5]+(Y[5]-Y[7]),X[5]-(X[6]-X[5])+(X[5]-(X[6]-X[5])-(X[7]-(X[8]-X[7]))),
  (Y[5]-(Y[6]-Y[5])+(Y[5]-(Y[6]-Y[5])-(Y[7]-(Y[8]-Y[7])))));
  { Povezave }
  Line(X[1]-(X[2]-X[1]),Y[1]-(Y[2]-Y[1]),X[5]-(X[6]-X[5]),Y[5]-(Y[6]-Y[5]));
  Line(X[2]+(X[2]-X[1]),Y[2]+(Y[2]-Y[1]),X[6]+(X[6]-X[5]),Y[6]+(Y[6]-Y[5]));
  Line(X[3]-(X[4]-X[3]),Y[3]-(Y[4]-Y[3]),X[7]-(X[8]-X[7]),Y[7]-(Y[8]-Y[7]));
  Line(X[4]+(X[4]-X[3]),Y[4]+(Y[4]-Y[3]),X[8]+(X[8]-X[7]),Y[8]+(Y[8]-Y[7]));
  Line(X[3],Y[3],X[7],Y[7]);
  Line(X[1]+(X[1]-X[3]),Y[1]+(Y[1]-Y[3]),X[5]+(X[5]-X[7]),Y[5]+(Y[5]-Y[7]));
  Line(X[5]-(X[6]-X[5])+(X[5]-(X[6]-X[5])-(X[7]-(X[8]-X[7]))),
  (Y[5]-(Y[6]-Y[5])+(Y[5]-(Y[6]-Y[5])-(Y[7]-(Y[8]-Y[7])))),X[1]-(X[2]-X[1])+(X[1]-(X[2]-X[1])-(X[3]-(X[4]-X[3]))),
  (Y[1]-(Y[2]-Y[1])+(Y[1]-(Y[2]-Y[1])-(Y[3]-(Y[4]-Y[3])))));
  Line(X[1],Y[1],X[5],Y[5]);
  Line(X[2],Y[2],X[6],Y[6]);
  Line(X[4],Y[4],X[8],Y[8]);
END;

{ ************************************************************************ }
FUNCTION ToRad(Deg: Real): Real;
{ Pretvori stopinje v radiane }
BEGIN
  ToRad:=(Pi/180)*Deg;
END;

BEGIN
  X0[1]:=305;     { Sredisce prve ploskve  - X }
  Y0[1]:=280;     { Sredisce prve ploskve  - Y }
  X0[2]:=340;     { Sredisce druge ploskve - X }
  Y0[2]:=290;     { Sredisce druge ploskve - Y }
  A:=30; {  }
  B:=40;
  Alpha:=0;
  SetFillStyle(1,LightGray);
  Bar(0,0,GetMaxX,GetMaxY);
  SetTextJustify(CenterText,CenterText);
  SetTextStyle(SmallFont,HorizDir,4);
  SetColor(Black);
  OutTextXY(230,466,'C');
  SetTextStyle(SmallFont,HorizDir,5);
  OutTextXY(320,465,'  1996 by David Krmpotic');
  Circle(230,467,5);
  SetTextStyle(TriplexFont,HorizDir,9);
  FOR I:=0 TO 2 DO
  BEGIN
    CASE I OF 0:SetColor(White);1:SetColor(Cyan); 2:SetColor(Blue) END;
    OutTextXY(320+I*2,70+I*2,'TETRIS +');
  END;
  Desno:=TRUE;
  Prvic:=TRUE;
  REPEAT
    IF Desno THEN
    BEGIN
      { Povecuje X sredisca prve in druge ploskve - lik se giblje v desno }
      Inc(X0[1],2);
      Inc(X0[2],2);
      Inc(Alpha,3);
      { Ob dolocenem polozaju lika, zacne povecevati radij (X) elipse,
      zato se lik obrne na glavo }
      IF (X0[1]>120)AND(X0[2]<265) THEN Inc(A);
    END ELSE
    BEGIN
      { Zmanjsuje X sredisca prve in druge ploskve - lik se giblje v Levo }
      Dec(X0[1],2);
      Dec(X0[2],2);
      Dec(Alpha,3);
      { Ob dolocenem polozaju lika, zacne zmanjsevati radij (X) elipse,
      zato se lik obrne na glavo }
      IF (X0[1]>270)AND(X0[2]<420) THEN Dec(A);
    END;
    {    WaitRetrace; { Prepreci utripanje crt oz. pocaka, da katodni zarek
    pride do konca ekrana}
    WaitRetrace;
    IF NOT(Prvic) THEN Draw(LightGray); { Izbrise staro telo - narise ga v barvi ozadja }
    { Ker mora biti parameter za funkciji COS in SIN v radianih
    moramo pretvoriti stopinje v radiane, zato je uporabljena funkcija ToRad.
    Izracuna koordinate tock obeh kvadratov (na obeh ploskvah). }

    Point[1].X:=X0[1]+Round(Cos(ToRad(4*90+Alpha))*A);
    Point[1].Y:=Y0[1]+Round(Sin(ToRad(4*90+Alpha))*B);
    Point[2].X:=X0[1]+Round(Cos(ToRad(1*90+Alpha))*A);
    Point[2].Y:=Y0[1]+Round(Sin(ToRad(1*90+Alpha))*B);
    Point[3].X:=X0[1]+Round(Cos(ToRad(3*90+Alpha))*A);
    Point[3].Y:=Y0[1]+Round(Sin(ToRad(3*90+Alpha))*B);
    Point[4].X:=X0[1]+Round(Cos(ToRad(2*90+Alpha))*A);
    Point[4].Y:=Y0[1]+Round(Sin(ToRad(2*90+Alpha))*B);
    Point[5].X:=X0[2]+Round(Cos(ToRad(4*90+Alpha))*A);
    Point[5].Y:=Y0[2]+Round(Sin(ToRad(4*90+Alpha))*B);
    Point[6].X:=X0[2]+Round(Cos(ToRad(1*90+Alpha))*A);
    Point[6].Y:=Y0[2]+Round(Sin(ToRad(1*90+Alpha))*B);
    Point[7].X:=X0[2]+Round(Cos(ToRad(3*90+Alpha))*A);
    Point[7].Y:=Y0[2]+Round(Sin(ToRad(3*90+Alpha))*B);
    Point[8].X:=X0[2]+Round(Cos(ToRad(2*90+Alpha))*A);
    Point[8].Y:=Y0[2]+Round(Sin(ToRad(2*90+Alpha))*B);
    Draw(Black); { Narise novo telo }
    { Ce pride lik do roba ekrana, mu spremeni smer }
    IF X0[2]>GetMaxX-80 THEN BEGIN A:=28;Desno:=FALSE END ELSE
      IF X0[1]<80 THEN Desno:=TRUE;
    { Postavi Alpha na 0 oz. na 360 (odvisno od smeri rotacije,
    ta pa je odvisna od smeri lika) }
    IF Alpha=360 THEN Alpha:=0 ELSE
      IF Alpha=0 THEN Alpha:=360;
    IF Prvic=TRUE THEN Prvic:=FALSE;
  UNTIL (KeyPressed)OR((GetMouseButton<>0)AND(MouseInstalled));
  IF KeyPressed THEN ReadKey;
END;

{***********************************************************************}
{******************************* Menu **********************************}
{***********************************************************************}
PROCEDURE Menu;
{ Uvodni zaslon - menu }

VAR I,Click: Integer;
  Konec,Koncaj: Boolean;
  C: Char;
  TempUP, TempDN, TempLT, TempRT, TempNext, TempLevel, TempShoot: Char;
  HotTempUP, HotTempDN, HotTempLT, HotTempRT, HotTempNext, HotTempLevel, HotTempShoot: Boolean;


  {************************************************************************}
PROCEDURE DrawMenu;
{ Narise vse elemente menuja s trenutnimi nastavitvami }

VAR I,X,Y: Integer;
BEGIN
  HideMouseCursor;
  SetFillStyle(1,LightGray);
  Bar(0,0,GetMaxX,GetMaxY);
  SetTextJustify(LeftText,TopText);
  SetTextStyle(SmallFont,HorizDir,5);
  IF Language=1 THEN
  BEGIN
    SetColor(Black);
    Stresica(536,137); { Hisa }
    Stresica(538,177); { Tocki }
    Stresica(421,174); { Sah }
    Stresica(568,197); { Nakljucno }
    Stresica(444,217); { Kriz }
    Stresica(104,136);  { Mreza }
    Stresica(222,216); { Tocke }
    Stresica(118,297);  { Angleski}
    SetColor(Blue);
    OutTextXY(32,80,'Splosne nastavitve');
    Stresica(65,85);
    OutTextXY(82,240,'Jezik');
    OutTextXY(204,180,'Prikaz');
    OutTextXY(308,80,'Stopnja');
    OutTextXY(212,80,'Igra');
    OutTextXY(475,80,'Vzorec');
  END ELSE
  BEGIN
    SetColor(Blue);
    SetColor(Blue);
    OutTextXY(42,80,'General Options');
    OutTextXY(68,240,'Language');
    OutTextXY(200,180,'Display');
    OutTextXY(316,80,'Level');
    OutTextXY(212,80,'Game');
    OutTextXY(472,80,'Pattern');
  END;
  SetColor(Black);
  FrameIn(27,75,608,320);
  LineIn(171,76,171,320); { ³ }
  LineIn(282,76,282,320); { ³ }
  LineIn(386,76,386,320); { ³ }
  LineIn(27,228,170,228); { Ä }
  LineIn(171,165,281,165); { Ä }
  DrawAllButtons;
  ShowMouseCursor;
END;

{************************************************************************}
PROCEDURE InitButtons;
{ Gumbom nastavi trenutne vrednosti oz. polozaje }
VAR I: Integer;
BEGIN
  ResetButtons;


  { Play }
  WITH Button[1] DO
  BEGIN
    X:=289;
    Y:=365;
    W:=62;
    H:=19;
    IF Language=1 THEN Text:='Igra' ELSE Text:='Play';
  END;

  { Exit }
  WITH Button[2] DO
  BEGIN
    X:=289;
    Y:=395;
    W:=62;
    H:=19;
    IF Language=1 THEN Text:='Izhod' ELSE Text:='Exit';
  END;

  { High Score }
  WITH Button[3] DO
  BEGIN
    X:=122;
    Y:=380;
    W:=137;
    H:=19;
    IF Language=1 THEN Text:='Lestvica' ELSE Text:='High Score';
  END;

  { Save Settings }
  WITH Button[4] DO
  BEGIN
    Mode:=4;
    X:=381;
    Y:=380;
    W:=137;
    H:=19;
    IF Language=1 THEN Text:='Shrani nastavitve' ELSE Text:='Save Settings';
  END;

  { Redefine }
  WITH Button[5] DO
  BEGIN
    X:=68;
    Y:=200;
    Size:=4;
    IF Language=1 THEN Text:='Spremeni' ELSE Text:='Redefine';
  END;

  { SoundOn }
  WITH Button[6] DO
  BEGIN
    Mode:=1;
    X:=62;
    Y:=119;
    IF Language=1 THEN Text:='Zvok' ELSE Text:='SoundOn';
    Down:=SoundOn;
  END;

  { Grid }
  WITH Button[48] DO
  BEGIN
    Mode:=1;
    X:=62;
    Y:=139;
    IF Language=1 THEN Text:='Mreza' ELSE Text:='Grid';
    Down:=Grid;
  END;

  { Keys #1 }
  WITH Button[7] DO
  BEGIN
    Mode:=2;
    X:=62;
    Y:=159;
    IF Language=1 THEN Text:='Tipke #1' ELSE Text:='Keys #1';
    Down:=NOT Boolean(Keys-1);
    Group:=0;
  END;

  { Keys #2 }
  WITH Button[8] DO
  BEGIN
    Mode:=2;
    X:=62;
    Y:=179;
    IF Language=1 THEN Text:='Tipke #2' ELSE Text:='Keys #2';
    Down:=Boolean(Keys-1);
    Group:=0;
  END;

  { Slovenian }
  WITH Button[9] DO
  BEGIN
    Mode:=2;
    X:=62;
    Y:=279;
    IF Language=1 THEN Text:='Slovenski' ELSE Text:='Slovenian';
    Down:=NOT Boolean(Language-1);
    Group:=1;
  END;

  { English }
  WITH Button[10] DO
  BEGIN
    Mode:=2;
    X:=62;
    Y:=299;
    IF Language=1 THEN Text:='Angleski' ELSE Text:='English';
    Down:=Boolean(Language-1);
    Group:=1;
  END;

  { Tetris }
  WITH Button[11] DO
  BEGIN
    Mode:=2;
    X:=195;
    Y:=118;
    Text:='Tetris';
    Group:=2;
  END;
  Button[11].Down:=NOT Boolean(Mode-1);

  { Pentix }
  WITH Button[12] DO
  BEGIN
    Mode:=2;
    X:=195;
    Y:=138;
    Text:='Pentix';
    Group:=2;
  END;
  Button[12].Down:=Boolean(Mode-1);

  { Display }
  FOR I:=1 TO 5 DO
  BEGIN
    WITH Button[I+12] DO
    BEGIN
      Mode:=1;
      IF Language=1 THEN X:=188 ELSE X:=202;
      Y:=219+20*(I-1);
      CASE I OF
        1:Down:=DisplayScore;
        2:Down:=DisplayRows;
        3:Down:=DisplayLevel;
        4:Down:=DisplayPlace;
        5:Down:=DisplayNext;
      END;
      CASE Language OF
        1:CASE I OF
          1:Text:='Tocke';
          2:Text:='Vrste';
          3:Text:='Stopnja';
          4:Text:='Mesto';
          5:Text:='Naslednji';
        END;
        2:CASE I OF
          1:Text:='Score';
          2:Text:='Rows';
          3:Text:='Level';
          4:Text:='Place';
          5:Text:='Next';
        END;
      END;
    END;
  END;

  { Level }
  FOR I:=0 TO 9 DO
    WITH Button[I+18] DO
    BEGIN
      Mode:=2;
      X:=327;
      Y:=119+20*I;
      Text:=ToStr(I);
      IF I=Level THEN Down:=TRUE ELSE Down:=FALSE;
      Group:=3;
    END;

  { Pattern }
  FOR I:=1 TO 20 DO
    WITH Button[I+27] DO
    BEGIN
      Mode:=2;
      IF I<=10 THEN X:=404 ELSE X:=504;
      IF I<=10 THEN Y:=119+20*(I-1) ELSE Y:=119+20*(I-11);
      Group:=4;
      CASE Language OF
        1:
          CASE I OF
            1:Text:='Brez';
            2:Text:='Top';
            3:Text:='Grad';
            4:Text:='Sah';
            5:Text:='Stolpci';
            6:Text:='Kriz';
            7:Text:='Diagonala';
            8:Text:='Diamant';
            9:Text:='Klobuk';
            10:Text:='Hrib';
            11:Text:='Horizontala';
            12:Text:='Hisa';
            13:Text:='Pi';
            14:Text:='Tocki';
            15:Text:='Nakljucno';
            16:Text:='Sito #1';
            17:Text:='Sito #2';
            18:Text:='Stopnice';
            19:Text:='Vertikala';
            20:Text:='Valovi';
          END;
        2:
          CASE I OF
            1:Text:='None';
            2:Text:='Cannon';
            3:Text:='Castle';
            4:Text:='Chess';
            5:Text:='Columns';
            6:Text:='Cross';
            7:Text:='Diagonal';
            8:Text:='Diamond';
            9:Text:='Hat';
            10:Text:='Hill';
            11:Text:='Horizontal';
            12:Text:='House';
            13:Text:='Pi';
            14:Text:='Points';
            15:Text:='Random';
            16:Text:='Sieve #1';
            17:Text:='Sieve #2';
            18:Text:='Stairs';
            19:Text:='Vertical';
            20:Text:='Waves';
          END;
      END;
      IF I=Pattern THEN Down:=TRUE ELSE Down:=FALSE;
    END;
END;

{************************************************************************}
PROCEDURE SaveButtons;
{ Trenutno stanje gumbov menuja shrani v spremenljivke }
VAR I: Integer;
BEGIN
  IF Button[11].Down THEN Mode:=1 ELSE Mode:=2;
  IF Button[7].Down THEN Keys:=1 ELSE Keys:=2;
  FOR I:=0 TO 9 DO IF Button[I+18].Down THEN Level:=I;
  FOR I:=1 TO 20 DO IF Button[I+27].Down THEN Pattern:=I;
  IF Button[9].Down THEN Language:=1 ELSE Language:=2;
  SoundOn:=Button[6].Down;
  Grid:=Button[48].Down;
  DisplayScore:=Button[13].Down;
  DisplayRows:=Button[14].Down;
  DisplayLevel:=Button[15].Down;
  DisplayPlace:=Button[16].Down;
  DisplayNext:=Button[17].Down;
END;

{************************************************************************}
PROCEDURE Redefine;
{ Zahteva od igralce vnos novih tipk za razlicne funkcije v igri }
BEGIN
  HideMouseCursor;
  ClearDevice;
  SetTextStyle(SmallFont,HorizDir,7);
  SetTextJustify(CenterText,CenterText);
  SetFillStyle(1,LightGray);
  Bar(0,0,GetMaxX,GetMaxY);
  IF Button[7].Down THEN Keys:=1 ELSE Keys:=2;
  TempUP:=#0;
  TempDN:=#0;
  TempLT:=#0;
  TempRT:=#0;
  TempNext:=#0;
  TempLevel:=#0;
  TempShoot:=#0;
  Koncaj:=FALSE;
  SetColor(White);
  IF Language=1 THEN
  BEGIN
    OutTextXY(320,52,'Pritisni tipko za rotacijo: ');
    SetColor(Black);
    OutTextXY(322,53,'Pritisni tipko za rotacijo: ');
  END ELSE
  BEGIN
    OutTextXY(320,52,'Press key for Rotate: ');
    SetColor(Black);
    OutTextXY(322,53,'Press key for Rotate: ');
  END;
  REPEAT
    TempUP:=UpCase(Read_Key);
    HotTempUP:=HotKey;

    IF (TempUP=ESC) THEN BEGIN Koncaj:=TRUE;Break;END ELSE
    BEGIN
      IF Language=1 THEN DrawKey(Round(TextWidth('Pritisni tipko za rotacijo: ')/2)+320,44,Blue,TempUP) ELSE
        DrawKey(Round(TextWidth('Press key for Rotate: ')/2)+320,44,Blue,TempUP);
      Break;
    END;
  UNTIL FALSE;
  SetColor(White);
  IF NOT(Koncaj) THEN
    IF Language=1 THEN
    BEGIN
      OutTextXY(320,113,'Pritisni tipko za spust: ');
      SetColor(Black);
      OutTextXY(322,114,'Pritisni tipko za spust: ');
    END
  ELSE
  BEGIN
    OutTextXY(320,113,'Press key for Drop: ');
    SetColor(Black);
    OutTextXY(322,114,'Press key for Drop: ');
  END;
  IF NOT(Koncaj) THEN
    REPEAT
      TempDN:=UpCase(Read_Key);
      HotTempDN:=HotKey;
      IF (TempDN=ESC) THEN BEGIN Koncaj:=TRUE;Break;END ELSE
        IF (TempDN=TempUP)AND(HotTempDN=HotTempUP) THEN Beep ELSE
        BEGIN
          IF Language=1 THEN DrawKey(Round(TextWidth('Pritisni tipko za spust: ')/2)+320,105,Blue,TempDN) ELSE
            DrawKey(Round(TextWidth('Press key for Drop: ')/2)+320,105,Blue,TempDN);
          Break;
        END;
    UNTIL FALSE;

  SetColor(White);
  IF NOT(Koncaj) THEN
    IF Language=1 THEN
    BEGIN
      OutTextXY(320,174,'Pritisni tipko za premik v levo: ');
      SetColor(Black);
      OutTextXY(322,175,'Pritisni tipko za premik v levo: ');
    END
  ELSE
  BEGIN
    OutTextXY(320,174,' Press key to Move Left: ');
    SetColor(Black);
    OutTextXY(322,175,' Press key to Move Left: ');
  END;
  IF NOT(Koncaj) THEN
    REPEAT
      TempLT:=UpCase(Read_Key);
      HotTempLT:=HotKey;
      IF (TempLT=ESC) THEN BEGIN Koncaj:=TRUE;Break;END ELSE
        IF ((TempLT=TempUP)AND(HotTempLT=HotTempUP))OR((TempLT=TempDN)AND(HotTempLT=HotTempDN)) THEN Beep ELSE
        BEGIN
          IF Language=1 THEN DrawKey(Round(TextWidth('Pritisni tipko za premik v levo: ')/2)+320,166,Blue,TempLT) ELSE
            DrawKey(Round(TextWidth('Press key for Move Left: ')/2)+320,166,Blue,TempLT);
          Break;
        END;
    UNTIL FALSE;

  SetColor(White);
  IF NOT(Koncaj) THEN
    IF Language=1 THEN
    BEGIN
      OutTextXY(320,235,'Pritisni tipko za premik v desno: ');
      SetColor(Black);
      OutTextXY(322,236,'Pritisni tipko za premik v desno: ');
    END
  ELSE
  BEGIN
    OutTextXY(320,235,'Press key for Move Right: ');
    SetColor(Black);
    OutTextXY(322,236,'Press key for Move Right: ');
  END;
  IF NOT(Koncaj) THEN
    REPEAT
      TempRT:=UpCase(Read_Key);
      HotTempRT:=HotKey;
      IF (TempRT=ESC) THEN BEGIN Koncaj:=TRUE;Break;END ELSE
        IF ((TempRT=TempUP)AND(HotTempRT=HotTempUP))OR((TempRT=TempDN)AND(HotTempRT=HotTempDN))OR((TempRT=TempLT)AND
        (HotTempRT=HotTempLT))
        THEN Beep ELSE
        BEGIN
          IF Language=1 THEN DrawKey(Round(TextWidth('Pritisni tipko za premik v desno: ')/2)+320,227,Blue,TempRT) ELSE
            DrawKey(Round(TextWidth('Press key for Move Right: ')/2)+320,227,Blue,TempRT);
          Break;
        END;
    UNTIL FALSE;

  SetColor(White);
  IF NOT(Koncaj) THEN
    IF Language=1 THEN
    BEGIN
      OutTextXY(320,296,'Pritisni tipko za prikazi/skrij nasl.: ');
      SetColor(Black);
      OutTextXY(322,297,'Pritisni tipko za prikazi/skrij nasl.: ');
      SetColor(White);
      Line(367,292,367-2,292-2);
      Line(367,292,367+2,292-2);
      SetColor(Black);
      Line(367+1,292+1,367-2+1,292-2+1);
      Line(367+1,292+1,367+2+1,292-2+1);
    END
  ELSE
  BEGIN
    OutTextXY(320,296,'Press key for Show/Hide Next: ');
    SetColor(Black);
    OutTextXY(322,297,'Press key for Show/Hide Next: ');
  END;
  IF NOT(Koncaj) THEN
    REPEAT
      TempNext:=UpCase(Read_Key);
      HotTempNext:=HotKey;
      IF (TempNext=ESC) THEN BEGIN Koncaj:=TRUE;Break;END ELSE
        IF ((TempNext=TempUP)AND(HotTempNext=HotTempUP))OR((TempNext=TempDN)AND(HotTempNext=HotTempDN))OR((TempNext=TempLT)
        AND(HotTempNext=HotTempLT))
           OR((TempNext=TempRT)AND(HotTempNext=HotTempRT))
        THEN Beep ELSE
        BEGIN
          IF Language=1 THEN
            DrawKey(Round(TextWidth('Pritisni tipko za prikazi/skrij nasl.: ')/2)+320,288,Blue,TempNext)
          ELSE
            DrawKey(Round(TextWidth('Press key for Show/Hide Next: ')/2)+320,288,Blue,TempNext);
          Break;
        END;
    UNTIL FALSE;

  SetColor(White);
  IF NOT(Koncaj) THEN
    IF Language=1 THEN
    BEGIN
      OutTextXY(320,357,'Pritisni tipko za povecanje stopnje: ');
      SetColor(Black);
      OutTextXY(322,358,'Pritisni tipko za povecanje stopnje: ');
      SetColor(White);
      Line(365,353,365-2,353-2);
      Line(365,353,365+2,353-2);
      SetColor(Black);
      Line(365+1,353+1,365-2+1,353-2+1);
      Line(365+1,353+1,365+2+1,353-2+1);
    END
  ELSE
  BEGIN
    OutTextXY(320,357,'Press key for Increase Level: ');
    SetColor(Black);
    OutTextXY(322,358,'Press key for Increase Level: ');
  END;
  IF NOT(Koncaj) THEN
    REPEAT
      TempLevel:=UpCase(Read_Key);
      HotTempLevel:=HotKey;

      IF (TempLevel=ESC) THEN BEGIN Koncaj:=TRUE;Break;END ELSE
        IF ((TempLevel=TempUP)AND(HotTempLevel=HotTempUP))OR((TempLevel=TempDN)AND(HotTempLevel=HotTempDN))OR
        ((TempLevel=TempLT)
        AND(HotTempLevel=HotTempLT))
           OR((TempLevel=TempRT)AND(HotTempLevel=HotTempRT))OR((TempLevel=TempNext)AND(HotTempLevel=HotTempNext))
        THEN Beep ELSE
        BEGIN
          IF Language=1 THEN DrawKey(Round(TextWidth('Pritisni tipko za povecanje stopnje: ')/2)+320,349,Blue,TempLevel) ELSE
            DrawKey(Round(TextWidth('Press key for Increase Level: ')/2)+320,349,Blue,TempLevel);
          Break;
        END;
    UNTIL FALSE;

  SetColor(White);
  IF NOT(Koncaj) THEN
    IF Language=1 THEN
    BEGIN
      OutTextXY(320,418,'Pritisni tipko za strel iz topa: ');
      SetColor(Black);
      OutTextXY(322,419,'Pritisni tipko za strel iz topa: ');
    END
  ELSE
  BEGIN
    OutTextXY(320,418,'Press key for Cannon Shoot: ');
    SetColor(Black);
    OutTextXY(322,419,'Press key for Cannon Shoot: ');
  END;
  IF NOT(Koncaj) THEN
    REPEAT
      TempShoot:=UpCase(Read_Key);
      HotTempShoot:=HotKey;
      IF (TempShoot=ESC) THEN BEGIN Koncaj:=TRUE;Break;END ELSE
        IF ((TempShoot=TempUP)AND(HotTempShoot=HotTempUP))OR((TempShoot=TempDN)AND(HotTempShoot=HotTempDN))OR
        ((TempShoot=TempLT)AND(HotTempShoot=HotTempLT))OR((TempShoot=TempRT)AND(HotTempShoot=HotTempRT))OR
        ((TempShoot=TempNext)AND(HotTempShoot=HotTempNext))OR((TempShoot=TempLevel)AND(HotTempShoot=HotTempLevel))
        THEN Beep ELSE
        BEGIN
          IF Language=1 THEN DrawKey(Round(TextWidth('Pritisni tipko za strel iz topa: ')/2)+320,410,Blue,TempShoot) ELSE
            DrawKey(Round(TextWidth('Press key for Cannon Shoot: ')/2)+320,410,Blue,TempShoot);
          Break;
        END;
    UNTIL FALSE;
  SetTextJustify(LeftText,TopText);
  IF NOT(Koncaj) THEN
  BEGIN
    UniDelay(500);
    gUP[Keys]    := TempUP;
    gDN[Keys]    := TempDN;
    gLT[Keys]    := TempLT;
    gRT[Keys]    := TempRT;
    gNext[Keys]  := TempNext;
    gLevel[Keys] := TempLevel;
    gShoot[Keys] := TempShoot;
    HotgUP[Keys]    := HotTempUP;
    HotgDN[Keys]    := HotTempDN;
    HotgLT[Keys]    := HotTempLT;
    HotgRT[Keys]    := HotTempRT;
    HotgNext[Keys]  := HotTempNext;
    HotgLevel[Keys] := HotTempLevel;
    HotgShoot[Keys] := HotTempShoot;
  END;
  FadeIn(0);
  DrawMenu;
  FadeOut(0);
  ShowMouseCursor;
  ClearKBBuffer;
END;

BEGIN
  InitButtons;
  DrawMenu;
  ShowMouseCursor;
  Konec:=FALSE;
  Click:=-100;
  REPEAT
    IF (Click=-100)AND(GetMouseButton<>0) THEN REPEAT UNTIL GetMouseButton=0;
    Click:=ProceedButtons;
    IF Click=-1 THEN Stop;
    CASE Click OF
      { Play }
      1:
      BEGIN
        SaveButtons;
        GameLevel:=Level;
        GameDisplayNext:=DisplayNext;
        OpenHighScore;
        Konec:=TRUE;
      END;
      { Exit }
      2: Stop;
      { View High Score }
      3:
      BEGIN
        SaveButtons; { Rabimo zaradi zaporedne stevilke lestvice: Pattern, Mode }
        Name:=' ';
        DrawHighScore;
        ResetButtons;
        WITH Button[1] DO
        BEGIN
          X:=270;
          Y:=435;
          W:=100;
          H:=27;
          Color:=Blue;
          IF Language=1 THEN Text:='Nazaj' ELSE Text:='Back';
        END;
        DrawAllButtons;
        C:=#0;
        REPEAT
          IF KeyPressed THEN C:=ReadKey;
        UNTIL (ProceedButtons=1)OR((C<>#0)AND(C<>UP)AND(C<>DN)AND(C<>LT)AND(C<>RT));
        ClearKBBuffer;
        InitButtons;
        DrawMenu;
      END;
      { Save Settings }
      4:
      BEGIN
        SaveButtons;
        SaveSettings;
        Button[4].Down:=FALSE;
        DrawButton(Button[4]);
      END;
      { Redefine }
      5: Redefine;
      { Language }
      9,10:
      BEGIN
        SaveButtons;
        InitButtons;
        HideMouseCursor;
        SetFillStyle(1,LightGray);
        Bar(30,80,167,215);
        Bar(50,240,147,310);
        Bar(185,80,260,150);
        Bar(180,175,275,310);
        Bar(305,80,362,310);
        Bar(395,80,602,310);
        Bar(120,360,520,417);
        SetTextJustify(LeftText,TopText);
        SetTextStyle(SmallFont,HorizDir,5);
        IF Language=1 THEN
        BEGIN
          SetColor(Black);
          Stresica(536,137); { Hisa }
          Stresica(538,177); { Tocki }
          Stresica(421,174); { Sah }
          Stresica(568,197); { Nakljucno }
          Stresica(444,217); { Kriz }
          Stresica(222,217); { Tocke }
          Stresica(118,297);  { Angleski}
          SetColor(Blue);
          OutTextXY(32,80,'Splosne nastavitve');
          Stresica(65,85);
          OutTextXY(82,240,'Jezik');
          OutTextXY(204,180,'Prikaz');
          OutTextXY(308,80,'Stopnja');
          OutTextXY(212,80,'Igra');
          OutTextXY(475,80,'Vzorec');
        END ELSE
        BEGIN
          SetColor(Blue);
          SetColor(Blue);
          OutTextXY(42,80,'General Options');
          OutTextXY(68,240,'Language');
          OutTextXY(200,180,'Display');
          OutTextXY(316,80,'Level');
          OutTextXY(212,80,'Game');
          OutTextXY(472,80,'Pattern');
        END;
        DrawAllButtons;
        ShowMouseCursor;
      END;
    END;
  UNTIL Konec;
  SaveButtons;
  SetTextJustify(LeftText,TopText);
  HideMouseCursor;
  FadeIn(5); { Pocasi zatemni zaslon }
  ClearDevice;
  ClearKBBuffer;
END;

PROCEDURE GetDemoPos;

TYPE TResult = RECORD
  Hole,Y,X,R,V: Integer;
END;

VAR I,J,R,TempX,TempY,Start1,Stop1: Integer;
    imgPolje: ARRAY [0..PoljeX+1,1..PoljeY+1] OF Integer;
    CurrentResult, SavedResult: TResult;

FUNCTION StPolnihVrstic: Integer;
VAR I,J,V: Integer;
    VrsticaPolna: Boolean;
BEGIN
  FOR J:=1 TO PoljeY-1 DO
  BEGIN
    VrsticaPolna:=TRUE;
    FOR I:=1 TO PoljeX DO
      IF Polje[I,J]<>1 THEN BEGIN VrsticaPolna:=FALSE;Break;END;
    IF VrsticaPolna THEN Inc(V);
  END;
  StPolnihVrstic:=V;
END;

FUNCTION GetHole: Integer;
VAR I,J,K,Hole: Integer;
    B: Boolean;
BEGIN
  Hole:=0;
  FOR I:=1 TO PoljeX DO
    FOR J:=2 TO PoljeY DO
      IF Polje[I,J]=0 THEN
      BEGIN
        B:=True;
        FOR K:=1 TO J DO
          IF Polje[I,K]=1 THEN BEGIN Inc(Hole);Break;END;
      END;
  GetHole:=Hole;
END;

PROCEDURE SavePolje;
VAR I,J: Integer;
BEGIN
  FOR I:=0 TO PoljeX+1 DO
    FOR J:=1 TO PoljeY+1 DO
      imgPolje[I,J]:=Polje[I,J];
END;

PROCEDURE RestorePolje;
VAR I,J: Integer;
BEGIN
  FOR I:=0 TO PoljeX+1 DO
    FOR J:=1 TO PoljeY+1 DO
      Polje[I,J]:=imgPolje[I,J];
END;

BEGIN
  TempX:=X;
  TempY:=Y;
  SavePolje;
  SavedResult.Hole:=1000;
  SavedResult.X:=0;
  SavedResult.Y:=0;
  SavedResult.V:=0;
  setFillStyle(1,Black);
  Bar(480,100,550,300);
  OutTextXY(500,200,ToStr(GetHole));
  FOR R:=1 TO 4 DO
  BEGIN
    Razcleni(lik1[Now,R]);
    Start1:=1;
    Stop1:=PoljeX-D+1;
    IF (TRUE)AND(Now=5)AND((R=1)OR(R=3)) THEN
    BEGIN
      Start1:=-1;
      Stop1:=PoljeX-D+1;
    END;
    FOR X:=Start1 TO Stop1 DO
    BEGIN
      RestorePolje;
      Y:=0;
      REPEAT
        Inc(Y);
      UNTIL NOT Prosto(X,Y);
      Dec(Y);
      NastaviPolja(1);
      CurrentResult.Hole:=GetHole;
      CurrentResult.X:=X;
      CurrentResult.Y:=Y;
      CurrentResult.R:=R;
{      CurrentResult.V:=StPolnihVrstic;
      IF (CurrentResult.V>SavedResult.V) THEN
      BEGIN
        SavedResult:=CurrentResult;
      END ELSE
      IF (CurrentResult.Hole=SavedResult.Hole) THEN}
      IF (CurrentResult.Hole<SavedResult.Hole) THEN
      BEGIN
        SavedResult:=CurrentResult;
      END ELSE
      IF CurrentResult.Hole=SavedResult.Hole THEN
      BEGIN
        IF (CurrentResult.Y>SavedResult.Y) THEN
        BEGIN
          SavedResult:=CurrentResult;
        END;
      END;
    END;
  END;
  Razcleni(lik1[Now,SavedResult.R]);
  DemoX:=SavedResult.X;
  RestorePolje;
  X:=TempX;
  Y:=TempY;
END;

BEGIN
  Init_SB;
  Reset_SB;
  Init; { Inicializira, vse kar je potrebno inicializirati samo na zacetku }
  OpenSettings; { Prebere nastavitve menuja iz datoteke }
  IF NOT Testing THEN Uvod;
  IF NOT MouseInstalled THEN
  BEGIN
    SetFillStyle(1,LightGray);
    Bar(0,0,GetMaxX,GetMaxY);
    SetTextJustify(CenterText,CenterText);
    SetTextStyle(SmallFont,HorizDir,6);
    SetColor(Red);
    OutTextXY(320,224,'Mouse driver not installed');
    SetColor(Black);
    OutTextXY(320,244,'Press any key to exit');
    ReadKey;
    Stop;
  END;
  InitMouse;
  {}Start:
  Menu; { Menu za nastavitve }
  InitField; { Inicializira polje }
  InitShapes;
  Rows:=0;
  Score:=0;
  StLikov:=0;
  Name:='';
  CannonLine:=16;
  DrawField; { Narise igralno polje }
 IF Pattern=2 THEN BEGIN DrawCannonText(320,466,Cyan,gShoot[Keys],HotgShoot[Keys]);CannonText:=TRUE END ELSE CannonText:=FALSE;
  FadeOut(2); { "Odtemni" zaslon }
  { Nakljucno izbere lik }
  CASE Mode OF
    1:BEGIN Now:=Random(7)+1;Razcleni(lik1[Now,1]);END;
    2:BEGIN Now:=Random(17)+1;Razcleni(lik2[Now,1]);END;
  END;
  Next:=0;
  OldGetPlace:=0;
  DemoMode:=False;
  Time1:=Timer;
  REPEAT
    { Ce ni to prvi lik, postane trenuten lik, lik ki je bil prej izbran za
    naslednjega }
    IF Next<>0 THEN
    BEGIN
      Now:=Next;
      CASE Mode OF
        1:Razcleni(lik1[Now,1]);
        2:Razcleni(lik2[Now,1]);
      END;
    END;
    { Izbere naslednji lik }
    CASE Mode OF
      1:Next:=Random(7)+1;
      2:Next:=Random(17)+1;
    END;
    Inc(StLikov);

    { Na vsakih 5000 tock, poveca stopnjo igranja }
    IF (((Score>=5000)AND(OldScore<5000))OR((Score>=10000)AND(OldScore<10000))
       OR((Score>=15000)AND(OldScore<15000))OR((Score>=20000)AND(OldScore<20000))
       OR((Score>=25000)AND(OldScore<25000))OR((Score>=30000)AND(OldScore<30000))
       OR((Score>=35000)AND(OldScore<35000))OR((Score>=40000)AND(OldScore<40000))
       OR((Score>=45000)AND(OldScore<45000)))AND(Level<9)
    THEN
    BEGIN
      IF SoundOn THEN FOR I:=1 TO 10 DO SFX(I*100,I*10);
      Inc(GameLevel);
      DrawStatistics;
    END ELSE DrawStatistics;
    Time:=19-2*GameLevel; { Doloci hitrost padanja lika, glede na stopnjo igranja }
    X:=Round(6-D/2)+1; { Lik se bo prikazal na sredini igralnega polja }
    Rot:=1;
    Spust:=FALSE;
    Shoot:=FALSE;
    SpustY:=0; { Spremenljivka SpustY pove, na kateri visini je bil lik odvrzen }
    Y:=1;
    IF NOT(Prosto(X,Y)) THEN { Ce ni prostora za nov lik }
    BEGIN
      GameOver;
      IF C=ESC THEN GOTO Start;
      IF Score>HighScore.Score[20] THEN
      BEGIN
        ClearDevice;
        SetTextStyle(SmallFont,HorizDir,7);
        SetTextJustify(CenterText,CenterText);
        SetFillStyle(1,LightGray);
        Bar(0,0,GetMaxX,GetMaxY);
        FrameIn(40,100,600,350);
        FrameIn(59,252,581,292);
        IF Language=1 THEN
        BEGIN
          SetColor(Blue);
          OutTextXY(320+1,170+1,'Vnesi svoje ime za lestvico najboljsih 20:');
          Line(490,169,490-2,169-2);
          Line(490,169,490+2,169-2);
        END ELSE
        BEGIN
          SetColor(Blue);
          OutTextXY(320+1,170+1,'Enter your name for Top 20 High Score:');
        END;
        SetTextStyle(SmallFont,HorizDir,7);
        Beri(320,270,31,Name);
        IF Name<>'' THEN
        BEGIN
          OpenHighScore;
          OldGetPlace:=GetPlace;
          HighScore.Name[20]:=Name;
          HighScore.Score[20]:=Score;
          SortHighScore;
          SaveHighScore;
        END ELSE Score:=0; { Zaradi pomote pri oznacevanje trenutnega }
      END;
      ShowMouseCursor;
      DrawHighScore;
      ResetButtons;
      WITH Button[1] DO
      BEGIN
        X:=270;
        Y:=435;
        W:=100;
        H:=27;
        Color:=Blue;
        IF Language=1 THEN Text:='Naprej' ELSE Text:='Forward';
      END;
      DrawAllButtons;
      C:=#0;
      REPEAT
        IF KeyPressed THEN C:=ReadKey;
      UNTIL (ProceedButtons=1)OR((C<>#0)AND(C<>UP)AND(C<>DN)AND(C<>LT)AND(C<>RT));
      ClearKBBuffer;
      GOTO Start;
    END;
    { Ce je lik "Next" ze narisan, ga ne narise se enkrat}
    IF ((Score=0)OR(Next<>Now))AND(GameDisplayNext) THEN DrawNext;
    IF DemoMode THEN GetDemoPos;
    FOR Y:=1 TO PoljeY DO
    BEGIN
      FOR I:=1 TO 21 DO { V eni vrstici 20x preveri, ce je bilo kaj pritisnjeno }
        { Pri I=21 vec ne sprejema tipk, samo izvrsuje prejsnje pritiske. }
      BEGIN
        IF NOT(Spust) THEN BEGIN ReFresh;UniDelay(Time);END ELSE
          IF (Spust)AND(NOT(Prosto(X,Y+1))) THEN Spust:=FALSE;
        { Tudi pri veliki hitrosti (Level) lahko premikamo lik po podlagi }
        IF (NOT(Prosto(X,Y+1)))AND(GameLevel>2) THEN Time:=12 ELSE
          IF Time=12 THEN Time:=19-2*GameLevel;
        IF ((KeyPressed)OR((DemoMode)AND(I=1)))AND(I<>21) THEN
        BEGIN
          IF NOT DemoMode THEN
          BEGIN
            C:=Read_Key
          END ELSE
          IF Y=1 THEN
          BEGIN
            X:=DemoX;
            C:=DN;
            HotKey:=True;
          END;
          IF CannonLine=PoljeY+1 THEN
          BEGIN
            DrawCannonText(320,466,Black,gShoot[Keys],HotgShoot[Keys]);
            CannonLine:=PoljeY+2; {da ne zazene znova}
          END;
          IF (UpCase(C)=gLT[Keys])AND(HotgLT[Keys]=HotKey)AND(Prosto(X-1,Y)) THEN Dec(X) ELSE
            IF (UpCase(C)=gRT[Keys])AND(HotgRT[Keys]=HotKey)AND(Prosto(X+1,Y)) THEN Inc(X) ELSE
              IF (UpCase(C)=gDN[Keys])AND(HotgDN[Keys]=HotKey) THEN BEGIN SpustY:=Y;Spust:=TRUE;END ELSE
                IF C=ESC THEN GOTO Start ELSE
                  IF (UpCase(C)=gLevel[Keys])AND(HotgLevel[Keys]=HotKey)AND(GameLevel<9) THEN
                  BEGIN
                    IF SoundOn THEN FOR I:=1 TO 10 DO SFX(I*100,I*10);
                    Inc(GameLevel);
                    Time:=19-2*GameLevel;
                    IF DisplayLevel THEN
                    BEGIN
                      SetFillStyle(1,Black);
                      Bar(0+3,205-3,124-3,220-3);
                      SetColor(Cyan);
                      OutTextXY(Round(62-TextWidth(ToStr(GameLevel))/2),200-4,ToStr(GameLevel));
                    END
                  END
                  ELSE
                    {***************}
                    IF (UpCase(C)=gNext[Keys])AND(HotgNext[Keys]=HotKey) THEN
                    BEGIN
                      IF (Now=Next)AND(Shoot) THEN
                      BEGIN
                        Temp:=Lik1[Now,Rot];
                        InitShapes;
                      END;
                      GameDisplayNext:=NOT(GameDisplayNext);
                      IF NOT(GameDisplayNext) THEN
                      BEGIN
                        SetFillStyle(1,Black);
                        Bar(0,300,125,470);
                      END ELSE
                      BEGIN
                        DrawNext;
                        SetFillStyle(1,Black);
                        Bar(0,310,124,337);
                        SetColor(Green);
                        IF Language=1 THEN
                          OutTextXY(62-Round(TextWidth('Naslednji:')/2),310,'Naslednji:')
                        ELSE
                          OutTextXY(62-Round(TextWidth('Next:')/2),310,'Next:');
                      END;
                      IF (Now=Next)AND(Shoot) THEN Lik1[Now,Rot]:=Temp
                    END ELSE
                      {***************}
                      IF (UpCase(C)=gUP[Keys])AND(HotgUP[Keys]=HotKey) THEN
                      BEGIN
                        Inc(Rot);
                        IF Rot>4 THEN Rot:=1;
                        CASE Mode OF
                          1:Razcleni(lik1[Now,Rot]);
                          2:Razcleni(lik2[Now,Rot]);
                        END;
                        IF NOT(Prosto(X,Y)) THEN
                        BEGIN
                          Dec(Rot);
                          IF Rot=0 THEN Rot:=4;
                          CASE Mode OF
                            1:Razcleni(lik1[Now,Rot]);
                            2:Razcleni(lik2[Now,Rot]);
                          END
                        END ELSE BEGIN ReFresh;END;
                      END ELSE
                        {***************}
               IF (UpCase(C)=gShoot[Keys])AND(HotgShoot[Keys]=HotKey)AND(Shoot=FALSE)AND(Pattern=2)AND(CannonLine<=PoljeY) THEN
                        { Strel iz topa }
                        BEGIN
                          IF SoundOn THEN OpenWhistle;
                          IF CannonText THEN DrawCannonText(320,466,Black,gShoot[Keys],HotgShoot[Keys]);
                          CannonText:=FALSE;
                          IF SoundOn THEN FOR I:=1 TO 10 DO SFX(I*100,I);
                          Shoot:=TRUE;
                          FOR I:=(CannonLine-1) DOWNTO 1 DO
                          BEGIN
                            PutImage(7*a-a+188,I*a-a,P[11]^,NormalPut);
                            Delay(20);
                            PutImage(7*a-a+188,I*a-a,P[0]^,NormalPut);
                            IF Grid THEN PutPixel(189+6*a,(I-1)*a+1,Cyan);
                            IF Polje[7,I]=1 THEN Polje[7,I]:=0 ELSE
                              IF (Polje[7,I]=-1) THEN
                              BEGIN
                                J:=0;
                                REPEAT
                                  CASE Mode OF
                                    1:
                                    BEGIN Delete(Lik1[Now,Rot],J+7-X+1,1);
                                      Insert('0',Lik1[Now,Rot],J+7-X+1);
                                    END;
                                    2:
                                    BEGIN Delete(Lik2[Now,Rot],J+7-X+1,1);
                                      Insert('0',Lik2[Now,Rot],J+7-X+1);
                                    END;
                                  END;
                                  Inc(J,D);
                                UNTIL ((J=Length(Lik1[Now,Rot])-1)AND(Mode=1))OR
                                      ((J=Length(Lik2[Now,Rot])-1)AND(Mode=2));
                              END;
                          END;
                          I:=Rot;
                          J:=0;
                          REPEAT
                            Inc(J);
                            Inc(I);
                            CASE Mode OF
                              1:IF I=5 THEN BEGIN I:=1;Lik1[Now,I]:=Rotacija(Lik1[Now,4]);END ELSE
                                Lik1[Now,I]:=Rotacija(Lik1[Now,I-1]);
                              2:IF I=5 THEN BEGIN I:=1;Lik2[Now,I]:=Rotacija(Lik2[Now,4]);END ELSE
                                Lik2[Now,I]:=Rotacija(Lik2[Now,I-1]);
                            END;
                          UNTIL J=4;
                          CASE Mode OF
                            1:Razcleni(Lik1[Now,Rot]);
                            2:Razcleni(Lik2[Now,Rot]);
                          END;
                          IF Pos('1',Copy(Pod,1,Length(Pod)))=0 THEN Y:=PoljeY;
                          I:=20;
                        END;

        END;
      END;
      ReFresh;
      OldScore:=Score;
      IF NOT(Prosto(X,Y+1)) THEN { Lik je pri tleh }
      BEGIN
        IF SpustY<>0 THEN Inc(Score,Y-SpustY+GameLevel+10) ELSE Inc(Score,GameLevel+5);
        NastaviPolja(1); { "Fiksira" lik }
        Break;
      END;
    END;
    Podri; { Preveri, ce so kje polne vrste in jih podre }
    IF Shoot THEN InitShapes; { Ce je bil lik prestreljen, se postavi v normalno obliko }
    Shoot:=FALSE;
  UNTIL FALSE;
  Stop;
END.
