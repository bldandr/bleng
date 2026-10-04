{$MODE TP}

program qq;

Uses MyTypes, SystemFunc, BaseFunc;

{ПЕРЕМЕННЫЕ}
var f: text; {Открытие файла .b}
    st: string; {Используется в GetLex как строка}
    Ch: ident; {Лексемы}
    Lex: string; {Лексема в виде строки}
    LexNum: longint; {Лексема в виде числа}
    LexNumFloat: real; {Лексема в виде вещественного числа}
    VarName: pVars; {Переменная всех временных названий в var}
    Var_:pointer; {Сами переменные}
    VarSize: word; {Колво глобальных переменных}
    LineFile, Symbol: integer; {Строка в прочитанном файле}
    stack: pStack; {Стек локальных переменных}

{Объявление пересекающихся функций}
Function OrExpr: pTree; forward;
Function AndExpr: pTree; forward;
Function NotExpr: pTree; forward;
Function CompareExpr: pTree; forward;
Function Expression: pTree; forward;
Function Term: pTree; forward;
Function Factor: pTree; forward;
Function Operator:pNode; forward;
Procedure EvalTree(p: pTree; var Res: tValue); forward;
Function Interpretator(p: pNode):pValue; forward;
procedure CommandFunc(var Last: pNode; index: pFunc); forward;
Function InterFunc(p: pFunc; vars: pointer):pValue; forward;

{Процедура вывода ошибки}
Procedure Error(err: string);
begin
  if not(eof(f)) then 
  begin
    writeln('-----------------------');
    writeln('Ошибка интерпретации: ');
    writeln(err);
    writeln('Строка: ', LineFile);
    writeln('-----------------------');
  end
  else 
  begin
    writeln('-----------------------');
    writeln('Ошибка в рантайме: ');
    writeln(err);
    writeln('-----------------------');
  end;
  halt(1);
end;

{Функция получения индекса переменной}
Function GetIndex(id: string):integer;
var i: integer;
    tz: pVars;
begin
  tz := Func^.vars;

  if tz <> nil then
  begin
    i := 1;
    while tz <> nil do
    begin
      if tz^.name = id then
      begin
        GetIndex := i;
        exit;
      end;
      tz := tz^.next;
      inc(i);
    end;
  end;

  tz := VarName;

  if tz <> nil then
  begin
    i := 1;
    while tz <> nil do
    begin
      if tz^.name = id then
      begin
        GetIndex := -i;
        exit;
      end;
      tz := tz^.next;
      inc(i);
    end;
  end;

  Error('Нет такого идентефикатора: ' + id);
end;

{Функция получения типа от имени}
Function GetType(id: string):ident;
var i: integer;
    tz: pVars;
begin
  tz := Func^.vars;

  if tz <> nil then
  begin
    i := 1;
    while tz <> nil do
    begin
      if tz^.name = id then
      begin
        GetType := tz^.type_;
        exit;
      end;
      tz := tz^.next;
      inc(i);
    end;
  end;

  tz := VarName;

  if tz <> nil then
  begin
    i := 1;
    while tz <> nil do
    begin
      if tz^.name = id then
      begin
        GetType := tz^.type_;
        exit;
      end;
      tz := tz^.next;
      inc(i);
    end;
  end;

  Error('Нет такого идентефикатора: ' + id);
end;


{Процедура добавления новой лексемы к последней}
Procedure AddElem(var Last: pNode; Elem: pNode);
begin
  Last^.next := Elem;
  Last := Last^.next;
end;

{Процедура создания новой переменной}
Function NewElem(Typ: ident):pNode;
var tz: pNode;
begin
  new(tz);
  tz^.next := nil;
  tz^.typ := typ;
  tz^.Type_ := typ;

  NewElem := tz;
end;

{Процедура получения лексемы}
Function GetLex:ident;
var i, code: integer;
    ii: ident;
    float: boolean;
begin
  float := False;

  while (st='') and not(eof(f)) do {Пока строки пустые}
  begin
    readln(f, st);
    inc(LineFile);
  end;
  i := 1;
  while st[i] = ' ' do {Пока идут пробелы}
    inc(i);

  delete(st, 1, i-1);
  i := 1;

  if (st = '') and not(eof(f)) then 
  begin
    GetLex := GetLex;
    exit;
  end;

  case st[1] of
    '<', '>','=','!','/': begin
                if st[2] in ['>', '=', '/'] then i := 2
                else i := 1;
                Lex := Copy(st, 1, i);
                Delete(st, 1, i);
              end;
    ':',';',',','{','}','(',')','[',']','+','-','*','%':
    begin
      Lex := copy(st,1,1);
      Delete(st, 1, 1);
    end;
    '0'..'9': begin
                while st[i] in ['0'..'9', '.'] do
                begin
                  inc(i);
                  if st[i] = '.' then Float := True;
                end;
                if float then
                begin
                  Lex := Copy(st, 1, i-1);
                  Val(lex, LexNumFloat, code);
                  if code < 0 then Error('Неверно запиисана цифра: ' + lex);
                  Delete(st, 1, i-1);
                  GetLex := cmNumberFloat;
                  exit;
                end;
                Lex := Copy(st, 1, i-1);
                Val(lex, LexNum, code);
                Delete(st, 1, i-1);
                GetLex := cmNumber;
                exit;
              end;
    '"': begin
           Delete(st, 1, 1);
           while st[i] <> '"' do
                  inc(i);
           Lex := Copy(st, 1, i-1);
           Delete(st, 1, i);
           GetLex := cmConst;
           exit;
         end;
    '#': begin
           Delete(st, 1, length(st));
           GetLex := GetLex;
         end;
    else
    begin
      if st[1] in ID then {Собираем символы идентефикатора}
      begin
        while st[i] in ID do
          inc(i);
        Lex := copy(st, 1, i-1);
        Delete(st, 1, i-1);
      end
      else Error('Недопустимый символ "' + lex + '"');
    end;
  end;
  Symbol := Symbol + i;

  ii := cmName;
  while (mainLex[ii] <> Lex) and (byte(ii) < MaxLex) do {Перебираем лексемы}
    inc(ii);
  GetLex := ii;
