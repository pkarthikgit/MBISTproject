module controller
(
    input logic start,
    input logic rst,
    input logic clk,
    input logic cout,
    output logic NbarT,
    output logic ld
   
);
    parameter RESET = 2'b00, 
                TEST = 2'b01;



    logic [1:0] state, next_state;

    logic NbarT_r, ld_r;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= RESET;
            NbarT_r  <= 1'b0;
            ld_r     <= 1'b1;
        end else begin
            state <= next_state;
            // outputs follow the *new* state immediately
            NbarT_r  <= (next_state == TEST);
            ld_r     <= (next_state == RESET);
        end
    end

    assign NbarT = NbarT_r;
    assign ld    = ld_r;

    always_comb begin
        next_state = RESET;
  
        case (state)
            RESET: begin

                if (start) begin
                    next_state = TEST;

                end else begin
                    next_state = RESET;
                end
            end

            TEST: begin
  
                if (cout) begin
                    next_state = RESET;
                end else begin
                    next_state = TEST;
                end
            end

            default: next_state = RESET;
        endcase
    end
endmodule
