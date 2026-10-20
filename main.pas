{$MODE TP}

program qq;

Uses MyTypes, SystemFunc, BaseFunc, ModuleGraph;

{ПЕРЕМЕННЫЕ}
var f: text; {Открытие файла .b}
    st, LastSt: string; {Используется в GetLex как строка}
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
procedure AddVal(L, R: tValue; var Res: tValue; op: ident); forward;

{Процедура вывода ошибки}
Procedure Error(err: string);
var i: integer;
begin
  {Если не конец файла, то ошибка интерпретации}
  if not(eof(f)) then 
  begin
    writeln('-----------------------');
    writeln('Ошибка интерпретации: ');
    writeln(err);
    writeln('Строка: ', LineFile);
    writeln(LastSt);
    for i := 1 to Symbol-1 do write(' ');
    writeln('^');
    writeln('-----------------------');
  end
  else 
  begin
    {Если конец, то уже в рантайме}
    writeln('-----------------------');
    writeln('Ошибка в рантайме: ');
    writeln(err);
    writeln('-----------------------');
  end;
  halt(1);
end;

{Функция получения индекса переменной. Получает название, возвращает числовой индекс}
Function GetIndex(id: string):integer;
var i: integer;
    tz: pVars;
begin
  {Сначала перебираем локальные перменные последней функции}
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


  {Перебираем глобальные переменные}
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

{Функция, которая возвращает указатель на элемент динамического списка имен переменных(глобальных и локальных) по индексу}
Function GetPointerForNameVar(index: integer):pVars;
var tz: pVars;
begin
  {Если индекс отрицательный - переменна глоабльная}
  if index < 0 then
  begin
    tz := VarName;
    while (tz^.name <> lex) and (tz <> nil) 
    do tz := tz^.next;
  end
  else
  {Иначе, переменная локальная}
  begin
    tz := func^.Vars;
    while (tz^.name <> lex) and (tz <> nil)
    do tz := tz^.next;
  end;

  GetPointerForNameVar := tz;
end;

{Функция, которая возвращает значение переменной по индеку}
function GetValueVarForIndex(index: integer):pValue;
begin
  if index < 0 then GetValueVarForIndex := @pVarArray(var_)^[abs(index)]
  else GetValueVarForIndex := @pVarArray(stack^.var_)^[index];
end;

{Функция получения типа от имени. Перебирает по именам все переменные и вовзращает тип нужной}
Function GetType(id: string):ident;
var i: integer;
    tz: pVars;
begin
  {Перебираем локальные переменные}
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

  {Перебираем глобальные переменные}
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


{Функция добавления новой лексемы к последней в AST}
Procedure AddElem(var Last: pNode; Elem: pNode);
begin
  Last^.next := Elem;
  Last := Last^.next;
end;

{Функция создания новой лексемы для AST}
Function NewElem(Typ: ident):pNode;
var tz: pNode;
begin
  new(tz);
  tz^.next := nil;
  tz^.typ := typ;
  tz^.Type_ := typ;

  NewElem := tz;
end;

{Функция, которая возвращает следущую лексему из файла}
Function GetLex:ident;
var i, code: integer;
    ii: ident;
    float: boolean;
begin
  float := False;

  while (st='') and not(eof(f)) do {Пока строки пустые}
  begin
    readln(f, st);
    LastSt := st;
    Symbol := 0;
    inc(LineFile);
  end;
  i := 1;
  while st[i] = ' ' do {Пока идут пробелы}
    inc(i);

  delete(st, 1, i-1);
  Symbol := Symbol + i-1;
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
  Symbol := Symbol + i-1;

  ii := cmName;
  while (mainLex[ii] <> Lex) and (byte(ii) < MaxLex) do {Перебираем лексемы}
    inc(ii);
  GetLex := ii;
end;

{Процедура обработки объявления глобальных переменных}
Procedure SectionVar;
var i: integer;
    type_, typeArray: ident;
    tz: pVars;
    numNames: integer;