end;

{Процедура обработки раздела var}
Procedure SectionVar;
var i: integer;
    type_, typeArray: ident;
    tz: pVars;
    numNames: integer;
begin
  While ch in [cmInt,cmFloat,cmChar,cmString,cmKSO,cmBool] do
  begin
    new(VarName); tz := VarName; tz^.next := nil;

    type_ := ch;

    numNames := 1;

    ch := GetLex;
    repeat
      if ch = cmIdent then {Если имя - запомнить}
      begin
        tz^.name := Lex;
        tz^.type_ := type_;
      end
      else if type_ = cmKSO then
      begin
        if ch = cmNumber then tz^.max_size := LexNum
        else Error('Требуется число!');

        ch := GetLex; 
        if ch in [cmKSC] then ch := GetLex
        else Error('Требуется ]!');

        if ch in [cmInt,cmString,cmBool,cmFloat,cmChar] then typeArray := ch
        else Error('Требуется тип!');
        
        ch := GetLex;
        if ch = cmIdent then 
        begin
          tz^.name := lex; tz^.type_ := cmArray; tz^.typeArray := typeArray;
        end
        else Error('Требуется идентефикатор!');

      end;
      Ch := GetLex;
      if not(Ch in [cmTZ,cmZP,cmInt,cmChar,cmFloat,cmString,cmKSO,cmBool,cmFunc])
      then Error('Требуется ";"!'){Если не ; ,}
      else if Ch <> cmTZ then
      begin
        ch := GetLex;
        new(tz^.next); tz := tz^.next; tz^.next := nil;
        inc(numNames);
        if ch in [cmInt,cmChar,cmFloat,cmString,cmKSO,cmBool] then
          type_ := ch;
      end;
    until ch = cmTZ;

    tz := VarName;

    VarSize := VarSize + numNames;
    GetMem(var_, (numNames)*sizeof(tValue));

    {Иначе переносим из временного хранилища имен все переменные}
    for i := 1 to numNames do
    begin
      pVarArray(var_)^[i].Type_ := tz^.type_;
      case tz^.Type_ of
        {Для каждого типа рассматриваем свое значение}
        cmInt: pVarArray(var_)^[i].i := 0;
        cmString:
        begin
          Getmem(pVarArray(var_)^[i].s, sizeof(byte));
          FillChar(pVarArray(var_)^[i].s^, sizeof(byte), 0);
        end;
        cmBool: pVarArray(var_)^[i].b := False;
        cmChar: pVarArray(var_)^[i].c := #0;
        cmFloat: pVarArray(var_)^[i].f := 0;
        {Для массива это все}
        cmArray:
        begin
          pVarArray(var_)^[i].Type_ := cmArray;

          new(pVarArray(var_)^[i].a);

          pVarArray(var_)^[i].a^.Size := tz^.max_size;

          pVarArray(var_)^[i].a^.Type_ := typeArray;
          GetMem(pVarArray(var_)^[i].a^.data, tz^.max_size*sizeof(tValue));
          FillChar(pVarArray(var_)^[i].a^.data^, tz^.max_size*sizeof(tValue), 0);
        end;
      end;
      tz := tz^.next;
    end;
    ch := GetLex;
  end;
end;

{Функция сложения строк}
Function PlusString(left, right:pointer):pointer;
var SizeLeft, SizeRight, SizeTotal: byte;
    p: pointer;
begin
  SizeLeft := byte(left^);
  SizeRight := Byte(right^);
  SizeTotal:= SizeLeft + SizeRight;

  GetMem(p, SizeTotal + sizeof(byte));
  byte(p^) := Sizetotal;

  Move(pCharArray(left)^[1], pCharArray(p)^[sizeof(byte)], SizeLeft);
  Move(pCharArray(right)^[1], pCharArray(p)^[sizeof(byte)+SizeLeft], SizeRight);

  PlusString := p;
end;

{Функция присваивания значения строке}
Function ValueString(s: string):pointer;
var p: pointer;
begin
  GetMem(p, sizeof(byte) + length(s));
  Move(s, p^, sizeof(char) + length(s));

  ValueString := p;
end;

{!! Функции рекурсивного спуска.}
Function OrExpr:pTree;
var left, tz: pTree;
    op: set of ident;
