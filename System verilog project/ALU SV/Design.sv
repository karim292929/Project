module Design(
    input logic [3:0] a,b,
    output logic [7:0] y,
    input logic [2:0] op
    );


always_comb begin
 case(op)
 3'b000: y=a+b;
 3'b001: y=a-b;
 3'b010: y=a&b;
 3'b011: y=a|b;
 default:y=8'b00000000;
 endcase
end
endmodule
 
