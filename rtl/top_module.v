`timescale 1ns / 1ps

/*
   @author:         Fawaaz Kamali Siddiqui
   @last_update:    28 August 2026
   @filename:       top_module.v
   @description:    Top module used to instantiate uart_rx
                    and seven_segment_display objects. 
                    Assigns the most-significant 4 bits of result
                    to display 1 and least-significant 4 bits
                    to display 2. Uses on-board LEDs 0-7 to 
                    output result. 
                    Implementation on AMD RealDigital Boolean 
                    Board, operating at a clock frequency 
                    of 100 MHz. 
*/


module top_module(
    input wire          rx, clk, 
    output wire [7:0]   result, display1, display2, 
    output wire [7:0]   anode,
    output wire         dp
    );
    
    assign dp = 1;
    assign anode = 8'b01110111;
    
    // instantiate uart_rx object
    uart_rx #(.CLOCK_FREQUENCY(100_000_000), .BAUD_RATE(9600)) 
        uart (.rx(rx), .clk(clk), .result(result));
       
    // instantiate displays 
    seven_segment_display disp1 (.digit(result[7:4]), .anode(anode[7:4]), .dp(dp), .display(display1));
    seven_segment_display disp2 (.digit(result[3:0]), .anode(anode[3:0]), .dp(dp), .display(display2));
endmodule
