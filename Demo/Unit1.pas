unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, CssStyledControl,
  CssPanelControl, CssCheckboxControl, CssRadioControl, CssProxyControl,
  CssLabelControl, CssTabbedControl, CssButtonControl, CssGroupControl,
  CssMenuControl, CssBitBtnControl, CssSvgImgList, CssSplitterControl,
  CssEditControl, CssComboControl, CssListboxControl, CssListViewControl,
  CssMemoControl, CssVirtualTreeControl, CssMessageDialogs,
  CssProgressBarControl;

type
  PNodeData = ^TNodeData;
  TNodeData = record
    Caption: String;
    Note:    String;
    Kind:    Integer;
    Size:    Integer;
  end;

  TForm1 = class(TForm)
    CssBitBtn1 : TCssBitBtn;
    CssBitBtn2 : TCssBitBtn;
    CssBitBtn3 : TCssBitBtn;
    CssBitBtn4 : TCssBitBtn;
    CssButton1 : TCssButton;
    CssButton2 : TCssButton;
    CssButton3 : TCssButton;
    CssButton4 : TCssButton;
    CssButton5 : TCssButton;
    CssButton6 : TCssButton;
    CssButton7 : TCssButton;
    CssCheckBox1 : TCssCheckBox;
    CssCheckBox2 : TCssCheckBox;
    CssCheckBox3 : TCssCheckBox;
    CssCheckBox4 : TCssCheckBox;
    CssCheckBox5 : TCssCheckBox;
    CssCheckBox6 : TCssCheckBox;
    CssCheckBox7 : TCssCheckBox;
    CssCheckGroup1 : TCssCheckGroup;
    CssCheckGroup2 : TCssCheckGroup;
    CssCheckGroup3 : TCssCheckGroup;
    CssCheckGroup4 : TCssCheckGroup;
    CssCheckGroup5 : TCssCheckGroup;
    CssCheckGroup6 : TCssCheckGroup;
    CssComboBox1 : TCssComboBox;
    CssComboBox2 : TCssComboBox;
    CssComboBox3 : TCssComboBox;
    CssComboBox4 : TCssComboBox;
    CssEdit1 : TCssEdit;
    CssEdit2 : TCssEdit;
    CssEdit3 : TCssEdit;
    CssEdit4 : TCssEdit;
    CssGroupBox1 : TCssGroupBox;
    CssLabel1 : TCssLabel;
    CssLabel2 : TCssLabel;
    CssListBox1 : TCssListBox;
    CssListBox2 : TCssListBox;
    CssListBox3 : TCssListBox;
    CssListView1 : TCssListView;
    CssListView2 : TCssListView;
    CssListView3 : TCssListView;
    CssListView4 : TCssListView;
    CssMainMenu1 : TCssMainMenu;
    CssMemo1 : TCssMemo;
    CssPageControl1 : TCssPageControl;
    CssPanel1 : TCssPanel;
    CssPanel10 : TCssPanel;
    CssPanel11 : TCssPanel;
    CssPanel12 : TCssPanel;
    CssPanel13 : TCssPanel;
    CssPanel14 : TCssPanel;
    CssPanel15 : TCssPanel;
    CssPanel16 : TCssPanel;
    CssPanel17 : TCssPanel;
    CssPanel18 : TCssPanel;
    CssPanel19 : TCssPanel;
    CssPanel2 : TCssPanel;
    CssPanel20 : TCssPanel;
    CssPanel21 : TCssPanel;
    CssPanel22 : TCssPanel;
    CssPanel23 : TCssPanel;
    CssPanel24 : TCssPanel;
    CssPanel25 : TCssPanel;
    CssPanel3 : TCssPanel;
    CssPanel4 : TCssPanel;
    CssPanel5 : TCssPanel;
    CssPanel6 : TCssPanel;
    CssPanel7 : TCssPanel;
    CssPanel8 : TCssPanel;
    CssPanel9 : TCssPanel;
    CssPopupMenu1 : TCssPopupMenu;
    CssProgressBar1 : TCssProgressBar;
    CssProgressBar10 : TCssProgressBar;
    CssProgressBar11 : TCssProgressBar;
    CssProgressBar12 : TCssProgressBar;
    CssProgressBar13 : TCssProgressBar;
    CssProgressBar14 : TCssProgressBar;
    CssProgressBar15 : TCssProgressBar;
    CssProgressBar16 : TCssProgressBar;
    CssProgressBar17 : TCssProgressBar;
    CssProgressBar18 : TCssProgressBar;
    CssProgressBar19 : TCssProgressBar;
    CssProgressBar2 : TCssProgressBar;
    CssProgressBar20 : TCssProgressBar;
    CssProgressBar21 : TCssProgressBar;
    CssProgressBar22 : TCssProgressBar;
    CssProgressBar23 : TCssProgressBar;
    CssProgressBar24 : TCssProgressBar;
    CssProgressBar25 : TCssProgressBar;
    CssProgressBar26 : TCssProgressBar;
    CssProgressBar27 : TCssProgressBar;
    CssProgressBar3 : TCssProgressBar;
    CssProgressBar4 : TCssProgressBar;
    CssProgressBar5 : TCssProgressBar;
    CssProgressBar6 : TCssProgressBar;
    CssProgressBar7 : TCssProgressBar;
    CssProgressBar8 : TCssProgressBar;
    CssProgressBar9 : TCssProgressBar;
    CssProxy1 : TCssProxy;
    CssRadioButton1 : TCssRadioButton;
    CssRadioButton2 : TCssRadioButton;
    CssRadioButton3 : TCssRadioButton;
    CssRadioButton4 : TCssRadioButton;
    CssRadioButton5 : TCssRadioButton;
    CssRadioButton6 : TCssRadioButton;
    CssRadioGroup1 : TCssRadioGroup;
    CssRadioGroup2 : TCssRadioGroup;
    CssRadioGroup3 : TCssRadioGroup;
    CssRadioGroup4 : TCssRadioGroup;
    CssRadioGroup5 : TCssRadioGroup;
    CssRadioGroup6 : TCssRadioGroup;
    CssSplitter1 : TCssSplitter;
    CssSplitter2 : TCssSplitter;
    CssStyleProvider1 : TCssStyleProvider;
    CssSvgImgList1 : TCssSvgImgList;
    CssTabSheet1 : TCssTabSheet;
    CssTabSheet2 : TCssTabSheet;
    CssTabSheet3 : TCssTabSheet;
    CssTabSheet4 : TCssTabSheet;
    CssTabSheet5 : TCssTabSheet;
    CssTabSheet6 : TCssTabSheet;
    LeftTree : TCssVirtualStringTree;
    MenuItem10 : TCssMenuItem;
    MenuItem11 : TCssMenuItem;
    MenuItem9 : TCssMenuItem;
    RightTree : TCssVirtualStringTree;
    MenuItem1 : TCssMenuItem;
    MenuItem2 : TCssMenuItem;
    MenuItem3 : TCssMenuItem;
    MenuItem4 : TCssMenuItem;
    MenuItem5 : TCssMenuItem;
    MenuItem6 : TCssMenuItem;
    MenuItem7 : TCssMenuItem;
    MenuItem8 : TCssMenuItem;
    procedure CssButton1Click(Sender : TObject);
    procedure CssButton6Click(Sender : TObject);
    procedure CssButton7Click(Sender : TObject);
    procedure CssCheckBox1Click(Sender : TObject);
    procedure CssListView1Edited(Sender : TObject; Item : TCssListItem;
      const NewText : string);
    procedure CssLabel2LinkClick(Sender : TObject; const AHref, AText: String);
    procedure FormCreate(Sender : TObject);
    procedure FormKeyDown(Sender : TObject; var Key : Word; Shift : TShiftState
      );
    procedure LeftTreeDragOverNodes(Sender : TObject; Nodes : TList;
      TargetNode : TCssVirtualNode; var Allowed : Boolean);
    procedure LeftTreeDropNodesEx(Sender : TObject;
      SourceTree : TCssVirtualStringTree; Nodes : TList;
      TargetNode : TCssVirtualNode);
    procedure LeftTreeEditing(Sender : TObject; Node : TCssVirtualNode;
      Column : Integer; var Allowed : Boolean);
    procedure LeftTreeFreeNode(Sender : TObject; Node : TCssVirtualNode);
    procedure LeftTreeGetImageIndex(Sender : TObject; Node : TCssVirtualNode;
      Column : Integer; var ImageIndex : Integer);
    procedure LeftTreeGetNodeDataSize(
      Sender : TObject; var NodeDataSize : Integer);
    procedure LeftTreeGetText(Sender : TObject; Node : TCssVirtualNode;
      Column : Integer;
      TextType : TCssVirtualTreeTextType; var CellText : String);
    procedure LeftTreeInitNode(Sender : TObject; Node : TCssVirtualNode);
    procedure LeftTreeNewText(Sender : TObject; Node : TCssVirtualNode;
      Column : Integer; const NewText : string);
    procedure MenuItem1Click(Sender : TObject);
    procedure MenuItem2Click(Sender : TObject);
    procedure MenuItem5Click(Sender : TObject);
    procedure MenuItem8Click(Sender : TObject);
  private
    function AddTextNode(
      Tree: TCssVirtualStringTree;
      aParent: TCssVirtualNode;
      const ACaption, ANote: string;
      AKind, ASize: Integer
    ): TCssVirtualNode;
    function CopyNodeToTree(
      SrcNode: TCssVirtualNode;
      TargetTree: TCssVirtualStringTree;
      TargetParent: TCssVirtualNode): TCssVirtualNode;
    procedure PopulateListViewDemo;
  public
    procedure OnLinkClick(Sender : TObject; const AHref, AText: String);
  end;

