module bist#(
  parameter size   = 6,  // address width
  parameter length = 8   // data width
)(
  input  logic                start,    // switch into BIST mode
  input  logic                rst,      // reset FSM/counter
  input  logic                clk,      // system clock
  // Normal mode interface
  input  logic                csin,     // chip select normal
  input  logic                rwbarin,  // read/write normal (0=write)
  input  logic                opr,      // enable fail check
  input  logic [size-1:0]     address,  // normal address
  input  logic [length-1:0]   datain,   // normal data input
  // Shared outputs
  output logic [length-1:0]   dataout,  // memory output
  output logic                fail      // BIST fail indicator
);

  //============================================================
  // Internal signals
  //============================================================
  logic NbarT, ld;                       // from controller (Moore)
  logic [length-1:0] cnt_q;              // BIST counter output
  logic [size-1:0]   cnt_addr;           // truncated address for BIST
  logic [length-1:0]  mux_data;          // selected write data
  logic [size-1:0]    mux_addr;          // selected address
  logic                rw_int;           // internal rwbar for SRAM
  logic                cs_int;           // internal cs for SRAM
  logic [length-1:0]   ramout;           // SRAM output
  logic                eq, gt, lt;       // comparator outputs
  logic                temp_rw;          // selected rw for fail logic

  //============================================================
  // Submodule: Controller (Moore)
  //============================================================
  controller u_ctrl (
    .start  (start),
    .rst    (rst),
    .clk    (clk),
    .cout   (cnt_q[6]),       // we use counter bit 6 as BIST webar
    .NbarT  (NbarT),
    .ld     (ld)
  );

  //============================================================
  // Submodule: Counter (address/data generator)
  //============================================================
  counter #(.LENGTH(length)) u_cnt (
    .d_in   ({length{1'b0}}), // d_in unused if ld pulses register
    .clk    (clk),
    .ld     (ld),
    .u_d    (1'b1),            // count up
    .cen    (NbarT),           // enable only in test
    .q      (cnt_q),
    .cout   ()
  );
  assign cnt_addr = cnt_q[size-1:0];

  //============================================================
  // Address and Data Mux
  //============================================================
  multiplexer #(.WIDTH(size)) u_mux_addr (
    .normal_in (address),
    .bist_in   (cnt_addr),
    .NbarT     (NbarT),
    .out       (mux_addr)
  );
  multiplexer #(.WIDTH(length)) u_mux_data (
    .normal_in (datain),
    .bist_in   (cnt_q),
    .NbarT     (NbarT),
    .out       (mux_data)
  );

  //============================================================
  // Internal SRAM signals
  //============================================================
  assign rw_int = NbarT ? cnt_q[6] : rwbarin;
  assign cs_int = NbarT ? 1'b1       : csin;

  //============================================================
  // Submodule: SRAM (single-port)
  //============================================================
  sram u_sram (
    .clk     (clk),
    .cs      (cs_int),
    .rwbar   (rw_int),
    .ramaddr (mux_addr),
    .ramin   (mux_data),
    .ramout  (ramout)
  );

  //============================================================
  // Submodule: Comparator
  //============================================================
  comparator #(.WIDTH(length)) u_cmp (
    .data_t  (cnt_q),         // expected data from counter
    .ramout  (ramout),
    .gt      (gt),
    .eq      (eq),
    .lt      (lt)
  );

  //============================================================
  // BIST fail logic
  //============================================================
  // Select the active read enable (rwbar=1) signal
  assign temp_rw = NbarT ? cnt_q[6] : rwbarin;

  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      fail <= 1'b0;
    else begin
      if (NbarT && opr && temp_rw && ~eq)
        fail <= 1'b1;
      else
        fail <= 1'b0;
    end
  end

  //============================================================
  // Continuous output
  //============================================================
  assign dataout = ramout;

endmodule
