`timescale 1ns / 1ps

module uart_rx_tb();

    localparam CLK_FREQUENCY = 100_000_000;
    localparam BAUD_RATE = 9600;
    localparam CLK_PERIOD_NS = 10; 
    localparam BIT_PERIOD_CLKS = CLK_FREQUENCY / BAUD_RATE;
    localparam BIT_PERIOD_NS = BIT_PERIOD_CLKS * CLK_PERIOD_NS;
    localparam TEST_CASES = 10;

    reg         clk, rx;
    wire [7:0]  result;
    wire        ack;
    integer     tests, errors, file_handle;
    
    reg [7:0] test_cases [0:TEST_CASES-1];
    
    uart_rx #(.CLOCK_FREQUENCY(CLK_FREQUENCY), .BAUD_RATE(BAUD_RATE))
        uut (.clk(clk), .rx(rx), .result(result), .ack(ack));
    
    initial begin 
        clk <= 0;
        rx <= 1;
        tests = 0;
        errors = 0;
        
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
        
        file_handle = $fopen("simulation_log.txt", "w");

        // Ensure file opened successfully
        if (file_handle == 0) begin
            $display("ERROR: Could not open file for writing!");
            $finish;
        end

        // Write file header
        $fdisplay(file_handle, "--- SIMULATION LOG START ---");
        $fdisplay(file_handle, "Time(ns) | RX Signal | Result (Hex) | ACK");
        $fdisplay(file_handle, "------------------------------------------");
    end
    
    always begin 
        // 100 MHz = 10 ns per cycle
        #(CLK_PERIOD_NS/2) clk <= ~clk;
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
    
    task validate(input [7:0] expected);
        begin
            @(posedge ack);              // blocks here until uut pulses ack signal
            tests = tests + 1;
            if (result == expected) begin
                $display("PASS: Received 0x%0h at time %0t", result, $time);
            end
            else begin
                $display("FAIL: Expected 0x%0h, but received 0x%0h at time %0t",
                            expected, result, $time);
                errors = errors + 1;
            end
            $fdisplay(file_handle, "%0t \t | %b         | 0x%0h       | %b", $time, expected, result, ack);
        end
    endtask
    
    task check_byte(input [7:0] expected);
        begin
            fork
                send_byte(expected);
                validate(expected);
            join
            @(posedge clk);
        end
    endtask
    
    initial begin 
//        // 1 UART bit is transmitted in 10,416.67 clock cycles 
        
        #(BIT_PERIOD_NS); // initial value of rx to 1
        
        for (integer i = 0; i < TEST_CASES; i = i + 1) begin 
            check_byte(test_cases[i]);
        end 
        
        $display("---------- %0d/%0d TESTS PASSED  ----------", tests - errors, tests);
        if (errors == 0) begin
            $display("ALL TESTS PASSED.");
        end
        else $display ("%0d TESTS FAILED.", errors);
        
        $fdisplay(file_handle, "--- SIMULATION COMPLETE ---");
        $fclose(file_handle);
        $finish;
    end 
    
    // Watchdog
    initial begin
        #(BIT_PERIOD_NS * 15 * TEST_CASES);
        $display("SIMULATION ERROR: UUT likely stuck.");
        $fclose(file_handle);
        $finish;
    end

endmodule