var
  Form1 : TForm1;

implementation

uses
  LCLType, CssUtils;

{$R *.lfm}

function NodeInsideAny(Node: TCssVirtualNode; List: TList): Boolean;
var
  P: TCssVirtualNode;
begin
  P := Node.Parent;
  while P <> nil do
  begin
    if List.IndexOf(P) >= 0 then
      Exit(True);
    P := P.Parent;
  end;
  Result := False;
end;

procedure TForm1.CssCheckBox1Click(Sender : TObject);
begin
  if CssCheckBox1.Checked then
    CssStyleProvider1.DefaultStyleName := 'Dark'
  else
    CssStyleProvider1.DefaultStyleName := 'Light';
end;

procedure TForm1.CssButton1Click(Sender: TObject);
var
  R: Integer;
  S: string;
begin
  // ------------------------------------------------------------------
  // HTML mode is a global switch that affects every subsequent
  // CssMessageDlg / CssShowMessage / CssInputQuery dialog. Turn it on
  // before the demos and off afterwards, so that the rest of the
  // application keeps interpreting '<' and '>' as ordinary characters.
  // ------------------------------------------------------------------
  CssMessageDlgSetHtmlMode(True);
  try
    // ------------------------------------------------------------------
    // 1. Inline formatting
    // ------------------------------------------------------------------
    CssShowMessage(
      '1. Inline formatting: ' +
      '<b>bold</b>, <i>italic</i>, <u>underline</u>, ' +
      '<s>strikeout</s>, <code>inline code</code>.');

    // ------------------------------------------------------------------
    // 2. Inline colors via <span style="..."> and <font color="...">
    // ------------------------------------------------------------------
    CssShowMessage(
      '2. Colors: ' +
      '<span style="color:#2563EB">blue</span>, ' +
      '<span style="color:#DC2626">red</span>, ' +
      '<span style="color:#16A34A">green</span>, ' +
      '<font color="#F59E0B">orange via &lt;font&gt;</font>.');

    // ------------------------------------------------------------------
    // 3. Headings
    // ------------------------------------------------------------------
    CssMessageDlg(
      '<h1>3. Heading level 1</h1>' +
      '<h2>Heading level 2</h2>' +
      '<h3>Heading level 3</h3>' +
      '<p>Normal paragraph text below the headings.</p>',
      mtInformation, [mbOK], 0, 'Headings');

    // ------------------------------------------------------------------
    // 4. Paragraphs and explicit line breaks
    // ------------------------------------------------------------------
    CssShowMessage(
      '<p>4. First paragraph — spans a couple of lines to demonstrate ' +
      'word wrapping inside the dialog label.</p>' +
      '<p>A second paragraph follows after a blank line.</p>' +
      'And a manual break here:<br>second half of the same paragraph.');

    // ------------------------------------------------------------------
    // 5. Ordered and unordered lists
    // ------------------------------------------------------------------
    CssMessageDlg(
      '<p>5. Lists supported by the HTML parser:</p>' +
      '<ul>' +
        '<li>unordered item one</li>' +
        '<li>unordered item two</li>' +
        '<li>unordered item three</li>' +
      '</ul>' +
      '<ol>' +
        '<li>ordered first</li>' +
        '<li>ordered second</li>' +
        '<li>ordered third</li>' +
      '</ol>',
      mtInformation, [mbOK], 0, 'Lists');

    // ------------------------------------------------------------------
    // 6. Preformatted block: <pre> preserves spaces and line breaks
    // ------------------------------------------------------------------
    CssMessageDlg(
      '<p>6. Code sample:</p>' +
      '<pre>' +
      'function Add(A, B: Integer): Integer;'#10 +
      'begin'#10 +
      '  Result := A + B;'#10 +
      'end;' +
      '</pre>',
      mtInformation, [mbOK], 0, 'Preformatted code');

    // ------------------------------------------------------------------
    // 7. Horizontal rule and alignment
    // ------------------------------------------------------------------
    CssMessageDlg(
      '<p>7. Divider and alignment:</p>' +
      '<hr>' +
      '<center>This line is centered.</center>' +
      '<p align="right">This line is right-aligned.</p>',
      mtInformation, [mbOK], 0, 'Divider and alignment');

    // ------------------------------------------------------------------
    // 8. Subscript, superscript and inline quotes
    // ------------------------------------------------------------------
    CssShowMessage(
      '8. Sub/superscript: H<sub>2</sub>O, E = mc<sup>2</sup>. ' +
      'Inline quote: <q>quoted text</q>.');

    // ------------------------------------------------------------------
    // 9. Hyperlink appearance. The link is rendered with the styled
    //    colour and underline; because the label lives inside an
    //    internally created form, there is no OnLinkClick hook here,
    //    so the demo only shows the visual styling.
    // ------------------------------------------------------------------
    CssShowMessage(
      '9. Hyperlink styling: see ' +
      '<a href="https://example.com">example.com</a>.');

    // ------------------------------------------------------------------
    // 10. Mixed content in a confirmation dialog
    // ------------------------------------------------------------------
    R := CssMessageDlg(
      '<h3>10. Uncommitted changes</h3>' +
      '<p>You are about to close the document with unsaved edits.</p>' +
      '<ul>' +
        '<li><b>3 files</b> modified</li>' +
        '<li><b>1 file</b> deleted</li>' +
      '</ul>' +
      '<p style="color:#DC2626"><b>This action cannot be undone.</b></p>',
      mtWarning,
      [mbYes, mbNo, mbCancel],
      0,
      'Unsaved changes',
      mbNo);

    // ------------------------------------------------------------------
    // 11. Long wrapped HTML paragraph with mixed inline fragments
    // ------------------------------------------------------------------
    CssMessageDlg(
      '<p>11. This paragraph exceeds the dialog width on purpose. ' +
      'The label performs word wrapping automatically, so the content ' +
      'stays fully readable without clipping. <b>Bold fragments</b> ' +
      'and <i>italics</i> still render inline, and ' +
      '<code>inline code</code> keeps its monospaced font, even when ' +
      'a wrap point falls in the middle of the run.</p>',
      mtInformation, [mbOK], 0, 'Long HTML paragraph');

    // ------------------------------------------------------------------
    // 12. Release-notes style combination
    // ------------------------------------------------------------------
    CssMessageDlg(
      '<h2>12. Release notes</h2>' +
      '<p><b>CssMessageDlg</b> supports a useful subset of HTML:</p>' +
      '<ul>' +
        '<li><b>Bold</b>, <i>italic</i>, <u>underline</u>, ' +
        '<s>strikeout</s></li>' +
        '<li><span style="color:#2563EB">Inline colors</span></li>' +
        '<li>Headings <code>&lt;h1&gt;</code>..<code>&lt;h6&gt;</code></li>' +
        '<li>Ordered and unordered lists</li>' +
        '<li>Preformatted blocks <code>&lt;pre&gt;</code></li>' +
        '<li>Paragraphs <code>&lt;p&gt;</code> and rules ' +
        '<code>&lt;hr&gt;</code></li>' +
      '</ul>' +
      '<hr>' +
      '<p align="center"><i>End of demonstration</i></p>',
      mtInformation, [mbOK], 0, 'HTML capabilities');

    // ------------------------------------------------------------------
    // 13. HTML is also honoured in the prompt of input dialogs
    // ------------------------------------------------------------------
    S := CssInputBox(
      'HTML prompt',
      'Enter the <b>user name</b> for the ' +
      '<span style="color:#2563EB">remote connection</span>:',
      'admin');

    // ------------------------------------------------------------------
    // 14. Mixed content in a confirmation dialog with custom icon
    // ------------------------------------------------------------------
    R := CssMessageDlgIcon(
      '<h3>14. Uncommitted changes</h3>' +
      '<p>You are about to close the document with unsaved edits.</p>' +
      '<ul>' +
        '<li><b>3 files</b> modified</li>' +
        '<li><b>1 file</b> deleted</li>' +
      '</ul>' +
      '<p style="color:#DC2626"><b>This action cannot be undone.</b></p>',
      mtWarning,
      [mbYes, mbNo, mbCancel],
      0,
      22,
      'Unsaved changes',
      mbNo);
  finally
    // ------------------------------------------------------------------
    // Restore plain-text mode. From here on, '<' and '>' inside message
    // strings are once again treated as ordinary characters.
    // ------------------------------------------------------------------
    CssMessageDlgSetHtmlMode(False);
  end;
