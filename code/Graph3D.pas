{

0 - Normal
1 - Check
2 - Radio

3 - Normal -
4 - Normal -

5 - Input

}

UNIT Graph3D;
{ Graph3D Unit (C) by David Krmpotic }

INTERFACE

USES Graph,Mouse,Crt,Keyb,Keys,Screen,Strings,Dos,Misc;

TYPE CharSet=SET OF Char;

TYPE TButton = RECORD
  X,Y,Size,Color: Word;
  Text: String[35];
  Down,Dead: Boolean;
  CASE Mode: Integer OF
    0,3,4: (W,H: Integer; Shade: Boolean);
    1: (A: Integer);
    2: (R,Group: Integer);
    5: (MaxLength: Byte; ValidChars: CharSet);
END;

CONST MaxButtons=100;

VAR Button: ARRAY [1..MaxButtons] OF TButton;
  NrButton: Integer;
  GloveCursor: Boolean;
  H,M,S,VirH,VirM,VirS,S100,ScreenS: Word;

PROCEDURE Stresica(X,Y: Integer);
PROCEDURE RefreshClock;
PROCEDURE LineIn(X1,Y1,X2,Y2: Integer);
PROCEDURE LineOut(X1,Y1,X2,Y2: Integer);
PROCEDURE FrameIn(X1,Y1,X2,Y2: Integer);
PROCEDURE FrameOut(X1,Y1,X2,Y2: Integer);
PROCEDURE ResetButtons;
PROCEDURE DrawButton(VAR Button: TButton);
PROCEDURE DrawAllButtons;
FUNCTION  ProceedButtons: Integer;

IMPLEMENTATION

{****************************** [Stresica] *********************************}
PROCEDURE Stresica(X,Y: Integer);
BEGIN
  Line(X,Y,X-1,Y-1);
  Line(X,Y,X+1,Y-1);
END;

{****************************** [LineIn] ************************************}
PROCEDURE LineIn(X1,Y1,X2,Y2: Integer);
{ Narise konkavno crto }
BEGIN
  SetColor(Black);
  IF Y1=Y2 THEN Line(X1,Y1-1,X2,Y2-1) ELSE { Crta je vodoravna }
    IF X1=X2 THEN Line(X1-1,Y1,X2-1,Y2); { Crta je navpicna }
  SetColor(White);
  Line(X1,Y1,X2,Y2);
END;

{****************************** [LineOut] ***********************************}
PROCEDURE LineOut(X1,Y1,X2,Y2: Integer);
{ Narise konveksno crto }
BEGIN
  SetColor(White);
  IF Y1=Y2 THEN Line(X1,Y1-1,X2,Y2-1) ELSE { Crta je vodoravna }
    IF X1=X2 THEN Line(X1-1,Y1,X2-1,Y2); { Crta je navpicna }
  SetColor(Black);
  Line(X1,Y1,X2,Y2);
END;

{****************************** [FrameIn] ***********************************}
PROCEDURE FrameIn(X1,Y1,X2,Y2: Integer);
{ Narise konkaven okvir }
BEGIN
  SetColor(White);
  Line(X1,Y1,X2,Y1); { Ä }
  Line(X1,Y1,X1,Y2); { ³ }
  SetColor(Black);
  Line(X2,Y1,X2,Y2); { ³ }
  Line(X1,Y2,X2,Y2); { Ä }
  Line(X1-1,Y1-1,X2,Y1-1); { Ä }
  Line(X1-1,Y1,X1-1,Y2);   { ³ }
  SetColor(White);
  Line(X2+1,Y1-1,X2+1,Y2); { ³ }
  Line(X1-1,Y2+1,X2+1,Y2+1); { Ä }
END;

{****************************** [FrameOut] **********************************}
PROCEDURE FrameOut(X1,Y1,X2,Y2: Integer);
{ Narise konveksen okvir }
BEGIN
  SetColor(Black);
  Line(X1,Y1,X2,Y1); { Ä }
  Line(X1,Y1,X1,Y2); { ³ }
  SetColor(White);
  Line(X2,Y1,X2,Y2); { ³ }
  Line(X1,Y2,X2,Y2); { Ä }
  Line(X1-1,Y1-1,X2,Y1-1); { Ä }
  Line(X1-1,Y1,X1-1,Y2);   { ³ }
  SetColor(Black);
  Line(X2+1,Y1-1,X2+1,Y2); { ³ }
  Line(X1-1,Y2+1,X2+1,Y2+1); { Ä }
