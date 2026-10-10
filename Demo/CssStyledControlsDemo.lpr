program CssStyledControlsDemo;

{$mode objfpc}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces,
  Forms,
  CssFormDarkTitle,
  CssMessageDialogs,
  Unit1;

{$R *.res}

begin
  RequireDerivedFormResource:= True;
  Application.Scaled:=True;
  {$PUSH}{$WARN 5044 OFF}
  Application.MainFormOnTaskbar:= True;
  {$POP}
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);

  TCssFormDarkTitle.EnableAutoAttach(Form1.CssStyleProvider1);
  CssMessageDlgSetStyleProvider(Form1.CssStyleProvider1);
  CssMessageDlgSetHtmlMode(True);
  CssMessageDlgSetOnLinkClick(@Form1.OnLinkClick);
  CssMessageDlgSetIconSource(Form1.CssSvgImgList1);

  Application.Run;
end.

