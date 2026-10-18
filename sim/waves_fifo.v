module waves_fifo();
   initial begin
      $dumpfile("sim_build/fifo/sync_fifo.fst");
      $dumpvars(0, sync_fifo);
      for (int i = 0; i < 16; i = i + 1) $dumpvars(0, sync_fifo.mem[i]);
   end
endmodule