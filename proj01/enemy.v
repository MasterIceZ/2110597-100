module enemy #(
  parameter [9:0] ENEMY_SIZE = 10'd30
) (
  // player middle point
  input wire [9:0] enemy_x,
  input wire [9:0] enemy_y,
  input wire enemy_alive,

  input wire [9:0] pix_x,
  input wire [9:0] pix_y,

  output wire is_enemy
);
  localparam [9:0] R = ENEMY_SIZE >> 1; 
  
  assign is_enemy = enemy_alive
                    && ((enemy_x- R) <= pix_x && pix_x <= (enemy_x + R))
                    && ((enemy_y - R) <= pix_y && pix_y <= (enemy_y + R));
endmodule