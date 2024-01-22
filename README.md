# Round Robin Arbiter

> SystemVerilog Round Robin arbiter  

## Get Started

The source files  are located at the repository root:

- [Round Robin arbiter module](./round_robin.sv)
- [Round Robin arbiter TB](./round_robin_TB.sv)

##
This repository containts a SystemVerilog implementation of a parametrized Round Robin arbiter with three instantiation options:
TYPE=0 : Conventional rotating scheme. Pointer is increased by one after each arbitration.
	![M_Fig_3](./docs/M_Fig_3.jpg) 

TYPE=1 : Modified rotating scheme. Pointer is updated according to the winning requester at the end of each arbitration.
	![M_Fig_3](./docs/M_Fig_3.jpg) 

TYPE=2 : Weighted rotating scheme. Winning requested is chosen based on both the instantaneous weights status and the pointer location.
	![M_Fig_3](./docs/M_Fig_3.jpg) 

## Testbench
### Conventional rotating scheme 
XXX

### Modified rotating scheme 
XXX

### Weighted rotating scheme
XXX

## Support

I will be happy to answer any questions.  
Approach me here using GitHub Issues or at tom.urkin@gmail.com