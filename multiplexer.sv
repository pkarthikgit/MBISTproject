module multiplexer #(parameter WIDTH = 8)
(
    input  logic [WIDTH-1:0] normal_in,
    input  logic [WIDTH-1:0] bist_in,
    input  logic NbarT,
    output logic [WIDTH-1:0] out
);

    always_comb begin
        if (NbarT) begin
            out = bist_in;
        end else begin
            out = normal_in;
        end
    end
endmodule