end;

procedure TForm1.CssButton6Click(Sender : TObject);
var
  Curr: Integer;
begin
  Curr := CssProgressBar19.Position;
  if Curr < 100 then
    inc(Curr, 10);
  CssProgressBar19.Position := Curr;
  CssProgressBar20.Position := Curr;
  CssProgressBar21.Position := Curr;
end;

procedure TForm1.CssButton7Click(Sender : TObject);
var
  Curr: Integer;
begin
  Curr := CssProgressBar19.Position;
  if Curr > 0 then
    dec(Curr, 10);
  CssProgressBar19.Position := Curr;
  CssProgressBar20.Position := Curr;
  CssProgressBar21.Position := Curr;
end;

procedure TForm1.CssLabel2LinkClick(Sender : TObject; const AHref,
  AText : String);
begin
  OnLinkClick(Sender, AHref, AText);
end;

procedure TForm1.FormCreate(Sender : TObject);
const
  SVG_OK      = 0;  // icons8-ok
  SVG_NEWS    = 1;  // icons8-news
  SVG_EDIT    = 2;  // icons8-edit
  SVG_DONE    = 3;  // icons8-done
  SVG_REFRESH = 4;  // icons8-refresh
  SVG_SHARE   = 5;  // icons8-share

var
  Root, tmpNode: TCssVirtualNode;
