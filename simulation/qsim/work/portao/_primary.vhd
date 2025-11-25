library verilog;
use verilog.vl_types.all;
entity portao is
    port(
        clk             : in     vl_logic;
        rst_n           : in     vl_logic;
        bot             : in     vl_logic;
        end_open        : in     vl_logic;
        end_close       : in     vl_logic;
        obst            : in     vl_logic;
        stop            : in     vl_logic;
        motor_open      : out    vl_logic;
        motor_close     : out    vl_logic;
        state_debug     : out    vl_logic_vector(2 downto 0)
    );
end portao;
