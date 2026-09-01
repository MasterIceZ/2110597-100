module player #(
  parameter [9:0] PLAYER_SIZE = 10'd30
) (
  // player middle point
  input wire [9:0] player_x,
  input wire [9:0] player_y,

  input wire [9:0] pix_x,
  input wire [9:0] pix_y,

  output wire is_player
);
  localparam [9:0] R = PLAYER_SIZE >> 1; 

  assign is_player = ((player_x - R) <= pix_x && pix_x <= (player_x + R)) 
                  && ((player_y - R) <= pix_y && pix_y <= (player_y + R));
endmodule