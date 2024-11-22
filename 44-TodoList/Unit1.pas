unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl,
  FMX.Effects, FMX.StdCtrls, FMX.Controls.Presentation, FireDAC.UI.Intf,
  FireDAC.FMXUI.Wait, FireDAC.Stan.ExprFuncs, FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  Data.DB, FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.DApt, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, System.Rtti,
  System.Bindings.Outputs, Fmx.Bind.Editors, Data.Bind.EngExt,
  Fmx.Bind.DBEngExt, Data.Bind.Components, Data.Bind.DBScope, FMX.ListView,
  FireDAC.Comp.Client, FireDAC.Phys.SQLiteVDataSet, FireDAC.Comp.DataSet,
  FireDAC.Comp.UI, FMX.Edit, FMX.Layouts, FMX.ListBox;

type
  TForm1 = class(TForm)
    MaterialOxfordBlueSB: TStyleBook;
    ToolBar1: TToolBar;
    Label1: TLabel;
    ShadowEffect1: TShadowEffect;
    TabControl1: TTabControl;
    ListTab: TTabItem;
    EditTab: TTabItem;
    ListView1: TListView;
    AddButton: TButton;
    BackButton: TButton;
    ListItemsTab: TTabItem;
    Label2: TLabel;
    Edit1: TEdit;
    SaveButton: TButton;
    MasterFDMemTable: TFDMemTable;
    BindSourceDB1: TBindSourceDB;
    BindingsList1: TBindingsList;
    LinkListControlToField1: TLinkListControlToField;
    ListBox1: TListBox;
    BindSourceDB2: TBindSourceDB;
    LinkListControlToField2: TLinkListControlToField;
    Edit2: TEdit;
    DetailFDMemTable: TFDMemTable;
    DetailLabel: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    procedure AddButtonClick(Sender: TObject);
    procedure BackButtonClick(Sender: TObject);
    procedure SaveButtonClick(Sender: TObject);
    procedure ListBox1ChangeCheck(Sender: TObject);
    procedure ListView1ItemClickEx(const Sender: TObject; ItemIndex: Integer;
      const LocalClickPos: TPointF; const ItemObject: TListItemDrawable);
    procedure TabControl1Change(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.fmx}

procedure DelayedSetFocus(Control: TControl);
begin
  TThread.CreateAnonymousThread(
    procedure
    begin
      TThread.Synchronize( nil,
         procedure
         begin
           Control.SetFocus;
         end
      );
    end
  ).Start;
end;

procedure TForm1.AddButtonClick(Sender: TObject);
begin
  DetailLabel.Visible := False; // Ẩn DetailLabel
  Form1.Tag := TabControl1.TabIndex; // Lưu tab hiện tại
  TabControl1.GotoVisibleTab(2); // Chuyển đến tab thêm mới
end;

procedure TForm1.BackButtonClick(Sender: TObject);
begin
  // Ẩn DetailLabel khi quay lại từ bất kỳ tab nào
  DetailLabel.Visible := False;

  case TabControl1.TabIndex of
    1: // Nếu đang ở tab chi tiết
      TabControl1.GotoVisibleTab(0); // Quay lại tab chính
    2: // Nếu đang ở tab thêm mới
      TabControl1.GotoVisibleTab(0); // Quay lại tab chính
  end;
end;

procedure TForm1.SaveButtonClick(Sender: TObject);
var
  FullEntry: string;
begin
  case Form1.Tag of
    0:
      begin
        MasterFDMemTable.Append;

        // Kết hợp tên và số điện thoại
        FullEntry := Edit1.Text + ' - ' + Edit2.Text; // Nối tên và số điện thoại
        MasterFDMemTable.FieldByName('Title').AsString := FullEntry;

        MasterFDMemTable.Post;

        LinkListControlToField1.Active := False;
        LinkListControlToField1.Active := True;
      end;
    1:
      begin
        // Chỉ lưu tên trong trường hợp này
        DetailFDMemTable.AppendRecord([nil, MasterFDMemTable.FieldByName('Id').AsInteger, Edit1.Text, False]);
        LinkListControlToField2.Active := False;
        LinkListControlToField2.Active := True;
      end;
  end;

  // Làm sạch các trường
  Edit1.Text := '';
  Edit2.Text := '';
  TabControl1.GotoVisibleTab(Form1.Tag);
end;



procedure TForm1.ListBox1ChangeCheck(Sender: TObject);
begin
  if DetailFDMemTable.Locate('Id',VarArrayOf([TListBoxItem(Sender).ImageIndex])) then
    begin
      DetailFDMemTable.Edit;
      DetailFDMemTable.FieldByName('Done').AsBoolean := ListBox1.Selected.IsChecked;
      DetailFDMemTable.Post;
    end;
end;

procedure TForm1.TabControl1Change(Sender: TObject);
begin
  case TabControl1.TabIndex of
    0: begin
      AddButton.Visible := True; // Hiển thị nút "Thêm" ở tab chính
      BackButton.Visible := False; // Ẩn nút "Quay lại"
    end;
    1: begin
      AddButton.Visible := False; // Ẩn nút "Thêm" ở tab chi tiết
      BackButton.Visible := True; // Hiển thị nút "Quay lại"
    end;
    2: begin
      AddButton.Visible := False; // Ẩn nút "Thêm" ở tab thêm mới
      BackButton.Visible := True; // Hiển thị nút "Quay lại"
      DelayedSetFocus(Edit1); // Đặt tiêu điểm vào Edit1
    end;
  end;

  // Ẩn nút "Thêm" nếu DetailLabel đang hiển thị
  if DetailLabel.Visible then
    AddButton.Visible := False;
end;

procedure TForm1.ListView1ItemClickEx(const Sender: TObject; ItemIndex: Integer;
  const LocalClickPos: TPointF; const ItemObject: TListItemDrawable);
var
  FullEntry: string;
  Parts: TArray<string>;
  Name: string;
  Phone: string;
begin
  // Lấy thông tin từ dòng được chọn trong ListView
  FullEntry := ListView1.Items[ItemIndex].Text;

  // Tách tên và số điện thoại
  Parts := FullEntry.Split([' - ']);

  // Gán giá trị cho tên và số điện thoại
  if Length(Parts) > 0 then
    Name := Parts[0]
  else
    Name := 'Chưa có tên';

  if Length(Parts) > 1 then
    Phone := Parts[1]
  else
    Phone := 'Chưa có số điện thoại';

  // Hiển thị thông tin chi tiết
  DetailLabel.Text := Format('Họ và tên người liên hệ là: %s' + sLineBreak +
                              'Số điện thoại người liên hệ là: %s', [Name, Phone]);

  // Hiển thị DetailLabel
  DetailLabel.Visible := True;

  // Chuyển đến tab hiển thị chi tiết
  TabControl1.GotoVisibleTab(1);
end;


end.
