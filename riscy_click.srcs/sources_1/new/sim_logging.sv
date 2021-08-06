`timescale 1ns / 1ps
`default_nettype none

package logging;

//
// Debug Logging
//

integer log_fd=0;

function void start_logging;
    begin
        if (log_fd == 0) begin
            log_fd = $fopen("log.json");
            if (!log_fd) begin
                $display("ERROR: unable to open log.json");
                $finish;
            end
            $fdisplay(log_fd, "[");
        end
    end
endfunction
        
function void stop_logging;
    begin
        if (log_fd) begin
            $fdisplay(log_fd, "{}");
            $fdisplay(log_fd, "]");
            $fclose(log_fd);
            log_fd = 0;
        end
    end
endfunction

endpackage
