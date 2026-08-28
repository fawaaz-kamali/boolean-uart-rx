`timescale 1ns / 1ps

/*
   @author:         Fawaaz Kamali Siddiqui
   @last_update:    22 August 2026
   @filename:       seven_segment_display.v
   @description:    Modular implementation of a 4-bit binary
                    to BCD converter. 
                    digit: number to be represented
                    anode: 7-segment display selector 
                    dp: decimal point value
*/

module seven_segment_display(
    input wire [3:0] digit, 
    input wire [3:0] anode,
    input wire dp, 
    output reg [7:0] display
    );
    
    // all LED values are active low
    always @(*) begin
        display[7] = dp; 
        case (digit) 
            4'b0000: display[6:0] = 7'b1000000; // 0
            4'b0001: display[6:0] = 7'b1111001; // 1
            4'b0010: display[6:0] = 7'b0100100; // 2
            4'b0011: display[6:0] = 7'b0110000; // 3
            4'b0100: display[6:0] = 7'b0011001; // 4
            4'b0101: display[6:0] = 7'b0010010; // 5
            4'b0110: display[6:0] = 7'b0000010; // 6
            4'b0111: display[6:0] = 7'b1111000; // 7
            4'b1000: display[6:0] = 7'b0000000; // 8 
            4'b1001: display[6:0] = 7'b0010000; // 9
            4'b1010: display[6:0] = 7'b0001000; // 10 (A)
            4'b1011: display[6:0] = 7'b0000011; // 11 (b)
            4'b1100: display[6:0] = 7'b1000110; // 12 (C)
            4'b1101: display[6:0] = 7'b0100001; // 13 (d)
            4'b1110: display[6:0] = 7'b0000110; // 14 (E)
            4'b1111: display[6:0] = 7'b0001110; // 15 (F)
            default: display[6:0] = 7'b1111111;
        endcase
    end
endmodule
