unit ModuleGraph;

{$mode objfpc}{$H+}

interface

Uses MyTypes, SystemFunc, raylib;

implementation

const
  {Инициплизация всех цветов в константу}
  COLORS: array[0..15] of TColor = (
    (r: 0;   g: 0;   b: 0;   a: 255), // 0 - Черный
    (r: 0;   g: 0;   b: 170; a: 255), // 1 - Синий
    (r: 0;   g: 170; b: 0;   a: 255), // 2 - Зеленый
    (r: 0;   g: 170; b: 170; a: 255), // 3 - Голубой
    (r: 170; g: 0;   b: 0;   a: 255), // 4 - Красный
    (r: 170; g: 0;   b: 170; a: 255), // 5 - Фиолетовый
    (r: 170; g: 85;  b: 0;   a: 255), // 6 - Коричневый
    (r: 170; g: 170; b: 170; a: 255), // 7 - Светло-серый
    (r: 85;  g: 85;  b: 85;  a: 255), // 8 - Темно-серый
    (r: 85;  g: 85;  b: 255; a: 255), // 9 - Ярко-синий
    (r: 85;  g: 255; b: 85;  a: 255), // 10 - Ярко-зеленый
    (r: 85;  g: 255; b: 255; a: 255), // 11 - Ярко-голубой
    (r: 255; g: 85;  b: 85;  a: 255), // 12 - Ярко-красный
    (r: 255; g: 85;  b: 255; a: 255), // 13 - Ярко-фиолетовый
    (r: 255; g: 255; b: 85;  a: 255), // 14 - Желтый
    (r: 255; g: 255; b: 255; a: 255)  // 15 - Белый
  );

var varsmod: tIdentArray;

{Процедура инициализации RayLib. Параметры: Width, Height: integer; Name: string}
Function InitGraph(var_: pointer):pValue;
var Wight, Height: longint; Name_: string;
begin
  Wight := pVarArray(var_)^[1].i;
  Height := pVarArray(var_)^[2].i;
  Name_ := pString(pVarArray(var_)^[3].s)^;

  InitWindow(Wight, Height, PChar(Name_)); //PChar(Name_)
  SetTargetFPS(60);

  InitGraph := nil;
end;

{Функция проверки закрытия окна.}
Function WindowNotClose(var_: pointer):pValue;
var res: pValue;
begin
  new(res);

  res^.type_ := cmBool;
  res^.b := not WindowShouldClose;

  WindowNotClose := res;
end;


{Функция BeginDrawing}
Function BegDraw(var_: pointer):pValue;
begin
  BeginDrawing;

  BegDraw := nil;
end;

{Функция EndDrawing}
Function EndDraw(var_: pointer):pValue;
begin
  EndDrawing;

  EndDraw := nil;
end;

{Функция рисования квадратов}
Function DrawRectangleMod(var_: pointer):pValue;
var x, y, width, height, COLOR: integer;
begin
  x := pVarArray(var_)^[1].i;
  y := pVarArray(var_)^[2].i;
  width := pVarArray(var_)^[3].i;
  height := pVarArray(var_)^[4].i;
  COLOR := pVarArray(var_)^[5].i;

  DrawRectangle(x, y, width, height, COLORS[COLOR]);

  DrawRectangleMod := nil;
end;

{Функция рисования пикселя}
Function DrawPixelMod(var_: pointer):pValue;
var x, y, COLOR: integer;
begin
  x := pVarArray(var_)^[1].i;
  y := pVarArray(var_)^[2].i;
  COLOR := pVarArray(var_)^[3].i;

  DrawPixel(x, y, COLORS[COLOR]);

  DrawPixelMod := nil;
end;

{Функция рисования линии}
Function DrawLineMod(var_: pointer):pValue;
var startX, startY, endX, endY, COLOR: integer;
begin
  startX := pVarArray(var_)^[1].i;
  startY := pVarArray(var_)^[2].i;
  endX := pVarArray(var_)^[3].i;
  endY := pVarArray(var_)^[4].i;
  COLOR := pVarArray(var_)^[5].i;

  DrawLine(startX, startY, endX, endY, COLORS[COLOR]);

  DrawLineMod := nil;
end;

{Функция рисования круга}
Function DrawCircleMod(var_: pointer):pValue;
var centerX, centerY, radius, COLOR: integer;
begin
  centerX := pVarArray(var_)^[1].i;
  centerY := pVarArray(var_)^[2].i;
  radius := pVarArray(var_)^[3].i;
  COLOR := pVarArray(var_)^[4].i;

  DrawCircle(centerX, centerY, radius, COLORS[COLOR]);

  DrawCircleMod := nil;
