{
use PascalABC.NET to run this code:
   http://pascalabc.net/en/

*******************
***    MINER    ***
*******************
}
uses GraphABC;

const
  WIDTH = 10;       // field width, maximum 127
  HEIGHT = 10;      // field height, maximum 127
  CELL_SIZE = 30;   // cell size in pixels
  MINES_COUNT = 10;
  BORDER = 1;       // width of border between cells

var
  Mines, Field: array [1..WIDTH, 1..HEIGHT] of shortint;
  {
  Field - field, as seen by player
    0..8 - mines around
    9 - not used
    10 - cell is unopened
    11 - mine
    12 - flag

  Mines - actual field state
    0 - no mine
    1 - mine
  }

//////// Initialization ////////

// at the start, all cells are unopened
procedure InitField();
var i,j: shortint;
begin
  for i := 1 to WIDTH do
    for j := 1 to HEIGHT do
      Field[i, j] := 10;
end;

// randomly placing mines
procedure PlaceMines();
var YetPlaced, pos_x, pos_y: shortint;
begin
  YetPlaced := 0;
  while YetPlaced < MINES_COUNT do
  begin
    pos_x := Random(WIDTH) + 1;
    pos_y := Random(HEIGHT) + 1;
    if Mines[pos_x, pos_y] = 0 then
    begin
      Mines[pos_x, pos_y] := 1;
      inc(YetPlaced);
    end
  end
end;

//////// Cell drawing routines ////////

procedure DrawClosed(i, j: shortint; Color: System.Drawing.Color);
var c: System.Drawing.Color;
begin
  c := Brush.Color;
  Brush.Color := Color;
  FillRoundRect( (i-1)*CELL_SIZE + BORDER, (j-1)*CELL_SIZE + BORDER,
    i*CELL_SIZE - BORDER, j*CELL_SIZE - BORDER, 4, 4);
  Brush.Color := c;
end;

procedure DrawMine(i, j: shortint);
var c: System.Drawing.Color;
begin
  c := Brush.Color;
  Brush.Color := clBlack;
  DrawRoundRect( (i-1)*CELL_SIZE + BORDER, (j-1)*CELL_SIZE + BORDER,
    i*CELL_SIZE - BORDER, j*CELL_SIZE - BORDER, 4, 4);
  FillCircle( (i-1)*CELL_SIZE + CELL_SIZE div 2,
    (j-1)*CELL_SIZE + CELL_SIZE div 2, CELL_SIZE div 5);
  Brush.Color := c;
end;

procedure DrawFlag(i, j: shortint);
var c: System.Drawing.Color; p1, p2, p3: System.Drawing.Point;
begin
  c := Brush.Color;
  Brush.Color := clRed;
  DrawClosed(i,j, clDarkGray);
  p1 := new Point((i-1)*CELL_SIZE + CELL_SIZE div 4,
    (j-1)*CELL_SIZE + CELL_SIZE div 4);
  p2 := new Point((i-1)*CELL_SIZE + CELL_SIZE div 4,
    (j-1)*CELL_SIZE + 3 * (CELL_SIZE div 4));
  p3 := new Point((i-1)*CELL_SIZE + 3 * (CELL_SIZE div 4),
    (j-1)*CELL_SIZE + CELL_SIZE div 2);
  Polygon(new Point[3] (p1, p2, p3));
  Brush.Color := c;
end;

procedure DrawNumber(var i, j, n: shortint);
begin
  case n of
    1: Font.Color := clBlue;
    2: Font.Color := clGreen;
    3: Font.Color := clRed;
    4: Font.Color := clDarkBlue;
    else Font.Color := clBlack;
  end;
  DrawRoundRect( (i-1)*CELL_SIZE + BORDER, (j-1)*CELL_SIZE + BORDER,
    i*CELL_SIZE - BORDER, j*CELL_SIZE - BORDER, 4, 4);
  if n <> 0 then
  DrawTextCentered( (i-1)*CELL_SIZE + BORDER, (j-1)*CELL_SIZE + BORDER,
    i*CELL_SIZE - BORDER, j*CELL_SIZE - BORDER, n);
end;

procedure DrawField();
var i,j: shortint;
begin
  FillRectangle(0, 0, WindowWidth(), WindowHeight());
  for i := 1 to WIDTH do
    for j := 1 to HEIGHT do
    begin
      case Field[i, j] of
        10: DrawClosed(i,j, clDarkGray);
        11: DrawMine(i,j);
        12: DrawFlag(i,j);
        else DrawNumber(i,j, Field[i,j]);
      end
    end