END;

{****************************** [ResetButtons] *****************************}
PROCEDURE ResetButtons;
VAR I: Integer;
BEGIN
  FOR I:=1 TO NrButton DO
  BEGIN
    Button[I].Mode:=0;
    Button[I].X:=0;
    Button[I].Y:=0;
    Button[I].H:=0;
    Button[I].W:=0;
    Button[I].R:=0;
    Button[I].A:=0;
    Button[I].MaxLength:=0;
    Button[I].ValidChars:=[];
    Button[I].Size:=0;
    Button[I].Color:=0;
    Button[I].Text:='';
    Button[I].Group:=0;
    Button[I].Down:=False;
    Button[I].Dead:=False;
    Button[I].Shade:=False;
  END;
  NrButton:=0;
END;

{****************************** [MouseInButton] ***********************************}
FUNCTION MouseInButton(Button: TButton): Boolean;
VAR Temp: String[35];
    I: Byte;
BEGIN
  Temp:='';
  WITH Button DO
  CASE Mode OF
    0,3,4: MouseInButton:=MouseIn(X,Y,X+W,Y+H);
    1: BEGIN
         SetTextStyle(SmallFont,HorizDir,Size);
         MouseInButton:=(MouseIn(X-A DIV 2,Y-A DIV 2,X+A-A DIV 2,Y+A-A DIV 2))OR
           (MouseIn(X+Round(A/2)-A DIV 2,Y-A DIV 2-1,X+TextWidth(Text)+Round(1.5*R+2)-A DIV 2,Y+A+3-A DIV 2));
       END;
    2: BEGIN
         SetTextStyle(SmallFont,HorizDir,Size);
         MouseInButton:=(MouseInCircle(X,Y,R))OR(MouseIn(X,Y-Round(R)-3,X+TextWidth(Text)+3*R+2,Y+Round(R)+3));
       END;
    5: BEGIN
         SetTextStyle(SmallFont,HorizDir,Size);
         FOR I:=1 TO MaxLength DO Temp:=Temp+'M';
         MouseInButton:=MouseIn(X-5,Y-2,X+TextWidth(Temp)+6,Y+3*Size+2+Size-5);
       END;
  END;
  IF Button.Dead THEN MouseInButton:=False;
END;

{****************************** [DrawButton] *******************************}
PROCEDURE DrawButton(VAR Button: TButton);
VAR I: Integer;
    Temp: String[35];
