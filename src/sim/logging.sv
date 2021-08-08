`timescale 1ns / 1ps
`default_nettype none

package logging;

//
// Debug Logging
//

integer log_fd=0;

function void start_logging;
    begin
`ifdef VERILATOR
        if (log_fd == 0) begin
            log_fd = 1;
            $display("[");
        end
`else
        if (log_fd == 0) begin
            log_fd = $fopen("log.json");
            if (!log_fd) begin
                $display("ERROR: unable to open log.json");
                $finish;
            end
            $display("[");
        end
`endif
    end
endfunction

function void stop_logging;
    begin
        if (log_fd) begin
`ifdef VERILATOR
            $display("{}");
            $display("]");
`else
            $fdisplay(log_fd, "{}");
            $fdisplay(log_fd, "]");
            $fclose(log_fd);
`endif
            log_fd = 0;
        end
    end
endfunction

endpackage
