//Round Robin arbiter module
//TYPE==0 : Conventional RR arbitration : pointer is increased by one after each arbitration
//TYPE==1 : Modified RR arbitration     : pointer is updated according to the winning requester
//TYPE==2 : Weighted RR arbitration     :
module round_robin(i_clk,i_rstn,i_en,i_req,o_gnt);

//Parameters
parameter N=8;                                     //Number of requesters
parameter TYPE = 1;                                //Arbitration logic (see above description)
localparam M = $clog2(N);                          //log2 of N, required width of the pointer signal
//Inputs
input logic i_clk;                                 //RR arbiter clock
input logic i_rstn;                                //RR arbiter reset signal (active high)
input logic i_en;                                  //Arbitration takes place only when the enable signal is logic high (i.e. not carried every clock edge)
input logic [N-1:0] i_req;                         //Request vector

//Outputs
output logic [N-1:0] o_gnt;                        //Grant vector

//Internal signals
logic [M-1:0] ptr;                                 //Round Robitn arbitration pointer
logic [N-1:0] tmp_r, tmp_l, rotate_r;              //Temporary and internal signals used in the Rotate-Priority_Rotate scheme
logic [N-1:0] priority_out;                        //Priority logic result
logic [M-1:0] ptr_arb;                             //Holds the winning requester index (basically an encoding operation on o_gnt)

//HDL body
generate
if (TYPE==0) begin
//Rotate right
assign {tmp_r,rotate_r} = {2{i_req}}>>ptr;

//Priority encoder logic
assign priority_out = rotate_r&~(rotate_r-1);

//Rotate left
assign {o_gnt,tmp_l} = {2{priority_out}}<<ptr;

always @(posedge i_clk or negedge i_rstn)
  if (!i_rstn)
    ptr<='0;
  else if (i_en)
    ptr<=ptr+$bits(ptr)'(1);
end

else if (TYPE==1) begin
//Rotate right
assign {tmp_r,rotate_r} = {2{i_req}}>>ptr;

//Priority encoder logic
assign priority_out = rotate_r&~(rotate_r-1);

//Rotate left
assign {o_gnt,tmp_l} = {2{priority_out}}<<ptr;

//ptr_next calculation
always @(*)
for (int i=0; i<N; i++)
  if (o_gnt[i])
    ptr_arb=i;

always @(posedge i_clk or negedge i_rstn)
  if (!i_rstn)
    ptr<='0;
  else if (i_en)
    ptr<=ptr_arb+$bits(ptr)'(1);
end
endgenerate

endmodule