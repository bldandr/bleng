unit MyTypes;
    
interface
    
Type str15 = string[15]; {Строка в 15 байт, чтоб не занимало много места}
     Ident = ( {Все лексемы языка}
     cmName, cmNumber, cmTZ, cmVar, cmZP, cmTT, cmInt,
     cmFSO, cmFSC, cmWrite, cmIF, cmSO, cmSC, cmConst, cmOper, cmString,
     cmRavno, cmBool, cmOpSr, cmOpB, cmOpM, cmOpBR, cmOpMR,
     cmOpNR, cmNot, cmAnd, cmOr, cmThen, cmFor, cmDo, cmElse, cmTo,
     cmWhile, cmRead, cmKSO, cmKSC, cmArray, cmPlus, cmMinus, cmCdot,
     cmDiv, cmMod, cmChar, cmFloat, cmFrac, cmNumberFloat, cmWriteln,
     cmFunc, cmReturn, cmUses, cmIdent);

const MaxLex = 50; Max_Items = 8190; {Константы максимального размера массива и колво лексем}
      MainLex: array[ident] of str15= {Константы буквенных обозначений лексем}
      ('name', '', ';', 'var', ',', ':', 'int', '{', '}',
      'write', 'if', '(', ')', '', '', 'string', '=', 'bool',
      '==', '>', '<', '>=', '<=', '!=', 'not', 'and', 'or', 'then', 'for', 'do',
      'else', 'to', 'while', 'read', '[', ']', 'array', '+', '-', '*',
      '//', '%', 'char', 'float', '/', '', 'writeln', 'func', 'return', 'uses', '');

{ТИПЫ}
Type
    {Указатели на типы}
    pValue = ^tValue;
    pTree = ^tTree; 
    pNode = ^tNode;
    pFunc = ^tFunc;
    pVars = ^tVars;
    pStack = ^tStack;

    {Указатель на функцию модуля}
     pFunction=  function(var_: pointer):pValue;

     {Тип, хранящий информацию о массивах}
     tArrayInfo = record 
                    data: pointer;
                    size: word;
                    Type_: Ident;
                end;


     {Универсальный тип значения переменных}
     tValue = record 
                Case Type_:ident of
                  cmInt: (i: Longint);
                  cmString: (s: pointer);
                  cmBool: (b: boolean);
                  cmChar: (c: char);
                  cmFloat: (f: real);
                  cmArray: (a: ^tArrayInfo);
                  cmVar: (v: pValue);
              end;
     
     {Тип дерева операций}
     tTree = record
               case Typ:ident of
                 cmOper: (op: ident; left, right: pTree);
                 cmVar: (index: integer; num: pTree);
                 cmConst: (Value: tValue);
                 cmFunc: (indexFunc: pFunc; vars: pointer);
             end;

     {Тип лексем, на которые разбивается программа}
     tNode = record
               Typ: ident;
               next: pNode;
               case Type_:ident of
                 cmIF:(op: pTree; Then_, Else_: pNode);
                 cmWrite:(tree: pTree);
                 cmIdent:(treeVar, treeIndex: pTree; index: integer);
                 cmFor: (varFor, opFor: pTree; do_: pNode; indexFor: integer;);
                 cmWhile: (opWhile: pTree; doWhile_: pNode);
                 cmRead: (indexRead: integer; indexArrayRead: pTree);
                 cmFunc: (indexFunc: pFunc; vars: pointer);
                 cmReturn: (return: pTree);
             end;
     
     {Тип списка функций}
     tFunc = record 
               name: str15;
               vars: pVars;
               performans: byte;
               next: pFunc;
               case type_:ident of
                 cmFunc: (tree: pNode);
                 cmUses: (body: pFunction);
             end;

     {Тип названий переменных}
     tVars = record
               name: str15;
               type_: ident;
               max_size: word;
               typeArray: ident;
               next: pVars;
             end;

     {Тип стека локальных переменных}
     tStack = record 
                var_: pointer;
                next: pStack;
              end;

    {Типы для приведения нетипизированных указателей и указатели на них}
     pVarArray = ^tVarArray;
     tVarArray = array[1..Max_Items] of tValue;

     tCharArray = array[0..65000] of char;
     pCharArray = ^tCharArray;

     pTreeArray = ^tTreeArray;
     tTreeArray = array[1..16000] of pTree;

     {Тип для типов переменных в модульной функции}
     tIdentArray = array[1..20] of ident;
var 
   Code: pFunc; {Указатель на начало списка функций для интерпретатора}
   Func: pFunc; {Указатель на последнюю функцию}
   ID: set of char; {Множество для возможных знаков идентефикатора}

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

    
begin
  {Инициализация допустимых букв в идентефикаторах}
  ID := ['a'..'z', '0'..'9', 'A'..'Z', '_'];

  {Инициализация первых функций}
  Code := NewFunc('main');
  func := Code;
    
end.