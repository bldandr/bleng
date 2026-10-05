unit BaseFunc;

interface 

Uses MyTypes, SystemFunc;

implementation

var varsmod: tIdentArray;

{Функция обработки random. Параметры: number: integer}
function RandomMod(var_: pointer):pValue;
var min, max: tValue; pResult: pValue;
begin
  min := pVarArray(var_)^[1];
  max := pVarArray(var_)^[2];

  new(pResult); 
  pResult^.type_ := cmInt;
  pResult^.i := min.i + random(max.i-min.i + 1);

  RandomMod := pResult;
end;

{Функция обработки sqrt. Параметры: number: integer/real}
Function SqrtMod(var_: pointer):pValue;
var numb: tValue; res: pValue;
begin
  numb := pVarArray(var_)^[1];

  New(res); res^.type_ := cmFloat;
  case numb.type_ of
    cmInt: res^.f := sqrt(numb.i);
    cmFloat: res^.f := sqrt(numb.f);
  end;

  SqrtMod := res;
end;

{Функция обработки trunc}
Function TruncMod(var_: pointer):pValue;
var numb: real; res: pValue; 
begin
  numb := pVarArray(var_)^[1].f;

  new(res);
  res^.type_ := cmInt;

  res^.i := trunc(numb);

  TruncMod := res;
end;

begin
  Randomize;

  varsmod[1] := cmInt; varsmod[2] := cmInt;
  InitFunc(Func, 'random', 2, @RandomMod, varsmod);

  varsmod[1] := cmInt;
  InitFunc(Func, 'sqrt', 1, @SqrtMod, varsmod);

  varsmod[1] := cmFloat;
  InitFunc(Func, 'trunc', 1, @TruncMod, varsmod);
end.