begin
  EnableSmoothPainting(Self);

  Root := AddTextNode(LeftTree, nil, 'Fruits',   '', SVG_OK,  0);

  AddTextNode(LeftTree, Root, '<b>Apples</b>',  'red',    SVG_OK,      12);
  tmpNode := AddTextNode(LeftTree, Root, '<i>Pears</i>', 'green',  SVG_NEWS,    7);
  LeftTree.DisableNode(tmpNode);
  AddTextNode(LeftTree, Root, 'Oranges',       'orange', SVG_DONE,    9);

  Root := AddTextNode(LeftTree, nil, 'Vegetables', '', SVG_NEWS, 0);
  AddTextNode(LeftTree, Root, 'Carrots',   'orange', SVG_EDIT,    5);
  AddTextNode(LeftTree, Root, 'Potatoes',  'brown',  SVG_REFRESH, 20);
  AddTextNode(LeftTree, Root, 'Cucumbers', 'green',  SVG_SHARE,   3);

  Root := AddTextNode(LeftTree, nil, 'Berries', '', SVG_DONE, 0);
  AddTextNode(LeftTree, Root, 'Raspberries', 'red',   SVG_OK,  8);
  AddTextNode(LeftTree, Root, 'Currants',    'black', SVG_NEWS, 6);

  LeftTree.FullExpand;

  PopulateListViewDemo;