end;

//////// Auxiliary ////////

function IsMine(x,y: shortint): boolean;
begin
  Result := (Mines[x,y] = 1);
end;

// how much mines around
function HowMuchMines(x,y: shortint): shortint;
var i, j, n: shortint;
begin
  n := 0;
  for i := -1 to 1 do
    for j := -1 to 1 do
      if ((x+i >= 1) and (x+i <= WIDTH) and (y+j >= 1) and (y+j <= HEIGHT)) then
        if IsMine(x+i,y+j) then
          inc(n);
  Result := n;
end;

// show message and quit game
procedure Quit(s: string; c: System.Drawing.Color);
begin
  DrawField();
  LockDrawing();
  Font.Color := c;
  Font.Size := CELL_SIZE;
  DrawTextCentered(0,0,WindowWidth(),WindowHeight(), s);
  Redraw;
  Sleep(2000);
  Halt;
end;

//////// Game logic ////////

// discover a cell (left click on a closed cell)
procedure Unveil(x,y: shortint);
var n, i, j: shortint;
begin
  if ((x >= 1) and (x <= WIDTH) and (y >= 1) and (y <= HEIGHT)) then
  begin
    n := HowMuchMines(x, y);
    Field[x, y] := n;
    if n = 0 then
    begin
      for i := -1 to 1 do
        for j := -1 to 1 do
          if ((x+i >= 1)and(x+i <= WIDTH)and(y+j >= 1)and(y+j <= HEIGHT)) then
            if Field[x+i, y+j] = 10 then
              Unveil(x + i, y + j)
    end
  end;
end;

procedure MouseDown(x,y,mb: integer); forward;

// explore the area around (right click on an opened cell)
procedure Open(x,y: shortint);
var i, j, n: shortint;
begin
  n := 0;
  for i := -1 to 1 do
    for j := -1 to 1 do
      if ((x+i >= 1) and (x+i <= WIDTH) and (y+j >= 1) and (y+j <= HEIGHT)) then
        if Field[x+i,y+j] = 12 then
          inc(n);
  if Field[x, y] = n then
    for i := -1 to 1 do
      for j := -1 to 1 do
        if ((x+i >= 1) and (x+i <= WIDTH) and (y+j >= 1) and (y+j <= HEIGHT)) then
          if Field[x+i,y+j] = 10 then
            MouseDown((x+i-1)*CELL_SIZE, (y+j-1)*CELL_SIZE, 1);
end;

// win conditions are checking after each mouse click
procedure WinConditions();
var i,j, rightFlags, wrongFlags, closedCells: shortint;
begin
  rightFlags := 0;
  wrongFlags := 0;
  closedCells := 0;
  for i := 1 to WIDTH do
    for j := 1 to HEIGHT do
      case Field[i,j] of
        10: inc(closedCells);
        12: if IsMine(i,j) then inc(rightFlags) else inc(wrongFlags);
      end;
  if ((wrongFlags = 0) and (rightFlags + closedCells = MINES_COUNT)) then
    Quit('You Win!', clGreen);
end;

// field mouse click handler
procedure MouseDown(x,y,mb: integer);
var cell_x, cell_y: shortint;
begin
  LockDrawing;
  cell_x := (x div CELL_SIZE) + 1;
  cell_y := (y div CELL_SIZE) + 1;
  // left button AND cell is closed = open a cell
  if ((mb = 1) and (Field[cell_x, cell_y] = 10)) then
  begin
    if IsMine(cell_x, cell_y) then
    begin
      Field[cell_x, cell_y] := 11;
      Quit('Game Over!', clRed);   // stumble on a mine - loose
    end
    else
      Unveil(cell_x, cell_y);
  end;
  // right button
  if mb = 2 then
    case Field[cell_x, cell_y] of
      10: Field[cell_x, cell_y] := 12;  // flag management
      12: Field[cell_x, cell_y] := 10;
      else Open(cell_x, cell_y);
    end;
  DrawField();
  Redraw;
  WinConditions;
end;

//////// Program entry point ////////

begin
  // initialization
  Brush.Color := clWhite;
  Pen.Color := clBlack;
  Font.Size := CELL_SIZE div 2;
  Font.Style := fsBold;
  OnMouseDown := MouseDown;
  SetWindowWidth(WIDTH * CELL_SIZE);
  SetWindowHeight(HEIGHT * CELL_SIZE);

  PlaceMines();
  InitField();
  DrawField();

  // now waiting for mouse clicks...
end.