BEGIN
  SetTextStyle(SmallFont,HorizDir,Button.Size);
  SetTextJustify(CenterText,CenterText);
  HideMouseCursor;
  WITH Button DO
  IF Mode=1 THEN
  BEGIN
    IF Down=TRUE THEN SetColor(Black) ELSE SetColor(LightGray);
    { "Kljukica" (*4X*) }
    Line(X+Round(0.2*A)-A DIV 2,Y+Round(0.4*A)-A DIV 2,X+Round(0.3*A)-A DIV 2,Y+A-Round(0.3*A)-A DIV 2);
    Line(X+Round(0.2*A)+1-A DIV 2,Y+Round(0.4*A)-A DIV 2,X+Round(0.3*A)-A DIV 2,Y+A-Round(0.3*A)-A DIV 2);
    Line(X+Round(0.3*A)-A DIV 2,Y+A-Round(0.3*A)-A DIV 2,X+A-Round(0.2*A)-A DIV 2,Y+Round(0.2*A)-A DIV 2);
    Line(X+Round(0.3*A)-A DIV 2,Y+A-Round(0.3*A)+1-A DIV 2,X+A-Round(0.2*A)-A DIV 2,Y+Round(0.2*A)+1-A DIV 2);
  END ELSE
  IF Mode=2 THEN
  BEGIN
    IF Down=TRUE THEN
    BEGIN
      SetColor(Black);
      Circle(X,Y,Round(1/3*R));
      SetFillStyle(1,Black);
      FloodFill(X,Y,Black);
    END ELSE
    BEGIN
      SetColor(LightGray);
      Circle(X,Y,Round(1/3*R));
      SetFillStyle(1,LightGray);
      FloodFill(X,Y,LightGray);
    END;
  END ELSE
  IF Mode=5 THEN
  BEGIN
    SetTextJustify(LeftText,TopText);
    SetColor(Black);
    OutTextXY(X,Y,Text);
    IF MaxLength=0 THEN MaxLength:=5;
    Temp:='';
    FOR I:=1 TO MaxLength DO Temp:=Temp+'M';
    FrameIn(X-5,Y-2,X+TextWidth(Temp)+5,Y+3*Size+2+Size-5);
  END ELSE
  BEGIN
    IF W=0 THEN W:=TextWidth(Text)+Size*3;
    IF H=0 THEN H:=TextHeight(Text)+Size;
    CASE Down OF
      TRUE:SetColor(Black);
      FALSE:SetColor(White);
    END;
    Line(X,Y,X+W,Y); { Ä }
    Line(X,Y,X,Y+H); { ³ }
    CASE Down OF
      TRUE:SetColor(White);
      FALSE:SetColor(Black);
    END;
    Line(X,Y+H,X+W,Y+H); { Ä }
    Line(X+W,Y,X+W,Y+H); { ³ }
    SetTextJustify(LeftText,CenterText);
    SetColor(LightGray);
    CASE Down OF
      TRUE:
      BEGIN
        IF Shade THEN
        BEGIN
          OutTextXY(X+Round(W/2)+2-Round(TextWidth(Text)/2)-1,Y+Round((H-Size)/2),Text);
          OutTextXY(X+1+Round(W/2)+2-Round(TextWidth(Text)/2)-1,Y+1+Round((H-Size)/2),Text);
          SetColor(White);
          OutTextXY(X+Round(W/2)+2-Round(TextWidth(Text)/2)+1-1,Y+Round((H-Size)/2)+1,Text);
          SetColor(Color);
          OutTextXY(X+1+Round(W/2)+2-Round(TextWidth(Text)/2),Y+1+Round((H-Size)/2)+1,Text);
        END ELSE
        BEGIN
          OutTextXY(X+Round(W/2)+2-Round(TextWidth(Text)/2)-1,Y+Round((H-Size)/2),Text);
          SetColor(Color);
          OutTextXY(X+Round(W/2)+2-Round(TextWidth(Text)/2)+1-1,Y+Round((H-Size)/2)+1,Text);
        END;
      END;
      FALSE:
      BEGIN
        IF Shade THEN
        BEGIN
          OutTextXY(X+Round(W/2)+2-Round(TextWidth(Text)/2)+1-1,Y+Round((H-Size)/2)+1,Text);
          OutTextXY(X+1+Round(W/2)+2-Round(TextWidth(Text)/2)+1-1,Y+1+Round((H-Size)/2)+1,Text);
          SetColor(White);
          OutTextXY(X+Round(W/2)+2-Round(TextWidth(Text)/2)-1,Y+Round((H-Size)/2),Text);
          SetColor(Color);
          OutTextXY(X+1+Round(W/2)+2-Round(TextWidth(Text)/2)-1,Y+1+Round((H-Size)/2),Text);
        END ELSE
        BEGIN
          OutTextXY(X+Round(W/2)+2-Round(TextWidth(Text)/2)+1-1,Y+Round((H-Size)/2)+1,Text);
          SetColor(Color);
          OutTextXY(X+Round(W/2)+2-Round(TextWidth(Text)/2)-1,Y+Round((H-Size)/2),Text);
        END;
      END;
    END;
  END;
  SetTextJustify(LeftText,TopText);
  ShowMouseCursor;
END;