end;

procedure TForm1.PopulateListViewDemo;
const
  SVG_OK      = 0;  // icons8-ok
  SVG_NEWS    = 1;  // icons8-news
  SVG_EDIT    = 2;  // icons8-edit
  SVG_DONE    = 3;  // icons8-done
  SVG_REFRESH = 4;  // icons8-refresh
  SVG_SHARE   = 5;  // icons8-share

var
  Col: TCssListColumn;

  procedure AddReportItem(const AName, AKind, ANote, ASize,
    AModified: string; AImage: Integer; AChecked: Boolean);
  var
    It: TCssListItem;
  begin
    It := CssListView1.Items.AddItem(AName);
    It.SubItems.Add(AKind);
    It.SubItems.Add(ANote);
    It.SubItems.Add(ASize);
    It.SubItems.Add(AModified);
    It.ImageIndex := AImage;
    It.Checked := AChecked;
  end;

  procedure CopyNames(ATarget: TCssListView);
  var
    J: Integer;
    Src, Dst: TCssListItem;
  begin
    ATarget.BeginUpdate;
    try
      for J := 0 to CssListView1.ItemCount - 1 do
      begin
        Src := CssListView1.Items[J];
        Dst := ATarget.Items.AddItem(Src.Caption);
        Dst.ImageIndex := Src.ImageIndex;
      end;
    finally
      ATarget.EndUpdate;
    end;
  end;

