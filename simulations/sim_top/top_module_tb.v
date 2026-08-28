`timescale 1ns / 1ps

module top_module_tb();
    
    localparam CLK_FREQUENCY = 100_000_000;
    localparam BAUD_RATE = 9600;
    localparam CLK_PERIOD_NS = 10; 
    localparam BIT_PERIOD_CLKS = CLK_FREQUENCY / BAUD_RATE;
    localparam BIT_PERIOD_NS = BIT_PERIOD_CLKS * CLK_PERIOD_NS;
    localparam TEST_CASES = 10;

    reg         rx, clk;
    wire [7:0]  result, display1, display2;
    
    reg [7:0] test_cases [0:TEST_CASES-1];
    
    top_module dut (.rx(rx), .clk(clk), 
                    .result(result), .display1(display1), .display2(display2)
                    );
                    
    initial begin 
        rx <= 1;
        clk <= 0;
        
        test_cases[0] = 8'hea;
        test_cases[1] = 8'h00;
        test_cases[2] = 8'hff;
        test_cases[3] = 8'h2b;
        test_cases[4] = 8'h09;
        test_cases[5] = 8'h5d;
        test_cases[6] = 8'h66;
        test_cases[7] = 8'h8a;
        test_cases[8] = 8'h90;
        test_cases[9] = 8'h71;  

    end 
    
    task send_byte (input [7:0] data);
        begin 
            rx <= 0; // start bit
            #(BIT_PERIOD_NS);
            for (integer i = 0; i < 8; i = i + 1) begin
                rx <= data[i];     
                #(BIT_PERIOD_NS);
            end
            rx <= 1; // stop bits
            #(BIT_PERIOD_NS);
            #(BIT_PERIOD_NS);
        end
    endtask 
    
    // watchdog timer
    initial begin 
        #(BIT_PERIOD_NS * 15 * TEST_CASES);
        $display("SIMULATION ERROR: UUT likely stuck.");
        $finish;
    end 
    
    always begin 
        // 100 MHz = 10 ns per cycle
        #(CLK_PERIOD_NS/2) clk <= ~clk;
    end
    
    // main test
    initial begin 
        #(BIT_PERIOD_NS); // initial value of rx to 1
        for (integer i = 0; i < TEST_CASES; i = i + 1) begin 
            send_byte(test_cases[i]);
            $display("Sent 0x%0h | Received 0x%0h | Display 1: 0x%0h, Display 2: 0x%0h | Time %0t", 
                test_cases[i], result, display1, display2, $time);
        end 
        $display("SIMULATION COMPLETE.");
        $finish;
    end 

endmodule
