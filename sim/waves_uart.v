module waves_uart();
   initial begin
      $dumpfile("sim_build/uart/uart_tx.fst");
      $dumpvars(0, uart_tx);
   end
endmodule