begin
  // ------------------------------------------------------------------
  // Report view: columns, SVG cell icons, checkboxes, grid lines,
  // hot tracking, multi-selection, sorting and inline editing.
  // ------------------------------------------------------------------
  CssListView1.Columns.Clear;
  CssListView1.Columns.AddItem('Name', 300);
  Col := CssListView1.Columns.AddItem('Kind', 110);
  Col.Alignment := taCenter;
  CssListView1.Columns.AddItem('Note', 360);
  Col := CssListView1.Columns.AddItem('Size', 90);
  Col.Alignment := taRightJustify;
  CssListView1.Columns.AddItem('Modified', 220);

  CssListView1.BeginUpdate;
  try
    AddReportItem('Projects', 'Folder', 'Contains 12 items', '',
      '2026-10-31 09:12', SVG_NEWS, False);
    AddReportItem('Report.pdf', 'Document', 'Quarterly report', '1.2 MB',
      '2026-10-30 18:45', SVG_OK, True);
    AddReportItem('Presentation.pptx', 'Presentation', 'Product overview',
      '4.8 MB', '2026-10-29 14:20', SVG_SHARE, False);
    AddReportItem('Budget.xlsx', 'Spreadsheet', '2027 planning', '860 KB',
      '2026-10-28 11:05', SVG_DONE, True);
    AddReportItem('Notes.txt', 'Text', 'Meeting notes', '12 KB',
      '2026-10-27 09:30', SVG_EDIT, False);
    AddReportItem('Photo.png', 'Image', 'Screenshot', '2.4 MB',
      '2026-10-26 16:10', SVG_NEWS, False);
    AddReportItem('Music.mp3', 'Audio', 'Demo track', '7.1 MB',
      '2026-10-25 20:00', SVG_SHARE, False);
    AddReportItem('Archive.zip', 'Archive', 'Source backup', '18 MB',
      '2026-10-24 08:15', SVG_REFRESH, False);
    AddReportItem('README.md', 'Markdown', 'Project readme', '6 KB',
      '2026-10-23 12:40', SVG_EDIT, False);
    AddReportItem('Setup.exe', 'Installer', 'Demo installer', '32 MB',
      '2026-10-22 17:55', SVG_OK, False);
    AddReportItem('Logo.svg', 'Vector', 'Application logo', '24 KB',
      '2026-10-21 10:25', SVG_EDIT, False);
    AddReportItem('Video.mp4', 'Video', 'Feature tour', '120 MB',
      '2026-10-20 19:35', SVG_SHARE, False);
    AddReportItem('Data.csv', 'Data', 'Exported records', '3.3 MB',
      '2026-10-19 13:00', SVG_DONE, False);
    AddReportItem('Backup.bak', 'Backup', 'Weekly snapshot', '45 MB',
      '2026-10-18 06:45', SVG_REFRESH, False);
  finally
    CssListView1.EndUpdate;
  end;

  CssListView1.ItemIndex := 1;

  // ------------------------------------------------------------------
  // List view: one column controls the item width; names and icons are
  // copied from the report above.
  // ------------------------------------------------------------------
  CssListView2.Columns.Clear;
  CssListView2.Columns.AddItem('', 160);
  CopyNames(CssListView2);
  CssListView2.ItemIndex := 0;

  // ------------------------------------------------------------------
  // Small icon view: a grid of 16x16 icons with captions.
  // ------------------------------------------------------------------
  CssListView3.Columns.Clear;
  CssListView3.Columns.AddItem('', 170);
  CopyNames(CssListView3);
  CssListView3.ItemIndex := 2;

  // ------------------------------------------------------------------
  // Icon view: the same items rendered with 40x40 artwork.
  // ------------------------------------------------------------------
  CssListView4.Columns.Clear;
  CssListView4.Columns.AddItem('', 120);
  CopyNames(CssListView4);
  CssListView4.ItemIndex := 4;