begin
  {Создаем новый элемент в динамическом списке названий глобальных переменных}
  new(VarName); tz := VarName; tz^.next := nil;
  numNames := 1;

  {ЦИкл обрабатывает несколько переменных одного типа. 1 итерация цикла = 1 новый тип}
  While ch in [cmInt,cmFloat,cmChar,cmString,cmKSO,cmBool] do
  begin
    {Запоминаем наш нужный тип}
    type_ := ch;
    ch := GetLex;

    {ЦИкл, который обрабатывает несколько переменных одного типа}
    repeat
      {Если это просто имя - создаем новое звено в динамическом списке глоабльных переменных с нужным типом}
      if ch = cmIdent then
      begin
        tz^.name := Lex;
        tz^.type_ := type_;
      end
      {Если тип, который мы запомнили - это "[", то значит, что это массив. Обрабатываем переменную, как массив}
      else if type_ = cmKSO then
      begin
        {Запоминаем число(количество элементов) в массиве и его тип}
        if ch = cmNumber then tz^.max_size := LexNum
        else Error('Требуется число!');

        ch := GetLex; 
        if ch in [cmKSC] then ch := GetLex
        else Error('Требуется ]!');

        tz^.type_ := cmArray;

        {Если мы снова видим "[", то это значит, что у нас матрица. Обрабатываем теперь ее как матрицу}
        if ch in [cmKSO] then 
        begin
          {Запоминаем максимальное количество элементов во второй плоскости матрицы и сохраняем тип}
          ch := GetLex;
          if ch = cmNumber then tz^.matrix_size := LexNum
          else Error('Требуется число!');
          ch := GetLex;

          if ch in [cmKSC] then ch := GetLex
          else Error('Требуется ]!');

          tz^.type_ := cmMatrix;
        end;

        {Если дальше не идет тип, то выдаем ошибку}
        if ch in [cmInt,cmString,cmBool,cmFloat,cmChar] then typeArray := ch
        else Error('Требуется тип!');
        
        {Если дальше идет идентефикаторы, то создаем новые элементы в списке глобальных имен переменных и следовательно запоминаем их}
        ch := GetLex;
        if ch = cmIdent then 
        begin
          tz^.name := lex; tz^.typeArray := typeArray;
        end
        else Error('Требуется идентефикатор!');

      end;
      {Если не лексемы, которые должны идти дальше - выдаем ошибку}
      Ch := GetLex;
      if not(Ch in [cmTZ,cmZP,cmInt,cmChar,cmFloat,cmString,cmKSO,cmBool,cmFunc])
      then Error('Требуется ";"!'){Если не ; ,}
      else if Ch <> cmTZ then
      begin
        {А иначе, если тип все таки запятая, то создаем новый элемент в списке глобальных названий переменных}
        ch := GetLex;
        new(tz^.next); tz := tz^.next; tz^.next := nil;
        inc(numNames);
        if ch in [cmInt,cmChar,cmFloat,cmString,cmKSO,cmBool] then
          type_ := ch;
      end;
    until ch = cmTZ; {Выходим, если лексема - ;}
    
    {Обработчик, если вдруг следущая лексема - это тип, то создаем элемент в списке названий глоабльных переменных и 
    увеличиваем количество глобальных переменных}
    ch := GetLex;
    if ch in [cmInt,cmFloat,cmChar,cmString,cmKSO,cmBool] then
    begin
      new(tz^.next); tz := tz^.next; tz^.next := nil; inc(numNames);
    end; 
  end;

  {Встаем на начальную позицию списка названий глобальных переменных}
  tz := VarName;

  {Считаем общее количество глобальных переменных и выделяем под них память}
  VarSize := numNames;
  GetMem(var_, (numNames)*sizeof(tValue));

  {Переносим из списка имен глобальных переменных все переменные в фактический стек глобальных переменных}
  for i := 1 to numNames do
  begin
    pVarArray(var_)^[i].Type_ := tz^.type_;
    case tz^.Type_ of
      {Для базовых типов - просто обнуляем значение}
      cmInt: pVarArray(var_)^[i].i := 0;
      cmBool: pVarArray(var_)^[i].b := False;
      cmChar: pVarArray(var_)^[i].c := #0;
      cmFloat: pVarArray(var_)^[i].f := 0;
      {Для строки - выделяем память для 1 байта(количества символом) и обнуляем его}
      cmString:
      begin
        Getmem(pVarArray(var_)^[i].s, sizeof(byte));
        FillChar(pVarArray(var_)^[i].s^, sizeof(byte), 0);
      end;
      {Для массива создаем новый элемент его описания, присваиваем этому элементу максимальный размер, выделяем память под этот размер и зануляем массив}
      cmArray:
      begin
        pVarArray(var_)^[i].Type_ := cmArray;

        new(pVarArray(var_)^[i].a);

        pVarArray(var_)^[i].a^.Size := tz^.max_size;

        pVarArray(var_)^[i].a^.Type_ := typeArray;
        GetMem(pVarArray(var_)^[i].a^.data, tz^.max_size*sizeof(tValue));
        FillChar(pVarArray(var_)^[i].a^.data^, tz^.max_size*sizeof(tValue), 0);
      end;
      {Для матрицы почти так же, как с массивом, но еще добавляется новый параметр размера}
      cmMatrix:
      begin
        pVarArray(var_)^[i].Type_ := cmMatrix;

        new(pVarArray(var_)^[i].m);

        pVarArray(var_)^[i].m^.Sizei := tz^.max_size;
        pVarArray(var_)^[i].m^.Sizej := tz^.matrix_size;

        pVarArray(var_)^[i].m^.Type_ := typeArray;
        GetMem(pVarArray(var_)^[i].m^.data, tz^.max_size*tz^.matrix_size*sizeof(tValue));
        FillChar(pVarArray(var_)^[i].a^.data^, tz^.max_size*tz^.matrix_size*sizeof(tValue), 0);
      end;
    end;
    tz := tz^.next;
  end;
end;

{Функция сложения строк. На вход берет два указателя на строки и возвращает другой указатель с полной строкой}
Function PlusString(left, right:pointer):pointer;
var SizeLeft, SizeRight, SizeTotal: byte;
    p: pointer;
