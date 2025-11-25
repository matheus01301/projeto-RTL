library verilog;
use verilog.vl_types.all;
entity portao_vlg_check_tst is
    port(
        motor_close     : in     vl_logic;
        motor_open      : in     vl_logic;
        state_debug     : in     vl_logic_vector(2 downto 0);
        sampler_rx      : in     vl_logic
    );
end portao_vlg_check_tst;
