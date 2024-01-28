//Round Robin arbiter TB
module round_robin_TB();
//Parameters
parameter CLK_PERIOD = 20;                  //Clock period
parameter N = 10;                           //Number of requesters
parameter W = 3;                            //Width of weight counters. Each requester may be assigned up to 2**W 'priority tokens' ('0' is the lowest priority, 2**W-1 is the highest priority)
localparam M = $clog2(N);                   //log2 of N, required width of the pointer signal
parameter TYPE = 2;                         //Arbitration scheme select parameter (please see the arbiter module for more details)

//Internal signals
logic clk;                                  //RR arbiter clock
logic rstn;                                 //RR arbiter reset signal (active high)
logic en_rand;                              //Arbitration takes place only when the enable signal is logic high (i.e. not carried every clock edge)
logic load_weights;                         //Pulse shaped input signal. Weights vector is loaded when logic high (for WRR scheme).
logic [N-1:0] [W-1:0] weights;              //weights hold the instantaneous priority order. Each requester has an W-bit register assigned to it (for WRR scheme).
logic [N-1:0] req;                          //Request vector supplied to the RR arbiter module
logic [N-1:0] gnt;                          //Grant vector produced by the RR arbiter module

logic [M-1:0] ptr_ver;                      //Round Robin pointer calculated in the verification environment 
logic [M-1:0] ptr_tmp;                      //Temporary pointer used in the ptr_ver clculations
logic [N-1:0] gnt_ver;                      //Grant vector calculated in the verification environment for comparison purposes

logic [N-1:0] [W-1:0] weights_mim;          //Mimic priority order for verification
logic [N-1:0] [W-1:0] masked_mim;           //Mimic masked vector for verification
logic [W-1:0] max_mim;                      //Max value of the masked_mimic vector
logic [N-1:0] req_w_mim;                    //Internally generated request vector in the verification environment

integer SEED=18;                            //Used as the seed for the randomization tasks                    
//Round Robin arbiter intsntiation
round_robin #(.N(N), .W(W), .TYPE(TYPE)) rr_tst(
                   .i_clk(clk),
                   .i_rstn(rstn),
                   .i_en(en_rand),
                   .i_req(req),
				   .i_load(load_weights),
				   .i_weights(weights),
                   .o_gnt(gnt)
);

//Initial block
initial begin
//Initializations
clk=1'b0;
rstn=1'b0;
ptr_ver='0;
gnt_ver='0;
en_rand=1'b0;

load_weights=1'b0;
weights_mim='0;

//Exit from reset mode
@(posedge clk)
  rstn=1'b1;


//------Conventional RR arbitration---//
if (TYPE==0) begin
$display("Initiate test - conventional Round Robin arbiter \n");

