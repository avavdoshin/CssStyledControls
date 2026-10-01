unit CssProxyControl;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, Graphics, StdCtrls, ExtCtrls, TypInfo, GraphType,
  CssStyledControl;

type
  TProxyHiddenControl = class(TCssStyledControl)
  protected
    procedure StyleChanged; override;
    procedure ApplyDeclaration(const AName, AValue: string); override;
  public
    Proxy: TObject;
    procedure NotifyProxy;
  end;

  TCssProxy = class(TComponent)
  private
    FThemeProvider: TCssStyleProvider;
    FHiddenControl: TProxyHiddenControl;
    FDefaultStyleName: string;
    FFormStyleName: string;
    FButtonStyleName: string;
    FEditStyleName: string;
    FLabelStyleName: string;
    FPanelStyleName: string;

    FThemeVariantCss: string;
    FThemeGlobalCss: string;

    FApplyPending: Boolean;
    procedure AsyncApplyThemes(Data: PtrInt);

    procedure RefreshThemeCss;

    procedure SetThemeProvider(AValue: TCssStyleProvider);
    procedure ApplyThemes;
    procedure ApplyThemeToComponent(AComponent: TComponent);
    procedure ApplyCssToControl(AControl: TControl; const ACss: string);

    function ParseColor(const AValue: string; out AColor: TColor): Boolean;
    function ParseFontSize(const AValue: string; out ASize: Integer): Boolean;
    function ExtractRuleDeclarations(const ACssText, AClassSelector: string): string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure ApplyStyles;
    procedure RequestApplyThemes;
  published
    property ThemeProvider: TCssStyleProvider read FThemeProvider write SetThemeProvider;
    property DefaultStyleName: string read FDefaultStyleName write FDefaultStyleName;
    property FormStyleName: string read FFormStyleName write FFormStyleName;
    property ButtonStyleName: string read FButtonStyleName write FButtonStyleName;
    property EditStyleName: string read FEditStyleName write FEditStyleName;
    property LabelStyleName: string read FLabelStyleName write FLabelStyleName;
    property PanelStyleName: string read FPanelStyleName write FPanelStyleName;
  end;

implementation

uses
  StrUtils;

procedure TProxyHiddenControl.StyleChanged;
begin
  inherited StyleChanged;
  NotifyProxy;
end;

procedure TProxyHiddenControl.ApplyDeclaration(const AName, AValue : string);
begin
  inherited ApplyDeclaration(AName, AValue);
  NotifyProxy;
end;

procedure TProxyHiddenControl.NotifyProxy;
begin
  if Assigned(Proxy) and
     not (csLoading in ComponentState) and
     not (csDestroying in ComponentState) then
    TCssProxy(Proxy).RequestApplyThemes;
end;

{ TProxyHiddenControl }


{ TCssProxy }

constructor TCssProxy.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHiddenControl := TProxyHiddenControl.Create(nil);
  FHiddenControl.Proxy := Self;
  FHiddenControl.Visible := False;
  FHiddenControl.Parent := nil;
  FApplyPending := False;
end;

destructor TCssProxy.Destroy;
begin
  SetThemeProvider(nil);
  FHiddenControl.Free;
  inherited Destroy;
end;

procedure TCssProxy.Loaded;
begin
  inherited Loaded;
  ApplyThemes;
end;

procedure TCssProxy.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FThemeProvider) then
    FThemeProvider := nil;
end;

procedure TCssProxy.AsyncApplyThemes(Data : PtrInt);
begin
  FApplyPending := False;
  if not (csDestroying in ComponentState) then
    ApplyThemes;
end;

procedure TCssProxy.RefreshThemeCss;
var
  I, P, Q, NameStart, Depth: Integer;
  Active, Nme, Css: string;
  S, Low, NameTok, Inner: string;
