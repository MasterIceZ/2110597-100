module frame_delay (
  input wire clk,
  input wire [9:0] pix_x,
  input wire [9:0] pix_y,

  input wire video_active,
  input wire hsync_in,
  input wire vsync_in,

  output reg [9:0] pix_x_1,
  output reg [9:0] pix_y_1,

  output reg [9:0] pix_x_2,
  output reg [9:0] pix_y_2,

  output reg de2,
  output reg hsync,
  output reg vsync 
);

  reg de1;

  always @(posedge clk) begin
    pix_x_1 <= pix_x;
    pix_y_1 <= pix_y;
    de1 <= video_active;

    pix_x_2 <= pix_x_1;
    pix_y_2 <= pix_y_1;
    de2 <= de1;

    hsync <= hsync_in;
    vsync <= vsync_in;
  end

endmodule