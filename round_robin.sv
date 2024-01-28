//Round Robin arbiter module
//TYPE==0 : Conventional RR arbitration : pointer is increased by one after each arbitration
//TYPE==1 : Modified RR arbitration     : pointer is updated according to the winning requester
//TYPE==2 : Weighted RR arbitration     : arbitration is carried with respect to the instantaneous weight vectors. Pointer update scheme follows modified Round Robin arbitration logic. 
module round_robin(i_clk,i_rstn,i_en,i_req,i_load,i_weights,o_gnt);

//Parameters
parameter N=8;                                     //Number of requesters
parameter TYPE = 1;                                //Arbitration logic (see above description)
parameter W =3;                                    //Width of weight counters. Each requester may be assigned up to 2**W 'priority tokens' ('0' is the lowest priority, 2**W-1 is the highest priority)
localparam M = $clog2(N);                          //log2 of N, required width of the pointer signal
//Inputs
input logic i_clk;                                 //RR arbiter clock
input logic i_rstn;                                //RR arbiter reset signal (active high)
input logic i_en;                                  //Arbitration takes place only when the enable signal is logic high (i.e. not carried every clock edge)
input logic [N-1:0] i_req;                         //Request vector
input logic i_load;                                //Pulse shaped input signal. Weights vector is loaded when logic high.
input logic [N-1:0] [W-1:0] i_weights;             //Internal registers holding the instantaneous priority order. Each requester has an W-bit register assigned to it.

//Outputs
output logic [N-1:0] o_gnt;                        //Output grant vector

//Internal signals
logic [M-1:0] ptr;                                 //Round Robitn arbitration pointer
logic [N-1:0] tmp_r, tmp_l, rotate_r;              //Temporary and internal signals used in the Rotate-Priority_Rotate scheme
logic [N-1:0] priority_out;                        //Priority logic result
logic [M-1:0] ptr_arb;                             //Holds the winning requester index (basically an encoding operation on gnt)
logic [N-1:0] gnt;                                 //Combinatorial calculation of the grant vector (continious)


logic [N-1:0] [W-1:0] weight_counters;             //Each requester is assigned a counter that holds its 'priority tokens'
logic [N-1:0] [W-1:0] masked;                      //Holds the 'priority tokens' values for each requesting requester
logic [N-1:0] req_w;                               //An internal request vector obtained by considerign both the priority status and the input request signal
logic [W-1:0] max;                                 //Holds the maximal weight between all requesting requesters. 

//HDL body
generate
if (TYPE==0) begin                                 //Simplified rotating scheme
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

else if (TYPE==1) begin                            //Modified rotating scheme
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
  else if (i_en) begin
    if (ptr_arb==N-1)
	  ptr<='0;
	else
      ptr<=ptr_arb+$bits(ptr)'(1);
	o_gnt<=gnt;
  end
end

else if (TYPE==2) begin                            //Weighted scheme
//Masking
always @(*) begin
  for (int i=0; i<N; i++)
    if (i_req[i]==1'b1)
	  masked[i]=weight_counters[i];
	else
      masked[i]='0;	
end

//Weighted request logic and Internal request vector generation
always @(*) begin
  max=0;
  for (int i=0; i<N; i++)
    if (masked[i]>max)
	  max=masked[i];
end

always @(*) begin
  req_w='0;
  for (int i=0; i<N; i++)
    if ((masked[i]==max)&&(i_req[i]==1'b1))
	  req_w[i]=1'b1;
	else 
	  req_w[i]=1'b0;
end

//Rotate right
assign {tmp_r,rotate_r} = {2{req_w}}>>ptr;

//Priority logic
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
	weight_counters<='0;
  end
  else begin  
    if (i_load)                                                   //load has priority
      weight_counters<=i_weights;
    else if ((i_en)&&(gnt!=0)&&(weight_counters[ptr_arb]>0))      //update winning counter only if arbitration has occured and the counter is not 0 (lowest value)	  
      weight_counters[ptr_arb]<=weight_counters[ptr_arb]-1;
  
    if (i_en) begin
      if (ptr_arb==N-1)
	    ptr<='0;
	  else
        ptr<=ptr_arb+$bits(ptr_arb)'(1);
	  o_gnt<=gnt;
    end 
  end 
  
end

endgenerate

endmodule