begin
  left := AndExpr;

  op := [cmOr];

  while ch in op do
  begin
    new(tz);
    tz^.Typ := cmOper;
    tz^.op := ch;
    tz^.left := left;
    ch := GetLex;
    tz^.right := AndExpr;
    left := tz;
  end;

  OrExpr := left;
end;

Function AndExpr:pTree;
var left, tz: pTree;
    op: set of Ident;
begin
  left := NotExpr;

  op := [cmAnd];

  while ch in op do
  begin
    new(tz);
    tz^.Typ := cmOper;
    tz^.op := ch;
    tz^.left := left;
    ch := GetLex;
    tz^.right := NotExpr;
    left := tz;
  end;

  AndExpr := left;
end;

Function NotExpr:pTree;
var left, tz: pTree;
    op: set of ident;
begin
  left := CompareExpr;

  op := [cmNot];

  while ch in op do
  begin
    new(tz);
    tz^.Typ := cmOper;
    tz^.op := ch;
    tz^.left := left;
    tz^.right := nil;
    ch := GetLex;
    left := tz;
  end;

  NotExpr := left;
end;


Function CompareExpr:pTree;
var left, tz: pTree;
    op: set of ident;
begin
  left := Expression;

  op := [cmOpB, cmOpM, cmOpSr, cmOpNR, cmOpMR, cmOpBR];

  while ch in op do
  begin
    new(tz);
    tz^.Typ := cmOper;
    tz^.op := ch;
    tz^.left := left;
    ch := GetLex;
    tz^.right := Expression;
    left := tz;
  end;

  CompareExpr := left;
end;

Function Expression:pTree;
var left, tz: pTree;
    op: set of ident;
begin
  left := Term;

  op := [cmPlus, cmMinus];

  while ch in op do
  begin
    new(tz);
    tz^.Typ := cmOper;
    tz^.op := ch;
    tz^.left := left;
    ch := GetLex;
    tz^.right := Term;
    left := tz;
  end;

  Expression := left;
end;


Function Term:pTree;
var left, tz: pTree;
    op: set of ident;
begin
  left := Factor;

  op := [cmCdot, cmDiv, cmMod, cmFrac];

  while ch in op do
  begin
    new(tz);
    tz^.Typ := cmOper;
    tz^.op := ch;
    tz^.left := left;
    ch := GetLex;
    tz^.right := Factor;
    left := tz;
  end;

  Term := left;
end;


Function Factor:pTree;
var tz: pTree;
    timeVar:pVars; 
    vrpointFunc: pFunc; vrNode: pNode;
begin
  Case ch of
    cmIdent: begin
               vrpointFunc := code;
               new(tz);

               {Проверяем на то, вдруг идентефикатор - функция}
               while vrpointFunc <> nil do
               begin
                if vrpointFunc^.name = lex then
                begin
                  vrNode := NewElem(cmName);
                  CommandFunc(vrNode, vrpointFunc);
                  
                  {переносим данные из временной прееменной Node в основную переменную}
                  tz^.typ := cmFunc; tz^.indexFunc := vrpointFunc; tz^.vars := vrNode^.vars; 

                  {Возвращаем последнее значение тут, чтоб не идти дальше}
                  Factor := tz;

                  exit;
                end;

                vrpointFunc := vrpointFunc^.next;
               end;

               {Если все таки не функция - рассматриваем его как переменную}
               tz^.index := GetIndex(Lex);

               if tz^.index < 0 then
               begin
                 timeVar := VarName;
                 while (timeVar^.name <> lex) and (timeVar <> nil) 
                 do timeVar := timeVar^.next;
               end
               else
               begin
                 timeVar := func^.Vars;
                 while (timeVar^.name <> lex) and (timeVar <> nil)
                 do timeVar := timeVar^.next;
               end;

               tz^.Typ := cmVar;

               if timeVar^.Type_ = cmArray then
               begin
                 ch := GetLex;
                 if ch = cmKSO then
                 begin
                   ch := GetLex;
                   tz^.num := OrExpr;
                   if ch <> cmKSC then Error('Требуется "]"!');
                 end
               end;
             end;
    cmConst: begin
               new(tz);
               tz^.Typ := cmConst;
               tz^.value.Type_ := cmString;
               tz^.value.s := ValueString(lex);
               if length(lex) = 1 then
               begin
                 tz^.value.Type_ := cmChar;
                 tz^.value.c := lex[1];
               end;
             end;
    cmNumber:begin
               new(tz);
               tz^.Typ := cmConst;
               tz^.value.Type_ := cmInt;
               tz^.value.i := LexNum;
             end;
    cmNumberFloat:begin
               new(tz);
               tz^.Typ := cmConst;
               tz^.value.Type_ := cmFloat;
               tz^.value.f := LexNumFloat;
             end;
    cmSO: begin
            ch := GetLex;
            tz := OrExpr;

            if ch <> cmSC then Error('Требуется скобка!')
          end;
    cmNot:begin
            ch := GetLex;

            if ch = cmSO then 
            begin
              ch := GetLex;
              tz^.left := OrExpr;
            end
            else Error('Требуется (!');

            if ch <> cmSC then Error('Требуется )!');

            tz^.Typ := cmOper;
            tz^.op := cmNot;
          end;
  end;

  Factor := tz;

  ch := GetLex;