{****************************** [DrawAllButtons] ***************************}
PROCEDURE DrawAllButtons;
VAR I: Integer;
BEGIN
  FOR I:=1 TO MaxButtons DO IF Button[I].X=0 THEN BEGIN NrButton:=I-1;Break;END;
  FOR I:=1 TO NrButton DO
  IF NOT Button[I].Dead THEN
  BEGIN
    IF Button[I].Size=0 THEN Button[I].Size:=5;
    IF Button[I].Mode=1 THEN
    WITH Button[I] DO
    BEGIN
      SetTextStyle(SmallFont,HorizDir,Size);
      SetTextJustify(LeftText,TopText);
      IF A=0 THEN A:=Size*2;
      SetColor(Color);
      OutTextXY(X+Round(2*A)-A DIV 2,Y-Round(1/3*Size)-A DIV 2-1,Text);
      SetColor(Black);
      Line(X-A DIV 2,Y-A DIV 2,X+A-A DIV 2,Y-A DIV 2); { Ä }
      Line(X-A DIV 2,Y-A DIV 2,X-A DIV 2,Y+A-A DIV 2); { ³ }
      SetColor(White);
      Line(X-A DIV 2,Y+A-A DIV 2,X+A-A DIV 2,Y+A-A DIV 2); { Ä }
      Line(X+A-A DIV 2,Y-A DIV 2,X+A-A DIV 2,Y+A-A DIV 2); { ³ }
    END ELSE
    IF Button[I].Mode=2 THEN
    WITH Button[I] DO
    BEGIN
      SetTextStyle(SmallFont,HorizDir,Size);
      SetTextJustify(LeftText,TopText);
      IF R=0 THEN R:=Size;
      SetColor(Color);
      OutTextXY(X+3*R,Y-Round(TextHeight(Text)/2)-Round(1/3*Size)+(Size-4),Text);
      SetColor(Black);
      Arc(X,Y,40,220,R);
      SetColor(White);
      Arc(X,Y,220,40,R);
    END;
    DrawButton(Button[I]);
  END;
END;

PROCEDURE RefreshClock;
PROCEDURE DrawClock(H,M,S,Color: Word);
VAR Time: String[8];
BEGIN
  Time:='';
  IF H<=9 tHEN Time:=Time+'0';
  Time:=Time+ToStr(H)+':';
  IF M<=9 tHEN Time:=Time+'0';
  Time:=Time+ToStr(M)+':';
  IF S<=9 tHEN Time:=Time+'0';
  Time:=Time+ToStr(S);
  SetTextStyle(SmallFont,HorizDir,5);
  SetTextJustify(LeftText,TopText);
  SetColor(Color);
  OutTextXY(584-TextWidth(Time) DIV 2,12,Time);
END;
BEGIN
  GetTime(VirH,VirM,VirS,S100);
  IF ScreenS<>VirS THEN
  BEGIN
    ScreenS:=VirS;
    DrawClock(H,M,S,LightGray);
    GetTime(H,M,S,S100);
    WaitRetrace;
    DrawClock(VirH,VirM,VirS,Black);
  END;
END;

{****************************** [ProceedButtons] ****************************}
FUNCTION ProceedButtons: Integer;
VAR I,ActiveButton,Utrip,LastRadioButton: Integer;
  StartDown,RealDown,Inside: Boolean;
  C: Char;
  Temp,Old: String[35];
