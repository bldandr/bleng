unit SystemFunc;

interface

uses MyTypes;

Function NewFunc(name: str15):pFunc;
Procedure InitFunc(var Func: pFunc; name: string; performans: word; pfunct: pFunction; vars: tIdentArray);

implementation

{Функция для создания функции в списке функций}
Function NewFunc(name: str15):pFunc;
var tz: pFunc;
begin
  new(tz);
  tz^.next := nil;
  tz^.name := name;
  tz^.tree := nil;
  tz^.vars := nil;
  tz^.body := nil;
  tz^.type_ := cmFunc;

  NewFunc := tz;
end;

{Функция инициплизации модульных функций}
Procedure InitFunc(var Func: pFunc; name: string; performans: word; pfunct: pFunction; vars: tIdentArray);
var i: integer;
    tz: pVars;
begin
  Func^.next := NewFunc(name); 
  Func := Func^.next; 
  Func^.performans := performans; 

  func^.type_ := cmUses; 
  func^.body := pfunct;

  if performans > 0 then
  begin
    new(Func^.vars);
    tz := Func^.vars;
  end;
  for i := 1 to performans do
  begin
    tz^.name := ''; 
    tz^.type_ := vars[i];
    tz^.next := nil;
    tz^.max_size := 0;
  end; 
end;


end.