end;
{!! Конец функций рекурсивного спуска}

{!!! РАЗДЕЛ С ПОСТРОЕНИЕМ ДЕРЕВА}

{Обработка команды переменных}
procedure CommandVar(var Last: pNode; index: integer);
var 
    val: pVars;
begin
  AddElem(Last, NewElem(cmIdent));

  if index < 0 then
  begin
    val := VarName;

    while (val <> nil) and (val^.name <> lex) do val := val^.next;
  end
  else
  begin
    val := Func^.vars;

    while (val <> nil) and (val^.name <> lex) do val := val^.next;
  end;

  ch := GetLex;

  if val^.Type_ = cmArray then
  begin
    if ch = cmKSO then ch := GetLex
    else Error('Требуется "["!');

    Last^.TreeIndex := OrExpr;

    if ch = cmKSC then ch := GetLex
    else Error('Требуется "]"!');
  end;

  if ch = cmRavno then
  begin
    ch := GetLex;
    Last^.treeVar := OrExpr;
    Last^.index := index;
  end
  else Error('Требуется "="!');
end;

procedure CommandFunc(var Last: pNode; index: pFunc);
var 
    i, iVar: integer;
    tz, timeVar: pVars;
begin
  AddElem(Last, NewElem(cmFunc));

  if index^.performans > 0 then
  begin
    ch := GetLex;
    if ch = cmSO then ch := GetLex
    else Error('Требуется (!');

    GetMem(Last^.vars, sizeof(pTree)*index^.performans);

    tz := index^.vars;

    for i := 1 to index^.performans do
    begin
      if ch in [cmIdent, cmNumber] then
      begin
        {Все это для var-параметров}
        if tz^.type_ = cmVar then
        begin
          iVar := GetIndex(lex);
          new(pTreeArray(Last^.vars)^[i]);
          pTreeArray(Last^.vars)^[i]^.typ := cmConst;
          pTreeArray(Last^.vars)^[i]^.Value.Type_ := cmInt;
          pTreeArray(Last^.vars)^[i]^.value.i := iVar;

          if iVar < 0 then
          begin
            timeVar := VarName;

            while (timeVar <> nil) and (timeVar^.name <> lex) do
              timeVar := timeVar^.next;
          end
          else
          begin
            timeVar := func^.vars;

            while (timeVar <> nil) and (timeVar^.name <> lex) do
              timeVar := timeVar^.next;
          end;

          if TimeVar^.type_ = cmArray then
          begin
            ch := GetLex;

          end;

          ch := GetLex;
        end
        {Это уже для обычных параметров}
        else pTreeArray(Last^.vars)^[i] := orExpr
      end
      {ТУТ ДОПИСАТЬ ЛОГИКУ ПРОВЕРКИ ТИПОВ}
      else Error('Требуется переменная!');

      if ch in [cmZP, cmSC] then ch := GetLex
      else Error('Требуется ,!');

      tz := tz^.next;
    end;
  end
  else ch := GetLex;

  Last^.indexFunc := index;
end;


