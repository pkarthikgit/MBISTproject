module comparator #(parameter WIDTH = 8 ) 
(
    input  logic [WIDTH-1:0] data_t,
    input  logic [WIDTH-1:0] ramout,
    output logic            gt, 
    output logic            eq,
    output logic            lt
);

always_comb begin
    if (data_t > ramout) begin
        gt = 1'b1;
        eq = 1'b0;
        lt = 1'b0;
    end
    else if (data_t == ramout) begin
        gt = 1'b0;
        eq = 1'b1;
        lt = 1'b0;
    end
    else begin
        gt = 1'b0;
        eq = 1'b0;
        lt = 1'b1;
    end
end

endmodule