for(int k=0; k<50; k++) begin

  if (en_rand==1'b1) begin
    req= $dist_uniform(SEED,0,2**N-1);                                                                 //Randomize the N-bit long requesting vector
    $display("Randomized request vector is %b", req);
  
	@(posedge clk)

    gnt_ver='0;
    ptr_tmp=ptr_ver;
	
    //Calculating the grant vector for comparison with the round_robin module 'gnt' signal	
    if (req[ptr_ver]==1'b1)
      gnt_ver[ptr_ver]=1'b1;
    else begin
      for (int i=ptr_ver-1; i>=0; i--)
	    if (req[i]==1'b1)
	      ptr_tmp=i;  
  
      for (int i=N-1; i>ptr_ver; i--)
	    if (req[i]==1'b1)
	      ptr_tmp=i;
		
	  gnt_ver[ptr_tmp] = req[ptr_tmp];		
    end

    if (ptr_ver==N-1)
	  ptr_ver='0;
	else
      ptr_ver=ptr_ver+$bits(ptr_ver)'(1);                                                              //In conventional RR the pointer is increased by one in a cyclic manner regardless of the arbitration result
    
	en_rand= $dist_uniform(SEED,0,1);
	
    @(negedge clk)
    if (gnt==gnt_ver)                                                                                  //Comparing the two grant vectors
      $display("Grant vector is %b. Verification grant vector is %b. SUCCESS!\n", gnt, gnt_ver);
    else begin
      $display("Grant vector is %b. Verification grant vector is %b. FAILURE!\n", gnt, gnt_ver);
	  $finish;
    end

  end
  else  begin                                                                                          //Do not execute arbitration if the enable signal is logic low
	@(posedge clk);
    en_rand= $dist_uniform(SEED,0,1);	
  end
end
 en_rand=1'b0;
 $display("End of conventional Round Robin Arbiter verification - SUCCESS");
 end
 
//------Modified RR arbitration-------//
if (TYPE==1) begin
$display("Initiate test - modified Round Robin arbiter \n");

for(int k=0; k<400; k++) begin  

  if (en_rand==1'b1) begin
    req=$dist_uniform(SEED,0,2**N-1);                                                                  //Randomize the N-bit long requesting vector
    $display("Randomized request vector is %b", en_rand);

	@(posedge clk);	

    gnt_ver='0;
    ptr_tmp=ptr_ver;
  
    //Calculating the grant vector for comparison with the round_robin module 'gnt' signal
    if (req[ptr_ver]==1'b1)
      gnt_ver[ptr_ver]=1'b1;
    else begin
      for (int i=ptr_ver-1; i>=0; i--)
	    if (req[i]==1'b1)
	      ptr_tmp=i;  
  
      for (int i=N-1; i>ptr_ver; i--)
	    if (req[i]==1'b1)
	      ptr_tmp=i;
		
	  gnt_ver[ptr_tmp] = req[ptr_tmp];	
    end
    
    for (int i=0; i<N; i++)
	  if (gnt_ver[i])
	    ptr_ver=i;	

    if (ptr_ver==N-1)
	  ptr_ver='0;
	else
      ptr_ver=ptr_ver+$bits(ptr_ver)'(1);                                                              //In the modified RR the pointer is a function of the winning requester

	en_rand= $dist_uniform(SEED,0,1);
    	
	@(negedge clk)
    if (gnt==gnt_ver)                                                                                  //Comparing the two grant vectors
      $display("Grant vector is %b. Verification grant vector is %b. SUCCESS!\n", gnt, gnt_ver);
    else begin
      $display("Grant vector is %b. Verification grant vector is %b. FAILURE!\n", gnt, gnt_ver);
	  $finish;
    end

	//en_rand= $dist_uniform(SEED,0,1);
  end
  else begin                                                                                           //Do not execute arbitration if the enable signal is logic low
	@(posedge clk);
    en_rand=$dist_uniform(SEED,0,1);
  end
end
 
en_rand=1'b0;
$display("End of modified Round Robin Arbiter verification - SUCCESS");
end

//------Weighted RR arbitration-------//
if (TYPE==2) begin
$display("Initiate test - weighted Round Robin arbiter \n");

for (int k=0; k<100; k++) begin	 

    if ($dist_uniform(SEED,0,6)==2) begin                                                              //Loading new weight status. Modify the distribution to change the update frequency.
	  for (int i=0; i<N; i++)                                                                          //Randomize weight vectors. Weight values span from 0 (lowest priority) to 2**W-1 (highest priority)
        weights[i]=$dist_uniform(SEED,0,2**W-1);
	  load_weights=1'b1;                                                                               //Generating a pulse shaped load signal.
    end
	else if (load_weights==1'b1)
	  load_weights=1'b0;
	
    if (en_rand==1'b1) begin
      req=$dist_uniform(SEED,0,2**N-1);                                                                //Randomize the N-bit long requesting vector
      $display("Randomized request vector is %b", req);
     
	  @(posedge clk)
	  
      //Calculating the grant vector for comparison with the round_robin module 'gnt' signal
	  gnt_ver='0;
      ptr_tmp=ptr_ver;
	  
	  //Masking
      for (int i=0; i<N; i++)
        if (req[i]==1'b1)
	      masked_mim[i]=weights_mim[i];
	    else
          masked_mim[i]='0;	

      //Weighted request logic and Internal request vector generation
      max_mim=0;
      for (int i=0; i<N; i++)
        if (masked_mim[i]>max_mim)
	      max_mim=masked_mim[i];

      req_w_mim='0;
      for (int i=0; i<N; i++)
        if ((masked_mim[i]==max_mim)&&(req[i]==1'b1))
	      req_w_mim[i]=1'b1;
	    else 
	      req_w_mim[i]=1'b0;
	   
      if (req_w_mim[ptr_ver]==1'b1)
        gnt_ver[ptr_ver]=1'b1;
      else begin
        for (int i=ptr_ver-1; i>=0; i--)
	      if (req_w_mim[i]==1'b1)
	        ptr_tmp=i;  
  
      for (int i=N-1; i>ptr_ver; i--)
	    if (req_w_mim[i]==1'b1)
	      ptr_tmp=i;
		
	  gnt_ver[ptr_tmp] = 1'b1;		
      end	

      if (ptr_tmp==N-1)
	    ptr_ver='0;
	  else
        ptr_ver=ptr_tmp+$bits(ptr_tmp)'(1);
	   
	  if (load_weights==1'b1)
	    weights_mim=weights;
      else if ((en_rand==1'b1)&&(|gnt_ver)&&(weights_mim[ptr_tmp]>0))	
	    weights_mim[ptr_tmp]=weights_mim[ptr_tmp]-1;
	 
	  en_rand= $dist_uniform(SEED,0,1);	  	  

	  //Compare to verification 	
	  @(negedge clk) 
      if (gnt==gnt_ver)                                                                                  //Comparing the two grant vectors
        $display("Grant vector is %b. Verification grant vector is %b. SUCCESS!\n", gnt, gnt_ver);
      else begin
        $display("Grant vector is %b. Verification grant vector is %b. FAILURE at time %t!\n", gnt, gnt_ver, $realtime);
	    $finish;
      end	 
    end
    else begin                                                                                         //Do not execute arbitration if the enable signal is logic low
	  @(posedge clk);
	  if (load_weights==1'b1)
	    weights_mim=weights;
	  en_rand= $dist_uniform(SEED,0,1);	  	  
    end
  
end
 
en_rand=1'b0;
$display("End of weighted Round Robin Arbiter verification - SUCCESS");
end

end                                                                                                    //End of initial block

//Clock generation
always
begin
#(CLK_PERIOD/2);
clk=~clk;
end


endmodule