end;

procedure TForm1.CssListView1Edited(Sender : TObject; Item : TCssListItem;
  const NewText : string);
var
  I: Integer;
begin
  // The report list, the list view, the small icon view and the icon
  // view hold independent items, so keep their captions in sync while
  // the demo is running.
  I := Item.Index;
  if (I >= 0) and (I < CssListView2.ItemCount) then
    CssListView2.Items[I].Caption := NewText;
  if (I >= 0) and (I < CssListView3.ItemCount) then
    CssListView3.Items[I].Caption := NewText;
  if (I >= 0) and (I < CssListView4.ItemCount) then
    CssListView4.Items[I].Caption := NewText;
end;

procedure TForm1.FormKeyDown(Sender : TObject; var Key : Word;
  Shift : TShiftState);
begin
  if Assigned(CssMainMenu1) and CssMainMenu1.HandleKeyDown(Key, Shift) then
    Key := 0;
end;

procedure TForm1.LeftTreeDragOverNodes(Sender : TObject; Nodes : TList;
  TargetNode : TCssVirtualNode; var Allowed : Boolean);
var
  I: Integer;
  SourceTree: TCssVirtualStringTree;
begin
  Allowed := True;

  if (TargetNode <> nil) and
     (TargetNode <> TCssVirtualStringTree(Sender).RootNode) and
     TCssVirtualStringTree(Sender).IsNodeDisabled(TargetNode) then
  begin
    Allowed := False;
    Exit;
  end;

  for I := 0 to Nodes.Count - 1 do
    if TCssVirtualStringTree(Sender).IsNodeDisabled(
         TCssVirtualNode(Nodes[I])) then
    begin
      Allowed := False;
      Exit;
    end;
end;

procedure TForm1.LeftTreeDropNodesEx(Sender : TObject;
  SourceTree : TCssVirtualStringTree; Nodes : TList;
  TargetNode : TCssVirtualNode);
var
  TargetTree: TCssVirtualStringTree;
  I: Integer;
  SrcNode: TCssVirtualNode;
  ToDelete: TList;
begin
  TargetTree := TCssVirtualStringTree(Sender);

  if SourceTree = TargetTree then
  begin
    TargetTree.MoveNodes(Nodes, TargetNode);
    Exit;
  end;

  if TargetNode = nil then
    TargetNode := TargetTree.RootNode;

  ToDelete := TList.Create;
  try
    for I := 0 to Nodes.Count - 1 do
    begin
      SrcNode := TCssVirtualNode(Nodes[I]);
      if SrcNode = nil then Continue;
      if SrcNode = SourceTree.RootNode then Continue;
      if NodeInsideAny(SrcNode, Nodes) then Continue;
      ToDelete.Add(SrcNode);
    end;

    if ToDelete.Count = 0 then
      Exit;

    TargetTree.BeginUpdate;
    try
      for I := 0 to ToDelete.Count - 1 do
        CopyNodeToTree(
          TCssVirtualNode(ToDelete[I]),
          TargetTree,
          TargetNode
        );
    finally
      TargetTree.EndUpdate;
    end;

    SourceTree.BeginUpdate;
    try
      for I := 0 to ToDelete.Count - 1 do
        SourceTree.DeleteNode(TCssVirtualNode(ToDelete[I]));
    finally
      SourceTree.EndUpdate;
    end;

    if TargetNode <> TargetTree.RootNode then
      TargetTree.ExpandNode(TargetNode);
  finally
    ToDelete.Free;
  end;
end;

procedure TForm1.LeftTreeEditing(Sender : TObject; Node : TCssVirtualNode;
  Column : Integer; var Allowed : Boolean);
begin
  if Column = 3 then Allowed := False;
end;

procedure TForm1.LeftTreeFreeNode(Sender : TObject; Node : TCssVirtualNode);
begin
  Finalize(PNodeData(Node.Data)^);