BEGIN
  RefreshClock;
  ProceedButtons:=0;
  ActiveButton:=0;
  LastRadioButton:=0;
  C:=#0;
  IF KeyPressed THEN
    BEGIN
      C:=ReadKey;
      CASE C OF
        #72:SetMouseXY(GetMouseX,GetMouseY-5);
        #80:SetMouseXY(GetMouseX,GetMouseY+5);
        #75:SetMouseXY(GetMouseX-5,GetMouseY);
        #77:SetMouseXY(GetMouseX+5,GetMouseY);
        #27: ProceedButtons:=-1;
      END;
    END;
  FOR I:=1 TO NrButton DO
    IF (MouseInButton(Button[I])) THEN
    BEGIN
      ActiveButton:=I;
      Break;
    END;
  IF (Button[1].X=280)AND(Button[1].Y=200)AND(Button[1].Mode=5) THEN ActiveButton:=1;
  IF (ActiveButton<>0)AND(NOT GloveCursor) THEN
  BEGIN
    IF Button[ActiveButton].Mode=5 THEN SetMouseCursor(VertLine) ELSE SetMouseCursor(Glove);
    GloveCursor:=TRUE;
  END;
  FOR I:=1 TO NrButton DO
    IF (Button[I].Mode=2)AND(Button[I].Down)AND(Button[I].Group=Button[ActiveButton].Group)AND(I<>ActiveButton) THEN
      LastRadioButton:=I;
  IF (Button[ActiveButton].Mode=5)AND((GetMouseButton=1)OR(C=ENTER)OR((Button[1].X=280)AND(Button[1].Y=200)
  AND(Button[1].Mode=5))) THEN
  WITH Button[ActiveButton] DO
  BEGIN
    Temp:=Text;
    Old:=Text;
    REPEAT
      SetTextStyle(SmallFont,HorizDir,Size);
      HideMouseCursor;
      SetColor(LightGray);
      Line(X+TextWidth(Temp)+1,Y,X+TextWidth(Temp)+1,Y+3*Size+Size-5);
      SetColor(Black);
      Line(X+TextWidth(Text)+1,Y,X+TextWidth(Text)+1,Y+3*Size+Size-5);
      OutTextXY(X,Y,Text);
      ShowMouseCursor;
      C:=#1;
      REPEAT
        RefreshClock;
        IF KeyPressed THEN C:=Read_Key;
        Inside:=False;
        FOR I:=1 TO NrButton DO
          IF (MouseInButton(Button[I])) THEN
          BEGIN
            IF NOT GloveCursor THEN IF Button[I].Mode=5 THEN SetMouseCursor(VertLine) ELSE SetMouseCursor(Glove);
            GloveCursor:=True;
            Inside:=True;
          END;
        IF (NOT Inside)AND(GloveCursor) THEN
        BEGIN
          SetMouseCursor(Normal);
          GloveCursor:=False;
        END;
      UNTIL (((C=BKSPACE)OR(C=ENTER)OR(C=ESC)OR(Length(Text)<MaxLength))
        AND(C<>#1))OR((GetMouseButton=1)AND(NOT MouseInButton(Button[ActiveButton])));
      Temp:=Text;
IF (C<>ENTER)AND(C<>BKSPACE)AND(C<>#1)AND(Length(Text)<MaxLength)AND(NOT HotKey)AND(C<>'%')AND((C IN ValidChars)
OR(ValidChars=[]))
        THEN Text:=Text+C;
      IF (C=BKSPACE)AND(Text<>'') THEN
      BEGIN
        SetTextStyle(SmallFont,HorizDir,Size);
        WaitRetrace;
        SetColor(LightGray);
        HideMouseCursor;
        OutTextXY(X,Y,Text);
        ShowMouseCursor;
        Delete(Text,Length(Text),1);
      END;
    UNTIL (C=ESC)OR(C=ENTER)OR((GetMouseButton=1)AND(NOT MouseInButton(Button[ActiveButton])));
    IF (C=ENTER)OR(GetMouseButton=1) THEN ProceedButtons:=ActiveButton;
    SetColor(LightGray);
    SetTextStyle(SmallFont,HorizDir,Size);
    HideMouseCursor;
    Line(X+TextWidth(Text)+1,Y,X+TextWidth(Text)+1,Y+3*Size+Size-5);
    IF (C=ESC)OR(((GetMouseButton=1)OR(Text='')OR(Text='0'))AND(Button[ActiveButton].Y=463)AND(Button[ActiveButton].X=65)) THEN
    BEGIN
      SetColor(LightGray);
      OutTextXY(X,Y,Text);
      Text:=Old;
      SetColor(Black);
      OutTextXY(X,Y,Text);
    END;
    IF (C=ENTER)AND(Old<>Text)AND(Text<>'0')AND(Text<>'')
    AND(Button[ActiveButton].Y=463)AND(Button[ActiveButton].X=65) THEN ProceedButtons:=-11;
    ShowMouseCursor;
  END ELSE
  IF (ActiveButton<>0)AND((GetMouseButton=1)OR(C=#13))AND NOT((Button[ActiveButton].Mode=2)AND(Button[ActiveButton].Down)) THEN
    BEGIN
    WITH Button[ActiveButton] DO
    BEGIN
      IF (Mode=3)AND(Down) THEN StartDown:=FALSE ELSE StartDown:=Down;
      RealDown:=Down;
      IF (NOT Down)OR(Mode=4) THEN
      BEGIN
        Down:=NOT(Down);
        DrawButton(Button[ActiveButton]);
      END;
      Utrip:=0;
      REPEAT
        IF MouseInButton(Button[ActiveButton]) THEN Inside:=TRUE ELSE Inside:=FALSE;
        IF (((NOT Inside)AND(NOT StartDown))OR((Inside)AND(StartDown)))AND((Utrip=2)OR(Utrip=0)) THEN
        BEGIN
          Down:=FALSE;
          IF (NOT((Mode=3)AND(RealDown)))AND(NOT((Mode=2)AND(RealDown))) THEN
          BEGIN
            IF MouseInButton(Button[ActiveButton]) THEN Inside:=TRUE ELSE Inside:=FALSE;
            DrawButton(Button[ActiveButton]);
          END;
          IF Mode=2 THEN
              FOR I:=1 TO NrButton DO
                IF (Button[I].Mode=2)AND(Button[I].Group=Group)AND(Button[I].Down)AND(I<>ActiveButton) THEN
                BEGIN
                  Button[I].Down:=False;
                  DrawButton(Button[I]);
                END;
          IF Mode=2 THEN
            BEGIN
              Button[LastRadioButton].Down:=True;
              DrawButton(Button[LastRadioButton]);
            END;
          IF NOT StartDown THEN SetMouseCursor(Normal) ELSE SetMouseCursor(Glove);
          Utrip:=1;
        END ELSE
          IF ((((Inside))AND(NOT StartDown))OR((NOT Inside)AND(StartDown)))AND((Utrip=1)OR(Utrip=0)) THEN
          BEGIN
            Down:=TRUE;
            IF (NOT((Mode=3)AND(RealDown)))AND(NOT((Mode=2)AND(RealDown))) THEN
            BEGIN
              IF MouseInButton(Button[ActiveButton]) THEN Inside:=TRUE ELSE Inside:=FALSE;
              DrawButton(Button[ActiveButton]);
            END;
            IF Mode=2 THEN
              FOR I:=1 TO NrButton DO
                IF (Button[I].Mode=2)AND(Button[I].Group=Group)AND(Button[I].Down)AND(I<>ActiveButton) THEN
                BEGIN
                  Button[I].Down:=False;
                  DrawButton(Button[I]);
                END;
            IF StartDown THEN SetMouseCursor(Normal) ELSE SetMouseCursor(Glove);
            Utrip:=2;
          END;
      UNTIL (GetMouseButton=0)OR(C=#27)OR(C=#13);
      IF ((Mode=3)OR(Mode=2))AND(RealDown) THEN Down:=TRUE;
      IF (Inside)AND(Mode=0) THEN
      BEGIN
        Down:=FALSE;
        DrawButton(Button[ActiveButton]);
      END;
      IF (Inside)AND(NOT((Mode=2)AND(RealDown)))AND(C<>#27) THEN ProceedButtons:=ActiveButton;
    END;
    END ELSE IF (GetMouseButton=1)AND(Button[ActiveButton].Mode=2)AND(Button[ActiveButton].Down) THEN
    BEGIN
      REPEAT
        Inside:=False;
        FOR I:=1 TO NrButton DO
          IF (MouseInButton(Button[I])) THEN
          BEGIN
            IF NOT GloveCursor THEN IF Button[I].Mode=5 THEN SetMouseCursor(VertLine) ELSE SetMouseCursor(Glove);
            GloveCursor:=True;
            Inside:=True;
          END;
        IF (NOT Inside)AND(GloveCursor) THEN
        BEGIN
          SetMouseCursor(Normal);
          GloveCursor:=False;
        END;
      UNTIL GetMouseButton=0;

      IF MouseInButton(Button[ActiveButton]) THEN ProceedButtons:=ActiveButton;
    END;
  IF (ActiveButton=0)AND(GloveCursor) THEN
  BEGIN
    SetMouseCursor(Normal);
    GloveCursor:=FALSE;
  END;
END;

BEGIN
END.