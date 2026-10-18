module waves_debounce();
   initial begin
      $dumpfile("sim_build/debounce/debounce_edge_detect.fst");
      $dumpvars(0, debounce_edge_detect);
   end
endmodule