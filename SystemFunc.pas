unit SystemFunc;

interface

uses MyTypes;

Function NewFunc(name: str15):pFunc;
Procedure InitFunc(var Func: pFunc; name: string; performans: word; pfunct: pFunction; vars: tIdentArray; typeReturn: ident);
Procedure DisposeFunc(tz: pFunc);
procedure DisposeVars(tz: pVars);
procedure DisposeAstTree(tz: pNode);
Procedure DisposeIndex(tz: pIndex);

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
Procedure InitFunc(var Func: pFunc; name: string; performans: word; pfunct: pFunction; vars: tIdentArray; typeReturn: ident);
var i: integer;
    tz: pVars;
begin
  Func^.next := NewFunc(name); 
  Func := Func^.next; 
  Func^.performans := performans; 
  Func^.typeReturn := typeReturn;
  Func^.count := performans;

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

    if i < performans then
    begin
      new(tz^.next); tz := tz^.next;
    end;
  end; 
end;

{Процедура затирания дерева}
Procedure DisposeTree(var p: pTree);
begin
  if p <> nil then
  begin
    if p^.typ = cmOper then 
    begin
      DisposeTree(p^.right);
      DisposeTree(p^.left);
    end;

    Dispose(p);
  end
end;

{Процедура затирания списка индексов}
Procedure DisposeIndex(tz: pIndex);
var next: pIndex;
begin
  while tz <> nil do
  begin
    if tz^.TreeIndex <> nil then DisposeTree(tz^.TreeIndex);
    next := tz^.next;
    
    dispose(tz);

    tz := next;
  end;
end;

{Процедура чистки AST}
procedure DisposeAstTree(tz: pNode);
var next: pNode;
begin
  while tz <> nil do
  begin
    case tz^.type_ of
      cmIf: 
      begin
        DisposeAstTree(tz^.then_); DisposeAstTree(tz^.else_); 
        DisposeTree(tz^.op);
      end;
      cmWrite,cmWriteLn: DisposeTree(tz^.tree);
      cmIdent: 
      begin
        DisposeTree(tz^.treeVar);
        DisposeIndex(tz^.index);
      end;
      cmFor:
      begin
        DisposeTree(tz^.varFor); DisposeTree(tz^.opFor); DisposeAstTree(tz^.do_); 
        DisposeIndex(tz^.indexFor);
      end;
      cmWhile:
      begin
        DisposeTree(tz^.opWhile); DisposeAstTree(tz^.doWhile_);
      end;
      cmRead: DisposeIndex(tz^.indexRead);
      cmReturn: DisposeTree(tz^.return);
    end;

    next := tz^.next;
    dispose(tz);
    tz := next;
  end;
end;

{Процедура зачистки списка vars}
procedure DisposeVars(tz: pVars);
var next: pVars;
begin
  while tz <> nil do
  begin
    next := tz^.next;
    dispose(tz);

    tz := tz^.next;
  end;
end;

{Процедура зачистки списка функций}
procedure DisposeFunc(tz: pFunc);
var next: pFunc;
begin
  while tz <> nil do
  begin
    DisposeVars(tz^.vars);

    if tz^.type_ = cmFunc then DisposeAstTree(tz^.tree);
  
    next := tz^.next;
    dispose(tz);
    tz := next;
  end;
end;


end.