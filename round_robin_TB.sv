//Round Robin arbiter TB
module round_robin_TB();
//Parameters
parameter CLK_PERIOD = 20;
parameter N = 8;

//Internal signals
logic clk;
logic rstn;
logic [N-1:0] req;
logic [N-1:0] gnt;

integer SEED = 0;

//Round Robin arbiter intsntiation
round_robin #(.N(N)) rr_tst(
                   .i_clk(clk),
                   .i_rstn(rstn),
                   .i_en(1'b1),
                   .i_req(req),
                   .o_gnt(gnt)
);

//Initial block
initial begin
clk=1'b0;
rstn=1'b0;

@(posedge clk)
  rstn=1'b1;


$display("Initiate test\n");

for(int k=0; k<10; k++) begin
  req= $dist_uniform(SEED,0,40);
  $display("req vector is %b", req);
  @(posedge clk)
  $display ("Grant vector is %b", gnt);
 end

end

//TB HDL code

//Clock generation
always
begin
#(CLK_PERIOD/2);
clk=~clk;
end

endmodule
