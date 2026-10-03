program CssStyledControlsDemo;

{$mode unleashed}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces,
  Forms, Unit1;

{$R *.res}

begin
  RequireDerivedFormResource:= True;
  Application.Scaled:= True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:= True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

