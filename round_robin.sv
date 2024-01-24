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
output logic [N-1:0] o_gnt;                        //Output grant vector

//Internal signals
logic [M-1:0] ptr;                                 //Round Robitn arbitration pointer
logic [N-1:0] tmp_r, tmp_l, rotate_r;              //Temporary and internal signals used in the Rotate-Priority_Rotate scheme
logic [N-1:0] priority_out;                        //Priority logic result
logic [M-1:0] ptr_arb;                             //Holds the winning requester index (basically an encoding operation on gnt)
logic [N-1:0] gnt;                                 //Combinatorial calculation of the grant vector (continious)

//HDL body
generate
if (TYPE==0) begin
//Rotate right
assign {tmp_r,rotate_r} = {2{i_req}}>>ptr;

//Priority encoder logic
assign priority_out = rotate_r&~(rotate_r-1);

//Rotate left
assign {gnt,tmp_l} = {2{priority_out}}<<ptr;

always @(posedge i_clk or negedge i_rstn)
  if (!i_rstn) begin
    ptr<='0;
	o_gnt<='0;                        
	end
  else if (i_en) begin
    if (ptr==N-1)
	  ptr<='0;
	else
    ptr<=ptr+$bits(ptr)'(1);
	
	o_gnt<=gnt;
  end
end

else if (TYPE==1) begin
//Rotate right
assign {tmp_r,rotate_r} = {2{i_req}}>>ptr;

//Priority encoder logic
assign priority_out = rotate_r&~(rotate_r-1);

//Rotate left
assign {gnt,tmp_l} = {2{priority_out}}<<ptr;

//ptr_next calculation
always @(*) begin
  ptr_arb=ptr;
  for (int i=0; i<N; i++)
    if (gnt[i])
      ptr_arb=i;
end

always @(posedge i_clk or negedge i_rstn)
  if (!i_rstn) begin
    ptr<='0;
	o_gnt<='0;
  end
  else if (i_en) begin     //Pointer cannot exceed the number of requesters !!! if N=10 it should go from 9 to 0!!! XXXX rewrite
    if (ptr_arb==N-1)
	  ptr<='0;
	else
      ptr<=ptr_arb+$bits(ptr)'(1);
	o_gnt<=gnt;
  end
end
endgenerate

endmodule