unit BaseFunc;

interface 

Uses MyTypes, SystemFunc;

implementation

var varsmod: tIdentArray;

{Функция обработки random. Параметры: number: integer}
function RandomMod(var_: pointer):pValue;
var numb: tValue; pResult: pValue;
begin
  numb := pVarArray(var_)^[1];

  new(pResult); 
  pResult^.type_ := cmInt;
  pResult^.i := random(numb.i);

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

begin
  Randomize;

  varsmod[1] := cmInt;
  InitFunc(Func, 'random', 1, @RandomMod, varsmod);

  varsmod[1] := cmInt;
  InitFunc(Func, 'sqrt', 1, @SqrtMod, varsmod);
end.