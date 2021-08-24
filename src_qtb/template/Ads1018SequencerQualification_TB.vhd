---------------------------------------------------------------------------------------
--! @file	Ads1018SequencerQualification_TB.vhd 
--! @brief	Testbench for the module Ads1018Sequencer.vhd.
   	    
--! @copyright 2020 Avionik Straubing Entwicklungs GmbH
--! @version Version 1.0, Platform: Quartus 19.0.0

--! | Attribute | Value |
--! | :-- | :-- |
--! | Subversion revision | $Rev:$ |
--! | Time of last change | $Date:$ |
--! | Author(s) | @author Andreas Schroeder |

----------------------------------------------------------------------------------------

-- Import vunit lib
library vunit_lib;
use vunit_lib.print_pkg.all;
use vunit_lib.log_levels_pkg.all;
use vunit_lib.logger_pkg.all;
use vunit_lib.log_handler_pkg.all;
use vunit_lib.run_pkg.all;
--! \cond
context vunit_lib.vunit_context;
--! \endcond
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.ALL;
use std.textio.all;

--! \addtogroup Ads1018Sequencer_Module
--! @{
--! \addtogroup Ads1018Sequencer_Testbench
--! @{

--! @brief Test of the Ads1018Sequencer logic module.
--! @details All test signal generation and result analysis is done here.
entity e_Ads1018SequencerQualification_TB is
    generic (runner_cfg : string := runner_cfg_default);
    port(
        trigger : out std_logic := '0' --! Trigger is set when test evaluation timing is required   
        );
end entity e_Ads1018SequencerQualification_TB;

--! @brief Generation and analysis of the test signals.
architecture a_Ads1018SequencerQualification_TB of e_Ads1018SequencerQualification_TB is
    -- Testbench Outputs
    signal M_Clk_TB       : std_logic := '1'; --! Clock
    signal M_Rst_TB       : std_logic := '1'; --! reset, active low
    signal Miso_TB        : std_logic;        --! SPI Master In Slave Out
    -- Testbench Inputs
    signal Mosi_TB             : std_logic;                     --! SPI Master Out Slave In
    signal Sclk_TB             : std_logic;                     --! SPI Serial Clock
    signal Cs_TB               : std_logic;                     --! SPI Chip Select
    signal Ads1018Ain0Dat_TB   : std_logic_vector(11 downto 0); --! ADS1018 AIN0 data out, 16 bit width
    signal Ads1018Ain1Dat_TB   : std_logic_vector(11 downto 0); --! ADS1018 AIN1 data out, 16 bit width
    signal Ads1018Ain2Dat_TB   : std_logic_vector(11 downto 0); --! ADS1018 AIN2 data out, 16 bit width
    signal Ads1018Ain3Dat_TB   : std_logic_vector(11 downto 0); --! ADS1018 AIN3 data out, 16 bit width
    signal Ads1018TempDat_TB   : std_logic_vector(11 downto 0); --! ADS1018 Temp data out, 16 bit width
    signal Ads1018CfgDat_TB    : std_logic_vector(15 downto 0); --! ADS1018 Config data out, 16 bit width
    signal Ads1018DatRdyPls_TB : std_logic;                     --! Indicates Valid Data on Data Outputs
    signal Error_TB            : std_logic;                     --! error output, active low, indicates corrupt ADS1018 config register readback
    -- TB Signals
    constant clock_period_TB   : time      := 250 ns;           --! Clock frequency of 4 MHz requires a period of 250 ns
    signal clock_go_TB         : std_logic := '0';              --! Enables the clock generation in the testbench
    signal read_back_dummy_TB  : std_logic_vector(15 downto 0) := x"0000"; --! 16 bits to store testbench data
    signal error_flag_TB       : std_logic := '0';              --! 1 bit to store testbench data
    signal reset_state_TB         : time := 0 ns;

begin
    --! @brief DUT instantiation
    --! @details Instantiation of the DUT
    i_DUT : entity work.e_Ads1018Sequencer(a_Ads1018Sequencer)
    port map(
        -- To DUT aka TB Outputs
		M_Clk => M_Clk_TB,
		M_Rst => M_Rst_TB,
		Miso => Miso_TB,
        -- From DUT aka TB Inputs
        Mosi => Mosi_TB,
		Sclk => Sclk_TB,
		Cs => Cs_TB,
		Ads1018Ain0Dat => Ads1018Ain0Dat_TB,
		Ads1018Ain1Dat => Ads1018Ain1Dat_TB,
		Ads1018Ain2Dat => Ads1018Ain2Dat_TB,
		Ads1018Ain3Dat => Ads1018Ain3Dat_TB,
		Ads1018TempDat => Ads1018TempDat_TB,
		Ads1018CfgDat => Ads1018CfgDat_TB,
		Ads1018DatRdyPls => Ads1018DatRdyPls_TB,
		Error => Error_TB
    );

    --! @brief Main process of the Ads1018Sequencer testbench
	--! @details Vunit loops through all the test cases present in the if statement inside while loop
    main : process

        variable qtb_logger : logger_t := get_logger("logging_timer_QTB:qtb_logger");   --! A logger framework provided by vunit
        constant file_name  : string   := output_path(runner_cfg) & "../../../results/Ads1018SequencerResult.vhd"; --! Output path for the testbench results
        file fptr           : text;             --! File variable to store text passed to the logger
        variable status     : file_open_status; --! Provides feedback to the logger if a file is open
        variable word_count, bit_count : integer := 0;
        variable adc_byte_one, adc_byte_two, adc_byte_three, adc_byte_four : std_logic_vector(7 downto 0) := x"00";
        variable byte_back  : std_logic_vector(7 downto 0) := x"13";
        variable time_one, time_two : time;
        constant number_of_bytes : integer := 3;
        constant number_of_bits  : integer := 7;
        variable miso_temperature, miso_ain0, miso_ain1, miso_ain2, miso_ain3 : std_logic_vector(15 downto 0) := x"0000";

        --! Bit checker customization to write pass/fail message in the logfile
        procedure check_equal_bit (
            constant got         : std_logic;
            constant expected    : std_logic;
            constant message     : string 
        ) is
        begin
            if (got = expected) then
                check_equal(got,expected,message);
                print("--! "& message &": \b PASS \n", fptr);
            else
                print("--! The check reported \b FAIL! \n", fptr);
                check_equal(got,expected,message);
            end if;
        end procedure check_equal_bit;

        --! Time checker customization to write pass/fail message in the logfile
        procedure check_equal_time (
            constant got         : time;
            constant expected    : time;
            constant message     : string 
        ) is
        begin
            if (got = expected) then
                check_equal(got,expected,message);
                print("--! "& message &": \b PASS \n", fptr);
            else
                print("--! The check reported \b FAIL! \n", fptr);
                check_equal(got,expected,message);
            end if;
        end procedure check_equal_time;

        --! Vector checker customization to write pass/fail message in the logfile
        procedure check_equal_vector (
            constant got         : std_logic_vector;
            constant expected    : std_logic_vector;
            constant message     : string 
        ) is
        begin
            if (got = expected) then
                check_equal(got,expected,message);
                print("--! "& message &": \b PASS \n", fptr);
            else
                print("--! The check reported \b FAIL! \n", fptr);
                check_equal(got,expected,message);
            end if;
        end procedure check_equal_vector;

        --! Integer checker customization to write pass/fail message in the logfile
        procedure check_equal_integer (
            constant got         : integer;
            constant expected    : integer;
            constant message     : string 
        ) is
        begin
            if (got = expected) then
                check_equal(got,expected,message);
                print("--! "& message &": \b PASS \n", fptr);
            else
                print("--! The check reported \b FAIL! \n", fptr);
                check_equal(got,expected,message);
            end if;
        end procedure check_equal_integer;

        --! Initial reset and default (off) states of all inputs
        procedure dut_init is
        begin
            wait for 1 us;
            M_Rst_TB <= '1';
            Miso_TB <= '1';
            wait for 0.5 us;
            M_Rst_TB <= '0';
            wait for 0.5 us;
            M_Rst_TB <= '1';
        end procedure dut_init;

        --! Waits for a number of clocks (>= 1) and an additional time (>= 0 ns)
        procedure wait_clock_plus_time(
            constant number_of_clocks : integer;
            constant additional_time : time
        ) is
        begin
            for clocks in 1 to number_of_clocks loop
                wait until rising_edge(M_Clk_TB);
            end loop;
            wait for additional_time;
        end procedure wait_clock_plus_time;

        --! Created the header for the tests
        procedure test_header (
            constant test_name      : string;
            constant short_desc     : string;
            constant test_desc      : string;
            constant req_id_one     : string := "";
            constant req_id_two     : string := "";
            constant req_id_three   : string := "";
            constant req_id_four    : string := "";
            constant req_id_five    : string := ""
        ) is
        begin
            print("--! <b>"& short_desc &" Test Name: "& test_name &"</b> \n", fptr);
            print("--! "& test_desc &" \n", fptr);
            print("--! \n", fptr);
            if (req_id_one'length > 0) then
                print("--! | Requirement(s) Covered |", fptr);
                print("--! | :-: |", fptr);
                if(req_id_one'length > 0) then
                    print("--! | Tests "& req_id_one &" |", fptr);
                    if (req_id_two'length > 0) then
                        print("--! | Tests "& req_id_two &" |", fptr);      end if;
                    if (req_id_three'length > 0) then
                        print("--! | Tests "& req_id_three &" |", fptr);    end if;
                    if (req_id_four'length > 0) then
                        print("--! | Tests "& req_id_four &" |", fptr);     end if;
                    if (req_id_five'length > 0) then
                        print("--! | Tests "& req_id_five &" |", fptr);     end if;
                end if;
            end if;
            print("--! \n", fptr);
            print("--! @image html lib.e_ads1018sequencerqualification_tb."& test_name &"_1.png "& test_name &"_1 width=1000", fptr);
            print("--! @image latex lib.e_ads1018sequencerqualification_tb."& test_name &"_1.png "& test_name &"_1 width=16cm", fptr);
            print("--! \n", fptr);
        end procedure test_header;

        --! Checks all DUT outputs
        procedure check_all_outputs (
            p_Cs_TB : std_logic;
            p_Ads1018Ain0Dat_TB     : std_logic_vector(11 downto 0);
            p_Ads1018Ain1Dat_TB     : std_logic_vector(11 downto 0);
            p_Ads1018Ain2Dat_TB     : std_logic_vector(11 downto 0);
            p_Ads1018Ain3Dat_TB     : std_logic_vector(11 downto 0);
            p_Ads1018TempDat_TB     : std_logic_vector(11 downto 0);
            p_Ads1018CfgDat_TB      : std_logic_vector(15 downto 0);
            p_Ads1018DatRdyPls_TB   : std_logic;
            p_Error_TB      : std_logic;
            p_n_mode_flag   : boolean := true
        ) is
        begin
            if p_n_mode_flag = true then -- Mode with report output enabled
                check_equal_bit(Cs_TB, p_Cs_TB, "Cs_TB was " & std_logic'image(Cs_TB));
                check_equal_vector(Ads1018Ain0Dat_TB,   p_Ads1018Ain0Dat_TB,    "Ads1018Ain0Dat_TB was 0x"        & to_hstring(Ads1018Ain0Dat_TB));
                check_equal_vector(Ads1018Ain1Dat_TB,   p_Ads1018Ain1Dat_TB,    "Ads1018Ain1Dat_TB was 0x"        & to_hstring(Ads1018Ain1Dat_TB));
                check_equal_vector(Ads1018Ain2Dat_TB,   p_Ads1018Ain2Dat_TB,    "Ads1018Ain2Dat_TB was 0x"        & to_hstring(Ads1018Ain2Dat_TB));
                check_equal_vector(Ads1018Ain3Dat_TB,   p_Ads1018Ain3Dat_TB,    "Ads1018Ain3Dat_TB was 0x"        & to_hstring(Ads1018Ain3Dat_TB));
                check_equal_vector(Ads1018TempDat_TB,   p_Ads1018TempDat_TB,    "Ads1018TempDat_TB was 0x"      & to_hstring(Ads1018TempDat_TB));
                check_equal_vector(Ads1018CfgDat_TB,    p_Ads1018CfgDat_TB,     "Ads1018CfgDat_TB was 0x"       & to_hstring(Ads1018CfgDat_TB));
                check_equal_bit(Ads1018DatRdyPls_TB,    p_Ads1018DatRdyPls_TB,  "Ads1018DatRdyPls_TB was "    & std_logic'image(Ads1018DatRdyPls_TB));
                check_equal_bit(Error_TB, p_Error_TB, "p_Error_TB was " & std_logic'image(Error_TB));
                print("--! \n", fptr);
            elsif p_n_mode_flag = false then -- Only check mode, no report file output
                check_equal(Cs_TB, p_Cs_TB, "Cs_TB was " & std_logic'image(Cs_TB));
                check_equal(Ads1018Ain0Dat_TB,   p_Ads1018Ain0Dat_TB,    "Ads1018Ain0Dat_TB was 0x"        & to_hstring(Ads1018Ain0Dat_TB));
                check_equal(Ads1018Ain1Dat_TB,   p_Ads1018Ain1Dat_TB,    "Ads1018Ain1Dat_TB was 0x"        & to_hstring(Ads1018Ain1Dat_TB));
                check_equal(Ads1018Ain2Dat_TB,   p_Ads1018Ain2Dat_TB,    "Ads1018Ain2Dat_TB was 0x"        & to_hstring(Ads1018Ain2Dat_TB));
                check_equal(Ads1018Ain3Dat_TB,   p_Ads1018Ain3Dat_TB,    "Ads1018Ain3Dat_TB was 0x"        & to_hstring(Ads1018Ain3Dat_TB));
                check_equal(Ads1018TempDat_TB,   p_Ads1018TempDat_TB,    "Ads1018TempDat_TB was 0x"      & to_hstring(Ads1018TempDat_TB));
                check_equal(Ads1018CfgDat_TB,    p_Ads1018CfgDat_TB,     "Ads1018CfgDat_TB was 0x"       & to_hstring(Ads1018CfgDat_TB));
                check_equal(Ads1018DatRdyPls_TB, p_Ads1018DatRdyPls_TB,  "Ads1018DatRdyPls_TB was "    & std_logic'image(Ads1018DatRdyPls_TB));
                check_equal(Error_TB, p_Error_TB, "p_Error_TB was " & std_logic'image(Error_TB));
            end if;
        end procedure check_all_outputs;

        --! Asynchronous reset with output check
        procedure async_reset_and_check(
            constant signals_checked : string
        ) is
        begin
            wait for 100 ns;
            M_Rst_TB <= '0';
            wait for 1 ns;
            check_all_outputs('1',x"000",x"000",x"000",x"000",x"000",x"0000",'0','0',true);
            wait for 5 us;
            adc_byte_one := (others => '0');
            adc_byte_two := (others => '0');
            M_Rst_TB <= '1';
            print("--! " & signals_checked & " \n", fptr);
            print("--! \n", fptr);
        end procedure async_reset_and_check;

    --! Initialization routine loop
        procedure dut_dac_four_byte (
            constant words_to_receive : integer;
            constant bits_per_word    : integer;
            constant byte_to_send_one : std_logic_vector(7 downto 0);
            constant byte_to_send_two : std_logic_vector(7 downto 0);
            constant byte_to_send_data_msb : std_logic_vector(7 downto 0) := x"00";
            constant byte_to_send_data_lsb : std_logic_vector(7 downto 0) := x"00";
            constant reset_trigger         : time := 0 ns
        )is
            variable i_word_count : integer := 0;
            variable i_bit_count  : integer := 0;
        begin
            while(i_word_count <= words_to_receive) loop
                while(i_bit_count <= bits_per_word) loop
                    wait until rising_edge(Sclk_TB);
                    Miso_TB <= '0';
                    if(i_word_count = 0) then
                        adc_byte_one(7 - i_bit_count) := Mosi_TB;
                        Miso_TB <= byte_to_send_data_msb(7 - i_bit_count);
                    elsif(i_word_count = 1) then
                        adc_byte_two(7 - i_bit_count) := Mosi_TB;
                        Miso_TB <= byte_to_send_data_lsb(7 - i_bit_count);
                    elsif(i_word_count = 2) then
                        -- Receive dummy byte 3
                        adc_byte_three(7 - i_bit_count) := Mosi_TB;
                        -- Send CFG byte 1
                        Miso_TB <= byte_to_send_one(7 - i_bit_count);
                    elsif(i_word_count = 3) then
                        -- Receive dummy byte 4
                        adc_byte_four(7 - i_bit_count) := Mosi_TB;
                        -- Send CFG byte 2 the LSB is always '1'
                        if(i_bit_count <= 6) then
                            Miso_TB <= byte_to_send_two(7 - i_bit_count);
                        else
                            Miso_TB <= '1';
                        end if;
                    end if;
                    i_bit_count := i_bit_count + 1;
                end loop;
                    i_word_count := i_word_count + 1;
                    i_bit_count := 0;
            end loop;
            wait until falling_edge(Sclk_TB);
            i_word_count := 0;
            Miso_TB <= '1';
        end procedure dut_dac_four_byte;

        --! Send all four data bytes
        procedure all_four_bytes(
            constant p_miso_ain0 : std_logic_vector(15 downto 0);
            constant p_miso_ain1 : std_logic_vector(15 downto 0);
            constant p_miso_ain2 : std_logic_vector(15 downto 0);
            constant p_miso_ain3 : std_logic_vector(15 downto 0);
            constant p_miso_temperature : std_logic_vector(15 downto 0);
            constant p_adc_byte_one : std_logic_vector(7 downto 0);
            constant p_adc_byte_two : std_logic_vector(7 downto 0);
            constant p_run : integer
        ) is
        begin
            if (p_run = 0) then
                wait until rising_edge(M_Clk_TB);
                dut_dac_four_byte(number_of_bytes,number_of_bits,p_adc_byte_one,p_adc_byte_two); -- DAC init routine SPI receive/send
                wait until rising_edge(M_Clk_TB);
                dut_dac_four_byte(number_of_bytes,number_of_bits,p_adc_byte_one,p_adc_byte_two,p_miso_ain3(15 downto 8),p_miso_ain3(7 downto 0)); -- DAC AIN 3
                wait for 5 us;
                Miso_TB <= '0';
                dut_dac_four_byte(number_of_bytes,number_of_bits,p_adc_byte_one,p_adc_byte_two,p_miso_ain3(15 downto 8),p_miso_ain3(7 downto 0)); -- DAC AIN 3
           end if;
            wait for 6 us;
            Miso_TB <= '0';
            dut_dac_four_byte(number_of_bytes,number_of_bits,p_adc_byte_one,p_adc_byte_two,p_miso_temperature(15 downto 8),p_miso_temperature(7 downto 0)); -- DAC Temp
            wait for 5 us;
            Miso_TB <= '0';
            dut_dac_four_byte(number_of_bytes,number_of_bits,p_adc_byte_one,p_adc_byte_two,p_miso_ain0(15 downto 8),p_miso_ain0(7 downto 0)); -- DAC AIN 0
            wait for 5 us;
            Miso_TB <= '0';
            dut_dac_four_byte(number_of_bytes,number_of_bits,p_adc_byte_one,p_adc_byte_two,p_miso_ain1(15 downto 8),p_miso_ain1(7 downto 0)); -- DAC AIN 1
            wait for 5 us;
            Miso_TB <= '0';
            dut_dac_four_byte(number_of_bytes,number_of_bits,p_adc_byte_one,p_adc_byte_two,p_miso_ain2(15 downto 8),p_miso_ain2(7 downto 0)); -- DAC AIN 2
            wait for 5 us;
            Miso_TB <= '0';
            dut_dac_four_byte(number_of_bytes,number_of_bits,p_adc_byte_one,p_adc_byte_two,p_miso_ain3(15 downto 8),p_miso_ain3(7 downto 0)); -- DAC AIN 3

        end procedure all_four_bytes;

        --! Time calculations
        function time_diff_calc(
            constant p_time_one : time;
            constant p_time_two : time
        ) return time is
            variable time_difference : time; 
        begin
            time_difference := p_time_two - p_time_one;
        return time_difference;
        end function time_diff_calc;

    begin
        -- Open the file and check if open
        file_open(status, fptr, file_name, append_mode);
        assert status = open_ok report "Failed to open file " & file_name severity failure;
        
        test_runner_setup(runner, runner_cfg);  -- Entry point for the vunit application

        while test_suite loop --! Testbench loop
            dut_init;

            --enable_sig_TB <= '1';

            if run("adc_power_up_init_tb") then
                -- Create the result file header
                --! \cond
                print("--! \addtogroup Ads1018Sequencer_Module", fptr);
                print("--! @{" ,fptr);
                print("--! \addtogroup Ads1018Sequencer_Result",fptr);
                print("--! @{",fptr);
                print("--! @brief Testbench for the Ads1018Sequencer module",fptr);
                print("--! @page Ads1018Sequencer" ,fptr);
                print("--! @section Ads1018Sequencer Result of tests",fptr);
                --! \endcond

                wait for 1 us;
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Power up ADC init test.", 
                            "Initialization routine valid data read back, sent bytes (from DUT) are 0x00, 0x12, 0x00 and 0x00. Return bytes shall be 0x13, Error_TB must be inactive (1).", 
                            "DHHLR_852","", "", "", "");

                wait until rising_edge(M_Clk_TB);
                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two); -- DAC init routine SPI receive/send
                wait until rising_edge(Error_TB);

                trigger <= '1';
                
                print("--! Mosi data received from the DUT:\n",fptr);
                check_equal_vector(adc_byte_one  , x"00", "Byte one was: 0x"   & to_hstring(adc_byte_one));
                check_equal_vector(adc_byte_two  , x"12", "Byte two was: 0x"   & to_hstring(adc_byte_two));
                check_equal_vector(adc_byte_three, x"00", "Byte three was: 0x" & to_hstring(adc_byte_three));
                check_equal_vector(adc_byte_four , x"00", "Byte four was: 0x"  & to_hstring(adc_byte_four));

                print("--! Error_TB must be inactive(1):\n",fptr);
                check_equal_bit(Error_TB, '1', "Error_TB was: " & std_logic'image(Error_TB));
                print("--! \n",fptr);
                
                check_all_outputs('0',x"000",x"000",x"000",x"000",x"000",x"0013",'0','1',false); -- Check DUT outputs -> Not required for the test, just to check all outputs
                wait for 2 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("adc_readback_invalid_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Read back data invalid tests.", 
                            "All invalid combinations of the read back data shall be sent (0x0000 to 0xFFFF, excluded 0x0013). Error_TB shall be active(0) for all combinations.", 
                            "DHHLR_853","DHHLR_854", "DHHLR_858", "", "");

                wait until rising_edge(M_Clk_TB);
                error_flag_TB <= '1';
                for count in 0 to 65534 loop
                    if (read_back_dummy_TB = x"0012") then
                        read_back_dummy_TB <= x"0014";
                     end if;

                    dut_dac_four_byte(number_of_bytes,number_of_bits,read_back_dummy_TB(15 downto 8),read_back_dummy_TB(7 downto 0)); -- DAC init routine SPI receive/send

                    read_back_dummy_TB <= read_back_dummy_TB + "1";
                    wait until falling_edge(M_Clk_TB);
                    check_equal(Error_TB, '0', "Error_TB must be low(0).");
                end loop;
                wait until rising_edge(Cs_TB);
                wait until rising_edge(Cs_TB);
                trigger <= '1';

                check_equal_bit(Error_TB, '0', "Error_TB was active(0) for all invalid combinations");
                print("--! \n",fptr);
                wait for 2 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("adc_chip_select_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "ADC init test chip select test.", 
                            "Cs_TB shall be active for one clock cycle after the 4 initial bytes are received.", 
                            "DHHLR_855","", "", "", "");

                wait until rising_edge(M_Clk_TB);
                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two); -- DAC init routine SPI receive/send

                wait until rising_edge(Cs_TB);
                trigger <= '1';
                time_one := now;
                wait until falling_edge(Cs_TB);
                time_two := now;

                check_equal_time(time_diff_calc(time_one,time_two), clock_period_TB,"Cs_TB was active after four init bytes where received, the pulse width was " & time'image(time_diff_calc(time_one,time_two)));
                print("--! \n",fptr);
                wait for 2 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("read_data_bytes_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "ADC read data bytes test.", 
                            "Several complete runs shall be performed. Dummy data is returned according to the configuration bytes in DHHLR_856, Table 6.", 
                            "DHHLR_856","", "", "", "");

                miso_temperature := x"1111";
                miso_ain0 := x"2222";
                miso_ain1 := x"3333";
                miso_ain2 := x"4444";
                miso_ain3 := x"5555";
            
                wait until rising_edge(M_Clk_TB);
                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two); -- DAC init routine SPI receive/send
                check_all_outputs('0',x"000",x"000",x"000",x"000",x"000",x"0000",'0','0',false);
                wait until rising_edge(M_Clk_TB);

                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two,miso_ain3(15 downto 8),miso_ain3(7 downto 0)); -- DAC AIN 3
                check_all_outputs('0',x"000",x"000",x"000",x"555",x"000",x"0013",'0','1',false);

                wait for 5 us;
                Miso_TB <= '0';
                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two,miso_ain3(15 downto 8),miso_ain3(7 downto 0)); -- DAC AIN 3
                wait for 1 us;
                check_all_outputs('0',x"000",x"000",x"000",x"555",x"000",x"4003",'0','1',false);

                for runs in 0 to 3 loop
                    wait for 5 us;
                    Miso_TB <= '0';
                    dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two,miso_temperature(15 downto 8),miso_temperature(7 downto 0)); -- DAC Temp
                    if(runs = 0)    then check_all_outputs('0',x"000",x"000",x"000",x"555",x"111",x"5003",'0','1',false);
                    elsif(runs = 1) then check_all_outputs('0',x"222",x"333",x"444",x"666",x"222",x"5003",'0','1',false);
                    elsif(runs = 2) then check_all_outputs('0',x"333",x"444",x"555",x"777",x"333",x"5003",'0','1',false);
                    elsif(runs = 3) then check_all_outputs('0',x"444",x"555",x"666",x"888",x"444",x"5003",'0','1',false); end if;

                    wait for 5 us;
                    Miso_TB <= '0';
                    dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two,miso_ain0(15 downto 8),miso_ain0(7 downto 0)); -- DAC AIN 0
                    if(runs = 0)    then check_all_outputs('0',x"222",x"000",x"000",x"555",x"111",x"6003",'0','1',false);
                    elsif(runs = 1) then check_all_outputs('0',x"333",x"333",x"444",x"666",x"222",x"6003",'0','1',false);
                    elsif(runs = 2) then check_all_outputs('0',x"444",x"444",x"555",x"777",x"333",x"6003",'0','1',false);
                    elsif(runs = 3) then check_all_outputs('0',x"555",x"555",x"666",x"888",x"444",x"6003",'0','1',false); end if;

                    wait for 5 us;
                    Miso_TB <= '0';
                    dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two,miso_ain1(15 downto 8),miso_ain1(7 downto 0)); -- DAC AIN 1
                    if(runs = 0)    then check_all_outputs('0',x"222",x"333",x"000",x"555",x"111",x"7003",'0','1',false);
                    elsif(runs = 1) then check_all_outputs('0',x"333",x"444",x"444",x"666",x"222",x"7003",'0','1',false);
                    elsif(runs = 2) then check_all_outputs('0',x"444",x"555",x"555",x"777",x"333",x"7003",'0','1',false);
                    elsif(runs = 3) then check_all_outputs('0',x"555",x"666",x"666",x"888",x"444",x"7003",'0','1',false); end if;

                    wait for 5 us;
                    Miso_TB <= '0';
                    dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two,miso_ain2(15 downto 8),miso_ain2(7 downto 0)); -- DAC AIN 2
                    wait_clock_plus_time(1, 1 ns);
                    trigger <= not trigger;
                    if(runs = 0)    then check_all_outputs('0',x"222",x"333",x"444",x"555",x"111",x"0013",'0','1',false);
                    elsif(runs = 1) then check_all_outputs('0',x"333",x"444",x"555",x"666",x"222",x"0013",'0','1',false);
                    elsif(runs = 2) then check_all_outputs('0',x"444",x"555",x"666",x"777",x"333",x"0013",'0','1',false);
                    elsif(runs = 3) then check_all_outputs('0',x"555",x"666",x"777",x"888",x"444",x"0013",'0','1',false); end if;

                    miso_temperature := miso_temperature + x"1111";
                    miso_ain0:= miso_ain0 + x"1111";
                    miso_ain1:= miso_ain1 + x"1111";
                    miso_ain2:= miso_ain2 + x"1111";
                    miso_ain3:= miso_ain3 + x"1111";

                    wait for 5 us;
                    Miso_TB <= '0';
                    dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two,miso_ain3(15 downto 8),miso_ain3(7 downto 0)); -- DAC AIN 3
                    if(runs = 0)    then check_all_outputs('0',x"222",x"333",x"444",x"666",x"111",x"4013",'0','1',false);
                    elsif(runs = 1) then check_all_outputs('0',x"333",x"444",x"555",x"777",x"222",x"4013",'0','1',false);
                    elsif(runs = 2) then check_all_outputs('0',x"444",x"555",x"666",x"888",x"333",x"4013",'0','1',false); end if;

                end loop;

                check_all_outputs('0',x"555",x"666",x"777",x"999",x"444",x"4013",'0','1',true);
                print("--! After four runs Ads1018Ain0Dat_TB is 0x555, Ads1018Ain1Dat_TB is 0x666, Ads1018Ain2Dat_TB is 0x777, Ads1018Ain3Dat_TB is 0x999 and Ads1018TempDat_TB is 0x444. \n \n", fptr);
                trigger <= '1';

                wait for 5 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("adc_data_ready_pulse_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case,
                            "ADC data ready pulse test.", 
                            "Ads1018DatRdyPls_TB shall be active for on clock cycle after Miso_TB changes to low (0).", 
                            "DHHLR_842","", "", "", "");

                miso_ain3 := x"5555";

                wait until rising_edge(M_Clk_TB);
                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two); -- DAC init routine SPI receive/send
                check_all_outputs('0',x"000",x"000",x"000",x"000",x"000",x"0000",'0','0',false);
                wait until rising_edge(M_Clk_TB);

                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two,miso_ain3(15 downto 8),miso_ain3(7 downto 0)); -- DAC AIN 3
                check_all_outputs('0',x"000",x"000",x"000",x"555",x"000",x"0013",'0','1',false);

                wait for 5 us;
                Miso_TB <= '0';

                wait until rising_edge(Ads1018DatRdyPls_TB);
                trigger <= '1';
                time_one := now;
                wait until falling_edge(Ads1018DatRdyPls_TB);
                time_two := now;

                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two,miso_ain3(15 downto 8),miso_ain3(7 downto 0)); -- DAC AIN 3
                check_all_outputs('0',x"000",x"000",x"000",x"555",x"000",x"4013",'0','1',false);

                check_equal_time(time_diff_calc(time_one,time_two), clock_period_TB,"Ads1018DatRdyPls_TB was active after Miso_TB changed to low (0), the pulse width was " & time'image(time_diff_calc(time_one,time_two)));
                print("--! \n",fptr);
                wait for 2 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("adc_sequencer_reset_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case,
                            "ADC sequencer reset test.", 
                            "Reset gets active and the outputs shall get inactive.", 
                            "DHHLR_857","", "", "", "");

                miso_ain3 := x"0000";

                Miso_TB <= '0';
                wait until rising_edge(Mosi_TB);
                check_equal_bit(Mosi_TB,'1',"Mosi_TB was active(1)");
                check_equal_bit(Cs_TB,'0',"Cs_TB was active(0)");
                check_equal_bit(Sclk_TB,'1',"Sclk_TB was active(1)");
                print("--! Reset now active(1): \n \n", fptr);
                wait for 100 ns;
                trigger <= '1';
                M_Rst_TB <= '0';
                wait for 1 ns;
                check_equal_bit(Mosi_TB,'0',"Mosi_TB was 0");
                check_equal_bit(Sclk_TB,'0',"Sclk_TB was 0");
                async_reset_and_check("Reset was active and Mosi_TB, Cs_TB and Sclk_TB switched to not active.");

                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,x"13"); -- DAC init routine SPI receive/send
                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two,miso_ain3(15 downto 8),miso_ain3(7 downto 0));
                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two,miso_ain3(15 downto 8),miso_ain3(7 downto 0));
                wait for 2 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("adc_sequencer_reset_two_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case,
                            "ADC sequencer reset test.", 
                            "Reset gets active and the outputs shall get inactive.", 
                            "DHHLR_857","", "", "", "");

                miso_ain3 := x"FFFF";
            
                wait until rising_edge(M_Clk_TB);
                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two); -- DAC init routine SPI receive/send
                check_all_outputs('0',x"000",x"000",x"000",x"000",x"000",x"0000",'0','0',false);
                wait until rising_edge(M_Clk_TB);

                dut_dac_four_byte(number_of_bytes,number_of_bits,adc_byte_one,adc_byte_two,miso_ain3(15 downto 8),miso_ain3(7 downto 0)); -- DAC AIN 3
                check_all_outputs('0',x"000",x"000",x"000",x"FFF",x"000",x"0013",'0','1',false);
                wait for 2 us;
                Miso_TB <= '0';

                wait until rising_edge(Ads1018DatRdyPls_TB);
                check_equal_bit(Ads1018DatRdyPls_TB,'1',"Ads1018DatRdyPls_TB was active(1)");
                check_equal_bit(Error_TB,'1',"Error_TB was active(1)");
                print("--! Reset now active(1): \n \n", fptr);
                trigger <= '1' after 100 ns;
                async_reset_and_check("Reset was active, Ads1018DatRdyPls_TB and Error_TB switched to not active(0).");
 
                wait for 2.5 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("adc_sequencer_reset_three_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "ADC sequencer reset test.", 
                            "Reset gets active and the outputs shall get inactive.", 
                            "DHHLR_857","", "", "", "");

                miso_temperature := x"AFAF";
                miso_ain0 := x"FAFA";
                miso_ain1 := x"AFAF";
                miso_ain2 := x"FAFA";
                miso_ain3 := x"AFAF";
            
                all_four_bytes(miso_ain0,miso_ain1,miso_ain2,miso_ain3,miso_temperature,adc_byte_one,adc_byte_two,0);

                check_all_outputs('0',x"FAF",x"AFA",x"FAF",x"AFA",x"AFA",x"4013",'0','1',true);
                print("--! Reset now active(1): \n \n", fptr);
                trigger <= '1' after 100 ns;
                async_reset_and_check("Ads1018Ain0Dat_TB, Ads1018Ain1Dat_TB, Ads1018Ain2Dat_TB, Ads1018Ain3Dat_TB and Ads1018TempDat_TB where reset to 0x000");

                wait for 5 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("readback_error_data_loop_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "ADC configuration readback error after init test.", 
                            "Configuration readback is invalid after initialization is done. Error_TB shall get active(0).", 
                            "DHHLR_841","", "", "", "");

                miso_temperature := x"1010";
                miso_ain0 := x"F0F0";
                miso_ain1 := x"1F1F";
                miso_ain2 := x"1010";
                miso_ain3 := x"A1A0";
            
                 for byte in 0 to 3 loop
                    trigger <= not trigger;
                    if (byte = 1) then
                        all_four_bytes(miso_ain0,miso_ain1,miso_ain2,miso_ain3,miso_temperature,x"00",x"FF",byte);
                        trigger <= '1';
                        check_all_outputs('0',x"F0F",x"1F1",x"101",x"A1A",x"101",x"00FF",'0','0',true);
                     else
                        all_four_bytes(miso_ain0,miso_ain1,miso_ain2,miso_ain3,miso_temperature,adc_byte_one,adc_byte_two,byte);
                   end if;
                 end loop;

                 check_all_outputs('0',x"F0F",x"1F1",x"101",x"A1A",x"101",x"4013",'0','1',false);
                 
                wait for 5 us;
                info("Test "& running_test_case &" - DONE");

