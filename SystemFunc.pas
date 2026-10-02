unit SystemFunc;

interface

uses MyTypes;

procedure AddFunc(s: string; vars: pVars; performans: byte);

implementation

procedure AddFunc(s: string; vars: pVars; performans: byte);
begin
  new(Func^.next); func := func^.next; 

  func^.name := s; func^.vars := vars; func^.performans := performans;
end;

end.