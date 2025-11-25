library verilog;
use verilog.vl_types.all;
entity portao_vlg_sample_tst is
    port(
        bot             : in     vl_logic;
        clk             : in     vl_logic;
        end_close       : in     vl_logic;
        end_open        : in     vl_logic;
        obst            : in     vl_logic;
        rst_n           : in     vl_logic;
        sampler_tx      : out    vl_logic
    );
end portao_vlg_sample_tst;
