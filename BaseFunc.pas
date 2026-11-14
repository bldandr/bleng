unit BaseFunc;

interface 

Uses MyTypes, SystemFunc;

implementation

var varsmod: tIdentArray;

{Функция обработки random. Параметры: number: integer}
function RandomMod(var_: pointer):tValue;
var min, max, Result: tValue;
begin
  min := pVarArray(var_)^[1];
  max := pVarArray(var_)^[2];

  Result.type_ := cmInt;
  Result.i := min.i + random(max.i-min.i + 1);

  RandomMod := Result;
end;

{Функция обработки sqrt. Параметры: number: integer/real}
Function SqrtMod(var_: pointer):tValue;
var numb, res: tValue;
begin
  numb := pVarArray(var_)^[1];

  res.type_ := cmFloat;
  case numb.type_ of
    cmInt: res.f := sqrt(numb.i);
    cmFloat: res.f := sqrt(numb.f);
  end;

  SqrtMod := res;
end;

{Функция обработки trunc}
Function TruncMod(var_: pointer):tValue;
var numb: real; res: tValue; 
begin
  numb := pVarArray(var_)^[1].f;

  res.type_ := cmInt;

  res.i := trunc(numb);

  TruncMod := res;
end;

{Функция обработки str}
Function StrMod(var_: pointer):tValue;
var numb: longint;
    s: string;
    code: integer;
    res: tValue; 
begin
  numb := pVarArray(var_)^[1].i;

  str(numb, s);

  res.type_ := cmString;
  GetMem(res.s, length(s) + 1);
  string(res.s^) := s; 

  StrMod := res;
end;

begin
  Randomize;

  varsmod[1] := cmInt; varsmod[2] := cmInt;
  InitFunc(Func, 'random', 2, @RandomMod, varsmod, cmInt);

  varsmod[1] := cmInt;
  InitFunc(Func, 'sqrt', 1, @SqrtMod, varsmod, cmFloat);

  varsmod[1] := cmFloat;
  InitFunc(Func, 'trunc', 1, @TruncMod, varsmod, cmInt);

  varsmod[1] := cmInt;
  InitFunc(Func, 'str', 1, @StrMod, varsmod, cmString);
end.