module cia_timer(
           input[15:0] latch_val,
           input enable,
           input clk,
           input latch,
           input reload,
           output underflow
       );

reg[15:0] cnt;

assign underflow = (cnt == 0);

always @(posedge clk ) begin
    if(enable & underflow) begin
        if( latch ) cnt = latch_val;
        if( underflow ) begin
            if(reload) begin
                cnt = latch_val;
            end
        end else cnt = cnt - 1;
    end
end

endmodule // ciainput a[4:0]
