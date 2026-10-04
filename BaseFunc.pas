unit BaseFunc;

interface 

Uses MyTypes, SystemFunc;

function RandomMod(var_: pointer):pValue;

implementation

var varsmod: tIdentArray;

{Функция обработки random. Параметры: number: integer}
function RandomMod(var_: pointer):pValue;
var numb, tmp: tValue; pResult: pValue;
begin
  numb := pVarArray(var_)^[1];

  new(pResult); 
  pResult^.type_ := cmInt;
  pResult^.i := random(numb.i);

  RandomMod := pResult;
end;

begin
  Randomize;

  varsmod[1] := cmInt;
  InitFunc(Func, 'random', 1, @RandomMod, varsmod);
end.