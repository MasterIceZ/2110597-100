module button_sanitizer #(
  parameter WIDTH = 1
) (
  input wire clk,
  input wire rst_n,
  input wire tick,
  input wire [WIDTH-1:0] btn,

  output wire [WIDTH-1:0] pressed
);

  reg [WIDTH-1:0] prev;

  always @(posedge clk) begin 
    if (~rst_n) begin
      prev <= {WIDTH{1'b0}};
    end else if (tick) begin
      prev <= btn;
    end
  end

  assign pressed = btn & ~prev;

endmodule