begin
  {Берем размерности строк, которые требуется сложить}
  SizeLeft := byte(left^);
  SizeRight := Byte(right^);
  SizeTotal:= SizeLeft + SizeRight;

  {Выделяем память под новую строку и присваем ему конечный размер}
  GetMem(p, SizeTotal + sizeof(byte));
  byte(p^) := Sizetotal;

  {Копируем оба указателя в новую строку}
  Move(pCharArray(left)^[1], pCharArray(p)^[sizeof(byte)], SizeLeft);
  Move(pCharArray(right)^[1], pCharArray(p)^[sizeof(byte)+SizeLeft], SizeRight);

  PlusString := p;
end;

{Функция присваивания значения строке. Берет значение, которое нужно присвоить и отдает указатель на новую строку}
Function ValueString(s: string):pointer;
var p: pointer;
begin
  {Выделяем память и копируем туда значение}
  GetMem(p, sizeof(byte) + length(s));
  Move(s, p^, sizeof(char) + length(s));

  ValueString := p;
end;

{!! ФУНКЦИИ РЕКУРСИВНОГО СПУСКА}

{Функция обработки or}
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

    {Проверка на соответствие типов и сложение двух констант заранее}
    if left^.left^.typeElem <> left^.right^.typeElem then Error('Несоответствие типов!')
    else left^.typeElem := left^.left^.typeElem;

    if (left^.left^.typ = cmConst) and (left^.right^.typ = cmConst) then 
    begin
      AddVal(left^.left^.value, left^.right^.value, left^.value, left^.op);
      left^.typ := cmConst;
    end;
  end;

  OrExpr := left;
end;

{Функция обработки and}
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

    {Проверка на соответствие типов и сложение двух констант заранее}
    if left^.left^.typeElem <> left^.right^.typeElem then Error('Несоответствие типов!')
    else left^.typeElem := left^.left^.typeElem;

    if (left^.left^.typ = cmConst) and (left^.right^.typ = cmConst) then 
    begin
      AddVal(left^.left^.value, left^.right^.value, left^.value, left^.op);
      left^.typ := cmConst;
    end;
  end;

  AndExpr := left;
end;

