//Round Robin arbiter TB
module round_robin_TB();
//Parameters
parameter CLK_PERIOD = 20;                  //Clock period
parameter N = 10;                            //Number of requesters
localparam M = $clog2(N);                   //log2 of N, required width of the pointer signal


parameter TYPE = 1;
//Internal signals
logic clk;                                  //RR arbiter clock
logic rstn;                                 //RR arbiter reset signal (active high)
logic en_rand;                              //Arbitration takes place only when the enable signal is logic high (i.e. not carried every clock edge)
logic [N-1:0] req;                          //Request vector supplied to the RR arbiter module
logic [N-1:0] gnt;                          //Grant vector produced by the RR arbiter module

logic [M-1:0] ptr_ver;                      //Round Robin pointer calculated in the verification environment 
logic [M-1:0] ptr_tmp;                      //Temporary pointer used in the ptr_ver clculations
logic [N-1:0] gnt_ver;                      //Grant vector calculated in the verification environment for comparison purposes

integer SEED=18;                            //Used as the seed for the randomization tasks                    

//Round Robin arbiter intsntiation
round_robin #(.N(N), .TYPE(TYPE)) rr_tst(
                   .i_clk(clk),
                   .i_rstn(rstn),
                   .i_en(en_rand),
                   .i_req(req),
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

//Exit from reset mode
@(posedge clk)
  rstn=1'b1;
  
//--------------//
if (TYPE==0) begin
$display("Initiate test - conventional Round Robin arbiter \n");
for(int k=0; k<50; k++) begin
  if (en_rand==1'b1) begin
    req= $dist_uniform(SEED,0,2**N-1);                                     //Randomize the N-bit long requesting vector
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
      ptr_ver=ptr_ver+$bits(ptr_ver)'(1);                                                                 //In conventional RR the pointer is increased by one in a cyclic manner regardless of the arbitration result
    
	en_rand= $dist_uniform(SEED,0,1);
	
    #1       //Required to allow... XXX
    if (gnt==gnt_ver)                                                                                  //Comparing the two grant vectors
      $display("Grant vector is %b. Verification grant vector is %b. SUCCESS!\n", gnt, gnt_ver);
    else begin
      $display("Grant vector is %b. Verification grant vector is %b. FAILURE!\n", gnt, gnt_ver);
	  $finish;
    end

  end
  else  begin                                                                                                //Do not execute arbitration if the enable signal is logic low
	@(posedge clk);
    en_rand= $dist_uniform(SEED,0,1);	
  end
end
 en_rand=1'b0;
 $display("End of conventional Round Robin Arbiter verification - SUCCESS");
 end
//--------------//
if (TYPE==1) begin
$display("Initiate test - modified Round Robin arbiter \n");
for(int k=0; k<400; k++) begin  
  if (en_rand==1'b1) begin
    req=$dist_uniform(SEED,0,2**N-1);                                     //Randomize the N-bit long requesting vector
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
    
    for (int i=0; i<N; i++)
	  if (gnt_ver[i])
	    ptr_ver=i;	

    if (ptr_ver==N-1)
	  ptr_ver='0;
	else
      ptr_ver=ptr_ver+$bits(ptr_ver)'(1);                                                                 //In the modified RR the pointer is a function of the winning requester

	en_rand= $dist_uniform(SEED,0,1);
    
	#1   //Requierd since.... XXXX
    if (gnt==gnt_ver)                                                                                  //Comparing the two grant vectors
      $display("Grant vector is %b. Verification grant vector is %b. SUCCESS!\n", gnt, gnt_ver);
    else begin
      $display("Grant vector is %b. Verification grant vector is %b. FAILURE!\n", gnt, gnt_ver);
	  $finish;
    end
  end
  else begin                                                                                              //Do not execute arbitration if the enable signal is logic low
	@(posedge clk);
    en_rand=$dist_uniform(SEED,0,1);
  end
end
 
en_rand=1'b0;
$display("End of modified Round Robin Arbiter verification - SUCCESS");
end

end

//Clock generation
always
begin
#(CLK_PERIOD/2);
clk=~clk;
end

endmodule
