//Round Robin arbiter module

module round_robin(i_clk,i_rstn,i_en,i_req,o_gnt);

//Parameters
parameter N=8;  //Number of requesters
localparam M = $clog2(N);
//Inputs
input logic i_clk;
input logic i_rstn;
input logic i_en;
input logic [N-1:0] i_req;

//Outputs
output logic [N-1:0] o_gnt;

//Internal signals
logic [M-1:0] ptr;
logic [N-1:0] tmp_r, tmp_l, rotate_r;
logic [N-1:0] priority_out;

//HDL body

//Rotate right
assign {tmp_r,rotate_r} = {2{i_req}}>>ptr;

//Priority encoder logic
assign priority_out = rotate_r&~(rotate_r-1);

//Rotate left
assign {o_gnt,tmp_l} = {2{priority_out}}<<gnt;

always @(posedge i_clk of negedge i_rstn)
  if (!i_rstn)
    ptr<='0;
  else if (i_en)
    ptr<=ptr+$bits(ptr)'(1);


endmodule