{{Функция обработки not}
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

    {Проверка на соответствие типов и сложение двух констант заранее}
    if left^.left^.typeElem <> left^.right^.typeElem then Error('Несоответствие типов!')
    else left^.typeElem := left^.left^.typeElem;

    if (left^.left^.typ = cmConst) and (left^.right^.typ = cmConst) then 
    begin
      AddVal(left^.left^.value, left^.right^.value, left^.value, left^.op);
      left^.typ := cmConst;
    end;
  end;

  NotExpr := left;
end;

{Функция обработки сравнения(> <  == != <= >=)}
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

    {Проверка на соответствие типов и сложение двух констант заранее}
    if left^.left^.typeElem <> left^.right^.typeElem then Error('Несоответствие типов!')
    else left^.typeElem := left^.left^.typeElem;

    if (left^.left^.typ = cmConst) and (left^.right^.typ = cmConst) then 
    begin
      AddVal(left^.left^.value, left^.right^.value, left^.value, left^.op);
      left^.typ := cmConst;
    end;
  end;

  CompareExpr := left;
end;

{Функция обработки +-}
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

    {Проверка на соответствие типов и сложение двух констант заранее}
    if left^.left^.typeElem <> left^.right^.typeElem then Error('Несоответствие типов!')
    else left^.typeElem := left^.left^.typeElem;

    if (left^.left^.typ = cmConst) and (left^.right^.typ = cmConst) then 
    begin
      AddVal(left^.left^.value, left^.right^.value, left^.value, left^.op);
      left^.typ := cmConst;
    end;
  end;

  Expression := left;
end;

{Функция обработки // * % /}
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

    {Проверка на соответствие типов и сложение двух констант заранее}
    if left^.left^.typeElem <> left^.right^.typeElem then Error('Несоответствие типов!')
    else left^.typeElem := left^.left^.typeElem;

    if (left^.left^.typ = cmConst) and (left^.right^.typ = cmConst) then 
    begin
      AddVal(left^.left^.value, left^.right^.value, left^.value, left^.op);
      left^.typ := cmConst;
    end;
  end;

  Term := left;
end;

{Функция обработки фактических значений}
Function Factor:pTree;
var tz: pTree;
    timeVar:pVars; 
    vrpointFunc: pFunc; vrNode: pNode;
begin
  Case ch of
    {Если лексема - идентефикатор}
    cmIdent: begin
               {Проверяем на то, вдруг идентефикатор - функция}
               vrpointFunc := code;
               new(tz);
               
               {Перебираем все функции}
               while vrpointFunc <> nil do
               begin
                {Если нашли функцию}
                if vrpointFunc^.name = lex then
                begin
                  {Создаем временную ноду, чтоб обработать вызов функции функцией CommandFunc}
                  vrNode := NewElem(cmName);
                  CommandFunc(vrNode, vrpointFunc);
                  
                  {переносим данные из временной прееменной Node в основную переменную}
                  tz^.typ := cmFunc; tz^.indexFunc := vrpointFunc; tz^.vars := vrNode^.vars; 
                  tz^.typeElem := vrpointFunc^.typeReturn;

                  {Возвращаем последнее значение тут, чтоб не идти дальше}
                  Factor := tz;

                  exit;
                end;

                vrpointFunc := vrpointFunc^.next;
               end;

               {Если все таки не функция - рассматриваем его как переменную}
               tz^.index := GetIndex(Lex);

               {Получаем указатель по индексу}
               timeVar := GetPointerForNameVar(tz^.index);

               {Инициализируем звено}
               tz^.Typ := cmVar;
               tz^.typeElem := timeVar^.type_;

               {Если у нас var-параметр, то присваиваем тип массива, т.к. там лежит фактический тип}
               if timeVar^.type_ = cmVar then tz^.typeElem := timeVar^.typeArray;

               case timeVar^.Type_ of
                  cmArray: begin
                              {Если наша переменная - массив, то обрабатываем индекс}
                              ch := GetLex;
                              if ch = cmKSO then
                              begin
                                ch := GetLex;
                                tz^.num := OrExpr;
                                if ch <> cmKSC then Error('Требуется "]"!');
                              end;
                              tz^.typeElem := timeVar^.typeArray;
                            end;
                  cmMatrix: begin
                              {Если матрица, то обрабатываем два индекса}
                              ch := GetLex;
                              if ch = cmKSO then 
                              begin
                                ch := GetLex;
                                tz^.num := OrExpr;
                                if ch <> cmKSC then Error('Требуется "]"!');

                                ch := GetLex;
                                if ch <> cmKSO then Error('Для матрицы требуется "["!');
                                ch := GetLex;
                                tz^.numj := OrExpr;
                                if ch <> cmKSC then Error('Требуется "]"!');
                              end;
                              tz^.typeElem := timeVar^.typeArray;
                            end;
               end;
             end;
    cmConst: begin
               {Если наше фактическое значение - константа(строковая), то определяем ее тип в строку и присваиваем значения}
               new(tz);
               tz^.Typ := cmConst;
               tz^.value.Type_ := cmString;
               tz^.value.s := ValueString(lex);
               if length(lex) = 1 then
               begin
                 tz^.value.Type_ := cmChar;
                 tz^.value.c := lex[1];
               end;
               tz^.typeElem := cmString;
             end;
    cmNumber:begin
               {Если число, то присваиваем в pValue}
               new(tz);
               tz^.Typ := cmConst;
               tz^.value.Type_ := cmInt;
               tz^.value.i := LexNum;
               tz^.typeElem := cmInt;
             end;
    cmNumberFloat:begin
               {Тоже самое, что и с числом, но теперь как вещественное}
               new(tz);
               tz^.Typ := cmConst;
               tz^.value.Type_ := cmFloat;
               tz^.value.f := LexNumFloat;
               tz^.typeElem := cmFloat;
             end;
    cmSO: begin
            {Если скобка открывается, то вызываемся первым рекурсивным спуском}
            ch := GetLex;
            tz := OrExpr;

            if ch <> cmSC then Error('Требуется скобка!')
          end;
    cmNot:begin
            {Если тут not, то обрабатываем левую ветку, как и с открытой скобкой}
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

{Обработка команды присваивания переменной}
procedure CommandVar(var Last: pNode; index: integer);
var 
    val: pVars;
begin
  {Добавляем новый элемент в AST}
  AddElem(Last, NewElem(cmIdent));

  {Получаем указатель на звено в списке имен переменных}
  val := GetPointerForNameVar(index);

  ch := GetLex;

  if val^.Type_ = cmArray then
  begin
    {Если тип - массив, то обарабтываем индекс}
    if ch = cmKSO then ch := GetLex
    else Error('Требуется "["!');

    Last^.TreeIndex := OrExpr;

    if ch = cmKSC then ch := GetLex
    else Error('Требуется "]"!');
  end;

  if val^.type_ = cmMatrix then
  begin
    {Если тип - матрица, то обрабатываем 2 индекса}
    if ch = cmKSO then ch := GetLex
    else Error('Требуется "["!');

    Last^.TreeIndex := OrExpr;

    if ch = cmKSC then ch := GetLex
    else Error('Требуется "]"!');

    if ch = cmKSO then ch := GetLex
    else Error('Требуется "[" в матрице!');

    Last^.treeIndexj := OrExpr;

    if ch = cmKSC then ch := GetLex
    else Error('Требуется "]"!');
  end;

  if ch = cmRavno then
  begin
    {Если лексема - присваивание, то вызываем рекурсивный спуск на значение и проверяем типы}
    ch := GetLex;
    Last^.treeVar := OrExpr;
    if (val^.type_ <> Last^.treeVar^.typeElem) and (val^.typeArray <> Last^.treeVar^.typeElem) 
    then Error('Несоответствие типов.');
    Last^.index := index;
  end
  else Error('Требуется "="!');
end;

{Процедура обработки вызова подпрограммы}
procedure CommandFunc(var Last: pNode; index: pFunc);
var 
    i, iVar: integer;
    tz, timeVar: pVars;
begin
  {Добавляем новый элемент в AST}
  AddElem(Last, NewElem(cmFunc));

  {Если есть параметры, то}
  if index^.performans > 0 then
  begin
    {Проверяем наличие скобки}
    ch := GetLex;
    if ch = cmSO then ch := GetLex
    else Error('Требуется (!');

    {Выделяем память под деревья значений параметров}
    GetMem(Last^.vars, sizeof(pTree)*index^.performans);

    tz := index^.vars;

    for i := 1 to index^.performans do
    begin
      {Если наш параметр начинается с идентефикатора, скобки, числа, константы, то обрабатываем}
      if ch in [cmIdent, cmNumber, cmConst, cmSO] then
      begin
        {Если наш параметр - var-параметр, то}
        if tz^.type_ = cmVar then
        begin
          {Определяем индекс переменной, создаем собственноручно инициализированный элемент дерева для удобства}
          iVar := GetIndex(lex);
          new(pTreeArray(Last^.vars)^[i]);
          pTreeArray(Last^.vars)^[i]^.typ := cmConst;
          pTreeArray(Last^.vars)^[i]^.Value.Type_ := cmInt;
          pTreeArray(Last^.vars)^[i]^.value.i := iVar;

          {Берем указатель на пзвено названий списка переменных и сверяем типы}
          timeVar := GetPointerForNameVar(iVar);
          if timeVar^.type_ <> tz^.typeArray then Error('Несоответствие типов!');
          ch := GetLex;
        end
        {Если параметр обычный -}
        else 
        begin
          {Вызываем рекурсию на значение параметра и сверяем типы}
          pTreeArray(Last^.vars)^[i] := orExpr;
          if pTreeArray(Last^.vars)^[i]^.typeElem <> tz^.type_ then Error('Несоответствие типов!');
        end;
      end
      else Error('Требуется переменная!');


      {Если не запятая/), то ошибка}
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
  {Ищем среди списка названий локальных переменных переменную с нашим названием. Если нашли - вызываем процедуру ее обработки и выходим}
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

  {Ищем среди списка названий глобальных переменных переменную с нашим названием. Если нашли - вызываем процедуру ее обработки и выходим}
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


  {Ищем среди списка функций функцию с нужным названием. Если нашли - вызываем процедуру ее обработки и выходим}
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

{Процедура обработки оператора вывода write}
procedure CommandWrite(var Last: pNode);
begin
  {Добавляем новый элемент в AST}
  AddElem(Last, NewElem(ch));

  {Првоеряем наличие скобок, строим дерево значения для вывода и проверяем наличие закрытой скобки}
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
  {Добавляем новый элемент в AST}
  AddElem(Last, NewElem(cmIf));

  {Строим дерево для условия}
  ch := GetLex;
  Last^.op := OrExpr;

  {Проверяем наличие then}
  if ch = cmThen then ch := GetLex
  else Error('Требуется then!');
  {Вызываем подпрограмму обработки тела опретаора}
  if ch = cmFSO then Last^.then_ := Operator
  else Error('Требуется "{"!');
  ch := GetLex;
  Last^.else_ := nil;
  {Если есть else, то бежим обарабатывать его тело}
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
  {Создаем новый элемент в AST}
  AddElem(Last, NewElem(cmFor));

  {Проверяем наличие идентефикатора(счетчика)}
  ch := GetLex;
  if ch = cmIdent then
  begin
    Last^.indexFor := GetIndex(Lex);
    ch := GetLex
  end
  else Error('Требуется идентефикатор!');
  
  {Обрабатываем оператор присваивания к счетчику}
  if ch = cmRavno then
  begin
    ch := GetLex;
    Last^.varFor := OrExpr;
  end
  else Error('Требуется "="!');

  {Проверяем наличие to и если есть - строим дерево, до куда должен идти счетчик}
  if ch = cmTo then
  begin
    ch := GetLex;
    Last^.opFor := orExpr;
  end
  else Error('Требуется "to"!');
  
  {Проверяем do и строим тело цикла}
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
  {Создаем новый элемент в AST}
  AddElem(Last, NewElem(cmWhile));

  {Строим дерево условия}
  ch := GetLex;
  Last^.OpWhile := OrExpr;

  {Строим тело цикла}
  if ch = cmDo then ch := GetLex
  else Error('Требуется "do"!');
  if ch = cmFSO then Last^.doWhile_ := Operator
  else Error('Требуется "{"!');

  ch := GetLex;
end;

{Обработка команды read}
procedure CommandRead(var Last: pNode);
begin
  {Добавляем новый элемент в AST}
  AddElem(Last, NewElem(cmRead));

  {Проверяем наличие скобки и сохраняем индекс переменной}
  ch := GetLex;
  if ch = cmSO then ch := GetLex
  else Error('Требуется "("!');
  if ch = cmIdent then Last^.indexRead := GetIndex(Lex);
  Last^.indexArrayRead := nil;
 
  {если наша переменная - массив, то обрабатываем еще и индекс массива}
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
  {Создаем новый элемент в AST}
  AddElem(Last, NewElem(cmReturn));

  {Строим дерево значения возврата и сверяем тип}
  ch := GetLex;
  Last^.return := OrExpr;
  if Last^.return^.typeElem <> Func^.typeReturn then Error('Несоответствие типов!');

  ch := GetLex;
end;


{Процедура обработки создания функций}
Procedure ComandFunc(var p, Last: pFunc);
var main: pFunc;
    tz: pVars;
    type_, typeArray: ident;
    i: byte;
begin
  {Инициализируем первоначальную функцию(main)}
  main := p;

  {Пока лексема - фукнция, обрабатываемся}
  while ch = cmFunc do
  begin
    {Если лексема main, то берем первую иницализированную переменную, а иначе создаем новую функцию в списке и присваиваем ей имя}
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

    {Если лексема - это тип, то сохраняем тип возврата. А иначе - cmName}
    if ch in [cmint,cmString,cmBool,cmChar,cmFloat] then 
    begin
      Last^.typeReturn := ch;
      ch := GetLex; 
    end
    else Last^.typeReturn := cmName;

    {Если (, то значит, что есть параметры, обрабатываем их}
    if ch = cmSO then
    begin
      {Создаем новый элемент в списке локальных функций новую переменную}
      new(Last^.vars); tz := Last^.vars; tz^.next := nil;
      ch := GetLex;
      {Пока лексема - это тип, то}
      while ch in [cmInt,cmString,cmFloat,cmBool,cmChar,cmKSO,cmVar] do
      begin
        {Сохраняем первоначальный тип}
        type_ := ch;

        {Если лексема - var-параметр, то сохраняем тип var-параметра в типе массива, чтоб не плодить переменные}
        if ch = cmVar then 
        begin
          ch := GetLex;
          typeArray := ch;
        end;

        {Если лексема - [, то обарабтываем индекс массива и его тип}
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

        {Дальше идут просто идентефикаторы одного типа}
        ch := getLex;
        while ch in [cmIdent] do
        begin
          {Сохраняем тип, увеличиваем колво параметров, присваиваем тип массива}
          tz^.Type_ := type_; inc(i); tz^.typeArray := typeArray;

          {Если массив,  то еще и максимальный размер сохраняем}
          if type_ = cmArray then tz^.max_size := lexNum;

          {Если идентефикатор, то сохраняем имя}
          if ch = cmIdent then tz^.name := lex
          else Error('Требуется имя переменной!');

          ch := GetLex;
          {если запятая, то создаем новый элемент в списке лексем}
          if ch in [cmZP, cmTZ] then
          begin
            new(tz^.next); tz := tz^.next; tz^.next := nil;
            ch := GetLex;
          end;   
        end;
      end;

      {Проверяем наличие закрывающейся скобки}
      if ch = cmSC then ch := GetLex
      else Error('Требуется )!');
    end;

    {Проверяем, есть ли тип у функции. если есть - сохраняем}
    if ch in [cmint,cmString,cmBool,cmChar,cmFloat] then 
    begin
      Last^.typeReturn := ch;
      ch := GetLex; 
    end;

    {Присваиваем колво параметров и начальнео колво локальных переменных}
    Last^.performans := i; Last^.count := i;

    {Строим дерево-тело функции}
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

  {Если тип - массив, то обрабатываем максимальное колво элементов + если это матрица, то обрабатываем максимальное количество строк}
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

  ch := GetLex;

  {проверяем на то, есть ли уже переменные в функции. если есть - добираемся
  до их конца, а если нет - создаем}
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
      {Инициализировать идентефикатор}
      tz^.name := lex; tz^.type_ := type_; tz^.next := nil;
      tz^.typeArray := typeArray;
      inc(Func^.count);
    end;
    Ch := GetLex;
    if not(Ch in [cmZP, cmTZ]) then Error('Требуется ":"!'){Если не , :}
    else if Ch = cmZP then
    begin
      {Если запятая - создаем еще переменную}
      ch := GetLex;
      new(tz^.next); tz := tz^.next;
    end;
  until ch = cmTZ; {ch = :}
end;


{Процедура обработки каждого идентефикатора в файле}
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
    {Если операция - не отрицание или тип - не бул}
    if (op <> cmNot) or (L.type_ <> cmBool) then
    begin 
      {Проверяем обе ветки на соответствие}
      if (L.Type_ <> cmBool) or (R.Type_ <> cmBool) then
        Error('Логические операции возможны только для boolean!');
    end;

    Res.Type_ := cmBool;

    {Присваиваем ответ по каждому из оператором}
    case op of
      cmAnd: Res.b := L.b and R.b;
      cmOr: Res.b := L.b or R.b;
      cmNot: Res.b := not(L.b);
    end;
    Exit;
  end;

  {Проверяем соответствие типов}
  if L.Type_ <> R.Type_ then Error('Несоответствие типов!');

  {Проверяем на сравнения}
  if op in [cmOpM, cmOpB, cmOpSr, cmOpBR, CmOpMR, cmOpNR] then
  begin
    {Для каждого типа - своя проверка}
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
      cmChar:
      begin
        case op of
          cmOpSr: Res.b := L.c = R.c;
          cmOpNR: Res.b := L.c <> R.c;
        end;
      end;
    end;
    exit;
  end;

  {Выполняем арефметичеаские операции для каждого типа и операции}
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
Procedure ReturnValueVar(index: integer; pNum, pNumj: pTree; var res: tValue);
var num, numj: tValue;
    RealVar: tValue;
begin
  {Получаем значение переменной по индексу}
  RealVar := GetValueVarForIndex(index)^;

  {Если переменная - массив}
  if RealVar.Type_ = cmArray then
  begin
    {Получаем значение индекса}
    EvalTree(pNum, num);
    {Проверякем выход за груницы}
    if num.i > RealVar.a^.size then
      Error('Выход за пределы массива!');
    {Возвращаем значение}
    res := pVarArray(RealVar.a^.data)^[num.i];
    res.Type_ := RealVar.a^.Type_;
  end
  {Если переменная - матрица}
  else if RealVar.Type_ = cmMatrix then
  begin
    {Получаем значение строки и столбца}
    EvalTree(pNum, num); EvalTree(pNumj, numj);

    {Проверяем выход за пределы}
    if num.i > RealVar.m^.sizei then Error('Выход за пределы матрицы!');
    if numj.i > RealVar.m^.sizej then Error('Выход за пределы матрицы!');

    {Возвращаем значение}
    Res := pVarArray(RealVar.m^.data)^[num.i*RealVar.m^.sizei + numj.i];
    Res.Type_ := RealVar.m^.type_;
  end
  {Если тип - Var, то возвращаем значение по ссылке}
  else if RealVar.Type_ = cmVar then Res := RealVar.v^
  {Иначе просто возвращаем значение}
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
             cmVar: ReturnValueVar(p^.index, p^.num, p^.numj, res); {Идентефикатор - возвращаем значение переменной}
             cmFunc:
             begin {Функция - интерпретируем функцию и возвращаем значение}
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
var val, index, indexj: tValue;
    timeVar: pValue;
begin
  {Получаем значение переменной}
  EvalTree(p^.treeVar, val);

  {Получаем указатель на переменную}
  timeVar := GetValueVarForIndex(p^.index);

  {Если тип - var-параметр, то возвращаем указатель var}
  if timeVar^.Type_ = cmVar then timeVar := timeVar^.v;

  {Если тип - массив}
  if timeVar^.Type_ = cmArray then
  begin
    {Получить индекс массива}
    EvalTree(p^.treeIndex, Index);

    {Получаем выход за пределы массива и соотвествие типов, если все норм - присваиваем значение}
    if index.i > timeVar^.a^.size then
      Error('Выход за пределы массива!');
    if timeVar^.a^.Type_ <> val.Type_ then
      Error('Несоответствие типов.')
    else
      pVarArray(timeVar^.a^.data)^[index.i] := val;
  end
  {Если тип - матрица}
  else if timeVar^.Type_ = cmMatrix then
  begin
    {Получаем строку и столбец}
    EvalTree(p^.treeIndex, Index);
    EvalTree(p^.treeIndexj, Indexj);
    
    {Првоеряем выход за пределы массива + соответствие типов, если все норм - присваиваем значение}
    if (index.i > timeVar^.m^.sizei) or (indexj.i > timeVar^.m^.sizej) then
      Error('Выход за пределы массива!');
    if timeVar^.m^.Type_ <> val.Type_ then
      Error('Несоответствие типов.')
    else
      pVarArray(timeVar^.m^.data)^[index.i*timeVar^.m^.sizei + indexj.i] := val;
  end 
  {Если не массив и не матрица - сразу присваиваем значение. Иначе ошибка}
  else if ((timeVar^.Type_ = val.Type_) or SoulTypes(timeVar^.Type_, val.Type_)) then
         timeVar^ := val
  else Error('Несоответствие типов.')
end;

{Интерпретация for}
procedure InterFor(pFor: pNode);
var val: tValue;
    timeVar: ^tValue;
begin
  {Получаем начальное значение переменной}
  EvalTree(pFor^.varFor, val);

  {Получаем адрес самой переменной}
  timeVar := GetValueVarForIndex(pFor^.indexFor);

  {Если не integer - ошибка. Иначе присваиваем значение переменной}
  if (timeVar^.Type_ <> val.Type_) or (val.Type_ <> cmInt)
  then Error('Требуется тип int.')
  else timeVar^ := val;

  {Получаем, до куда надо идти}
  EvalTree(pFor^.opFor, val);
  if val.Type_ <> cmInt then Error('Требуется тип integer.');

  {Повторяем выполнение интерпретации, пока наша переменная меньше итогового значения}
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
  {Получаем значение условия}
  Evaltree(p^.opWhile, val);

  if val.Type_ <> cmBool then Error('Недопустимый тип.');

  {Пока условие верно - интерпретируем тело и получаем условие снова}
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
  {Получаем значение вывода и выводим в зависимости от типа}
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
  {Получаем значение вывода и выводим в зависимости от типа}
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
  {Получаем значение условия. Если верно - выполняем тело then, иначе - else}
  EvalTree(p^.op, val);
  if val.b = True then Interpretator(p^.then_)
  else if p^.else_ <> nil then Interpretator(p^.else_);
end;

{Функция интерпретации команды return}
function InterReturn(p:pNode):pValue;
var pVal: pValue;
begin
  {Создаем звено возврата, получаем сам возврат и возвращаем его}
  new(pVal);
  EvalTree(p^.return, pval^);

  InterReturn := pval;
end;


{Процедура интерпретации оператора ввода}
procedure InterRead(p: pNode);
var timeVar: pValue; indexArray: tValue; type_: ident;
begin
  {Получаем переменную}
  timeVar := GetValueVarForIndex(p^.indexRead);

  {Обработка переменной массива}
  if timeVar^.type_ = cmArray then
  begin
    EvalTree(p^.indexArrayRead, indexArray); type_ := timeVar^.a^.type_; 
    timeVar := pValue(@pVarArray(timeVar^.a^.data)^[indexArray.i]);
    timeVar^.type_ := type_;
  end;

  {Читаем нужный тип в зависимости от типа}
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
    {Если тип - массив, то чистим сам массив в памяи}
    case pVarArray(p)^[i].type_ of
      cmArray:
      begin
        FreeMem(pVarArray(p)^[i].a^.data, pVarArray(p)^[i].a^.size*sizeof(tValue));
      end;
      {cmString:
      begin
        SizeString := byte(pVarArray(p)^[i].s^)+sizeof(char);
        Freemem(pVarArray(p)^[i].s, SizeString);
      end;}
    end;
  end; 
  {Очищаем  стек переменных}
  FreeMem(p, size*sizeof(tValue));
end;

{Обработка команды функций}
Function InterFunc(p: pFunc; vars: pointer):pValue;
var timeStack: pStack;
    i, numb: integer;
    vr: tValue;
    tz: pVars; res: pValue;
begin
  {Создаем новый элемент в стеке}
  new(timeStack); timeStack^.next := stack; stack := timeStack;

  {определяем количество локальных переменных}
  numb := p^.count;

  {Выделяем память под локальные переменные}
  GetMem(stack^.var_, numb*sizeof(tValue));
  tz := p^.vars;
  i := 1;
  
  {Пока есть куда идти по списку типов переменных}
  while tz <> nil do
  begin
    {Присваиваем к каждому типу свой тип в памяти в стеке}
    pVarArray(stack^.var_)^[i].Type_ := tz^.Type_;

    {Если это массив - выделяем память под него}
    if tz^.type_ = cmArray then
    begin
      new(pVarArray(stack^.var_)^[i].a);
      GetMem(pVarArray(stack^.var_)^[i].a^.data, tz^.max_size*sizeof(tValue));
      pVarArray(stack^.var_)^[i].a^.Type_ := tz^.typeArray;
      pVarArray(stack^.var_)^[i].a^.size := tz^.max_size;
    end;

    {Если еще и параметров больше, чем переменных, которые мы просмотрели, то это значит, что данная переменная - параметр}
    if p^.performans >= i then
    begin
      {Если var-параметр, то}
      if tz^.Type_ = cmVar then
      begin
        {Определяем индекс переменной}
        EvalTree(pTreeArray(vars)^[i], vr);
        
        {Присваиваем параметру адрес переменной}
        pVarArray(Stack^.var_)^[i].v := GetValueVarForIndex(vr.i);

        {Если вдруг наша переменная - тоже var, то идем по ее ссылке и присваиваем ее}
        if pVarArray(stack^.next^.var_)^[vr.i].type_ = cmVar then
          pVarArray(Stack^.var_)^[i].v := pVarArray(stack^.next^.var_)^[vr.i].v
      end
      {Если наша переменная - это все таки не var-параметр, то}
      else
      begin
        {Откатываемся в стеке назад(ибо не будет корректно работать EvalTree т.к. новый стек содержит бесполеный мусор) и присваиваем к нашему мусору
        нужное значение}
        timeStack := stack;
        stack := stack^.next;
        EvalTree(pTreeArray(vars)^[i], pVarArray(timeStack^.var_)^[i]);
        stack := timeStack
      end;
    end;

    inc(i);
    tz := tz^.next;
  end;

  {Если тип функции - базовая функция в коде, то вызываем выполнение тела функции}
  if p^.type_ = cmFunc then InterFunc := Interpretator(p^.tree)
  else 
  begin
    {а иначе вызываем функцию из библиотеки}
    Res := p^.body(stack^.var_);
    InterFunc := res;
  end;

  {Очищаем данные в стеке и сам стек}
  DisposeVar(stack^.var_, numb);
  TimeStack := stack;
  stack := stack^.next;
  dispose(TimeStack);
end;

{Процедура, которая проходит по AST и вызыввет соответствующие функции в нем}
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
  {Если есть параметры - открываем файл из параметра, иначе открываем main.b}
  if ParamCount = 0 then assign(f, 'main.b')
  else assign(f, ParamStr(1));

  {Открытие файла}
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