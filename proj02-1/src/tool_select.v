module tool_select (
  input wire clk,
  input wire rst_n,
  input wire tick,

  input wire color_next,
  input wire color_prev,
  
  input wire brush_next,
  input wire brush_prev,

  input wire grid_toggle,

  output reg [2:0] selected_color,
  output reg [1:0] selected_brush,

  output reg grid_on 
);


  always @(posedge clk) begin
    if(~rst_n) begin
      selected_color <= 1;
      selected_brush <= 0;
      grid_on <= 1;
    end else if (tick) begin
      if (color_next) begin
        selected_color <= (selected_color == 7) ? 3'd1 : selected_color + 1;
      end else if (color_prev) begin
        selected_color <= (selected_color == 1) ? 3'd7 : selected_color - 1;
      end

      if (brush_next) begin
        selected_brush <= selected_brush + 1;
      end else if (brush_prev) begin
        selected_brush <= selected_brush - 1;
      end
      
      if (grid_toggle) begin
        grid_on <= ~grid_on;
      end
    end
  end

endmodule