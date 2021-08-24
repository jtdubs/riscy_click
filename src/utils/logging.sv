`timescale 1ns / 1ps
`default_nettype none

package logging;

`ifdef ENABLE_LOGGING
`define log_display(A) \
    $fdisplay(log_fd, "%s", $sformatf A );

`define log_strobe(A) \
    $fstrobe(log_fd, "%s", $sformatf A );
`else
`define log_display(A) \
    ;
`define log_strobe(A) \
    ;
`endif

//
// Debug Logging
//

`ifdef ENABLE_LOGGING
integer log_fd=0;
`endif

function void start_logging;
    begin
`ifdef ENABLE_LOGGING
        if (log_fd == 0) begin
            log_fd = $fopen("log.json");
            if (log_fd <= 0) begin
                $display("ERROR: unable to open log.json");
                $finish;
            end
        end
`endif
    end
endfunction

function void stop_logging;
    begin
`ifdef ENABLE_LOGGING
        if (log_fd == 0) begin
            $fclose(log_fd);
            log_fd = 0;
        end
`endif
    end
endfunction

endpackage