-------------------------------------------------------------- Transition Coverage ----------------------------------------------------------
            elsif run("state1_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State1 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");

                miso_ain1 := x"1F1F";
                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 5 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state2_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State2 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");

                miso_ain1 := x"1F1F";
                reset_state_TB <= (2250 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;
                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 5 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state3_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State3 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                miso_ain1 := x"1F1F";
                reset_state_TB <= (11000 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;
                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 5 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state4_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State4 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                miso_ain1 := x"1F1F";
                reset_state_TB <= (11250 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;
                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state5_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State5 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                miso_ain1 := x"1F1F";
                reset_state_TB <= (19750 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;
                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state6_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State6 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                miso_ain1 := x"1F1F";
                reset_state_TB <= (20000 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;
                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state7_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State7 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                miso_ain1 := x"1F1F";
                reset_state_TB <= (28500 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;
                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state8_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State8 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                miso_ain1 := x"1F1F";
                reset_state_TB <= (28750 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;
                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state9_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State9 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                miso_ain1 := x"1F1F";
                reset_state_TB <= (37250 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;
                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("statecheckinit_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - StateCheckInit to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                miso_ain1 := x"1F1F";
                reset_state_TB <= (37500 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;
                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state11_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State11 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                dut_dac_four_byte(number_of_bytes,number_of_bits,x"00",x"13"); 

                miso_ain1 := x"1F1F";
                reset_state_TB <= (38000 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;

                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state12_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State12 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                dut_dac_four_byte(number_of_bytes,number_of_bits,x"00",x"13"); 

                miso_ain1 := x"1F1F";
                reset_state_TB <= (46500 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;

                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state13_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State13 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                dut_dac_four_byte(number_of_bytes,number_of_bits,x"00",x"13"); 

                miso_ain1 := x"1F1F";
                reset_state_TB <= (46750 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;

                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state14_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State14 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                dut_dac_four_byte(number_of_bytes,number_of_bits,x"00",x"13"); 

                miso_ain1 := x"1F1F";
                reset_state_TB <= (55250 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;

                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state15_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State15 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                dut_dac_four_byte(number_of_bytes,number_of_bits,x"00",x"13"); 

                miso_ain1 := x"1F1F";
                reset_state_TB <= (55500 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;

                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("state16_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - State16 to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                dut_dac_four_byte(number_of_bytes,number_of_bits,x"00",x"13");

                miso_ain1 := x"1F1F";
                reset_state_TB <= (64000 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;

                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("statecheck_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - StateCheck to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                dut_dac_four_byte(number_of_bytes,number_of_bits,x"00",x"13");

                miso_ain1 := x"1F1F";
                reset_state_TB <= (72750 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;

                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");

            elsif run("statewait_to_statedefault_tb") then
                info("Test "& running_test_case &" - START");
                test_header(running_test_case, 
                            "Transition converage test - StateWait to StateDefault.", 
                            "M_Rst_TB get active(0) after the desired state is reached, this shall the the state to StateDefault.", 
                            "DHHLR_852","", "", "", "");
                            
                dut_dac_four_byte(number_of_bytes,number_of_bits,x"00",x"13");

                miso_ain1 := x"1F1F";
                reset_state_TB <= (73000 ns - now);
                wait for 1 ns;
                wait for reset_state_TB - 1 ns;

                trigger <= '1' after 100 ns;
                async_reset_and_check("All outputs where checked.");

                wait for 50 us;
                info("Test "& running_test_case &" - DONE");
                    
                -- Create the result file footer
                print("--! \n \n", fptr);
                print("entity e_Ads1018SequencerLog is ", fptr);
                print("end e_Ads1018SequencerLog;",fptr);
                print("architecture a_Ads1018SequencerLog of e_Ads1018SequencerLog is",fptr);
                print("begin",fptr);
                print("end a_Ads1018SequencerLog;",fptr);
                print("--! @}",fptr);
                print("--! @}",fptr);
                
             end if;
             clock_go_TB <= '0';
             --enable_sig_TB <= '0';
        end loop;
        wait for 10 us;
        file_close(fptr); -- Close the file
        test_runner_cleanup(runner); -- End vunit script
        wait;
    end process;

clk: process
begin
    M_Clk_TB <= '1';
    wait for (clock_period_TB / 2);
    M_Clk_TB <= '0';
    wait for (clock_period_TB / 2);
end process;

end architecture a_Ads1018SequencerQualification_TB;
--! @}
--! @}