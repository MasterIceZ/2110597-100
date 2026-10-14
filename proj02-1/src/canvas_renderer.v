module canvas_renderer #(
  parameter COL,
  parameter ROW,

  parameter AW
) (
  input wire clk,
  input wire rst_n,
  input wire frame_tick,

  input wire [9:0] pix_x,
  input wire [9:0] pix_y,
  
  output wire [AW-1:0] rd_addr,

  input wire [9:0] pix_x_1,
  input wire [9:0] pix_y_1,
  input wire [4:0] cell_data,

  input wire [9:0] pix_x_2,
  input wire [9:0] pix_y_2,

  input wire [9:0] cursor_x,
  input wire [9:0] cursor_y,
  input wire [2:0] selected_color,
  input wire [1:0] selected_brush,
  input wire grid_on,

  output reg [5:0] rgb
);

  reg [5:0] frame_cnt;
  always @(posedge clk) begin
    if(~rst_n) begin
      frame_cnt <= 0;
    end else if (frame_tick) begin
      frame_cnt <= frame_cnt + 1;
    end
  end
  wire blink = frame_cnt[5];

  wire in_canvas = (pix_x < 10'd640) && (pix_y < 448);
  wire [9:0] rcx = pix_x >> 3;
  wire [9:0] rcy = pix_y >> 4;

  wire [19:0] rd_lin = {10'd0, rcy} * {10'd0, COL[9:0]} + {10'd0, rcx};
  assign rd_addr = in_canvas ? rd_lin[AW - 1:0] : {AW{1'b0}};

  wire is_cursor_1 = ((pix_x_1 >> 3) == cursor_x) && ((pix_y_1 >> 4) == cursor_y);
  wire preview_1 = is_cursor_1 && blink;
  wire [2:0] color_1 = preview_1 ? selected_color : cell_data[4:2];
  wire [1:0] brush_1 = preview_1 ? selected_brush : cell_data[1:0];
  wire [3:0] row_1 = pix_y_1[3 -: 4];

  wire [6:0] char_1;
  brush_to_char ascii(
    .brush(brush_1),
    .code(char_1)
  );

  wire [7:0] font_word;
  ascii_rom font (
    .clk(clk),
    .addr({char_1, row_1}),
    .data(font_word)
  );

  reg [2:0] color_2;
  reg is_cursor_2;
  always @(posedge clk) begin
    color_2 <= color_1;
    is_cursor_2 <= is_cursor_1;
  end

  wire [2:0] pixel_cell_x = pix_x_2[2:0];
  wire [3:0] pixel_cell_y = pix_y_2[3:0];
  wire [2:0] gx = pix_x_2[2 -: 3];

  wire cursor_border = is_cursor_2 &&
                        ((pixel_cell_x == 0 || pixel_cell_x == 7) ||
                        (pixel_cell_y == 0 || pixel_cell_y == 15));
  wire glyph_on = (color_2 != 0) && font_word[3'd7 - gx];
  wire grid_dot = grid_on && (pixel_cell_x == 0 && pixel_cell_y == 0);

  wire [5:0] glyph_rgb;
  color_palette colors (
    .index(color_2),
    .rgb(glyph_rgb)
  );

  always @(*) begin
    if(cursor_border) begin
      rgb = 6'b111111;
    end else if (glyph_on) begin
      rgb = glyph_rgb;
    end else if (grid_dot) begin
      rgb = 6'b010101;
    end else begin
      rgb = 6'b000000;
    end
  end

endmodule