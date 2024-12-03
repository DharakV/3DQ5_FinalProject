library verilog;
use verilog.vl_types.all;
entity milestone2 is
    port(
        CLOCK_50_I      : in     vl_logic;
        Resetn          : in     vl_logic;
        m2_start        : in     vl_logic;
        SRAM_read_data  : in     vl_logic_vector(15 downto 0);
        SRAM_write_data : out    vl_logic_vector(15 downto 0);
        SRAM_address    : out    vl_logic_vector(17 downto 0);
        write_en_n      : out    vl_logic;
        m2_finish       : out    vl_logic
    );
end milestone2;
