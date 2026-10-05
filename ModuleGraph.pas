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


begin
  varsmod[1] := cmInt; varsmod[2] := cmInt; varsmod[3] := cmString;
  InitFunc(Func, 'InitGraph', 3, @InitGraph, varsmod);

  InitFunc(Func, 'WindowNotClose', 0, @WindowNotClose, varsmod);
  InitFunc(Func, 'BeginDrawing', 0, @BegDraw, varsmod);
  InitFunc(Func, 'EndDrawing', 0, @EndDraw, varsmod);

  varsmod[1] := cmInt; varsmod[2] := cmInt; varsmod[3] := cmInt; varsmod[4] := cmInt; varsmod[5] := cmInt;
  InitFunc(Func, 'DrawRectangle', 5, @DrawRectangleMod, varsmod);
end.