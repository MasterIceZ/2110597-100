module toolbar_renderer(
  input wire clk,
  
  input wire [9:0] pix_x_1,
  input wire [9:0] pix_y_1,

  input wire [9:0] pix_x_2,
  input wire [9:0] pix_y_2,

  input wire [2:0] selected_color,
  input wire [1:0] selected_brush,

  output reg [5:0] rgb
);

  wire [1:0] brush_1 = pix_x_1[6:5];
  wire [3:0] row_1 = pix_y_1[3:0] - 4'd8;

  wire [6:0] char_1;
  brush_to_char ascii (
    .brush(brush_1),
    .code(char_1)
  );

  wire [7:0] font_word;
  ascii_rom font(
    .clk(clk),
    .addr({char_1, row_1}),
    .data(font_word)
  );

  wire [4:0] slot = pix_x_2[9:5];
  wire [4:0] tx = pix_x_2[4:0];
  wire [4:0] ty = pix_y_2[4:0];

  wire is_swatch = (slot >= 1) && (slot <= 7);
  wire is_brush = (slot[4:2] == 3'b011);

  wire box_frame = (tx >= 1 && tx <= 30 && ty >= 3 && ty <= 28) &&
                  !(tx >= 3 && tx <= 28 && ty >= 5 && ty <= 26);
  wire box_fill = (tx >= 4 && tx <= 27 && ty >= 6 && ty <= 25);

  wire [2:0] bcol = tx[2:0] - 3'd4;
  wire bglyph = (tx >= 12 && tx <= 19 && ty >= 8 && ty <= 23 && font_word[7 - bcol]);

  wire [5:0] fill_rgb;
  color_palette colors (
    .index(is_swatch ? slot[2:0] : selected_color),
    .rgb(fill_rgb)
  );

  always @(*) begin
    rgb = 0;
    if(ty == 0) begin
      rgb = 6'b010101;
    end else if (is_swatch) begin
      if (box_frame && slot[2:0] == selected_color) begin
        rgb = 6'b111111;
      end else if (box_fill) begin
        rgb = fill_rgb;
      end
    end else if (is_brush) begin
      if (box_frame && slot[1:0] == selected_brush) begin
        rgb = 6'b111111;
      end else if (bglyph) begin
        rgb = fill_rgb;
      end
    end
  end

endmodule