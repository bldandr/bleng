unit ModuleGraph;

{$mode objfpc}{$H+}

interface

Uses MyTypes, SystemFunc, raylib;

implementation

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
end;

{Функция EndDrawing}
Function EndDraw(var_: pointer):pValue;
begin
  EndDrawing;
end;


begin
  varsmod[1] := cmInt; varsmod[2] := cmInt; varsmod[3] := cmString;
  InitFunc(Func, 'InitGraph', 3, @InitGraph, varsmod);

  InitFunc(Func, 'WindowNotClose', 0, @WindowNotClose, varsmod);
  InitFunc(Func, 'BeginDrawing', 0, @BegDraw, varsmod);
  InitFunc(Func, 'EndDrawing', 0, @EndDraw, varsmod);
end.