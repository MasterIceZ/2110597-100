module bullet #(
  parameter [9:0] BULLET_X = 10'd10,
  parameter [9:0] BULLET_Y = 10'd30
) (
  input wire [9:0] bullet_x,
  input wire [9:0] bullet_y,

  input wire [9:0] pix_x,
  input wire [9:0] pix_y,

  output wire is_bullet
);
  localparam [9:0] R_x = BULLET_X >> 1; 
  localparam [9:0] R_y = BULLET_Y >> 1;

  assign is_bullet = ((bullet_x - R_x) <= pix_x && pix_x <= (bullet_x + R_x)) 
                  && ((bullet_y - R_y) <= pix_y && pix_y <= (bullet_y + R_y));
endmodule