{Процедура обработки идентефикаторов(функции/переменные}
procedure CommandIdent(var Last: pNode);
var tz: pFunc;
    i: integer;
    tzVars: pVars;
begin
  i := 1;
  tzVars := Func^.vars;
  if tzVars <> nil then
  begin
    while tzVars <> nil do
    begin
      if tzVars^.name = lex then
      begin
        CommandVar(Last, i);
        exit;
      end;
      tzVars := tzVars^.next;
      inc(i);
    end;
  end;

  i := 1;
  tzVars := VarName;
  if tzVars <> nil then
  begin
    while tzVars <> nil do
    begin
      if tzVars^.name = lex then
      begin
        CommandVar(Last, -i);
        exit;
      end;
      tzVars := tzVars^.next;
      inc(i);
    end;
  end;

  tz := code;

  while tz <> nil do
  begin
    if tz^.name = lex then
    begin
      CommandFunc(last, tz);
      exit;
    end;

    tz := tz^.next;
  end;

  Error('Нет такого идентефикатора: ' + lex);
end;

{Процедура обработки команды вывода write}
procedure CommandWrite(var Last: pNode);
begin
  AddElem(Last, NewElem(ch));

  ch := GetLex;
  if ch = cmSO then ch := GetLex
  else error('Требуется "("!');
  Last^.tree := OrExpr;
  if ch = cmSC then ch := GetLex
  else error('Требуется ")"!');
end;

{Обработка оператора if}
procedure OperatorIf(var Last: pNode);
begin
  AddElem(Last, NewElem(cmIf));

  ch := GetLex;
  Last^.op := OrExpr;
  if ch = cmThen then ch := GetLex
  else Error('Требуется then!');
  if ch = cmFSO then Last^.then_ := Operator
  else Error('Требуется "{"!');
  ch := GetLex;
  Last^.else_ := nil;
  if ch = cmElse then
  begin
    ch := GetLex;
    if ch = cmFSO then Last^.else_ := Operator
    else Error('Требуется "{"!');
    ch := GetLex;
  end
end;


{Функция оператора for}
procedure OperatorFor(var Last: pNode);
begin
  AddElem(Last, NewElem(cmFor));

  ch := GetLex;
  if ch = cmIdent then
  begin
    Last^.indexFor := GetIndex(Lex);
    ch := GetLex
  end
  else Error('Требуется идентефикатор!');
  if ch = cmRavno then
  begin
    ch := GetLex;
    Last^.varFor := OrExpr;
  end
  else Error('Требуется "="!');
  if ch = cmTo then
  begin
    ch := GetLex;
    Last^.opFor := orExpr;
  end
  else Error('Требуется "to"!');
  if ch = cmDo then
  begin
    ch := GetLex;
    Last^.do_ := nil;
    if ch = cmFSO then Last^.do_ := Operator
    else Error('Требуется "{"!');
  end
  else Error('Требуется "do"!');
  ch := GetLex;
end;

{Обработка цикла while}
Procedure OperatorWhile(var Last: pNode);
begin
  AddElem(Last, NewElem(cmWhile));

  ch := GetLex;
  Last^.OpWhile := OrExpr;

  if ch = cmDo then ch := GetLex
  else Error('Требуется "do"!');
  if ch = cmFSO then Last^.doWhile_ := Operator
  else Error('Требуется "{"!');

  ch := GetLex;
end;

{Обработка команды read}
procedure CommandRead(var Last: pNode);
begin
  AddElem(Last, NewElem(cmRead));

  ch := GetLex;
  if ch = cmSO then ch := GetLex
  else Error('Требуется "("!');
  if ch = cmIdent then Last^.indexRead := GetIndex(Lex);
  Last^.indexArrayRead := nil;
 
  if GetType(lex) = cmArray then 
  begin
    ch := getLex; 
    if ch = cmKSO then ch := GetLex
    else Error('Требуется [!');

    Last^.indexArrayRead := orExpr;
  end; 

  ch := GetLex;

  if ch = cmSC then ch := GetLex
  else Error('Требуется ")"!');
end;

{Обработка команды return}
procedure CommandReturn(var Last: pNode);
begin
  AddElem(Last, NewElem(cmReturn));

  ch := GetLex;
  Last^.return := OrExpr;

  ch := GetLex;
end;


{Процедура обработки команды функции}
Procedure ComandFunc(var p, Last: pFunc);
var main: pFunc;
    tz: pVars;
    type_, typeArray: ident;
    i: byte;
begin
  main := p;

  while ch = cmFunc do
  begin
    ch := GetLex;
    if lex = 'main' then Last := main
    else
    begin
      if ch = cmIdent then last^.next := NewFunc(lex)
      else Error('Требуется имя функции!');
      Last := Last^.next;
    end;

    i := 0;

    ch := GetLex;
    if ch = cmSO then
    begin
      new(Last^.vars); tz := Last^.vars; tz^.next := nil;
      ch := GetLex;
      while ch in [cmInt,cmString,cmFloat,cmBool,cmChar,cmKSO,cmVar] do
      begin
        type_ := ch;

        if ch = cmVar then ch := GetLex;

        if ch = cmKSO then
        begin
          type_ := cmArray;
          ch := GetLex;
          if ch <> cmNumber then Error('Требуется число!');
          ch := GetLex;
          if ch = cmKSC then ch := GetLex
          else Error('Требуется ]!');

          typeArray := ch;
        end;

        ch := getLex;
        while ch in [cmIdent] do
        begin
          tz^.Type_ := type_; inc(i);
          if type_ = cmArray then
          begin
            tz^.max_size := lexNum;
            tz^.typeArray := typeArray;
          end;
          if ch = cmIdent then tz^.name := lex
          else Error('Требуется имя переменной!');

          ch := GetLex;
          if ch = cmZP then
          begin
            new(tz^.next); tz := tz^.next; tz^.next := nil;
            ch := GetLex;
          end
          else if ch = cmTZ then begin
            ch := GetLex;
            new(tz^.next); tz := tz^.next; tz^.next := nil;
          end;
        end;
      end;

      if ch = cmSC then ch := GetLex
      else Error('Требуется )!');
    end;

    Last^.performans := i;

    if ch = cmFSO then Last^.tree := operator
    else Error('Требуется {!');

    ch := GetLex;
    if ch = cmTZ then ch := GetLex;
  end;
end;

{Обработка команды создания переменной}
procedure CommandCreateVar(var Last: pNode);
var tz: pVars;
    type_, typeArray: ident;
begin
  {Добавляем новый элемент в цепочке команд и сохраняем тип}
  AddElem(Last, NewElem(cmVar));
  type_ := ch;
  if ch = cmKSO then
  begin
    type_ := cmArray;
    ch := GetLex;
    if ch <> cmNumber then Error('Требуется число!');
    ch := GetLex;
    if ch <> cmKSC then Error('Требуется ]!');
    ch := GetLex;
    if ch in [cmInt,cmFloat,cmBool,cmChar,cmString] then TypeArray := ch
    else Error('Требуется тип!');
  end;

  {проверяем на то, есть ли уже переменные в функции. если есть - добираемся
  до их конца, а если нет - создаем}
  ch := GetLex;

  if Func^.vars = nil then
  begin
    new(Func^.vars);
    tz := Func^.Vars;
  end
  else
  begin
    tz := Func^.Vars;
    while tz^.next <> nil do tz := tz^.next;

    new(tz^.next); tz := tz^.next;
  end;

  tz^.max_size := LexNum;

  repeat
    if ch = cmIdent then {Если имя - запомнить}
    begin
      tz^.name := lex; tz^.type_ := type_; tz^.next := nil;
      tz^.typeArray := typeArray;
    end;
    Ch := GetLex;
    if not(Ch in [cmZP, cmTZ]) then Error('Требуется ":"!'){Если не , :}
    else if Ch = cmZP then
    begin
      ch := GetLex;
      new(tz^.next); tz := tz^.next;
    end;
  until ch = cmTZ; {ch = :}
end;


{Процедура обработки тела всего угодно}
Function Operator:pNode;
var Last: pNode;
begin
  Last := NewElem(cmName);
  Operator := Last;
  repeat
    ch := GetLex;
    case ch of
      cmWrite, cmWriteLn: CommandWrite(Last);
      cmIf: OperatorIf(Last);
      cmFor: OperatorFor(Last);
      cmIdent: CommandIdent(Last);
      cmWhile: OperatorWhile(Last);
      cmRead: CommandRead(Last);
      cmInt,cmFloat,cmChar,cmString,cmBool,cmKSO: CommandCreateVar(Last);
      cmReturn: CommandReturn(Last);
      cmElse: Error('Ошибка в операторе!');
    end;

    if not(ch in [cmTZ, cmFSC]) then Error('Требуется ";"!');
  until Ch = cmFSC;
  Last^.next := nil;
end;


{!!! РАЗДЕЛ С ИНТЕРПРЕТАЦИЕЙ ДЕРЕВА}

{Получаем результат вычислений(математика/логика)}
procedure AddVal(L, R: tValue; var Res: tValue; op: ident);
begin
  {Смотрим на логические операции}
  if op in [cmAnd, cmOr, cmNot] then
  begin
    if (op <> cmNot) or (L.type_ <> cmBool) then
    begin 
      if (L.Type_ <> cmBool) or (R.Type_ <> cmBool) then
        Error('Логические операции возможны только для boolean!');
    end;

    Res.Type_ := cmBool;

    case op of
      cmAnd: Res.b := L.b and R.b;
      cmOr: Res.b := L.b or R.b;
      cmNot: Res.b := not(L.b);
    end;
    Exit;
  end;

  {Проверяем соответствие типов}
  if L.Type_ <> R.Type_ then Error('Несоответствие типов!');

  {Проверяем на операции для флагов}
  if op in [cmOpM, cmOpB, cmOpSr, cmOpBR, CmOpMR, cmOpNR] then
  begin
    Res.Type_ := cmBool;
    case L.Type_ of
      cmInt:
      begin
        case op of
          cmOpB: Res.b := L.i > R.i;
          cmOpM: Res.b := L.i < R.i;
          cmOpSr: Res.b := L.i = R.i;
          cmOpBR: Res.b := L.i >= R.i;
          cmOpMr: Res.b := L.i <= R.i;
          cmOpNR: Res.b := L.i <> R.i;
        end;
      end;
      cmFloat:
      begin
        case op of
          cmOpB: Res.b := L.f > R.f;
          cmOpM: Res.b := L.f < R.f;
          cmOpSr: Res.b := L.f = R.f;
          cmOpBR: Res.b := L.f >= R.f;
          cmOpMr: Res.b := L.f <= R.f;
          cmOpNR: Res.b := L.f <> R.f;
        end;
      end;
      cmString:
      begin
        case op of
          cmOpSr: Res.b := L.s = R.s;
          cmOpNR: Res.b := L.s <> R.s;
          else Error('Для строк допустима только операция равенства.');
        end;
      end;
    end;
    exit;
  end;

  {Код для математики}
  case L.Type_ of
    cmInt: begin
             case op of
               cmPlus: Res.i := L.i + R.i;
               cmMinus: Res.i := L.i - R.i;
               cmCdot: Res.i := L.i * R.i;
               cmDiv: Res.i := L.i div R.i;
               cmMod: Res.i := L.i mod R.i;
               else Error('Данная операция не поддерживается над типом integer.');
             end;
             Res.Type_ := cmInt;
           end;
    cmFloat:
    begin
      case op of
        cmPlus: Res.f := L.f + R.f;
        cmMinus: Res.f := L.f - R.f;
        cmCdot: Res.f := L.f * R.f;
        cmFrac: Res.f := L.f / R.f;
      end;
      Res.Type_ := cmFloat;
    end;
    cmString: begin
                case op of
                  cmPlus: Res.s := PlusString(l.s, r.s)
                  else Error('Для строк невозможна данная операция!');
                end;
                Res.Type_ := cmString;
              end;
  end;
end;

{Получение значение переменной}
Procedure ReturnValueVar(index: integer; pNum: pTree; var res: tValue);
var num: tValue;
    RealVar: tValue;
begin
  if index < 0 then RealVar := pVarArray(var_)^[abs(index)]
  else RealVar := pVarArray(stack^.var_)^[index];

  if RealVar.Type_ = cmArray then
  begin
    EvalTree(pNum, num);
    if num.i > RealVar.a^.size then
      Error('Выход за пределы массива!');
    res := pVarArray(RealVar.a^.data)^[num.i];
    res.Type_ := RealVar.a^.Type_;
  end
  else if RealVar.Type_ = cmVar then Res := RealVar.v^
  else res := RealVar;
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

{Функция для обхода дерева и получения результата в следствии}
Procedure EvalTree(p: pTree; var Res: tValue);
var ResL, ResR: tValue;
    pRes: pValue;
begin
  if p <> nil then
  begin
    if p^.Typ = cmOper then {Если наш узел - операция, то рекурсивно}
    begin
      EvalTree(p^.left, ResL); {вызываемся обрабатывая каждую операцию}
      EvalTree(p^.Right, ResR);
      AddVal(ResL, ResR, Res, p^.op);
    end
    else begin {Если наш узел - не операция, то обрабатываем его как}
           case p^.Typ of                {переменную/константу}
             cmConst: Res := p^.value; {Конст - просто отдаем значение}
             cmVar: ReturnValueVar(p^.index, p^.num, res); {Идентефикатор - возвращаем значение переменной}
             cmFunc:
             begin
               new(pRes);
               pRes := InterFunc(p^.indexFunc, p^.vars);
               Res := pRes^;

               dispose(pRes);            
             end;           
           end;
         end;
  end;
end;



{Проверка на то, подходят ли разные типы друг другу.}
function SoulTypes(type1, type2: ident):boolean;
begin
  SoulTypes := False;

  if (type1 in [cmString]) and (type2 in [cmChar])
  then SoulTypes := True;
  if (type1 in [cmFloat]) and (type2 in [cmInt])
  then SoulTypes := True;
end;

{Интерпретация использования идентефикаторов}
procedure InterIdent(p: pNode);
var val, index: tValue;
    timeVar: pValue;
begin
  EvalTree(p^.treeVar, val);

  if p^.index < 0 then timeVar := @pVarArray(var_)^[abs(p^.index)]
  else timeVar := @pVarArray(stack^.var_)^[p^.index];

  if timeVar^.Type_ = cmVar then timeVar := timeVar^.v;

  if timeVar^.Type_ = cmArray then
  begin
    EvalTree(p^.treeIndex, Index);
    if index.i > timeVar^.a^.size then
      Error('Выход за пределы массива!');

    if timeVar^.a^.Type_ <> val.Type_ then
      Error('Несоответствие типов.')
    else
      pVarArray(timeVar^.a^.data)^[index.i] := val;
  end
  else if ((timeVar^.Type_ = val.Type_) or SoulTypes(timeVar^.Type_, val.Type_)) then
         timeVar^ := val
  else Error('Несоответствие типов.')
end;

{Интерпретация for}
procedure InterFor(pFor: pNode);
var val: tValue;
    timeVar: ^tValue;
begin
  EvalTree(pFor^.varFor, val);

  if pFor^.indexFor < 0 then timeVar := @pVarArray(var_)^[abs(pFor^.indexFor)]
  else timeVar := @pVarArray(stack^.var_)^[pFor^.indexFor];

  if (timeVar^.Type_ <> val.Type_) or (val.Type_ <> cmInt)
  then Error('Требуется тип integer.')
  else timeVar^ := val;

  EvalTree(pFor^.opFor, val);
  if val.Type_ <> cmInt then Error('Требуется тип integer.');

  while timeVar^.i <= val.i do
  begin
    Interpretator(pFor^.do_);
    inc(timeVar^.i);
  end;
end;

{Процедура интерпретации цикла while}
Procedure InterWhile(p: pNode);
var val: tValue;
begin
  Evaltree(p^.opWhile, val);

  if val.Type_ <> cmBool then Error('Недопустимый тип.');

  while val.b do
  begin
    Interpretator(p^.doWhile_);
    Evaltree(p^.opWhile, val);
  end;
end;

{Процедура интерпретации оператора ввода}
Procedure InterWrite(p: pNode);
var val: tValue;
begin
  EvalTree(p^.tree, val);
  case val.Type_ of
    cmInt: Write(val.i);
    cmString: Write(string(val.s^));
    cmBool: Write(val.b);
    cmChar: Write(val.c);
    cmFloat: Write(val.f:0:2);
  end;
end;

{Процедура интерпретации оператора ввода с новой строкой}
Procedure InterWriteln(p: pNode);
var val: tValue;
begin
  EvalTree(p^.tree, val);
  case val.Type_ of
    cmInt: Writeln(val.i);
    cmString: Writeln(string(val.s^));
    cmBool: Writeln(val.b);
    cmChar: Writeln(val.c);
    cmFloat: Writeln(val.f:0:2);
  end;
end;


{Процедура интерпретации оператора ветвления}
Procedure InterIf(p: pNode);
var val: tValue;
begin
  EvalTree(p^.op, val);
  if val.b = True then Interpretator(p^.then_)
  else if p^.else_ <> nil then Interpretator(p^.else_);
end;

function InterReturn(p:pNode):pValue;
var pVal: pValue;
begin
  new(pVal);
  EvalTree(p^.return, pval^);

  InterReturn := pval;
end;


{Процедура интерпретации оператора ввода}
procedure InterRead(p: pNode);
var timeVar: pValue; indexArray: tValue; type_: ident;
begin
  if p^.indexRead < 0 then timeVar := @pVarArray(var_)^[abs(p^.indexRead)]
  else timeVar := @pVarArray(stack^.var_)^[p^.indexRead];

  {Обработка переменной массива}
  if timeVar^.type_ = cmArray then
  begin
    EvalTree(p^.indexArrayRead, indexArray); type_ := timeVar^.a^.type_; 
    timeVar := pValue(@pVarArray(timeVar^.a^.data)^[indexArray.i]);
    timeVar^.type_ := type_;
  end;

  case timeVar^.Type_ of
    cmInt: read(timeVar^.i);
    cmString: read(string(timeVar^.s^));
    cmChar: read(timeVar^.c);
    cmFloat: read(timeVar^.f)
    else Error('Нельзя считать переменную данного типа!');
  end;
end;

{Зачистка переменных в памяти}
procedure DisposeVar(p: pointer; size: integer);
var i, sizeString: integer;
begin
  for i := 1 to size do
  begin
    case pVarArray(p)^[i].type_ of
      cmArray:
      begin
        FreeMem(pVarArray(p)^[i].a^.data, pVarArray(p)^[i].a^.size*sizeof(tValue));
      end;
      cmString:
      begin
        SizeString := byte(pVarArray(p)^[i].s^)+sizeof(char);
        Freemem(pVarArray(p)^[i].s, SizeString);
      end;
    end;
  end; 
  FreeMem(p, size*sizeof(tValue));
end;

{Обработка команды функций}
Function InterFunc(p: pFunc; vars: pointer):pValue;
var timeStack: pStack;
    i, numb: integer;
    vr: tValue;
    tz: pVars; res: pValue;
begin
  new(timeStack); timeStack^.next := stack; stack := timeStack;

  numb := 0;
  tz := p^.vars;
  while tz <> nil do
  begin
    inc(numb);
    tz := tz^.next;
  end;

  GetMem(stack^.var_, numb*sizeof(tValue));
  tz := p^.vars;
  i := 1;
  while tz <> nil do
  begin
    pVarArray(stack^.var_)^[i].Type_ := tz^.Type_;

    if tz^.type_ = cmArray then
    begin
      new(pVarArray(stack^.var_)^[i].a);
      GetMem(pVarArray(stack^.var_)^[i].a^.data, tz^.max_size*sizeof(tValue));
      pVarArray(stack^.var_)^[i].a^.Type_ := tz^.typeArray;
      pVarArray(stack^.var_)^[i].a^.size := tz^.max_size;
    end;

    if p^.performans >= i then
    begin
      if tz^.Type_ = cmVar then
      begin
        EvalTree(pTreeArray(vars)^[i], vr);
        if vr.i < 0 then
          pVarArray(Stack^.var_)^[i].v := @pVarArray(var_)^[abs(vr.i)]
        else
        begin
          if pVarArray(stack^.next^.var_)^[vr.i].type_ = cmVar then
          begin
            pVarArray(Stack^.var_)^[i].v := pVarArray(stack^.next^.var_)^[vr.i].v
          end
          else
          pVarArray(Stack^.var_)^[i].v := @pVarArray(stack^.next^.var_)^[vr.i]
        end;
      end
      else
      begin
        timeStack := stack;
        stack := stack^.next;
        EvalTree(pTreeArray(vars)^[i], pVarArray(timeStack^.var_)^[i]);
        stack := timeStack
      end;
    end;

    inc(i);
    tz := tz^.next;
  end;

  if p^.type_ = cmFunc then InterFunc := Interpretator(p^.tree)
  else 
  begin
    Res := p^.body(stack^.var_);
    InterFunc := res;
  end;

  {Очистка переменных и элемента в стеке}
  DisposeVar(stack^.var_, numb);
  TimeStack := stack;
  stack := stack^.next;
  dispose(TimeStack);
end;

{Процедура выполнения команд}
Function Interpretator(p: pNode):pValue;
begin
  while p <> nil do
  begin
    case p^.Typ of
      cmWrite: InterWrite(p);
      cmWriteln: InterWriteLn(p);
      cmIf: InterIf(p);
      cmIdent: InterIdent(p);
      cmFunc: InterFunc(p^.indexFunc, p^.vars);
      cmFor: InterFor(p);
      cmWhile: InterWhile(p);
      cmRead: InterRead(p);
      cmReturn: Interpretator := InterReturn(p);
    end;
    p := p^.next;
  end;
end;

begin
  {Открытие файла}
  assign(f, 'BLENG/main.b');
  reset(f);

  ch := GetLex;
  if ch in [cmInt,cmFloat,cmBool,cmKSO,cmChar,cmString] then SectionVar; {Если дальше идет раздел var - вызываем его}
  if ch = cmFunc then ComandFunc(Code, func)
  else Error('Требуется хотя бы 1 функция!');

  InterFunc(Code, nil); {Вызываем выполнение команд}

  {Отчистка глобальных переменных}
  DisposeVar(var_, varSize);

  close(f);
end.