module tb_decoder;
  //------------------------------------------------------------------
  // Local parameters
  //------------------------------------------------------------------
  `define QWIDTH 3
  `define DWIDTH 8

  //------------------------------------------------------------------
  // DUT interface signals
  //------------------------------------------------------------------
  logic [`QWIDTH-1:0] q;
  logic [`DWIDTH-1:0] data_t;

  //------------------------------------------------------------------
  // Instantiate DUT
  //------------------------------------------------------------------
  decoder dut (
    .q      (q),
    .data_t (data_t)
  );

  //------------------------------------------------------------------
  // Utility: PASS / FAIL reporter
  //------------------------------------------------------------------
  task automatic check_output(input logic [`DWIDTH-1:0] exp_data);
    if (data_t !== exp_data) begin
      $display("FAIL\tTime=%0t\t q=%b | Expected data_t=%b | Got data_t=%b", $time, q, exp_data, data_t);
    end else begin
      $display("PASS\tTime=%0t\t q=%b | data_t=%b", $time, q, data_t);
    end
  endtask

  //------------------------------------------------------------------
  // Stimulus (combinational)
  //------------------------------------------------------------------
  initial begin
    //--------------------------------------------------------------
    // 1) Fixed cases
    //--------------------------------------------------------------
    q = 3'b000; #1; check_output(8'b10101010);
    q = 3'b001; #1; check_output(8'b01010101);
    q = 3'b010; #1; check_output(8'b11110000);
    q = 3'b011; #1; check_output(8'b00001111);
    q = 3'b100; #1; check_output(8'b00000000);
    q = 3'b101; #1; check_output(8'b11111111);

    //--------------------------------------------------------------
    // 2) Unknown outputs for undefined codes
    //--------------------------------------------------------------
    q = 3'b110; #1; check_output(8'bxxxxxxxx);
    q = 3'b111; #1; check_output(8'bxxxxxxxx);

    //--------------------------------------------------------------
    // 3) Randomized verification
    //--------------------------------------------------------------
    repeat (10) begin
      void'(std::randomize(q));
      #1;
      unique case (q)
        3'b000: check_output(8'b10101010);
        3'b001: check_output(8'b01010101);
        3'b010: check_output(8'b11110000);
        3'b011: check_output(8'b00001111);
        3'b100: check_output(8'b00000000);
        3'b101: check_output(8'b11111111);
        default: check_output(8'bxxxxxxxx);
      endcase
    end

    //--------------------------------------------------------------
    // Finish simulation
    //--------------------------------------------------------------
    $display("All decoder tests completed.");
    $finish;
  end
endmodule