end;

procedure TForm1.LeftTreeGetImageIndex(Sender : TObject;
  Node : TCssVirtualNode; Column : Integer; var ImageIndex : Integer);
var
  D: PNodeData;
begin
  ImageIndex := -1;

  if not Assigned(Node.Data) then Exit;

  D := PNodeData(Node.Data);

  if Column = 1 then
  begin
    if (D^.Kind >= 0) and (D^.Kind < CssSvgImgList1.Count) then
      ImageIndex := D^.Kind;
  end;
end;

procedure TForm1.LeftTreeGetNodeDataSize(
  Sender : TObject; var NodeDataSize : Integer);
begin
  NodeDataSize := SizeOf(TNodeData);
end;

procedure TForm1.LeftTreeGetText(Sender : TObject; Node : TCssVirtualNode;
  Column : Integer; TextType : TCssVirtualTreeTextType; var CellText : String);
var
  D: PNodeData;
begin
  CellText := '';
  if not Assigned(Node.Data) then Exit;

  D := PNodeData(Node.Data);

  case Column of
    0: CellText := D^.Caption;
    1: ;
    2: CellText := D^.Note;
    3: if D^.Size > 0 then
         CellText := IntToStr(D^.Size) + ' KB';
  else
    CellText := '';
  end;
end;

procedure TForm1.LeftTreeInitNode(Sender : TObject; Node : TCssVirtualNode);
begin
  Initialize(PNodeData(Node.Data)^);
end;

procedure TForm1.LeftTreeNewText(Sender : TObject; Node : TCssVirtualNode;
  Column : Integer; const NewText : string);
var
  D: PNodeData;
  Tree: TCssVirtualStringTree;
begin
  if not Assigned(Node.Data) then
    Exit;

  D := PNodeData(Node.Data);
  Tree := TCssVirtualStringTree(Sender);

  case Column of
    0:
      D^.Caption := Tree.PlainTextToHtml(NewText);

    2:
      D^.Note := Tree.PlainTextToHtml(NewText);

    3:
      D^.Size := StrToIntDef(Trim(NewText), D^.Size);
  end;
end;


procedure TForm1.MenuItem1Click(Sender : TObject);
begin
  CssButton5.Caption := MenuItem1.Caption;
end;

procedure TForm1.MenuItem2Click(Sender : TObject);
begin
  CssButton5.Caption := MenuItem2.Caption;
end;

procedure TForm1.MenuItem5Click(Sender : TObject);
begin
  CssCheckBox1.Checked := not CssCheckBox1.Checked;
  CssCheckBox1Click(Sender);
end;

procedure TForm1.MenuItem8Click(Sender : TObject);
begin
  Application.Terminate;
end;

function TForm1.AddTextNode(Tree : TCssVirtualStringTree;
  aParent : TCssVirtualNode; const ACaption, ANote : string; AKind,
  ASize : Integer) : TCssVirtualNode;
begin
  Result := Tree.AddChild(aParent);
  if Assigned(Result.Data) then
  begin
    PNodeData(Result.Data)^.Caption := ACaption;
    PNodeData(Result.Data)^.Note    := ANote;
    PNodeData(Result.Data)^.Kind    := AKind;
    PNodeData(Result.Data)^.Size    := ASize;
  end;
end;

function TForm1.CopyNodeToTree(
  SrcNode: TCssVirtualNode;
  TargetTree: TCssVirtualStringTree;
  TargetParent: TCssVirtualNode): TCssVirtualNode;
var
  Child: TCssVirtualNode;
begin
  Result := TargetTree.AddChild(TargetParent);

  if Assigned(Result.Data) and Assigned(SrcNode.Data) then
    PNodeData(Result.Data)^ := PNodeData(SrcNode.Data)^;

  Result.States := SrcNode.States - [cvsSelected];

  Child := SrcNode.FirstChild;
  while Child <> nil do
  begin
    CopyNodeToTree(Child, TargetTree, Result);
    Child := Child.NextSibling;
  end;
end;

procedure TForm1.OnLinkClick(Sender : TObject; const AHref, AText : String);
begin
  CssMessageBox('Link clicked', 'Href='+AHref+' , Text='+AText, MB_YESNOCANCEL or MB_ICONINFORMATION);
end;

end.

