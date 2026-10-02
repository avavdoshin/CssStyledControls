unit CssFontUtils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Graphics;

function ResolveFontFamily(const FontFamilyList: string): string;

implementation

function FontExists(const FontName: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to Screen.Fonts.Count - 1 do
    if SameText(Screen.Fonts[I], FontName) then
      Exit(True);
  Result := False;
end;

function TryFindFont(const FontNames: array of string; out FoundFont: string): Boolean;
var
  I: Integer;
begin
  for I := Low(FontNames) to High(FontNames) do
    if FontExists(FontNames[I]) then
    begin
      FoundFont := FontNames[I];
      Exit(True);
    end;
  Result := False;
end;

function ResolveFontFamily(const FontFamilyList: string): string;
var
  Tokens: TStringList;
  I: Integer;
  Token: string;
begin
  Result := Screen.SystemFont.Name;   
  if Trim(FontFamilyList) = '' then Exit;

  Tokens := TStringList.Create;
  try
    Tokens.Delimiter := ',';
    Tokens.StrictDelimiter := True;
    Tokens.DelimitedText := FontFamilyList;

    for I := 0 to Tokens.Count - 1 do
    begin
      Token := Trim(Tokens[I]);

      if (Length(Token) >= 2) and ((Token[1] = '"') or (Token[1] = ''''))
         and (Token[Length(Token)] = Token[1]) then
        Token := Copy(Token, 2, Length(Token) - 2);

      if Token = '' then Continue;

      if SameText(Token, 'serif') then
      begin
        if TryFindFont(['Times New Roman', 'Times', 'DejaVu Serif', 'Liberation Serif'], Result) then Exit;
      end
      else if SameText(Token, 'sans-serif') then
      begin
        if TryFindFont(['Arial', 'Helvetica', 'DejaVu Sans', 'Liberation Sans'], Result) then Exit;
      end
      else if SameText(Token, 'monospace') then
      begin
        if TryFindFont(['Courier New', 'Courier', 'DejaVu Sans Mono', 'Liberation Mono'], Result) then Exit;
      end
      else if SameText(Token, 'cursive') then
      begin
        if TryFindFont(['Comic Sans MS', 'Apple Chancery', 'URW Chancery L'], Result) then Exit;
      end
      else if SameText(Token, 'fantasy') then
      begin
        if TryFindFont(['Impact', 'Papyrus', 'URW Gothic L'], Result) then Exit;
      end
      else if SameText(Token, 'system-ui') then
      begin
        Result := Screen.SystemFont.Name;
        Exit;
      end
      else if FontExists(Token) then
      begin
        Result := Token;
        Exit;
      end;
    end;
  finally
    Tokens.Free;
  end;
end;

end.