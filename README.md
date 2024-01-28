# Round Robin Arbiter

> SystemVerilog Round Robin arbiter  

## Get Started

The source files  are located at the repository root:

- [Round Robin arbiter module](./round_robin.sv)
- [Round Robin arbiter TB](./round_robin_TB.sv)

##
This repository containts a SystemVerilog implementation of a parametrized Round Robin arbiter with three instantiation options:

**TYPE=0 :** Conventional rotating scheme. Pointer is increased by one after each arbitration.

![simplified_block](./docs/simplified_block.jpg)

**TYPE=1 :** Modified rotating scheme. Pointer is updated according to the winning requester at the end of each arbitration.

![modified_block](./docs/modified_block.jpg) 

**TYPE=2 :** Weighted rotating scheme. Winning requested is chosen based on both the instantaneous weights status and the pointer location.

![weighted_block](./docs/weighted_block.jpg) 

## Testbench
In the following testbenches the following variables were randomized:
1. enable signal - Arbitration is carried only when the enable signal is logic high at the capturing clock edge (rising).
2. request vector - N-bit request vector is generated and routed to both the arbiter module as well as the verification logic.

### Conventional rotating scheme (N=8)

![simplified_sim](./docs/simplified_sim.jpg) 

As can be seen,	when the enable signal is logic high at the rising edge of the clock a new request vector is generated and arbitration is carried. Since this is a standard circular realization, the 'priority' vector (marked in red) changes in a circular manner. 

![simplified_sim_zoom](./docs/simplified_sim_zoom.jpg) 

**Examplary events marked on the zoom-in figure:**
1) Arbitration is not carrried since the enable signal is logic low
2) The enable signal is logic high, therefore arbitration is carried. The pointer's value is '4', however only req[1] is logic high and therefore the grant vector matched the request vector.
3) The enable signal is logic high, therefore arbitration is carried. The pointer's value is '5' but req[5] is logic low (i.e. the requester with the instantaneous priority does not request access to the shared resource) the access is given to the next in line which is requester '6'.
4) Arbitration is not carrried since the enable signal is logic low
5) The enable signal is logic high, therefore arbitration is carried. The pointer's value is '6' and req[6] is logic high, therefore the requester with the instanteous priority is given access to the shared resource.
6) Please note that the pointer value is updated to '0' for the  8-requesters scenario shown here. 

Please run the testbench and observe the teminal messages for in-depth understanding, for example:

![simplified_teminal](./docs/simplified_teminal.jpg) 


### Modified rotating scheme  (N=10)

![modified_sim](./docs/modified_sim.jpg) 

As can be seen,	when the enable signal is logic high at the rising edge of the clock a new request vector is generated and arbitration is carried. In this realization, the priority pointer is updated according to the arbitration outcome. Please see the block diagram above.

**Examplary events marked on the zoom-in figure:**
1) Arbitration is not carrried since the enable signal is logic low
2) The pointer's value is '0' and req[0] is logic high. Therefore, requester '0' is granted access and the pointer is updated to '1'
3) Arbitration is not carrried since the enable signal is logic low
4) The pointer's value is '3' but this requester does not request access. Therefore the next in line is granted, i.e. requester number '4'. The pointer is updated to '5', i.e. the winning requester incremented by 1.

Please run the testbench and observe the teminal messages for in-depth understanding using the log messages.

### Weighted rotating scheme (N=10)

![weighted_sim](./docs/weighted_sim.jpg) 

As can be seen,	when the enable signal is logic high at the rising edge of the clock a new request vector is generated and arbitration is carried. In this realization, the priority pointer is updated according to the arbitration outcome which considers both the pointer location and the weight vector status (please see the block diagram above). Marked on the timing diagram is a weight vector update event.

![weighted_sim_zoom](./docs/weighted_sim_zoom.jpg) 

For better understading two arbitration events are discussed here in detail.

**Case '1'** <br>
Request vector              : 1-1-0-1-0-1-1-0-1-0 <br>
Weight vector               : 2-4-3-5-4-0-6-2-5-7 <br>
Masked vector               : 2-4-0-5-0-0-6-0-5-0 <br>
Max                         : 6                   <br>
Internal request vector     : 0-0-0-0-0-0-1-0-0-0 <br>

The internal request vector is then processed by the same logic as in 'modified RR' case to produce the grant vector which is : 0-0-0-0-0-0-1-0-0-0.
After the arbitration event the weight status is updated and the winning requester weight is decreased (requester number 3) from 6-->5.

**Case '2'** <br>
Request vector              : 0-1-0-1-0-1-1-1-1-1 <br>
Weight vector               : 2-4-3-5-4-0-5-2-5-6 <br>
Masked vector               : 0-4-0-5-0-0-5-2-5-6 <br>
Max                         : 6                   <br>
Internal request vector     : 0-0-0-0-0-0-0-0-0-1 <br>

The internal request vector is then processed by the same logic as in 'modified RR' case to produce the grant vector which is : 0-0-0-0-0-0-1-0-0-0.<br>
After the arbitration event the weight status is updated and the winning requester weight is decreased (requester number 3) from 6-->5.

Please run the testbench and observe the teminal messages for in-depth understanding using the log messages.

## Support

I will be happy to answer any questions.
Approach me here using GitHub Issues or at tom.urkin@gmail.com