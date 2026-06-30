module tb_multiplexer;
  `define WIDTH  8

  //------------------------------------------------------------------
  // DUT interface signals
  //------------------------------------------------------------------
  logic [`WIDTH-1:0] normal_in, bist_in, out;
  logic             NbarT;

  //------------------------------------------------------------------
  // Instantiate DUT
  //------------------------------------------------------------------
  multiplexer #(.WIDTH(`WIDTH)) dut (
    .normal_in (normal_in),
    .bist_in   (bist_in),
    .NbarT     (NbarT),
    .out       (out)
  );

  //------------------------------------------------------------------
  // Utility: Pass/Fail reporter
  //------------------------------------------------------------------
  task automatic check_output(input logic [`WIDTH-1:0] exp_out);
    if (out !== exp_out) begin
      $display("FAIL\tTime=%0t\t Expected out:%h | Got:%h (NbarT=%0b)", $time, exp_out, out, NbarT);
    end else begin
      $display("PASS\tTime=%0t\t Expected out:%h | Got:%h (NbarT=%0b)", $time, exp_out, out, NbarT);
    end
  endtask

  //------------------------------------------------------------------
  // Stimulus (purely combinational)
  //------------------------------------------------------------------
  initial begin
    //--------------------------------------------------------------
    // 1) Basic functional cases
    //--------------------------------------------------------------
    normal_in = 8'hA5; bist_in = 8'h5A; NbarT = 0; #1;  check_output(normal_in);
    NbarT     = 1;                       #1;  check_output(bist_in);

    //--------------------------------------------------------------
    // 2) Edge values (all 0s / all 1s)
    //--------------------------------------------------------------
    normal_in = 8'h00; bist_in = 8'hFF; NbarT = 0; #1; check_output(8'h00);
    NbarT     = 1;                     #1; check_output(8'hFF);

    //--------------------------------------------------------------
    // 3) Random pattern trials
    //--------------------------------------------------------------
    repeat (10) begin
      void'(std::randomize(normal_in));
      void'(std::randomize(bist_in));
      void'(std::randomize(NbarT));
      #1;
      if (NbarT)
        check_output(bist_in);
      else
        check_output(normal_in);
    end

    $display("All multiplexer tests completed.");
    $finish;
  end
endmodule
