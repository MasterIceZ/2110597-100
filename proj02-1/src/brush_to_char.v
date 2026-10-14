module brush_to_char (
  input wire [1:0] brush,
  
  output reg [6:0] code
);

  always @(*) begin
    case (brush)
      2'd0: code = 7'h2A;
      2'd1: code = 7'h23;
      2'd2: code = 7'h40;
      default: code = 7'h25;
    endcase
  end

endmodule