begin
  FThemeVariantCss := '';
  FThemeGlobalCss := '';
  if not Assigned(FThemeProvider) then Exit;

  Active := LowerCase(Trim(FThemeProvider.DefaultStyleName));

  for I := 0 to FThemeProvider.StyleCount - 1 do
  begin
    Nme := Trim(FThemeProvider.StyleNames[I]);
    Css := FThemeProvider.CssByName[Nme];
    if (Active <> '') and (LowerCase(Nme) = Active) then
      FThemeVariantCss := FThemeVariantCss + Css + LineEnding
    else if (Nme = '') or (LowerCase(Nme) = 'default') or (LowerCase(Nme) = 'global') then
      FThemeGlobalCss := FThemeGlobalCss + Css + LineEnding;
  end;

  S := FThemeProvider.CssText;
  if S = '' then Exit;
  Low := LowerCase(S);
  P := 1;
  while P <= Length(S) do
  begin
    Q := PosEx('@variant', Low, P);
    if Q = 0 then
    begin
      FThemeGlobalCss := FThemeGlobalCss + Copy(S, P, MaxInt);
      Break;
    end;
    FThemeGlobalCss := FThemeGlobalCss + Copy(S, P, Q - P);
    NameStart := Q + Length('@variant');
    while (NameStart <= Length(S)) and (S[NameStart] in [' ', #9, #13, #10]) do
      Inc(NameStart);
    NameTok := '';
    while (NameStart <= Length(S)) and not (S[NameStart] in ['{', #13, #10, ';']) do
    begin
      NameTok := NameTok + S[NameStart];
      Inc(NameStart);
    end;
    NameTok := Trim(NameTok);
    Q := PosEx('{', S, NameStart);
    if Q = 0 then Break;
    P := Q + 1;
    Depth := 1;
    while (P <= Length(S)) and (Depth > 0) do
    begin
      if S[P] = '{' then Inc(Depth)
      else if S[P] = '}' then Dec(Depth);
      if Depth > 0 then Inc(P);
    end;
    Inner := Copy(S, Q + 1, P - Q - 1);
    if (Active <> '') and (LowerCase(NameTok) = Active) then
      FThemeVariantCss := FThemeVariantCss + Inner + LineEnding;
    P := P + 1;
  end;
end;

procedure TCssProxy.SetThemeProvider(AValue: TCssStyleProvider);
begin
  if FThemeProvider = AValue then Exit;
  
  if Assigned(FThemeProvider) then
  begin
    FThemeProvider.UnRegisterControl(FHiddenControl);
    FThemeProvider.RemoveFreeNotification(Self);
  end;
  
  FThemeProvider := AValue;
  
  if Assigned(FThemeProvider) then
  begin
    FThemeProvider.RegisterControl(FHiddenControl);
    FThemeProvider.FreeNotification(Self);
    if (csLoading in ComponentState) then
      ApplyThemes;
  end;
end;

procedure TCssProxy.ApplyStyles;
begin
  ApplyThemes;
end;

procedure TCssProxy.RequestApplyThemes;
begin
  if FApplyPending then Exit;
  FApplyPending := True;
  Application.QueueAsyncCall(@AsyncApplyThemes, 0);
end;

procedure TCssProxy.ApplyThemes;
var
  I: Integer;
begin
  if csDesigning in ComponentState then Exit;
  if not Assigned(Owner) then Exit;

  RefreshThemeCss;

  if Owner is TCustomForm then
    ApplyThemeToComponent(Owner);

  for I := 0 to Owner.ComponentCount - 1 do
    ApplyThemeToComponent(Owner.Components[I]);
end;

procedure TCssProxy.ApplyThemeToComponent(AComponent: TComponent);
var
  Css, StyleName: string;
begin
  if AComponent is TCssStyledControl then
    Exit;

  StyleName := '';
  if AComponent is TCustomForm then StyleName := FFormStyleName
  else if AComponent is TCustomButton then StyleName := FButtonStyleName
  else if AComponent is TCustomEdit then StyleName := FEditStyleName
  else if AComponent is TCustomLabel then StyleName := FLabelStyleName
  else if AComponent is TCustomPanel then StyleName := FPanelStyleName;

  if (StyleName = '') and (FDefaultStyleName <> '') then
    StyleName := FDefaultStyleName;
  if StyleName = '' then Exit;

  Css := ExtractRuleDeclarations(FThemeVariantCss, StyleName);
  if Css = '' then
    Css := ExtractRuleDeclarations(FThemeGlobalCss, StyleName);
  if (Css = '') and Assigned(FThemeProvider) then
  begin
    Css := ExtractRuleDeclarations(FThemeProvider.GetCssForControl(''), StyleName);
    if Css = '' then
      Css := FThemeProvider.CssByName[StyleName];
  end;

  if (Css <> '') and (AComponent is TControl) then
    ApplyCssToControl(TControl(AComponent), Css);
end;

procedure TCssProxy.ApplyCssToControl(AControl: TControl; const ACss: string);
var
  Font: TFont;
  Obj: TObject;
  Css, aName, Value: string;
  P: Integer;
  C: TColor;
  N: Integer;
begin
  Css := ACss;
  P := Pos('{', Css);
  if P > 0 then
  begin
    Css := Copy(Css, P + 1, MaxInt);
    P := Pos('}', Css);
    if P > 0 then
      Css := Copy(Css, 1, P - 1);
  end;

  Font := nil;
  if IsPublishedProp(AControl, 'Font') then
  begin
    Obj := GetObjectProp(AControl, 'Font');
    if Obj is TFont then
      Font := TFont(Obj);
  end;

  Css := Trim(Css);
  while Css <> '' do
  begin
    P := Pos(';', Css);
    if P > 0 then
    begin
      Value := Trim(Copy(Css, 1, P - 1));
      Css := Trim(Copy(Css, P + 1, MaxInt));
    end
    else
    begin
      Value := Css;
      Css := '';
    end;

    P := Pos(':', Value);
    if P > 0 then
    begin
      aName := LowerCase(Trim(Copy(Value, 1, P - 1)));
      Value := Trim(Copy(Value, P + 1, MaxInt));

      if (aName <> '') and (Value <> '') then
      begin
        if aName = 'color' then
        begin
          if ParseColor(Value, C) and (Font <> nil) then
            Font.Color := C;
        end
        else if (aName = 'background') or (aName = 'background-color') then
        begin
          if ParseColor(Value, C) then
          begin
            if IsPublishedProp(AControl, 'Color') then
              SetOrdProp(AControl, 'Color', C);
            if IsPublishedProp(AControl, 'Transparent') then
              SetOrdProp(AControl, 'Transparent', Ord(False));
          end;
        end
        else if aName = 'font-family' then
        begin
          if Font <> nil then
          begin
            P := Pos(',', Value);
            if P > 0 then
              Value := Trim(Copy(Value, 1, P - 1));
            if (Length(Value) >= 2) and
               ((Value[1] = '''') or (Value[1] = '"')) and
               (Value[Length(Value)] = Value[1]) then
              Value := Copy(Value, 2, Length(Value) - 2);
            Font.Name := Value;
          end;
        end
        else if aName = 'font-size' then
        begin
          if ParseFontSize(Value, N) and (Font <> nil) then
            Font.Size := N;
        end
        else if aName = 'font-weight' then
        begin
          if Font <> nil then
          begin
            if (LowerCase(Value) = 'bold') or (LowerCase(Value) = 'bolder') or
               (TryStrToInt(Value, N) and (N >= 600)) then
              Font.Style := Font.Style + [fsBold]
            else
              Font.Style := Font.Style - [fsBold];
          end;
        end
        else if aName = 'font-style' then
        begin
          if Font <> nil then
          begin
            if LowerCase(Value) = 'italic' then
              Font.Style := Font.Style + [fsItalic]
            else
              Font.Style := Font.Style - [fsItalic];
          end;
        end
        else if aName = 'text-align' then
        begin
          if IsPublishedProp(AControl, 'Alignment') then
          begin
            if LowerCase(Value) = 'center' then
              SetOrdProp(AControl, 'Alignment', Ord(taCenter))
            else if LowerCase(Value) = 'right' then
              SetOrdProp(AControl, 'Alignment', Ord(taRightJustify))
            else
              SetOrdProp(AControl, 'Alignment', Ord(taLeftJustify));
          end;
        end;
      end;
    end;
  end;

  if Font <> nil then
    AControl.Invalidate;
end;

function TCssProxy.ParseColor(const AValue: string; out AColor: TColor): Boolean;
var
  S, Hex: string;
  R, G, B: Integer;
begin
  Result := False;
  S := Trim(LowerCase(AValue));
  if S = '' then Exit;

  if S[1] = '#' then
  begin
    Hex := Copy(S, 2, MaxInt);
    if Length(Hex) = 3 then
    begin
      if TryStrToInt('$' + Hex[1] + Hex[1], R) and
         TryStrToInt('$' + Hex[2] + Hex[2], G) and
         TryStrToInt('$' + Hex[3] + Hex[3], B) then
      begin
        AColor := RGBToColor(R, G, B);
        Result := True;
      end;
    end
    else if Length(Hex) >= 6 then
    begin
      if TryStrToInt('$' + Copy(Hex, 1, 2), R) and
         TryStrToInt('$' + Copy(Hex, 3, 2), G) and
         TryStrToInt('$' + Copy(Hex, 5, 2), B) then
      begin
        AColor := RGBToColor(R, G, B);
        Result := True;
      end;
    end;
  end
  else
  begin
    if S = 'transparent' then begin AColor := clNone; Result := True; end
    else if S = 'black' then begin AColor := clBlack; Result := True; end
    else if S = 'white' then begin AColor := clWhite; Result := True; end
    else if S = 'red' then begin AColor := clRed; Result := True; end
    else if S = 'green' then begin AColor := clGreen; Result := True; end
    else if S = 'blue' then begin AColor := clBlue; Result := True; end
    else if S = 'yellow' then begin AColor := clYellow; Result := True; end
    else if (S = 'gray') or (S = 'grey') then begin AColor := clGray; Result := True; end
    else if S = 'silver' then begin AColor := clSilver; Result := True; end;
  end;
end;

function TCssProxy.ParseFontSize(const AValue: string; out ASize: Integer): Boolean;
var
  S: string;
  Num: Integer;
begin
  Result := False;
  ASize := -1;
  S := LowerCase(Trim(AValue));
  if S = '' then Exit;
  
  if S = 'small' then ASize := 8
  else if S = 'medium' then ASize := 10
  else if S = 'large' then ASize := 12
  else if S = 'x-large' then ASize := 14
  else if S = 'xx-large' then ASize := 18
  else
  begin
    if TryStrToInt(StringReplace(S, 'px', '', [rfReplaceAll, rfIgnoreCase]), Num) then
    begin
      ASize := Round(Num * 72 / 96);
      Result := True;
    end
    else if TryStrToInt(StringReplace(S, 'pt', '', [rfReplaceAll, rfIgnoreCase]), Num) then
    begin
      ASize := Num;
      Result := True;
    end;
  end;
  if ASize > 0 then Result := True;
end;

function TCssProxy.ExtractRuleDeclarations(const ACssText, AClassSelector: string): string;
var
  S, SelBlock, Decl, Sel, One: string;
  OpenPos, ClosePos, P: Integer;
  Target: string;
  Matched: Boolean;
begin
  Result := '';
  Target := LowerCase(Trim(AClassSelector));
  if (Target <> '') and (Target[1] <> '.') then
    Target := '.' + Target;
  if Target = '.' then Exit;

  S := ACssText;
  while S <> '' do
  begin
    OpenPos := Pos('{', S);
    if OpenPos = 0 then Break;
    SelBlock := Trim(Copy(S, 1, OpenPos - 1));
    ClosePos := PosEx('}', S, OpenPos);
    if ClosePos = 0 then Break;
    Decl := Trim(Copy(S, OpenPos + 1, ClosePos - OpenPos - 1));
    S := Copy(S, ClosePos + 1, MaxInt);

    Sel := SelBlock;
    Matched := False;
    while Sel <> '' do
    begin
      P := Pos(',', Sel);
      if P > 0 then
      begin
        One := Trim(Copy(Sel, 1, P - 1));
        Sel := Trim(Copy(Sel, P + 1, MaxInt));
      end
      else
      begin
        One := Sel;
        Sel := '';
      end;
      if LowerCase(One) = Target then
      begin
        Matched := True;
        Break;
      end;
    end;

    if Matched then
    begin
      Result := Decl;
      Break;
    end;
  end;
end;

end.
