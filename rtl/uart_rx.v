`timescale 1ns / 1ps

/*
   @author:         Fawaaz Kamali Siddiqui
   @last_update:    28 August 2026
   @filename:       uart_rx.v
   @description:    Module used to establish UART reception 
                    on FPGA (8-N-2). Designed using 4 states: 
                    IDLE, START, GET_BIT, and STOP. 
                    -------
                    IDLE: Detect falling edge on rx line
                    START: Wait half a period (clock freq / baud rate)
                    GET_BIT: Store UART bits internally for 8 cycles
                    STOP: Wait 2 periods, and pulse the ack signal. 
                        Reset all internal counters and indices.
*/
module uart_rx
    #(parameter CLOCK_FREQUENCY = 100_000_000, 
      parameter BAUD_RATE = 9600)
    (
    input   wire         clk, rx,
    output  reg [7:0]    result, 
    output  reg          ack
    );
    
    // internal registers
    reg [1:0] sampled_rx;
    reg [1:0] current_state;
    reg [13:0] counter;
    reg [3:0] index;
    reg [7:0] temp_result;
    
    localparam PERIOD = CLOCK_FREQUENCY / BAUD_RATE; // 10,416.67 clocks / UART bit
    localparam IDLE = 2'b00; 
    localparam START = 2'b01;
    localparam GET_BIT = 2'b10;
    localparam STOP = 2'b11;
    
    // initialize values 
    initial begin
        sampled_rx = 0;
        current_state = IDLE;
        counter = 0;
        index = 0;
        temp_result = 0;
        result = 0;
        ack = 0;
    end
    
    always @(posedge clk) begin
        ack <= 0;
        case (current_state) 
            
            // State 1: Detect falling edge to move to next state
            IDLE: begin
                sampled_rx[0] <= sampled_rx[1];
                sampled_rx[1] <= rx;
                if (sampled_rx == 2'b01) begin
                    current_state <= START;
                end
                else current_state <= IDLE;
            end
            
            // State 2: Wait PERIOD / 2 cycles and transition to next state
            START: begin
                counter <= counter + 1'b1;
                if (counter == PERIOD / 2) begin
                    counter <= 0;
                    current_state <= GET_BIT;
                end
                else current_state <= START;
            end
            
            // State 3: Wait PERIOD, sample input bit and repeat until 
            //          index is 7, and transition to next state
            GET_BIT: begin
                counter <= counter + 1'b1;
                if (counter == PERIOD) begin
                    temp_result[index] <= rx;
                    counter <= 0;
                    if (index < 7) begin
                        index <= index + 1'b1;
                        current_state <= GET_BIT;
                    end
                    else begin
                        result <= {rx, temp_result[6:0]};
                        index <= 0;
                        current_state <= STOP;
                    end
                end
                else current_state <= GET_BIT;
            end
            
            // STATE 4: Wait for 2 PERIOD and transition to IDLE state
            STOP: begin
                counter <= counter + 1'b1;
                if (counter == PERIOD) begin
                    if (index != 1) begin
                        counter <= 0;
                        index <= index + 1'b1;
                        current_state <= STOP;
                    end
                    else begin 
                        // assert done signal for brief time
                        ack <= 1;
                        counter <= 0;
                        index <= 0;
                        current_state <= IDLE;
                        temp_result <= 0;
                    end
                end
                else current_state <= STOP;
            end
        endcase
        
    
    end
    
endmodule