end;


{Процедура рисования текста}
Function DrawTextMod(var_: pointer):pValue;
var Text: string; x, y, fontSize, color: integer;
begin
  case pVarArray(var_)^[1].Type_ of
    cmChar: Text := pVarArray(var_)^[1].c;
    cmString: Text := pString(pVarArray(var_)^[1].s)^;
  end;  

  x := pVarArray(var_)^[2].i;
  y := pVarArray(var_)^[3].i;
  fontSize := pVarArray(var_)^[4].i;
  color := pVarArray(var_)^[5].i;

  DrawText(PChar(Text), x, y, fontSize, COLORS[color]);

  DrawTextMod := nil;
end;

{Процедура закраски фона}
Function ClearBackgroundMod(var_: pointer):pValue;
var color: integer;
begin
  color := pVarArray(var_)^[1].i;

  ClearBackground(COLORS[color]);

  ClearBackgroundMod := nil;
end;


{Процедура IsKeyDown}
Function IsKeyDownMod(var_: pointer):pValue;
var key: integer; res: pValue;
begin
  key := pVarArray(var_)^[1].i;

  new(res); res^.type_ := cmBool; res^.b := IsKeyDown(key);

  IsKeyDownMod := res;
end;

{Процедура IsKeyPressed}
Function IsKeyPressedMod(var_: pointer):pValue;
var key: integer; res: pValue;
begin
  key := pVarArray(var_)^[1].i;

  new(res); res^.type_ := cmBool; res^.b := IsKeyPressed(key);

  IsKeyPressedMod := res;
end;

{Функция рисования овала}
Function DrawEllipseMod(var_: pointer):pValue;
var centerX, centerY, radiusH, radiusV, color: integer;
begin
  centerX := pVarArray(var_)^[1].i;
  centerY := pVarArray(var_)^[2].i;
  radiusH := pVarArray(var_)^[3].i;
  radiusV := pVarArray(var_)^[4].i;
  color := pVarArray(var_)^[5].i;

  DrawEllipse(centerX, centerY, radiusH, radiusV, COLORS[color]);

  DrawEllipseMod := nil;
end;


begin
  varsmod[1] := cmInt; varsmod[2] := cmInt; varsmod[3] := cmString;
  InitFunc(Func, 'InitGraph', 3, @InitGraph, varsmod);

  InitFunc(Func, 'WindowNotClose', 0, @WindowNotClose, varsmod);
  InitFunc(Func, 'BeginDrawing', 0, @BegDraw, varsmod);
  InitFunc(Func, 'EndDrawing', 0, @EndDraw, varsmod);

  varsmod[1] := cmInt; varsmod[2] := cmInt; varsmod[3] := cmInt; varsmod[4] := cmInt; varsmod[5] := cmInt;
  InitFunc(Func, 'DrawRectangle', 5, @DrawRectangleMod, varsmod);

  varsmod[1] := cmInt; varsmod[2] := cmInt; varsmod[3] := cmInt; 
  InitFunc(Func, 'DrawPixel', 3, @DrawPixelMod, varsmod);

  varsmod[1] := cmInt; varsmod[2] := cmInt; varsmod[3] := cmInt; varsmod[4] := cmInt; varsmod[5] := cmInt;
  InitFunc(Func, 'DrawLine', 5, @DrawLineMod, varsmod);

  varsmod[1] := cmInt; varsmod[2] := cmInt; varsmod[3] := cmInt; varsmod[4] := cmInt;
  InitFunc(Func, 'DrawCircle', 4, @DrawCircleMod, varsmod);

  varsmod[1] := cmString; varsmod[2] := cmInt; varsmod[3] := cmInt; varsmod[4] := cmInt; varsmod[5] := cmInt;
  InitFunc(Func, 'DrawText', 5, @DrawTextMod, varsmod);

  varsmod[1] := cmString;
  InitFunc(Func, 'ClearBackground', 1, @ClearBackgroundMod, varsmod);

  varsmod[1] := cmInt;
  InitFunc(Func, 'IsKeyDown', 1, @IsKeyDownMod, varsmod);

  varsmod[1] := cmInt;
  InitFunc(Func, 'IsKeyPressed', 1, @IsKeyPressedMod, varsmod);

  varsmod[1] := cmString; varsmod[2] := cmInt; varsmod[3] := cmInt; varsmod[4] := cmInt; varsmod[5] := cmInt;
  InitFunc(Func, 'DrawEllipse', 5, @DrawEllipseMod, varsmod);
end.